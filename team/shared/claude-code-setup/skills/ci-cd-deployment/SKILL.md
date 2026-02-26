---
name: ci-cd-deployment
description: "GitHub Actions + Vercel deploys: workflow syntax, parallel test pipelines, env vars/secrets, trunk-based branching, Dependabot"
user-invocable: false
---

# CI/CD & Deployment Patterns

## When to Apply

Reference this skill when:
- Setting up or modifying GitHub Actions workflows
- Configuring Vercel deployment (preview, production)
- Building automated test pipelines (lint, type-check, test, build)
- Managing environment variables and secrets across environments
- Defining branch strategies and protection rules
- Configuring Dependabot for dependency updates

## Scope & Relationship to Other Skills

| Topic | This Skill | Other Skill |
|-------|-----------|-------------|
| GitHub Actions workflows | Here | - |
| Vercel deployment config | Here | `nextjs-app-router-patterns` (app optimization) |
| Test execution in CI | Here (pipeline orchestration) | `testing-strategy` (test design, TDD, Playwright) |
| Container-based CI jobs | Partial (service containers) | `docker-expert` (Dockerfile, compose, image optimization) |
| Secrets & vulnerability scanning | Here (secrets in CI/Vercel) | `security-review` (code-level vulnerability detection) |
| Error monitoring post-deploy | - | `error-handling-logging` (Sentry, error boundaries) |
| Vercel runtime performance | - | `vercel-react-best-practices` (render optimization) |
| TypeScript strict mode in CI | Here (type-check job) | `typescript-best-practices` (tsconfig, strict rules) |
| DB migration in deploy pipeline | Here (workflow orchestration) | `supabase-postgres-best-practices` (migration safety) |
| Auth env vars (Supabase keys) | Here (secrets config) | `supabase-auth-patterns` (RLS, session handling) |

---

## Decision Tree: CI/CD Setup

```
CI pipeline? -> Simple: Section 1 / Monorepo: Matrix (reference.md)
Deployment? -> Vercel (Section 2) / Other: custom deploy job
Dependency updates? -> Dependabot (reference.md)
```

---

## Section 1: Standard GitHub Actions Pipeline [CRITICAL]

4 parallel jobs: `lint`, `type-check`, `test` run concurrently, then `build` after all pass. Always set `concurrency` with `cancel-in-progress: true` to avoid wasted runs.

```
lint --------\
type-check ---+-> build
test ---------/
```

Key setup per job: `actions/checkout@v4` + `actions/setup-node@v4` (with `cache: 'npm'`) + `npm ci`.

> Full CI pipeline template (.github/workflows/ci.yml): see reference.md "Standard CI Pipeline Template"

---

## Section 2: Vercel Deployment [CRITICAL]

### Automatic (Recommended)

Vercel's GitHub integration handles deployment automatically:
- **Push to main** -> Production deploy
- **Push to PR branch** -> Preview deploy with unique URL
- **No GitHub Actions needed** for deployment itself

### vercel.json [HIGH]

Essential fields: `framework`, `buildCommand`, `installCommand`, `outputDirectory`, `regions`. Set `Cache-Control: no-store` on API routes.

> Full vercel.json template + Preview deploy + CI integration, Vercel CLI: see [reference.md](reference.md) "vercel.json Template"

---

## Section 3: Environment Variable Management [CRITICAL]

### Flow

```
Local (.env.local) -> NOT committed, loaded by Next.js
CI (GitHub Secrets) -> Settings > Secrets, accessed via ${{ secrets.NAME }}
Vercel (Project Settings) -> Per environment (Production / Preview / Development)
```

### Naming Conventions [HIGH]

- Browser-accessible: prefix with `NEXT_PUBLIC_` (e.g., `NEXT_PUBLIC_SUPABASE_URL`)
- Server-only: NO prefix (e.g., `SUPABASE_SERVICE_ROLE_KEY`, `DATABASE_URL`)
- In CI: non-secret values use `${{ vars.NAME }}`, secrets use `${{ secrets.NAME }}`

### .env Files [HIGH]

- `.env.local` — local dev, git-ignored, real values
- `.env.example` — committed, empty template for team onboarding

> Full naming examples + .env templates: see reference.md "Environment Variable Examples"

### Security Rules [CRITICAL]

```
NEVER commit: .env.local, .env.production, real API keys
ALWAYS: Use GitHub Secrets for CI, Vercel env vars for deploy
         Have .env* in .gitignore (except .env.example)
         Rotate keys if accidentally committed
```

> Deep secrets audit: see `security-review` skill for hardcoded credential detection

---

## Section 4: Branch Strategy (Trunk-Based) [HIGH]

```
main (production)
  +-- feature/add-auth    -> PR -> merge to main
  +-- fix/login-error     -> PR -> merge to main
```

**Rules:**
- `main` is always deployable
- Feature branches kept short-lived
- PRs require CI pass + code review
- Merge via squash (clean history)

### Branch Protection [HIGH]

```
Settings > Branches > main: [x] Require PR (1 approval)
[x] Require status checks (lint, type-check, test, build, Vercel Preview)
[x] Require up to date before merging  [x] Do not allow bypassing
```

---

## Section 5: Workflow Triggers Quick Reference [MEDIUM]

Common triggers: `push` (branches/paths/tags), `pull_request` (types), `schedule` (cron), `workflow_dispatch` (manual with inputs).

> Full trigger syntax template + Conditionals, Job Outputs, Artifacts: see [reference.md](reference.md) "Workflow Triggers Template"

---

## Section 6: Dependabot [MEDIUM]

Automate dependency updates for npm packages and GitHub Actions versions.

> Configuration (.github/dependabot.yml) + auto-merge workflow: see [reference.md](reference.md)

---

## Troubleshooting [HIGH]

| Problem | Cause | Solution |
|---------|-------|----------|
| CI passes but Vercel fails | Different Node/env | Match Node version in `engines` field and Vercel settings |
| Secrets empty in fork PR | GitHub security policy | Use `pull_request_target` with caution |
| Cache not working | Key mismatch | Check `hashFiles()` path matches lock file |
| Concurrency cancels runs | Too broad group | Include `${{ github.ref }}` in group key |
| Build too slow | No cache/parallelism | Add npm cache + split into parallel jobs |

## Cross-references [MEDIUM]

- **testing-strategy**: テスト設計・TDD・Playwrightの実装（CIパイプラインで実行するテストの設計方針）
- **docker-expert**: Dockerイメージ最適化・compose設定（コンテナベースのCIジョブ構築）
- **security-review**: シークレット漏洩検知・脆弱性スキャン（CI/Vercelでの機密情報管理の監査）

## Checklist: New Project CI/CD [CRITICAL]

- [ ] `.github/workflows/ci.yml` with lint, type-check, test, build
- [ ] `concurrency` set to cancel stale runs
- [ ] Node version and npm cache configured
- [ ] Vercel connected to GitHub repo
- [ ] Env vars set in Vercel (per environment)
- [ ] Secrets stored in GitHub Secrets (not hardcoded)
- [ ] Branch protection on `main`
- [ ] `.github/dependabot.yml` configured
- [ ] `.env.example` committed, `.env*` in `.gitignore`
- [ ] Test pipeline validated: see `testing-strategy` for test design
