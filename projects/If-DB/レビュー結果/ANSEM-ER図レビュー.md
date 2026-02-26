---
tags: [ANSEM, database, design, review]
created: 2026-02-06
updated: 2026-02-10
status: completed
related: "[[ANSEM-ER図]], [[ANSEM-ER図（ビジュアル版）]]"
---

# ANSEM DB設計書 レビュー結果

## レビュー概要

- **対象**: [[ANSEM-ER図|ANSEMプロジェクト データベース設計書]]
- **初回レビュー日**: 2026-02-06（v1.0.0対象）
- **v2.0.0 対応確認日**: 2026-02-09
- **v3.0.0 対応確認日**: 2026-02-10
- **v4.0.0 対応確認日**: 2026-02-10
- **v5.0.0 対応確認日**: 2026-02-10
- **v5.1.0 対応確認日**: 2026-02-10
- **レビュー観点**: 設計一貫性・命名規則・実装可能性・スケーラビリティ・リレーション整合性

---

## 良い点

- **設計方針が明文化されている**: TEXT統一・TIMESTAMPTZ統一・監査カラム必須など、ルールが明確。例外も全て明記
- **堅牢なFK設計**: ON DELETE RESTRICT原則、CASCADE/SET NULLの使い分けルールが明文化済み
- **パーティション戦略**: 集計テーブルの年次パーティション＋audit_logsの月単位パーティション方針
- **スケーリング方針**: PgBouncer、リードレプリカ、アーカイブ戦略が運用ガイドラインに明記
- **階層構造の設計**: カテゴリ・部署の親子構造がシンプルで拡張性が高い
- **認証情報の分離**: セキュリティテーブルを1対1で分離しておりセキュリティ的に正しい
- **汎用パターンの統一**: t_notifications, t_translations, t_files がポリモーフィック/汎用テーブル方式で一貫
- **スプシDDLとの整合**: v3.0で大規模アライメントを実施し、実運用に即した構造
- **初期データ・サンプルクエリの充実**: 実用的で、導入時の参考になる

---

## 指摘事項（v1.0〜v2.0 からの継続分）

### 1. ~~[重要] m_/t_ プレフィックスの分類が不統一~~ → 対応済み (v2.0)

> [!TIP]
> **v2.0で全テーブルのプレフィックスを修正済み。**

| テーブル | v1.0 | v2.0 | 対応 |
| --- | --- | --- | --- |
| 住所情報 | `m_addresses` | `t_addresses` | 修正済み |
| 銀行口座 | `m_bank_accounts` | `t_bank_accounts` | 修正済み |
| 請求先情報 | `m_billing_info` | `t_billing_info` | 修正済み |
| SNSアカウント | `m_influencer_sns_accounts` | `t_influencer_sns_accounts` | 修正済み |
| 担当割当 | `m_influencer_agent_assignments` | `t_influencer_agent_assignments` | 修正済み |
| アカウント×カテゴリ | `m_account_categories` | `t_account_categories` | 修正済み |
| 監査ログ | `m_audit_logs` | `t_audit_logs` | 修正済み |
| インフルエンサー | `t_influencers` | `m_influencers` | 修正済み |
| パートナー | `t_partners` | `m_partners` | 修正済み |
| キャンペーン | `t_campaigns` | `m_campaigns` | 修正済み |

---

### 2. ~~[重要] ER図のリレーションに誤りがある~~ → 対応済み (v2.0)

> [!TIP]
> **v2.0で修正済み。** `m_agent_role_types` は `t_influencer_agent_assignments` 経由のリレーションに修正。

---

### 3. ~~[重要] updated_at の自動更新トリガーが未定義~~ → 対応済み (v4.0)

> [!TIP]
> **v4.0で対応済み。** 共通関数 `update_updated_at()` と全テーブル（例外: t_audit_logs, ingestion_logs）へのCREATE TRIGGER文を「共通トリガー・ファンクション」セクションに追加。

---

