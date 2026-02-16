---
name: security-review
description: "Detect, analyze, and report exploitable security vulnerabilities in application code and infrastructure configs. Use when asked to 'security review', 'find vulnerabilities', 'check for security issues', 'audit security', 'OWASP review', 'pen test code', 'threat model', 'check for injection', 'find XSS', 'review auth bypass', or assess code for SQL injection, XSS, SSRF, CSRF, IDOR, deserialization, path traversal, command injection, cryptography weaknesses, or hardcoded secrets. Traces attacker-controlled input, verifies exploitability against framework mitigations, classifies severity per OWASP Top 10 and CWE, and outputs structured remediation."
user-invocable: true
---

<!--
Reference material based on OWASP Cheat Sheet Series (CC BY-SA 4.0)
https://cheatsheetseries.owasp.org/
-->

# Security Review Skill

Identify exploitable security vulnerabilities in code. Report only **HIGH CONFIDENCE** findings -- clear vulnerable patterns with attacker-controlled input. This skill **detects vulnerabilities**; it does not implement security patterns.

## [CRITICAL] Differentiation

This skill **finds and reports exploitable bugs**. Other skills **build secure implementations**:

| This skill (detect) | Other skill (implement) | Boundary |
|---------------------|------------------------|----------|
| Flags fail-open error as vulnerability | `error-handling-logging` designs error recovery | Error leaks stack trace? Flag here. Need retry logic? Use that skill |
| Flags Docker misconfig (root user, secrets in layers) | `docker-expert` builds optimized containers | Running as root? Flag here. Need multi-stage build? Use that skill |
| Audits CI/CD for secret leaks, workflow injection | `ci-cd-deployment` designs pipeline workflows | Secret in logs? Flag here. Need deploy pipeline? Use that skill |
| Audits auth for bypass, token weakness, session flaws | `supabase-auth-patterns` designs auth flows | JWT not verified? Flag here. Need OAuth flow? Use that skill |
| Identifies what to test for security regressions | `testing-strategy` designs how to test | Found SQLi? Flag + suggest test. Need test suite? Use that skill |

## [CRITICAL] Research vs. Reporting Scope

- **Report on**: Only the specific file, diff, or code provided by the user
- **Research**: The ENTIRE codebase to build confidence before reporting

Before flagging any issue, you MUST research the codebase to understand:
- Where does this input actually come from? (Trace data flow)
- Is there validation/sanitization elsewhere?
- How is this configured? (Check settings, config files, middleware)
- What framework protections exist?

**Do NOT report issues based solely on pattern matching.** Investigate first, then report only what you're confident is exploitable.

## [CRITICAL] Confidence Levels

| Level | Criteria | Action |
|-------|----------|--------|
| **HIGH** | Vulnerable pattern + attacker-controlled input confirmed | **Report** with severity |
| **MEDIUM** | Vulnerable pattern, input source unclear | **Note** as "Needs verification" |
| **LOW** | Theoretical, best practice, defense-in-depth | **Do not report** |

## [HIGH] Do Not Flag

### [HIGH] General Rules
- Test files (unless explicitly reviewing test security)
- Dead code, commented code, documentation strings
- Patterns using **constants** or **server-controlled configuration**
- Code paths that require prior authentication to reach (note the auth requirement instead)

### [HIGH] Server-Controlled Values (NOT Attacker-Controlled)

These are configured by operators, not controlled by attackers:

| Source | Example | Why It's Safe |
|--------|---------|---------------|
| Django settings | `settings.API_URL`, `settings.ALLOWED_HOSTS` | Set via config/env at deployment |
| Environment variables | `os.environ.get('DATABASE_URL')` | Deployment configuration |
| Config files | `config.yaml`, `app.config['KEY']` | Server-side files |
| Framework constants | `django.conf.settings.*` | Not user-modifiable |
| Hardcoded values | `BASE_URL = "https://api.internal"` | Compile-time constants |

