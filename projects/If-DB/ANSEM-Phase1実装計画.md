---
tags: [ANSEM, Phase1, 実装計画, memo]
created: 2026-02-15
status: draft
related: "[[ANSEM-追加機能ロードマップ]], [[ANSEM-一括登録機能メモ]], [[ANSEM-ER図]]"
---

# ANSEM Phase 1 実装計画

> 親ドキュメント: [[ANSEM-プロジェクト全体サマリー]] | [[ANSEM-設計ナビゲーションマップ]]

DB設計（v5.4.0 / 32テーブル）は完了。ここから先はアプリケーション層の実装。Phase 1はデータを入れて確認できる状態を作る。

---

## Phase 1 スコープ

| 機能 | 優先度 | 概要 |
|------|--------|------|
| ansem-import CLIツール | 最優先 | スプシCSV → DB投入 |
| BQ自動取り込み | 高 | BigQuery → PostgreSQL の日次パイプライン |
| 確認画面（DRY RUN） | 高 | データ変更前の差分プレビュー |
| 検索・フィルタリング | 中 | マスタデータの検索UI |

Phase 2（請求確定、CSVエクスポート、ダッシュボード）は Phase 1 の安定稼働後に着手。

---

## 1. ansem-import CLIツール

Phase 1 の核。初回データ移行だけでなく、月次・案件開始時の継続的なデータ投入に使う。

### 技術スタック

| 要素 | 選定 | 理由 |
|------|------|------|
| 言語 | Python 3.12+ | チーム習熟度、データ処理ライブラリが豊富 |
| DB接続 | psycopg 3 | 非同期対応、型安全、公式推奨 |
| CSV処理 | pandas | 大量データのバリデーション・変換に強い |
| CLI | click or typer | コマンド体系の構築が楽 |
| 設定 | YAML (PyYAML) | テーブル定義の外部化 |
| テスト | pytest + testcontainers | PostgreSQLコンテナで統合テスト |

### ディレクトリ構成

```
ansem-import/
├── pyproject.toml
├── src/
│   └── ansem_import/
│       ├── __init__.py
│       ├── cli.py              # CLIエントリポイント
│       ├── config.py           # YAML設定読み込み
│       ├── validator.py        # バリデーションエンジン
│       ├── transformer.py      # ID変換・正規化
│       ├── duplicate_checker.py # 重複検出
│       ├── loader.py           # DB投入（DRY RUN/本番）
│       └── reporter.py         # エラーレポート生成
├── tables/                     # テーブル定義YAML
│   ├── influencers.yaml
│   ├── partners.yaml
│   ├── clients.yaml
│   └── ...
├── tests/
│   ├── conftest.py             # DB fixture
│   ├── test_validator.py
│   ├── test_transformer.py
│   └── test_loader.py
└── README.md
```

### 実装順序

#### Step 1: 基盤（CLI + 設定 + バリデーション）

```
ansem-import --table influencers --file data.csv --dry-run
```

1. cli.py: click/typerでコマンド定義
2. config.py: YAML設定ファイルの読み込み・バリデーション
3. validator.py: 必須チェック、形式チェック、ドロップダウン値チェック
4. reporter.py: バリデーションNG行のCSV/テーブル出力

#### Step 2: 変換＋投入

1. transformer.py: 名前→ID変換（m_agents, m_categories, m_departments参照）
2. duplicate_checker.py: 名前完全一致、メール重複、SNS URL重複
3. loader.py: DRY RUNモード（SQL出力）、本番モード（トランザクション投入）

#### Step 3: 拡張

1. --skip-errors オプション（エラー行スキップ）
2. --report out.csv（エラーレポートCSV出力）
3. ingestion_logs への実行記録保存
4. 他テーブル対応（partners, clients, ad_contents等）

### テーブル定義YAML（influencers.yaml 例）

```yaml
table: m_influencers
display_name: インフルエンサー
columns:
  - csv: マスター名
    db: influencer_name
    required: true
  - csv: 区分
    db: affiliation_type_id
    type: dropdown
    mapping:
      事務所所属: 1
      フリーランス: 2
      企業専属: 3
  - csv: コンプラチェック
    db: compliance_check
    type: boolean
    mapping:
      "○": true
      "×": false
  - csv: メールアドレス
    db: email_address
    format: email
  - csv: 所属名(正式名称)
    db: affiliation_name

related_tables:
  - table: t_influencer_sns_accounts
    columns:
      - csv: Instagram
        db: account_url
        extra: { platform_id: 1 }
      - csv: YouTube
        db: account_url
        extra: { platform_id: 2 }
      - csv: Twitter/X
        db: account_url
        extra: { platform_id: 3 }
      - csv: TikTok
        db: account_url
        extra: { platform_id: 4 }
  - table: t_bank_accounts
    columns:
      - csv: 銀行名
        db: bank_name
      - csv: 支店名
        db: branch_name
      - csv: 口座種別
        db: account_type
        type: dropdown
        mapping:
          普通: 1
          当座: 2
          貯蓄: 3
      - csv: 口座番号
        db: account_number
        format: "digits:7"
      - csv: 口座名義
        db: account_holder_name
```

---

## 2. BQ自動取り込み

BigQueryの日次集計データをPostgreSQLに取り込むパイプライン。

### アーキテクチャ

```
Cloud Scheduler（毎日AM 6:00）
    ↓ トリガー
Cloud Functions / Cloud Run Jobs
    ↓
BigQuery API（前日分データ取得）
    ↓
PostgreSQL（t_daily_performance_details, t_daily_click_details）
    ↓
ingestion_logs に実行結果記録
    ↓
Slack通知（成功/失敗）
```

### 技術選定