### 4. ~~[中] カラム命名の不統一~~ → 対応済み (v3.0)

> [!TIP]
> **v3.0で対応済み。** `country_type_id` → `country_id` にリネーム（t_addresses, t_bank_accounts）。
> FK参照先 `m_countries.country_id` と名称が一致するようになった。

---

### 5. ~~[中] 自己ルール違反: 監査カラム~~ → 対応済み (v2.0 + v3.0)

> [!TIP]
> **v2.0で対応済み、v3.0で追加。** 設計方針に例外を明記。
> - **`t_audit_logs`** — 監査ログ自体が監査の記録のため、`operator_id` / `operated_at` で代替
> - **`ingestion_logs`** — システムジョブの実行ログのため、`started_at` / `finished_at` で代替
> - **`m_partners_division`** — BQ/ASP外部ID一致用。一括インポートのため `created_by` / `updated_by` 不要（v3.0追加）

---

### 6. ~~[中] 自己ルール違反: 主キーのID生成~~ → 対応済み (v2.0 + v3.0)

> [!TIP]
> **v2.0で対応済み、v3.0で追加。** 設計方針とチェックリストに例外ルールを明記。
> - **例外①**: マスタ系で件数が少なく値が固定的なもの（`m_countries`, `m_agent_role_types`）→ SMALLINT手動採番
> - **例外②**: 1対1リレーションのセキュリティテーブル（`m_agent_security`, `m_influencer_security`）→ 親テーブルのIDをPK/FKとして使用
> - **例外③**: 外部システムID一致テーブル（`m_partners_division`）→ BQ/ASPのIDと一致させるため手動PK（v3.0追加）

---

### 7. ~~[中] ソフトデリートの方針が不統一~~ → 改善済み (v3.0)

> [!TIP]
> **v3.0で大幅改善。** 主要テーブルから `is_active` を廃止し、`status_id` に統一。
> - `m_influencers`: `is_active` → `status_id SMALLINT NOT NULL DEFAULT 1`
> - `m_agents`: 同上
> - `m_partners`: 同上
> - `m_clients`: 同上
>
> 削除表現は `status_id` パターンに一本化された。

残存する `is_active` / `is_primary`:
- `t_billing_info.is_active` — 請求先の有効/無効（ソフトデリートではなく業務フラグ）
- `t_billing_info.is_primary` — 主たる請求先フラグ

> [!NOTE]
> これらは「ソフトデリート」ではなく「業務ステータスフラグ」として妥当。方針不統一は解消済みと判断。

---

### 8. ~~[中] 排他制御・楽観ロックの仕組みがない~~ → 対応済み (v4.0)

> [!TIP]
> **v4.0で対応済み。** 競合が起きやすい3テーブルに `version INTEGER NOT NULL DEFAULT 1` を追加。
> - `m_influencers` — プロフィール編集
> - `m_campaigns` — ステータス更新
> - `t_unit_prices` — 単価変更

---

### 9. ~~[低] password_salt カラムの必要性~~ → 対応済み (v3.0)

> [!TIP]
> **v3.0で対応済み。** `m_agent_security` と `m_influencer_security` から `password_salt` カラムを削除。
> bcrypt/argon2 等の現代的ハッシュアルゴリズムはソルトをハッシュ値に内包するため、別カラム不要。
> また `last_login_at` / `last_login_ip` も削除され、セキュリティテーブルが簡素化された。

---

### 10. ~~[低] スケーリング観点の欠如~~ → 対応済み (v5.0)

> [!TIP]
> **v5.0で対応済み。** 運用ガイドラインに「スケーリング方針」セクションを追加。
> - コネクションプーリング（PgBouncer推奨設定）
> - リードレプリカ（参照系クエリの負荷分散方針）
> - t_audit_logs の月単位パーティション化
> - データアーカイブ戦略（テーブル別の保持期間・アーカイブ先）

---

## v3.0 新規指摘事項

