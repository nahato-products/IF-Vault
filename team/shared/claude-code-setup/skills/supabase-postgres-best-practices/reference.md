# Supabase Postgres Best Practices - Reference

Detailed rules with SQL examples, organized by category and impact.

---

## 1. Query Performance [CRITICAL]

### 1.1 Add Indexes on WHERE and JOIN Columns

Impact: 100-1000x faster queries on large tables.

```sql
-- BAD: full table scan
SELECT * FROM orders WHERE customer_id = 123;

-- GOOD: index scan
CREATE INDEX CONCURRENTLY orders_customer_id_idx ON orders (customer_id);
```

For JOINs, index FK side. Find missing FK indexes:
```sql
SELECT conrelid::regclass AS table_name, a.attname AS fk_column
FROM pg_constraint c
JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = ANY(c.conkey)
WHERE c.contype = 'f' AND NOT EXISTS (
  SELECT 1 FROM pg_index i WHERE i.indrelid = c.conrelid AND a.attnum = ANY(i.indkey)
);
```

-> FK indexing schema rule -> `supabase-postgres-best-practices` (Rule 1.1)

### 1.2 Composite Index Column Order

Impact: 5-10x faster multi-column queries. Place equality columns first, range last. Leftmost prefix rule.

```sql
-- GOOD: composite index
CREATE INDEX CONCURRENTLY idx ON orders (status, created_at);
-- Works: WHERE status = 'pending'
-- Works: WHERE status = 'pending' AND created_at > '2024-01-01'
-- Fails: WHERE created_at > '2024-01-01' (no leftmost prefix)
```

### 1.3 Choose Index Type

Impact: 10-100x improvement with correct type.

| Type | Use Case | Operators |
|------|----------|-----------|
| B-tree (default) | Equality, range, sorting | `=, <, >, BETWEEN, IN` |
| GIN | JSONB, arrays, full-text | `@>, ?, ?&, ?|, @@` |
| GiST | Geometric, range types, KNN | `&&, @>, <->` |
| BRIN | Large time-series (10-100x smaller) | `=, <, >` on correlated data |
| Hash | Equality-only (slightly faster) | `=` |

```sql
CREATE INDEX CONCURRENTLY idx ON products USING gin (attributes);
CREATE INDEX CONCURRENTLY idx ON events USING brin (created_at);
CREATE INDEX CONCURRENTLY idx ON locations USING gist (coordinates);
```

BRIN requirement: data must be physically correlated (append-only tables with timestamp).

### 1.4 Partial Indexes

Impact: 5-20x smaller indexes, faster writes and queries.

```sql
-- Index only active users
CREATE INDEX CONCURRENTLY idx ON users (email) WHERE deleted_at IS NULL;

-- Only pending orders
CREATE INDEX CONCURRENTLY idx ON orders (created_at) WHERE status = 'pending';
```

Query must include the WHERE clause for the partial index to be used.

### 1.5 Covering Indexes (INCLUDE)

Impact: 2-5x faster by eliminating heap fetches (index-only scan).

```sql
-- Include columns you SELECT but don't filter on
CREATE INDEX CONCURRENTLY idx ON users (email) INCLUDE (name, created_at);

SELECT email, name, created_at FROM users WHERE email = 'user@example.com';
-- Index-only scan: no table access needed
```

INCLUDE columns are not part of the index key, so they do not affect sort order or uniqueness.

### 1.6 Expression Indexes

Impact: Enable index usage on computed values.

```sql
-- Case-insensitive lookups
CREATE INDEX CONCURRENTLY idx ON users (lower(email));
SELECT * FROM users WHERE lower(email) = 'user@example.com';

-- JSONB field extraction
CREATE INDEX CONCURRENTLY idx ON products ((attributes->>'brand'));
SELECT * FROM products WHERE attributes->>'brand' = 'Nike';
```

The query must use the same expression for the index to be used.

---

## 2. Connection Management [CRITICAL]

### 2.1 Connection Pooling (Supavisor)