| 要素 | 選定 | 理由 |
|------|------|------|
| 実行環境 | Cloud Run Jobs | コンテナベース、スケジュール実行、コスト効率 |
| BQ接続 | google-cloud-bigquery (Python) | 公式SDK |
| DB接続 | psycopg 3 | ansem-importと共通 |
| スケジューラ | Cloud Scheduler | GCP標準、cron式 |
| 監視 | Cloud Monitoring + Slack | 失敗時の即座通知 |

### 取り込みフロー

1. 前日分のデータをBQから取得（WHERE action_date = CURRENT_DATE - 1）
2. パートナー名・サイト名をスナップショットとして非正規化
3. UPSERT（ON CONFLICT DO UPDATE）で冪等性を担保
4. ingestion_logs にジョブ結果を記録（rows_affected, error_count等）
5. 失敗時はリトライ（最大3回、exponential backoff）

### 冪等性の確保

```sql
INSERT INTO t_daily_performance_details (action_date, partner_id, site_id, ...)
VALUES ($1, $2, $3, ...)
ON CONFLICT (action_date, partner_id, site_id, content_id, client_id)
DO UPDATE SET
  cv_count = EXCLUDED.cv_count,
  updated_at = CURRENT_TIMESTAMP;
```

同じ日のデータを再取り込みしても壊れない。障害復旧時の再実行が安全にできる。

---

## 3. 確認画面（DRY RUN）

### CLIでの実装（Phase 1）

ansem-importの`--dry-run`オプションがこの役割を担う。

```
$ ansem-import --table influencers --file data.csv --dry-run

╔══════════════════════════════════════╗
║  DRY RUN 結果                        ║
╠══════════════════════════════════════╣
║  対象テーブル: m_influencers          ║
║  新規登録: 45件                       ║
║  バリデーションエラー: 3件             ║
║  重複候補: 2件                        ║
╚══════════════════════════════════════╝

⚠️ バリデーションエラー:
  行3: メールアドレス形式不正 (abc@)
  行15: 必須項目「マスター名」が空
  行22: 口座番号が7桁でない (12345)

⚠️ 重複候補:
  行7: 「田中花子」→ 既存ID=1234 と名前一致
  行31: メール「test@example.com」→ 既存ID=5678 と一致

続行しますか？ [y/N]
```

### WebUI化（Phase 3で対応）

Phase 1のCLIロジックをAPI化し、画面から呼び出す。ロジックの再実装は不要。

---

## 4. 検索・フィルタリング

### 最小実装（Phase 1）

CLIツールまたはシンプルなWebUI（Streamlit or Retool）で:

| 検索対象 | 方式 |
|---------|------|
| IF名 | ILIKE '%keyword%' |
| ステータス | status_id = ? |
| 担当エージェント | agent_id = ? |
| 日付範囲 | created_at BETWEEN ? AND ? |

### 将来の拡張（Phase 2以降）

- 全文検索（pg_trgm拡張）
- ファセット検索
- ソート・ページネーション
- 保存済み検索条件

---

## 環境構築

### 開発環境

| 要素 | ツール |
|------|--------|
| PostgreSQL | Docker（postgres:16-alpine） |
| Python | 3.12+、venv or uv |
| DDL適用 | 001〜005のSQLファイルを順番に実行 |
| シードデータ | m_countries, m_departments等の固定マスタ |

### 初期セットアップ手順

```bash
# 1. PostgreSQLコンテナ起動
docker run -d --name ansem-db \
  -e POSTGRES_DB=ansem \
  -e POSTGRES_USER=ansem_admin \
  -e POSTGRES_PASSWORD=<secure> \
  -p 5432:5432 \
  postgres:16-alpine

# 2. DDL適用（FK依存順）
for f in sql/001_create_tables.sql \
         sql/002_create_indexes.sql \
         sql/003_create_comments.sql \
         sql/004_create_triggers.sql \
         sql/005_create_partitions.sql; do
  psql -h localhost -U ansem_admin -d ansem -f "$f"
done

# 3. シードデータ投入
psql -h localhost -U ansem_admin -d ansem -f sql/seed/master_data.sql

# 4. ansem-import セットアップ
cd ansem-import
python -m venv .venv && source .venv/bin/activate
pip install -e ".[dev]"
```

---

## マイルストーン

### M1: ansem-import MVP
- CLIの基本構造（click/typer）
- influencers.yamlの設定ファイル
- バリデーション（必須、形式、ドロップダウン）
- DRY RUNモード（SQL出力）
- 本番モード（DB投入）

### M2: 重複チェック＋エラーレポート
- 名前完全一致チェック
- メール・SNS URL重複チェック
- エラーレポートCSV出力
- ingestion_logs記録

### M3: BQ取り込みパイプライン
- BQ APIクライアント
- 差分取り込み（前日分）
- UPSERT（冪等）
- ingestion_logs記録
- Cloud Run Jobs設定

### M4: 検索・フィルタリング
- CLI検索コマンド or Streamlit画面
- 基本検索（名前、ステータス、担当者、日付範囲）
- 結果表示（ページネーション）

---

## リスクと対策

| リスク | 影響 | 対策 |
|--------|------|------|
| 既存スプシのデータ品質 | バリデーションエラー大量発生 | --skip-errorsで段階的投入、エラーレポートで手動修正 |
| BQ側のスキーマ変更 | パイプライン破壊 | スキーマバージョニング、アラート設定 |
| 同時投入の競合 | データ不整合 | トランザクション管理、楽観ロック |
| パフォーマンス（大量データ） | 投入時間増大 | バルクINSERT（COPY）、バッチ処理 |

---

_作成: 2026-02-15_
_ステータス: ドラフト_
