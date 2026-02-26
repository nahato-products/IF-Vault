# インフルエンサー管理システム ER図

## 🏛️ 設計思想

### 監査カラム（全マスタテーブル共通）

全てのマスタテーブルに以下4カラムを**標準装備**する。

| カラム | 型 | 説明 |
|-------|----|------|
| `created_by` | BIGINT | 作成者（`t_agents.agent_id`） |
| `updated_by` | BIGINT | 最終更新者（`t_agents.agent_id`） |
| `created_at` | TIMESTAMPTZ | 作成日時 |
| `updated_at` | TIMESTAMPTZ | 最終更新日時 |

**対象外テーブルと理由**:

| テーブル | 具体例 | 理由 |
|---------|-------|------|
| ログ系（`t_*_logs`） | `t_agent_logs`, `t_influencer_logs` | 追記専用。更新しない。`created_at` のみ持つ |
| セキュリティ系（`t_*_security`） | `t_agent_security`, `t_influencer_security` | `created_by` 不要（主キー = 本人）。`created_at` / `updated_at` のみ持つ |
| 集計系（`t_daily_*`） | `t_daily_performance_details`, `t_daily_click_details` | バッチ処理で自動生成。`created_by` / `updated_by` は不要。`created_at` / `updated_at` のみ持つ |
| 監査ログ系 | `t_audit_logs` | 追記専用。`operated_at` で管理。`created_by` / `updated_by` 不要 |
| バッチログ系 | `t_ingestion_logs` | `finished_at` で管理。ジョブ専用テーブル。`created_by` / `updated_by` 不要 |

> [!NOTE]
> `created_by` / `updated_by` は `t_agents.agent_id` を参照するが、監査用途のため Mermaid ER図のリレーション定義には記載しない（全テーブルに引くと図が煩雑になるため）。実装時は FK 制約ではなくアプリ側で保証する。

### カラム命名規則

全テーブルで以下の命名を統一する。

| 用途 | カラム名 | 備考 |
|------|---------|------|
| 期間開始 | `start_at` | 適用開始・参加日・活動開始日・配信開始日 |
| 期間終了 | `end_at` | 適用終了・脱退日・活動終了日・配信終了日 |
| 恒常（無期限） | `end_at = '2999-12-31'` | 実質無期限を表すセンチネル値 |
| 型の使い分け | DATE / TIMESTAMPTZ | 活動期間・参加日など「日付で管理するもの」はDATE。配信開始・担当割当など「時刻が意味を持つもの」はTIMESTAMPTZ。テーブルの業務性質に応じて選択する |
| 論理削除 | `status_id = 9` | 全テーブル共通。9 = 無効・削除 |
| 論理削除の例外 | `t_ad_contents.delivery_status` | 広告コンテンツのみ配信ライフサイクルを表す `delivery_status`（1:配信前, 2:配信中, 3:配信終了, 9:停止）を使用。`9:停止` が論理削除相当 |
| 現在有効判定 | `end_at > NOW()` | NULLチェック不要 |
| 配信中判定 | `start_at <= NOW() AND end_at > NOW() AND status_id = 1` | `end_at` 単独では不十分。`status_id` と必ず併用 |

> [!NOTE]
> `t_influencer_agent_assignments` の `assigned_at` / `unassigned_at` は既存の慣習として残すのではなく、`start_at` / `end_at` に統一済み。
> 新規テーブル・既存テーブルともにこの命名規則に従う。

### プログレッシブ登録（段階的入力）

Apple のセットアップフローのように、**任意項目は Skip 可能**とし後から補完できる設計を採用する。

- Nullable カラム = バグではなく**意図的な UX 判断**
- 登録ハードルを下げ、必須情報だけで先に進める
- 未入力項目は後からプロフィール画面等で補完

```
登録フロー例：
Step1（必須）: インフルエンサー名・ログインID
Step2（任意）: SNSアカウント → Skip 可
Step3（任意）: 請求先・口座情報 → Skip 可
```

> [!NOTE]
> Nullable カラムが複数テーブルに並存する移行期は、**新しい側（グループ）を正**とし、古い側（インフルエンサー直紐づき）は `@deprecated` として扱う。アプリ側で参照先を統一すること。

### DB制約ルール（Mermaidに書けないもの）

ER図では表現できないが、実装時に必ず設定する制約。

| テーブル | 制約 | 内容 |
|---------|------|------|
| `t_group_members` | `UNIQUE (group_id, influencer_id)` | 同じインフルエンサーが同じグループに2重登録されない |
| `t_group_addresses` | `UNIQUE (group_id) WHERE is_primary = true` | メイン住所は1グループに1件のみ |
| `t_group_bank_accounts` | `UNIQUE (group_id) WHERE is_primary = true` | メイン口座は1グループに1件のみ |
| `t_daily_performance_details` | `UNIQUE (action_date, partner_id, site_id, client_id, ad_content_id)` | 同日・同組み合わせの重複登録を防ぐ（業務キー） |
| `t_daily_click_details` | `UNIQUE (action_date, site_id)` | 同日・同サイトの重複登録を防ぐ（業務キー） |
| `t_campaigns` | `UNIQUE (site_id, platform_type, reward_type, price_type)` | 同一サイトに同条件のキャンペーンが重複しない |
| `t_account_categories` | `UNIQUE (account_id, category_id)` | 同じSNSアカウントに同じカテゴリを重複登録しない |
| `t_sns_platforms` | `UNIQUE (platform_key)` | 識別キーの重複防止 |
| `t_influencer_sns_accounts` | `UNIQUE (influencer_id, platform_id) WHERE is_primary = true` | プラットフォームごとにメインアカウントは1件のみ |
| `t_account_categories` | `UNIQUE (account_id) WHERE is_primary = true` | SNSアカウントごとにメインカテゴリは1件のみ |
| `t_group_billing_info` | `UNIQUE (group_id) WHERE is_primary = true` | メイン請求先は1グループに1件のみ |

