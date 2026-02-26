---
name: typescript-best-practices
description: "Use when writing, reviewing, refactoring, designing, or auditing TypeScript type patterns. Covers discriminated unions, branded types, exhaustive switch with never, constrained generics, type narrowing, assertion functions, mapped and conditional types, template literal types, utility type composition (Pick/Omit/Partial/Record/Extract/Exclude/satisfies), Zod runtime validation (safeParse, schema composition, z.infer), typed configuration, and functional immutability. Does NOT cover React props (react-component-patterns), error classes (error-handling-logging), test patterns (testing-strategy), typed queries (supabase-postgres-best-practices), or input validation auditing (security-review)."
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
// GOOD: only valid combinations exist
type RequestState<T> =
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'success'; data: T }
  | { status: 'error'; error: Error };

// BAD: allows { loading: true, error: Error }
type RequestState<T> = { loading: boolean; data?: T; error?: Error };
```

### 2. Branded Types

Prevent accidental value interchange at compile time.

```ts
type UserId = string & { readonly __brand: 'UserId' };
type OrderId = string & { readonly __brand: 'OrderId' };

function createUserId(id: string): UserId { return id as UserId; }
function getUser(id: UserId): Promise<User> { /* ... */ }
// getUser(orderId) -> compile error
```

### 3. Const Assertions & Literal Unions

Keep arrays and their derived types in sync.

```ts
const ROLES = ['admin', 'user', 'guest'] as const;
type Role = typeof ROLES[number]; // 'admin' | 'user' | 'guest'

function isValidRole(role: string): role is Role {
  return ROLES.includes(role as Role);
}
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

function label(status: Status): string {
  switch (status) {
    case 'active': return 'Active';
    case 'inactive': return 'Inactive';
    case 'suspended': return 'Suspended';
    default: {
      const _exhaustive: never = status;
      throw new Error(`Unhandled status: ${_exhaustive}`);
    }
  }
}
```

### 6. Type Narrowing Patterns

```ts
// Type guard function
function isError(result: Result): result is ErrorResult {
  return result.type === 'error';
}

// in operator narrowing
function handle(event: MouseEvent | KeyboardEvent) {
  if ('key' in event) { /* KeyboardEvent */ }
  else { /* MouseEvent */ }
}

// Assertion function
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
// Constrain to objects with id
function findById<T extends { id: string }>(items: T[], id: string): T | undefined {
  return items.find(item => item.id === id);
}

// Constrain keys
function pick<T, K extends keyof T>(obj: T, keys: K[]): Pick<T, K> {
  const result = {} as Pick<T, K>;
  keys.forEach(k => { result[k] = obj[k]; });
  return result;
}
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
// satisfies: validate shape while keeping literal types
const config = {
  endpoint: '/api/v1',
  timeout: 5000,
} satisfies Record<string, string | number>;
// typeof config.endpoint is '/api/v1', not string
```

### 10. Mapped & Conditional Types

```ts
// Make all properties optional and nullable
type Nullable<T> = { [K in keyof T]: T[K] | null };

// Extract async function return types
type AsyncReturnType<T extends (...args: any[]) => Promise<any>> =
  T extends (...args: any[]) => Promise<infer R> ? R : never;

// Conditional type for API responses
type ApiResponse<T> = T extends undefined ? { success: true } : { success: true; data: T };
```

---

## Part 4: Runtime Validation with Zod [HIGH]

Schema as single source of truth; infer TypeScript types with `z.infer<>`.

### 11. Schema Definition & Type Inference

```ts
import { z } from 'zod';

const UserSchema = z.object({
  id: z.string().uuid(),
  email: z.string().email(),
  name: z.string().min(1),
  createdAt: z.string().transform(s => new Date(s)),
});
type User = z.infer<typeof UserSchema>;
```

### 12. safeParse vs parse

- `safeParse`: User input where failure is expected -> returns `{ success, data?, error? }`
- `parse`: Trust boundaries where invalid data is a bug -> throws on failure

```ts
// User input: handle gracefully
const result = UserSchema.safeParse(rawInput);
if (!result.success) { return result.error.flatten().fieldErrors; }

// API boundary: invalid data = contract violation
const user = UserSchema.parse(apiResponse); // throws ZodError
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
  PORT: z.coerce.number().default(3000),
  DATABASE_URL: z.string().url(),
  API_KEY: z.string().min(1),
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
});
export const config = ConfigSchema.parse(process.env);

// Access config values (never process.env directly)
const server = app.listen(config.PORT);
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
type Result<T, E = Error> =
  | { ok: true; value: T }
  | { ok: false; error: E };

function divide(a: number, b: number): Result<number, string> {
  if (b === 0) return { ok: false, error: 'Division by zero' };
  return { ok: true, value: a / b };
}
```

Use Result for recoverable errors in pure functions. Use throw for unrecoverable programmer errors.

---

## Quick Reference

See [reference.md](reference.md) for: tsconfig strict settings checklist, Zod pattern cookbook, utility type cheat sheet, discriminated union decision matrix, and code review checklist.
