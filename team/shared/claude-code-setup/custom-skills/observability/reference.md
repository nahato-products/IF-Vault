# Observability — Reference

Copy-paste-ready テンプレート: OTel SDK、pino構造化ログ、メトリクス、SLOワークシート、アラートルール、Burn rate計算、Datadog/Grafana、Before/After。

**Cross-references**: `error-handling-logging`(AppError/ログ基盤), `ci-cd-deployment`(OTel Collector デプロイ), `_dashboard-data-viz`(ダッシュボードUI設計), `testing-strategy`(計装コードのテスト).

---

## OTel SDK Setup

### Complete Node.js / Next.js Setup

```typescript
// lib/otel.ts
import { NodeSDK } from '@opentelemetry/sdk-node';
import { getNodeAutoInstrumentations } from '@opentelemetry/auto-instrumentations-node';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';
import { OTLPMetricExporter } from '@opentelemetry/exporter-metrics-otlp-http';
import { PeriodicExportingMetricReader } from '@opentelemetry/sdk-metrics';
import { Resource } from '@opentelemetry/resources';
import {
  ATTR_SERVICE_NAME, ATTR_SERVICE_VERSION, ATTR_DEPLOYMENT_ENVIRONMENT_NAME,
} from '@opentelemetry/semantic-conventions';

const resource = new Resource({
  [ATTR_SERVICE_NAME]: process.env.OTEL_SERVICE_NAME ?? 'my-next-app',
  [ATTR_SERVICE_VERSION]: process.env.npm_package_version ?? '0.0.0',
  [ATTR_DEPLOYMENT_ENVIRONMENT_NAME]: process.env.NODE_ENV ?? 'development',
});

const endpoint = process.env.OTEL_EXPORTER_OTLP_ENDPOINT ?? 'http://localhost:4318';

const sdk = new NodeSDK({
  resource,
  traceExporter: new OTLPTraceExporter({ url: `${endpoint}/v1/traces` }),
  metricReader: new PeriodicExportingMetricReader({
    exporter: new OTLPMetricExporter({ url: `${endpoint}/v1/metrics` }),
    exportIntervalMillis: 30_000,
  }),
  instrumentations: [
    getNodeAutoInstrumentations({
      '@opentelemetry/instrumentation-fs': { enabled: false }, // fs は大量Span生成
      '@opentelemetry/instrumentation-fetch': { enabled: true },
      '@opentelemetry/instrumentation-http': { enabled: true },
    }),
  ],
});

sdk.start();
process.on('SIGTERM', () => { sdk.shutdown().catch(console.error); });
```

### Next.js instrumentation.ts

```typescript
// instrumentation.ts（プロジェクトルート）
export async function register() {
  if (process.env.NEXT_RUNTIME === 'nodejs') await import('./lib/otel');
}
```

### Vercel + @vercel/otel

```typescript
// instrumentation.ts（Vercel デプロイ時）
import { registerOTel } from '@vercel/otel';
export function register() {
  registerOTel({ serviceName: 'my-next-app' });
}
```

---

## Pino Logger Setup

```typescript
// lib/logger.ts
import pino from 'pino';
import { trace, context } from '@opentelemetry/api';

function otelMixin() {
  const span = trace.getSpan(context.active());
  if (!span) return {};
  const ctx = span.spanContext();
  return { trace_id: ctx.traceId, span_id: ctx.spanId, trace_flags: ctx.traceFlags };
}

export const logger = pino({
  level: process.env.LOG_LEVEL ?? (process.env.NODE_ENV === 'production' ? 'info' : 'debug'),
  redact: {
    paths: ['password', 'token', 'accessToken', 'refreshToken', 'creditCard',
            'req.headers.authorization', 'req.headers.cookie', '*.apiKey', '*.secret'],
    censor: '[REDACTED]',
  },
  mixin: otelMixin,
  transport: process.env.NODE_ENV === 'development'
    ? { target: 'pino-pretty', options: { colorize: true } } : undefined,
  timestamp: pino.stdTimeFunctions.isoTime,
});

export function createChildLogger(module: string, extra?: Record<string, unknown>) {
  return logger.child({ module, ...extra });
}
```

