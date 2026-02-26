# ansem-db-patterns — Reference

SKILL.md の補足資料。DDLテンプレート、実装サンプル、チェックリスト、アンチパターン。

---

## DDLテンプレート集 [CRITICAL]

### マスタテーブル

```sql
CREATE TABLE m_{entity} (
  {entity}_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name TEXT NOT NULL,
  -- 業務カラム
  status_id SMALLINT NOT NULL DEFAULT 1,
  created_by BIGINT NOT NULL,
  updated_by BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE m_{entity} IS '{日本語名}';
COMMENT ON COLUMN m_{entity}.status_id IS 'ステータスID（1: 有効, 9: 削除済み）';
```

### トランザクションテーブル

```sql
CREATE TABLE t_{entity} (
  {entity}_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  {parent}_id BIGINT NOT NULL,
  -- 業務カラム
  created_by BIGINT NOT NULL,
  updated_by BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_{entity}_{parent} FOREIGN KEY ({parent}_id)
    REFERENCES m_{parent}({parent}_id) ON DELETE RESTRICT
);
```

### 1対1セキュリティテーブル

```sql
CREATE TABLE m_{entity}_security (
  {entity}_id BIGINT PRIMARY KEY,
  password_hash TEXT NOT NULL,
  last_login_at TIMESTAMPTZ,
  session_token TEXT,
  session_expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_{entity}_security FOREIGN KEY ({entity}_id)
    REFERENCES m_{entity}({entity}_id) ON DELETE CASCADE
);
```

### 中間テーブル（多対多）

```sql
CREATE TABLE t_{a}_{b} (
  {a}_id BIGINT NOT NULL,
  {b}_id BIGINT NOT NULL,
  created_by BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY ({a}_id, {b}_id),
  CONSTRAINT fk_{a}_{b}_{a} FOREIGN KEY ({a}_id)
    REFERENCES {a_table}({a}_id) ON DELETE CASCADE,
  CONSTRAINT fk_{a}_{b}_{b} FOREIGN KEY ({b}_id)
    REFERENCES {b_table}({b}_id) ON DELETE RESTRICT
);
```

### 集計テーブル（パーティション付き）

```sql
CREATE TABLE t_daily_{metric}_details (
  detail_id BIGINT GENERATED ALWAYS AS IDENTITY,
  action_date DATE NOT NULL,
  partner_id BIGINT NOT NULL,
  partner_name TEXT NOT NULL,       -- スナップショット（#15）
  count_value INTEGER NOT NULL DEFAULT 0,
  created_by BIGINT NOT NULL DEFAULT 1,
  updated_by BIGINT NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (detail_id, action_date),
  CONSTRAINT fk_daily_{metric}_partner FOREIGN KEY (partner_id)
    REFERENCES m_partners(partner_id) ON DELETE RESTRICT
) PARTITION BY RANGE (action_date);
```

### ポリモーフィックテーブル

```sql
CREATE TABLE t_{feature} (
  {feature}_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  entity_type TEXT NOT NULL,
  entity_id BIGINT NOT NULL,
  -- 業務カラム
  created_by BIGINT NOT NULL,
  updated_by BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_{feature}_entity ON t_{feature}(entity_type, entity_id);
```

---

## updated_at 自動更新トリガー [CRITICAL]

```sql
-- 関数（1回だけ作成）
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 各テーブルに適用
CREATE TRIGGER trg_{table}_updated_at
  BEFORE UPDATE ON {table}
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();
```

例外: `t_audit_logs`, `ingestion_logs`（UPDATEされない設計）

---

## パーティション作成テンプレート [HIGH]

### 年次パーティション

```sql
CREATE TABLE t_daily_performance_details_2025
  PARTITION OF t_daily_performance_details
  FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

-- アーカイブ
ALTER TABLE t_daily_performance_details
  DETACH PARTITION t_daily_performance_details_2022;
```

### 月次パーティション

```sql
CREATE TABLE t_audit_logs_2025_01
  PARTITION OF t_audit_logs
  FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');
```

### 自動作成関数

```sql
CREATE OR REPLACE FUNCTION create_yearly_partitions(
  base_table TEXT, year_start INT, year_end INT
) RETURNS VOID AS $$
DECLARE
  y INT;
BEGIN
  FOR y IN year_start..year_end LOOP
    EXECUTE format(
      'CREATE TABLE IF NOT EXISTS %I PARTITION OF %I FOR VALUES FROM (%L) TO (%L)',
      base_table || '_' || y,
      base_table,
      y || '-01-01',
      (y + 1) || '-01-01'
    );
  END LOOP;
END;
$$ LANGUAGE plpgsql;
```

