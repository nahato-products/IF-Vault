---
tags: [ANSEM, NotebookLM, feed]
created: 2026-02-15
purpose: NotebookLMにアップロードして質疑応答やポッドキャスト生成に使う統合ドキュメント
---

# ANSEM プロジェクト完全ガイド

このドキュメントはANSEMプロジェクトの全情報を1ファイルにまとめたもの。NotebookLMやAIツールへのフィード用に最適化している。

---

## 1. プロジェクト概要

ANSEMはnahato Inc.のインフルエンサーマーケティング管理をスプレッドシートからPostgreSQLに移行するプロジェクト。数百名のインフルエンサー情報・成果データ・請求業務をシステム化する。

現状はGoogleスプレッドシートで管理。45個以上の関数で「調理」と呼ばれる加工工程（0A〜0Fシート）を経て請求データを作っている。名前の表記揺れ、重複データ、引き継ぎ困難が課題。

DB設計は v5.4.0 で完了。32テーブル構成、DDL全5ファイルが実行可能な状態。Phase 1の実装に入る段階。

---

## 2. データベース構成（32テーブル）

### マスタテーブル（15テーブル）

| テーブル | 説明 |
|---------|------|
| m_countries | 国マスタ（ISO準拠） |
| m_departments | 部署マスタ（階層構造、parent_idで自己参照） |
| m_categories | カテゴリマスタ（2階層） |
| m_agents | エージェント（社員） |
| m_agent_role_types | エージェント役割（メイン担当、サブ担当、スカウト等） |
| m_agent_security | エージェント認証（パスワードハッシュ、セッション） |
| m_influencers | インフルエンサー（中心エンティティ） |
| m_influencer_security | IF認証情報 |
| m_ad_groups | 広告グループ（案件単位） |
| m_clients | クライアント（広告主） |
| m_ad_contents | 広告コンテンツ（クリエイティブ） |
| m_partners | パートナー（ASP、配信媒体） |
| m_partners_division | パートナー区分（IF卸 / トータルマーケ） |
| m_sns_platforms | SNSプラットフォーム（Instagram, YouTube等） |
| m_campaigns | キャンペーン（加工用パラメータ） |

### トランザクションテーブル（16テーブル）

| テーブル | 説明 |
|---------|------|
| t_partner_sites | パートナーサイト |
| t_influencer_sns_accounts | SNSアカウント（複数登録対応） |
| t_account_categories | アカウント×カテゴリ（多対多） |
| t_addresses | 住所（国内・海外対応） |
| t_bank_accounts | 銀行口座（通貨別管理） |
| t_billing_info | 請求先（インボイス制度対応） |
| t_unit_prices | 単価設定（期間管理、楽観ロック） |
| t_influencer_agent_assignments | 担当割当（履歴管理） |
| t_notifications | 通知 |
| t_translations | 翻訳（多言語対応） |
| t_files | ファイル管理（S3/GCS連携） |
| t_audit_logs | 監査ログ（JSONB、月次パーティション） |
| t_daily_performance_details | 日次CV集計（年次パーティション） |
| t_daily_click_details | 日次クリック集計（年次パーティション） |
| t_billing_runs | 請求確定バッチ（論理削除方式） |
| t_billing_line_items | 請求明細（確定済みスナップショット） |

### システムテーブル

| テーブル | 説明 |
|---------|------|
| ingestion_logs | BigQuery取り込みログ |

---

## 3. 設計上の重要な決定事項

### データ型ルール
- 文字列は全て TEXT。VARCHAR は使わない。PostgreSQLではTEXTとVARCHARに性能差がない
- 日時は全て TIMESTAMPTZ。タイムゾーンなしのTIMESTAMPは使わない
- IDは BIGINT GENERATED ALWAYS AS IDENTITY が原則。小マスタ（国、役割等）のみSMALLINT手動採番
- 金額は DECIMAL(12, 0)。浮動小数点は誤差があるので使わない
- BOOLEANは必ず NOT NULL + DEFAULT。is_プレフィックスで統一

### FK削除ポリシー（3パターン）
- RESTRICT（デフォルト）: 子データに独立した価値がある場合。集計テーブル、単価、SNSアカウント
- CASCADE: 親と運命を共にする子。住所、口座、請求先、1対1セキュリティテーブル
- SET NULL: 任意の参照を切る場合。パートナー→IF兼業、IF→国

### 監査カラム
全テーブルに created_by, updated_by, created_at, updated_at の4カラムを必須にしている。updated_atはトリガーで自動更新。例外は監査ログ自体とシステムジョブログ。

### 楽観ロック
同時編集が起きうるテーブル（m_influencers, m_campaigns, t_unit_prices）にversionカラムを追加。UPDATE時にWHERE version = ? で競合を検出する。