**SSRF Example - NOT a vulnerability:**
```python
# SAFE: URL comes from Django settings (server-controlled)
response = requests.get(f"{settings.SEER_AUTOFIX_URL}{path}")
```

**SSRF Example - IS a vulnerability:**
```python
# VULNERABLE: URL comes from request (attacker-controlled)
response = requests.get(request.GET.get('url'))
```

### [HIGH] Framework-Mitigated Patterns
Check language guides before flagging. Common false positives:

| Pattern | Why It's Usually Safe |
|---------|----------------------|
| Django `{{ variable }}` | Auto-escaped by default |
| React `{variable}` | Auto-escaped by default |
| Vue `{{ variable }}` | Auto-escaped by default |
| `User.objects.filter(id=input)` | ORM parameterizes queries |
| `cursor.execute("...%s", (input,))` | Parameterized query |
| `innerHTML = "<b>Loading...</b>"` | Constant string, no user input |

**Only flag these when:**
- Django: `{{ var|safe }}`, `{% autoescape off %}`, `mark_safe(user_input)`
- React: `dangerouslySetInnerHTML={{__html: userInput}}`
- Vue: `v-html="userInput"`
- ORM: `.raw()`, `.extra()`, `RawSQL()` with string interpolation

## [CRITICAL] Review Process

### [HIGH] 1. Detect Context

What type of code am I reviewing?

| Code Type | Load These References |
|-----------|----------------------|
| API endpoints, routes | `authorization.md`, `authentication.md`, `injection.md` |
| Frontend, templates | `xss.md`, `csrf.md` |
| File handling, uploads | `file-security.md` |
| Crypto, secrets, tokens | `cryptography.md`, `data-protection.md` |
| Data serialization | `deserialization.md` |
| External requests | `ssrf.md` |
| Business workflows | `business-logic.md` |
| GraphQL, REST design | `api-security.md` |
| Config, headers, CORS | `misconfiguration.md` |
| CI/CD, dependencies | `supply-chain.md` |
| Error handling | `error-handling.md` |
| Audit, logging | `logging.md` |

### [MEDIUM] 2. Load Language Guide

Based on file extension or imports:

| Indicators | Guide |
|------------|-------|
| `.py`, `django`, `flask`, `fastapi` | `languages/python.md` |
| `.js`, `.ts`, `express`, `react`, `vue`, `next` | `languages/javascript.md` |

### [MEDIUM] 3. Load Infrastructure Guide (if applicable)

| File Type | Guide |
|-----------|-------|
| `Dockerfile`, `.dockerignore` | `infrastructure/docker.md` (also consult `docker-expert` for container hardening) |

### 4. [CRITICAL] Research Before Flagging

For each potential issue, research the codebase to build confidence:

- Where does this value actually come from? Trace the data flow
- Is it configured at deployment (settings, env vars) or from user input?
- Is there validation, sanitization, or allowlisting elsewhere?
- What framework protections apply?

Only report issues where you have HIGH confidence after understanding the broader context.

### 5. [HIGH] Verify Exploitability

For each potential finding, confirm:

**Is the input attacker-controlled?**

| Attacker-Controlled (Investigate) | Server-Controlled (Usually Safe) |
|-----------------------------------|----------------------------------|
| `request.GET`, `request.POST`, `request.args` | `settings.X`, `app.config['X']` |
| `request.json`, `request.data`, `request.body` | `os.environ.get('X')` |
| `request.headers` (most headers) | Hardcoded constants |
| `request.cookies` (unsigned) | Internal service URLs from config |
| URL path segments: `/users/<id>/` | Database content from admin/system |
| File uploads (content and names) | Signed session data |
| Database content from other users | Framework settings |
| WebSocket messages | |

**Does the framework mitigate this?**
- Check language guide for auto-escaping, parameterization
- Check for middleware/decorators that sanitize

**Is there validation upstream?**
- Input validation before this code
- Sanitization libraries (DOMPurify, bleach, etc.)

