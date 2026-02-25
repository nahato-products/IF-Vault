# Security Review -- Reference

Supplementary material: file index, OWASP-to-CWE mapping, severity decision tree, cross-skill handoff, review checklists, vulnerability references, language guides, infrastructure patterns.

---

## [CRITICAL] OWASP Top 10 to CWE Mapping

| OWASP | CWE IDs | Reference Sections | Critical Pattern |
|-------|---------|-----------------|-----------------|
| A01 Broken Access Control | CWE-200, CWE-284, CWE-285, CWE-352, CWE-639 | Authorization, CSRF | Missing ownership check on data access |
| A02 Cryptographic Failures | CWE-256, CWE-310, CWE-326, CWE-327, CWE-328 | Cryptography, Data Protection | Plaintext secrets, weak algorithms |
| A03 Injection | CWE-20, CWE-74, CWE-79, CWE-89, CWE-94 | Injection, XSS | String interpolation with user input in queries/commands |
| A04 Insecure Design | CWE-362, CWE-400, CWE-501, CWE-522 | Business Logic, API Security | Race conditions, missing rate limiting |
| A05 Security Misconfiguration | CWE-16, CWE-209, CWE-215, CWE-611 | Misconfiguration, Docker | Debug mode, default creds, permissive CORS |
| A06 Vulnerable Components | CWE-1035, CWE-1104 | Supply Chain | Unpinned dependencies, known CVEs |
| A07 Auth Failures | CWE-255, CWE-287, CWE-384 | Authentication | Weak password storage, session fixation |
| A08 Data Integrity Failures | CWE-502, CWE-829 | Deserialization, Supply Chain | Deserializing untrusted data |
| A09 Logging Failures | CWE-117, CWE-223, CWE-778 | Logging | Missing audit trail, log injection |
| A10 SSRF | CWE-918 | SSRF | User-controlled URL in server-side requests |

---

## [CRITICAL] Severity Decision Tree

```
Is input attacker-controlled?
  No  --> NOT vulnerability (server config, constants, env vars)
  Yes --> Framework auto-mitigate? (auto-escaping, ORM parameterization)
    Yes --> Mitigation explicitly bypassed? (mark_safe, dangerouslySetInnerHTML, .raw())
      No  --> NOT vulnerability
      Yes --> VULNERABLE (severity by impact)
    No  --> Upstream validation/sanitization?
      Yes --> Likely safe (note as VERIFY if unsure)
      No  --> VULNERABLE
        RCE or full data access? --> CRITICAL
        Requires conditions, significant impact? --> HIGH
        Specific conditions, moderate impact? --> MEDIUM
        Defense-in-depth only? --> LOW (skip)
```

---

## [HIGH] Cross-Skill Handoff Triggers

| Finding Type | Hand Off To | Trigger |
|-------------|-------------|---------|
| Error leaks stack traces, sensitive data | `error-handling-logging` | Info disclosure (CWE-209) |
| Missing structured logging, audit trail gaps | `error-handling-logging` | Logging failures (A09/CWE-778) |
| Docker root, secrets in build args/layers | `docker-expert` | Container misconfig |
| CI/CD secrets in logs, workflow injection | `ci-cd-deployment` | Pipeline secret leak |
| Auth bypass, JWT not verified, session fixation | `supabase-auth-patterns` | Auth flaw |
| RLS policy missing or bypassable | `supabase-auth-patterns` | Authorization gap |
| SQL injection, need regression test | `testing-strategy` | Security finding needs test |
| Prototype pollution, type confusion | `typescript-best-practices` | Type-level fix |

---

## [HIGH] Review Checklist

### [CRITICAL] Pre-Review
- [ ] Identify code type (API, frontend, infra, crypto)
- [ ] Load relevant reference sections
- [ ] Check language-specific patterns
- [ ] Check infrastructure patterns if config files

### [CRITICAL] For Each Potential Finding
- [ ] Trace data flow: input origin?
- [ ] Attacker-controlled or server-controlled?
- [ ] Framework auto-mitigate?
- [ ] Validation/sanitization upstream?
- [ ] Mitigation explicitly bypassed?
- [ ] Assign confidence: HIGH (report), MEDIUM (verify), LOW (skip)
- [ ] Assign severity using decision tree + CWE ID

