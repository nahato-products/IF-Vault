---
name: security-review
description: "Detect exploitable security vulnerabilities including SQLi, XSS, SSRF, CSRF, IDOR, path traversal, injection, hardcoded secrets, and OWASP Top 10 patterns with confidence-level triage. Use when reviewing code for security issues, auditing authentication flows, checking for secret leaks, validating input sanitization, or assessing MCP/multi-AI security boundaries."
user-invocable: false
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
| Flags fail-open error as vuln | `error-handling-logging` | Error leaks stack trace? Here. Need retry? That skill |
| Flags Docker misconfig (root, secrets in layers) | `docker-expert` | Root user? Here. Multi-stage build? That skill |
| Audits CI/CD for secret leaks, workflow injection | `ci-cd-deployment` | Secret in logs? Here. Deploy pipeline? That skill |
| Audits auth bypass, token weakness, session flaws | `supabase-auth-patterns` | JWT not verified? Here. OAuth flow? That skill |
| Identifies what to test for security regressions | `testing-strategy` | Found SQLi? Here + suggest test. Test suite? That skill |

## [CRITICAL] Research vs. Reporting Scope

- **Report on**: Only the specific file, diff, or code provided by the user
- **Research**: The ENTIRE codebase to build confidence before reporting

Before flagging, MUST research: Where does input come from? Validation/sanitization elsewhere? Config/middleware? Framework protections?

**Do NOT report issues based solely on pattern matching.** Investigate first, report only confirmed exploitables.

## [CRITICAL] Confidence Levels

| Level | Criteria | Action |
|-------|----------|--------|
| **HIGH** | Vulnerable pattern + attacker-controlled input confirmed | **Report** with severity |
| **MEDIUM** | Vulnerable pattern, input source unclear | **Note** as "Needs verification" |
| **LOW** | Theoretical, best practice, defense-in-depth | **Do not report** |

## [HIGH] Do Not Flag

- Test files (unless explicitly reviewing test security)
- Dead code, commented code, documentation strings
- Patterns using **constants** or **server-controlled configuration**
- Code paths requiring prior authentication (note auth requirement instead)

Server-controlled values (settings, env vars, config) are NOT attacker-controlled -- do not flag. Only flag when input comes from request/user data.

### [HIGH] Framework-Mitigated Patterns
Check language guides before flagging (common false positive patterns: see reference.md).

**Only flag these when:**
- Django: `{{ var|safe }}`, `{% autoescape off %}`, `mark_safe(user_input)`
- React: `dangerouslySetInnerHTML={{__html: userInput}}`
- Vue: `v-html="userInput"`
- ORM: `.raw()`, `.extra()`, `RawSQL()` with string interpolation

## [CRITICAL] Review Process

1. **Detect Context** — What type of code? Load relevant reference.md sections (Auth, Injection, XSS, CSRF, SSRF, File, Crypto, Deserialization, Business Logic, API, Misconfiguration, Supply Chain, Error, Logging)
2. **Load Language/Infra Guide** — By file extension/imports: Python or JS/TS patterns. Dockerfiles: Docker Security Patterns
3. **[CRITICAL] Research Before Flagging** — Trace data flow origin. Config or user input? Validation elsewhere? Framework protections? Only report HIGH confidence after understanding context
4. **[HIGH] Verify Exploitability**:
   - Attacker-controlled? (`request.*`, URL segments, uploads, WebSocket) → Investigate. (`settings.*`, `os.environ`, constants, signed sessions) → Usually safe
   - Framework mitigate? (auto-escaping, parameterization, middleware)
   - Validation upstream? (DOMPurify, bleach, etc.)
5. **[CRITICAL] Report HIGH Confidence Only** — Skip theoretical issues

---

## [HIGH] Severity Classification

| Severity | Examples |
|----------|----------|
| **Critical** | RCE, SQL injection to data, auth bypass, hardcoded secrets |
| **High** | Stored XSS, SSRF to metadata, IDOR to sensitive data |
| **Medium** | Reflected XSS, CSRF on state-changing actions, path traversal |
| **Low** | Missing headers, verbose errors, weak algorithms in non-critical context |

---

## [CRITICAL] Quick Patterns Reference

### [CRITICAL] Always Flag (Critical)

eval/exec/pickle.loads/yaml.load(not safe_load)/unserialize/deserialize with user input. shell=True + user input. child_process.exec with user input.

### [HIGH] Always Flag (High)

innerHTML/dangerouslySetInnerHTML/v-html with user input (XSS). String-interpolated SQL with user input (SQLi). os.system/subprocess with user input (command injection).

### [CRITICAL] Always Flag (Secrets)

Hardcoded passwords, API keys (`sk-...`), AWS secrets, private keys in source code.

### [CRITICAL] Next.js Specific Patterns

