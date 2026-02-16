# TypeScript Best Practices — Reference

## A. tsconfig Strict Settings Checklist

```jsonc
// tsconfig.json — minimum strict settings
{
  "compilerOptions": {
    "strict": true,                    // enables all strict flags below
    "noUncheckedIndexedAccess": true,  // array/object index returns T | undefined
    "noImplicitReturns": true,         // every code path must return
    "noFallthroughCasesInSwitch": true,
    "exactOptionalProperties": true,   // distinguishes undefined from missing
    "forceConsistentCasingInFileNames": true,
    "isolatedModules": true,           // required for esbuild/swc
    "moduleResolution": "bundler",     // modern bundler resolution
    "verbatimModuleSyntax": true,       // explicit type imports
    "noUnusedLocals": true,            // error on unused variables
    "noUnusedParameters": true         // error on unused function params
  }
}
```

**Key flags explained:**
- `noUncheckedIndexedAccess`: `arr[0]` is `T | undefined`, forcing null checks
- `exactOptionalProperties`: `{ name?: string }` means `name` is missing or string, NOT `undefined`
- `verbatimModuleSyntax`: requires `import type { Foo }` for type-only imports
- `noUnusedLocals` / `noUnusedParameters`: catches dead code; prefix unused params with `_`

---

## B. Discriminated Union Decision Matrix

| Situation | Pattern | Example |
|-----------|---------|---------|
| 2-5 mutually exclusive states | Discriminated union | `RequestState<T>` with status field |
| State with associated data | Tagged union variants | `{ type: 'text'; content: string } \| { type: 'image'; url: string }` |
| Compile-time string validation | Template literal types | `EventName = \`on${Capitalize<string>}\`` |
| Preventing value interchange | Branded types | `UserId`, `OrderId` |
| Enum-like values needing array | Const assertion + typeof | `ROLES as const` + `typeof ROLES[number]` |
| Complex nested state | Nested discriminated unions | State machine with sub-states |
| Optional but related fields | Discriminated union NOT optional fields | Avoid `{ url?: string; width?: number }` |

### When NOT to use discriminated unions:
- Simple boolean toggles (just use `boolean`)
- Truly independent optional fields
- Performance-critical hot paths (union narrowing has small overhead)

---

## C. Zod Pattern Cookbook

### C-1. Common Schema Patterns

```ts
// Email with normalization
const EmailSchema = z.string().email().transform(s => s.toLowerCase().trim());

// Pagination params
const PaginationSchema = z.object({
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

// Date range validation
const DateRangeSchema = z.object({
  start: z.coerce.date(),
  end: z.coerce.date(),
}).refine(d => d.end > d.start, { message: 'End must be after start' });

// Discriminated union schema
const NotificationSchema = z.discriminatedUnion('type', [
  z.object({ type: z.literal('email'), to: z.string().email() }),
  z.object({ type: z.literal('sms'), phone: z.string().regex(/^\+\d{10,15}$/) }),
  z.object({ type: z.literal('push'), deviceToken: z.string() }),
]);
```

### C-2. Schema Composition Patterns

```ts
// Base -> Create -> Update pattern
const BaseSchema = z.object({ name: z.string().min(1), email: z.string().email() });
const CreateSchema = BaseSchema.extend({ password: z.string().min(8) });
const UpdateSchema = BaseSchema.partial();

// Merge independent schemas
const WithTimestamps = z.object({ createdAt: z.coerce.date(), updatedAt: z.coerce.date() });
const UserRow = BaseSchema.merge(WithTimestamps).extend({ id: z.string().uuid() });

// Pick/Omit for API responses
const PublicUser = UserRow.omit({ password: true });
const UserSummary = UserRow.pick({ id: true, name: true });
```

### C-3. Custom Refinements

```ts
// Password strength
const PasswordSchema = z.string()
  .min(8)
  .refine(s => /[A-Z]/.test(s), 'Must contain uppercase')
  .refine(s => /[0-9]/.test(s), 'Must contain number')
  .refine(s => /[^A-Za-z0-9]/.test(s), 'Must contain special character');

// Cross-field validation
const FormSchema = z.object({
  password: z.string().min(8),
  confirmPassword: z.string(),
}).refine(d => d.password === d.confirmPassword, {
  message: 'Passwords must match',
  path: ['confirmPassword'],
});
```

---

## D. Utility Type Cheat Sheet

### D-1. Built-in Types

```ts
// Object manipulation
type UserUpdate = Partial<User>;          // all optional
type RequiredUser = Required<User>;        // all required
type NameEmail = Pick<User, 'name' | 'email'>;
type WithoutId = Omit<User, 'id'>;
type ImmutableUser = Readonly<User>;

// Union manipulation
type ActiveOrSuspended = Extract<Status, 'active' | 'suspended'>;
type NotArchived = Exclude<Status, 'archived'>;
type DefinitelyUser = NonNullable<User | null | undefined>;

// Function type extraction
type FetchReturn = ReturnType<typeof fetchUser>;     // Promise<User>
type FetchArgs = Parameters<typeof fetchUser>;       // [id: string]
type ResolvedUser = Awaited<ReturnType<typeof fetchUser>>; // User

// Index types
type UserKeys = keyof User;                          // 'id' | 'name' | 'email'
type NameType = User['name'];                        // string
type RoleMap = Record<Role, Permission[]>;
```

### D-2. Custom Utility Recipes

```ts
// Make specific fields required
type WithRequired<T, K extends keyof T> = T & Required<Pick<T, K>>;
type UserWithEmail = WithRequired<Partial<User>, 'email'>;

// Make specific fields optional
type WithOptional<T, K extends keyof T> = Omit<T, K> & Partial<Pick<T, K>>;

// Deep readonly
type DeepReadonly<T> = { readonly [K in keyof T]: T[K] extends object ? DeepReadonly<T[K]> : T[K] };

// Strict omit (errors on invalid keys)
type StrictOmit<T, K extends keyof T> = Omit<T, K>;
```

---

## E. Code Review Checklist

### Types
- [ ] `strict: true` in tsconfig
- [ ] No `any` (use `unknown` + narrowing)
- [ ] No type assertions (`as`) except branded type constructors
- [ ] Discriminated unions for mutually exclusive states
- [ ] Exhaustive switch with `never` default

### Functions
- [ ] Return types explicit on exported functions
- [ ] Pure functions for business logic
- [ ] `const` over `let`; no `var`
- [ ] Edge cases handled: empty arrays, null, undefined, boundary values

### Validation
- [ ] Zod schemas at system boundaries (API, user input, env vars)
- [ ] `safeParse` for user input, `parse` for trust boundaries
- [ ] Types inferred from schemas (`z.infer<>`)

### Modules
- [ ] One concern per file
- [ ] Feature-grouped, not type-grouped
- [ ] Tests colocated (`foo.test.ts`)
- [ ] No circular imports

### Async
- [ ] All promises awaited or explicitly fire-and-forget
- [ ] External calls wrapped with contextual error messages
- [ ] No unhandled rejections

### Boundaries (see `security-review` for audit)
- [ ] Zod validation at every trust boundary (API input, env vars, external data)
- [ ] Type guards narrow `unknown` before use (never trust unvalidated casts)
