---
name: testing-strategy
description: "Vitest TDD Red-Green-Refactor, overmocking detection, unit/integration/E2E selection, AAA pattern, coverage, Playwright"
user-invocable: false
---

# Testing Strategy

## Scope & Relationship to Other Skills [HIGH]

| Topic | This Skill | Other Skill |
|-------|-----------|-------------|
| Test design and methodology | Here | - |
| Bug reproduction tests | Here (write failing test) | `systematic-debugging` (find root cause first) |
| Test execution in CI pipeline | - | `ci-cd-deployment` (pipeline config) |
| Error path test scenarios | Here (test error handling) | `error-handling-logging` (error architecture) |
| Security test patterns | Here (test for vulnerabilities) | `security-review` (identify what to test) |
| Type-safe test patterns | Here (test structure) | `typescript-best-practices` (type design) |
| React component testing | Here (render + assert) | `react-component-patterns` (component design) |
| DB query testing | Here (mock repository layer) | `supabase-postgres-best-practices` (query design) |
| Auth flow E2E tests | Here (test auth journeys) | `supabase-auth-patterns` (auth implementation) |

---

## Part 1: Test-Driven Development (TDD) [CRITICAL]

Write the test first. Watch it fail. Write minimal code to pass.

**Core principle:** If you didn't watch the test fail, you don't know if it tests the right thing.

### The Iron Law

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

Write code before the test? Delete it. Start over. No "reference" keeping, no "adapting."

### When to Use TDD [HIGH]

**Always:** New features, bug fixes, refactoring, behavior changes.
**Exceptions (ask human partner):** Throwaway prototypes, generated code, configuration files.

### Unit vs Integration vs E2E Selection [CRITICAL]

| Level | Scope | Speed | When to Use | Ratio |
|-------|-------|-------|-------------|-------|
| **Unit** | Single function/class | <10ms | Pure logic, calculations, transformations | 70% |
| **Integration** | Multiple modules + I/O | <1s | API routes, DB queries, service interactions | 20% |
| **E2E** | Full user flow | <30s | Critical paths (auth, payment, signup) | 10% |

**Decision rule:** Start with unit. Escalate to integration only when testing I/O boundaries. Escalate to E2E only for critical user journeys.

### Red-Green-Refactor Cycle [CRITICAL]

**RED** -- Write one minimal failing test showing desired behavior
**Verify RED** -- Run test. Confirm it fails for the right reason (feature missing, not typo)
**GREEN** -- Write simplest code to pass the test. No extras.
**Verify GREEN** -- Run test. Confirm it passes. Confirm other tests still pass.
**REFACTOR** -- Remove duplication, improve names, extract helpers. Keep tests green.
**Repeat** -- Next failing test for next behavior.

### Good vs Bad Tests [HIGH]

```typescript
// GOOD: Descriptive name, tests real behavior, one assertion concept
test('retries failed operations up to 3 times before succeeding', ...)
// BAD: Vague name, tests mock not code, no value assertion
test('retry works', ...)
```
Full examples: see reference.md R-1

### Common Rationalizations (All Wrong) [MEDIUM]

"Too simple to test" -- Simple code breaks. Test takes 30 seconds.
"I'll test after" -- Tests passing immediately prove nothing.
"Already manually tested" -- Not systematic. No record, can't re-run.
"TDD slows me down" -- TDD is faster than debugging.
"Test is hard to write" -- Hard to test = hard to use. Fix the design.

### Red Flags - STOP and Start Over [HIGH]

Code before test, test passes immediately, can't explain why test failed, rationalizing "just this once", "I already manually tested it", "keep as reference".

**All of these mean: Delete code. Start over with TDD.**

---

## Part 2: Test Quality Analysis [CRITICAL]

### Core Quality Dimensions [HIGH]

- **Correctness**: Tests verify the right behavior
- **Reliability**: Tests are deterministic, not flaky
- **Maintainability**: Tests are easy to understand and change
- **Isolation**: Tests don't depend on external state or each other

### Test Smells [CRITICAL]

See reference.md sections A-1 through A-4 for detailed anti-patterns with code examples.

**Overmocking** [CRITICAL]
- **Detection**: More than 3-4 mocks per test, mocking pure functions, complex mock setup exceeding test body.
- **Fix**: Mock only I/O boundaries (APIs, databases, filesystem).
- Code example: see reference.md A-1

**Fragile Tests** [HIGH]
- **Detection**: CSS selectors, implementation details, breaks on refactor.
- **Fix**: Use semantic selectors (`getByRole`, `getByText`).
- Code example: see reference.md A-2

**Flaky Tests** [CRITICAL]
- **Detection**: Arbitrary timeouts, race conditions, ordering dependency.
- **Fix**: Proper async handling (`await`), deterministic assertions.
- Code example: see reference.md A-3

