---
name: systematic-debugging
description: "Debug complex issues to root cause using git-bisect, boundary logging, data-flow trace, hypothesis test, single-variable, 3-fix escalation. Use when debugging complex issues, tracing root causes, or when initial fix attempts fail."
user-invocable: false
---

# Systematic Debugging

> **Scope**: This skill provides the debugging *process* (how to find and fix bugs). For writing regression tests after a fix, see `testing-strategy`. For error classification (operational vs programmer) and structured logging, see `error-handling-logging`. For investigating security-related bugs (injection, auth bypass, data leaks), see `security-review`.

### Decision Tree

**Flow**: Read error -> Reproduce? (No: gather data) -> Check git diff -> Multi-component? (Yes: boundary logging) -> Trace data flow backward -> Root cause? (No: hypothesis loop) -> Find working example, compare -> Create failing test -> Single fix -> Pass? (No, 3+ attempts: question architecture)

## Core Rule [CRITICAL]

**NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST.**

If you have not completed Phase 1, you cannot propose fixes. Symptom fixes are failure.

## Phase 1: Root Cause Investigation [CRITICAL]

**BEFORE attempting ANY fix:**

### 1.1 Read Error Messages Completely

- Read stack traces top to bottom
- Note line numbers, file paths, error codes
- Error messages often contain the exact solution

### 1.2 Reproduce Consistently

- Define exact reproduction steps
- Confirm it triggers reliably
- If not reproducible, gather more data -- do not guess

### 1.3 Check Recent Changes

- `git diff` and recent commits
- New dependencies, config changes
- Environmental differences (local vs CI, Node version, OS)
- Use `git bisect` to pinpoint the exact commit introducing a regression:
  `git bisect start`, `git bisect bad`, `git bisect good <known-good>`, then test each step

### 1.4 Gather Evidence at Component Boundaries

**For multi-component systems (CI -> build -> deploy, API -> service -> DB):**

Add diagnostic logging at EACH boundary BEFORE proposing fixes:

For each component boundary: log data in, log data out, verify config/env, check state at each layer. Run once, analyze evidence, identify failing component.

This reveals which layer fails (e.g., secrets -> workflow OK, workflow -> build FAIL).

### 1.5 Trace Data Flow Backward

When error is deep in call stack, trace backward from symptom to source: find the throwing line, then ask "what called this with bad data?" repeatedly until you reach the origin. Fix at the source, not the symptom.

See reference.md > Root Cause Tracing for the complete 5-step technique with examples.

## Phase 2: Pattern Analysis [HIGH]

### 2.1 Find Working Examples

- Locate similar working code in same codebase
- What works that is similar to what is broken?

### 2.2 Compare Working vs Broken

- List EVERY difference, however small
- Do not assume "that cannot matter"
- If implementing a pattern, read the reference implementation completely

### 2.3 Understand Dependencies

- What components, config, environment does this need?
- What assumptions does the code make?

## Phase 3: Hypothesis Testing [HIGH]

### 3.1 Form Single Hypothesis

State clearly: "I think X is the root cause because Y evidence shows Z."

### 3.2 Test Minimally

- Make the SMALLEST possible change to test hypothesis
- ONE variable at a time
- Never fix multiple things at once

### 3.3 Evaluate Result

- Confirmed? Proceed to Phase 4
- Refuted? Form NEW hypothesis from new evidence
- Do NOT stack additional fixes on top

### 3.4 Admit Uncertainty

If you do not understand something, say so. Do not pretend to know. Research more or ask for help.

## Phase 4: Verified Implementation [CRITICAL]

### 4.1 Create Failing Test

- Simplest possible reproduction as an automated test
- MUST exist before implementing fix
- See `testing-strategy` skill for test writing patterns

### 4.2 Implement Single Fix

- Address the root cause identified in Phase 1
- ONE change at a time
- No "while I'm here" improvements or bundled refactoring

### 4.3 Verify Fix

- Failing test now passes
- No other tests broken
- Issue actually resolved end-to-end

### 4.4 Three-Fix Escalation Rule

Count how many fixes you have attempted:

| Attempts | Action |
|----------|--------|
| < 3 | Return to Phase 1 with new information |
| >= 3 | STOP. This signals an **architectural problem** |

**Architectural problem indicators:**
- Each fix reveals new shared state or coupling issues
- Fixes require massive refactoring
- Each fix creates new symptoms elsewhere

**Action:** Discuss fundamentals with the user before attempting more fixes. This is not a failed hypothesis; it is a wrong architecture.

## Red Flags: Return to Phase 1 [CRITICAL]

If you catch yourself thinking any of these, STOP immediately:

- **Acting without understanding**: "Quick fix for now" / "Just try changing X" / "I don't fully understand but this might work"
- **Confusing symptoms with root cause**: "I see the problem, let me fix it" (seeing symptoms != understanding)
- **Multiple changes at once**: changing several things then running tests (violates single-variable rule)
- **Skipping verification**: "Skip the test, manually verify"
- **Proposing solutions before investigation**: listing fixes or solutions before tracing data flow

## User Signals of Process Violation [HIGH]

Watch for these redirections from the user:

| Signal | Meaning |
|--------|---------|
| "Is that not happening?" | You assumed without verifying |
| "Will it show us...?" | You should have added evidence gathering |
| "Stop guessing" | Proposing fixes without understanding |
| "We're stuck?" (frustrated) | Your approach is not working, reset |

**Response:** STOP. Return to Phase 1.

## When Investigation Finds No Root Cause [MEDIUM]

If systematic investigation reveals a truly environmental, timing-dependent, or external issue:

1. Document what was investigated
2. Implement appropriate handling (retry, timeout, error message)
3. Add monitoring/logging for future investigation

Note: most "no root cause" cases are incomplete investigation.

### Debugging Start Checklist

- [ ] Error message fully read (stack trace, error code, file paths noted)
- [ ] Bug reproduced consistently with exact steps
- [ ] `git diff` / recent commits checked for related changes
- [ ] Environment differences identified (local vs CI, versions)
- [ ] Boundary logging added for multi-component systems
- [ ] Data flow traced backward from symptom to source
- [ ] Working example found and compared with broken code
- [ ] Single hypothesis formed with supporting evidence
- [ ] Minimal test change prepared (one variable only)
- [ ] Failing test written before implementing fix

## Cross-references [MEDIUM]

- **testing-strategy**: Write failing regression test before fix, test-first redesign after 3-fix escalation
- **error-handling-logging**: Classify root cause as operational vs programmer error, add structured logging
- **security-review**: Assess exploitability if bug may be a security vulnerability
- **ci-cd-deployment**: Fix pipeline configuration after boundary logging isolates failing CI stage

## Supporting Techniques [MEDIUM]

See `reference.md` for condensed versions. Full detail in separate files:

- **`root-cause-tracing.md`** - Backward call-stack tracing to find original trigger
- **`defense-in-depth.md`** - Multi-layer validation (entry, business, environment, debug)
- **`condition-based-waiting.md`** - Replace arbitrary timeouts with condition polling
- **`find-polluter.sh`** - Bisection script to isolate test-state pollution