### インデックス戦略

実装時に必ず設定するインデックス。

| テーブル | インデックス | 理由 |
|---------|------------|------|
| `t_group_members` | `(group_id, is_active)` | グループ↔インフルエンサーの頻繁なJOIN |
| `t_group_members` | `(influencer_id, is_active)` | インフルエンサー→グループの逆引き |
| `t_influencer_agent_assignments` | `(influencer_id, is_active)` | 担当者検索で頻繁に使用 |
| `t_influencer_agent_assignments` | `(agent_id, is_active)` | エージェント→担当インフルエンサーの逆引き |
| `t_unit_prices` | `(site_id, start_at, end_at, status_id)` | 適用単価の期間検索 |
| `t_partners` | `(group_id)` | group_id経由JOINが多発 |
| `t_daily_performance_details` | `(action_date, partner_id, status_id)` | 日次集計の主要検索パターン |
| `t_daily_performance_details` | `(group_id, action_date)` | グループ別成果集計・RLSフィルタ |
| `t_daily_click_details` | `(action_date, site_id)` | 日次クリック集計 |
| `t_influencer_sns_accounts` | `(influencer_id, status_id)` | インフルエンサー別SNSアカウント絞り込み |
| `t_influencer_sns_accounts` | `(platform_id)` | プラットフォーム別絞り込み |

### グループID自動生成（アプリ側の責任）

インフルエンサー登録時に1人グループを自動生成するのは**アプリ側の責任**。
DB側では担保できないため、以下をトランザクションでセット実行すること。

```
Step1: t_influencers に INSERT
Step2: t_influencer_groups に1人グループを自動生成（end_at = '2999-12-31'）
Step3: t_group_members に紐づけ INSERT
```

> [!WARNING]
> Step2・3 を忘れると請求処理ができないグループなしインフルエンサーが発生する。

### 請求処理時のバリデーション

プログレッシブ登録（Skip可）の思想を維持しつつ、請求処理時のみ以下を必須チェックする。

| チェック項目 | タイミング |
|------------|---------|
| `t_group_bank_accounts` に口座が1件以上あること | 請求処理実行時 |
| `is_primary = true` の口座が1件あること | 請求処理実行時 |

口座未登録の場合は請求不可ステータスで弾き、担当者に通知する。

また、`t_partners.group_id` が `NULL` のパートナーは成果集計から漏れるため、バックエンドで以下のNULLガードを必ず実施する。

```python
# 集計処理実行前にNULLチェック
null_partners = session.query(Partner).filter(Partner.group_id.is_(None)).count()
if null_partners > 0:
    raise ValidationError(f"group_id未設定のパートナーが{null_partners}件あります")
```

### 口座情報の暗号化方針

`t_group_bank_accounts.account_number` は個人情報。DB漏洩時のリスクを下げるために以下の方針を採用する。

| 方針 | 内容 |
|------|------|
| 保存時 | アプリ側でAES-256等で暗号化してから保存 |
| 表示時 | 復号して下4桁のみ表示（例: `****1234`） |
| 請求処理時 | バックエンドで復号して使用 |

> [!WARNING]
> 暗号化キーは環境変数で管理。ハードコード禁止。

### 単価計算ロジックはバックエンドの責任

BQデータ取り込み（Cloud Run）と同様に、単価系のビジネスロジックは**バックエンド（Python）で処理**し、DBは結果の保存のみを担う。

| 処理 | 担当 | DB側の役割 |
|------|------|-----------|
| グロス/ネット計算 | バックエンド | `t_campaigns.price_type` で区分を参照するのみ |
| 予算超過チェック | バックエンド | `t_unit_prices.limit_cap` を参照するのみ |
| セミアフィ計算 | バックエンド | `t_unit_prices.semi_unit_price` を参照するのみ |
| セミアフィ月別切り替え | バックエンド | 切り替え日はバックエンドが判断 |

> [!TIP]
> ロジックをPythonで管理することでGit管理・テスト・デバッグがしやすくなる。DBにビジネスロジックを持たせない。

### 楽観ロック（version カラム）

金額・配信設定に直結するテーブルには `version` カラムを導入し、上書き事故を防ぐ。

| テーブル | 理由 |
|---------|------|
| `t_unit_prices` | 単価の上書きは請求ミスに直結。必須 |
| `t_campaigns` | キャンペーン設定の同時変更は配信・報酬体系に影響 |

```sql
-- 更新時の楽観ロック例（バックエンド実装）
UPDATE t_unit_prices
SET unit_price = ?, version = version + 1
WHERE id = ? AND version = ?
-- 0件更新 = 他のユーザーが先に変更済み → アプリ側でエラー返却
```

> [!WARNING]
> フロントエンドは `version` の値を取得・保持し、更新リクエスト時に必ず送信すること。

---

### SMALLINTコード値の方針

`role_type`, `platform_type`, `billing_type_id` 等のコード値は**マスタテーブル化しない**。

