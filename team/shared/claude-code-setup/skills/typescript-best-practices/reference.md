# TypeScript Best Practices — Reference

## A. tsconfig Strict Settings

```jsonc
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,  // array[0] returns T | undefined
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "exactOptionalProperties": true,
    "forceConsistentCasingInFileNames": true,
    "isolatedModules": true,
    "moduleResolution": "bundler",
    "verbatimModuleSyntax": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true
  }
}
```

**重要フラグ:**
- `noUncheckedIndexedAccess`: `arr[0]` は `T | undefined`、null チェック強制
- `exactOptionalProperties`: `{ name?: string }` は `name` が欠落または string（`undefined` 不可）
- `verbatimModuleSyntax`: `import type { Foo }` を明示的に要求

---

## B. Discriminated Union 判断マトリクス

| 状況 | パターン | 例 |
|------|---------|---|
| 2-5の相互排他状態 | Discriminated union | `RequestState<T>` with status field |
| 関連データ付き状態 | Tagged union variants | `{ type: 'text'; content: string } \| { type: 'image'; url: string }` |
| コンパイル時文字列検証 | Template literal types | `EventName = \`on${Capitalize<string>}\`` |
| 値の取り違え防止 | Branded types | `UserId`, `OrderId` |
| 配列が必要な Enum 風 | Const assertion + typeof | `ROLES as const` + `typeof ROLES[number]` |
| 複雑ネスト状態 | Nested discriminated unions | State machine with sub-states |

**使わない場合:**
- 単純な boolean トグル
- 本当に独立したオプションフィールド
- パフォーマンスクリティカルなホットパス

---

## C. Zod パターン集

### C-1. 共通スキーマ

```ts
// Email 正規化
const EmailSchema = z.string().email().transform(s => s.toLowerCase().trim());

// ページネーション
const PaginationSchema = z.object({
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

// 日付範囲検証
const DateRangeSchema = z.object({
  start: z.coerce.date(),
  end: z.coerce.date(),
}).refine(d => d.end > d.start, { message: 'End must be after start' });

// Discriminated union
const NotificationSchema = z.discriminatedUnion('type', [
  z.object({ type: z.literal('email'), to: z.string().email() }),
  z.object({ type: z.literal('sms'), phone: z.string().regex(/^\+\d{10,15}$/) }),
  z.object({ type: z.literal('push'), deviceToken: z.string() }),
]);
```

### C-2. スキーマ合成

```ts
// Base -> Create -> Update パターン
const BaseSchema = z.object({ name: z.string().min(1), email: z.string().email() });
const CreateSchema = BaseSchema.extend({ password: z.string().min(8) });
const UpdateSchema = BaseSchema.partial();

// 独立スキーマをマージ
const WithTimestamps = z.object({ createdAt: z.coerce.date(), updatedAt: z.coerce.date() });
const UserRow = BaseSchema.merge(WithTimestamps).extend({ id: z.string().uuid() });

// API レスポンス用に Pick/Omit
const PublicUser = UserRow.omit({ password: true });
const UserSummary = UserRow.pick({ id: true, name: true });
```

### C-3. カスタム Refinements

```ts
// パスワード強度
const PasswordSchema = z.string()
  .min(8)
  .refine(s => /[A-Z]/.test(s), 'Must contain uppercase')
  .refine(s => /[0-9]/.test(s), 'Must contain number')
  .refine(s => /[^A-Za-z0-9]/.test(s), 'Must contain special character');

// クロスフィールド検証
const FormSchema = z.object({
  password: z.string().min(8),
  confirmPassword: z.string(),
}).refine(d => d.password === d.confirmPassword, {
  message: 'Passwords must match',
  path: ['confirmPassword'],
});
```

---

## D. Utility Type チートシート

### D-1. 組み込み型

```ts
// オブジェクト操作
type UserUpdate = Partial<User>;
type RequiredUser = Required<User>;
type NameEmail = Pick<User, 'name' | 'email'>;
type WithoutId = Omit<User, 'id'>;
type ImmutableUser = Readonly<User>;

// Union 操作
type ActiveOrSuspended = Extract<Status, 'active' | 'suspended'>;
type NotArchived = Exclude<Status, 'archived'>;
type DefinitelyUser = NonNullable<User | null | undefined>;

// 関数型抽出
type FetchReturn = ReturnType<typeof fetchUser>;
type FetchArgs = Parameters<typeof fetchUser>;
type ResolvedUser = Awaited<ReturnType<typeof fetchUser>>;

// インデックス型
type UserKeys = keyof User;
type NameType = User['name'];
type RoleMap = Record<Role, Permission[]>;
```

### D-2. カスタム Utility