Impact: Handle 10-100x more concurrent users. Supabase uses Supavisor (config via Dashboard).

Pool modes:
- **Transaction** (6543): connection returned after tx. Best for most apps
- **Session** (5432): connection held. Needed for prepared statements, temp tables, LISTEN/NOTIFY

Pool size: `(CPU cores * 2) + spindle_count` (4 cores → 10)

### 2.2 Connection Limits & Memory

Impact: Prevent crashes. `max_connections * work_mem` should not exceed 25% of RAM (4GB RAM: max=100, work_mem=8MB).

```sql
ALTER SYSTEM SET max_connections = 100;
ALTER SYSTEM SET work_mem = '8MB';

-- Monitor
SELECT count(*) AS active FROM pg_stat_activity WHERE state = 'active';
```

### 2.3 Idle Connection Timeouts

Impact: Reclaim 30-50% of connection slots.

```sql
ALTER SYSTEM SET idle_in_transaction_session_timeout = '30s';
ALTER SYSTEM SET idle_session_timeout = '10min';
SELECT pg_reload_conf();
```

### 2.4 Prepared Statements with Pooling

Impact: Avoid errors. Named prepared statements break in transaction-mode pooling.

```sql
-- GOOD: deallocate after use
PREPARE get_user AS SELECT * FROM users WHERE id = $1;
EXECUTE get_user(123);
DEALLOCATE get_user;

-- Or use unnamed statements (most ORMs do this)
```

Driver settings: Node.js pg `{ prepare: false }`, JDBC `prepareThreshold=0`

### 2.5 Edge Function Connection Patterns [CRITICAL]

Impact: Prevent connection exhaustion from serverless invocations.

```typescript
// GOOD: Use supabase-js (REST, no connection management needed)
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_ANON_KEY')!
)
const { data } = await supabase.from('orders').select('*').eq('status', 'pending')

// OK: Direct Postgres when needed
// MUST use pooler connection string (port 6543), never direct (port 5432)
import postgres from 'https://deno.land/x/postgresjs/mod.js'
const sql = postgres(Deno.env.get('DATABASE_URL')!) // pooler URL only
const result = await sql`SELECT * FROM orders WHERE status = 'pending'`
await sql.end() // Always close
```

Rules:
- Prefer supabase-js REST for simple CRUD
- Use pooler URL (port 6543) for direct Postgres access
- Always close connections in Edge Functions
- Set short `idle_timeout` and `connect_timeout`

---

## 3. RLS Performance [CRITICAL]

### 3.1 Wrap auth.uid() in Subquery

Impact: 100x+ faster on large tables.

```sql
-- BAD: auth.uid() called per row (1M rows = 1M calls)
CREATE POLICY p ON orders USING (auth.uid() = user_id);

-- GOOD: subquery caches the result (called once)
CREATE POLICY p ON orders USING ((SELECT auth.uid()) = user_id);
```

Same applies to `auth.jwt()`:
```sql
-- BAD: JWT parsed per row
CREATE POLICY p ON orders USING ((auth.jwt()->>'role')::text = 'admin');

-- GOOD: cached via subquery
CREATE POLICY p ON orders USING ((SELECT (auth.jwt()->>'role')::text) = 'admin');
```

### 3.2 Security Definer Functions

Impact: 5-10x faster complex RLS checks.

```sql
CREATE FUNCTION is_team_member(team_id bigint) RETURNS boolean
LANGUAGE sql SECURITY DEFINER SET search_path = '' AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.team_members
    WHERE team_id = $1 AND user_id = (SELECT auth.uid())
  );
$$;

CREATE POLICY p ON orders USING ((SELECT is_team_member(team_id)));
```

SECURITY DEFINER runs as function owner (bypasses RLS on inner queries), so always SET search_path = '' to prevent injection.

### 3.3 Index RLS Policy Columns

Always index columns referenced in RLS policies:
```sql
CREATE INDEX CONCURRENTLY orders_user_id_idx ON orders (user_id);
CREATE INDEX CONCURRENTLY team_members_team_user_idx ON team_members (team_id, user_id);
```