### 6. [CRITICAL] Report HIGH Confidence Only

Skip theoretical issues. Report only what you've confirmed is exploitable after research.

---

## [HIGH] Severity Classification

| Severity | Impact | Examples |
|----------|--------|----------|
| **Critical** | Direct exploit, severe impact, no auth required | RCE, SQL injection to data, auth bypass, hardcoded secrets |
| **High** | Exploitable with conditions, significant impact | Stored XSS, SSRF to metadata, IDOR to sensitive data |
| **Medium** | Specific conditions required, moderate impact | Reflected XSS, CSRF on state-changing actions, path traversal |
| **Low** | Defense-in-depth, minimal direct impact | Missing headers, verbose errors, weak algorithms in non-critical context |

---

## [CRITICAL] Quick Patterns Reference

### [CRITICAL] Always Flag (Critical)
```
eval(user_input)           # Any language
exec(user_input)           # Any language
pickle.loads(user_data)    # Python
yaml.load(user_data)       # Python (not safe_load)
unserialize($user_data)    # PHP
deserialize(user_data)     # Java ObjectInputStream
shell=True + user_input    # Python subprocess
child_process.exec(user)   # Node.js
```

### [HIGH] Always Flag (High)
```
innerHTML = userInput              # DOM XSS
dangerouslySetInnerHTML={user}     # React XSS
v-html="userInput"                 # Vue XSS
f"SELECT * FROM x WHERE {user}"    # SQL injection
`SELECT * FROM x WHERE ${user}`    # SQL injection
os.system(f"cmd {user_input}")     # Command injection
```

### [CRITICAL] Always Flag (Secrets)
```
password = "hardcoded"
api_key = "sk-..."
AWS_SECRET_ACCESS_KEY = "..."
private_key = "-----BEGIN"
```

### [MEDIUM] Check Context First (Investigate Before Flagging)
```
# SSRF - ONLY if URL is from user input, NOT from settings/config
requests.get(request.GET['url'])     # FLAG: User-controlled URL
requests.get(settings.API_URL)       # SAFE: Server-controlled config
requests.get(f"{settings.BASE}/{x}") # CHECK: Is 'x' user input?

# Path traversal - ONLY if path is from user input
open(request.GET['file'])            # FLAG: User-controlled path
open(settings.LOG_PATH)              # SAFE: Server-controlled config
open(f"{BASE_DIR}/{filename}")       # CHECK: Is 'filename' user input?

# Open redirect - ONLY if URL is from user input
redirect(request.GET['next'])        # FLAG: User-controlled redirect
redirect(settings.LOGIN_URL)         # SAFE: Server-controlled config

# Weak crypto - ONLY if used for security purposes
hashlib.md5(file_content)            # SAFE: File checksums, caching
hashlib.md5(password)                # FLAG: Password hashing
random.random()                      # SAFE: Non-security uses (UI, sampling)
random.random() for token            # FLAG: Security tokens need secrets module
```

---

## [HIGH] Output Format

```markdown
## Security Review: [File/Component Name]

### Summary
- **Findings**: X (Y Critical, Z High, ...)
- **Risk Level**: Critical/High/Medium/Low
- **Confidence**: High/Mixed

### Findings

#### [VULN-001] [Vulnerability Type] (Severity)
- **Location**: `file.py:123`
- **Confidence**: High
- **Issue**: [What the vulnerability is]
- **Impact**: [What an attacker could do]
- **Evidence**:
  ```python
  [Vulnerable code snippet]
  ```
- **Fix**: [How to remediate]

### Needs Verification

#### [VERIFY-001] [Potential Issue]
- **Location**: `file.py:456`
- **Question**: [What needs to be verified]
```

If no vulnerabilities found, state: "No high-confidence vulnerabilities identified."

See `reference.md` for OWASP-to-CWE mapping, severity decision tree, and review checklists.
