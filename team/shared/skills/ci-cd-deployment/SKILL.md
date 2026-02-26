---
name: ci-cd-deployment
description: "CI/CD pipeline architecture with GitHub Actions and Vercel deployment for Next.js applications. Covers workflow syntax (triggers, concurrency, matrix, reusable workflows), Vercel preview and production deploys, automated testing pipelines (lint, type-check, test, build in parallel), environment variable and secrets management across local/CI/Vercel, trunk-based branch strategies with protection rules, and Dependabot dependency automation. Use when setting up CI/CD pipelines, creating or debugging GitHub Actions workflows, configuring Vercel deployment settings, automating build and test stages, managing secrets across environments, or implementing branch protection and merge strategies. Does NOT cover Docker image optimization (docker-expert), test writing (testing-strategy), or app code patterns (nextjs-app-router-patterns)."
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
Starting a project?
  |
  +-- Need CI pipeline?
  |     +-- Simple (lint + test + build)? -> Standard Pipeline (Section 1)
  |     +-- Monorepo or complex? -> Matrix / Path Filter (reference.md)
  |
  +-- Need deployment?
  |     +-- Vercel (Next.js)? -> Vercel Integration (Section 2)
  |     +-- Other platform? -> Custom deploy job
  |
  +-- Need dependency updates? -> Dependabot (reference.md)
```

---

## Section 1: Standard GitHub Actions Pipeline [CRITICAL]

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'npm'
      - run: npm ci
      - run: npm run lint

  type-check: # For strict config, see `typescript-best-practices`
    runs-on: ubuntu-latest
    steps: # Same setup as lint job
      - run: npm run type-check

  test:
    runs-on: ubuntu-latest
    steps: # Same setup as lint job
      - run: npm test

  build:
    runs-on: ubuntu-latest
    needs: [lint, type-check, test]
    steps: # Same setup as lint job
      - run: npm run build
```

### Pipeline Order [HIGH]

```
lint --------\
type-check ---+-> build
test ---------/
```

**Rule:** `lint`, `type-check`, `test` run in parallel. `build` runs only after all three pass.

---

## Section 2: Vercel Deployment [CRITICAL]

### Automatic (Recommended)

Vercel's GitHub integration handles deployment automatically:
- **Push to main** -> Production deploy
- **Push to PR branch** -> Preview deploy with unique URL
- **No GitHub Actions needed** for deployment itself

### vercel.json [HIGH]

```json
{
  "framework": "nextjs",
  "buildCommand": "npm run build",
  "installCommand": "npm ci",
  "outputDirectory": ".next",
  "regions": ["hnd1"],
  "headers": [
    {
      "source": "/api/(.*)",
      "headers": [
        { "key": "Cache-Control", "value": "no-store" }
      ]
    }
  ]
}
```

> Preview deploy + CI integration, Vercel CLI: see [reference.md](reference.md)

---

## Section 3: Environment Variable Management [CRITICAL]

### Flow

```
Local (.env.local) -> NOT committed, loaded by Next.js
CI (GitHub Secrets) -> Settings > Secrets, accessed via ${{ secrets.NAME }}
Vercel (Project Settings) -> Per environment (Production / Preview / Development)
```

### Naming Conventions [HIGH]

```bash
# Public (browser) - prefix with NEXT_PUBLIC_
NEXT_PUBLIC_SUPABASE_URL=https://xxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...

# Private (server-only) - NO prefix
SUPABASE_SERVICE_ROLE_KEY=eyJ...
DATABASE_URL=postgresql://...
```

```yaml
# Separate by sensitivity
env:
  NEXT_PUBLIC_SUPABASE_URL: ${{ vars.SUPABASE_URL }}       # Non-secret -> vars
  SUPABASE_SERVICE_ROLE_KEY: ${{ secrets.SERVICE_ROLE_KEY }} # Secret -> secrets
```

### .env Files [HIGH]

```bash
# .env.local (local dev - git ignored)
NEXT_PUBLIC_SUPABASE_URL=http://127.0.0.1:54321
SUPABASE_SERVICE_ROLE_KEY=eyJ...local...

# .env.example (committed - template for team)
NEXT_PUBLIC_SUPABASE_URL=
SUPABASE_SERVICE_ROLE_KEY=
```

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
Settings > Branches > main:
  [x] Require pull request (1 approval)
  [x] Require status checks: lint, type-check, test, build, Vercel Preview
  [x] Require up to date before merging
  [x] Do not allow bypassing
```

---

## Section 5: Workflow Triggers Quick Reference [MEDIUM]

```yaml
on:
  push:
    branches: [main]
    paths: ['src/**']
    tags: ['v*']
  pull_request:
    branches: [main]
    types: [opened, synchronize, reopened]
  schedule:
    - cron: '0 9 * * 1'  # Monday 9am UTC
  workflow_dispatch:       # Manual trigger
    inputs:
      environment:
        type: choice
        options: [staging, production]
```

> Conditionals, Job Outputs, Artifacts: see [reference.md](reference.md)

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
