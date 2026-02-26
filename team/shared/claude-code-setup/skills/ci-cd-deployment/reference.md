# CI/CD & Deployment — Reference

SKILL.md の補足資料。テンプレート、Advanced Workflow Patterns、Dependabot設定、Vercel CLI/Preview CI統合。

---

## Standard CI Pipeline Template

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

permissions:
  contents: read

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
      - uses: actions/setup-node@v4
        with:
          node-version-file: '.node-version'
          cache: 'pnpm'
      - run: pnpm install --frozen-lockfile
      - run: pnpm lint

  type-check: # For strict config, see `typescript-best-practices`
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
      - uses: actions/setup-node@v4
        with:
          node-version-file: '.node-version'
          cache: 'pnpm'
      - run: pnpm install --frozen-lockfile
      - run: pnpm tsc --noEmit

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
      - uses: actions/setup-node@v4
        with:
          node-version-file: '.node-version'
          cache: 'pnpm'
      - run: pnpm install --frozen-lockfile
      - run: pnpm vitest run --coverage

  build:
    runs-on: ubuntu-latest
    needs: [lint, type-check, test]
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
      - uses: actions/setup-node@v4
        with:
          node-version-file: '.node-version'
          cache: 'pnpm'
      - run: pnpm install --frozen-lockfile
      - run: pnpm build