### Usage

```typescript
const log = createChildLogger('orders');
// GOOD: 構造化ログ + 業務コンテキスト
log.info({ orderId: 'ord_123', userId: 'usr_456', amount: 9800 }, 'Order created');
log.error({ orderId: 'ord_123', err }, 'Payment failed');
// BAD: console.log('Order created: ' + orderId);
```

### Production JSON Output

```json
{"level":30,"time":"2026-02-24T10:30:00.000Z","module":"orders","orderId":"ord_123","trace_id":"abc123...","msg":"Order created"}
```

---

## Custom Metrics Examples

### RED Metrics (lib/metrics.ts)

```typescript
import { metrics } from '@opentelemetry/api';
const meter = metrics.getMeter('api-metrics');

export const requestCounter = meter.createCounter('http.server.request.count', {
  description: 'Total HTTP requests', unit: 'requests',
});
export const errorCounter = meter.createCounter('http.server.error.count', {
  description: 'Total HTTP errors (4xx, 5xx)', unit: 'errors',
});
export const requestDuration = meter.createHistogram('http.server.duration', {
  description: 'HTTP request duration', unit: 'ms',
  advice: { explicitBucketBoundaries: [5, 10, 25, 50, 100, 250, 500, 1000, 2500, 5000] },
});

export function recordRequest(method: string, route: string, status: number, durationMs: number) {
  const attrs = { 'http.method': method, 'http.route': route, 'http.status_code': status };
  requestCounter.add(1, attrs);
  if (status >= 400) errorCounter.add(1, attrs);
  requestDuration.record(durationMs, attrs);
}
```

### Business Metrics (lib/business-metrics.ts)

```typescript
import { metrics } from '@opentelemetry/api';
const meter = metrics.getMeter('business-metrics');

export const ordersCreated = meter.createCounter('app.orders.created');
export const orderValue = meter.createHistogram('app.orders.value', {
  unit: 'JPY', advice: { explicitBucketBoundaries: [500, 1000, 3000, 5000, 10000, 30000, 100000] },
});
export const activeUsers = meter.createObservableGauge('app.users.active');
export const queueDepth = meter.createUpDownCounter('app.queue.depth');

// Usage
ordersCreated.add(1, { plan: 'pro', payment_method: 'credit_card' });
orderValue.record(9800, { currency: 'JPY' });
queueDepth.add(1);  // enqueue
queueDepth.add(-1); // dequeue
```

---

## SLO Worksheet

```markdown
## SLO Worksheet: [Service Name]

### Service Overview
- **Owner**: [Team]
- **Dependencies**: [upstream/downstream]
- **Critical User Journeys**: [list]

### SLI Definitions
| SLI | Good Event | Total Event | Measurement |
|-----|-----------|-------------|-------------|
| Availability | status != 5xx | All requests | Load balancer logs |
| Latency (p99) | duration < 500ms | All requests | OTel histogram |
| Error Rate | no application error | All requests | Application metrics |

### SLO Targets
| SLI | Target | Window | Error Budget |
|-----|--------|--------|-------------|
| Availability | 99.9% | 30 days | 43.2 min/month |
| Latency p99 | < 500ms for 99.5% | 30 days | 3.65 hours/month |

### Error Budget Policy
- **50%**: Deploy 減速、信頼性優先
- **80%**: Feature freeze
- **100%**: 完全停止、ポストモーテム

### Burn Rate Alerts
| Severity | Short Window | Long Window | Burn Rate | Action |
|----------|-------------|-------------|-----------|--------|
| Critical | 1h | 6h | 14.4x | Page on-call |
| Warning | 6h | 1d | 6x | Create ticket |
| Info | 1d | 3d | 3x | Dashboard review |
```

---

## Burn Rate Calculation