| 理由 | 内容 |
|------|------|
| テーブル数の抑制 | コード値ごとにマスタを作ると管理対象が増えすぎる |
| 変更頻度が低い | プラットフォーム種別・報酬体系は業務上ほぼ固定 |
| アプリ側で管理 | enum / 定数として定義し、バックエンドで一元管理 |

> [!NOTE]
> 追加・変更はバックエンドのenum定義とDBのコメントを同時に更新すること。

---

### サロゲートキーの命名方針

テーブルによってPKカラム名が異なるが、以下の方針で統一されている。

| パターン | 対象テーブル例 | 理由 |
|---------|-------------|------|
| `{テーブル略称}_id`（例: `group_id`） | 他のテーブルからFKとして参照される主要マスタ | 参照側で `group_id` と書くだけで直感的に理解できる |
| `id`（サロゲートキー） | `t_group_members`, `t_group_bank_accounts`, `t_unit_prices`, `t_campaigns`, `t_daily_*` 等 | 他テーブルから直接FK参照されない中間・集計・履歴テーブルでは汎用的な `id` を使用 |

> [!NOTE]
> 業務キー（一意性）は UNIQUE 制約で別途保証する。PKはあくまでも行の物理識別子。

---

### @deprecated カラムの削除方針

設計フェーズでの `@deprecated` カラムはER図から削除済み。現時点で残存する `@deprecated` カラムはなし。

---

## 📊 概要

**8つの主要領域**:
0. 共通マスタ (Common)
1. 社内組織 (Internal)
2. インフルエンサー (Influencer Domain)
2b. グループ (Group Domain)
3. パートナー・広告主 (Business)
4. 広告配信 (Ad Delivery)
5. 成果・集計 (Performance)
6. 請求確定 (Billing)
7. ユーティリティ (Utility)

**リレーション表記**:
- **実線**: 物理的な外部キー制約（システムで強制される繋がり）
- **点線**: 論理的な繋がり（IDは持っているが、FK制約がないもの）

---

## 🗺️ ER図

