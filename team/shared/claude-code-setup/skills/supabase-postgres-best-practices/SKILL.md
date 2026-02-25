---
name: supabase-postgres-best-practices
description: "Optimize Supabase Postgres performance with indexing strategies, EXPLAIN ANALYZE diagnostics, Supavisor connection pooling, RLS query optimization, N+1 prevention, cursor/offset pagination, and VACUUM maintenance. Use when tuning query performance, analyzing slow queries, configuring connection pooling, optimizing RLS policies, or diagnosing database issues."
user-invocable: false
---

# Supabase Postgres Best Practices

Postgres query performance and runtime optimization for Supabase projects. Focus: making queries fast, connections efficient, and RLS performant at runtime.

## Scope & Boundaries

| Topic | This Skill | Other Skill |
|-------|-----------|-------------|
| Query optimization, indexing, EXPLAIN | **Here** | - |
| Connection pooling (Supavisor), timeouts | **Here** | - |
| RLS **performance** (subquery caching, index) | **Here** | `supabase-auth-patterns` (RLS policy design, auth flows) |
| Concurrency, locking, queues | **Here** | - |
| Monitoring (pg_stat_*, VACUUM) | **Here** | - |
| Unused index detection, index maintenance | **Here** | - |
| Full-text search, JSONB query tuning | **Here** | - |
| Edge Function DB connections | **Here** | - |
| Schema design (naming, types, constraints, FK) | - | `supabase-postgres-best-practices` (reference.md) |
| Auth flows, session management, RLS creation | - | `supabase-auth-patterns` |
| Query performance debugging process | - | `systematic-debugging` (Phase 1 investigation) |
| Load testing, regression test for perf fixes | - | `testing-strategy` (test protocol) |

## When to Apply

- Writing or reviewing SQL queries for performance
- Adding, optimizing, or removing unused indexes
- Diagnosing slow queries with EXPLAIN ANALYZE
- Configuring connection pooling (Supavisor)
- Optimizing RLS policies that cause slowdowns
- Implementing concurrent processing (queues, locks)
- Bulk data loading or cursor pagination
- Profiling with pg_stat_statements
- Setting statement_timeout / idle timeouts
- Connecting from Edge Functions or serverless environments

## When NOT to Apply

- Table design, naming conventions, data types, FK policies -> `typescript-best-practices`
- Auth flows, RLS policy creation, JWT handling -> `supabase-auth-patterns`
- Root cause investigation process for query issues -> `systematic-debugging`
- Writing regression tests after performance fix -> `testing-strategy`
- Application-level error handling -> `error-handling-logging`

---

## Category 1: Query Performance [CRITICAL]

### Index Missing WHERE/JOIN Columns

Unindexed columns cause full table scans (100-1000x slower on large tables). Always index columns used in WHERE and JOIN. Use `CREATE INDEX CONCURRENTLY` in production to avoid blocking writes. Verify with `EXPLAIN` that Index Scan is used (not Seq Scan).

-> Full examples with EXPLAIN output and FK index detection: [reference.md](reference.md) Section 1.1

### Composite Index Column Order

Equality columns first, range columns last. Leftmost prefix rule applies.

```sql
-- Good: status (=) before created_at (>)
CREATE INDEX idx ON orders (status, created_at);
-- Works for: WHERE status = 'pending'
-- Works for: WHERE status = 'pending' AND created_at > '2024-01-01'
-- Does NOT work for: WHERE created_at > '2024-01-01' alone
```

### Choose Index Type by Query Pattern

- **B-tree** (default): `=, <, >, BETWEEN, IN` -- general purpose
- **GIN**: JSONB `@>`, arrays, full-text `@@`
- **GiST**: geometric, range types, KNN `<->`
- **BRIN**: large time-series (10-100x smaller, requires physically correlated data)

-> Type comparison table and CREATE INDEX examples: [reference.md](reference.md) Section 1.3

