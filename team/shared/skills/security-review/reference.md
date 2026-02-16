# Security Review -- Reference

Supplementary material for SKILL.md: file index, OWASP-to-CWE mapping, severity decision tree, cross-skill handoff triggers, and review checklists.

---

## [HIGH] File Index

### [HIGH] Core Vulnerability References (`references/`)

| File | Covers | Key Patterns to Flag |
|------|--------|---------------------|
| `injection.md` | SQL, NoSQL, OS command, LDAP, template injection | String interpolation in queries, `eval()`, `exec()`, `os.system()` |
| `xss.md` | Reflected, stored, DOM-based XSS | `innerHTML`, `dangerouslySetInnerHTML`, `v-html`, `mark_safe()` |
| `authorization.md` | IDOR, privilege escalation, deny-by-default | Missing ownership checks, direct object references without authz |
| `authentication.md` | Sessions, credentials, password storage | Plaintext passwords, weak hashing (MD5/SHA1), missing MFA |
| `cryptography.md` | Algorithms, key management, randomness | ECB mode, `random` for tokens, hardcoded keys, DES/3DES/RC4 |
| `deserialization.md` | Pickle, YAML, Java, PHP deserialization | `pickle.loads()`, `yaml.load()`, `ObjectInputStream`, `unserialize()` |
| `file-security.md` | Path traversal, uploads, XXE | User-controlled file paths, missing extension validation, XML parsers |
| `ssrf.md` | Server-side request forgery | User-controlled URLs in `requests.get()`, `fetch()`, `http.Get()` |
| `csrf.md` | Cross-site request forgery | Missing CSRF tokens on state-changing endpoints |
| `data-protection.md` | Secrets exposure, PII, logging | API keys in code, PII in logs, sensitive data in URLs |
| `api-security.md` | REST, GraphQL, mass assignment | Missing rate limiting, unbounded queries, mass assignment |
| `business-logic.md` | Race conditions, workflow bypass | TOCTOU, missing idempotency, state machine bypass |
| `modern-threats.md` | Prototype pollution, LLM injection, WebSocket | `Object.assign()` with user input, unsanitized LLM prompts |
| `misconfiguration.md` | Headers, CORS, debug mode, defaults | `CORS: *`, debug=True in prod, default credentials |
| `error-handling.md` | Fail-open, information disclosure | Stack traces exposed, fail-open on exception |
| `supply-chain.md` | Dependencies, build security | Unpinned deps, typosquatting, compromised build scripts |
| `logging.md` | Audit failures, log injection | Missing audit logs, user input in log format strings |

### [MEDIUM] Language Guides (`languages/`)

| File | Scope | Framework-Specific Notes |
|------|-------|-------------------------|
| `python.md` | Django, Flask, FastAPI | Django auto-escaping, ORM parameterization, `mark_safe()` traps |
| `javascript.md` | Node, Express, React, Vue, Next.js | React auto-escaping, Express middleware, prototype pollution |

### [MEDIUM] Infrastructure Guides (`infrastructure/`)

| File | Scope | Key Checks |
|------|-------|------------|
| `docker.md` | Dockerfile, docker-compose | Root user, secret in build args, unpinned base images |

---

## [CRITICAL] OWASP Top 10 to CWE Mapping

| OWASP | CWE IDs | Reference Files | Critical Pattern |
|-------|---------|-----------------|-----------------|
| A01 Broken Access Control | CWE-200, CWE-284, CWE-285, CWE-352, CWE-639 | `authorization.md`, `csrf.md` | Missing ownership check on data access |
| A02 Cryptographic Failures | CWE-256, CWE-310, CWE-326, CWE-327, CWE-328 | `cryptography.md`, `data-protection.md` | Plaintext secrets, weak algorithms for security |
| A03 Injection | CWE-20, CWE-74, CWE-79, CWE-89, CWE-94 | `injection.md`, `xss.md` | String interpolation with user input in queries/commands |
| A04 Insecure Design | CWE-362, CWE-400, CWE-501, CWE-522 | `business-logic.md`, `api-security.md` | Race conditions, missing rate limiting |
| A05 Security Misconfiguration | CWE-16, CWE-209, CWE-215, CWE-611 | `misconfiguration.md`, `infrastructure/*` | Debug mode, default creds, permissive CORS |
| A06 Vulnerable Components | CWE-1035, CWE-1104 | `supply-chain.md` | Unpinned dependencies, known CVEs |
| A07 Auth Failures | CWE-255, CWE-287, CWE-384 | `authentication.md` | Weak password storage, session fixation |
| A08 Data Integrity Failures | CWE-502, CWE-829 | `deserialization.md`, `supply-chain.md` | Deserializing untrusted data |
| A09 Logging Failures | CWE-117, CWE-223, CWE-778 | `logging.md` | Missing audit trail, log injection |
| A10 SSRF | CWE-918 | `ssrf.md` | User-controlled URL in server-side requests |