---

## 楽観ロック実装パターン [HIGH]

```sql
-- テーブル定義
version INTEGER NOT NULL DEFAULT 1

-- 更新時（アプリ側）
UPDATE m_influencers
SET name = $1, version = version + 1, updated_at = CURRENT_TIMESTAMP
WHERE influencer_id = $2 AND version = $3;

-- 行数0なら競合発生 → アプリ側でリトライ or エラー
```

---

## UPSERT パターン集 [HIGH]

### 基本UPSERT（日次集計投入）

```sql
INSERT INTO t_daily_performance_details
  (action_date, partner_id, site_id, partner_name, site_name, cv_count)
VALUES ($1, $2, $3, $4, $5, $6)
ON CONFLICT (action_date, partner_id, site_id)
DO UPDATE SET
  cv_count = EXCLUDED.cv_count,
  partner_name = EXCLUDED.partner_name,
  site_name = EXCLUDED.site_name,
  updated_at = CURRENT_TIMESTAMP;
```

### バルクUPSERT

```sql
INSERT INTO m_influencers (influencer_name, affiliation_type_id, email_address, created_by, updated_by)
VALUES
  ($1, $2, $3, $4, $4),
  ($5, $6, $7, $8, $8)
ON CONFLICT (influencer_id) DO NOTHING;
```

### 条件付きUPSERT

```sql
INSERT INTO t_unit_prices (influencer_id, price, start_at, created_by, updated_by)
VALUES ($1, $2, $3, $4, $4)
ON CONFLICT (influencer_id, start_at)
DO UPDATE SET price = EXCLUDED.price
WHERE t_unit_prices.updated_at < EXCLUDED.updated_at;
```

---

## FK削除ポリシー判断フローチャート [HIGH]

```
子データに独立した価値がある？
├─ YES → RESTRICT
│   例: SNSアカウント（実績紐付き）、集計データ
└─ NO
    ├─ 親子が1対1か、親なしで意味なし？
    │   ├─ YES → CASCADE
    │   │   例: IF→住所、IF→口座、IF→セキュリティ
    │   └─ NO
    │       └─ 参照がNULLABLEで任意？
    │           ├─ YES → SET NULL
    │           │   例: パートナー→IF兼業（optional）
    │           └─ NO → RESTRICT（安全側に倒す）
    └─
```

---

## チェックリスト [CRITICAL]

### テーブル設計チェック

- [ ] プレフィックス: マスタは `m_`、トランザクションは `t_`
- [ ] PK: `{entity}_id` + BIGINT GENERATED ALWAYS AS IDENTITY
- [ ] データ型: 文字列は全てTEXT、日時は全てTIMESTAMPTZ
- [ ] 監査カラム: created_by, updated_by, created_at, updated_at
- [ ] FK制約: 全外部キーに制約あり + 削除ポリシー明示
- [ ] NULL: 必須カラムに NOT NULL、任意カラムのみNULLABLE
- [ ] BOOLEAN: `is_` プレフィックス + NOT NULL + DEFAULT
- [ ] インデックス: 全FK + 頻出検索条件
- [ ] コメント: テーブルと主要カラムにCOMMENT ON
- [ ] 制約命名: fk_/idx_/uq_/chk_ プレフィックス

### 集計テーブルチェック

- [ ] 次元カラム: NOT NULL + FK制約（DEFAULTなし）
- [ ] 集計値: NOT NULL DEFAULT 0
- [ ] スナップショット: 名前カラムが非正規化で保持
- [ ] パーティション: RANGE + 適切な分割単位
- [ ] created_by/updated_by: DEFAULT 1（システム管理者）

### リリース前チェック

- [ ] FK依存順でCREATE TABLE（参照先を先に作る）
- [ ] インデックスはテーブル作成後に一括作成
- [ ] コメントは別ファイルで管理
- [ ] トリガーは関数を先に作成、次にトリガー
- [ ] パーティションは3年分を事前作成

---

## アンチパターン集 [HIGH]

### データ型