```mermaid
erDiagram
    %% ==========================================
    %% 0. 共通マスタ (Common)
    %% ==========================================

    t_countries {
        SMALLINT country_id PK
        TEXT country_name
        TEXT country_code "ISO 3166-1 alpha-2"
        TEXT country_code3 "ISO 3166-1 alpha-3"
        TEXT currency_code "通貨コード"
        TEXT phone_prefix "国際電話プレフィックス"
        BOOLEAN is_active
        INTEGER display_order
        BIGINT created_by FK
        BIGINT updated_by FK
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }

    %% リレーション
    t_countries ||--o{ t_influencers : "国籍・活動拠点"

    %% ==========================================
    %% 1. 社内組織 (Internal)
    %% ==========================================

    t_departments {
        BIGINT department_id PK
        BIGINT parent_department_id FK "自己参照"
        TEXT department_name
        TEXT department_code
        BOOLEAN is_active
        BIGINT created_by FK "作成者agent_id"
        BIGINT updated_by FK "更新者agent_id"
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }

    t_agents {
        BIGINT agent_id PK
        BIGINT department_id FK
        TEXT agent_name
        TEXT email_address
        TEXT login_id
        SMALLINT status_id "1:現役,2:退任,3:休職"
        DATE join_date
        BIGINT created_by FK "作成者agent_id"
        BIGINT updated_by FK "更新者agent_id"
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }

    t_agent_security {
        BIGINT agent_id PK,FK
        TEXT password_hash
        TEXT password_salt
        TIMESTAMPTZ last_login_at
        SMALLINT login_failure_count
        TEXT session_token "セッショントークン"
        TIMESTAMPTZ session_expires_at "セッション有効期限"
        TIMESTAMPTZ password_changed_at "パスワード変更日時"
        TEXT password_reset_token "リセットトークン"
        TIMESTAMPTZ reset_token_expires_at "リセット有効期限"
        TIMESTAMPTZ locked_until "ロック解除日時"
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }

    t_agent_logs {
        BIGINT log_id PK
        BIGINT agent_id FK
        TEXT action_type
        TIMESTAMPTZ created_at
    }

    %% リレーション
    t_departments ||--o{ t_departments : "階層構造"
    t_departments ||--o{ t_agents : "所属"
    t_agents ||--|| t_agent_security : "1:1 認証"
    t_agents ||--o{ t_agent_logs : "履歴"

    %% ==========================================
    %% 2. インフルエンサー (Influencer Domain)
    %% ==========================================

    t_influencers {
        BIGINT influencer_id PK
        TEXT influencer_name
        TEXT influencer_alias
        TEXT login_id
        SMALLINT status_id "仮登録→本登録"
        BOOLEAN compliance_check
        SMALLINT country_id FK "国籍・活動拠点"
        BIGINT created_by FK "作成者agent_id"
        BIGINT updated_by FK "更新者agent_id"
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }

    t_influencer_security {
        BIGINT influencer_id PK,FK
        TEXT password_hash
        TEXT password_salt
        TIMESTAMPTZ last_login_at
        SMALLINT login_failure_count
        TEXT session_token "セッショントークン"
        TIMESTAMPTZ session_expires_at "セッション有効期限"
        TIMESTAMPTZ password_changed_at "パスワード変更日時"
        TEXT password_reset_token "リセットトークン"
        TIMESTAMPTZ reset_token_expires_at "リセット有効期限"
        TIMESTAMPTZ locked_until "ロック解除日時"
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }

    t_sns_platforms {
        BIGINT platform_id PK
        TEXT platform_name "Instagram/TikTok/YouTube/X等"
        TEXT platform_key "識別キー（システム内部用）"
        SMALLINT status_id "1:有効, 9:無効"
        BIGINT created_by FK "作成者agent_id"
        BIGINT updated_by FK "更新者agent_id"
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }

    t_influencer_sns_accounts {
        BIGINT account_id PK
        BIGINT influencer_id FK
        BIGINT platform_id FK
        TEXT account_url
        TEXT account_handle
        BIGINT follower_count
        DECIMAL engagement_rate "小数2桁"
        BOOLEAN is_primary "メインアカウントフラグ"
        BOOLEAN is_verified "認証済みフラグ"
        SMALLINT status_id
        BIGINT created_by FK "作成者agent_id"
        BIGINT updated_by FK "更新者agent_id"
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }

    t_categories {
        BIGINT category_id PK
        TEXT category_name
        BIGINT parent_category_id FK "自己参照（階層対応）"
        SMALLINT status_id
        BIGINT created_by FK "作成者agent_id"
        BIGINT updated_by FK "更新者agent_id"
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }

    t_account_categories {
        BIGINT account_category_id PK
        BIGINT account_id FK
        BIGINT category_id FK
        BOOLEAN is_primary "メインカテゴリフラグ"
        BIGINT created_by FK "作成者agent_id"
        BIGINT updated_by FK "更新者agent_id"
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }

    %% t_addresses は t_group_addresses に移行済み（@deprecated）

    t_influencer_logs {
        BIGINT log_id PK
        BIGINT influencer_id FK
        TEXT action_type
        TIMESTAMPTZ created_at
    }

    t_influencer_agent_assignments {
        BIGINT assignment_id PK
        BIGINT influencer_id FK
        BIGINT agent_id FK
        SMALLINT role_type "メイン/サブ/スカウト"
        TIMESTAMPTZ start_at
        TIMESTAMPTZ end_at
        BOOLEAN is_active
        BIGINT created_by FK "作成者agent_id"
        BIGINT updated_by FK "更新者agent_id"
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }

    %% ==========================================
    %% 2b. グループ (Group Domain)
    %% ==========================================

    t_influencer_groups {
        BIGINT group_id PK
        TEXT group_name
        SMALLINT billing_type_id "1:請求書, 2:適格請求書（インボイス）"
        TEXT invoice_tax_id "適格請求書番号"
        SMALLINT affiliation_type_id "1:個人, 2:事務所, 3:グループ"
        SMALLINT status_id "1:有効, 9:無効"
        DATE start_at "活動開始日"
        DATE end_at "活動終了日（恒常は2999-12-31）"
        BIGINT created_by FK "作成者agent_id"
        BIGINT updated_by FK "更新者agent_id"
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }

    t_group_members {
        BIGINT id PK
        BIGINT group_id FK
        BIGINT influencer_id FK
        BOOLEAN is_active
        DATE start_at "参加日"
        DATE end_at "脱退日（在籍中は2999-12-31）"
        BIGINT created_by FK "作成者agent_id"
        BIGINT updated_by FK "更新者agent_id"
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }

    t_group_addresses {
        BIGINT address_id PK
        BIGINT group_id FK
        TEXT zip_code
        TEXT address_line1
        TEXT address_line2
        BOOLEAN is_primary
        BIGINT created_by FK "作成者agent_id"
        BIGINT updated_by FK "更新者agent_id"
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }

    t_group_bank_accounts {
        BIGINT id PK
        BIGINT group_id FK
        TEXT bank_name
        TEXT branch_name
        SMALLINT account_type "1:普通, 2:当座, 3:貯蓄"
        TEXT account_number
        TEXT account_holder
        BOOLEAN is_primary
        BIGINT created_by FK "作成者agent_id"
        BIGINT updated_by FK "更新者agent_id"
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }

    t_group_billing_info {
        BIGINT billing_info_id PK
        BIGINT group_id FK
        TEXT billing_name "請求先名称"
        SMALLINT billing_type_id "1:請求書, 2:適格請求書"
        TEXT invoice_tax_id "適格請求書番号"
        SMALLINT purchase_order_status_id "発注書ステータス"
        BOOLEAN is_primary
        BOOLEAN is_active
        DATE valid_from "適用開始日"
        DATE valid_to "適用終了日"
        BIGINT created_by FK
        BIGINT updated_by FK
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }

    %% リレーション
    t_influencers ||--|| t_influencer_security : "1:1 認証"
    t_influencers ||--o{ t_influencer_sns_accounts : "SNS(1:N)"
    t_sns_platforms ||--o{ t_influencer_sns_accounts : "プラットフォーム"
    t_influencer_sns_accounts ||--o{ t_account_categories : "カテゴリ紐付け"
    t_categories ||--o{ t_categories : "階層構造"
    t_categories ||--o{ t_account_categories : "カテゴリ"
    t_influencers ||--o{ t_influencer_logs : "履歴"
    t_influencers ||--o{ t_influencer_agent_assignments : "割当"
    t_agents ||--o{ t_influencer_agent_assignments : "担当"
    t_influencers ||--o{ t_group_members : "所属"
    t_influencer_groups ||--o{ t_group_members : "メンバー管理"
    t_influencer_groups ||--o{ t_group_addresses : "住所"
    t_influencer_groups ||--o{ t_group_bank_accounts : "口座"
    t_influencer_groups |o--o{ t_partners : "パートナー紐付け"
    t_influencer_groups ||--o{ t_group_billing_info : "請求先"

    %% ==========================================
    %% 3. パートナー・広告主 (Business)
    %% ==========================================

    t_partners {
        BIGINT partner_id PK
        BIGINT group_id FK
        TEXT partner_name
        TEXT email_address
        TEXT login_id
        SMALLINT status_id
        BIGINT created_by FK "作成者agent_id"
        BIGINT updated_by FK "更新者agent_id"
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }

    t_partner_sites {
        BIGINT site_id PK
        BIGINT partner_id FK
        TEXT site_name
        SMALLINT status_id "1:稼働中,2:審査中,3:一時停止,9:停止"
        BIGINT created_by FK "作成者agent_id"
        BIGINT updated_by FK "更新者agent_id"
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }

    t_clients {
        BIGINT client_id PK
        TEXT client_name
        TEXT industry "業界・ジャンル"
        SMALLINT status_id
        BIGINT created_by FK "作成者agent_id"
        BIGINT updated_by FK "更新者agent_id"
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }

    %% リレーション
    t_partners ||--o{ t_partner_sites : "運営"
    %% ※ t_clients と t_partners は直接FK関係なし（意図的）
    %% ナハト社が仲介するため、2者は t_ad_contents / t_daily_performance_details を経由してのみ関係する

    %% ==========================================
    %% 4. 広告配信 (Ad Delivery)
    %% ==========================================

    t_ad_groups {
        BIGINT ad_group_id PK
        TEXT ad_group_name "グループ名(案件名)"
        SMALLINT status_id "1:有効, 9:無効"
        BIGINT created_by FK "作成者agent_id"
        BIGINT updated_by FK "更新者agent_id"
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }

    t_ad_contents {
        BIGINT ad_content_id PK
        BIGINT ad_group_id FK
        BIGINT client_id FK
        BIGINT person_id "No FK・固定運用のためFK不要"
        TEXT ad_name
        TIMESTAMPTZ start_at "配信開始日"
        TIMESTAMPTZ end_at "配信終了日"
        SMALLINT delivery_status "1:配信前,2:配信中,3:配信終了,9:停止"
        BIGINT created_by FK "作成者agent_id"
        BIGINT updated_by FK "更新者agent_id"
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }

    t_unit_prices {
        BIGINT id PK
        BIGINT site_id FK
        DECIMAL unit_price
        DECIMAL limit_cap "上限金額"
        DECIMAL semi_unit_price "セミ単価"
        TIMESTAMPTZ start_at "適用開始日"
        TIMESTAMPTZ end_at "適用終了日"
        SMALLINT status_id
        INTEGER version "楽観ロック用（DEFAULT 1）"
        BIGINT created_by FK "作成者agent_id"
        BIGINT updated_by FK "更新者agent_id"
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }

    t_campaigns {
        BIGINT id PK
        BIGINT site_id FK
        SMALLINT platform_type "1:YouTube, 2:Instagram"
        SMALLINT reward_type "1:固定/CPA, 2:成果/CPC"
        SMALLINT price_type "1:Gross, 2:Net"
        SMALLINT status_id
        INTEGER version "楽観ロック用（DEFAULT 1）"
        BIGINT created_by FK "作成者agent_id"
        BIGINT updated_by FK "更新者agent_id"
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }

    %% リレーション
    t_ad_groups ||--o{ t_ad_contents : "内包(FKあり)"
    t_partner_sites ||--o{ t_unit_prices : "単価設定"
    t_partner_sites ||--o{ t_campaigns : "キャンペーン設定"

    %% 論理リレーション(点線) - FK制約なし
    t_influencers |o..o{ t_ad_contents : "出演(person_id)"
    %% FK制約あり
    t_clients ||--o{ t_ad_contents : "クライアント"

    %% ==========================================
    %% 5. 成果・集計 (Performance)
    %% ==========================================

    t_daily_performance_details {
        BIGINT id "PK（複合PK: action_date + id）"
        DATE action_date "PK兼パーティションキー（RANGE年次）"
        BIGINT partner_id FK
        BIGINT group_id "スナップショット（partner.group_idをコピー）"
        BIGINT site_id FK
        BIGINT client_id FK
        BIGINT ad_content_id FK
        SMALLINT status_id "1:未承認,2:承認,9:否認"
        TEXT rejection_reason "否認理由（status_id=9のとき使用）"
        TEXT partner_name "スナップショット"
        TEXT site_name "スナップショット"
        TEXT client_name "スナップショット"
        TEXT content_name "スナップショット"
        INTEGER cv_count "NOT NULL（BQ取り込み時確定）"
        DECIMAL client_action_cost "報酬総額 NULL=BQ未計算"
        DECIMAL unit_price "平均単価 NULL=BQ未計算"
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }

    t_daily_click_details {
        BIGINT id "PK（複合PK: action_date + id）"
        DATE action_date "PK兼パーティションキー（RANGE年次）"
        BIGINT site_id FK
        TEXT site_name "スナップショット"
        INTEGER click_count
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }

    %% リレーション
    t_partners ||--o{ t_daily_performance_details : "集計"
    t_partner_sites ||--o{ t_daily_performance_details : "集計"
    t_clients ||--o{ t_daily_performance_details : "集計"
    t_ad_contents ||--o{ t_daily_performance_details : "集計"

    t_partner_sites ||--o{ t_daily_click_details : "クリック集計"

    %% ==========================================
    %% 6. 請求確定 (Billing)
    %% ==========================================

    t_billing_runs {
        BIGINT billing_run_id PK
        DATE billing_period_from "請求期間開始"
        DATE billing_period_to "請求期間終了"
        JSONB filter_conditions "抽出条件スナップショット"
        BIGINT confirmed_by FK "確定エージェント"
        TIMESTAMPTZ confirmed_at
        BOOLEAN is_cancelled
        BIGINT cancelled_by FK
        TIMESTAMPTZ cancelled_at
        TEXT notes
        BIGINT created_by FK
        BIGINT updated_by FK
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }

    t_billing_line_items {
        BIGINT line_item_id PK
        BIGINT billing_run_id FK
        DATE action_date
        BIGINT partner_id FK
        BIGINT site_id FK
        BIGINT client_id FK
        BIGINT ad_content_id FK
        TEXT partner_name "スナップショット"
        TEXT site_name "スナップショット"
        TEXT client_name "スナップショット"
        TEXT content_name "スナップショット"
        INTEGER cv_count
        DECIMAL unit_price
        DECIMAL amount
        BIGINT created_by FK
        BIGINT updated_by FK
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }

    %% リレーション
    t_billing_runs ||--o{ t_billing_line_items : "明細"
    t_agents ||--o{ t_billing_runs : "確定"
    t_partners ||--o{ t_billing_line_items : "請求対象"
    t_partner_sites ||--o{ t_billing_line_items : "サイト"
    t_clients ||--o{ t_billing_line_items : "クライアント"
    t_ad_contents ||--o{ t_billing_line_items : "広告"

    %% ==========================================
    %% 7. ユーティリティ (Utility)
    %% ==========================================

    t_files {
        BIGINT file_id PK
        SMALLINT entity_type "1:influencer,2:group,3:partner,4:agent,5:content"
        BIGINT entity_id "対象レコードID"
        TEXT file_category "ファイル種別"
        TEXT file_name
        TEXT storage_path "Cloud Storage パス"
        TEXT mime_type
        BIGINT file_size_bytes
        SMALLINT sort_order
        BOOLEAN is_primary
        BIGINT created_by FK
        BIGINT updated_by FK
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }

    t_notifications {
        BIGINT notification_id PK
        BIGINT user_id "通知先ID"
        SMALLINT user_type "1:agent, 2:influencer"
        TEXT notification_type "通知種別"
        TEXT title
        TEXT message
        TEXT link_url
        BOOLEAN is_read
        TIMESTAMPTZ read_at
        BIGINT created_by FK
        BIGINT updated_by FK
        TIMESTAMPTZ created_at
        TIMESTAMPTZ updated_at
    }

    t_audit_logs {
        BIGINT log_id "PK（複合PK: operated_at + log_id）"
        TEXT table_name "操作対象テーブル"
        BIGINT record_id "操作対象レコードID"
        TEXT action_type "INSERT/UPDATE/DELETE"
        JSONB old_value "変更前の値"
        JSONB new_value "変更後の値"
        SMALLINT operator_type "1:agent, 2:influencer"
        BIGINT operator_id "操作者ID"
        TEXT operator_ip
        TIMESTAMPTZ operated_at "PK兼パーティションキー（RANGE月次）"
    }

    t_ingestion_logs {
        BIGINT ingestion_id PK
        TEXT job_type "バッチジョブ種別"
        TIMESTAMPTZ target_from "取り込み対象期間開始"
        TIMESTAMPTZ target_to "取り込み対象期間終了"
        JSONB parameters
        TEXT status "RUNNING/SUCCESS/FAILED"
        INTEGER records_count
        TEXT error_message
        TIMESTAMPTZ started_at
        TIMESTAMPTZ finished_at
    }

```