### Partial & Covering Indexes

- **Partial**: index only rows you query (5-20x smaller). Query WHERE must match index WHERE.
- **Covering (INCLUDE)**: add non-key columns to enable index-only scans (2-5x faster).

-> Syntax and examples: [reference.md](reference.md) Sections 1.4, 1.5

### Detect & Remove Unused Indexes

Unused indexes waste disk and slow writes. Check periodically.

```sql
-- Find unused indexes (wait 2+ weeks of data before dropping)
SELECT indexrelname, idx_scan, pg_size_pretty(pg_relation_size(i.indexrelid))
FROM pg_stat_user_indexes i JOIN pg_index USING (indexrelid)
WHERE idx_scan = 0 AND NOT indisunique ORDER BY pg_relation_size(i.indexrelid) DESC;
```

-> Full details with EXPLAIN output: [reference.md](reference.md)
-> Index naming conventions and FK indexing rules -> `supabase-postgres-best-practices` (reference.md Section 1.1)

---

## Category 2: Connection Management [CRITICAL]

### Connection Pooling (Supavisor)

Each Postgres connection uses 1-3MB RAM. Always pool. Supabase uses Supavisor.

```
-- Pool size formula: (CPU cores * 2) + spindle_count
-- 4 cores -> pool_size = 10

-- Transaction mode (port 6543): connection returned after each transaction (default, best)
-- Session mode (port 5432): needed for prepared statements, LISTEN/NOTIFY, temp tables
```

### Connection Limits & Timeouts

Key settings: `max_connections = 100`, `work_mem = '8MB'` (max_connections * work_mem < 25% RAM), `statement_timeout = '30s'`, `idle_in_transaction_session_timeout = '30s'`

Monitor: `SELECT count(*), state FROM pg_stat_activity GROUP BY state;`

-> Full configuration examples: [reference.md](reference.md) Section 2.2

### Prepared Statements with Pooling

Named prepared statements break in transaction-mode pooling. Use unnamed statements or deallocate after use.

### Edge Function Connections [CRITICAL]

Edge Functions are short-lived and create many connections. Always use Supavisor pooling. Prefer supabase-js REST for simple CRUD (no connection management needed). For direct Postgres, always use pooler URL (port 6543) and close connections when done.

-> Code examples (supabase-js and direct postgres): [reference.md](reference.md) Section 2.5

---

## Category 3: RLS Performance [CRITICAL]

### Wrap Functions in Subquery

`auth.uid()` called per-row is 100x slower than cached in subquery.

```sql
-- BAD: USING (auth.uid() = user_id)
-- GOOD: USING ((SELECT auth.uid()) = user_id)
```

Full example: see [reference.md](reference.md)

### Security Definer for Complex Checks

```sql
-- BAD: complex JOIN inside RLS policy directly
-- GOOD: SECURITY DEFINER function wrapping the check
CREATE POLICY p ON orders USING ((SELECT is_team_member(team_id)));
```

Full example: see [reference.md](reference.md). Always index columns used in RLS policies.

-> RLS policy design and auth patterns -> `supabase-auth-patterns`
-> Debugging slow RLS queries: use `systematic-debugging` Phase 1 with EXPLAIN ANALYZE

---

## Category 4: Concurrency & Locking [HIGH]

### Short Transactions

Move external calls (HTTP, payment APIs) outside transactions. Set `statement_timeout` as safety net.

```sql
-- Per-session safety net
SET statement_timeout = '10s';
```

### Deadlock Prevention

Acquire locks in consistent order (e.g., by ID ascending).

```sql
SELECT * FROM accounts WHERE id IN (1, 2) ORDER BY id FOR UPDATE;
```

### SKIP LOCKED Queue Pattern

```sql
-- SELECT ... FOR UPDATE SKIP LOCKED in subquery, UPDATE in outer query
-- Prevents worker contention on job queues
```

