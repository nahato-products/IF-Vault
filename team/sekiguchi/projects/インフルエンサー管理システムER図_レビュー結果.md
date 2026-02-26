# インフルエンサー管理システム ER図 レビュー結果

## 📊 レビュー概要

**レビュー日**: 2026-01-30
**レビュアー**: Claude Sonnet 4.5 (Senior Data Architect)
**対象**: インフルエンサー管理システムER図 v1.0
**総合評価**: 8.5/10

---

## 🎯 総合評価

### ✅ 優れている点

1. **セキュリティ情報の分離** - 認証情報を別テーブルに分離し、パスワード漏洩リスクを低減
2. **パーティショニング戦略** - 日次集計テーブルで効率的なデータ管理
3. **スナップショット方式** - 過去データの名前変更に対応
4. **履歴管理機能** - 担当者変更・単価変更の完全追跡
5. **階層構造対応** - 柔軟な組織構造
6. **サイトごとのパラメーター管理** - t_campaignsによる柔軟な設定

### ⚠️ 改善が必要な点

1. **FK制約の欠如** - 論理リレーションを物理FK化すべき
2. **SNS拡張性不足** - 固定カラム設計では新しいSNSに対応困難
3. **複合PKの粒度** - status_idがPKに含まれる設計上の問題
4. **監査情報の不足** - created_by, updated_by, deleted_atが未実装
5. **データ型の曖昧さ** - TEXT型の多用、DECIMAL精度未指定
6. **パートナー概念の不明瞭さ** - 卸先とインフルエンサーの区別が不明確（運用者確認待ち）

---

## 🔴 優先度: 高（必須対応）

### 1. SNSアカウント管理の拡張性改善

#### 現状の問題

```sql
-- ❌ 問題のある設計
t_sns_accounts {
    BIGINT influencer_id PK,FK
    TEXT instagram_url
    TEXT tiktok_url
    TEXT youtube_url
    TEXT x_url
}
```

**問題点**:
- 新しいSNS（Threads、Bluesky等）追加のたびにALTER TABLE必要
- 1インフルエンサーが複数のInstagramアカウントを持つケースに非対応
- URLのバリデーションがない
- フォロワー数などのメトリクスを保存できない

#### 改善案

```sql
-- ✅ SNSプラットフォームマスタ
CREATE TABLE t_sns_platforms (
    platform_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    platform_name VARCHAR(50) NOT NULL UNIQUE,
    platform_code VARCHAR(20) NOT NULL UNIQUE,
    url_pattern TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    display_order SMALLINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ✅ インフルエンサーのSNSアカウント（1:N対応）
CREATE TABLE t_influencer_sns_accounts (
    account_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    influencer_id BIGINT NOT NULL,
    platform_id BIGINT NOT NULL,
    account_url VARCHAR(500) NOT NULL,
    account_handle VARCHAR(100),
    follower_count INTEGER,
    last_synced_at TIMESTAMPTZ,
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    is_verified BOOLEAN NOT NULL DEFAULT FALSE,
    status_id SMALLINT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_sns_account_influencer
        FOREIGN KEY (influencer_id) REFERENCES t_influencers(influencer_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_sns_account_platform
        FOREIGN KEY (platform_id) REFERENCES t_sns_platforms(platform_id)
        ON DELETE RESTRICT,
    CONSTRAINT unique_influencer_platform_url
        UNIQUE (influencer_id, platform_id, account_url)
);

CREATE INDEX idx_sns_accounts_influencer
    ON t_influencer_sns_accounts(influencer_id, is_primary);
CREATE INDEX idx_sns_accounts_platform
    ON t_influencer_sns_accounts(platform_id, status_id);

-- 初期データ投入
INSERT INTO t_sns_platforms (platform_name, platform_code, url_pattern, display_order) VALUES
('Instagram', 'instagram', 'https://(www\.)?instagram\.com/.*', 1),
('TikTok', 'tiktok', 'https://(www\.)?tiktok\.com/.*', 2),
('YouTube', 'youtube', 'https://(www\.)?youtube\.com/.*', 3),
('X (Twitter)', 'x', 'https://(www\.)?(x|twitter)\.com/.*', 4),
('Threads', 'threads', 'https://(www\.)?threads\.net/.*', 5);
```

**メリット**:
- 新しいSNS追加時はINSERT文のみ（スキーマ変更不要）
- 複数アカウント管理が可能
- フォロワー数などのメトリクスを保存可能
- 認証バッジなどの情報も管理可能

**マイグレーション戦略**:
```sql
-- 既存データ移行例
INSERT INTO t_influencer_sns_accounts (influencer_id, platform_id, account_url, is_primary)
SELECT
    influencer_id,
    1, -- Instagram
    instagram_url,
    TRUE
FROM t_sns_accounts
WHERE instagram_url IS NOT NULL AND instagram_url <> '';

-- 旧テーブル削除
DROP TABLE t_sns_accounts;
```

---

### 2. role_typeマスタテーブル化

#### 現状の問題

```sql
-- ❌ 問題のある設計
t_influencer_agent_assignments {
    SMALLINT role_type "メイン/サブ/スカウト"  -- コメントのみ、FK制約なし
}
```

**問題点**:
- データ整合性がアプリケーション依存
- 存在しない値（例: 99）が入る可能性
- 役割の説明や権限情報を保持できない

#### 改善案