---

## 📋 テーブル一覧

### 0. 共通マスタ (Common)
| テーブル名 | 説明 |
|-----------|------|
| **t_countries** | 国マスタ（国際対応） |

### 1. 社内組織 (Internal)
| テーブル名 | 説明 |
|-----------|------|
| **t_departments** | 部署マスタ（階層構造対応） |
| **t_agents** | エージェント（担当者）マスタ |
| **t_agent_security** | エージェント認証情報（1:1） |
| **t_agent_logs** | エージェント操作履歴 |

### 2. インフルエンサー (Influencer Domain)
| テーブル名 | 説明 |
|-----------|------|
| **t_influencers** | インフルエンサーマスタ（個人情報のみ） |
| **t_influencer_security** | 認証情報（1:1） |
| **t_sns_platforms** | SNSプラットフォームマスタ（Instagram/TikTok/YouTube/X等） |
| **t_influencer_sns_accounts** | SNSアカウント（1:N・プラットフォーム別） |
| **t_categories** | カテゴリマスタ（階層対応） |
| **t_account_categories** | SNSアカウント↔カテゴリ中間テーブル |
| **t_influencer_logs** | 操作履歴 |
| **t_influencer_agent_assignments** | 担当者割当（履歴管理） |

### 2b. グループ (Group Domain)
| テーブル名 | 説明 |
|-----------|------|
| **t_influencer_groups** | グループマスタ（活動単位・請求主体） |
| **t_group_members** | グループ↔インフルエンサー中間テーブル（多対多） |
| **t_group_addresses** | グループ住所（複数対応） |
| **t_group_bank_accounts** | グループ口座（複数対応） |
| **t_group_billing_info** | グループ請求先情報（複数対応） |