### 18. ~~[高] ON DELETE CASCADE / RESTRICT の矛盾~~ → 対応済み (v4.0)

> [!TIP]
> **v4.0で対応済み。** `t_billing_info` から `billing_address_id` カラムを削除し、FK参照の矛盾を解消。
> 加えて、設計方針「4. 外部キー制約」にON DELETE使い分けルール（CASCADE/RESTRICT/SET NULL）を明文化。

---

### 19. ~~[中] m_partners.login_id に NOT NULL 制約がない~~ → 対応済み (v4.0)

> [!TIP]
> **v4.0で対応済み。** パートナーはこのプロジェクトのログイン対象外のため、`login_id` カラム自体を削除。

---

### 20. ~~[中] assigned_at / unassigned_at が DATE 型~~ → 対応済み (v4.0)

> [!TIP]
> **v4.0で対応済み。** `assigned_at` / `unassigned_at` を `DATE` → `TIMESTAMPTZ` に変更。設計方針の日時型統一ルールに準拠。

---

### 21. ~~[中] COMMENT 値定義の不足~~ → 対応済み (v4.0)

> [!TIP]
> **v4.0で対応済み。** 以下のCOMMENTに辞書値を追記:
> - `affiliation_type_id`: 1: 事務所所属, 2: フリーランス, 3: 企業専属
> - `billing_type_id`: 1: 固定報酬, 2: 成果報酬, 3: 予算型
> - `purchase_order_status_id`: 1: 未発行, 2: 発行済, 3: 承認済, 9: 取消
> - `delivery_status_id`: 1: 承認待ち, 2: 配信中, 3: 停止
> - `is_itp_param_status_id`: 0: 未設定, 1: 設定済

---

### 22. ~~[中] ON DELETE 使い分けルールが設計方針に未明文化~~ → 対応済み (v4.0)

> [!TIP]
> **v4.0で対応済み。** 設計方針「4. 外部キー制約」に「ON DELETE 使い分けルール」テーブルを追加。
> RESTRICT/CASCADE/SET NULL の使用基準と対象テーブルを明記。

---

### 23. ~~[低] t_influencer_sns_accounts の ON DELETE が他と不統一~~ → 対応済み (v4.0)

> [!TIP]
> **v4.0で対応済み。** 設計方針の「ON DELETE 使い分けルール」NOTE欄に意図を明記。
> SNSアカウント・担当割当がRESTRICTなのは、キャンペーン実績や集計データとの紐付きがあり、安易な連動削除はデータ損失リスクがあるため。

---

## 拡張性評価

### 拡張しやすいところ

#### マスタデータの追加（評価: 高い）

カテゴリ・部署は自己参照の階層構造で、2階層→3階層以上にもコード変更なしで対応可能。
SNSプラットフォーム（`m_sns_platforms`）や国（`m_countries`）も、INSERTだけで新規追加できる。

#### データ量の増加（評価: 高い）

集計テーブルが年次パーティション対応済み。
監査ログのJSONBカラムも、テーブル構造が変わってもスキーマ変更不要で柔軟。

---

### 拡張しにくいところ

#### 11. ~~[重要] ユーザー種別の拡張に弱い~~ → 対象外 (v4.0)

> [!TIP]
> **クローズ。** クライアント・パートナーはログイン対象外のため、現状のエージェント+IF の2種別で十分。認証テーブルの統合は不要。

---

#### 12. ~~[重要] 住所・口座がインフルエンサー専用~~ → 対象外 (v4.0)

> [!TIP]
> **クローズ。** エージェントやパートナーの住所・口座管理は業務上不要。IF専用で問題なし。

---

#### 13. ~~[中] 単価設定の柔軟性が低い~~ → 対象外 (v4.0)

> [!TIP]
> **クローズ。** `site_id` はインフルエンサーごとに付与されるため、IF別単価は実質的に対応済み。現状の構造で運用上の問題なし。

---

#### 14. ~~[中] キャンペーン構造が単純すぎる~~ → 対象外 (v4.0)