```sql
-- ✅ 役割マスタテーブル
CREATE TABLE t_agent_role_types (
    role_type_id SMALLINT PRIMARY KEY,
    role_name VARCHAR(50) NOT NULL UNIQUE,
    role_code VARCHAR(20) NOT NULL UNIQUE,
    description TEXT,
    can_edit_profile BOOLEAN NOT NULL DEFAULT FALSE,
    can_approve_content BOOLEAN NOT NULL DEFAULT FALSE,
    commission_rate DECIMAL(5, 2),
    display_order SMALLINT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 初期データ投入
INSERT INTO t_agent_role_types
    (role_type_id, role_name, role_code, description, can_edit_profile, can_approve_content, commission_rate, display_order)
VALUES
    (1, 'メイン担当', 'main', 'メイン担当者。プロフィール編集・コンテンツ承認権限あり。報酬配分率50%。', TRUE, TRUE, 50.00, 1),
    (2, 'サブ担当', 'sub', 'サブ担当者。コンテンツ承認権限あり。報酬配分率30%。', FALSE, TRUE, 30.00, 2),
    (3, 'スカウト担当', 'scout', 'スカウト担当者。新規登録時のみ関与。報酬配分率20%。', FALSE, FALSE, 20.00, 3);

-- 既存テーブルに外部キー追加
ALTER TABLE t_influencer_agent_assignments
    ADD CONSTRAINT fk_assignment_role_type
    FOREIGN KEY (role_type) REFERENCES t_agent_role_types(role_type_id)
    ON DELETE RESTRICT;

CREATE INDEX idx_assignments_role_type
    ON t_influencer_agent_assignments(role_type);
```

**メリット**:
- データベースレベルでの整合性保証
- 役割の権限情報を一元管理
- 管理画面での役割マスタ編集が可能

---

### 3. t_ad_contentsの論理リレーションを物理FK化

#### 現状の問題

```sql
-- ❌ 問題のある設計
t_ad_contents {
    BIGINT client_id "No FK"      -- 存在しないIDが入る可能性
    BIGINT person_id "No FK"      -- 命名も不統一（influencer_idであるべき）
}
```

**問題点**:
- データ整合性がアプリケーション依存
- 存在しないclient_id、person_idが挿入される可能性
- JOINクエリが遅くなる（インデックスなし）
- 命名規則の不統一（person_id vs influencer_id）

#### 改善案

```sql
-- ✅ カラム名の統一
ALTER TABLE t_ad_contents
    RENAME COLUMN person_id TO influencer_id;

-- ✅ 外部キー制約の追加
ALTER TABLE t_ad_contents
    ADD CONSTRAINT fk_content_client
    FOREIGN KEY (client_id) REFERENCES t_clients(client_id)
    ON DELETE RESTRICT;

ALTER TABLE t_ad_contents
    ADD CONSTRAINT fk_content_influencer
    FOREIGN KEY (influencer_id) REFERENCES t_influencers(influencer_id)
    ON DELETE RESTRICT;

-- ✅ インデックス追加
CREATE INDEX idx_ad_contents_client
    ON t_ad_contents(client_id);
CREATE INDEX idx_ad_contents_influencer
    ON t_ad_contents(influencer_id);
CREATE INDEX idx_ad_contents_delivery
    ON t_ad_contents(delivery_status, delivery_start_at, delivery_end_at);
```

**メリット**:
- データベースレベルでの参照整合性保証
- 削除時のカスケード制御
- クエリパフォーマンスの向上

---

### 4. t_daily_performance_detailsの複合PK改善

#### 現状の問題

```sql
-- ❌ 問題のある設計
t_daily_performance_details {
    -- 6カラムの複合主キー
    DATE action_date PK
    BIGINT partner_id PK,FK
    BIGINT site_id PK
    BIGINT client_id PK
    BIGINT content_id PK
    SMALLINT status_id PK  -- ⚠️ これが問題
}
```

**問題点**:
1. **status_idがPKに含まれる**
   - 承認ステータス変更（未承認→承認）が別レコードになる
   - UPDATEではなくINSERTが必要になり、データが重複
2. **同日・同組み合わせで複数CV発生時の処理が困難**
3. **INSERTのパフォーヘッドが大きい**（6カラムの一意性チェック）

#### 改善案

```sql
-- ✅ サロゲートキー導入
CREATE TABLE t_daily_performance_details (
    detail_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    action_date DATE NOT NULL,
    partner_id BIGINT NOT NULL,
    site_id BIGINT NOT NULL,
    client_id BIGINT NOT NULL,
    content_id BIGINT NOT NULL,
    status_id SMALLINT NOT NULL,

    -- スナップショット（名前変更に対応）
    partner_name VARCHAR(200),
    site_name VARCHAR(200),
    client_name VARCHAR(200),
    content_name VARCHAR(200),

    -- メトリクス
    cv_count INTEGER NOT NULL DEFAULT 0,
    client_action_cost DECIMAL(15, 2),
    unit_price DECIMAL(10, 2),

    -- 監査
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- ✅ ビジネスキーのユニーク制約
    CONSTRAINT unique_daily_performance
        UNIQUE (action_date, partner_id, site_id, client_id, content_id, status_id),

    -- ✅ 外部キー制約
    CONSTRAINT fk_perf_partner
        FOREIGN KEY (partner_id) REFERENCES t_partners(partner_id)
        ON DELETE RESTRICT,
    CONSTRAINT fk_perf_site
        FOREIGN KEY (site_id) REFERENCES t_partner_sites(site_id)
        ON DELETE RESTRICT,
    CONSTRAINT fk_perf_client
        FOREIGN KEY (client_id) REFERENCES t_clients(client_id)
        ON DELETE RESTRICT,
    CONSTRAINT fk_perf_content
        FOREIGN KEY (content_id) REFERENCES t_ad_contents(ad_content_id)
        ON DELETE RESTRICT
) PARTITION BY RANGE (action_date);

-- ✅ パーティション作成例（PostgreSQL）
CREATE TABLE t_daily_performance_details_2026_01
    PARTITION OF t_daily_performance_details
    FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');

-- ✅ インデックス戦略
CREATE INDEX idx_perf_date_partner
    ON t_daily_performance_details(action_date, partner_id);
CREATE INDEX idx_perf_date_status
    ON t_daily_performance_details(action_date, status_id);
CREATE INDEX idx_perf_client
    ON t_daily_performance_details(client_id, action_date);
CREATE INDEX idx_perf_updated
    ON t_daily_performance_details(updated_at);
```