### 3. パートナー・広告主 (Business)
| テーブル名 | 説明 |
|-----------|------|
| **t_partners** | パートナー（ASP）マスタ |
| **t_partner_sites** | サイト（媒体）マスタ |
| **t_clients** | クライアント（広告主）マスタ |

### 4. 広告配信 (Ad Delivery)
| テーブル名 | 説明 |
|-----------|------|
| **t_ad_groups** | 広告グループ（案件単位） |
| **t_ad_contents** | 広告コンテンツ（クリエイティブ） |
| **t_unit_prices** | 単価マスタ（期間・上限管理） |
| **t_campaigns** | キャンペーン設定（媒体・報酬体系） |

### 5. 成果・集計 (Performance)
| テーブル名 | 説明 |
|-----------|------|
| **t_daily_performance_details** | 日次CV成果（パーティション） |
| **t_daily_click_details** | 日次クリック数（パーティション） |

### 6. 請求確定 (Billing)
| テーブル名 | 説明 |
|-----------|------|
| **t_billing_runs** | 請求確定バッチ（確定・取消管理） |
| **t_billing_line_items** | 請求明細（スナップショット付き） |

### 7. ユーティリティ (Utility)
| テーブル名 | 説明 |
|-----------|------|
| **t_files** | ファイル管理（ポリモーフィック） |
| **t_notifications** | ユーザー通知 |
| **t_audit_logs** | 共通監査ログ（月次パーティション） |
| **t_ingestion_logs** | BQ取り込みログ |