> [!TIP]
> **クローズ。** `t_unit_prices` に有効期間（`start_at` / `end_at`）があり、期間ごとの単価管理は対応済み。
> フライト・予算配分・KPI管理は現行スコープ外。必要になった時点で中間テーブル追加で対応可能。

---

#### 15. ~~[中] 多言語対応ができない~~ → 対応済み (v5.0)

> [!TIP]
> **v5.0で対応済み。** `t_translations` テーブルを新設。
> 翻訳テーブル方式を採用し、既存カラムを変更せず後付けで多言語対応可能。
> table_name + record_id + column_name + language_code のユニーク制約で管理。

---

#### 16. ~~[低] ファイル・メディア管理がない~~ → 対応済み (v5.0)

> [!TIP]
> **v5.0で対応済み。** `t_files` テーブルを新設。
> ポリモーフィックパターン（entity_type + entity_id）で任意エンティティにファイルを紐付け。
> 実ファイルはオブジェクトストレージ（S3/GCS）保存、DBにはメタデータのみ格納。

---

#### 17. ~~[低] 通知・メッセージ機能がない~~ → 対応済み (v4.0)

> [!TIP]
> **v4.0で対応済み。** `t_notifications` テーブルを新設。
> user_type で通知先種別（Agent/Influencer/Partner）を管理し、notification_type で通知カテゴリを分類。

---

### 拡張性の総合評価

| 観点 | 評価 | 理由 |
|------|------|------|
| マスタデータの追加 | 高い | INSERTで対応可能な構造 |
| ユーザー種別 | **十分** | Agent+IFの2種別で運用要件を満たす |
| 住所・口座 | **十分** | IF専用で業務上問題なし |
| 単価設定 | **十分** | site_id=IF単位、有効期間管理あり |
| キャンペーン | **十分** | 現行スコープで対応済み |
| 多言語対応 | **対応済み** | v5.0で `t_translations` 追加 |
| データ量の増加 | 高い | パーティション対応済み |
| ファイル管理 | **対応済み** | v5.0で `t_files` 追加 |
| 通知・メッセージ | **対応済み** | v4.0で `t_notifications` 追加 |

---

## 総評

### 全バージョン対応状況サマリ

#### v1.0〜v2.0 指摘（#1〜#17）

| #   | 指摘事項                      | 重要度 | v2.0     | v3.0        | v4.0        | v5.0        |
| --- | ------------------------- | --- | -------- | ----------- | ----------- | ----------- |
| 1   | m_/t_ プレフィックス不統一          | 重要  | ~~対応済み~~ | -           | -           | -           |
| 2   | ER図リレーション誤り               | 重要  | ~~対応済み~~ | -           | -           | -           |
| 3   | updated_at 自動更新トリガー未定義    | 重要  | 未対応      | 未対応         | ~~対応済み~~    | -           |
| 4   | カラム命名不統一（country_type_id） | 中   | 未対応      | ~~対応済み~~    | -           | -           |
| 5   | 監査カラムルール違反                | 中   | ~~対応済み~~ | ~~例外③追加~~   | -           | -           |
| 6   | 主キーID生成ルール違反              | 中   | ~~対応済み~~ | ~~例外③追加~~   | -           | -           |
| 7   | ソフトデリート方針不統一              | 中   | 未対応      | ~~改善済み~~    | -           | -           |
| 8   | 楽観ロック未実装                  | 中   | 未対応      | 未対応         | ~~対応済み~~    | -           |
| 9   | password_salt の必要性        | 低   | 未対応      | ~~対応済み~~    | -           | -           |
| 10  | スケーリング観点の欠如               | 低   | 未対応      | 未対応         | 保留          | ~~対応済み~~    |
| 11  | ユーザー種別の拡張性                | 重要  | 未対応      | 未対応         | ~~対象外~~     | -           |
| 12  | 住所・口座がIF専用                | 重要  | 未対応      | 未対応         | ~~対象外~~     | -           |
| 13  | 単価設定の柔軟性                  | 中   | 未対応      | 未対応         | ~~対象外~~     | -           |
| 14  | キャンペーン構造                  | 中   | 部分対応     | 部分対応        | ~~対象外~~     | -           |
| 15  | 多言語対応                     | 中   | 未対応      | 未対応         | 保留          | ~~対応済み~~    |
| 16  | ファイル・メディア管理               | 低   | 未対応      | 未対応         | 保留          | ~~対応済み~~    |
| 17  | 通知・メッセージ機能                | 低   | 未対応      | 未対応         | ~~対応済み~~    | -           |