**メリット**:
- status_id変更がUPDATEで処理可能
- UPSERT処理が簡単（ON CONFLICT対応）
- パフォーマンス向上
- データ整合性の保証

---

## 🟡 優先度: 中（運用改善）

### 5. 監査カラムの追加

#### 対象テーブル

全マスタテーブルに以下を追加：

```sql
-- ✅ 標準監査カラム
created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
created_by BIGINT        -- FK to t_agents(agent_id)
updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
updated_by BIGINT        -- FK to t_agents(agent_id)
deleted_at TIMESTAMPTZ   -- 論理削除（NULL = 有効）
```

#### 実装例

```sql
-- t_influencersへの追加
ALTER TABLE t_influencers
    ADD COLUMN created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ADD COLUMN created_by BIGINT,
    ADD COLUMN updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ADD COLUMN updated_by BIGINT,
    ADD COLUMN deleted_at TIMESTAMPTZ;

ALTER TABLE t_influencers
    ADD CONSTRAINT fk_influencer_created_by
    FOREIGN KEY (created_by) REFERENCES t_agents(agent_id)
    ON DELETE SET NULL;

ALTER TABLE t_influencers
    ADD CONSTRAINT fk_influencer_updated_by
    FOREIGN KEY (updated_by) REFERENCES t_agents(agent_id)
    ON DELETE SET NULL;

CREATE INDEX idx_influencers_deleted
    ON t_influencers(deleted_at) WHERE deleted_at IS NULL;

-- トリガーでupdated_at自動更新
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_influencers_updated_at
    BEFORE UPDATE ON t_influencers
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
```

#### 対象テーブル一覧

- t_departments
- t_agents
- t_influencers
- t_partners
- t_partner_sites
- t_clients
- t_ad_groups
- t_ad_contents
- t_unit_prices
- t_campaigns

---

### 6. データ型の最適化

#### TEXT型の見直し

```sql
-- ❌ 現状: TEXT型が多用されている
t_influencers {
    TEXT influencer_name        -- 無制限
    TEXT email_address          -- バリデーションなし
    TEXT login_id               -- 無制限
    TEXT account_number         -- 機密情報
}

-- ✅ 改善後
ALTER TABLE t_influencers
    ALTER COLUMN influencer_name TYPE VARCHAR(100),
    ALTER COLUMN influencer_name SET NOT NULL,
    ALTER COLUMN influencer_alias TYPE VARCHAR(100),
    ALTER COLUMN email_address TYPE VARCHAR(255),
    ALTER COLUMN login_id TYPE VARCHAR(50),
    ALTER COLUMN login_id SET NOT NULL,
    ADD CONSTRAINT unique_influencer_login_id UNIQUE (login_id),
    ADD CONSTRAINT check_email_format
        CHECK (email_address ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$');
```

#### DECIMAL型の精度指定

```sql
-- ❌ 現状: 精度未指定
t_unit_prices {
    DECIMAL unit_price        -- 精度不明
    DECIMAL limit_cap
    DECIMAL semi_unit_price
}

-- ✅ 改善後
ALTER TABLE t_unit_prices
    ALTER COLUMN unit_price TYPE DECIMAL(12, 2),
    ALTER COLUMN limit_cap TYPE DECIMAL(12, 2),
    ALTER COLUMN semi_unit_price TYPE DECIMAL(12, 2);

-- t_daily_performance_detailsも同様
ALTER TABLE t_daily_performance_details
    ALTER COLUMN client_action_cost TYPE DECIMAL(15, 2),
    ALTER COLUMN unit_price TYPE DECIMAL(10, 2);
```

**データ型ガイドライン**:
- 名前: VARCHAR(100)
- メールアドレス: VARCHAR(255)
- ログインID: VARCHAR(50)
- URL: VARCHAR(500)
- 金額: DECIMAL(12, 2) （最大9,999,999,999.99円）
- 大規模案件の金額: DECIMAL(15, 2)

---

### 7. インデックス戦略の追加

#### パフォーマンス最適化のためのインデックス

```sql
-- ✅ t_influencers
CREATE INDEX idx_influencers_status
    ON t_influencers(status_id) WHERE status_id IN (1, 2);
CREATE INDEX idx_influencers_compliance
    ON t_influencers(compliance_check) WHERE compliance_check = FALSE;

-- ✅ t_influencer_agent_assignments（担当者検索最適化）
CREATE INDEX idx_assignments_active
    ON t_influencer_agent_assignments(influencer_id, agent_id, is_active)
    WHERE is_active = TRUE;
CREATE INDEX idx_assignments_agent_active
    ON t_influencer_agent_assignments(agent_id, is_active)
    WHERE is_active = TRUE;
CREATE INDEX idx_assignments_dates
    ON t_influencer_agent_assignments(assigned_at, unassigned_at);

-- ✅ t_ad_contents（配信期間検索最適化）
CREATE INDEX idx_ad_contents_delivery_period
    ON t_ad_contents(delivery_start_at, delivery_end_at, delivery_status);

-- ✅ t_unit_prices（有効期間検索最適化）
CREATE INDEX idx_unit_prices_active_period
    ON t_unit_prices(site_id, start_at, end_at, status_id)
    WHERE status_id = 1;

-- ✅ t_campaigns
CREATE INDEX idx_campaigns_site_platform
    ON t_campaigns(site_id, platform_type, status_id);

-- ✅ t_agent_logs, t_influencer_logs（時系列検索最適化）
CREATE INDEX idx_agent_logs_created
    ON t_agent_logs(created_at DESC);
CREATE INDEX idx_influencer_logs_created
    ON t_influencer_logs(created_at DESC);
```

