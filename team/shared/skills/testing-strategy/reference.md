# Testing Strategy Reference

## A. Testing Anti-Patterns (Deep Dive)

### A-1. Testing Mock Behavior Instead of Real Behavior

```typescript
// ANTI-PATTERN: Testing that mock returns what you told it to
const mockDB = vi.fn().mockResolvedValue({ id: 1, name: 'John' })
const result = await mockDB()
expect(result).toEqual({ id: 1, name: 'John' }) // Tests nothing!

// CORRECT: Mock the boundary, test the logic
const mockDB = vi.fn().mockResolvedValue({ id: 1, name: 'John' })
const user = await getUserDisplayName(mockDB)
expect(user).toBe('John') // Tests actual transformation
```

### A-2. Adding Test-Only Methods to Production Classes

```typescript
// ANTI-PATTERN
class UserService {
  getInternalState() { return this.state } // Only used in tests!
}

// CORRECT: Test through public API
const service = new UserService()
await service.createUser({ name: 'John' })
const users = await service.listUsers()
expect(users).toHaveLength(1)
```

### A-3. The God Test

```typescript
// ANTI-PATTERN: One test that tests everything
test('user flow', async () => {
  const user = await createUser(data)
  expect(user.id).toBeDefined()
  await updateUser(user.id, { name: 'New' })
  const updated = await getUser(user.id)
  expect(updated.name).toBe('New')
  await deleteUser(user.id)
  // ... 50 more lines
})

// CORRECT: Separate tests per behavior
test('creates user with generated id', async () => { ... })
test('updates user name', async () => { ... })
test('deletes user', async () => { ... })
```

### A-4. Snapshot Abuse

```typescript
// ANTI-PATTERN: Snapshot testing complex objects
expect(apiResponse).toMatchSnapshot() // Breaks on any change

// CORRECT: Assert specific important fields
expect(apiResponse).toMatchObject({
  status: 'success',
  data: { userId: expect.any(String) }
})
```

### A-5. Test Interdependence

```typescript
// ANTI-PATTERN: Tests depend on execution order
let sharedUser: User
test('creates user', async () => {
  sharedUser = await createUser({ name: 'John' })
})
test('updates user', async () => {
  await updateUser(sharedUser.id, { name: 'Jane' }) // Fails if run alone!
})

// CORRECT: Each test creates its own state
test('updates user name', async () => {
  const user = await createUser({ name: 'John' })
  const updated = await updateUser(user.id, { name: 'Jane' })
  expect(updated.name).toBe('Jane')
})
```

---

## B. Test Doubles Classification

| Type | Purpose | When to Use |
|------|---------|-------------|
| **Stub** | Returns predetermined data | Replace data source with known values |
| **Mock** | Verifies interactions (calls, args) | Verify outgoing commands (send email, log) |
| **Spy** | Wraps real implementation + records | Observe real behavior without replacing it |
| **Fake** | Simplified working implementation | In-memory DB, fake filesystem |
| **Dummy** | Placeholder (never actually used) | Fill required parameters |

**Rule:** Prefer stubs and fakes over mocks. Mocks create coupling to implementation.

```typescript
// Stub - returns known data
const getUser = vi.fn().mockResolvedValue({ id: 1, name: 'John' })

// Spy - wraps real implementation
const logSpy = vi.spyOn(console, 'log')
doSomething()
expect(logSpy).toHaveBeenCalledWith('expected message')

// Fake - simplified real implementation
const fakeDB = new Map<string, User>()
const fakeRepo = {
  save: (user: User) => { fakeDB.set(user.id, user) },
  findById: (id: string) => fakeDB.get(id),
}
```

---

## C. Vitest Patterns

### C-1. Setup and Teardown

```typescript
import { describe, test, expect, beforeEach, afterEach } from 'vitest'

describe('UserService', () => {
  let service: UserService

  beforeEach(() => {
    service = new UserService(testConfig)
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  test('creates user', async () => {
    const user = await service.create({ name: 'John' })
    expect(user.name).toBe('John')
  })
})
```

### C-2. Parameterized Tests

```typescript
test.each([
  { input: '', expected: false },
  { input: 'a@b.com', expected: true },
  { input: 'invalid', expected: false },
  { input: 'a@b.c', expected: true },
])('validates email "$input" -> $expected', ({ input, expected }) => {
  expect(isValidEmail(input)).toBe(expected)
})
```

### C-3. Async Error Testing

```typescript
test('rejects invalid input', async () => {
  await expect(
    createUser({ email: '' })
  ).rejects.toThrow('Email required')
})
```

### C-4. Testing Hooks with @testing-library/react

```typescript
import { renderHook, act } from '@testing-library/react'

test('useCounter increments', () => {
  const { result } = renderHook(() => useCounter(0))
  act(() => result.current.increment())
  expect(result.current.count).toBe(1)
})
```

### C-5. Timer and Date Mocking

```typescript
test('debounce delays execution', async () => {
  vi.useFakeTimers()
  const fn = vi.fn()
  const debounced = debounce(fn, 300)

  debounced()
  expect(fn).not.toHaveBeenCalled()

  vi.advanceTimersByTime(300)
  expect(fn).toHaveBeenCalledOnce()

  vi.useRealTimers()
})
```

---

## D. Playwright Advanced Patterns

### D-1. Page Object Model