- **Server Action CSRF**: Server Actions via POST lack origin check if `serverActions.allowedOrigins` misconfigured. Flag if no CSRF middleware and `allowedOrigins` not set in `next.config`
- **Middleware auth bypass**: CVE-2025-29927 — `x-middleware-subrequest` header skips middleware. Flag if middleware is sole auth gate without `next@>=14.2.26/15.2.4`
- **RSC payload data leak**: Server Components serialize full query results into RSC payload. Flag if SC fetches sensitive fields not needed by client
- **`redirect()` in try-catch**: `redirect()` throws `NEXT_REDIRECT` internally. Wrapping in try-catch silently swallows redirect. Flag `try { redirect() }` patterns

### [HIGH] Supply Chain Patterns

- **Lockfile poisoning**: `package-lock.json`/`pnpm-lock.yaml` with registry URLs pointing to non-default registries. Flag suspicious `resolved` URLs
- **Dependency confusion**: Private package names without `@scope/` prefix published to public npm. Flag unscoped private packages in `package.json`
- **postinstall scripts**: Flag `postinstall`/`preinstall` scripts in dependencies that execute arbitrary code

### [MEDIUM] Check Context First (Investigate Before Flagging)

- **SSRF**: Flag only if URL from user input, not from settings/config
- **Path traversal**: Flag only if path from user input, not from config
- **Open redirect**: Flag only if redirect URL from user input
- **Weak crypto**: Flag md5/random only for security purposes (passwords, tokens), not checksums/UI

---

## [HIGH] Output Format

```markdown
## Security Review: [File/Component Name]
Summary: X findings (Y Critical, Z High) | Risk: Critical/High/Medium/Low
[VULN-001] Type (Severity) @ file.py:123 — Issue / Impact / Evidence / Fix
[VERIFY-001] Potential Issue @ file.py:456 — Question to verify
```

If no vulnerabilities found, state: "No high-confidence vulnerabilities identified."

See `reference.md` for OWASP-to-CWE mapping, severity decision tree, full output template, and review checklists.

---

## Decision Tree

脆弱性タイプ判定 → ユーザー入力がSQL/ORM rawに到達？ → SQLi / HTML出力に到達？ → XSS / URL fetchに到達？ → SSRF / ファイルパスに到達？ → Path Traversal / コマンド実行に到達？ → Command Injection / デシリアライズに到達？ → Insecure Deserialization

信頼度判定 → 入力元はattacker-controlled？ → No → フラグしない / Yes → フレームワーク緩和あり？ → Yes → 緩和をバイパス可能か確認 / No → HIGH confidence → レポート

## Checklist

- [ ] attacker-controlled input のデータフローを末端まで追跡したか
- [ ] フレームワークの自動緩和（auto-escape, parameterized query）を確認したか
- [ ] server-controlled values（settings, env vars）を誤検出していないか
- [ ] hardcoded secrets（API key, password, private key）をgrepで検索したか
- [ ] RLS / 認可チェックが全データ変更パスに存在するか
- [ ] CSRF保護が状態変更エンドポイントに適用されているか
- [ ] エラーレスポンスがstack trace / 内部情報を漏洩していないか
- [ ] 発見した脆弱性にCWE番号とOWASPカテゴリを付与したか
- [ ] Next.js middleware が唯一の認証ゲートになっていないか（CVE-2025-29927）
- [ ] Server Actions に `allowedOrigins` が設定されているか
- [ ] RSC payload に不要な機密フィールドが含まれていないか
- [ ] `package-lock.json` の `resolved` URL が正規レジストリを指しているか
- [ ] MCP/AI統合時: ツール出力のサニタイズと機密情報フィルタリングがあるか

## [HIGH] MCP / Multi-AI Security Boundaries

MCP経由で外部AIツールを統合する場合、3層防御（L1: Static deny, L2: Dynamic hooks, L3: Prompt constraints）でチェック。L1/L2はMCP経由の内部挙動に適用されない点に注意。

AI統合時の追加チェック: indirect prompt injection（ツール出力→次のプロンプト操作）、tool result poisoning（外部データの不可視テキスト）、exfiltration via tool calls（動的URLで機密送信）。

→ 完全なMCPセキュリティチェックリスト・3層防御モデル詳細・既知CVE: `reference.md`

## Cross-references [MEDIUM]

- `supabase-auth-patterns` — auth bypass/token weakness 検出 ↔ 認証フロー設計
- `error-handling-logging` — fail-open/stack trace 漏洩検出 ↔ エラー設計
- `typescript-best-practices` — 型不備→セキュリティ穴の連携
- `claude-env-optimizer` — MCP診断(Mode 6)/hooks診断(Mode 1) ↔ セキュリティ穴検出
- `_security-best-practices` — セキュアコーディングパターンの防御側
- `_security-threat-model` — 脅威モデルに基づく脆弱性スキャン
- `security-arsenal` — Red/Blue team の脆弱性検出連携
- `_supabase-postgres-best-practices` — RLS バイパス・SQL インジェクション検出
- `ci-cd-deployment` — CI パイプラインでのセキュリティスキャン
- `code-review` — セキュリティ観点のコードレビュー