---

### 8. セキュリティテーブルの改善

#### 現状の問題

```sql
-- ❌ 現状
t_agent_security {
    TEXT password_hash
    TEXT password_salt           -- 現代的にはbcryptなどでsalt込みのハッシュを使う
    SMALLINT login_failure_count
}
```

#### 改善案

```sql
-- ✅ 改善後
ALTER TABLE t_agent_security
    DROP COLUMN password_salt,
    ALTER COLUMN password_hash TYPE VARCHAR(255),
    ADD COLUMN locked_until TIMESTAMPTZ,
    ADD COLUMN last_login_ip VARCHAR(45),
    ADD COLUMN session_token VARCHAR(255),
    ADD COLUMN session_expires_at TIMESTAMPTZ,
    ADD COLUMN password_changed_at TIMESTAMPTZ,
    ADD COLUMN created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ADD COLUMN updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP;

-- t_influencer_securityも同様の改善
ALTER TABLE t_influencer_security
    DROP COLUMN password_salt,
    ALTER COLUMN password_hash TYPE VARCHAR(255),
    ADD COLUMN locked_until TIMESTAMPTZ,
    ADD COLUMN last_login_ip VARCHAR(45),
    ADD COLUMN session_token VARCHAR(255),
    ADD COLUMN session_expires_at TIMESTAMPTZ,
    ADD COLUMN password_changed_at TIMESTAMPTZ,
    ADD COLUMN created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ADD COLUMN updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP;
```

**セキュリティベストプラクティス**:
- password_hashは bcrypt/argon2 でsalt込みで保存
- アカウントロック機構（locked_until）
- セッション管理（session_token, session_expires_at）
- IPアドレスログ（不正アクセス検知）
- パスワード変更履歴（password_changed_at）

---

## 🔵 優先度: 低（将来検討）

### 9. 将来的に必要になる可能性があるテーブル

#### 権限管理システム

```sql
-- 権限マスタ
CREATE TABLE t_permissions (
    permission_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    permission_code VARCHAR(50) NOT NULL UNIQUE,
    permission_name VARCHAR(100) NOT NULL,
    description TEXT,
    category VARCHAR(50),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 役割と権限の紐付け
CREATE TABLE t_role_permissions (
    role_type_id SMALLINT NOT NULL,
    permission_id BIGINT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (role_type_id, permission_id),
    CONSTRAINT fk_role_permission_role
        FOREIGN KEY (role_type_id) REFERENCES t_agent_role_types(role_type_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_role_permission_permission
        FOREIGN KEY (permission_id) REFERENCES t_permissions(permission_id)
        ON DELETE CASCADE
);
```

#### 通知システム

```sql
CREATE TABLE t_notifications (
    notification_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    user_id BIGINT NOT NULL,
    user_type SMALLINT NOT NULL, -- 1:Agent, 2:Influencer, 3:Partner
    notification_type VARCHAR(50) NOT NULL, -- 'assignment', 'approval', 'payment'
    title VARCHAR(200) NOT NULL,
    message TEXT,
    link_url VARCHAR(500),
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notifications_user
    ON t_notifications(user_id, user_type, is_read, created_at DESC);
```

#### コメント・メモ機能

```sql
CREATE TABLE t_comments (
    comment_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    entity_type VARCHAR(50) NOT NULL, -- 'influencer', 'ad_content', 'partner'
    entity_id BIGINT NOT NULL,
    author_id BIGINT NOT NULL,
    author_type SMALLINT NOT NULL, -- 1:Agent, 2:Influencer
    comment_text TEXT NOT NULL,
    parent_comment_id BIGINT, -- 返信機能
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_comments_entity
    ON t_comments(entity_type, entity_id, created_at DESC)
    WHERE deleted_at IS NULL;
```

#### メディアファイル管理

```sql
CREATE TABLE t_media_files (
    file_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    ad_content_id BIGINT,
    file_type VARCHAR(20) NOT NULL, -- 'video', 'image', 'thumbnail', 'document'
    file_url VARCHAR(1000) NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_size_bytes BIGINT,
    mime_type VARCHAR(100),
    uploaded_by BIGINT,
    uploaded_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_media_content
        FOREIGN KEY (ad_content_id) REFERENCES t_ad_contents(ad_content_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_media_uploader
        FOREIGN KEY (uploaded_by) REFERENCES t_agents(agent_id)
        ON DELETE SET NULL
);

CREATE INDEX idx_media_content
    ON t_media_files(ad_content_id, file_type);
```

---

## 🚧 保留事項（運用者確認待ち）

### パートナーとインフルエンサーの関係性

**確認が必要な点**:

1. **パートナーの定義**
   - 「卸先」と「インフルエンサー自身」の2タイプがあるとのこと
   - 現在のt_partnersテーブルでは区別が不明瞭

2. **確認事項**:
   - 卸先パートナーは複数のインフルエンサーを管理するか？（1:N関係）
   - 1インフルエンサーが複数のASP（A8、バリューコマース等）に登録するか？
   - パートナータイプの区別をDB制約で強制すべきか？

3. **暫定的な改善案**:

```sql
-- オプション1: partner_type列を追加
ALTER TABLE t_partners
    ADD COLUMN partner_type SMALLINT NOT NULL DEFAULT 1, -- 1:卸先, 2:インフルエンサー
    ADD COLUMN asp_provider VARCHAR(50); -- ASP名（タイプ2の場合）

-- オプション2: 中間テーブルで多対多関係を管理
CREATE TABLE t_partner_influencer_relations (
    relation_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    partner_id BIGINT NOT NULL,
    influencer_id BIGINT NOT NULL,
    relation_type SMALLINT NOT NULL, -- 1:所属, 2:ASP連携
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    start_date DATE,
    end_date DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_relation_partner
        FOREIGN KEY (partner_id) REFERENCES t_partners(partner_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_relation_influencer
        FOREIGN KEY (influencer_id) REFERENCES t_influencers(influencer_id)
        ON DELETE CASCADE,
    CONSTRAINT unique_partner_influencer
        UNIQUE (partner_id, influencer_id, relation_type)
);
```