```
Burn Rate = Error Rate / (1 - SLO Target)
例: SLO 99.9%, Error Rate 1.44% → 0.0144 / 0.001 = 14.4x

Budget Consumed = Burn Rate × Window Hours / (30 × 24) × 100%

| Burn Rate | 1h    | 6h   | 1d   | 3d    |
|-----------|-------|------|------|-------|
| 1x        | 0.14% | 0.83% | 3.33% | 10%  |
| 3x        | 0.42% | 2.5%  | 10%   | 30%  |
| 6x        | 0.83% | 5%    | 20%   | 60%  |
| 14.4x     | 2%    | 12%   | 48%   | 100%+|
```

### Multi-Window Alert Rule

```
ALERT: SLO Burn Rate Critical
  IF burn_rate(1h) > 14.4 AND burn_rate(6h) > 14.4
  SEVERITY: critical → Page on-call
  RUNBOOK: https://runbooks.internal/slo-burn-critical

ALERT: SLO Burn Rate Warning
  IF burn_rate(6h) > 6 AND burn_rate(1d) > 6
  SEVERITY: warning → Create ticket
```

---

## Alert Rule Templates

### Datadog Monitor

```json
{
  "name": "[SLO] API Availability - Burn Rate Critical",
  "type": "query alert",
  "query": "sum(last_1h):sum:http.server.error.count{service:my-api}.as_count() / sum:http.server.request.count{service:my-api}.as_count() > 0.0144",
  "message": "## SLO Burn Rate Critical\n\nError rate exceeds 14.4x burn rate (~2%/hour).\n\n### Investigation\n1. [APM Dashboard](https://app.datadoghq.com/apm/service/my-api)\n2. `gh run list --limit 5`\n\n### Mitigation\n- `vercel rollback`\n\n@pagerduty-my-team",
  "tags": ["service:my-api", "slo:availability", "severity:critical"],
  "options": { "thresholds": { "critical": 0.0144 }, "renotify_interval": 30 }
}
```

### Grafana Alert Rule

```yaml
apiVersion: 1
groups:
  - name: SLO Alerts
    folder: Observability
    interval: 1m
    rules:
      - uid: slo-burn-critical
        title: "SLO Burn Rate Critical"
        data:
          - refId: A
            relativeTimeRange: { from: 3600, to: 0 }
            datasourceUid: prometheus
            model:
              expr: "sum(rate(http_server_request_duration_seconds_count{status=~\"5..\"}[1h])) / sum(rate(http_server_request_duration_seconds_count[1h]))"
          - refId: B
            relativeTimeRange: { from: 21600, to: 0 }
            datasourceUid: prometheus
            model:
              expr: "sum(rate(http_server_request_duration_seconds_count{status=~\"5..\"}[6h])) / sum(rate(http_server_request_duration_seconds_count[6h]))"
        for: 5m
        labels: { severity: critical }
        annotations:
          summary: "API availability SLO burn rate exceeds 14.4x"
          runbook_url: "https://runbooks.internal/slo-burn-critical"
```

---

## Dashboard Layout Patterns

### RED Dashboard

```
┌─────────────────────────────────────────────────┐
│ Service: my-api                    [Last 6 hours]│
├────────────────┬────────────────┬────────────────┤
│ Request Rate   │ Error Rate     │ Latency        │
│ 1,234 req/s    │ 0.3%          │ p50:45ms p99:234ms│
├────────────────┴────────────────┴────────────────┤
│ Latency Heatmap                                   │
├────────────────┬─────────────────────────────────┤
│ Error Breakdown│ Top Slow Endpoints               │
│ 400: 50%       │ POST /api/orders (p99: 890ms)   │
│ 500: 27%       │ GET /api/users   (p99: 456ms)   │
└────────────────┴─────────────────────────────────┘
```

### SLO Dashboard