---

## 🔍 設計の特徴

### ✅ 良い設計ポイント

#### 1. 監査カラムの標準化
全マスタテーブルに `created_by` / `updated_by` / `created_at` / `updated_at` を統一装備。
「誰がいつ登録・更新したか」を全テーブルで追跡可能。

#### 2. サイトごとのパラメーター管理
```
t_campaigns {
    site_id FK
    platform_type    -- YouTube/Instagram
    reward_type      -- 固定/成果報酬
    price_type       -- Gross/Net
}
```
各サイト（媒体）ごとに媒体タイプ、報酬体系、価格区分を柔軟に設定可能。

#### 3. セキュリティ分離
```
インフルエンサー ←1:1→ 認証テーブル
エージェント ←1:1→ 認証テーブル
```
認証情報を別テーブルに分離し、パスワード漏洩リスクを低減。

#### 4. パーティショニング
```sql
t_daily_performance_details (action_date で分割)
t_daily_click_details (action_date で分割)
```
大量データの効率的な検索・集計が可能。

#### 5. スナップショット方式
```sql
t_daily_performance_details {
    partner_name TEXT  -- マスタの名前を保存
    site_name TEXT
    client_name TEXT
    content_name TEXT
}
```
過去の集計データで名前が変わっても、当時の名前を保持。

#### 6. 履歴管理
```sql
t_influencer_agent_assignments {
    start_at  -- 開始日
    end_at    -- 終了日
    is_active      -- 現在担当中フラグ
}

t_unit_prices {
    start_at  -- 適用開始
    end_at    -- 適用終了
}
```
担当者変更や単価変更の履歴を完全追跡。

#### 7. 柔軟な組織階層
```sql
t_departments {
    parent_department_id  -- 自己参照FK
}
```
任意の深さの組織構造に対応。

### ⚠️ 改善検討ポイント

#### 1. FK制約のない論理リレーション（対応済み）
```sql
t_ad_contents {
    client_id BIGINT FK  -- ✅ FK追加済み
    person_id BIGINT     -- 固定のため FK不要（No FK維持）
}
```

`client_id` は `t_clients` への FK制約を追加済み。`person_id` は固定運用のため No FK を維持。

#### 2. パートナーとサイトの関係
```
t_partners (パートナー)
  └─ t_partner_sites (サイト)
       └─ なぜsite_idに複数のCV?
```

**不明点**:
- 1サイト = 1媒体（InstagramアカウントやYouTubeチャンネル）？
- それとも1サイト = 複数の投稿枠？

#### 3. 複合主キーの粒度（対応済み）
```sql
t_daily_performance_details {
    id BIGINT PK  -- ✅ サロゲートキー導入済み
    action_date DATE
    partner_id BIGINT
    ...
    status_id SMALLINT  -- PKから外れた → UPDATEで変更可能に
}
-- UNIQUE (action_date, partner_id, site_id, client_id, ad_content_id) で一意性保証
-- INDEX (action_date, partner_id, status_id) で検索最適化
```

#### 4. グループ概念（導入済み）
インフルエンサーの上位概念としてグループ（活動単位）を正式導入。
5テーブル（`t_influencer_groups` / `t_group_members` / `t_group_addresses` / `t_group_bank_accounts` / `t_group_billing_info`）を新設。
請求先・住所・口座はグループに紐づく設計に変更済み。

---

## 💡 主要なクエリパターン

### インフルエンサーの月次成果
```sql
SELECT
    i.influencer_name,
    SUM(d.cv_count) as total_cv,
    SUM(d.client_action_cost) as total_revenue,
    AVG(d.unit_price) as avg_unit_price
FROM t_influencers i
JOIN t_group_members gm ON i.influencer_id = gm.influencer_id AND gm.is_active = TRUE
JOIN t_partners p ON gm.group_id = p.group_id
JOIN t_daily_performance_details d ON p.partner_id = d.partner_id
WHERE d.action_date BETWEEN '2026-01-01' AND '2026-01-31'
  AND d.status_id = 2  -- 承認済みのみ
GROUP BY i.influencer_id, i.influencer_name
ORDER BY total_revenue DESC;
```

