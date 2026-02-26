---
name: observability
description: "Instrument applications with OpenTelemetry traces, metrics, and logs for full-stack observability covering distributed tracing, structured JSON logging, SLI/SLO definition, alert design, Datadog/Grafana dashboards, and Next.js/Node.js instrumentation. Use when adding tracing to services, implementing structured logging, defining SLIs and SLOs, designing alert rules, setting up Datadog or Grafana dashboards, instrumenting Next.js API routes or Server Actions, configuring OpenTelemetry SDK, reducing alert fatigue, debugging latency issues, building observability pipelines, or reviewing monitoring coverage. Do not trigger for application error handling patterns (use error-handling-logging), CI/CD pipeline configuration (use ci-cd-deployment), or security incident detection (use security-arsenal)."
user-invocable: false
---

# Observability

## Scope [HIGH]

| Topic | Here | Other |
|-------|------|-------|
| OpenTelemetry SDK setup / tracing | Yes | - |
| Structured logging format & correlation | Yes | `error-handling-logging`(エラー分類・AppError設計) |
| Metrics design (RED/USE/custom) | Yes | - |
| SLI/SLO definition & error budgets | Yes | - |
| Alert design & burn rate alerts | Yes | - |
| Datadog APM / Grafana dashboards | Yes | `_dashboard-data-viz`(ダッシュボードUI設計) |
| Next.js instrumentation.ts | Yes | `nextjs-app-router-patterns`(ルーティング・file conventions) |
| Error boundary / AppError class | - | `error-handling-logging` |
| CI/CD pipeline for deploy | - | `ci-cd-deployment` |
| Security incident detection | - | `security-arsenal` |
| Performance optimization (Core Web Vitals) | - | `vercel-react-best-practices` |

---

## Three Pillars of Observability [CRITICAL]

各シグナルの使い分け。**全部使う**のが理想だが、優先順位をつけるならこの順。

| Pillar | What | When to Use | Example |
|--------|------|-------------|---------|
| **Traces** | リクエストのライフサイクル全体を追跡 | レイテンシ調査、サービス間依存の可視化、ボトルネック特定 | `POST /api/orders` が遅い → どのSpanが支配的か |
| **Metrics** | 集約された数値データ（時系列） | SLI/SLO監視、トレンド分析、アラート発火 | Error rate > 1% で PagerDuty 通知 |
| **Logs** | 個別イベントの詳細記録 | デバッグ、監査、エラー詳細の調査 | `userId=abc` の注文が失敗した理由 |

### Decision Tree: Traces vs Metrics vs Logs

```
何を知りたい？
├─ 「今、正常？異常？」 → Metrics（集約値でアラート）
├─ 「なぜ遅い？どこで詰まった？」 → Traces（Span単位でボトルネック特定）
├─ 「この1件の詳細は？」 → Logs（個別イベントの文脈）
└─ 「全部つなげて調査したい」 → Trace ID で 3つを相関（Golden Signal）
```

**Iron Rule:** Metrics でアラート → Traces で原因特定 → Logs で詳細調査。この順番を守る。

---

## OpenTelemetry SDK Setup [CRITICAL]

### Auto-Instrumentation (Node.js / Next.js)

```typescript
// instrumentation.ts（Next.js App Router）
export async function register() {
  if (process.env.NEXT_RUNTIME === 'nodejs') {
    await import('./lib/otel');
  }
}
```