### 3.4 Least Privilege

```sql
-- BAD: GRANT ALL to application role
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO app_user;

-- GOOD: minimal grants
CREATE ROLE app_readonly NOLOGIN;
GRANT USAGE ON SCHEMA public TO app_readonly;
GRANT SELECT ON public.products, public.categories TO app_readonly;

-- Revoke public defaults
REVOKE ALL ON SCHEMA public FROM public;
```

-> RLS policy design (USING vs WITH CHECK) -> `supabase-auth-patterns`

---

## 4. Concurrency & Locking [HIGH]

### 4.1 Short Transactions

Impact: 3-5x throughput improvement, fewer deadlocks.

```sql
-- BAD: holding lock during HTTP call
BEGIN;
SELECT * FROM orders WHERE id = 1 FOR UPDATE; -- lock acquired
-- ... HTTP call to payment API (2-5 seconds, lock held) ...
UPDATE orders SET status = 'paid' WHERE id = 1;
COMMIT;

-- GOOD: external call outside transaction
-- response = await paymentAPI.charge(...)
BEGIN;
UPDATE orders SET status = 'paid', payment_id = $1
WHERE id = $2 AND status = 'pending' RETURNING *;
COMMIT; -- lock held for milliseconds
```

Safety: `SET statement_timeout = '30s';`

### 4.2 Deadlock Prevention

Impact: Eliminate deadlock errors.

```sql
-- Acquire locks in consistent order (by ID ascending)
BEGIN;
SELECT * FROM accounts WHERE id IN (1, 2) ORDER BY id FOR UPDATE;
UPDATE accounts SET balance = balance - 100 WHERE id = 1;
UPDATE accounts SET balance = balance + 100 WHERE id = 2;
COMMIT;

-- Or use single atomic statement
UPDATE accounts SET balance = balance + CASE id WHEN 1 THEN -100 WHEN 2 THEN 100 END
WHERE id IN (1, 2);
```

Detect: `SELECT * FROM pg_stat_database WHERE deadlocks > 0;`

-> Use `systematic-debugging` Phase 1 to investigate recurring deadlocks

### 4.3 SKIP LOCKED Queues

Impact: 10x throughput for worker queues.

```sql
-- Atomic claim-and-process (workers don't block each other)
UPDATE jobs SET status = 'processing', worker_id = $1, started_at = now()
WHERE id = (
  SELECT id FROM jobs WHERE status = 'pending'
  ORDER BY created_at LIMIT 1 FOR UPDATE SKIP LOCKED
) RETURNING *;
```

Index: `CREATE INDEX CONCURRENTLY idx ON jobs (status, created_at) WHERE status = 'pending';`

### 4.4 Advisory Locks

Impact: Efficient application-level coordination.

```sql
-- Transaction-level (released on commit/rollback)
BEGIN;
SELECT pg_advisory_xact_lock(hashtext('daily_report'));
-- ... exclusive work ...
COMMIT;

-- Non-blocking try-lock
SELECT pg_try_advisory_lock(hashtext('resource_name'));
-- Returns true if lock acquired, false if already held
```

Use case: prevent concurrent runs of scheduled jobs, rate limiting, distributed locks.

---

## 5. Data Access Patterns [HIGH]

### 5.1 N+1 Query Elimination

Impact: 10-100x fewer round trips.

```sql
-- BAD: 1 query per user (101 total round trips)
SELECT id FROM users WHERE active = true; -- 100 IDs
-- ... N more queries

-- GOOD: single batch
SELECT * FROM orders WHERE user_id = ANY($1::bigint[]);

-- Or JOIN
SELECT u.id, u.name, o.* FROM users u
LEFT JOIN orders o ON o.user_id = u.id WHERE u.active = true;
```

-> Write regression test after fixing N+1 -> `testing-strategy`

### 5.2 Cursor Pagination

Impact: O(1) performance regardless of page depth.

