---
name: ansem-db-patterns
description: Guides PostgreSQL database design using battle-tested patterns from a 32-table production system. Covers naming conventions, data type discipline, FK delete policies, optimistic locking, snapshot patterns, partitioning, and scaling strategies. Use when designing database schemas, creating tables, writing DDL, defining foreign keys, choosing data types, implementing audit trails, setting up partitions, planning scaling strategies, reviewing database designs, or making schema decisions.
user-invocable: false
---

# PostgreSQL DB Design Patterns

32テーブル・5本のDDLで実証済みの設計パターン集。判断に迷ったらここを見る。

## When to Apply

- PostgreSQLのテーブル設計・DDL作成
- 命名規則・データ型・制約の判断
- FK削除ポリシーの選択
- 監査ログ・履歴管理の設計
- パーティション・スケーリングの検討
- 既存スキーマのレビュー

## When NOT to Apply

- MySQL/SQLite等の他DB固有の最適化
- アプリケーション層のビジネスロジック
- ORMの設定（Prisma/TypeORM等のconfig）
- パフォーマンスチューニング（EXPLAIN ANALYZE等）→ supabase-postgres-best-practicesを参照

---

## Part 1: 命名規則 [CRITICAL]

### 1. テーブルプレフィックス

用途でプレフィックスを分ける。一目で性質がわかる。

| プレフィックス | 用途 | 例 |
|---------------|------|-----|
| `m_` | マスタ（固定・低頻度更新） | m_countries, m_agents |
| `t_` | トランザクション（業務データ・高頻度更新） | t_addresses, t_unit_prices |
| なし | システムテーブル | ingestion_logs |

判断基準: データが「定義」なら `m_`、「イベント・状態変化」なら `t_`。

### 2. カラム命名

- PK: `{entity}_id`（テーブル名ではなくエンティティ名）
- FK: 参照先の `{entity}_id` をそのまま使う
- 複合語: スネークケース（`email_address`, `follower_count`）
- 真偽値: `is_` プレフィックス（`is_active`, `is_cancelled`）
- 日時: `_at` サフィックス（`created_at`, `assigned_at`）
- 日付: `_date` サフィックス（`action_date`, `join_date`）

### 3. 制約・インデックス命名

```sql
-- FK制約
CONSTRAINT fk_{table}_{column} FOREIGN KEY ...

-- インデックス
CREATE INDEX idx_{table}_{column} ON ...
CREATE INDEX idx_{table}_{col1}_{col2} ON ...  -- 複合

-- ユニーク制約
CONSTRAINT uq_{table}_{column} UNIQUE ...
```

---

## Part 2: データ型 [CRITICAL]

### 4. 文字列はTEXT統一

`VARCHAR(n)` は使わない。PostgreSQLではTEXTとVARCHARに性能差がない。

- 長さ制限はアプリ層で実施
- ALTER不要で運用が楽
- `VARCHAR(255)` のような「とりあえず」の制限は害しかない

### 5. 日時はTIMESTAMPTZ統一

`TIMESTAMP`（タイムゾーンなし）は使わない。

- グローバル展開・タイムゾーン変換が自動
- 全ての日時カラムに適用: `created_at`, `updated_at`, `assigned_at` 等

**DATE型の例外**: 時刻不要で日単位の精度で十分なケースだけ
- 有効期間: `valid_from` / `valid_to`
- 単価期間: `start_at` / `end_at`
- 集計日: `action_date`
- 入社日: `join_date`

### 6. 数値型の使い分け

| 用途 | 型 | 理由 |
|------|-----|------|
| ID（通常） | `BIGINT GENERATED ALWAYS AS IDENTITY` | 自動採番、枯渇リスクなし |
| ID（小マスタ） | `SMALLINT` 手動採番 | 国・役割など数十件 |
| 金額 | `DECIMAL(12, 0)` | 整数円、浮動小数点誤差なし |
| カウント | `INTEGER` or `BIGINT` | データ量次第 |
| ステータスコード | `SMALLINT` | 種類が少ない |

### 7. BOOLEAN設計

