---
name: typescript-best-practices
description: "Apply advanced TypeScript patterns including discriminated unions, branded types, exhaustive switch, generics, type narrowing, utility types, and Zod schema-driven validation for robust type-safe codebases. Use when writing type-safe code, designing discriminated union hierarchies, creating branded types for domain safety, implementing exhaustive pattern matching, leveraging generics and conditional types, narrowing unknown inputs with type guards, deriving types from Zod schemas, or reviewing TypeScript code for type safety issues. Do not trigger for React component patterns (use react-component-patterns) or testing patterns (use testing-strategy)."
user-invocable: false
---

# TypeScript Best Practices

## Scope & Cross-references

| Topic | This Skill | Other Skill |
|-------|-----------|-------------|
| React component types/props | - | `react-component-patterns` (typed props, generic components) |
| Error classes, logging, Sentry | - | `error-handling-logging` (AppError hierarchy) |
| Type-safe test helpers | - | `testing-strategy` (typed mocks, assertion patterns) |
| Type-safe input validation auditing | - | `security-review` (Zod + type guards at trust boundaries) |
| Supabase typed queries | - | `supabase-postgres-best-practices` (typed DB access) |

**Boundary**: This skill covers language-level TypeScript type patterns only. Framework-specific typing (React, Next.js, Supabase) lives in dedicated skills.

---

## Part 1: Type-First Development [CRITICAL]

Design types before implementation. The compiler enforces completeness.

**Workflow**: Define data model -> Define function signatures -> Implement to satisfy types -> Validate at boundaries

### 1. Discriminated Unions

Model mutually exclusive states so invalid combinations are impossible.

```ts
// GOOD: type RequestState<T> = { status: 'idle' } | { status: 'loading' }
//   | { status: 'success'; data: T } | { status: 'error'; error: Error };
// BAD: { loading: boolean; data?: T; error?: Error } allows invalid combos
```

### 2. Branded Types

Prevent accidental value interchange at compile time.

```ts
type UserId = string & { readonly __brand: 'UserId' };
type OrderId = string & { readonly __brand: 'OrderId' };
function createUserId(id: string): UserId { return id as UserId; }
// getUser(orderId) -> compile error
```

### 3. Const Assertions & Literal Unions

Keep arrays and their derived types in sync.

```ts
const ROLES = ['admin', 'user', 'guest'] as const;
type Role = typeof ROLES[number]; // 'admin' | 'user' | 'guest'
function isValidRole(role: string): role is Role { return ROLES.includes(role as Role); }
```

### 4. Required vs Optional — Be Explicit

```ts
type CreateUser = { email: string; name: string };
type UpdateUser = Partial<CreateUser>;
type User = CreateUser & { id: UserId; createdAt: Date };
```

---

## Part 2: Exhaustive Handling & Type Narrowing [CRITICAL]

### 5. Exhaustive Switch with `never`

Unhandled union members become compile errors.

```ts
type Status = 'active' | 'inactive' | 'suspended';
function label(s: Status): string {
  switch (s) { case 'active': return 'Active'; /* ...other cases... */
    default: const _: never = s; throw new Error(`Unhandled: ${_}`); }
}
```

### 6. Type Narrowing Patterns

```ts
function isError(result: Result): result is ErrorResult { return result.type === 'error'; }
function handle(e: MouseEvent | KeyboardEvent) { if ('key' in e) { /* Keyboard */ } }
function assertDefined<T>(val: T | undefined, msg: string): asserts val is T {
  if (val === undefined) throw new Error(msg);
}
```

### 7. Template Literal Types

Enforce string format at compile time.

```ts
type EventName = `on${Capitalize<string>}`;
type CSSUnit = `${number}${'px' | 'rem' | 'em' | '%'}`;
type APIRoute = `/api/${string}`;
```

---

## Part 3: Generics & Utility Types [HIGH]

### 8. Constrained Generics

```ts
function findById<T extends { id: string }>(items: T[], id: string): T | undefined {
  return items.find(item => item.id === id);
}
function pick<T, K extends keyof T>(obj: T, keys: K[]): Pick<T, K> { /* ... */ }
```

### 9. Essential Utility Types

| Utility | Use Case |
|---------|----------|
| `Partial<T>` | Update/patch operations |
| `Required<T>` | Ensure all fields present |
| `Pick<T, K>` / `Omit<T, K>` | Select/exclude fields |
| `Record<K, V>` | Typed dictionaries |
| `Extract<T, U>` / `Exclude<T, U>` | Filter union members |
| `NonNullable<T>` | Remove null/undefined |
| `ReturnType<F>` / `Parameters<F>` | Infer from functions |
| `Awaited<T>` | Unwrap Promise types |
| `Readonly<T>` | Immutable data |
| `satisfies` operator | Validate type without widening |

```ts
// satisfies: validate shape, keep literal types
const config = { endpoint: '/api/v1', timeout: 5000 } satisfies Record<string, string | number>;
// typeof config.endpoint is '/api/v1', not string
```

### 10. Mapped & Conditional Types

