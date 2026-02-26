---
name: docker-expert
description: "Dockerfile multi-stage, docker-compose, image optimization, security hardening, health checks, buildx multi-arch"
user-invocable: false
---

# Docker Expert

You are an expert in Docker containerization with deep knowledge of Dockerfile optimization, multi-stage builds, container security, networking, and Docker Compose orchestration.

## When to Apply

Reference this skill when:
- Creating or optimizing a Dockerfile
- Writing or modifying `docker-compose.yml`
- Debugging container startup, networking, or volume issues
- Reducing Docker image size
- Implementing container security hardening
- Setting up development environments with hot reload
- Building multi-architecture images with `docker buildx`

## Scope & Relationship to Other Skills

| Topic | This Skill | Other Skill |
|-------|-----------|-------------|
| Dockerfile / image optimization | Here | - |
| Docker Compose orchestration | Here | - |
| Container security hardening | Here (non-root, pinned images, no secrets in layers) | `security-review` (detects Docker misconfigs as vulnerabilities) |
| Docker in CI/CD pipelines | Partial (image build, multi-stage targets) | `ci-cd-deployment` (GitHub Actions workflow, service containers) |
| Container log collection / format | Here (log driver config, `docker logs`) | `error-handling-logging` (structured app-level logging, Sentry) |
| Container debugging process | Here (debug commands, troubleshooting table) | `systematic-debugging` (root-cause methodology, Phase 1-4 process) |

---

## Decision Tree

Need Docker help? → Creating Dockerfile? → Single app: Section 1 / Minimal size: Section 2 → Multi-container app? → docker-compose: Section 3 / Dev hot reload: reference.md Task 5 → Debugging? → Won't start: Troubleshooting table / Network/volume: Section 6 → Optimizing? → Image too large: Section 7 / Build slow: reference.md BuildKit cache

---

## Section 1: Dockerfile Essentials

### [CRITICAL] Layer Caching Rule

Order instructions from least-changing to most-changing:

```dockerfile
# 1. COPY requirements → RUN install (変更少) → COPY . . (変更多)
# 完全例 → reference.md Task 6
```

### [CRITICAL] .dockerignore

```
node_modules, .git, .env, *.md, dist, coverage, __pycache__, .DS_Store
# Full template → reference.md Task 7
```

### [CRITICAL] Non-Root User (Required for Production)

```dockerfile
RUN addgroup -g 1001 -S appgroup && \
    adduser -S appuser -u 1001
USER appuser
```

---

## Section 2: Multi-Stage Builds & Image Optimization

### [HIGH] Pattern: Build + Minimal Runtime

> Full language-specific examples (Node.js, Python, Go): see reference.md

Key principles:
1. Separate build stage from production stage
2. Copy only built artifacts and production dependencies
3. Use smallest possible base image for production stage
4. Add signal handling (dumb-init or tini)

> Full example: see reference.md Task 1

### [HIGH] Next.js 15 Standalone Dockerfile

Next.js の `output: 'standalone'` を使ったマルチステージビルド。pnpm 対応。

```dockerfile
# Next.js 15 standalone multi-stage
FROM node:20-alpine AS base

FROM base AS deps
WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN corepack enable pnpm && pnpm install --frozen-lockfile

FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
ENV NEXT_TELEMETRY_DISABLED=1
RUN corepack enable pnpm && pnpm build

FROM base AS runner
WORKDIR /app
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
RUN addgroup --system --gid 1001 nodejs && adduser --system --uid 1001 nextjs
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:1001 /app/.next/standalone ./
COPY --from=builder --chown=nextjs:1001 /app/.next/static ./.next/static
USER nextjs
EXPOSE 3000
ENV PORT=3000
CMD ["node", "server.js"]
```

> **必須設定**: `next.config.ts` で `output: 'standalone'` を有効にすること。
>
> ```ts
> // next.config.ts
> const nextConfig = { output: 'standalone' };
> ```

### [MEDIUM] Base Image Selection Guide