**運用者に確認後、最適な設計を決定する。**

---

## 📊 実装プラン

### Phase 1: データ整合性の確保（必須）

**期間**: 1-2週間
**影響**: 中（既存データのマイグレーション必要）

- [ ] SNSアカウント管理の拡張実装
  - [ ] t_sns_platformsテーブル作成
  - [ ] t_influencer_sns_accountsテーブル作成
  - [ ] 既存データマイグレーション
  - [ ] t_sns_accountsテーブル削除
- [ ] role_typeマスタテーブル化
  - [ ] t_agent_role_typesテーブル作成
  - [ ] 初期データ投入
  - [ ] 外部キー制約追加
- [ ] t_ad_contentsのFK追加
  - [ ] カラム名変更（person_id → influencer_id）
  - [ ] 外部キー制約追加
  - [ ] インデックス追加
- [ ] t_daily_performance_detailsのPK変更
  - [ ] 新テーブル作成（サロゲートキー方式）
  - [ ] データマイグレーション
  - [ ] パーティション設定
  - [ ] インデックス作成

### Phase 2: 品質向上（推奨）

**期間**: 1週間
**影響**: 小（スキーマ変更のみ）

- [ ] 監査カラムの追加（全マスタテーブル）
- [ ] データ型の最適化
  - [ ] TEXT → VARCHAR変換
  - [ ] DECIMAL精度指定
  - [ ] CHECK制約追加
- [ ] インデックス追加
  - [ ] パフォーマンス測定
  - [ ] 必要なインデックスの追加
  - [ ] 不要なインデックスの削除

### Phase 3: セキュリティ強化（推奨）

**期間**: 数日
**影響**: 小（認証ロジックの変更必要）

- [ ] セキュリティテーブルの改善
  - [ ] password_salt削除
  - [ ] ロック機構追加
  - [ ] セッション管理カラム追加
  - [ ] パスワードハッシュ化ロジック変更（bcrypt/argon2）

### Phase 4: 将来対応（任意）

**期間**: 未定
**影響**: なし（新機能追加時）

- [ ] 権限管理システム
- [ ] 通知システム
- [ ] コメント機能
- [ ] メディアファイル管理

---

## ✅ チェックリスト

### DDL実行前の確認

- [ ] バックアップ取得完了
- [ ] マイグレーションスクリプトのテスト実行完了
- [ ] ロールバック手順の確認
- [ ] 影響範囲の特定（テーブル、ビュー、ストアドプロシージャ等）
- [ ] 本番環境の停止時間調整

### DDL実行後の確認

- [ ] データ整合性チェック（既存データの検証）
- [ ] パフォーマンステスト
- [ ] アプリケーション側のコード修正
- [ ] テストケースの更新
- [ ] ドキュメントの更新

---

## 📚 参考資料

### 推奨読書

