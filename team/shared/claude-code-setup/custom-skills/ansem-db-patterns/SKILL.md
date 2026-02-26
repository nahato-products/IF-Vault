---
name: ansem-db-patterns
description: PostgreSQL schema design patterns from a 32-table production system. Covers naming (m_/t_ prefixes), data types (TEXT/TIMESTAMPTZ/DECIMAL), constraints (FK delete policies, NULL rules, boolean design, CHECK), audit columns, optimistic locking, soft delete, period management, snapshot+FK pattern, polymorphic tables, dictionary vs COMMENT, translations, JSONB with GIN, partitioning, UPSERT, and index strategies. Use when designing tables, writing DDL, choosing FK policies, managing NULLability, reviewing schemas, or planning migrations. Do not trigger for MySQL/SQLite-specific optimization, application-layer business logic, or ORM config (use supabase-postgres-best-practices for query tuning).
user-invocable: false
triggers:
  - テーブル設計をする
  - DDLを書く
  - FKの削除ポリシーを決める
  - スキーマをレビューする
  - マイグレーションを計画する
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
- クエリパフォーマンスチューニング（EXPLAIN ANALYZE、実行計画分析）→ supabase-postgres-best-practices参照
- コネクション管理（pool size、timeout、プーリング方式）→ neon-postgres参照
- リードレプリカ構成・読み書き分離 → neon-postgres参照

## 他スキルとの棲み分け

| スキル | このスキルの役割 | そのスキルの役割 |
|--------|----------------|----------------|
| supabase-postgres-best-practices | テーブル設計・制約・命名の判断基準 | クエリ最適化・実行計画・パフォーマンス |
| neon-postgres | DDL・マイグレーション・パーティション | 接続管理・ブランチング・サーバーレス設定 |

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

- 長さ制限はアプリ層で実施。DB層で必要なら `CHECK (length(col) <= n)` を使う
- ALTER不要で運用が楽
- `VARCHAR(255)` のような根拠のない制限は避ける

### 5. 日時はTIMESTAMPTZ統一

`TIMESTAMP`（タイムゾーンなし）は使わない。

- グローバル展開・タイムゾーン変換が自動
- 全ての日時カラムに適用: `created_at`, `updated_at`, `assigned_at` 等

**DATE型の例外**: 時刻不要で日単位の精度で十分なケースだけ
- 有効期間: `valid_from` / `valid_to`（`_from`/`_to` は期間の開始終了を示す慣例的サフィックス）
- 単価期間: `start_date` / `end_date`
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

原則は `BIGINT GENERATED ALWAYS AS IDENTITY`。例外は3パターン。

| 分類 | パターン | 条件 | 例 |
|------|----------|------|-----|
| 原則 | 自動採番 | 通常のテーブル | m_influencers, t_addresses |
| 例外 | 手動採番 | 数十件の固定マスタ | m_countries, m_agent_role_types |
| 例外 | 親PK共有 | 1対1リレーション | m_agent_security（agent_idがPKかつFK） |
| 例外 | 外部ID一致 | 外部システム連携 | m_partners_division（BQのIDに合わせる） |

### 9. FK削除ポリシー

3つのポリシーを明確に使い分ける。PostgreSQLのデフォルトは NO ACTION だが、本規約では明示的に RESTRICT を指定する（deferred制約時の挙動が異なるため）。

| ポリシー | いつ使うか | 実例 |
|----------|-----------|------|
| **RESTRICT** | 参照データを保全したい | 集計テーブル、単価、SNSアカウント、担当割当 |
| **CASCADE** | 親と運命を共にする子 | IF→住所・口座・請求先、1対1セキュリティ、SNS→カテゴリ紐付け |
| **SET NULL** | 任意の参照を切る | パートナー→IF兼業、IF→国、広告→担当者 |

判断フロー: 子データに独立した価値がある→RESTRICT、親なしで意味なし→CASCADE、参照がNULLABLEで任意→SET NULL。詳細フローチャートは reference.md 参照。

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

