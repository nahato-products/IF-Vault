# Docker Expert — Reference

Detailed code examples and advanced patterns referenced from SKILL.md.

## Task 1: Optimized Node.js Dockerfile

Complete multi-stage build with signal handling, health check, and non-root user.

```dockerfile
FROM node:lts-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build && npm prune --omit=dev

FROM node:lts-alpine
RUN apk add --no-cache dumb-init
WORKDIR /app
RUN addgroup -g 1001 -S nodejs && adduser -S nodejs -u 1001
COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --chown=nodejs:nodejs package.json ./
USER nodejs
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s CMD node healthcheck.js || exit 1
ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "dist/index.js"]
```

## Task 2: Python Application Dockerfile

Uses virtual environment, system deps cleanup, and non-root user.

```dockerfile
FROM python:3-slim AS builder
RUN apt-get update && \
    apt-get install -y --no-install-recommends gcc && \
    rm -rf /var/lib/apt/lists/*
WORKDIR /app
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

FROM python:3-slim
WORKDIR /app
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
COPY . .
RUN useradd -m -u 1001 appuser && chown -R appuser:appuser /app
USER appuser
EXPOSE 8000
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "app:app"]
```

## Task 3: Go Static Binary with Distroless

Minimal image using scratch or distroless for compiled languages.

```dockerfile
FROM golang:alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /server .

FROM gcr.io/distroless/static
COPY --from=builder /server /server
EXPOSE 8080
ENTRYPOINT ["/server"]
```

## Task 4: Multi-Service Docker Compose

Full-stack example with frontend, backend, database, and cache.

```yaml
services:
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    ports:
      - '3000:3000'
    environment:
      - API_URL=http://backend:4000
    depends_on:
      backend:
        condition: service_healthy
    networks:
      - app-network
    restart: unless-stopped

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    ports:
      - '4000:4000'
    environment:
      - DATABASE_URL=postgresql://user:password@database:5432/mydb
      - REDIS_URL=redis://cache:6379
    depends_on:
      database:
        condition: service_healthy
      cache:
        condition: service_started
    networks:
      - app-network
      - db-network
    healthcheck:
      test: ['CMD', 'curl', '-f', 'http://localhost:4000/health']
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    restart: unless-stopped

  database:
    image: postgres:16-alpine
    environment:
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=password
      - POSTGRES_DB=mydb
    volumes:
      - postgres-data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    networks:
      - db-network
    healthcheck:
      test: ['CMD-SHELL', 'pg_isready -U user']
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped

  cache:
    image: redis:7-alpine
    command: redis-server --appendonly yes
    volumes:
      - redis-data:/data
    networks:
      - app-network
    restart: unless-stopped

networks:
  app-network:
    driver: bridge
  db-network:
    driver: bridge

volumes:
  postgres-data:
  redis-data:
```

## Task 5: Development Environment with Hot Reload

**docker-compose.override.yml** (auto-merged with docker-compose.yml):

```yaml
services:
  app:
    build:
      context: .
      target: development
    volumes:
      - .:/app
      - /app/node_modules
    ports:
      - '3000:3000'
      - '9229:9229'  # Debugger
    environment:
      - NODE_ENV=development
    command: npm run dev
```

**Dockerfile with development target:**

```dockerfile
FROM node:lts-alpine AS base
WORKDIR /app
COPY package*.json ./

FROM base AS development
RUN npm install
COPY . .
CMD ["npm", "run", "dev"]

FROM base AS production
RUN npm ci --omit=dev
COPY . .
CMD ["node", "dist/index.js"]
```

## Advanced Patterns

### BuildKit Cache Mounts

Speed up builds by caching package manager data across builds.

```dockerfile
# syntax=docker/dockerfile:1

FROM golang:alpine
WORKDIR /app

# Cache go modules
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=bind,source=go.sum,target=go.sum \
    --mount=type=bind,source=go.mod,target=go.mod \
    go mod download

COPY . .

# Cache build artifacts
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go build -o /app/server .

CMD ["/app/server"]
```

### Docker Compose Profiles

Selectively start services based on environment.

```yaml
services:
  app:
    profiles: ['production', 'development']
    # ...

  test-db:
    profiles: ['development']
    image: postgres:16-alpine

  monitoring:
    profiles: ['production']
    image: prom/prometheus
```

```bash
docker compose --profile development up
docker compose --profile production up
```

### Docker Secrets Management

Use Docker Compose `secrets:` to avoid passing sensitive data through environment variables.

```yaml
services:
  backend:
    image: myapp:latest
    secrets:
      - db_password
      - api_key
    environment:
      - DB_PASSWORD_FILE=/run/secrets/db_password
      - API_KEY_FILE=/run/secrets/api_key

secrets:
  db_password:
    file: ./secrets/db_password.txt
  api_key:
    environment: API_KEY
```

Reading secrets at runtime in the application:

```javascript
const fs = require('fs');

function readSecret(name) {
  const filePath = `/run/secrets/${name}`;
  return fs.readFileSync(filePath, 'utf8').trim();
}

const dbPassword = readSecret('db_password');
```

### Multi-Architecture Builds

Build images for multiple CPU architectures (amd64 + arm64).

```bash
# Create and use a multi-platform builder
docker buildx create --name multiarch --use
docker buildx build --platform linux/amd64,linux/arm64 \
  -t myapp:latest --push .
```
