---
name: testing-strategy
description: "Test architecture and TDD workflow for TypeScript/Vitest projects. Covers Red-Green-Refactor cycle, test quality analysis (overmocking detection, flaky test elimination, assertion strength), unit vs integration vs E2E test selection, AAA pattern, mock boundary rules, coverage target strategy, bug-fix testing protocol, and Playwright browser automation. Use when writing tests, designing test suites, implementing features test-first, fixing bugs with regression tests, reviewing test quality or coverage gaps, detecting test smells, choosing test granularity, refactoring with test safety, or automating browser testing for web apps. Does NOT cover debugging methodology (systematic-debugging), error handling architecture (error-handling-logging), or security vulnerability detection (security-review)."
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

<Good>
```typescript
test('retries failed operations up to 3 times before succeeding', async () => {
  let attempts = 0;
  const operation = () => {
    attempts++;
    if (attempts < 3) throw new Error('fail');
    return 'success';
  };
  const result = await retryOperation(operation);
  expect(result).toBe('success');
  expect(attempts).toBe(3);
});
```
Descriptive name, tests real behavior, one assertion concept
</Good>

<Bad>
```typescript
test('retry works', async () => {
  const mock = jest.fn()
    .mockRejectedValueOnce(new Error())
    .mockResolvedValueOnce('success');
  await retryOperation(mock);
  expect(mock).toHaveBeenCalledTimes(2);
});
```
Vague name, tests mock not code, no value assertion
</Bad>

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
test('registered user receives welcome email', async () => {
  // Arrange - set up preconditions
  const userData = { email: 'user@example.com' }
  // Act - perform the action under test
  const user = await registerUser(userData)
  // Assert - verify expected outcome
  expect(user.email).toBe('user@example.com')
})
```

**Rule:** One Act per test. Multiple Asserts OK if they verify one logical concept.

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

## Part 4: Web App Testing with Playwright [MEDIUM]

Write native Python Playwright scripts for testing local web applications. See reference.md sections D-1 through D-4 for advanced patterns.

### Decision Tree [HIGH]

```
User task -> Is it static HTML?
    +-- Yes -> Read HTML file to identify selectors
    |         -> Write Playwright script using selectors
    +-- No (dynamic webapp) -> Is the server already running?
        +-- No -> Run: python scripts/with_server.py --help
        |        Then use the helper + write Playwright script
        +-- Yes -> Reconnaissance-then-action:
            1. Navigate and wait for networkidle
            2. Take screenshot or inspect DOM
            3. Identify selectors from rendered state
            4. Execute actions with discovered selectors
```

### Playwright Script Template [MEDIUM]

```python
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    page = browser.new_page()
    page.goto('http://localhost:5173')
    page.wait_for_load_state('networkidle')  # CRITICAL: Wait for JS
    # ... automation logic
    browser.close()
```

### Reconnaissance-Then-Action Pattern [MEDIUM]

1. **Inspect**: `page.screenshot(path='/tmp/inspect.png', full_page=True)`
2. **Identify selectors** from inspection results
3. **Execute actions** using discovered selectors

**Pitfall:** Don't inspect DOM before `networkidle` on dynamic apps. Always wait first.

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

## Reference

Detailed anti-patterns (A-1 to A-5), test doubles classification, Vitest patterns, Playwright advanced patterns, coverage analysis decision tree, error path testing, security test patterns, and CI pipeline config are in [reference.md](reference.md).
