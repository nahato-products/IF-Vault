# Systematic Debugging - Reference

## Root Cause Tracing (Condensed)

Bugs manifest deep in call stacks. Fix at the source, not the symptom.

### Tracing Steps

1. **Observe symptom**: Error message, wrong output, crash
2. **Find immediate cause**: Which line throws? What value is wrong?
3. **Trace one level up**: What called this function with the bad value?
4. **Repeat** until you reach the original trigger
5. **Fix at the source**, then add defense-in-depth validation

### Adding Stack Traces for Investigation

```typescript
// Add BEFORE the problematic operation, not after failure
async function riskyOperation(input: string) {
  console.error('DEBUG riskyOperation:', {
    input,
    cwd: process.cwd(),
    stack: new Error().stack,
  });
  // ... operation
}
```

Use `console.error()` in tests (logger output may be suppressed).

### Git Bisect for Regression Hunting

When a bug exists now but did not exist before, use `git bisect` to find the exact commit:

```bash
git bisect start
git bisect bad                    # Current commit has the bug
git bisect good <known-good-sha> # Last known working commit
# Git checks out midpoint; test and mark:
git bisect good  # or  git bisect bad
# Repeat until Git identifies the first bad commit
git bisect reset                  # Return to original branch
```

Automate with a test script: `git bisect run npm test -- --testPathPattern=failing.test`

### Finding Test Polluters

Use `find-polluter.sh` for bisection:

```bash
./find-polluter.sh '.git' 'src/**/*.test.ts'
```

Runs tests one-by-one, stops at first polluter.

---

## Defense-in-Depth Validation (Condensed)

After finding root cause, add validation at EVERY layer to make the bug structurally impossible.

### Four Layers

| Layer | Purpose | Example |
|-------|---------|---------|
| Entry point | Reject invalid input at API boundary | Validate non-empty, exists, correct type |
| Business logic | Ensure data makes sense for operation | Validate required fields for context |
| Environment guard | Prevent dangerous ops in specific contexts | Refuse destructive ops outside tmpdir in tests |
| Debug instrumentation | Capture context for forensics | Log input, cwd, stack before dangerous ops |

### Why All Four

- Different code paths bypass entry validation
- Mocks bypass business logic
- Edge cases on different platforms need environment guards
- Debug logging identifies structural misuse patterns

---

## Condition-Based Waiting (Condensed)

Replace arbitrary `setTimeout`/`sleep` with polling for actual conditions.

### Core Pattern

```typescript
// BAD: guessing at timing
await new Promise(r => setTimeout(r, 50));
expect(getResult()).toBeDefined();

// GOOD: waiting for condition
await waitFor(() => getResult() !== undefined, 'result available');
expect(getResult()).toBeDefined();
```

### Generic Implementation

```typescript
async function waitFor<T>(
  condition: () => T | undefined | null | false,
  description: string,
  timeoutMs = 5000
): Promise<T> {
  const startTime = Date.now();
  while (true) {
    const result = condition();
    if (result) return result;
    if (Date.now() - startTime > timeoutMs) {
      throw new Error(`Timeout waiting for ${description} after ${timeoutMs}ms`);
    }
    await new Promise(r => setTimeout(r, 10)); // Poll every 10ms
  }
}
```

### Quick Reference

| Scenario | Pattern |
|----------|---------|
| Wait for event | `waitFor(() => events.find(e => e.type === 'DONE'))` |
| Wait for state | `waitFor(() => machine.state === 'ready')` |
| Wait for count | `waitFor(() => items.length >= 5)` |
| Wait for file | `waitFor(() => fs.existsSync(path))` |

### When Arbitrary Timeout IS Correct

Only when testing actual timing behavior (debounce, throttle). Requirements:
1. First wait for triggering condition
2. Timeout based on known timing, not guessing
3. Comment explaining WHY

---

## Debugging Decision Flowchart

```
Bug reported
  |
  v
Read error message completely
  |
  v
Can reproduce? --NO--> Gather more data, add logging, wait for recurrence
  |YES
  v
Check git diff / recent changes
  |
  v
Multi-component? --YES--> Add boundary logging, run once, analyze
  |NO                      |
  v                        v
Trace data flow backward   Identify failing component
  |                        |
  v                        v
Root cause identified? --NO--> Form hypothesis, test minimally
  |YES                         |
  v                            v (loop until confirmed)
Find working example, compare differences
  |
  v
Create failing test
  |
  v
Implement single fix
  |
  v
Tests pass? --NO--> Fix count < 3? --YES--> Return to investigation
  |YES                              |NO
  v                                 v
Done. Add defense-in-depth.     STOP: Question architecture with user.
```

---

## Boundary With Related Skills

| Debugging scenario | This skill does | Hand off to |
|-------------------|----------------|-------------|
| Bug found, need regression test | Identify root cause | `testing-strategy`: write failing test, then fix |
| Error classification unclear | Trace data flow to find origin | `error-handling-logging`: classify as operational vs programmer error |
| Bug may be security vulnerability | Investigate reproduction and root cause | `security-review`: assess exploitability and severity |
| Fix attempt #3 fails | Escalate to architectural discussion | `testing-strategy`: redesign with test-first approach |
| CI pipeline breaks | Add boundary logging to isolate failing stage | `ci-cd-deployment`: fix pipeline configuration |