**Poor Assertions** [HIGH]
- **Detection**: `toBeDefined()`, `toBeTruthy()` — passes with any truthy value.
- **Fix**: Specific assertions (`toMatchObject`, `toEqual`, `toHaveLength`).
- Code example: see reference.md A-4

### Test Structure: AAA Pattern [HIGH]

```typescript
// Arrange - set up preconditions
// Act - perform the action under test
// Assert - verify expected outcome
```
Full example: see reference.md R-2

**Rule:** One Act per test. Multiple Asserts OK if they verify one logical concept.

### API Mocking with MSW [HIGH]

外部APIのモックには [MSW (Mock Service Worker)](https://mswjs.io/) を推奨。テスト・開発環境の両方でネットワークレベルのインターセプトが可能:
```typescript
server.use(http.get('/api/users', () => HttpResponse.json([{ id: 1, name: 'test' }])))
```

### Error Boundary テストの console.error 抑制 [MEDIUM]

Error Boundaryのテストでは `console.error` がノイズになるため抑制する:
```typescript
vi.spyOn(console, 'error').mockImplementation(() => {})
```
テスト後に `vi.restoreAllMocks()` で必ず復元すること。

### Mock Boundary Rules [CRITICAL]

| Category | Mock? | Reason |
|----------|-------|--------|
| External APIs | **Yes** | Unreliable, slow, costly |
| Database | **Usually** | Use test DB or mock repository layer |
| Filesystem | **Yes** | Side effects, platform differences |
| Time/Date | **Yes** | Non-deterministic |
| Random | **Yes** | Non-deterministic |
| Pure functions | **Never** | Real implementation is fast and reliable |
| Business logic | **Never** | You're testing behavior, not bypassing it |

**Max mocks per test: 3-4.** More than that = design problem, not test problem.

### Coverage Targets [HIGH]

| Code Category | Target | Rationale |
|---------------|--------|-----------|
| Critical paths (auth, payment) | **100%** | Failures are catastrophic |
| Business logic | **80%+** | Core value of the application |
| Data mutations | **90%+** | Data corruption risk |
| Read operations | **70%+** | Lower risk, diminishing returns |
| UI rendering | **50%+** | Test behavior, not pixels |

**Rule:** Chase quality, not quantity. 80% meaningful coverage > 95% superficial coverage.

---

## Part 3: Bug Fix Testing Protocol [HIGH]

1. **Reproduce**: Write failing test that demonstrates the bug exactly
2. **Verify RED**: Confirm test fails for the right reason (the actual bug, not a typo)
3. **Fix**: Write minimal code to fix the bug
4. **Verify GREEN**: All tests pass (new + existing)
5. **Regression**: Test stays in suite permanently -- never delete bug regression tests

**Rule:** Never fix a bug without a failing test first. See `systematic-debugging` for root cause investigation before writing the test.

---

## Part 4: React Testing Library (RTL) Patterns [CRITICAL]

Component testing is essential for Next.js/React apps. Use `@testing-library/react` with Vitest.

### Query Priority [CRITICAL]

Always prefer accessible queries. This order reflects how users find elements:

| Priority | Query | When to Use |
|----------|-------|-------------|
| 1st | `getByRole` | Buttons, links, headings, form controls |
| 2nd | `getByLabelText` | Form inputs with labels |
| 3rd | `getByPlaceholderText` | Input without visible label |
| 4th | `getByText` | Non-interactive text content |
| 5th | `getByDisplayValue` | Filled form elements |
| Last resort | `getByTestId` | Only when no semantic query works |

**Rule:** If you reach for `getByTestId` first, your component likely has accessibility problems. Fix the component.

### Component Test with userEvent [CRITICAL]

```typescript
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

test('submits form with valid data', async () => {
  const mockSubmit = vi.fn();
  const user = userEvent.setup();
  render(<LoginForm onSubmit={mockSubmit} />);

  await user.type(screen.getByLabelText('Email'), 'test@example.com');
  await user.type(screen.getByLabelText('Password'), 'password123');
  await user.click(screen.getByRole('button', { name: '送信' }));

  expect(mockSubmit).toHaveBeenCalledWith({
    email: 'test@example.com',
    password: 'password123',
  });
});
```

**Important:** Always use `userEvent.setup()` over `fireEvent`. `userEvent` simulates real browser interactions (focus, keydown, input, keyup) while `fireEvent` dispatches a single synthetic event.

### Scoped Queries with within() [HIGH]

```typescript
import { render, screen, within } from '@testing-library/react';

test('renders correct item in each list section', () => {
  render(<Dashboard />);

  const sidebar = within(screen.getByRole('navigation'));
  expect(sidebar.getByText('設定')).toBeInTheDocument();

  const main = within(screen.getByRole('main'));
  expect(main.getByText('ダッシュボード')).toBeInTheDocument();
});
```

### Testing Custom Hooks with renderHook [HIGH]

```typescript
import { renderHook, act } from '@testing-library/react';

test('useCounter increments and decrements', () => {
  const { result } = renderHook(() => useCounter(0));

  expect(result.current.count).toBe(0);

  act(() => result.current.increment());
  expect(result.current.count).toBe(1);

  act(() => result.current.decrement());
  expect(result.current.count).toBe(0);
});
```

### Async Component Testing [HIGH]

```typescript
test('displays user data after loading', async () => {
  render(<UserProfile userId="123" />);

  // ローディング状態を確認
  expect(screen.getByText('読み込み中...')).toBeInTheDocument();

  // データ表示を待機（findBy* は自動的にリトライする）
  expect(await screen.findByText('関口さん')).toBeInTheDocument();

  // ローディングが消えたことを確認
  expect(screen.queryByText('読み込み中...')).not.toBeInTheDocument();
});
```

**Query variants:**
- `getBy*` -- 要素が存在することを期待（なければ即エラー）
- `findBy*` -- 非同期で要素の出現を待機（Promise返却、デフォルト1秒タイムアウト）
- `queryBy*` -- 要素が存在しないことを確認（なければnull返却）

### RTL Anti-Patterns [HIGH]

```typescript
// ANTI-PATTERN: container.querySelector でDOM構造に依存
const { container } = render(<Nav />);
container.querySelector('.nav-item-active'); // 壊れやすい

// CORRECT: セマンティッククエリを使用
render(<Nav />);
screen.getByRole('link', { current: 'page' });

// ANTI-PATTERN: fireEvent で不完全なイベント
fireEvent.change(input, { target: { value: 'text' } });

// CORRECT: userEvent でリアルなインタラクション
const user = userEvent.setup();
await user.type(input, 'text');
```

---

## Part 5: Web App Testing with Playwright [MEDIUM]

Write Playwright tests in TypeScript using `@playwright/test` for E2E testing. See reference.md sections D-1 through D-4 for advanced patterns.

### Decision Tree [HIGH]

Static HTML? → Yes → セレクタ特定 → Playwrightテスト作成 / No（動的アプリ）→ サーバー起動済み? → No → `webServer` config使用 / Yes → Reconnaissance-then-action: ページ読込待機 → screenshot/DOM検査 → セレクタ特定 → アクション実行

### Playwright Test Template [MEDIUM]

```typescript
import { test, expect } from '@playwright/test';

test('user can login', async ({ page }) => {
  await page.goto('/login');
  await page.getByLabel('Email').fill('test@example.com');
  await page.getByLabel('Password').fill('password123');
  await page.getByRole('button', { name: '送信' }).click();
  await expect(page).toHaveURL('/dashboard');
});
```
Full template and advanced patterns: see reference.md R-3, D-1 through D-4

### Reconnaissance-Then-Action Pattern [MEDIUM]

1. **Inspect**: `await page.screenshot({ path: '/tmp/inspect.png', fullPage: true })`
2. **Identify selectors** from inspection results
3. **Execute actions** using discovered selectors

**Pitfall:** Don't inspect DOM before page load completes on dynamic apps. Use `await page.waitForLoadState('domcontentloaded')` first, then explicit `await page.waitForSelector()` や `await expect(locator).toBeVisible()` で要素を待機。`networkidle` は不安定なため使用禁止。

---

## Verification Checklist [CRITICAL]

Before marking work complete:

- [ ] Every new function/method has a test
- [ ] Watched each test fail before implementing
- [ ] Each test failed for expected reason (not typo/import error)
- [ ] Wrote minimal code to pass each test
- [ ] All tests pass (new + existing)
- [ ] Output pristine (no errors, warnings, skipped tests)
- [ ] Tests use real code (mocks only at I/O boundaries)
- [ ] Edge cases and error paths covered
- [ ] No flaky tests (timing, ordering, environment issues)
- [ ] Assertions are specific and meaningful (not just `.toBeDefined()`)

## When Stuck [MEDIUM]

| Problem | Solution |
|---------|----------|
| Don't know how to test | Write wished-for API first. Write assertion first. |
| Test too complicated | Design too complicated. Simplify interface. |
| Must mock everything | Code too coupled. Use dependency injection. |
| Test setup huge | Extract helpers. Still complex? Simplify design. |
| 3 fix attempts failed | Suspect architecture. Step back and redesign. |
| Flaky test in CI | See `systematic-debugging` for isolation techniques. |

---

## Cross-references [MEDIUM]

- **typescript-best-practices**: 型安全なテストパターン・型設計とテスタビリティの関係
- **error-handling-logging**: エラーパスのテストシナリオ設計・エラー分類に基づくテスト網羅
- **ci-cd-deployment**: テストのCIパイプライン実行・並列ジョブ構成・テスト結果ゲート

## Reference

Detailed anti-patterns (A-1 to A-5), test doubles classification, Vitest patterns, Playwright advanced patterns, coverage analysis decision tree, error path testing, security test patterns, and CI pipeline config are in [reference.md](reference.md).