- [PostgreSQL公式ドキュメント - パーティショニング](https://www.postgresql.org/docs/current/ddl-partitioning.html)
- [データベース設計のベストプラクティス](https://www.postgresql.org/docs/current/sql-createtable.html)
- [OWASP - パスワード保存のベストプラクティス](https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html)

### クエリ例

主要なクエリパターンは元のER図ドキュメント（インフルエンサー管理システムER図.md:457-511）に記載。

---

## 🔍 追加レビューポイント

### 設計上の疑問点・確認事項

#### 1. t_influencersのaccount_numberの設計意図

**質問**: 口座情報（account_number）を直接influencersテーブルに持たせる意図は？

**潜在的な問題**:
```sql
t_influencers {
    TEXT account_number "口座情報"  -- ❌ 機密情報が直接保存
}
```

- 機密情報がメインテーブルに混在
- 1インフルエンサーが複数の口座を持つケース（報酬振込先、税金対策等）に非対応
- 銀行名、支店名、口座種別などの詳細情報が保持できない

**改善提案**:
```sql
-- 銀行口座情報テーブル（分離・暗号化対応）
CREATE TABLE t_bank_accounts (
    account_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    influencer_id BIGINT NOT NULL,
    bank_name VARCHAR(100) NOT NULL,
    bank_code VARCHAR(10),
    branch_name VARCHAR(100),
    branch_code VARCHAR(10),
    account_type SMALLINT NOT NULL, -- 1:普通, 2:当座
    account_number_encrypted TEXT NOT NULL, -- 暗号化された口座番号
    account_holder_name VARCHAR(100) NOT NULL,
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    status_id SMALLINT NOT NULL DEFAULT 1, -- 1:有効, 9:無効
    verified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_bank_account_influencer
        FOREIGN KEY (influencer_id) REFERENCES t_influencers(influencer_id)
        ON DELETE CASCADE
);

CREATE INDEX idx_bank_accounts_influencer
    ON t_bank_accounts(influencer_id, is_primary);
```

---

#### 2. t_addressesのリレーションキー

**質問**: t_influencersとt_addressesは何をKeyにしてリレーションを張っている？

**現状の確認**:
```sql
-- 元の定義
t_addresses {
    BIGINT address_id PK
    BIGINT influencer_id FK  -- ✅ 外部キーは明記されている
    ...
}
```

**確認事項**:
- ✅ influencer_idで正しく紐付いている
- ⚠️ ただし、1:N関係でis_primaryフラグがあるため、「1インフルエンサーに必ず1つのプライマリ住所」を保証する仕組みがない

**改善提案**:
```sql
-- アプリケーションレベルまたはトリガーでチェック
CREATE OR REPLACE FUNCTION check_primary_address()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_primary = TRUE THEN
        -- 他の住所のプライマリフラグを解除
        UPDATE t_addresses
        SET is_primary = FALSE
        WHERE influencer_id = NEW.influencer_id
          AND address_id != NEW.address_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ensure_single_primary_address
    BEFORE INSERT OR UPDATE ON t_addresses
    FOR EACH ROW
    WHEN (NEW.is_primary = TRUE)
    EXECUTE FUNCTION check_primary_address();

-- 少なくとも1つのプライマリ住所を保証するチェックは複雑なので、
-- アプリケーションロジックで対応することを推奨
```

---

#### 3. 担当者変更ログの管理

**質問**: 担当者とインフルエンサーの組み合わせの変更ログは、t_influencer_agent_assignmentsで管理する？

**現状の確認**:
```sql
t_influencer_agent_assignments {
    assigned_at TIMESTAMPTZ      -- ✅ 開始日
    unassigned_at TIMESTAMPTZ    -- ✅ 終了日
    is_active BOOLEAN            -- ✅ 現在の状態
}
```

**評価**: ✅ 正しい設計
- 履歴テーブルとして機能している
- assigned_at/unassigned_atで期間管理
- is_activeで現在の担当者をフィルタリング可能

**さらなる改善提案**:
```sql
-- 変更理由を記録するカラム追加
ALTER TABLE t_influencer_agent_assignments
    ADD COLUMN change_reason TEXT,
    ADD COLUMN changed_by BIGINT,
    ADD CONSTRAINT fk_assignment_changed_by
        FOREIGN KEY (changed_by) REFERENCES t_agents(agent_id)
        ON DELETE SET NULL;

-- 変更履歴の監査用インデックス
CREATE INDEX idx_assignments_audit
    ON t_influencer_agent_assignments(influencer_id, assigned_at DESC);
```

---

#### 4. パートナーとインフルエンサーの関係性

**状況**: 運用者に確認中（保留中）

既に「保留事項」セクションに記載済み。

---

#### 5. 複数ASPアカウント管理の欠如

**問題**: 既にレビュー済みの内容と重複

「パートナーとインフルエンサーの関係性」の確認と合わせて対応予定。

---

#### 6. role_typeの外部キー制約

**状況**: ✅ 既に「優先度: 高」セクションで対応済み

インフルエンサー管理システムER図_レビュー結果.md:129-170 で詳細な改善案を記載。

---

#### 7. 広告グループ、広告、広告主（クライアント）の関係性

**質問**: 今の広告グループ、広告、広告主（クライアント）の関係性は適切か？

**現状の確認**:
```sql
-- 現状の関係
t_ad_groups (広告グループ)
  ↓ 1:N (FK: ad_group_id)
t_ad_contents (広告コンテンツ)
  ↓ 論理リレーション (No FK: client_id)
t_clients (クライアント)
```

**潜在的な問題**:
1. **クライアントと広告グループの直接的な関係がない**
   - 1クライアントが複数の広告グループを持つ場合、どう管理するのか不明
   - 「案件」の単位が不明確

2. **広告グループの意味が曖昧**
   - ad_group_nameが「案件名」とコメントされているが、案件の定義が不明
   - 1案件 = 1クライアント？それとも1案件 = 複数クライアント？

**改善提案**:
```sql
-- オプション1: クライアントを広告グループに紐付ける
ALTER TABLE t_ad_groups
    ADD COLUMN client_id BIGINT NOT NULL,
    ADD CONSTRAINT fk_ad_group_client
        FOREIGN KEY (client_id) REFERENCES t_clients(client_id)
        ON DELETE RESTRICT;

CREATE INDEX idx_ad_groups_client
    ON t_ad_groups(client_id);

-- オプション2: 案件（キャンペーン）の概念を明確化
-- t_ad_groups → t_campaigns に名称変更し、より明確な構造にする
CREATE TABLE t_client_campaigns (
    campaign_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    client_id BIGINT NOT NULL,
    campaign_name VARCHAR(200) NOT NULL,
    campaign_code VARCHAR(50) UNIQUE,
    start_date DATE,
    end_date DATE,
    budget DECIMAL(15, 2),
    status_id SMALLINT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_campaign_client
        FOREIGN KEY (client_id) REFERENCES t_clients(client_id)
        ON DELETE RESTRICT
);

-- 広告コンテンツはキャンペーンに紐付く
ALTER TABLE t_ad_contents
    RENAME COLUMN ad_group_id TO campaign_id;
```

**推奨**: オプション1の実装（既存構造への最小変更）

---

#### 8. 各種マスタテーブルのログテーブル欠如

**指摘**: 以下のテーブルにログテーブルがない

- t_clients（クライアントの変更履歴）
- t_ad_groups（広告グループの変更履歴）
- t_departments（部署の変更履歴）
- t_partners（パートナーの変更履歴）
- t_partner_sites（サイトの変更履歴）

**現状**: エージェントとインフルエンサーのみログテーブルが存在
```sql
t_agent_logs        -- ✅ あり
t_influencer_logs   -- ✅ あり
```

**評価**:
- ログテーブルの必要性は**ビジネス要件による**
- エージェント・インフルエンサー：ユーザー操作のため必要性が高い
- クライアント・広告グループ：マスタデータのため、監査カラム（created_at, updated_at, created_by, updated_by）で十分な可能性

**推奨アプローチ**:
```sql
-- オプション1: 汎用ログテーブル（全エンティティ対応）
CREATE TABLE t_audit_logs (
    log_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    entity_type VARCHAR(50) NOT NULL, -- 'client', 'ad_group', 'department', etc.
    entity_id BIGINT NOT NULL,
    action_type VARCHAR(20) NOT NULL, -- 'INSERT', 'UPDATE', 'DELETE'
    changed_by BIGINT,
    changed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    old_values JSONB,
    new_values JSONB,

    CONSTRAINT fk_audit_changed_by
        FOREIGN KEY (changed_by) REFERENCES t_agents(agent_id)
        ON DELETE SET NULL
);

CREATE INDEX idx_audit_logs_entity
    ON t_audit_logs(entity_type, entity_id, changed_at DESC);

-- PostgreSQLのトリガーで自動ログ記録
CREATE OR REPLACE FUNCTION log_table_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO t_audit_logs (entity_type, entity_id, action_type, new_values)
        VALUES (TG_TABLE_NAME, NEW.id, 'INSERT', to_jsonb(NEW));
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO t_audit_logs (entity_type, entity_id, action_type, old_values, new_values)
        VALUES (TG_TABLE_NAME, NEW.id, 'UPDATE', to_jsonb(OLD), to_jsonb(NEW));
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO t_audit_logs (entity_type, entity_id, action_type, old_values)
        VALUES (TG_TABLE_NAME, OLD.id, 'DELETE', to_jsonb(OLD));
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 各テーブルにトリガー設定
CREATE TRIGGER audit_clients
    AFTER INSERT OR UPDATE OR DELETE ON t_clients
    FOR EACH ROW EXECUTE FUNCTION log_table_changes();
```

**オプション2**: 個別ログテーブル（必要に応じて）
```sql
CREATE TABLE t_client_logs (
    log_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    client_id BIGINT NOT NULL,
    action_type VARCHAR(50) NOT NULL,
    changed_by BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_client_log_client
        FOREIGN KEY (client_id) REFERENCES t_clients(client_id)
        ON DELETE CASCADE
);
```

**推奨**: まずは監査カラム（created_by, updated_by）の追加から始め、詳細なログが必要になったら汎用ログテーブル（オプション1）を実装。

---

#### 9. t_daily_performance_detailsのステータス表記

**指摘**: 「未承認」→「承認待ち」に変更すべきでは？

**現状**:
```sql
SMALLINT status_id "1:未承認,2:承認,9:否認"
```

**検討**:
- 「未承認」は「まだ承認されていない状態」を指す
- 「承認待ち」は「承認のアクションを待っている状態」を指す

**推奨**:
```sql
-- より明確なステータス定義
SMALLINT status_id
-- 1: 承認待ち (pending)
-- 2: 承認済み (approved)
-- 3: 差し戻し (rejected)
-- 9: 否認 (denied)

-- マスタテーブル化する場合
CREATE TABLE t_performance_status_types (
    status_id SMALLINT PRIMARY KEY,
    status_name VARCHAR(50) NOT NULL,
    status_code VARCHAR(20) NOT NULL UNIQUE,
    description TEXT,
    display_order SMALLINT
);

INSERT INTO t_performance_status_types (status_id, status_name, status_code, display_order) VALUES
(1, '承認待ち', 'pending', 1),
(2, '承認済み', 'approved', 2),
(3, '差し戻し', 'rejected', 3),
(9, '否認', 'denied', 9);
```

---

#### 10. スナップショット方式の説明

**質問**: スナップショットってなんだ？

**説明**:
```sql
t_daily_performance_details {
    partner_name TEXT  -- ⚠️ これがスナップショット
    site_name TEXT
    client_name TEXT
    content_name TEXT
}
```

**スナップショットとは**:
- マスタテーブルの**データをその時点で保存**する手法
- 集計データ作成時点の名前を保存しておくことで、**後からマスタの名前が変更されても過去データの整合性を保つ**

**具体例**:
1. 2026年1月にパートナー名が「山田太郎」だった
2. 日次集計時に「山田太郎」をスナップショット保存
3. 2026年3月にパートナー名が「山田次郎」に変更
4. しかし、1月の集計データには「山田太郎」が残っている（当時の正しい名前）

**メリット**:
- 過去のレポートが正確に再現できる
- JOIN不要で名前を取得可能（パフォーマンス向上）

**デメリット**:
- データの重複（ストレージ増加）
- マスタ変更時にスナップショットが更新されない（意図的）

**ベストプラクティス**: ✅ 集計・レポート用テーブルでは推奨される手法

---

#### 11. t_daily_performance_detailsのリレーションと項目

**質問**: リレーションが多いのでは？現在の項目が必要な場合、今のようなリレーションが必要？

**現状の確認**:
```sql
-- 複数の外部キー
t_partners ||--o{ t_daily_performance_details
t_partner_sites ||--o{ t_daily_performance_details
t_clients ||--o{ t_daily_performance_details
t_ad_contents ||--o{ t_daily_performance_details
```

**評価**:
- ✅ **これは正しい設計** - 集計テーブルは多次元分析のため複数のディメンション（次元）が必要
- 典型的な**スタースキーマ**または**スノーフレークスキーマ**の設計

**データウェアハウスの観点**:
```
         ┌─────────────┐
         │ t_partners  │ (ディメンション)
         └──────┬──────┘
                │
         ┌──────▼──────────────────┐
         │ t_daily_performance_    │
    ┌────┤      details            ├────┐
    │    │   (ファクトテーブル)      │    │
    │    └─────────────────────────┘    │
    │                                   │
┌───▼────────┐                 ┌───────▼──────┐
│ t_clients  │                 │ t_ad_contents│
│(ディメンション)│                 │ (ディメンション)│
└────────────┘                 └──────────────┘
```

**リレーション削減の検討**:
```sql
-- もしパフォーマンスが問題なら、非正規化も選択肢
-- ただし、現状の設計で問題ないと思われる

-- 改善案: サロゲートキーのみでリレーション
CREATE TABLE t_daily_performance_details (
    detail_id BIGINT PRIMARY KEY,
    action_date DATE NOT NULL,

    -- ディメンションキー（外部キー）
    partner_id BIGINT NOT NULL,
    site_id BIGINT NOT NULL,
    client_id BIGINT NOT NULL,
    content_id BIGINT NOT NULL,

    -- スナップショット（非正規化）
    partner_name VARCHAR(200),
    site_name VARCHAR(200),
    client_name VARCHAR(200),
    content_name VARCHAR(200),

    -- メトリクス（測定値）
    cv_count INTEGER,
    client_action_cost DECIMAL(15, 2),
    unit_price DECIMAL(10, 2)
);
```

**結論**: ✅ 現在のリレーション数は適切。集計・分析用テーブルとして正しい設計。

---

#### 12. t_campaignsのprice_type配置

**質問**: price_type（1:Gross, 2:Net）はt_unit_pricesに持たせるべきでは？

**現状の確認**:
```sql
-- 現状
t_campaigns {
    site_id FK
    platform_type "1:YouTube, 2:Instagram"
    reward_type "1:固定/CPA, 2:成果/CPC"
    price_type "1:Gross, 2:Net"  -- ⚠️ ここにある
}

t_unit_prices {
    site_id FK
    unit_price DECIMAL
    limit_cap DECIMAL
    start_at TIMESTAMPTZ
    end_at TIMESTAMPTZ
}
```

**検討**:

**現状の設計意図** (推測):
- t_campaigns: サイトごとの**基本設定**（プラットフォーム、報酬体系、価格区分）
- t_unit_prices: **期間ごとの単価設定**（時期によって単価が変わる）

**問題点**:
- price_typeが期間によって変わる可能性がある場合、t_campaignsでは対応できない
- 例: 2026年1月はGross、2026年2月からNetに変更、というケース

**改善提案**:
```sql
-- オプション1: price_typeをt_unit_pricesに移動
ALTER TABLE t_unit_prices
    ADD COLUMN price_type SMALLINT NOT NULL DEFAULT 1; -- 1:Gross, 2:Net

ALTER TABLE t_campaigns
    DROP COLUMN price_type;

-- オプション2: 両方に持たせる（デフォルト値と個別設定）
-- t_campaigns.price_type: デフォルトの価格区分
-- t_unit_prices.price_type: 個別設定（NULLの場合はキャンペーンのデフォルトを使用）
ALTER TABLE t_unit_prices
    ADD COLUMN price_type SMALLINT; -- NULLable

-- クエリ例
SELECT
    COALESCE(up.price_type, c.price_type) as effective_price_type,
    up.unit_price
FROM t_unit_prices up
JOIN t_campaigns c ON up.site_id = c.site_id;
```

**推奨**: **オプション1**（price_typeをt_unit_pricesに移動）
- 期間ごとの設定変更に対応
- より柔軟な運用が可能

---

#### 13. 加工用テーブルの欠如

**質問**: 加工用テーブルなくない？

**現状**:
- t_daily_performance_details: 日次集計
- t_daily_click_details: 日次クリック集計

**不足している可能性があるテーブル**:

```sql
-- 1. 月次集計テーブル（パフォーマンス最適化）
CREATE TABLE t_monthly_performance_summary (
    summary_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    year_month VARCHAR(7) NOT NULL, -- '2026-01'
    partner_id BIGINT NOT NULL,
    site_id BIGINT,
    client_id BIGINT,

    total_cv INTEGER,
    total_revenue DECIMAL(15, 2),
    total_clicks INTEGER,
    average_cvr DECIMAL(5, 4), -- コンバージョン率
    average_unit_price DECIMAL(10, 2),

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT unique_monthly_summary
        UNIQUE (year_month, partner_id, site_id, client_id)
);

-- 2. インフルエンサー成果集計（キャッシュテーブル）
CREATE TABLE t_influencer_performance_cache (
    cache_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    influencer_id BIGINT NOT NULL,
    year_month VARCHAR(7) NOT NULL,

    total_cv INTEGER,
    total_revenue DECIMAL(15, 2),
    total_clicks INTEGER,
    active_campaigns INTEGER,

    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT unique_influencer_cache
        UNIQUE (influencer_id, year_month)
);

-- 3. エージェント成果集計（レポート用）
CREATE TABLE t_agent_performance_summary (
    summary_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    agent_id BIGINT NOT NULL,
    year_month VARCHAR(7) NOT NULL,

    managed_influencer_count INTEGER,
    total_cv INTEGER,
    total_revenue DECIMAL(15, 2),

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT unique_agent_summary
        UNIQUE (agent_id, year_month)
);

-- 4. ステージングテーブル（外部データ取込用）
CREATE TABLE t_staging_performance_import (
    import_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    import_batch_id VARCHAR(50) NOT NULL,
    action_date DATE,
    partner_code VARCHAR(50),
    site_code VARCHAR(50),
    client_code VARCHAR(50),
    cv_count INTEGER,
    revenue DECIMAL(15, 2),

    -- 処理ステータス
    import_status SMALLINT DEFAULT 1, -- 1:未処理, 2:処理済, 9:エラー
    error_message TEXT,
    imported_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMPTZ
);

CREATE INDEX idx_staging_import_batch
    ON t_staging_performance_import(import_batch_id, import_status);
```

**推奨**:
- 月次集計テーブルは**パフォーマンス向上のため推奨**
- ステージングテーブルは**外部連携がある場合に必須**
- キャッシュテーブルは**アプリケーション側で実装する選択肢もあり**

---

**次のステップ**:
1. 運用者とパートナー概念の確認
2. 上記の追加レビューポイントについて優先度を決定
3. Phase 1の実装計画策定（追加項目を含む）
4. マイグレーションスクリプトの作成
5. 開発環境でのテスト実施

---

**作成日**: 2026-01-30
**作成者**: Claude Sonnet 4.5 (Data Architect Review)
**対象バージョン**: インフルエンサー管理システムER図 v1.0
**タグ**: #database #review #改善提案 #er図 #インフルエンサー