| Base Image | Approx Size | Use Case |
|-----------|-------------|----------|
| `scratch` | 0 MB | Static Go/Rust binaries |
| `distroless/static` | ~2 MB | Static binaries needing CA certs |
| `alpine` | ~7 MB | Minimal Linux with package manager |
| `node:20-alpine` | ~130 MB | Node.js apps |
| `python:3-slim` | ~150 MB | Python apps |
| `ubuntu` | ~78 MB | When you need full Linux |

---

## Section 3: Docker Compose Patterns

### [HIGH] Service Orchestration

Key rules:
- Use `depends_on` with `condition: service_healthy` for startup ordering
- Separate networks for isolation (frontend/backend)
- Named volumes for persistent data
- `restart: unless-stopped` on all services
- Health checks on critical services
- Omit top-level `version:` key (deprecated in Compose Spec)

```yaml
# depends_on + condition: service_healthy, separate networks, named volumes
# healthcheck + restart: unless-stopped on all services
# Full example → reference.md Task 8
```

> Full multi-service example with frontend/backend/cache: see reference.md

---

## Section 4: Security Hardening

### [CRITICAL] Rules (Priority Order)

1. **Run as non-root** - Always use `USER` directive
2. **Pin image digests in prod** - Use `image@sha256:...` or specific tags, never `:latest`
3. **No secrets in images** - Use runtime env vars or Docker secrets
4. **Minimal packages** - Use `--no-install-recommends`, clean apt cache
5. **Scan images** - `docker scout cves` or `trivy image`
6. **Use distroless** - When possible for production

### Anti-Patterns

```dockerfile
# BAD: FROM node:latest + COPY .env + ENV API_KEY=secret123
# GOOD: FROM node:20-alpine + adduser + USER app + runtime env
# Full example → reference.md Task 9
```

---

## Section 5: Resource Management & Health Checks

```yaml
# deploy.resources.limits: cpus '0.5', memory 512M
# HEALTHCHECK --interval=30s --timeout=3s CMD wget ... || exit 1
# Full examples → reference.md Task 10
```

---

## Section 6: Debug & Build Commands

```bash
docker logs <c> --tail 100 -f    # Logs
docker exec -it <c> sh           # Shell
docker stats                      # Resources
docker build --target prod -t app:prod .
# Full command reference → reference.md Task 11
```

---

## Section 7: [HIGH] Production Checklist

- [ ] Multi-stage build to reduce image size
- [ ] Non-root user with `USER` directive
- [ ] Specific image tags (not `latest`)
- [ ] `.dockerignore` file present
- [ ] Layer caching optimized (deps before source)
- [ ] Health check defined
- [ ] Resource limits set
- [ ] Signals handled properly (dumb-init or tini)
- [ ] Image scanned for vulnerabilities
- [ ] Restart policy configured
- [ ] Secrets passed at runtime (not baked in)

---

## Troubleshooting

| Problem | Cause | Solution |
|---------|-------|----------|
| Container exits immediately | CMD fails or missing | Check `docker logs`, verify CMD |
| Port already in use | Host port conflict | Change host port mapping |
| Permission denied on mount | UID mismatch | Match container user UID with host |
| Image too large | No multi-stage build | Use multi-stage + .dockerignore |
| Build cache not working | Layer order wrong | Put deps COPY before source COPY |
| Container can't reach other | Wrong network | Put both on same Docker network |
| OOM killed | No memory limit | Set `deploy.resources.limits.memory` |
| Slow builds | No BuildKit cache | Use `DOCKER_BUILDKIT=1` + cache mounts |

> Advanced patterns (BuildKit cache mounts, Compose profiles, dev hot reload): see reference.md
> If container issues persist after 3 fix attempts, escalate via `systematic-debugging` (Phase 4.4 Three-Fix Rule).

---

## Cross-references [MEDIUM]

- `ci-cd-deployment` — Docker in CI/CD パイプライン（GitHub Actions workflow、service containers、image push）
- `security-review` — Docker misconfig の脆弱性検出（root 実行、secrets in layers、未スキャンイメージ）