---

## [CRITICAL] Severity Decision Tree

```
Is the input attacker-controlled?
  No  --> NOT a vulnerability (server config, constants, env vars)
  Yes --> Does the framework auto-mitigate? (auto-escaping, ORM parameterization)
    Yes --> Is mitigation explicitly bypassed? (mark_safe, dangerouslySetInnerHTML, .raw())
      No  --> NOT a vulnerability
      Yes --> VULNERABLE (severity depends on impact)
    No  --> Is there upstream validation/sanitization?
      Yes --> Likely safe (note as VERIFY if unsure)
      No  --> VULNERABLE
        Can attacker achieve RCE or full data access? --> CRITICAL
        Requires conditions but significant impact?   --> HIGH
        Specific conditions, moderate impact?          --> MEDIUM
        Defense-in-depth only?                         --> LOW (do not report)
```

---

## [HIGH] Cross-Skill Handoff Triggers

When a security review finding requires implementation work, hand off to the appropriate skill:

| Finding Type | Hand Off To | Trigger |
|-------------|-------------|---------|
| Error leaks stack traces, sensitive data in error responses | `error-handling-logging` | Info disclosure via error messages (CWE-209) |
| Missing structured logging, audit trail gaps | `error-handling-logging` | Logging failures (A09/CWE-778) |
| Docker running as root, secrets in build args/layers | `docker-expert` | Container misconfig needs remediation |
| CI/CD secrets in logs, workflow injection via `${{ }}` | `ci-cd-deployment` | Pipeline secret leak needs workflow redesign |
| Auth bypass, JWT not verified, session fixation | `supabase-auth-patterns` | Auth flaw needs correct flow implementation |
| RLS policy missing or bypassable | `supabase-auth-patterns` | Authorization gap in Supabase context |
| SQL injection found, need regression test | `testing-strategy` | Security finding needs test coverage |
| Prototype pollution, type confusion | `typescript-best-practices` | Type-level fix needed for runtime safety |

---

## [HIGH] Review Checklist

### [CRITICAL] Pre-Review
- [ ] Identify code type (API, frontend, infra, crypto)
- [ ] Load relevant reference files from index above
- [ ] Load language guide matching file extension
- [ ] Load infrastructure guide if reviewing config files

### [CRITICAL] For Each Potential Finding
- [ ] Trace data flow: where does the input originate?
- [ ] Check: is it attacker-controlled or server-controlled?
- [ ] Check: does the framework auto-mitigate this pattern?
- [ ] Check: is there validation/sanitization upstream?
- [ ] Check: is the mitigation explicitly bypassed?
- [ ] Assign confidence: HIGH (report), MEDIUM (verify), LOW (skip)
- [ ] Assign severity using decision tree above with CWE ID

### [HIGH] Post-Review
- [ ] All findings have evidence (code snippet + location)
- [ ] All findings have CWE ID and OWASP category
- [ ] All findings have remediation guidance
- [ ] No false positives from server-controlled values
- [ ] No false positives from framework auto-mitigation
- [ ] VERIFY items clearly state what needs confirmation
- [ ] Cross-skill handoffs noted where implementation is needed

---

## [MEDIUM] Common False Positive Patterns

Avoid flagging these unless bypass is explicitly used:

| Pattern | Why Safe | Flag Only When |
|---------|----------|----------------|
| Django `{{ var }}` | Auto-escaped | `{{ var\|safe }}`, `{% autoescape off %}` |
| React `{var}` | Auto-escaped | `dangerouslySetInnerHTML` |
| Vue `{{ var }}` | Auto-escaped | `v-html` |
| ORM `.filter(field=input)` | Parameterized | `.raw()`, `.extra()`, `RawSQL()` + interpolation |
| `cursor.execute("...%s", (input,))` | Parameterized | `f"...{input}"` in query string |
| `requests.get(settings.URL)` | Server-controlled | `requests.get(request.GET['url'])` |
| `hashlib.md5(file_bytes)` | Checksum use | `hashlib.md5(password)` |
| `random.random()` | Non-security use | Used for tokens, secrets, or session IDs |
| `os.environ.get('KEY')` | Deployment config | Never attacker-controlled |
| `innerHTML = "<b>Loading</b>"` | Constant string | `innerHTML = userInput` |