#### v3.0 新規指摘（#18〜#23）

| #   | 指摘事項                         | 重要度 | v3.0  | v4.0       |
| --- | ---------------------------- | --- | ----- | ---------- |
| 18  | ON DELETE CASCADE/RESTRICT 矛盾 | 高   | 要対応   | ~~対応済み~~   |
| 19  | m_partners.login_id NOT NULL欠如 | 中   | 要確認   | ~~対応済み~~   |
| 20  | assigned_at DATE型             | 中   | 要確認   | ~~対応済み~~   |
| 21  | COMMENT値定義の不足                | 中   | 要対応   | ~~対応済み~~   |
| 22  | ON DELETE使い分けルール未明文化         | 中   | 要対応   | ~~対応済み~~   |
| 23  | SNSアカウントのON DELETE不統一        | 低   | 要確認   | ~~対応済み~~   |

**v5.0 対応率: 23/23 (100%)**
- 対応済み/対象外: 23件
- 保留: 0件
- 未対応: 0件

### 評価

| 観点 | v1.0 | v2.0 | v3.0 | v4.0 | v5.0 | 変化 |
|------|------|------|------|------|------|------|
| 体裁・網羅性 | 高い | 高い | 高い | 非常に高い | **非常に高い** | 維持（30テーブル、スケーリング方針追加） |
| 設計方針の明確さ | 高い | 高い | 非常に高い | 非常に高い | **非常に高い** | 維持 |
| ルールとの一貫性 | **低い** | **中** | **高い** | 非常に高い | **非常に高い** | 維持 |
| 命名の統一性 | 中 | 中 | **高い** | 高い | **高い** | 維持 |
| 実装可能性 | 中 | 中 | 中 | 高い | **非常に高い** | 改善（スケーリング方針追加） |
| スプシDDLとの整合性 | - | - | **高い** | 高い | **高い** | 維持 |
| 拡張性 | 中〜低 | **中** | **中** | 高い | **非常に高い** | 改善（多言語・ファイル管理追加） |
| スケーラビリティ | 低 | 低 | 低 | 低 | **高い** | 改善（スケーリング方針・アーカイブ戦略追加） |

### v4.0 総合所見

v4.0で**v3.0レビュー指摘の全件対応**を実施し、設計書の完成度が大幅に向上。

**主な改善点:**

1. **実装準備完了**: `updated_at` 自動更新トリガーを全テーブルに定義
2. **楽観ロック対応**: `m_influencers`, `m_campaigns`, `t_unit_prices` に `version` カラム追加
3. **ON DELETE ルール明文化**: 設計方針にCASCADE/RESTRICT/SET NULLの使い分けを追記
4. **COMMENT値定義の充実**: 辞書値をCOMMENTに明記（一部暫定値あり）
5. **不要カラム削除**: `billing_address_id`（t_billing_info）、`login_id`（m_partners）
6. **TIMESTAMPTZ統一**: `assigned_at`/`unassigned_at` をDATE→TIMESTAMPTZに変更
7. **通知テーブル新設**: `t_notifications`（28テーブル目）

### v5.0 総合所見

v5.0で**全23件の指摘を100%完了**。保留項目ゼロを達成。

**主な改善点:**