### [HIGH] Post-Review
- [ ] All findings have evidence (code snippet + location)
- [ ] All findings have CWE ID and OWASP category
- [ ] All findings have remediation guidance
- [ ] No false positives from server-controlled values
- [ ] No false positives from framework auto-mitigation
- [ ] VERIFY items clearly state what needs confirmation
- [ ] Cross-skill handoffs noted where needed

---

## [MEDIUM] Common False Positive Patterns

| Pattern | Why Safe | Flag Only When |
|---------|----------|----------------|
| Django `{{ var }}` | Auto-escaped | `{{ var\|safe }}`, `{% autoescape off %}` |
| React `{var}` | Auto-escaped | `dangerouslySetInnerHTML` |
| Vue `{{ var }}` | Auto-escaped | `v-html` |
| ORM `.filter(field=input)` | Parameterized | `.raw()`, `.extra()`, `RawSQL()` + interpolation |
| `cursor.execute("...%s", (input,))` | Parameterized | `f"...{input}"` in query |
| `requests.get(settings.URL)` | Server-controlled | `requests.get(request.GET['url'])` |
| `hashlib.md5(file_bytes)` | Checksum use | `hashlib.md5(password)` |
| `random.random()` | Non-security use | Tokens, secrets, session IDs |
| `os.environ.get('KEY')` | Deployment config | Never attacker-controlled |
| `innerHTML = "<b>Loading</b>"` | Constant string | `innerHTML = userInput` |

---

## Injection Prevention

### SQL Injection

**Parameterized queries (required):**

```python
# SAFE
cursor.execute("SELECT * FROM users WHERE username = %s", (user_input,))
```

```javascript
// SAFE (node-postgres)
const result = await client.query('SELECT * FROM users WHERE id = $1', [userId]);
```

**Vulnerable patterns:**

```python
# VULNERABLE: String interpolation
query = f"SELECT * FROM users WHERE id = {user_id}"
query = "SELECT * FROM users WHERE name = '{}'".format(user_input)
```

```javascript
// VULNERABLE: Template literal
const query = `SELECT * FROM users WHERE id = ${userId}`;
```

**ORM safety:** Django ORM `.filter()` is parameterized. Flag `.raw()`, `.extra()`, `RawSQL()` with interpolation. SQLAlchemy `.query().filter()` safe; flag `text()` with f-strings.

### NoSQL Injection (MongoDB)

```javascript
// VULNERABLE: Operator injection
db.users.find({ username: req.body.username, password: req.body.password });
// Attack: { "password": { "$gt": "" } }

// SAFE: Type coercion
db.users.find({ username: String(req.body.username), password: String(req.body.password) });
```

Dangerous operators: `$where` (JS execution), `$regex` (ReDoS), `$gt`/`$ne`/`$in`.

### OS Command Injection

```python
# VULNERABLE
os.system(f"cmd {user_input}")
subprocess.run(cmd, shell=True)  # If cmd has user input

# SAFE: List of arguments
subprocess.run(["convert", input_file, output_file], shell=False)
```

Dangerous functions: Python (`os.system`, `subprocess(shell=True)`, `os.popen`, `eval`, `exec`), JavaScript (`child_process.exec`, `eval`), PHP (`exec`, `shell_exec`, `system`, `passthru`), Ruby (`system`, `exec`, backticks).

### Template Injection (SSTI)

```python
# VULNERABLE
Template(f"Hello {user_input}")

# SAFE
Template("Hello {{ name }}").render(name=user_input)
```

### LDAP/XPath Injection

Escape special characters for LDAP filters (`* ( ) \ NUL`) and DN context (`\ # + < > ; " = /`). Use parameterized XPath.

---

## Cross-Site Scripting (XSS)

### XSS Types

| Type | Description |
|------|-------------|
| Reflected | Malicious script from current HTTP request |
| Stored | Malicious script stored on server |
| DOM-based | Vulnerability in client-side code |

### Output Encoding by Context