```ts
// 特定フィールドを必須化
type WithRequired<T, K extends keyof T> = T & Required<Pick<T, K>>;
type UserWithEmail = WithRequired<Partial<User>, 'email'>;

// 特定フィールドをオプション化
type WithOptional<T, K extends keyof T> = Omit<T, K> & Partial<Pick<T, K>>;

// Deep readonly
type DeepReadonly<T> = { readonly [K in keyof T]: T[K] extends object ? DeepReadonly<T[K]> : T[K] };

// Strict omit（無効キーでエラー）
type StrictOmit<T, K extends keyof T> = Omit<T, K>;
```

---

## E. コードレビューチェックリスト

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

### Boundaries
- [ ] Zod validation at every trust boundary
- [ ] Type guards narrow `unknown` before use

---

## F. Conditional & Mapped Type パターン

```ts
// 文字列キーのみ抽出
type StringKeys<T> = { [K in keyof T]: T[K] extends string ? K : never }[keyof T];

// 特定フィールドを必須化
type WithRequired<T, K extends keyof T> = T & Required<Pick<T, K>>;

// Deep partial
type DeepPartial<T> = { [K in keyof T]?: T[K] extends object ? DeepPartial<T[K]> : T[K] };

// Async 関数の戻り値型を推論
type AsyncReturnType<T extends (...args: any[]) => Promise<any>> =
  T extends (...args: any[]) => Promise<infer R> ? R : never;

// 条件で Union をフィルタ
type FilterByProp<T, K extends string, V> = T extends Record<K, V> ? T : never;
```

---

## G. Template Literal Type パターン

```ts
// イベントハンドラ名
type EventHandler = `on${Capitalize<string>}`;

// CSS プロパティ with unit
type CSSLength = `${number}${'px' | 'rem' | 'em' | '%' | 'vh' | 'vw'}`;

// API ルートパス
type APIRoute = `/api/v${1 | 2}/${string}`;

// ドット記法オブジェクトパス
type DotPath<T, Prefix extends string = ''> = {
  [K in keyof T & string]: T[K] extends object
    ? DotPath<T[K], `${Prefix}${K}.`>
    : `${Prefix}${K}`
}[keyof T & string];

// 型安全 i18n キー
type TranslationKey = `${string}.${string}`;
function t(key: TranslationKey): string { return ''; }
```

---

## H. TypeScript エラートラブルシューティング

| エラー | 原因 | 修正 |
|-------|------|------|
| `Type 'X' is not assignable to type 'Y'` | 型の不一致 | 両方の型を確認、type guard または assertion 使用 |
| `Property 'x' does not exist on type 'Y'` | プロパティ欠落 | `in` または discriminant で型を絞り込み |
| `Argument of type 'string' is not assignable to parameter of type 'X'` | 文字列リテラル期待 | 値に `as const` または型を広げる |
| `Type 'X \| undefined' is not assignable to type 'X'` | null チェック欠落 | `if (!val)` チェック追加 |
| `Object is possibly 'undefined'` | `noUncheckedIndexedAccess` | `if (arr[0]) { ... }` で null チェック |
| `Type instantiation is excessively deep` | 再帰型が深すぎ | 再帰を簡素化または深さ制限追加 |
| `Cannot find module 'X'` | 型定義欠落 | `npm i -D @types/X` または `moduleResolution` 確認 |
| `'X' refers to a value, but is used as a type` | 値と型の混同 | `typeof X` で値から型を取得 |
| `Type 'unknown' is not assignable to type 'X'` | `unknown` 絞り込み必要 | type guard または `instanceof` で絞り込み |
| `Unused '@ts-expect-error' directive` | エラーが修正済 | ディレクティブを削除 |

---

## I. `satisfies` オペレータパターン

```ts
// 設定の形状を検証しつつリテラル型を保持
const routes = {
  home: '/',
  about: '/about',
  blog: '/blog',
} satisfies Record<string, string>;
// typeof routes.home は '/' であり string でない

// カラーパレット検証
const palette = {
  primary: [240, 90, 60] as const,
  secondary: [200, 80, 50] as const,
} satisfies Record<string, readonly [number, number, number]>;

// イベントハンドラ検証
const handlers = {
  click: (e: MouseEvent) => console.log(e.clientX),
  keydown: (e: KeyboardEvent) => console.log(e.key),
} satisfies Record<string, (e: Event) => void>;
```

---

## J. Branded Type Factory

```ts
// 汎用 branded type factory
declare const __brand: unique symbol;
type Brand<T, B extends string> = T & { readonly [__brand]: B };

type UserId = Brand<string, 'UserId'>;
type OrderId = Brand<string, 'OrderId'>;
type Email = Brand<string, 'Email'>;

// 検証付きコンストラクタ
function createEmail(input: string): Email {
  if (!input.includes('@')) throw new Error('Invalid email');
  return input as Email;
}
```