```python
class LoginPage:
    def __init__(self, page):
        self.page = page
        self.email = page.get_by_label('Email')
        self.password = page.get_by_label('Password')
        self.submit = page.get_by_role('button', name='Sign in')

    def login(self, email, password):
        self.email.fill(email)
        self.password.fill(password)
        self.submit.click()
        self.page.wait_for_load_state('networkidle')
```

### D-2. Network Interception

```python
def handle_route(route):
    route.fulfill(
        status=200,
        content_type='application/json',
        body='{"users": [{"id": 1, "name": "Test"}]}'
    )

page.route('**/api/users', handle_route)
page.goto('http://localhost:3000/users')
```

### D-3. Console Log Capture

```python
logs = []
page.on('console', lambda msg: logs.append(f'{msg.type}: {msg.text}'))
page.goto('http://localhost:3000')

errors = [log for log in logs if log.startswith('error:')]
assert len(errors) == 0, f'Console errors found: {errors}'
```

### D-4. Multi-Server Setup

```bash
# Single server
python scripts/with_server.py --server "npm run dev" --port 5173 -- python your_automation.py

# Multiple servers (backend + frontend)
python scripts/with_server.py \
  --server "cd backend && python server.py" --port 3000 \
  --server "cd frontend && npm run dev" --port 5173 \
  -- python your_automation.py
```

---

## E. Coverage Analysis Decision Tree

```
Coverage < 60% -> Focus on critical paths first
  +-- Auth flows -> Must be 100%
  +-- Payment flows -> Must be 100%
  +-- Data mutations -> Must be 90%+
  +-- Read operations -> 80%+ is fine

Coverage 60-80% -> Fill gaps
  +-- Error handlers -> Often untested
  +-- Edge cases -> Null, empty, boundary values
  +-- Async error paths -> Timeout, network failure

Coverage > 80% -> Diminishing returns
  +-- Don't chase 100% on non-critical code
  +-- Focus on test quality over quantity
  +-- Consider mutation testing for real effectiveness
```

---

## F. Error Path Testing Patterns

Complements `error-handling-logging` skill -- test that error handling works correctly.

### F-1. Testing Operational Errors

```typescript
test('returns 404 when post not found', async () => {
  const mockDB = vi.fn().mockResolvedValue(null)
  const result = await getPost('nonexistent', mockDB)
  expect(result).toEqual({
    success: false,
    error: { code: 'NOT_FOUND', message: 'Post not found' }
  })
})
```

### F-2. Testing Error Boundaries (React)

```typescript
test('error boundary renders fallback on child error', () => {
  const ThrowingComponent = () => { throw new Error('test') }
  const { getByText } = render(
    <ErrorBoundary fallback={<div>Something went wrong</div>}>
      <ThrowingComponent />
    </ErrorBoundary>
  )
  expect(getByText('Something went wrong')).toBeInTheDocument()
})
```

### F-3. Testing Retry Logic

```typescript
test('retries transient failures with exponential backoff', async () => {
  vi.useFakeTimers()
  const api = vi.fn()
    .mockRejectedValueOnce(new Error('503'))
    .mockRejectedValueOnce(new Error('503'))
    .mockResolvedValueOnce({ data: 'success' })

  const promise = withRetry(api, { maxRetries: 3, baseDelay: 1000 })
  await vi.advanceTimersByTimeAsync(1000) // 1st retry
  await vi.advanceTimersByTimeAsync(2000) // 2nd retry
  const result = await promise
  expect(result).toEqual({ data: 'success' })
  expect(api).toHaveBeenCalledTimes(3)
  vi.useRealTimers()
})
```

---

## G. Security Test Patterns

Complements `security-review` skill -- test that security controls are enforced.

### G-1. Auth Guard Testing

```typescript
test('rejects unauthenticated requests with 401', async () => {
  const response = await request(app).get('/api/protected')
  expect(response.status).toBe(401)
  expect(response.body.error.code).toBe('UNAUTHORIZED')
})

test('rejects requests with expired token', async () => {
  const expiredToken = generateToken({ userId: '1', exp: Date.now() / 1000 - 3600 })
  const response = await request(app)
    .get('/api/protected')
    .set('Authorization', `Bearer ${expiredToken}`)
  expect(response.status).toBe(401)
})
```

### G-2. Input Validation Testing

```typescript
test.each([
  { input: '<script>alert("xss")</script>', field: 'name' },
  { input: "'; DROP TABLE users; --", field: 'name' },
  { input: '../../../etc/passwd', field: 'filename' },
])('rejects malicious input in $field', async ({ input, field }) => {
  const response = await request(app)
    .post('/api/users')
    .send({ [field]: input })
  expect(response.status).toBe(400)
})
```

---

## H. CI Pipeline Test Configuration

Complements `ci-cd-deployment` skill -- test configuration for automated pipelines.

### H-1. Vitest Config for CI

```typescript
// vitest.config.ts
export default defineConfig({
  test: {
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json-summary', 'lcov'],
      thresholds: {
        branches: 80,
        functions: 80,
        lines: 80,
        statements: 80,
      },
    },
    reporters: process.env.CI ? ['default', 'junit'] : ['default'],
    outputFile: process.env.CI ? 'test-results/junit.xml' : undefined,
  },
})
```

### H-2. GitHub Actions Test Step

```yaml
test:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-node@v4
      with:
        node-version: 20
        cache: 'npm'
    - run: npm ci
    - run: npm test -- --coverage
    - uses: actions/upload-artifact@v4
      if: always()
      with:
        name: test-results
        path: test-results/
```