**HTML body:** Use `textContent` or `createTextNode` instead of `innerHTML`. **HTML attributes:** Always quote, never in event handlers. **JavaScript context:** Never `eval(userInput)`, use `JSON.parse()`. **URL context:** Validate scheme (`http:`/`https:`), use `encodeURIComponent()`. **CSS context:** Never allow user input in selectors or URLs.

### Safe vs Dangerous DOM APIs

**Safe:** `elem.textContent`, `elem.innerText`, `elem.setAttribute('data-x', v)`, `document.createTextNode(v)`.

**Dangerous (flag with user input):** `elem.innerHTML`, `elem.outerHTML`, `document.write()`, `elem.insertAdjacentHTML()`, `eval()`, `new Function()`, `setTimeout(string)`, `setInterval(string)`.

### HTML Sanitization

Use DOMPurify: `DOMPurify.sanitize(dirty, { ALLOWED_TAGS: ['b','i','a'], ALLOWED_ATTR: ['href'] })`.

### Content Security Policy (CSP)

Strict CSP: `default-src 'self'; script-src 'nonce-{RANDOM}' 'strict-dynamic'; object-src 'none'; base-uri 'none'`.

### DOM-based XSS Sources

`location.hash`, `location.search`, `document.referrer`, `window.name`, `postMessage data` -- validate and encode before DOM sinks.

---

## Authorization

### Core Principles

1. **Deny by default** -- explicit grants only.
2. **Least privilege** -- minimum permissions.
3. **Validate every request** -- never rely on UI hiding.

### IDOR (Insecure Direct Object References)

```python
# VULNERABLE
@app.route('/api/orders/<order_id>')
def get_order(order_id):
    return Order.query.get(order_id).to_dict()

# SAFE: Scope to current user
order = Order.query.filter_by(id=order_id, user_id=current_user.id).first_or_404()
```

### Privilege Escalation

