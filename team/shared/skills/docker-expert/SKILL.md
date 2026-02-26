---
name: docker-expert
description: "Docker containerization, image optimization, and container orchestration expertise. Use when creating, debugging, or optimizing Dockerfiles, writing docker-compose.yml configurations, implementing multi-stage builds, reducing image size with distroless or alpine bases, hardening container security with non-root users and pinned digests, configuring health checks and restart policies, managing Docker networking or volumes, building multi-architecture images with buildx, setting up development environments with hot reload, troubleshooting container startup failures or OOM kills, analyzing layer caching for build performance, or scanning images for vulnerabilities with trivy or docker scout. Does NOT cover CI/CD pipelines (ci-cd-deployment), app architecture (nextjs-app-router-patterns), or security auditing (security-review)."
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

```
Need Docker help?
  |
  +-- Creating a new Dockerfile?
  |     +-- Single language app -> Quick Start (Section 1)
  |     +-- Need minimal size -> Multi-stage + Distroless (Section 2)
  |
  +-- Setting up multi-container app?
  |     +-- docker-compose.yml -> Section 3
  |     +-- Need dev hot reload -> reference.md (Task 5)
  |
  +-- Debugging container issues?
  |     +-- Container won't start -> Troubleshooting table
  |     +-- Network/volume issues -> Debug Commands (Section 6)
  |
  +-- Optimizing existing image?
        +-- Image too large -> Checklist (Section 7)
        +-- Build too slow -> BuildKit cache mounts (reference.md)
```

---

## Section 1: Dockerfile Essentials

### [CRITICAL] Layer Caching Rule

Order instructions from least-changing to most-changing:

```dockerfile
FROM python:3-slim
WORKDIR /app
COPY requirements.txt .                    # Changes rarely
RUN pip install --no-cache-dir -r requirements.txt
COPY . .                                   # Changes often
CMD ["python", "app.py"]
```

### [CRITICAL] .dockerignore

```
node_modules
.git
.env
*.md
dist
coverage
__pycache__
.pytest_cache
.DS_Store
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

### [MEDIUM] Base Image Selection Guide

| Base Image | Approx Size | Use Case |
|-----------|-------------|----------|
| `scratch` | 0 MB | Static Go/Rust binaries |
| `distroless/static` | ~2 MB | Static binaries needing CA certs |
| `alpine` | ~7 MB | Minimal Linux with package manager |
| `node:lts-alpine` | ~130 MB | Node.js apps |
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
services:
  backend:
    build: ./backend
    depends_on:
      database:
        condition: service_healthy
    networks: [app-network, db-network]
    healthcheck:
      test: ['CMD', 'curl', '-f', 'http://localhost:4000/health']
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    restart: unless-stopped

  database:
    image: postgres:16-alpine
    volumes:
      - postgres-data:/var/lib/postgresql/data
    networks: [db-network]
    healthcheck:
      test: ['CMD-SHELL', 'pg_isready -U user']
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped

networks:
  app-network:
  db-network:

volumes:
  postgres-data:
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
# BAD: Running as root, using latest, embedding secrets
FROM node:latest
COPY .env .
ENV API_KEY=secret123
CMD ["node", "server.js"]

# GOOD: Pinned version, non-root, no secrets
FROM node:20-alpine
RUN addgroup -S app && adduser -S app
USER app
CMD ["node", "server.js"]
# Pass secrets at runtime: docker run -e API_KEY=$API_KEY my-app
```

---

## Section 5: Resource Management & Health Checks

```yaml
# In docker-compose.yml
services:
  app:
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M
```

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:3000/health || exit 1
```

---

## Section 6: Debug & Build Commands

```bash
# Container inspection
docker logs <container> --tail 100 -f      # Tail logs
docker exec -it <container> sh             # Shell into container
docker inspect <container>                 # Full metadata
docker stats                               # Live resource usage

# Network debugging
docker network ls                          # List networks
docker network inspect <network>           # Show connected containers

# Image analysis
docker image history <image>               # Show layers
docker system df                           # Disk usage overview

# Build commands
docker build -t my-app .
docker build --target production -t my-app:prod .
docker buildx build --platform linux/amd64,linux/arm64 -t my-app .

# Compose commands
docker compose up -d
docker compose ps
docker compose logs -f
docker compose down
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