```ts
type Nullable<T> = { [K in keyof T]: T[K] | null };
type AsyncReturnType<T extends (...args: any[]) => Promise<any>> =
  T extends (...args: any[]) => Promise<infer R> ? R : never;
type ApiResponse<T> = T extends undefined ? { success: true } : { success: true; data: T };
```

---

## Part 4: Runtime Validation with Zod [HIGH]

Schema as single source of truth; infer TypeScript types with `z.infer<>`.

### 11. Schema Definition & Type Inference

```ts
import { z } from 'zod';
const UserSchema = z.object({ id: z.string().uuid(), email: z.string().email(),
  name: z.string().min(1), createdAt: z.string().transform(s => new Date(s)) });
type User = z.infer<typeof UserSchema>;
```

### 12. safeParse vs parse

- `safeParse`: User input where failure is expected -> returns `{ success, data?, error? }`
- `parse`: Trust boundaries where invalid data is a bug -> throws on failure

```ts
// User input: const result = UserSchema.safeParse(rawInput);
// if (!result.success) return result.error.flatten().fieldErrors;
// Trust boundary: const user = UserSchema.parse(apiResponse); // throws ZodError
```

### 13. Schema Composition

```ts
const CreateUserSchema = UserSchema.omit({ id: true, createdAt: true });
const UpdateUserSchema = CreateUserSchema.partial();
const UserWithPostsSchema = UserSchema.extend({ posts: z.array(PostSchema) });
```

### 14. Typed Configuration

Validate env vars at startup with Zod. Invalid config crashes immediately.

```ts
const ConfigSchema = z.object({
  PORT: z.coerce.number().default(3000), DATABASE_URL: z.string().url(),
  API_KEY: z.string().min(1), NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
});
export const config = ConfigSchema.parse(process.env); // crashes on invalid config
```

---

## Part 5: Code Style & Module Design [MEDIUM]

### 15. Functional Patterns

- Prefer `const` over `let`; use `readonly` and `Readonly<T>` for immutable data
- Use `array.map/filter/reduce` over `for` loops; chain transformations
- Write pure functions for business logic; isolate side effects
- Never mutate function parameters; return new objects/arrays

### 16. Module Structure

- One component, hook, or utility per file
- Split when a file exceeds ~200 lines or handles multiple concerns
- Colocate tests: `foo.test.ts` alongside `foo.ts`
- Group by feature, not by type

### 17. Strict Mode Rules

- Enable `strict: true` in tsconfig — non-negotiable
- Every code path returns a value or throws
- Handle edge cases explicitly: empty arrays, null/undefined, boundary values
- Use `await` for async calls; wrap external calls with contextual error messages

---

## Part 6: Advanced Patterns [MEDIUM]

### 18. type-fest Utilities

For patterns beyond TS builtins, consider [type-fest](https://github.com/sindresorhus/type-fest):

- `Opaque<T, Token>` — cleaner branded types
- `PartialDeep<T>` — recursive partial for nested objects
- `SetRequired<T, K>` / `SetOptional<T, K>` — targeted field modifications
- `Simplify<T>` — flatten intersection types in IDE tooltips

### 19. Result Pattern (Alternative to throw)

```ts
type Result<T, E = Error> = { ok: true; value: T } | { ok: false; error: E };
function divide(a: number, b: number): Result<number, string> {
  if (b === 0) return { ok: false, error: 'Division by zero' };
  return { ok: true, value: a / b };
}
```

Use Result for recoverable errors in pure functions. Use throw for unrecoverable programmer errors.

---

## Decision Tree

型の選択 → 複数状態の排他表現？ → Discriminated Union / 値の取り違え防止？ → Branded Types / 網羅性保証？ → Exhaustive switch + never / 外部入力？ → Zod safeParse / 内部信頼境界？ → Zod parse

ユーティリティ型 → フィールド選択？ → Pick/Omit / 部分更新？ → Partial / 辞書型？ → Record / Union絞り込み？ → Extract/Exclude / Promise展開？ → Awaited

## Checklist

- [ ] `strict: true` が tsconfig で有効
- [ ] 排他的状態は discriminated union で表現
- [ ] switch文に exhaustive check（`never`）がある
- [ ] 外部入力は Zod `safeParse` でバリデーション
- [ ] 関数パラメータを直接変更していない（immutable）
- [ ] `any` を使っていない（`unknown` + 型ガード）
- [ ] 全コードパスが値を返すか throw する

## Quick Reference

See [reference.md](reference.md) for: tsconfig strict settings checklist, Zod pattern cookbook, utility type cheat sheet, discriminated union decision matrix, and code review checklist.

## Cross-references

- **react-component-patterns**: コンポーネント Props 型設計・CVA variant 型・asChild 型パターン
- **testing-strategy**: テスト内の型安全性・Vitest の型付きモック
- **error-handling-logging**: Result 型パターン・AppError discriminated union
- **code-review**: 型安全性の判断基準・レビュー観点
- **security-review**: 型不備→セキュリティ穴の検出連携
- **context-economy**: TokenGuardian 型定義・MCP ツール型
- **supabase-postgres-best-practices**: Zod スキーマ→DB 型の整合性
