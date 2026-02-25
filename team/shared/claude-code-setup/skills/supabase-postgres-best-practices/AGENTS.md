# Supabase Postgres Best Practices

## Structure

```
supabase-postgres-best-practices/
  SKILL.md       # Main skill file - read this first
  reference.md   # Detailed rules with SQL examples
  {category}-{rule}.md  # Individual rule files (flat structure)
```

## Usage

1. Read `SKILL.md` for categorized best practices with inline examples
2. Read `reference.md` for detailed rules with incorrect/correct SQL, EXPLAIN output, and diagnostics
3. Browse individual `{category}-{rule}.md` files if you need a single topic

## Rule File Naming

Individual rule files follow the pattern `{category}-{rule}.md`:

- `query-*`: Indexing and query optimization (CRITICAL)
- `conn-*`: Connection pooling and management (CRITICAL)
- `security-*`: RLS and privilege patterns (CRITICAL)
- `schema-*`: Schema design and migrations (HIGH)
- `lock-*`: Concurrency and locking (HIGH)
- `data-*`: Data access patterns (MEDIUM)
- `monitor-*`: Monitoring and diagnostics (MEDIUM)
- `advanced-*`: Full-text search, JSONB (LOW)