| やりがち | 問題 | 正解 |
|----------|------|------|
| VARCHAR(255)乱用 | 根拠のない長さ制限 | TEXT統一 |
| TIMESTAMP without TZ | タイムゾーン問題 | TIMESTAMPTZ統一 |
| FLOAT/DOUBLEで金額 | 浮動小数点誤差 | DECIMAL(12, 0) |
| INTEGERでID | 21億で枯渇 | BIGINT |
| CHARで固定長 | パディング問題 | TEXT |

### 命名

| やりがち | 問題 | 正解 |
|----------|------|------|
| プレフィックスなし | テーブルの性質が不明 | m_/t_ プレフィックス |
| キャメルケース | ダブルクォート必須に | スネークケース統一 |
| 略語乱用 | 可読性低下 | フルスペル推奨 |
| id だけのPK | JOINで曖昧 | {entity}_id |

### 制約

| やりがち | 問題 | 正解 |
|----------|------|------|
| FK制約なし | データ不整合 | 全FKに制約必須 |
| 全部CASCADE | 意図しない連鎖削除 | RESTRICTをデフォルトに |
| NULL許容しすぎ | 三値論理の罠 | 業務必須はNOT NULL |
| 制約名なし | ALTER/DROPで困る | fk_/chk_/uq_ 命名 |

### 設計

| やりがち | 問題 | 正解 |
|----------|------|------|
| 物理削除 | データ復旧不能 | status_idでソフトデリート |
| updated_at手動更新 | 更新漏れ | トリガーで自動化 |
| 監査カラムなし | 誰がいつ変えたか不明 | 4カラム必須 |
| 集計をJOINで毎回計算 | パフォーマンス劣化 | スナップショット方式 |
| パーティションなし | 大規模テーブルの性能劣化 | RANGE パーティション |

---

## DDLファイル構成 [MEDIUM]

実行順序が重要。FK依存を考慮して番号順に実行する。

| ファイル | 内容 | 依存 |
|----------|------|------|
| 001_create_tables.sql | 全テーブル + FK制約 | なし |
| 002_create_indexes.sql | 全インデックス | 001 |
| 003_create_comments.sql | 全コメント | 001 |
| 004_create_triggers.sql | 更新トリガー | 001 |
| 005_create_partitions.sql | パーティション | 001 |

---

## マイグレーション手順 [HIGH]

### カラム追加

```sql
-- 1. NULLABLEで追加（ロックなし）
ALTER TABLE m_influencers ADD COLUMN nickname TEXT;

-- 2. デフォルト値付きで追加（PG11以降ロックなし）
ALTER TABLE m_influencers ADD COLUMN is_verified BOOLEAN NOT NULL DEFAULT FALSE;

-- 3. NOT NULL + デフォルトなし（既存データの更新が先）
ALTER TABLE m_influencers ADD COLUMN nickname TEXT;
UPDATE m_influencers SET nickname = influencer_name WHERE nickname IS NULL;
ALTER TABLE m_influencers ALTER COLUMN nickname SET NOT NULL;
```

### カラム型変更

```sql
-- SMALLINT→INTEGERは安全、INTEGER→SMALLINTはデータ次第で失敗
ALTER TABLE m_influencers ALTER COLUMN status_id TYPE INTEGER;
```

### VARCHAR→TEXT移行

```sql
-- メタデータのみ変更。テーブルREWRITE不要で即完了
ALTER TABLE m_influencers ALTER COLUMN influencer_name TYPE TEXT;
-- 長さチェックが必要ならCHECK制約で
ALTER TABLE m_influencers ADD CONSTRAINT chk_name_length CHECK (length(influencer_name) <= 200);
```

### インデックス追加

```sql
-- CONCURRENTLY: テーブルロックなしで作成（本番推奨）
-- 注意: トランザクション内では使えない
CREATE INDEX CONCURRENTLY idx_influencers_email ON m_influencers(email_address);
```

### マイグレーションチェックリスト

- [ ] ALTER TABLE はロックが必要か確認
- [ ] 大テーブルのインデックス追加は CONCURRENTLY を使用
- [ ] NOT NULL制約の追加はデフォルト値セットが先
- [ ] FK追加は参照先テーブルにインデックスがあることを確認
- [ ] 本番実行前にステージングで実行時間を測定
- [ ] ロールバック手順を用意
- [ ] マイグレーション前後のデータ整合性テストを用意 → `testing-strategy` 参照