### 担当エージェントの成果集計
```sql
SELECT
    a.agent_name,
    COUNT(DISTINCT i.influencer_id) as influencer_count,
    SUM(d.cv_count) as total_cv,
    SUM(d.client_action_cost) as total_revenue
FROM t_agents a
JOIN t_influencer_agent_assignments ia
  ON a.agent_id = ia.agent_id
  AND ia.is_active = TRUE  -- 現在の担当のみ
JOIN t_influencers i ON ia.influencer_id = i.influencer_id
JOIN t_group_members gm ON i.influencer_id = gm.influencer_id AND gm.is_active = TRUE
JOIN t_partners p ON gm.group_id = p.group_id
JOIN t_daily_performance_details d ON p.partner_id = d.partner_id
WHERE d.action_date >= CURRENT_DATE - INTERVAL '30 days'
  AND ia.role_type = 1  -- メイン担当のみ
GROUP BY a.agent_id, a.agent_name
ORDER BY total_revenue DESC;
```

### クライアント別の投資対効果
```sql
SELECT
    c.client_name,
    c.industry,
    COUNT(DISTINCT ac.ad_content_id) as content_count,
    SUM(d.cv_count) as total_cv,
    SUM(d.client_action_cost) as total_cost,
    ROUND(AVG(d.unit_price), 0) as avg_unit_price
FROM t_clients c
JOIN t_daily_performance_details d ON c.client_id = d.client_id
LEFT JOIN t_ad_contents ac ON d.ad_content_id = ac.ad_content_id
WHERE d.action_date >= CURRENT_DATE - INTERVAL '90 days'
  AND d.status_id = 2
GROUP BY c.client_id, c.client_name, c.industry
ORDER BY total_cost DESC;
```

---

## 🎯 総合評価

**スコア: 9/10**

### ✅ 優れている点
- 監査カラムの標準化（created_by / updated_by / created_at / updated_at）
- サイトごとのパラメーター管理（t_campaigns）
- セキュリティ情報の分離
- パーティショニング戦略
- スナップショット方式
- 履歴管理機能
- 階層構造対応

### ✅ 設計フェーズ完了
全ての設計課題を解消済み。次フェーズ（実装）に進める状態。

---

## 📅 変更履歴

| 日付 | 変更内容 |
|------|---------|
| 2026-01-29 | 初版作成 |
| 2026-02-25 | 監査カラム（created_by / updated_by / created_at / updated_at）を全マスタテーブルに追加。設計思想セクション追加 |
| 2026-02-25 | グループ概念導入。t_influencer_groups / t_group_members / t_group_addresses / t_group_bank_accounts を新設。t_influencers からグループ系カラムを移動。t_addresses を t_group_addresses に移行。t_partners に group_id FK 追加 |
| 2026-02-26 | t_partners.influencer_id（@deprecated）を削除。t_ad_contents.client_id に FK制約追加。t_daily_performance_details をサロゲートキー（id PK）に変更・複合PK解消。設計フェーズ完了 |
| 2026-02-26 | DBレビュー対応。口座暗号化方針・インデックス戦略・group_id NULLガード を設計思想に追記。t_daily_click_details サロゲートキー化。start_at/end_at を DATE 型に統一（t_influencer_groups / t_group_members）。person_id コメント補足 |
| 2026-02-26 | 100点対応。t_daily_performance_details の site_id / content_id に FK追加・rejection_reason カラム追加。delivery_status にコメント追加。t_campaigns に UNIQUE制約追加 |
| 2026-02-26 | SNSアカウント設計を固定カラム1:1（t_sns_accounts）から1:N構成に刷新。t_sns_platforms・t_influencer_sns_accounts・t_categories・t_account_categories を新設 |
| 2026-02-26 | 実装者版との統合（v7.0.0）。t_countries / t_group_billing_info / t_billing_runs / t_billing_line_items / t_files / t_notifications / t_audit_logs / t_ingestion_logs を追加。t_agent_security・t_influencer_security に認証カラム（session管理・パスワードリセット・ロックアウト）を追加 |
| 2026-02-26 | レビュー修正（v7.0.1）。t_partners.group_id を ON DELETE SET NULL に変更。t_billing_line_items にスナップショット設計の意図コメント追加。006_create_rls.sql に v7.0.0 追加テーブルの GRANT / RLS ポリシーを追加（t_group_billing_info / t_billing_runs / t_billing_line_items / t_notifications / t_agent_security / t_influencer_security）。influencers_agent_own ポリシーを FOR SELECT, UPDATE に変更（INSERT時 WITH CHECK 常時 FALSE バグ修正）。パーティションテーブル 3 件の複合 PK を ER 図に反映（t_daily_performance_details: action_date+id、t_daily_click_details: action_date+id、t_audit_logs: operated_at+log_id）。t_unit_prices に btree_gist EXCLUDE 制約追加（期間重複防止）。t_daily_performance_details の unit_price / client_action_cost を nullable に変更（NULL = BQ未計算）|

**作成者**: sekiguchi
**タグ**: #database #er図 #設計 #インフルエンサー #project