```sql
is_active BOOLEAN NOT NULL DEFAULT TRUE
```

- 必ず `NOT NULL` + `DEFAULT` を付ける
- 名前は `is_` プレフィックスで統一
- 三値論理（TRUE/FALSE/NULL）を避ける

---

## Part 3: 整合性と制約 [HIGH]

### 8. PK戦略

原則は `BIGINT GENERATED ALWAYS AS IDENTITY`。例外は3パターンだけ。

| パターン | 条件 | 例 |
|----------|------|-----|
| 自動採番 | 通常のテーブル | m_influencers, t_addresses |
| 手動採番 | 数十件の固定マスタ | m_countries, m_agent_role_types |
| 親PK共有 | 1対1リレーション | m_agent_security（agent_idがPKかつFK） |
| 外部ID一致 | 外部システム連携 | m_partners_division（BQのIDに合わせる） |

### 9. FK削除ポリシー

3つのポリシーを明確に使い分ける。デフォルトは RESTRICT。

| ポリシー | いつ使うか | 実例 |
|----------|-----------|------|
| **RESTRICT** | 参照データを保全したい | 集計テーブル、単価、SNSアカウント、担当割当 |
| **CASCADE** | 親と運命を共にする子 | IF→住所・口座・請求先、1対1セキュリティ、SNS→カテゴリ紐付け |
| **SET NULL** | 任意の参照を切る | パートナー→IF兼業、IF→国、広告→担当者 |

判断フロー:
1. 子データに独立した価値があるか？ → YES: RESTRICT
2. 親削除時に子が意味をなさなくなるか？ → YES: CASCADE
3. 参照がNULLABLEで任意か？ → YES: SET NULL

### 10. 監査カラム

全テーブルに4カラムを必須にする。

```sql
created_by BIGINT NOT NULL,
updated_by BIGINT NOT NULL,
created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
```

**例外（3パターン）**:
- 監査ログ自体: `operator_id` / `operated_at` で代替（自己参照は冗長）
- システムジョブログ: `started_at` / `finished_at` で代替（人の操作ではない）
- 外部ID一致テーブル: `created_at` / `updated_at` のみ（一括インポート用）

`updated_at` の自動更新トリガーは全テーブルに設定する（上記例外除く）。

```sql
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

### 11. NULL許容ルール

| NULL許容 | 条件 | 例 |
|----------|------|-----|
| NOT NULL | PK、必須FK、監査カラム、業務必須 | influencer_id, created_at |
| NULLABLE | 任意項目、期間終了日、ルートノード、オプション設定 | end_at, parent_id, country_id |

集計テーブルの特殊ルール:
- 次元カラム: `NOT NULL` + FK制約（DEFAULTなし。不明データを入れさせない）
- 集計値: `NOT NULL DEFAULT 0`（NULLと0を区別しない）

---

## Part 4: 同時実行と履歴 [HIGH]

### 12. 楽観ロック

同時編集が起きうるテーブルに `version` カラムを追加する。

```sql
version INTEGER NOT NULL DEFAULT 1
```

対象: ユーザーが直接編集するマスタ、期間管理テーブル。
非対象: 集計テーブル（バッチ投入）、ログ系（追記のみ）。

アプリ側: `UPDATE ... WHERE id = ? AND version = ?` で競合検出。

### 13. ソフトデリート

物理削除ではなく状態管理で論理削除する。方式は2つ。

| 方式 | 用途 | 実装 |
|------|------|------|
| status_id | マスタテーブル全般 | `SMALLINT NOT NULL DEFAULT 1` + COMMENT |
| is_cancelled | 単一フラグで済むケース | `BOOLEAN NOT NULL DEFAULT FALSE` + CHECK |

```sql
-- 請求確定のキャンセル
is_cancelled BOOLEAN NOT NULL DEFAULT FALSE,
CONSTRAINT chk_billing_cancelled CHECK (
  (is_cancelled = FALSE) OR (cancelled_at IS NOT NULL)
)
```

### 14. 期間管理

有効期間を持つデータの設計パターン。

```sql
start_at DATE NOT NULL,
end_at DATE,  -- NULLは無期限
```

- `end_at IS NULL` = 現在有効
- 重複チェックはアプリ層 or EXCLUDE制約で実施
- 担当割当は `assigned_at` / `unassigned_at` + `is_active` の3点セット

---

## Part 5: 高度なパターン [MEDIUM]

### 15. スナップショット方式

集計データにマスタの名前を非正規化して保存する。マスタが後から変わっても過去の集計が壊れない。

```sql
-- 集計テーブル
partner_name TEXT NOT NULL,      -- 集計時点の名前
site_name TEXT NOT NULL,         -- 集計時点の名前
partner_id BIGINT NOT NULL,      -- FK制約あり（ID整合性は担保）
```

FKとスナップショットの併用がポイント。IDの整合性はFKで担保し、表示名はスナップショットで固定する。

### 16. ポリモーフィック設計

1つのテーブルで複数のエンティティに紐付ける。

```sql
-- 通知テーブル
user_type TEXT NOT NULL,    -- 'agent', 'influencer', 'partner'
user_id BIGINT NOT NULL,