`lib/otel.ts` の完全な実装 -> [reference.md > OTel SDK Setup](reference.md#otel-sdk-setup)

### Key Packages

```bash
pnpm add @opentelemetry/sdk-node @opentelemetry/auto-instrumentations-node \
  @opentelemetry/exporter-trace-otlp-http @opentelemetry/exporter-metrics-otlp-http \
  @opentelemetry/resources @opentelemetry/semantic-conventions
```

### Manual Span Creation [CRITICAL]

```typescript
import { trace, SpanStatusCode } from '@opentelemetry/api';

const tracer = trace.getTracer('app-name');

async function processOrder(orderId: string) {
  return tracer.startActiveSpan('processOrder', async (span) => {
    try {
      span.setAttribute('order.id', orderId);
      const result = await chargePayment(orderId);
      span.setAttribute('payment.status', result.status);
      return result;
    } catch (err) {
      span.recordException(err as Error);
      span.setStatus({ code: SpanStatusCode.ERROR, message: (err as Error).message });
      throw err;
    } finally {
      span.end();
    }
  });
}
```

### Context Propagation [HIGH]

- **自動**: `fetch` / `http` は auto-instrumentation が W3C TraceContext ヘッダを伝播
- **手動**: `context.with(trace.setSpan(context.active(), span), fn)` で明示的に伝播
- **Edge Runtime**: `propagation.inject(context.active(), headers)` でヘッダに注入

### Span Attributes Best Practices [HIGH]

| Category | Attributes | Example |
|----------|-----------|---------|
| Identity | `user.id`, `tenant.id` | `span.setAttribute('user.id', userId)` |
| Business | `order.id`, `payment.method` | 業務コンテキストを付与 |
| Technical | `db.system`, `http.method` | Auto-instrumentation が自動付与 |
| Error | `error.type`, `error.message` | `span.recordException(err)` |

**Rule:** Sensitive data (password, token, PII) は絶対に Span Attribute に入れない。

---

## Structured Logging [HIGH]

### JSON Log Format with Correlation IDs

```typescript
// 全ログに trace_id / span_id を自動付与
logger.info('Order created', {
  orderId: 'ord_123',
  userId: 'usr_456',
  amount: 9800,
  trace_id: getActiveTraceId(),  // OTelから自動取得
});
// Output: {"level":"info","message":"Order created","orderId":"ord_123","trace_id":"abc123...","timestamp":"..."}
```

pino を使った完全な実装 -> [reference.md > Pino Logger Setup](reference.md#pino-logger-setup)

### Log Levels Strategy [HIGH]

| Level | When | Production | Alert? |
|-------|------|-----------|--------|
| **ERROR** | 対処が必要な障害 | Always | Yes (PagerDuty) |
| **WARN** | 劣化・リトライ成功・閾値接近 | Always | No (ダッシュボード監視) |
| **INFO** | 正常な業務イベント | Always | No |
| **DEBUG** | 開発時のみ必要な詳細 | Off (`LOG_LEVEL=info`) | No |

**Rule:** `console.log` 禁止。構造化ロガー（pino推奨）を使う。

### Sensitive Data Redaction [HIGH]

```typescript
// pino の redact オプション
const logger = pino({
  redact: ['password', 'token', 'creditCard', '*.authorization', 'req.headers.cookie'],
});
```

NEVER log: passwords, API keys, tokens, credit card numbers, PII (email, phone).
error-handling-logging の Sensitive Data Rules と同じ原則。

---

## Metrics Design [CRITICAL]

### RED Method (Services) [CRITICAL]

サービスごとに必ずこの3つを計測。

| Signal | Metric | Type | Example |
|--------|--------|------|---------|
| **R**ate | `http.server.request.count` | Counter | リクエスト数/秒 |
| **E**rrors | `http.server.error.count` | Counter | 5xx レスポンス数 |
| **D**uration | `http.server.duration` | Histogram | レスポンスタイム分布 |

### USE Method (Resources) [HIGH]

インフラリソースごとに計測。

| Signal | What | Example |
|--------|------|---------|
| **U**tilization | 使用率 | CPU 80%, Memory 70% |
| **S**aturation | 飽和度 | Queue depth, connection pool usage |
| **E**rrors | エラー | Disk I/O errors, OOM kills |

### Metric Type Selection [CRITICAL]

| Type | When | Example |
|------|------|---------|
| **Counter** | 単調増加する値 | Total requests, errors, bytes sent |
| **Histogram** | 分布を見たい値 | Response time, payload size |
| **Gauge** | 増減する現在値 | Active connections, queue depth, CPU % |
| **UpDownCounter** | 増減するカウンタ | Active sessions, in-flight requests |

**Rule:** レイテンシは**必ず Histogram**。平均値だけ見ると p99 の劣化を見逃す。

### Custom Business Metrics [HIGH]

```typescript
const orderCounter = meter.createCounter('app.orders.created');
const orderValueHistogram = meter.createHistogram('app.orders.value');

orderCounter.add(1, { payment_method: 'credit_card', plan: 'pro' });
orderValueHistogram.record(amount, { currency: 'JPY' });
```

-> 完全な実装: [reference.md > Custom Metrics Examples](reference.md#custom-metrics-examples)

---

## SLI/SLO [CRITICAL]

### SLI Definition Patterns [CRITICAL]

| SLI Type | Formula | Good Event | Total Event |
|----------|---------|-----------|-------------|
| **Availability** | good / total | Status != 5xx | All requests |
| **Latency** | fast / total | Duration < threshold | All requests |
| **Error Rate** | (total - errors) / total | No error | All requests |
| **Freshness** | fresh / total | Data age < threshold | All data points |

### SLO Target Setting [CRITICAL]

| Target | Monthly Downtime | Use Case |
|--------|-----------------|----------|
| 99.0% | ~7.3 hours | 社内ツール、バッチ処理 |
| 99.5% | ~3.65 hours | 一般的なWebアプリ |
| 99.9% | ~43.8 minutes | 重要なAPI、決済系 |
| 99.95% | ~21.9 minutes | プラットフォーム API |
| 99.99% | ~4.38 minutes | インフラ基盤（高コスト） |

**Rule:** 最初は 99.5% から始めて実績を見て調整。99.99% はコストと複雑さが急増する。

### Error Budget Policy [HIGH]

```
Error Budget = 1 - SLO Target
例: SLO 99.9% → Error Budget = 0.1%（月間約43分）

Budget 消費 > 50%: 新機能デプロイ減速、信頼性改善を優先
Budget 消費 > 80%: Feature freeze、全リソースを信頼性に
Budget 消費 100%: 完全停止、ポストモーテム実施
```

-> SLO Worksheet テンプレート: [reference.md > SLO Worksheet](reference.md#slo-worksheet)

### Burn Rate Alerts [CRITICAL]

単純なエラー率アラートではなく、**Error Budget の消費速度**で発火。

| Window | Burn Rate | Budget Consumed | Severity |
|--------|-----------|-----------------|----------|
| 1h | 14.4x | 2% in 1h | Critical (page) |
| 6h | 6x | 5% in 6h | Critical (page) |
| 1d | 3x | 10% in 1d | Warning (ticket) |
| 3d | 1x | 10% in 3d | Info (dashboard) |

**Multi-window**: 短い窓(1h) AND 長い窓(6h) の両方が閾値超えで発火。誤報を大幅削減。

-> 計算式とアラートルール: [reference.md > Burn Rate Calculation](reference.md#burn-rate-calculation)

---

## Alert Design [HIGH]

### Alert Fatigue Prevention [CRITICAL]

| Principle | Bad | Good |
|-----------|-----|------|
| Symptom-based | `CPU > 80%` | `Error rate > 1% for 5min` |
| Actionable | `Disk 90%` (then what?) | `Disk 90%` + Runbook link |
| Deduplicated | 同じ問題で10件通知 | Group by service + alert name |
| Right severity | 全部 Critical | Critical = page人、Warning = チケット |

**Rule:** 全アラートに Runbook URL を必須。「何をすべきか」がわからないアラートは害。

### Severity Levels [HIGH]

| Severity | Response | Channel | Example |
|----------|----------|---------|---------|
| **Critical** | 即時対応（5分以内にACK） | PagerDuty / Phone | SLO burn rate 14.4x |
| **Warning** | 営業時間内に対応 | Slack #alerts | Error rate trending up |
| **Info** | 次スプリントで検討 | Dashboard only | Cache hit ratio declining |

### Runbook Template [HIGH]

```markdown
## Alert: [alert-name]
### Impact: [ユーザー影響の説明]
### Investigation:
1. ダッシュボード確認: [URL]
2. 関連ログ検索: `service=xxx error=true`
3. 直近デプロイ確認: `gh run list --limit 5`
### Mitigation:
- [ ] ロールバック手順: [URL]
- [ ] スケールアップ手順: [URL]
### Escalation: [次の連絡先]
```

---

## Next.js Specific [HIGH]

### Server Actions Tracing [HIGH]

```typescript
'use server'
import { trace } from '@opentelemetry/api';

const tracer = trace.getTracer('server-actions');

export async function createOrder(formData: FormData) {
  return tracer.startActiveSpan('serverAction.createOrder', async (span) => {
    try {
      span.setAttribute('form.fields', Object.keys(Object.fromEntries(formData)).join(','));
      // ... business logic
      return { success: true, data: result };
    } catch (err) {
      span.recordException(err as Error);
      span.setStatus({ code: SpanStatusCode.ERROR });
      return { success: false, error: { code: 'CREATE_FAILED', message: 'Order creation failed' } };
    } finally {
      span.end();
    }
  });
}
```

### Route Handler Instrumentation [HIGH]

```typescript
// app/api/orders/route.ts
import { trace } from '@opentelemetry/api';

const tracer = trace.getTracer('api-routes');

export async function POST(request: Request) {
  return tracer.startActiveSpan('api.orders.create', async (span) => {
    try {
      span.setAttribute('http.method', 'POST');
      span.setAttribute('http.route', '/api/orders');
      // ... handler logic
    } finally {
      span.end();
    }
  });
}
```

**Note:** `@vercel/otel` を使うと Route Handler は自動計装される。手動は追加のビジネスSpanだけ。

### Edge Runtime Considerations [MEDIUM]

- Edge Runtime では `@opentelemetry/sdk-node` が動かない（Node.js API 依存）
- **代替**: `@opentelemetry/api` のみ import し、Vercel の Edge トレーシングに委譲
- Middleware のトレーシングは `@vercel/otel` が自動対応

### Vercel Observability Integration [HIGH]

```typescript
// instrumentation.ts（Vercel 環境）
import { registerOTel } from '@vercel/otel';

export function register() {
  registerOTel({
    serviceName: 'my-next-app',
    // Vercel が自動でトレースを収集・可視化
  });
}
```

Vercel + 外部バックエンド（Datadog等）の併用 -> [reference.md > Vercel + Datadog Setup](reference.md#datadog-apm-integration)

---

## Checklist [CRITICAL]

### [CRITICAL] Tracing
- [ ] `instrumentation.ts` で OTel SDK 初期化済み
- [ ] 主要 API Route / Server Action に手動 Span 追加
- [ ] Span に業務コンテキスト（orderId, userId 等）を付与
- [ ] `span.recordException()` でエラー記録
- [ ] Sensitive data が Span Attribute に含まれていない

### [CRITICAL] Metrics
- [ ] RED metrics（Rate, Errors, Duration）をサービスごとに計測
- [ ] レイテンシは Histogram で計測（平均値だけではない）
- [ ] ビジネスメトリクス（注文数、売上等）をカスタム計測

### [CRITICAL] SLI/SLO
- [ ] 主要サービスの SLI を定義（Availability, Latency p99）
- [ ] SLO ターゲットを設定し、Error Budget を算出
- [ ] Burn rate alert を設定（multi-window）

### [HIGH] Logging
- [ ] 構造化 JSON ログ（pino推奨）
- [ ] `trace_id` / `span_id` をログに自動付与（Log-Trace correlation）
- [ ] Sensitive data の redact 設定済み
- [ ] Log Level が適切（本番で DEBUG off）

### [HIGH] Alerts
- [ ] 全アラートに Runbook URL 付与
- [ ] Severity が適切（Critical = page 人、Warning = チケット）
- [ ] Symptom-based アラート（cause-based ではない）
- [ ] Multi-window burn rate で誤報削減

---

## Anti-Patterns [HIGH]

| Anti-Pattern | Problem | Fix |
|-------------|---------|-----|
| `console.log` デバッグ | 構造化されない、相関不可 | pino + trace_id |
| 平均レイテンシだけ監視 | p99 劣化を見逃す | Histogram + percentile |
| CPU > 80% でアラート | Cause-based、actionable でない | Error rate / latency SLI |
| 全部 Critical アラート | Alert fatigue → 無視される | Severity を3段階に分離 |
| Sampling rate 100% | コスト爆発 | 0.1〜0.01 に設定、エラーは 100% |
| ログに PII 含む | コンプライアンス違反 | pino redact 設定 |
| SLO なしでアラート | 基準不明 → ノイズ | SLI 定義 → SLO → Burn rate |

---

## Cross-references [MEDIUM]

- **error-handling-logging**: エラー分類（Operational/Programmer）、AppError設計、ログレベル基本方針
- **ci-cd-deployment**: OTel Collector のデプロイ、Feature flag によるサンプリング率制御
- **_dashboard-data-viz**: ダッシュボードのUI設計原則、RED/SLOダッシュボードのレイアウト

## Reference

OTel SDK完全セットアップ、pino実装、メトリクス例、SLOワークシート、アラートルールテンプレート、Burn rate計算式、Datadog/Grafana設定、Before/After例 -> [reference.md](reference.md)