### パーティション
- 日次集計テーブル: RANGE(action_date) で年次分割
- 監査ログ: 月次分割
- 3年超のデータはDETACH PARTITIONでアーカイブ

### スナップショット方式
集計テーブルにマスタの名前を非正規化で保存。パートナー名やサイト名が後から変わっても過去の集計が壊れない。FKでID整合性を担保しつつ、表示名はスナップショットで固定する。

### 請求確定フロー
t_billing_runsで請求確定バッチを管理。filter_conditions（JSONB）で確定条件を保存し、t_billing_line_itemsにスナップショットとして明細を保存。is_cancelledで論理削除に対応。

---

## 4. SQLファイル構成（DDL）

| ファイル | 内容 |
|---------|------|
| 001_create_tables.sql | 32テーブル作成（FK依存順） |
| 002_create_indexes.sql | インデックス作成 |
| 003_create_comments.sql | テーブル・カラムコメント |
| 004_create_triggers.sql | 30トリガー + updated_at自動更新関数 |
| 005_create_partitions.sql | パーティション作成 |

FK依存順でテーブルを作成するため、参照先のテーブルが先に来る。

---

## 5. Phase 1 実装計画

### ansem-import CLIツール（最優先）

スプシCSVからDBにデータを一括投入するPython CLIツール。初回データ移行だけでなく、月次・案件開始時の継続的な投入に使う。

技術スタック: Python 3.12+, psycopg 3, pandas, click, PyYAML
テーブル定義はYAMLで外部化し、新しいテーブルの対応はYAMLファイル追加だけで済む。

主な機能: バリデーション、名前→ID変換、重複チェック、DRY RUNモード（SQL出力のみ）、エラーレポート生成。

### BQ自動取り込み

BigQueryの日次集計データをPostgreSQLに取り込むパイプライン。Cloud Run Jobs + Cloud Schedulerで毎日AM 6:00に実行。UPSERTで冪等性を担保し、障害復旧時の再実行が安全にできる。

### Moltbot連携

LINEボット（Moltbot）からインフルエンサー情報を検索・登録する。REST APIを6エンドポイント構築し、サービス間認証（API Key）で接続する。

---

## 6. 命名規則

- テーブル: m_（マスタ）/ t_（トランザクション）プレフィックス、全てスネークケース
- PK: {entity}_id（例: influencer_id, partner_id）
- FK: 参照先と同名のカラム名を使用
- インデックス: idx_{table}_{column}
- FK制約: fk_{table}_{referenced_table}
- トリガー: trg_{table}_{purpose}

---

## 7. 要件変更ログ（会議メモから）

1. 請求書テンプレートの統一 → t_billing_infoに法人名・担当者名を追加
2. パートナーがIF経営を兼ねるケース → m_partnersからm_influencersへの任意参照
3. 単価管理の期間対応 → t_unit_pricesにstart_at/end_atを追加
4. 海外IF対応 → t_bank_accountsに通貨、t_addressesに国コード
5. パートナーID重複問題 → m_partnersにexternal_partner_id（外部ID）
6. 広告コンテンツのPK → content_id（FK参照との一致のため）

---

## 8. 追加機能ロードマップ

| フェーズ | 内容 |
|---------|------|
| Phase 1（初期構築） | BQ取り込み、ansem-import CLI、DRY RUN確認、検索機能 |
| Phase 2（MVP） | 請求確定フロー、CSVエクスポート、ダッシュボード |
| Phase 3（運用改善） | 単価管理UI、担当者管理、通知、WebUI化 |
| Phase 4（拡張） | RBAC+RLS、監査ログ閲覧、ファイル管理、多言語 |

---

## 9. セキュリティ設計

- 認証情報は分離テーブル（m_agent_security, m_influencer_security）
- パスワードはハッシュ化して格納（password_hash TEXT）
- セッション管理: session_token + session_expires_at
- 監査ログ: t_audit_logsに全操作をJSONBで記録
- RBAC: ansem_app / ansem_readonly / ansem_admin の3ロール（Phase 4で実装予定）
- RLS: m_influencersの担当エージェント別アクセス制御（Phase 4）

---

## 10. スケーリング戦略

- 接続プーリング: PgBouncerでトランザクションプーリング
- リードレプリカ: ダッシュボード・検索・レポートを読み取りレプリカに分散
- パーティション: 日次集計は年次、監査ログは月次で分割
- アーカイブ: 3年超のデータはDETACH PARTITIONでコールドストレージに

---

_ANSEM プロジェクト完全ガイド（NotebookLM用）_
_生成日: 2026-02-15_
_バージョン: v5.4.0_