Horizontal (access others' resources) and vertical (access admin functions). Check object-level permissions, not just type-level. Validate paths with `os.path.realpath()` + prefix check.

### Mass Assignment

```python
# VULNERABLE
user.update(**request.json)  # Attacker sets is_admin=True

# SAFE: Allowlist
ALLOWED = {'name', 'email', 'bio'}
data = {k: v for k, v in request.json.items() if k in ALLOWED}
```

---

## Authentication

### Password Storage

Recommended: Argon2id, scrypt, bcrypt (work factor 10+), PBKDF2 (600k+ iterations, HMAC-SHA-256). **Never:** MD5, SHA1, SHA256 without key stretching, plain hash without salt.

### Error Messages

Identical messages regardless of failure: `"Login failed; Invalid user ID or password."` Never reveal account existence.

### Session Security

- Entropy: min 64 bits (`secrets.token_hex(32)`)
- Cookie flags: `Secure`, `HttpOnly`, `SameSite=Lax`
- Regenerate session ID after auth (prevent fixation)
- Idle timeout (15-30 min), absolute timeout (4-8 hours)

### Brute Force Protection

Account lockout (5 failures, 30-min lockout), exponential backoff, rate limiting per-IP and per-account. Allow password reset when locked.

### MFA

WebAuthn/FIDO2 preferred (phishing-resistant). Support multiple methods. Require re-auth before disabling MFA.

---

## Cryptography

### Symmetric Encryption

**Use:** AES-256-GCM (preferred), AES-128-GCM, ChaCha20-Poly1305. **Avoid:** DES, 3DES, RC4, AES-ECB, AES-CBC without authentication.

### Secure Random

| Language | Safe | Unsafe |
|----------|------|--------|
| Python | `secrets`, `os.urandom()` | `random` module |
| JavaScript | `crypto.randomBytes()`, `crypto.randomUUID()` | `Math.random()` |
| Java | `SecureRandom` | `Math.random()`, `java.util.Random` |
| Go | `crypto/rand` | `math/rand` |

### Key Management

Never hardcode. Use HSM, cloud KMS, or secrets managers. Store keys separately from encrypted data. Implement rotation.

### Common Vulnerabilities

ECB mode (reveals patterns), static IV/nonce, insufficient key size, CBC without HMAC (padding oracle), hardcoded keys.

---

## Deserialization

### Critical: Always Flag

```python
pickle.loads(untrusted_data)  # RCE
yaml.load(untrusted_data)     # RCE via !!python/object
marshal.loads(untrusted_data)
```

```java
ObjectInputStream.readObject()  // RCE via gadget chains
```

```csharp
BinaryFormatter.Deserialize()  // "Cannot be made secure" -- Microsoft
```

```php
unserialize($_GET['data'])  // RCE via __wakeup, __destruct
```

### Safe Alternatives

Use JSON with schema validation. Python: `json.loads()` + Pydantic. YAML: `yaml.safe_load()`. Java: `ObjectMapper.readValue(json, DTO.class)`. Sign with HMAC if native serialization required.

---

## File Security

### Path Traversal

```python
# VULNERABLE
return send_file(f'/uploads/{request.args.get("file")}')
# Attack: ?file=../../../etc/passwd

# SAFE: Validate and canonicalize
base = Path(base_directory).resolve()
target = (base / user_path).resolve()
if not str(target).startswith(str(base)):
    raise ValueError("Path traversal detected")
```

Block `..`, `~`, `%2e%2e`, `%00` and URL-encoded variants.

### File Upload Security

1. Check size. 2. Validate extension (allowlist). 3. Validate MIME (magic bytes, not header). 4. Match extension to content. 5. Generate safe filename (UUID). 6. Store outside webroot. 7. Restrictive permissions (0o640).

### XXE Prevention

```python
# SAFE: defusedxml
import defusedxml.ElementTree as ET
doc = ET.parse(untrusted_file)

# Or disable entities in lxml
parser = etree.XMLParser(resolve_entities=False, no_network=True)
```

### ZIP Security

Validate paths in ZIP entries (Zip Slip). Check compression ratio (Zip Bomb, limit 100:1).

---

## SSRF (Server-Side Request Forgery)

### Prevention Strategies

1. **Allowlist** domains when known.
2. **Block internal networks**: 127.0.0.0/8, 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, 169.254.0.0/16 (metadata), plus IPv6.
3. **Disable redirects** or validate each.
4. **DNS pinning** against rebinding.
5. **Cloud metadata protection**: IMDSv2 (AWS), block 169.254.169.254.

### Bypass Techniques to Block

URL encoding (`169%2e254%2e169%2e254`), octal (`0251.0376.0251.0376`), hex (`0xa9fea9fe`), decimal (`2852039166`), IPv6 (`[::1]`, `[::ffff:127.0.0.1]`), localhost alternatives (`127.0.0.2`, `127.1`).

---

## CSRF (Cross-Site Request Forgery)

### Primary Defenses

1. **Synchronizer token**: unique per session, validate with `secrets.compare_digest()`.
2. **Double submit cookie**: cryptographically signed, stateless.
3. **SameSite cookie**: `Lax` (default), `Strict` (maximum).
4. **Custom headers**: AJAX/API (`X-CSRF-Token`), can't be set cross-origin without CORS.
5. **Fetch Metadata**: `Sec-Fetch-Site`, `Sec-Fetch-Mode` for modern browsers.

### Common Mistakes

GET for state changes (use POST). CORS reflecting origin with credentials. Token in URL (logged, cached). `@csrf_exempt` without reason.

---

## Data Protection

### Information Disclosure Prevention

- Generic errors (no stack traces, SQL errors, paths).
- API response filtering (explicit fields, never `__dict__`).
- Remove headers (`Server`, `X-Powered-By`).
- No-cache headers for sensitive pages.

### Logging Security

Never log: passwords, API keys, credit cards, SSNs, session tokens. Mask: `api_key[:4] + '****'`. Prevent log injection: sanitize newlines/control chars, use structured JSON.

---

## API Security

### JWT Best Practices

Explicit algorithm (`algorithms=['HS256']`), never `none`. Validate issuer, audience, expiration.

### Rate Limiting

Login: 5/min. Password reset: 3/hour. General API: 200/day, 50/hour. Return `X-RateLimit-*` headers, `429` responses.

### GraphQL Security

Limit query depth (max 5), query cost analysis, disable introspection in prod, limit batch size (max 10).

### CORS Configuration

Never `Access-Control-Allow-Origin: *` with credentials. Use explicit allowlist. Never reflect origin without validation.

---

## Business Logic

### Race Conditions (TOCTOU)

```python
# SAFE: Database locking
@transaction.atomic
def transfer(from_id, to_id, amount):
    from_acc = Account.objects.select_for_update().get(id=from_id)
    to_acc = Account.objects.select_for_update().get(id=to_id)
    if from_acc.balance >= amount:
        from_acc.balance -= amount
        to_acc.balance += amount
        from_acc.save(); to_acc.save()
```

### Workflow Bypass

Enforce server-side state machines. Validate every step transition.

### Numeric Manipulation

Validate ranges (no negative quantities). Use `Decimal` for financial (not float). Cap discounts. Calculate prices server-side.

### Idempotency

Use idempotency keys for critical operations (payments, transfers).

---

## Modern Threats

### Prototype Pollution (JavaScript)

```javascript
// VULNERABLE: merge without __proto__ check
merge({}, JSON.parse(userInput));  // {"__proto__": {"isAdmin": true}}

// SAFE: Skip dangerous keys or use Map/Object.create(null)
```

### DOM Clobbering

Named HTML elements become properties on `document`/`window`. Use `window.location` explicitly, check property types.

### WebSocket Security

Validate Origin header, require auth, validate messages against schema, rate limiting, protect against CSWSH.

### LLM Prompt Injection

Separate user input from system prompts with clear boundaries. Sanitize injection patterns. Validate output. Mark external content untrusted.

---

## Security Misconfiguration

### Security Headers Checklist

| Header | Secure Value |
|--------|--------------|
| `X-Content-Type-Options` | `nosniff` |
| `X-Frame-Options` | `DENY` or `SAMEORIGIN` |
| `Strict-Transport-Security` | `max-age=31536000; includeSubDomains` |
| `Content-Security-Policy` | Restrictive policy |
| `Referrer-Policy` | `strict-origin-when-cross-origin` |
| `Permissions-Policy` | Disable unused features |

### Debug Mode

Flag `debug=True`, `DEBUG=True`, `FLASK_ENV=development` in prod. Exposes stack traces, may allow code execution.

### Default Credentials

Flag `admin/admin`, `root/root`, `password`, `123456`, `changeme`, hardcoded `SECRET_KEY`.

### TLS/SSL

Flag `verify=False`, TLS < 1.2, weak ciphers (`ALL`, `DEFAULT`). Require `CERT_REQUIRED`, `check_hostname=True`.

### Cookie Security

Require: `Secure`, `HttpOnly`, `SameSite=Lax`. Flag missing flags, `SameSite=None`.

---

## Error Handling

### Fail-Open Patterns (Always Flag)

```python
# VULNERABLE: Allows access on service failure
except ServiceUnavailable:
    return True  # Fail-open!

# SAFE: Deny on error
except ServiceUnavailable:
    return False
```

### Exception Swallowing

Flag bare `except: pass` around validation, auth checks, security-critical code. Handle specific exceptions.

### Differential Error Messages

Flag different messages for "user not found" vs "wrong password" (user enumeration). Use constant-time comparison with dummy hash.

### Resource Cleanup

Use context managers (`with`) or `try/finally` to prevent resource leaks.

---

## Supply Chain

### Dependencies

Pin exact versions. Commit lock files. Run `npm audit` / `pip-audit`. Watch typosquatting.

### Dependency Confusion

Scope internal packages (`@company/`). Claim names on public registries. Configure registry priority.

### CI/CD Security

Pin GitHub Actions to commit hashes. Use `${{ secrets.X }}` for secrets. Use `pull_request` not `pull_request_target` for untrusted PRs. Minimal permissions.

### Malicious Package Indicators

Network calls in `setup.py`/`preinstall` scripts. Obfuscated code (`eval(base64.b64decode(...))`). Environment variable exfiltration.

---

## Security Logging

### Required Security Events

Login success/failure, password changes, access denied, permission changes, admin actions, data exports, API key management. Include user ID, IP, timestamp.

### Log Injection Prevention

Sanitize newlines/control chars. Use structured JSON. Use parameterized logging.

### Log Storage

Restrict permissions (0o600). Log rotation. Store outside web-accessible dirs. Centralized logging with TLS.

### Alerting

Failed logins > 5/hour, access denied > 10/hour, admin login from new IP, privilege escalation, large data exports.

### Audit Trail

Append-only with chained checksums. No delete. Retention per compliance (security events 1 year, audit trail 7 years).

---

## Python Security Patterns

### Framework Detection

| Indicator | Framework |
|-----------|-----------|
| `from django`, `settings.py`, `urls.py`, `views.py` | Django |
| `from flask`, `@app.route` | Flask |
| `from fastapi`, `@app.get`, `@app.post` | FastAPI |

### Django

**Server-controlled (NEVER flag):** `settings.EXTERNAL_API_URL`, `os.environ.get()`, `settings.DATABASE_URL` -- deployment config.

**Auto-escaped (safe):** `{{ variable }}`, `User.objects.filter(username=input)`, `{% csrf_token %}`.

**Flag:** `{{ var|safe }}`, `{% autoescape off %}`, `mark_safe(user_input)`, `.raw(f"...")`, `.extra(where=[f"..."])`, `cursor.execute(f"...")`, `RawSQL(f"...")`. Settings: `DEBUG=True`, `ALLOWED_HOSTS=['*']`, hardcoded `SECRET_KEY`, missing security middleware.

### Flask

**Safe:** `{{ variable }}` (Jinja2 auto-escapes), `db.session.query().filter()`, `form.validate_on_submit()`.

**Flag:** `Markup(user_input)`, `render_template_string(user_input)` (SSTI), `{{ var|safe }}`, `db.engine.execute(f"...")`, `text(f"...")`, `app.secret_key = 'hardcoded'`, `app.run(debug=True)`.

### FastAPI

**Safe:** Pydantic validates input, typed path parameters, SQLAlchemy ORM.

**Flag:** `db.execute(f"...")`, unvalidated response dicts.

### General Python

**Always flag:** `pickle.loads/load`, `yaml.load` (without SafeLoader), `eval`, `exec`, `compile`, `__import__`, `os.system`, `subprocess(shell=True)`.

**Check context:** `requests.get(url)` (SSRF if user-controlled), `open(user_path)` (path traversal), `hashlib.md5(password)` (weak for passwords, fine for checksums), `random.random()` (weak for tokens).

### SQLAlchemy

**Safe:** `session.query(User).filter(User.name == name)`, `text("...WHERE id = :id"), {"id": id}`.

**Flag:** `session.execute(f"SELECT ... {name}")`, `text(f"... {id}")`.

### Python Grep Patterns

```bash
grep -rn "mark_safe\||safe\|autoescape off\|\.raw(\|\.extra(" --include="*.py"
grep -rn "render_template_string\|Template(" --include="*.py"
grep -rn "pickle\.load\|yaml\.load\|marshal\.load" --include="*.py"
grep -rn "os\.system\|subprocess.*shell=True\|os\.popen" --include="*.py"
grep -rn "execute.*f\"\|execute.*%\|\.raw.*f\"" --include="*.py"
```

---

## JavaScript/TypeScript Security Patterns

### Framework Detection

| Indicator | Framework |
|-----------|-----------|
| `import React`, `jsx/tsx`, `useState` | React |
| `import Vue`, `.vue`, `v-bind` | Vue |
| `import express`, `app.get/post` | Express |
| `import next`, `getServerSideProps` | Next.js |
| `import angular`, `@Component` | Angular |

### React

**Auto-escaped (safe):** `<div>{userInput}</div>`, `<div className={userInput}>`.

**Flag:** `dangerouslySetInnerHTML={{__html: userInput}}`, `<a href={userInput}>` (javascript: protocol), `eval(userInput)`, `new Function(userInput)`, `setTimeout(userInput, ms)` (string).

### Vue

**Auto-escaped (safe):** `<div>{{ userInput }}</div>`.

**Flag:** `<div v-html="userInput">`, `Vue.compile(userInput)`, `new Vue({ template: userInput })`, `<component :is="userInput" />`.

### Express / Node.js

**Safe:** Sequelize `findOne({ where: ... })`, `res.json()`, template engines default escaping.

**Flag:** `db.query(\`SELECT ... ${userId}\`)`, `db.collection.find({ $where: userInput })`, `exec(userInput)`, `execSync(userInput)`, `spawn(cmd, { shell: true })`, `res.sendFile(userPath)`, `fetch(userUrl)`, `Object.assign(target, userObject)`, `_.merge(target, userObject)`.

### MongoDB Injection

```javascript
// VULNERABLE: Operator injection
db.users.find({ username: req.body.username, password: req.body.password });
// SAFE: Schema validation (Mongoose) or String() coercion
```

### Next.js

**Flag:** `fetch(query.url)` in `getServerSideProps` (SSRF), `NEXT_PUBLIC_` env vars (exposed to client), `dangerouslySetInnerHTML` with props content.

### Angular

**Flag:** `bypassSecurityTrustHtml/Script/Url/ResourceUrl(userInput)`.

### General JavaScript

**Always flag:** `eval()`, `new Function()`, `document.write(userInput)`, `element.innerHTML = userInput`, `element.outerHTML = userInput`.

**Safe DOM:** `element.textContent`, `element.innerText`, `element.setAttribute('data-x', v)`.

### TypeScript

Types don't validate at runtime. `req.body as UserInput` has no validation. Use Zod: `z.object({...}).parse(req.body)`. Flag `any` in security-critical code.

### Prototype Pollution

Flag `Object.assign(target, userInput)`, `_.merge()` (lodash < 4.17.12), `$.extend(true, ...)`, custom merge without `__proto__`/`constructor` checks.

**Safe:** `Object.create(null)`, `Map`, freeze prototypes.

### JS/TS Grep Patterns

```bash
grep -rn "innerHTML\|outerHTML\|document\.write" --include="*.js" --include="*.jsx" --include="*.ts" --include="*.tsx"
grep -rn "dangerouslySetInnerHTML" --include="*.jsx" --include="*.tsx"
grep -rn "v-html" --include="*.vue"
grep -rn "eval(\|new Function(\|setTimeout.*string" --include="*.js" --include="*.ts"
grep -rn "child_process\|exec(\|execSync(\|spawn(" --include="*.js" --include="*.ts"
grep -rn "__proto__\|constructor\[" --include="*.js" --include="*.ts"
grep -rn "bypassSecurityTrust" --include="*.ts"
```

---

## Docker Security Patterns

### Dockerfile Security

**Running as root:**
```dockerfile
# VULNERABLE: default root
FROM node:18
CMD ["node", "app.js"]

# SAFE: non-root user
FROM node:18
RUN groupadd -r app && useradd -r -g app app
USER app
```

**Base images:** Pin versions with digest (`node:18.19.0-alpine@sha256:abc...`). Never `:latest`. Use official images.

**Secrets in images:** Never `ARG DB_PASSWORD`, `COPY .env`, or `ENV API_KEY=sk-...`. Use multi-stage builds with `--mount=type=secret`. Mount secrets at runtime.

**Package installation:** Use `--no-install-recommends`, clean caches (`rm -rf /var/lib/apt/lists/*`). Use minimal base images (alpine, distroless).

**COPY vs ADD:** Prefer COPY. ADD auto-extracts and fetches URLs.

**Exposed ports:** Flag SSH (22), database ports (3306, 5432). Only expose necessary ports.

### Runtime Security

- Flag `--privileged`, `--cap-add=ALL`, `--cap-add=SYS_ADMIN`.
- Flag Docker socket mount (`/var/run/docker.sock`) -- equals root on host.
- Flag `--network=host` (no isolation).
- Flag no resource limits (DoS risk). Set `--memory`, `--cpus`, `--pids-limit`.
- Use `--cap-drop=ALL --cap-add=NET_BIND_SERVICE`, `--read-only`, `--security-opt=no-new-privileges`.

### Docker Compose Security

**Secrets:** Use `secrets:` directive, not `environment:` for passwords. **Privileges:** Set `user: "1000:1000"`, `read_only: true`, `cap_drop: [ALL]`. **Networks:** Use `internal: true` for backend services.

### .dockerignore

Must exclude: `.env`, `*.pem`, `*.key`, `id_rsa*`, `secrets/`, `.git/`, `node_modules/`.

### Docker Grep Patterns

```bash
grep -rn "^USER" Dockerfile || echo "No USER directive - runs as root"
grep -rn "^ENV.*PASSWORD\|^ENV.*SECRET\|^ENV.*KEY\|^ENV.*TOKEN" Dockerfile
grep -rn "^ARG.*PASSWORD\|^ARG.*SECRET\|^ARG.*KEY" Dockerfile
grep -rn "FROM.*:latest" Dockerfile
grep -rn "^ADD\|EXPOSE 22" Dockerfile
```

---

## MCP / Multi-AI Security Boundaries (Full Reference)

MCP経由で外部AIツール（Codex等）を統合する場合、セキュリティ境界が変わる。3層防御モデルでチェック:

### 3-Layer Defense Model

| Layer | 対策 | 技術的強制力 | チェック項目 |
|-------|------|------------|-------------|
| **L1: Static deny** | settings.json の `permissions.deny` | **強** — ツール実行前にブロック | `.env*`, `*.pem`, `secrets/` の Read/Write が deny されているか |
| **L2: Dynamic hooks** | PreToolUse/PostToolUse hooks | **強** — パターンマッチでブロック | force push, `rm -rf`, network exfiltration がhookで検出されるか |
| **L3: Prompt constraints** | MCP呼び出し時の developer-instructions | **弱** — LLMの善意に依存 | MUST/NEVERで記述されているか、「推奨」「できれば」は不可 |

### MCP境界の既知の穴

**L1/L2はMCP経由の内部挙動に適用されない。** Claude Code の deny/hooks は Claude のツール呼び出し（Read/Write/Bash）を制御するが、MCP サーバーが内部でファイルアクセスする挙動までは制御できない。

**Known CVEs:**
- CVE-2025-68145: Git MCP Server RCE via crafted repo
- CVE-2025-55284: Claude Code DNS exfiltration of API keys via malicious `.claude/settings.json`
- Rules File Backdoor: `.cursorrules`/`.claude/` に悪意あるプロンプト注入 → コード生成を汚染

### MCP Security Checklist

- [ ] MCP サーバーの sandbox 権限は最小か（read-only がデフォルト、workspace-write は明示承認）
- [ ] developer-instructions にセキュリティルールが MUST/NEVER で注入されているか
- [ ] MCP 出力に機密情報（API key, token, PII）が含まれていないか（2段階レビューで検証）
- [ ] セキュリティ敏感タスク（認証・認可・暗号化）はMCP委譲せずClaude直接実行か
- [ ] MCP呼び出しのリトライ上限が設定されているか（無限ループ防止）
- [ ] 技術的強制（L1/L2）と運用的担保（L3）の境界が文書化されているか
- [ ] `.claude/` や project settings のレビュー — 外部リポジトリclone時に悪意ある設定が混入していないか

### AI/LLM Prompt Injection

AIツール統合時の追加チェック:
- **Indirect prompt injection**: MCP tool出力やDB内容に攻撃プロンプトが埋め込まれ、AIの次の行動を操作。Flag: ツール結果をそのまま次のプロンプトに渡すパターン
- **Tool result poisoning**: 外部API/DBからの応答にHTML/Markdownで不可視テキストを仕込み、AIの判断を誘導。Flag: 外部データのサニタイズなしでのAI入力
- **Exfiltration via tool calls**: AIに機密情報をURL/webhook経由で外部送信させる。Flag: AIが動的URLにアクセスするフロー

---

## References

- [OWASP Cheat Sheet Series](https://cheatsheetseries.owasp.org/) (CC BY-SA 4.0)
- [OWASP Top 10](https://owasp.org/Top10/)
- [OWASP API Security Top 10](https://owasp.org/www-project-api-security/)
- [CWE - Common Weakness Enumeration](https://cwe.mitre.org/)
- [Docker Security Best Practices](https://docs.docker.com/develop/security-best-practices/)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