1. **スケーリング方針の明文化**: コネクションプーリング（PgBouncer）、リードレプリカ、t_audit_logsの月単位パーティション化、データアーカイブ戦略を運用ガイドラインに追加
2. **多言語対応**: `t_translations` テーブル新設。翻訳テーブル方式で既存カラムに影響なく多言語対応可能
3. **ファイル管理**: `t_files` テーブル新設。ポリモーフィックパターンで任意エンティティにファイルメタデータを紐付け

> [!NOTE]
> **全指摘対応率 100%（23/23）** を達成。v5.1でさらにコンテンツレビュー指摘にも全件対応。

### v5.1 総合所見

v5.1で**コンテンツ・リレーション深層レビューの全件対応**を実施。

**主な改善点:**

1. **データ整合性強化**: 初期データ投入順序のFK違反修正、冗長インデックス削除
2. **リレーション補完**: m_partners_division → m_partners のFK追加
3. **監査ログ拡張**: t_audit_logs をポリモーフィック化し、Agent/IF両方の操作を記録可能に（IFマイページ対応）
4. **セキュリティテーブル統一**: m_agent_security / m_influencer_security のカラム差異を解消
5. **命名・型統一**: display_order 型統一、entity_type 番号統一
6. **ON DELETE 安全化**: fk_campaign_site を CASCADE → RESTRICT に変更

> [!NOTE]
> **コンテンツレビュー: 修正 10件 / 対象外 3件 / 全件対応完了。** 設計書として完成。

---

## v5.0 レビュー指摘事項

v5.0の追加内容に対する品質レビュー結果。

### V5-1. ~~[高] m_agent_security のCOMMENTに削除済みカラム参照~~ → 修正済み

> [!TIP]
> **即時修正済み。** `last_login_ip` のCOMMENT ON文を削除。DDLにカラムが存在しないのにCOMMENTだけ残っていた。

---

### V5-2. ~~[中] m_campaigns.fk_campaign_site の ON DELETE CASCADE~~ → 修正済み (v5.1)

> [!TIP]
> **v5.1で修正済み。** `fk_campaign_site` を `ON DELETE CASCADE` → `ON DELETE RESTRICT` に変更。パートナーサイト削除時にキャンペーンが連動削除されるリスクを排除。

---

### V5-3. ~~[低] t_notifications がテキスト図に未記載~~ → 修正済み

> [!TIP]
> **即時修正済み。** テーブル間リレーション概要のテキスト図に t_notifications を追記。

---

### V5-4. ~~[低] セキュリティテーブル間のカラム差異~~ → 修正済み (v5.1)

> [!TIP]
> **v5.1で修正済み。** m_agent_security に password_reset_token, reset_token_expires_at を追加。m_influencer_security に password_changed_at を追加。両テーブルのカラム構成を統一。

---

### V5-5. [情報] 問題なし確認項目

以下の観点は全て問題なし:
- DDL構文（全30テーブル）: 末尾カンマ・括弧不一致なし
- TEXT統一ルール: VARCHAR混入なし
- TIMESTAMPTZ統一ルール: DATE例外は全て設計方針に記載済み
- 監査カラム: 全テーブル完備（例外3テーブルも設計通り）
- PK生成ルール: 全例外が設計方針に記載済み
- ON DELETE ルール: 設計方針と整合（V5-2も修正済み）
- Mermaid ER図: 全30テーブル定義済み、FK制約と整合
- テーブル構成: マスタ15 + トランザクション14 + システム1 = 30テーブル
- トリガー: 全対象テーブルに定義済み（t_translations, t_files 含む）
- t_translations / t_files: DDL・インデックス・COMMENT全て適切
- スケーリング方針: 技術的に正確で実用的
- まとめ・変更履歴: 最新状態を反映

---

## v5.1 コンテンツレビュー指摘事項

v5.0の内容・リレーション・整合性に対する深層レビュー結果。

### C-23. ~~[高] 初期データ投入順序のFK違反~~ → 修正済み