```sql
-- BAD: OFFSET scans all skipped rows
SELECT * FROM products ORDER BY id LIMIT 20 OFFSET 199980; -- scans 200K rows

-- GOOD: cursor/keyset pagination
SELECT * FROM products WHERE id > $last_id ORDER BY id LIMIT 20;

-- Multi-column sort cursor
SELECT * FROM products
WHERE (created_at, id) > ('2024-01-15 10:00:00', 12345)
ORDER BY created_at, id LIMIT 20;
```

### 5.3 Batch Inserts

Impact: 10-50x faster bulk inserts.

```sql
-- Multi-row VALUES (up to ~1000 rows per batch)
INSERT INTO events (user_id, action) VALUES (1,'click'), (1,'view'), (2,'click');

-- COPY for large imports (fastest)
COPY events (user_id, action, created_at) FROM '/path/to/data.csv'
WITH (FORMAT csv, HEADER true);
```

### 5.4 UPSERT

Impact: Atomic operation, eliminates race conditions.

```sql
INSERT INTO settings (user_id, key, value) VALUES ($1, $2, $3)
ON CONFLICT (user_id, key) DO UPDATE SET value = EXCLUDED.value, updated_at = now()
RETURNING *;

-- Insert-or-ignore
INSERT INTO page_views (page_id, user_id) VALUES (1, 123)
ON CONFLICT (page_id, user_id) DO NOTHING;
```

-> UPSERT conflict target design -> `supabase-postgres-best-practices` (Rule 5.4)

### 5.5 SELECT Only Needed Columns

Impact: 2-10x less I/O, enables index-only scans.

```sql
-- BAD: transfers all columns including large JSONB
SELECT * FROM products WHERE category = 'electronics';

-- GOOD: only what you need
SELECT id, name, price FROM products WHERE category = 'electronics';
```

---

## 6. Monitoring & Diagnostics [HIGH]

### 6.1 EXPLAIN ANALYZE

```sql
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT) SELECT * FROM orders WHERE customer_id = 123;
```

Red flags:

| Signal | Fix |
|--------|-----|
| Seq Scan on large table | Add B-tree index |
| Rows Removed by Filter: high | Composite/partial index |
| Buffers: read >> hit | More shared_buffers |
| Sort: external merge | Increase work_mem |
| Nested Loop high loops | Batch/JOIN |
| Hash Join: batches > 1 | Increase work_mem |

Run on prod-like data. Use `FORMAT JSON` for parsing. -> `systematic-debugging` Phase 1 when unclear

### 6.2 pg_stat_statements

```sql
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Top 10 by total time
SELECT calls, round(total_exec_time::numeric, 2) AS total_ms, query
FROM pg_stat_statements ORDER BY total_exec_time DESC LIMIT 10;

-- Slow queries (>100ms avg)
SELECT query, round(mean_exec_time::numeric, 2) AS mean_ms
FROM pg_stat_statements WHERE mean_exec_time > 100 ORDER BY mean_exec_time DESC;
```

### 6.3 VACUUM & ANALYZE

```sql
-- Run ANALYZE after large data changes
ANALYZE orders;
ANALYZE orders (status, created_at); -- specific columns

-- Tune autovacuum for high-churn tables
ALTER TABLE orders SET (
  autovacuum_vacuum_scale_factor = 0.05,   -- vacuum at 5% dead rows (default 20%)
  autovacuum_analyze_scale_factor = 0.02   -- analyze at 2% changes (default 10%)
);

-- Check last maintenance
SELECT relname, last_vacuum, last_autovacuum, last_analyze, last_autoanalyze,
       n_dead_tup, n_live_tup
FROM pg_stat_user_tables ORDER BY n_dead_tup DESC;
```

### 6.4 Table and Index Size

```sql
-- Largest tables
SELECT relname, pg_size_pretty(pg_total_relation_size(relid)) AS total
FROM pg_stat_user_tables ORDER BY pg_total_relation_size(relid) DESC LIMIT 10;

-- Index size vs usage
SELECT indexrelname, idx_scan, pg_size_pretty(pg_relation_size(indexrelid)) AS size
FROM pg_stat_user_indexes ORDER BY pg_relation_size(indexrelid) DESC LIMIT 10;
```