```
┌─────────────────────────────────────────────────┐
│ SLO Overview                       [Last 30 days]│
├────────────────┬────────────────┬────────────────┤
│ Availability   │ Latency p99    │ Error Budget   │
│ 99.94%         │ 99.7%          │ 42% remaining  │
│ Target: 99.9%  │ Target: 99.5%  │ ████████░░░░   │
├─────────────────────────────────────────────────┤
│ Burn Rate (7d) + Budget Events                   │
└─────────────────────────────────────────────────┘
```

### Grafana Panels (Prometheus)

```
# Request Rate
sum(rate(http_server_request_duration_seconds_count{service="my-api"}[5m]))

# Latency Percentiles
histogram_quantile(0.50, sum(rate(http_server_request_duration_seconds_bucket{service="my-api"}[5m])) by (le))
histogram_quantile(0.99, sum(rate(http_server_request_duration_seconds_bucket{service="my-api"}[5m])) by (le))
```

---

## Datadog APM Integration

### dd-trace Setup

```typescript
// lib/dd-trace.ts — Datadog ネイティブトレーサー（OTel の代替）
import tracer from 'dd-trace';
tracer.init({
  service: process.env.DD_SERVICE ?? 'my-next-app',
  env: process.env.DD_ENV ?? process.env.NODE_ENV,
  version: process.env.DD_VERSION ?? '1.0.0',
  logInjection: true,    // ログに trace_id 自動注入
  runtimeMetrics: true,  // Node.js ランタイムメトリクス
  profiling: true,
  sampleRate: process.env.NODE_ENV === 'production' ? 0.1 : 1.0,
});
export default tracer;
```

### Datadog Log Correlation (pino)

```typescript
// Datadog convention に合わせた pino formatter
const logger = pino({
  messageKey: 'message',
  formatters: {
    level: (label) => ({ status: label }),
    log: (obj) => obj.trace_id
      ? { ...obj, 'dd.trace_id': obj.trace_id, 'dd.span_id': obj.span_id }
      : obj,
  },
});
```

---

## Log Correlation Patterns

```typescript
// Server Action 内でのログ + トレース相関
'use server'
import { trace } from '@opentelemetry/api';
import { createChildLogger } from '@/lib/logger';

const log = createChildLogger('checkout');

export async function checkout(formData: FormData) {
  const traceId = trace.getActiveSpan()?.spanContext().traceId;
  log.info({ traceId, step: 'start' }, 'Checkout started');
  try {
    const payment = await processPayment(formData);
    log.info({ traceId, paymentId: payment.id, step: 'payment_ok' }, 'Payment succeeded');
    const order = await createOrder(payment);
    log.info({ traceId, orderId: order.id }, 'Order created');
    return { success: true, data: { orderId: order.id } };
  } catch (err) {
    log.error({ traceId, err }, 'Checkout failed');
    trace.getActiveSpan()?.recordException(err as Error);
    return { success: false, error: { code: 'CHECKOUT_FAILED', message: 'Checkout failed' } };
  }
}
```

---

## Before/After Examples

### Before: 計装なし

```typescript
export async function POST(request: Request) {
  try {
    const body = await request.json();
    const order = await db.orders.create({ data: body });
    await sendEmail(order.userId, 'Order confirmed');
    return Response.json(order);
  } catch (err) {
    console.log('Error:', err);  // 文字列ログ、trace なし
    return Response.json({ error: 'Something went wrong' }, { status: 500 });
  }
}
```

### After: トレース + 構造化ログ + メトリクス