> [!TIP]
> **修正済み。** m_agents INSERT が department_id=1 を参照するが、m_departments の INSERT が後に記載されていた。投入順序を m_departments → m_agents に修正。

---

### C-1. ~~[中] fk_campaign_site の ON DELETE CASCADE~~ → 修正済み

> [!TIP]
> **修正済み（V5-2と同一）。** ON DELETE CASCADE → RESTRICT に変更。

---

### C-4. ~~[中] role_type_id にインデックスがない~~ → 修正済み

> [!TIP]
> **修正済み。** `t_influencer_agent_assignments` に `idx_assignments_role(role_type_id)` を追加。

---

### C-9. ~~[中] m_campaigns.status_id の COMMENT に値定義がない~~ → 修正済み

> [!TIP]
> **修正済み。** COMMENT を `'ステータス（1: 進行中, 2: 完了, 3: 中止）'` に更新。

---

### C-19. ~~[中] m_partners_division に m_partners へのFK がない~~ → 修正済み

> [!TIP]
> **修正済み。** `fk_division_partner` FK制約を追加（ON DELETE CASCADE）。Mermaid ER・テキスト図・ON DELETEルール表も更新。

---

### C-20. ~~[中] t_audit_logs が Agent 操作のみ記録可能~~ → 修正済み

> [!TIP]
> **修正済み。** `operator_type SMALLINT NOT NULL`（1: Agent, 2: Influencer）を追加し、FK制約を外してポリモーフィック化。t_notifications, t_files と同じ方式で統一。サンプルクエリも Agent/IF 両対応に更新。

---

### C-5/6/7. ~~[低] UNIQUE制約カラムの冗長インデックス~~ → 修正済み

> [!TIP]
> **修正済み。** PostgreSQL は UNIQUE 制約で自動的にインデックスを作成するため、以下の冗長インデックスを削除:
> - `idx_agents_email`, `idx_agents_login`（m_agents）
> - `idx_influencers_login`, `idx_influencers_email`（m_influencers）
> - `idx_agent_role_types_code`（m_agent_role_types）

---

### C-10. ~~[低] display_order の型不統一~~ → 修正済み

> [!TIP]
> **修正済み。** m_agent_role_types の `display_order SMALLINT`（NULLable, DEFAULTなし）を `INTEGER NOT NULL DEFAULT 0` に変更し、他テーブルと統一。

---

### C-12. ~~[低] CLAUDE.md の DEFAULT 0 記述が曖昧~~ → 修正済み

> [!TIP]
> **修正済み。** 「DEFAULT 0 なし」→「次元カラムは NOT NULL + FK制約（DEFAULTなし）、集計値は NOT NULL DEFAULT 0」に修正。

---

### C-17. ~~[低] entity_type 番号の不統一~~ → 修正済み

> [!TIP]
> **修正済み。** t_files の entity_type を t_notifications と統一: 1:Agent, 2:Influencer, 3:Partner, 4:AdContent, 5:Campaign。

---

### C-21. [情報] m_campaigns にキャンペーン名・期間がない → 対象外

> [!NOTE]
> m_campaigns は「加工用」テーブルであり、単価パラメータを保持する目的。キャンペーン名・期間は不要と確認済み。

---

### C-22. [情報] 集計テーブルに campaign_id がない → 対象外

> [!NOTE]
> site_id + content_id + date で十分特定可能。campaign_id の追加は不要と確認済み。

---

### C-11. [情報] m_influencers.influencer_name が NULL 許容 → 現状維持

> [!NOTE]
> 案件打診時点では名前不明のケースがあるため、NULL許容は運用上妥当。

---

**初回レビュー日**: 2026-02-06
**v2.0 対応確認日**: 2026-02-09
**v3.0 対応確認日**: 2026-02-10
**v4.0 対応確認日**: 2026-02-10
**v5.0 対応確認日**: 2026-02-10
**v5.1 対応確認日**: 2026-02-10
**レビュアー**: Claude Code (AI Review)