### 6.5 Lock Monitoring

```sql
SELECT blocked.pid, blocked.query, blocking.pid, blocking.query
FROM pg_stat_activity blocked
JOIN pg_locks bl ON bl.pid = blocked.pid
JOIN pg_locks kl ON kl.locktype = bl.locktype AND kl.relation = bl.relation AND kl.pid != bl.pid
JOIN pg_stat_activity blocking ON blocking.pid = kl.pid
WHERE NOT bl.granted;
```

-> `systematic-debugging` Phase 1 for persistent contention

---

## 7. Advanced Query Tuning [MEDIUM]

### 7.1 Full-Text Search (tsvector)

100x faster than LIKE with wildcards.

```sql
ALTER TABLE articles ADD COLUMN search_vector tsvector
  GENERATED ALWAYS AS (
    to_tsvector('english', coalesce(title,'') || ' ' || coalesce(content,''))
  ) STORED;

CREATE INDEX CONCURRENTLY idx ON articles USING gin (search_vector);

SELECT *, ts_rank(search_vector, query) AS rank
FROM articles, to_tsquery('english', 'postgresql & performance') query
WHERE search_vector @@ query ORDER BY rank DESC;
```

For multilingual content, use 'simple' config or create language-specific columns.

### 7.2 JSONB Indexing

```sql
-- GIN for containment queries (@>)
CREATE INDEX CONCURRENTLY idx ON products USING gin (attributes);
SELECT * FROM products WHERE attributes @> '{"color": "red"}';

-- jsonb_path_ops: only @> but 2-3x smaller
CREATE INDEX CONCURRENTLY idx ON products USING gin (attributes jsonb_path_ops);

-- Expression index for specific key lookups (smallest, fastest)
CREATE INDEX CONCURRENTLY idx ON products ((attributes->>'brand'));
```

Choose: jsonb_path_ops for @> queries, expression index for specific key access, full GIN for flexible queries.

-> JSONB indexing strategy -> `supabase-postgres-best-practices` (Rule 7.2)

### 7.3 CTE Optimization

```sql
-- PostgreSQL 12+: CTEs can be inlined (no longer optimization fences)

-- GOOD: inlined CTE (planner can push predicates down)
WITH recent_orders AS (
  SELECT * FROM orders WHERE created_at > now() - interval '7 days'
)
SELECT * FROM recent_orders WHERE status = 'pending';

-- Force materialization when CTE is referenced multiple times
WITH MATERIALIZED summary AS (
  SELECT user_id, count(*) AS order_count FROM orders GROUP BY user_id
)
SELECT * FROM summary WHERE order_count > 10
UNION ALL
SELECT * FROM summary WHERE order_count = 1;
```

---

## Cross-Reference Map

| When you encounter... | Use this skill for... | Use other skill for... |
|-----------------------|----------------------|----------------------|
| Slow query | EXPLAIN ANALYZE, indexing (here) | Root cause investigation -> `systematic-debugging` |
| New table design | - | Schema, naming, types -> `typescript-best-practices` |
| RLS policy slow | Subquery wrapping, SECURITY DEFINER (here) | Policy design (USING/WITH CHECK) -> `supabase-auth-patterns` |
| Index design decision | Composite order, partial, covering (here) | FK indexing as schema rule -> `supabase-postgres-best-practices` (Rule 1.1) |
| Performance fix verified | - | Write regression test -> `testing-strategy` |
| Deadlock investigation | Lock ordering, advisory locks (here) | Phase 1 investigation -> `systematic-debugging` |
| JSONB query slow | GIN index, expression index (here) | JSONB vs column decision -> `supabase-postgres-best-practices` (Rule 7.2) |
| Load/stress testing | pg_stat_statements baselines (here) | Test protocol, execution -> `testing-strategy` |
