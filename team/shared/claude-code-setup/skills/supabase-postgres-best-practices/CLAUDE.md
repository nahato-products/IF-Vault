# Supabase Postgres Best Practices

## Structure

```
supabase-postgres-best-practices/
  SKILL.md       # Main skill file - read this first
  reference.md   # Detailed rules with SQL examples
```

## Usage

1. Read `SKILL.md` for categorized best practices with inline examples and decision guide
2. Read `reference.md` for detailed rules with incorrect/correct SQL, EXPLAIN output, and diagnostics

## Category Map

- `Category 1 (Query Performance)`: Indexing, composite order, index types, partial/covering [CRITICAL]
- `Category 2 (Connection Management)`: Supavisor pooling, timeouts, Edge Functions [CRITICAL]
- `Category 3 (RLS Performance)`: Subquery caching, SECURITY DEFINER, index policies [CRITICAL]
- `Category 4 (Concurrency)`: Short transactions, deadlocks, SKIP LOCKED, advisory locks [HIGH]
- `Category 5 (Data Access)`: N+1, cursor pagination, batch inserts, UPSERT [HIGH]
- `Category 6 (Monitoring)`: EXPLAIN ANALYZE, pg_stat_statements, VACUUM, lock monitoring [HIGH]
- `Category 7 (Advanced)`: Full-text search, JSONB indexing, CTE optimization [MEDIUM]

## Scope

This skill covers QUERY PERFORMANCE and RUNTIME operations only. For auth/RLS policy design -> `supabase-auth-patterns`.