`updated_at` は全テーブルにBEFORE UPDATEトリガーで自動更新（例外除く）。

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

対象: ユーザーが直接編集するマスタ、期間管理テーブル（`version INTEGER NOT NULL DEFAULT 1`）。
非対象: 集計テーブル（バッチ投入）、ログ系（追記のみ）。
アプリ側: `UPDATE ... WHERE id = ? AND version = ?` で競合検出。実装例は reference.md 参照。

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

FK（ID整合性）とスナップショットカラム（表示名固定）を両立させる。マスタ名が後から変わっても過去の集計値は影響を受けない。→ #9 FK制約と併用

```sql
-- 集計テーブル: FK（ID整合性）+ スナップショット（表示名固定）
partner_name TEXT NOT NULL,      -- 集計時点の名前
site_name TEXT NOT NULL,         -- 集計時点の名前
partner_id BIGINT NOT NULL,      -- FK制約あり（RESTRICT: 集計データ保全）
```

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

目安: 単一テーブル1000万行超 or 月次増加100万行超で検討開始。
アーカイブ: 3年超のデータはDETACH PARTITIONでコールドストレージに移行。

### 19. UPSERT（冪等投入）

バッチ投入やデータパイプラインでは INSERT ... ON CONFLICT で冪等性を担保する。→ #12 楽観ロックと組み合わせ

```sql
INSERT INTO t_daily_performance_details (action_date, partner_id, partner_name, count_value)
VALUES ($1, $2, $3, $4)
ON CONFLICT (action_date, partner_id)
DO UPDATE SET count_value = EXCLUDED.count_value,
             updated_at = CURRENT_TIMESTAMP;
-- ※ updated_at トリガー(#10)がある場合、SET句のupdated_atは不要
```

再実行しても結果が変わらないので障害復旧時に安全。

### 20. JSONB活用パターン

構造が可変・スキーマレスなデータにJSONBを使う。→ GINインデックスで検索可能

| 用途 | 例 |
|------|-----|
| 監査ログの操作内容 | `change_detail JSONB` |
| 請求確定の抽出条件 | `filter_conditions JSONB` |
| 外部APIレスポンス保存 | `raw_response JSONB` |

```sql
-- GINインデックスで@>演算子（包含検索）を高速化
CREATE INDEX idx_audit_logs_detail ON t_audit_logs USING GIN (change_detail);
-- @>: 左辺が右辺を包含するか判定
SELECT * FROM t_audit_logs WHERE change_detail @> '{"table": "m_influencers"}';
```

注意: 頻繁にWHEREで使うキーは通常カラムに昇格させる。JSONBは「構造が事前に決まらない」データ専用。

### 21. 多言語対応（翻訳テーブル方式）

既存テーブルのカラムを変更せずに多言語化する。entity_type + entity_id で汎用的に参照する点は #16 と共通。

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

---

## Part 6: スケーリング [MEDIUM]

### 22. インデックス設計

- 必須: 全FK、頻出WHERE句、JOIN条件
- 推奨: 複合検索（複合インデックス）、ORDER BY
- 効果大: 部分インデックス（`WHERE is_active = TRUE`）
- 特殊: GINインデックス（JSONB検索用）→ #20

### 23. Enum vs SMALLINT+COMMENT

| 判断 | 条件 |
|------|------|
| SMALLINT+COMMENT | 値が固定（3-5個）、アプリ層で分岐 |
| PostgreSQL ENUM | 値の可読性を重視、追加は `ALTER TYPE ADD VALUE` で可能 |
| マスタテーブル | 属性が複数（名前+表示順等）、JOIN先として使う |

本規約ではSMALLINT+COMMENTを標準とする。ENUMは値の削除・順序変更が困難なため。

---

## Reference

コード例（トリガー、パーティション、UPSERT）、テンプレート、マイグレーション手順、チェックリスト、アンチパターン集は [reference.md](reference.md) を参照。

## Cross-references

- **supabase-postgres-best-practices**: クエリチューニング・RLS最適化
- **error-handling-logging**: DB層のエラーハンドリング