Full example: see [reference.md](reference.md)

-> Advisory locks, deadlock detection: [reference.md](reference.md)

---

## Category 5: Data Access Patterns [HIGH]

### Eliminate N+1 Queries

```sql
-- BAD: SELECT * FROM orders WHERE user_id = 1; -- ... N times
-- GOOD: SELECT * FROM orders WHERE user_id = ANY($1::bigint[]);
```

### Cursor Pagination (not OFFSET)

```sql
-- OFFSET scans all skipped rows. Cursor is O(1).
SELECT * FROM products WHERE id > $last_id ORDER BY id LIMIT 20;
```

### Batch Inserts & UPSERT

```sql
-- Batch: INSERT INTO events (user_id, action) VALUES (1,'click'), (2,'view'), ...;
-- UPSERT: INSERT INTO settings (...) VALUES (...) ON CONFLICT (user_id, key) DO UPDATE SET value = EXCLUDED.value;
```

-> UPSERT conflict target design -> `supabase-postgres-best-practices` (reference.md Section 5.4)
-> After fixing N+1, write regression test to prevent recurrence -> `testing-strategy`

---

## Category 6: Monitoring & Diagnostics [HIGH]

### EXPLAIN ANALYZE

```sql
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT) SELECT ...;
-- Look for: Seq Scan (missing index), Rows Removed by Filter (poor selectivity)
-- Buffers read >> hit (cold cache), Sort external merge (work_mem too low)
```

### pg_stat_statements

`pg_stat_statements` で実行時間Top-Nクエリ特定。最適化後はstatsリセット。→ [reference.md](reference.md) Section 6.2

### VACUUM & ANALYZE

大量データ変更後は `ANALYZE` 実行。高頻度更新テーブルは autovacuum scale factor を 5%/2% に。→ [reference.md](reference.md) Sections 6.3, 6.4

---

## Cross-references [MEDIUM]

- **supabase-auth-patterns**: RLSポリシーの設計・認証フロー（本スキルはRLSのパフォーマンス面を担当）
- **typescript-best-practices**: 型設計・命名規則（DB型のTypeScript表現）
- **security-review**: SQLインジェクション・RLS未設定テーブル・クエリ経由の情報漏洩監査

## Checklist

- [ ] 全WHERE/JOIN対象カラムにインデックス設定済み
- [ ] RLSポリシーで `(SELECT auth.uid())` サブクエリ使用
- [ ] コネクションプーリング（Supavisor）設定済み
- [ ] `statement_timeout` 設定済み
- [ ] 未使用インデックスの定期チェック体制あり
- [ ] EXPLAIN ANALYZEでSeq Scan排除確認済み
- [ ] Edge Functionからのアクセスはpooler URL使用

## Decision Tree

1. **Query slow?** -> `EXPLAIN (ANALYZE, BUFFERS)`: Seq Scan = add index (Cat 1), Nested Loop = N+1 (Cat 5), Sort external merge = work_mem, Rows Removed = partial/composite index
2. **RLS slow?** -> Wrap `auth.uid()` in subquery (Cat 3)
3. **Connection errors?** -> Pooling config (Cat 2)
4. **Lock waits?** -> Shorten transactions (Cat 4)
5. **Find slowest queries?** -> `pg_stat_statements` (Cat 6)
6. **Unused indexes?** -> `pg_stat_user_indexes` (Cat 1)
7. **Can't find root cause?** -> `systematic-debugging` Phase 1
8. **After fix?** -> `testing-strategy` (load test)

## Cross-references

- **supabase-auth-patterns**: RLS ポリシー設計・auth bypass 検出
- **typescript-best-practices**: Zod スキーマ→DB 型の整合性
- **security-review**: SQL インジェクション・RLS バイパス検出
- **systematic-debugging**: クエリパフォーマンス問題の根本原因調査
- **testing-strategy**: 負荷テスト・DB マイグレーションテスト