```

---

## vercel.json Template

```json
{
  "framework": "nextjs",
  "buildCommand": "pnpm run build",
  "installCommand": "pnpm install --frozen-lockfile",
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

---

## Environment Variable Examples

### Naming Conventions

```bash
# Public (browser) - prefix with NEXT_PUBLIC_
NEXT_PUBLIC_SUPABASE_URL=https://xxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...

# Private (server-only) - NO prefix
SUPABASE_SERVICE_ROLE_KEY=eyJ...
DATABASE_URL=postgresql://...
```

### CI: vars vs secrets

```yaml
# Separate by sensitivity
env:
  NEXT_PUBLIC_SUPABASE_URL: ${{ vars.SUPABASE_URL }}       # Non-secret -> vars
  SUPABASE_SERVICE_ROLE_KEY: ${{ secrets.SERVICE_ROLE_KEY }} # Secret -> secrets
```

### .env File Templates

```bash
# .env.local (local dev - git ignored)
NEXT_PUBLIC_SUPABASE_URL=http://127.0.0.1:54321
SUPABASE_SERVICE_ROLE_KEY=eyJ...local...

# .env.example (committed - template for team)
NEXT_PUBLIC_SUPABASE_URL=
SUPABASE_SERVICE_ROLE_KEY=
```

---

## Workflow Triggers Template

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

---

## Advanced Workflow Patterns

### Path Filtering (Monorepo)

```yaml
on:
  push:
    paths:
      - 'packages/frontend/**'
      - 'package.json'
      - '.github/workflows/frontend.yml'
```

### Matrix Strategy

```yaml
jobs:
  test:
    strategy:
      matrix:
        node-version: [18, 20, 22]
        os: [ubuntu-latest, macos-latest]
      fail-fast: false
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
      - run: npm test
```

### Reusable Workflows

```yaml
# .github/workflows/reusable-test.yml
name: Reusable Test
on:
  workflow_call:
    inputs:
      node-version:
        type: string
        default: '20'
    secrets:
      SUPABASE_URL:
        required: true

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ inputs.node-version }}
          cache: 'npm'
      - run: npm ci
      - run: npm test
        env:
          SUPABASE_URL: ${{ secrets.SUPABASE_URL }}
```

```yaml
# Calling reusable workflow
jobs:
  test:
    uses: ./.github/workflows/reusable-test.yml
    with:
      node-version: '20'
    secrets:
      SUPABASE_URL: ${{ secrets.SUPABASE_URL }}
```

### Caching

```yaml
# setup-node cache (simplest)
- uses: actions/setup-node@v4
  with:
    node-version: 20
    cache: 'npm'

# Custom cache for other tools
- uses: actions/cache@v4
  with:
    path: ~/.cache/playwright
    key: playwright-${{ hashFiles('package-lock.json') }}
```

---

## Preview Deploy + CI Integration

```yaml
# Run E2E tests against Vercel preview URL
jobs:
  e2e:
    runs-on: ubuntu-latest
    needs: [build]
    steps:
      - uses: actions/checkout@v4
      - name: Wait for Vercel Preview
        uses: patrickedqvist/wait-for-vercel-preview@v1.3.2
        id: vercel
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          max_timeout: 300
      - name: E2E Tests
        run: npx playwright test
        env:
          BASE_URL: ${{ steps.vercel.outputs.url }}
```

### Vercel CLI Deployment

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Deploy to Vercel
        run: |
          npx vercel pull --yes --token=${{ secrets.VERCEL_TOKEN }}
          npx vercel build --token=${{ secrets.VERCEL_TOKEN }}
          npx vercel deploy --prebuilt --token=${{ secrets.VERCEL_TOKEN }}
        env:
          VERCEL_ORG_ID: ${{ secrets.VERCEL_ORG_ID }}
          VERCEL_PROJECT_ID: ${{ secrets.VERCEL_PROJECT_ID }}
```

---

## Supply Chain Security: SHA Pinning

サードパーティActionsはタグではなくSHAピンニングで固定し、サプライチェーン攻撃を防ぐ:
```yaml
# Bad: タグは上書き可能
- uses: actions/checkout@v4
# Good: SHAで固定（Dependabotが自動更新してくれる）
- uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11 # v4.1.1
```
`github-actions` ecosystem の Dependabot を併用すれば、SHA固定でもバージョン更新が自動化される。

## Coverage Reporting

テスト結果のカバレッジをPRに可視化するには [Codecov](https://codecov.io/) を統合:
```yaml
- uses: codecov/codecov-action@v4
  with:
    token: ${{ secrets.CODECOV_TOKEN }}
    files: ./coverage/lcov.info
```

## Dependabot Configuration

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
    open-pull-requests-limit: 10
    reviewers:
      - "your-github-username"
    labels:
      - "dependencies"
    groups:
      production:
        patterns: ["*"]
        update-types: ["minor", "patch"]
    ignore:
      - dependency-name: "next"
        update-types: ["version-update:semver-major"]

  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
    labels:
      - "ci"
```

### Auto-merge for Patch Updates

```yaml
# .github/workflows/dependabot-auto-merge.yml
name: Auto-merge Dependabot PRs

on:
  pull_request:

permissions:
  contents: write
  pull-requests: write

jobs:
  auto-merge:
    runs-on: ubuntu-latest
    if: github.actor == 'dependabot[bot]'
    steps:
      - name: Fetch Dependabot metadata
        id: metadata
        uses: dependabot/fetch-metadata@v2
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
      - name: Auto-merge patch updates
        if: steps.metadata.outputs.update-type == 'version-update:semver-patch'
        run: gh pr merge --auto --squash "$PR_URL"
        env:
          PR_URL: ${{ github.event.pull_request.html_url }}
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

## Workflow Syntax: Conditionals, Outputs, Artifacts

### Conditionals

```yaml
steps:
  - name: Deploy
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    run: npm run deploy

  - name: Comment PR
    if: github.event_name == 'pull_request'
    uses: actions/github-script@v7
    with:
      script: |
        github.rest.issues.createComment({
          issue_number: context.issue.number,
          owner: context.repo.owner,
          repo: context.repo.repo,
          body: 'CI passed!'
        })
```

### Job Outputs

```yaml
jobs:
  check:
    runs-on: ubuntu-latest
    outputs:
      should-deploy: ${{ steps.check.outputs.deploy }}
    steps:
      - id: check
        run: echo "deploy=true" >> $GITHUB_OUTPUT

  deploy:
    needs: check
    if: needs.check.outputs.should-deploy == 'true'
    runs-on: ubuntu-latest
    steps:
      - run: echo "Deploying..."
```

### Artifacts

```yaml
- uses: actions/upload-artifact@v4
  with:
    name: build-output
    path: .next/
    retention-days: 7

- uses: actions/download-artifact@v4
  with:
    name: build-output
    path: .next/
```

---

## Service Containers (DB in CI)

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_USER: test
          POSTGRES_PASSWORD: test
          POSTGRES_DB: testdb
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - run: npm test
        env:
          DATABASE_URL: postgresql://test:test@localhost:5432/testdb
```

> For migration safety patterns, see `supabase-postgres-best-practices` skill.

---

## Slack Notification on Deploy

```yaml
  notify:
    runs-on: ubuntu-latest
    needs: [build]
    if: always()
    steps:
      - name: Notify Slack
        uses: slackapi/slack-github-action@v1.27.0
        with:
          payload: |
            {
              "text": "${{ needs.build.result == 'success' && 'Deploy succeeded' || 'Deploy FAILED' }}: ${{ github.repository }}@${{ github.ref_name }}"
            }
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
```

> For LINE notifications instead, see `line-bot-dev` skill.

---

## Release & Rollback

### Tag-based Release

```yaml
on:
  push:
    tags: ['v*']

jobs:
  release:
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@v4
      - name: Create GitHub Release
        uses: softprops/action-gh-release@v2
        with:
          generate_release_notes: true
```

### Vercel Rollback

```bash
# List recent deployments
vercel ls --token=$VERCEL_TOKEN

# Promote a previous deployment to production
vercel promote <deployment-url> --token=$VERCEL_TOKEN
```

### Rollback Strategy

```
Production incident?
  +-- Vercel? -> Instant rollback via dashboard or `vercel promote`
  +-- Code fix needed? -> Revert commit on main, auto-deploys fix
  +-- DB migration involved? -> NEVER auto-rollback; see `supabase-postgres-best-practices`
```

---

## DB Migration in CI Pipeline

```yaml
  migrate:
    runs-on: ubuntu-latest
    needs: [test]
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - name: Run migrations
        run: npx supabase db push
        env:
          SUPABASE_ACCESS_TOKEN: ${{ secrets.SUPABASE_ACCESS_TOKEN }}
          SUPABASE_DB_PASSWORD: ${{ secrets.SUPABASE_DB_PASSWORD }}
```

> Migration design and safety: see `supabase-postgres-best-practices`. Auth config: see `supabase-auth-patterns`.