```typescript
import { trace, SpanStatusCode } from '@opentelemetry/api';
import { createChildLogger } from '@/lib/logger';
import { requestDuration, errorCounter, ordersCreated, orderValue } from '@/lib/metrics';

const tracer = trace.getTracer('api-orders');
const log = createChildLogger('orders');

export async function POST(request: Request) {
  const start = performance.now();
  return tracer.startActiveSpan('api.orders.create', async (span) => {
    try {
      const body = await request.json();
      span.setAttribute('order.plan', body.plan);
      const order = await db.orders.create({ data: body });
      span.setAttribute('order.id', order.id);

      await tracer.startActiveSpan('sendConfirmationEmail', async (emailSpan) => {
        try { await sendEmail(order.userId, 'Order confirmed'); }
        finally { emailSpan.end(); }
      });

      ordersCreated.add(1, { plan: body.plan });
      orderValue.record(body.amount, { currency: 'JPY' });
      log.info({ orderId: order.id, amount: body.amount }, 'Order created');
      requestDuration.record(performance.now() - start, { 'http.method': 'POST', 'http.route': '/api/orders' });
      return Response.json(order, { status: 201 });
    } catch (err) {
      span.recordException(err as Error);
      span.setStatus({ code: SpanStatusCode.ERROR });
      errorCounter.add(1, { 'http.method': 'POST', 'http.route': '/api/orders' });
      log.error({ err }, 'Order creation failed');
      requestDuration.record(performance.now() - start, { 'http.method': 'POST', 'http.route': '/api/orders' });
      return Response.json({ error: { code: 'CREATE_FAILED', message: 'Order creation failed' } }, { status: 500 });
    } finally { span.end(); }
  });
}
```

---

## Anti-Patterns Checklist

### Tracing

| # | Anti-Pattern | Fix |
|---|-------------|-----|
| T-1 | Span を end() しない → メモリリーク | `finally { span.end() }` |
| T-2 | Sampling 100% → コスト爆発 | Production: 0.01〜0.1 |
| T-3 | Span に PII → コンプラ違反 | userId のみ。email/name NG |
| T-4 | recordException しない | `span.recordException(err)` |
| T-5 | 全部1つの巨大 Span | 論理ステップごとに子 Span |

### Metrics

| # | Anti-Pattern | Fix |
|---|-------------|-----|
| M-1 | 平均値だけ監視 | Histogram + percentile |
| M-2 | カーディナリティ爆発 | Label 値は有限集合に限定 |
| M-3 | Gauge でリクエスト数 | Counter を使う |
| M-4 | バケット境界が不適切 | レイテンシに合わせて調整 |

### Logging

| # | Anti-Pattern | Fix |
|---|-------------|-----|
| L-1 | console.log 文字列連結 | 構造化 JSON（pino） |
| L-2 | DEBUG が本番で ON | `LOG_LEVEL=info` |
| L-3 | trace_id なし | pino mixin で自動付与 |
| L-4 | catch {} で握りつぶし | 最低限 log.error |
| L-5 | PII をログ出力 | pino redact 設定 |

### Alerts

| # | Anti-Pattern | Fix |
|---|-------------|-----|
| A-1 | 全部 Critical | Severity 3段階 |
| A-2 | Runbook なし | Runbook URL 必須 |
| A-3 | Cause-based (CPU 80%) | Symptom-based (SLI) |
| A-4 | 単一窓アラート | Multi-window burn rate |
| A-5 | SLO なしの閾値 | SLI → SLO → Burn rate |

---

## Environment Variables

```bash
# OpenTelemetry
OTEL_SERVICE_NAME=my-next-app
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318
OTEL_TRACES_SAMPLER=parentbased_traceidratio
OTEL_TRACES_SAMPLER_ARG=0.1

# Datadog
DD_SERVICE=my-next-app
DD_ENV=production
DD_VERSION=1.0.0
DD_TRACE_SAMPLE_RATE=0.1

# Logging
LOG_LEVEL=info
```

---

## New Project Setup Checklist

```
instrumentation.ts         <- OTel SDK 登録
lib/otel.ts               <- NodeSDK 初期化
lib/logger.ts             <- pino + trace_id mixin
lib/metrics.ts            <- RED メトリクス
lib/business-metrics.ts   <- ビジネスメトリクス
.env.local                <- OTEL_* / DD_* / LOG_LEVEL
lib/dd-trace.ts           <- Datadog 使用時のみ
docs/slo-worksheet.md     <- SLI/SLO 定義シート
docs/runbooks/            <- アラート対応手順書
```