-- ファイル管理
entity_type TEXT NOT NULL,  -- 'influencer', 'partner', 'ad_content'
entity_id BIGINT NOT NULL,
```

使いどころ: 通知、ファイル、翻訳など横断的な機能。
注意: FK制約が張れない。アプリ層でバリデーション必須。

### 17. 辞書テーブル判断

マスタテーブルを作るかCOMMENTで済ませるかの判断。

| 判断 | 条件 |
|------|------|
| テーブル作る | 階層構造、頻繁な追加・変更、関連属性が複数 |
| COMMENTで管理 | 10個未満、ほぼ固定、名前以外の属性なし |

```sql
-- COMMENTで十分なケース
COMMENT ON COLUMN t_addresses.address_type_id IS
  '住所タイプID（1: 自宅, 2: お届け先）';
```

### 18. パーティション戦略

データ量が増え続けるテーブルに RANGE パーティションを適用する。

| テーブル種別 | 分割単位 | パーティションキー |
|-------------|---------|------------------|
| 日次集計 | 年次 | action_date |
| 監査ログ | 月次 | operated_at |

```sql
CREATE TABLE t_daily_performance_details (
  ...
) PARTITION BY RANGE (action_date);

CREATE TABLE t_daily_performance_details_2025
  PARTITION OF t_daily_performance_details
  FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');
```

アーカイブ: 3年超のデータはDETACH PARTITIONでコールドストレージに移行。

### 19. 多言語対応（翻訳テーブル方式）

既存テーブルのカラムを変更せずに多言語化する。

```sql
CREATE TABLE t_translations (
  translation_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  table_name TEXT NOT NULL,
  record_id BIGINT NOT NULL,
  column_name TEXT NOT NULL,
  language_code TEXT NOT NULL,
  translated_text TEXT NOT NULL,
  UNIQUE (table_name, record_id, column_name, language_code)
);
```

既存テーブルにカラム追加不要。どのテーブルのどのカラムでも翻訳できる汎用性。

---

## Part 6: スケーリング [MEDIUM]

### 20. インデックス設計

| 優先度 | 対象 |
|--------|------|
| 必須 | 全FK、頻出WHERE句、JOIN条件 |
| 推奨 | 複合検索（複合インデックス）、ORDER BY |
| 効果大 | 部分インデックス（`WHERE is_active = TRUE`） |
| 特殊 | GINインデックス（JSONB検索用） |

### 21. 接続プーリング

PgBouncerでトランザクションプーリング。アプリからの同時接続数を制御する。PostgreSQLは接続ごとにプロセスを生成するため、直接接続は100-200が限界。

### 22. リードレプリカ

ダッシュボード・検索・レポート等の読み取りクエリをレプリカに分散する。書き込みはプライマリのみ。

---

## Reference

テーブル設計テンプレート、DDLサンプル、チェックリスト、アンチパターン集は [reference.md](reference.md) を参照。
