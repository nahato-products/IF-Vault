# 機能設計書：BQ日次集計パイプライン

## 概要

BigQuery（BQ）から CloudSQL（PostgreSQL）へ CV・クリックデータを日次で自動集計・取り込みするパイプライン。
スプレッドシートの「調理」工程（0A〜0F）を完全に置き換える。

## 対象テーブル

| テーブル | 内容 | 集計粒度 |
|----------|------|----------|
| `t_daily_performance_details` | CV件数・報酬額・単価 | パートナー × サイト × クライアント × コンテンツ × 日 |
| `t_daily_click_details` | クリック数 | サイト × 日 |
| `ingestion_logs` | ジョブ実行履歴 | ジョブ単位 |

## アーキテクチャ

```
Cloud Scheduler (毎日 AM 5:00 JST)
    │
    ▼
Cloud Run Jobs (Python コンテナ)
    │
    ├── 1. ingestion_logs に RUNNING レコード作成
    ├── 2. BQ API で前日分データを集計クエリ
    ├── 3. マスタ情報を JOIN してスナップショット化
    ├── 4. CloudSQL に UPSERT（ON CONFLICT で冪等性確保）
    ├── 5. ingestion_logs を SUCCESS に更新
    └── 6. 失敗時 → FAILED + error_message 記録 → RETRY ジョブ登録
```

## 方式選定

| 方法 | 評価 | 理由 |
|------|------|------|
| Cloud Functions + Scheduler | △ | タイムアウト制約（最大60分）が不安 |
| **Cloud Run Jobs + Scheduler** | **◎ 採用** | タイムアウト柔軟、Python環境自由、コスト安い |
| Dataflow (Apache Beam) | × | 今の規模にはオーバーキル |

## BQ クエリ設計

### CV集計

```sql
SELECT
  DATE(action_timestamp) AS action_date,
  partner_id,
  site_id,
  client_id,
  content_id,
  COUNT(*) AS cv_count,
  SUM(cost) AS client_action_cost
FROM `project.dataset.cv_raw_table`
WHERE DATE(action_timestamp) = @target_date
GROUP BY 1, 2, 3, 4, 5
```

### クリック集計

```sql
SELECT
  DATE(action_timestamp) AS action_date,
  site_id,
  COUNT(*) AS click_count
FROM `project.dataset.click_raw_table`
WHERE DATE(action_timestamp) = @target_date
GROUP BY 1, 2
```

### スナップショット化

BQ集計結果に対して CloudSQL 側でマスタを JOIN し、集計時点の名称を保存する。

```sql
INSERT INTO t_daily_performance_details (
  action_date, partner_id, site_id, client_id, content_id,
  partner_name, site_name, client_name, content_name,
  cv_count, client_action_cost, unit_price
)
SELECT
  bq.action_date,
  bq.partner_id, bq.site_id, bq.client_id, bq.content_id,
  p.partner_name, s.site_name, c.client_name, ac.content_name,
  bq.cv_count,
  bq.client_action_cost,
  CASE WHEN bq.cv_count > 0
       THEN bq.client_action_cost / bq.cv_count
       ELSE 0 END
FROM bq_staging bq
JOIN m_partners p ON p.partner_id = bq.partner_id
JOIN t_partner_sites s ON s.site_id = bq.site_id
JOIN m_clients c ON c.client_id = bq.client_id
JOIN m_ad_contents ac ON ac.content_id = bq.content_id
ON CONFLICT (action_date, partner_id, site_id, client_id, content_id)
DO UPDATE SET
  cv_count = EXCLUDED.cv_count,
  client_action_cost = EXCLUDED.client_action_cost,
  unit_price = EXCLUDED.unit_price,
  updated_at = CURRENT_TIMESTAMP;
```

## ジョブ管理フロー

```
正常系:
  RUNNING → SUCCESS (records_count に取込件数記録)

異常系:
  RUNNING → FAILED (error_message にエラー詳細)
    → 自動で RETRY ジョブ登録（最大3回）
    → 3回失敗 → Slack / メール通知
```

## コスト設計

### BQ 課金の仕組み

| 料金種別 | 課金先 | 説明 |
|----------|--------|------|
| **スキャン料（クエリ課金）** | クエリを実行する GCP プロジェクト | 読み取ったデータ量に応じて課金 |
| **ストレージ料** | データを保持する GCP プロジェクト | 保存量に応じて課金 |

> CloudSQL 側にはデータ受信に対する追加課金は発生しない。
> BQ のスキャン料は「どのプロジェクトからクエリを投げたか」で決まる。

### コスト最適化

| 対策 | 効果 | 優先度 |
|------|------|--------|
| BQ テーブルをパーティション分割 | `WHERE date = @target_date` で1日分だけスキャン | 必須 |
| 必要カラムだけ SELECT | BQ はカラム単位課金。`SELECT *` 禁止 | 必須 |
| 日次1回のみ実行 | 不要な再実行を ingestion_logs で防止 | 必須 |
| BQ 定額プラン検討 | スキャン量が月 1TB 超えたら検討 | 将来 |

### 概算コスト（オンデマンド料金）

| 項目 | 単価 | 想定月額 |
|------|------|---------|
| BQ クエリ | $6.25 / TB | 日次集計なら月数百円〜数千円程度 |
| Cloud Run Jobs | 実行時間課金 | 月数百円以下 |
| Cloud Scheduler | $0.10 / ジョブ / 月 | ほぼ無料 |

## エラーハンドリング

| エラー種別 | 対応 |
|-----------|------|
| BQ API タイムアウト | リトライ（exponential backoff） |
| BQ クエリエラー | error_message に記録、RETRY ジョブ登録 |
| CloudSQL 接続エラー | リトライ + コネクションプール確認 |
| データ不整合（FK違反） | ログ記録 + 該当行スキップ + 通知 |
| 重複実行 | ingestion_logs で当日分 SUCCESS を確認してスキップ |

## 実装チェックリスト

- [ ] BQ 側テーブルのパーティション設定確認
- [ ] Cloud Run Jobs の Python コンテナ作成
- [ ] BQ API クライアント実装（google-cloud-bigquery）
- [ ] CloudSQL 接続設定（Cloud SQL Auth Proxy or Private IP）
- [ ] UPSERT ロジック実装（冪等性確保）
- [ ] ingestion_logs 管理ロジック
- [ ] リトライ機構（最大3回）
- [ ] Cloud Scheduler ジョブ設定（cron: `0 5 * * *`）
- [ ] 失敗時の通知（Slack / メール）
- [ ] ステージング環境でのE2Eテスト

## 関連ドキュメント

- [[ANSEM-プロジェクト全体サマリー]]
- [[ANSEM-ER図]]
- [[ANSEM-データ投入運用方針]]
- [[ANSEM-追加機能ロードマップ]]

---

_作成日: 2026-02-20_
_ステータス: 設計中（Phase 1 実装対象）_
