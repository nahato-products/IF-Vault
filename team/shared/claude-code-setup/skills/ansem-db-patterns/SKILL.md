---
name: ansem-db-patterns
description: "PostgreSQL schema design patterns from a production system. Covers table naming (m_/t_ prefixes, entity-based PKs), data types (TEXT over VARCHAR, TIMESTAMPTZ, DECIMAL, BIGINT identity), constraints (FK delete policies, NOT NULL rules, CHECK), audit columns, updated_at triggers, optimistic locking, soft delete, period management, snapshot denormalization, polymorphic tables, dictionary vs COMMENT, JSONB/GIN, translation tables, RANGE partitioning, UPSERT, and index strategy. Use when designing tables, writing DDL, choosing FK delete policies, defining constraints, reviewing schema designs, planning migrations, selecting data types, implementing audit trails, or structuring aggregation tables. Does NOT cover query performance (supabase-postgres-best-practices) or auth/RLS policies (supabase-auth-patterns)."
user-invocable: false
---

# PostgreSQL DB Design Patterns

## Scope Boundary [CRITICAL]

| Topic | This Skill | Other Skill |
|-------|-----------|-------------|
| Table design, naming, types, constraints, FK policies | **Here** | - |
| Audit columns, soft delete, period management | **Here** | - |
| Partitioning, UPSERT, JSONB schema design | **Here** | - |
| Query optimization, EXPLAIN ANALYZE, indexing tuning | - | `supabase-postgres-best-practices` |
| Connection pooling, PgBouncer config | - | `supabase-postgres-best-practices` |
| RLS policy design, auth flows | - | `supabase-auth-patterns` |
| DB error handling in app layer | - | `error-handling-logging` |
| Schema migration safety in CI/CD | - | `ci-cd-deployment` |
| SQL injection, FK constraint bypass review | - | `security-review` |
| Zod schema ↔ DB type mapping, branded ID types | - | `typescript-best-practices` |
| Migration test strategy, seed data fixtures | - | `testing-strategy` |

## When to Apply

- PostgreSQLのテーブル設計・DDL作成
- 命名規則・データ型・制約の判断
- FK削除ポリシーの選択
- 監査ログ・履歴管理の設計
- パーティション・スケーリングの検討
- 既存スキーマのレビュー

## When NOT to Apply

- クエリパフォーマンスチューニング（EXPLAIN ANALYZE） → `supabase-postgres-best-practices`
- コネクション管理（pool size、timeout） → `supabase-postgres-best-practices`
- RLSポリシー設計・auth.uid()最適化 → `supabase-auth-patterns`
- ORMの設定（Prisma/TypeORM等のconfig）
- MySQL/SQLite等の他DB固有の最適化

---

## Part 1: 命名規則 [CRITICAL]

### 1. テーブルプレフィックス

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
CONSTRAINT fk_{table}_{column} FOREIGN KEY ...
CREATE INDEX idx_{table}_{column} ON ...
CREATE INDEX idx_{table}_{col1}_{col2} ON ...  -- 複合
CONSTRAINT uq_{table}_{column} UNIQUE ...
CONSTRAINT chk_{table}_{rule} CHECK ...
```

---

## Part 2: データ型 [CRITICAL]

### 4. 文字列はTEXT統一

`VARCHAR(n)` は使わない。PostgreSQLではTEXTとVARCHARに性能差がない。

- 長さ制限が必要なら `CHECK (length(col) <= n)`
- ALTER不要で運用が楽
- `VARCHAR(255)` のような根拠のない制限は避ける

### 5. 日時はTIMESTAMPTZ統一

`TIMESTAMP`（タイムゾーンなし）は使わない。

- グローバル展開・タイムゾーン変換が自動
- 全ての日時カラムに適用: `created_at`, `updated_at`, `assigned_at` 等

**DATE型の例外**: 時刻不要で日単位の精度で十分なケースだけ
- 有効期間: `valid_from` / `valid_to`
- 単価期間: `start_date` / `end_date`
- 集計日: `action_date`、入社日: `join_date`

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

- 必ず `NOT NULL` + `DEFAULT` を付ける → 三値論理（TRUE/FALSE/NULL）を回避
- 名前は `is_` プレフィックスで統一

---

## Part 3: 整合性と制約 [CRITICAL]

### 8. PK戦略

| 分類 | パターン | 条件 | 例 |
|------|----------|------|-----|
| 原則 | `BIGINT GENERATED ALWAYS AS IDENTITY` | 通常のテーブル | m_influencers, t_addresses |
| 例外 | 手動採番 | 数十件の固定マスタ | m_countries, m_agent_role_types |
| 例外 | 親PK共有 | 1対1リレーション | m_agent_security（agent_idがPKかつFK） |
| 例外 | 外部ID一致 | 外部システム連携 | m_partners_division（BQのIDに合わせる） |

→ アプリ層でIDの型安全性を担保するには `typescript-best-practices` のbranded typesパターンを活用

### 9. FK削除ポリシー

PostgreSQLのデフォルトはNO ACTIONだが、本規約ではRESTRICTを明示指定する（deferred制約時の挙動が異なるため）。

| ポリシー | いつ使うか | 実例 |
|----------|-----------|------|
| **RESTRICT** | 子データに独立した価値がある | 集計テーブル、単価、SNSアカウント |
| **CASCADE** | 親なしで意味がない子 | IF→住所・口座、1対1セキュリティ |
| **SET NULL** | 任意の参照を切る（NULLABLE FK） | パートナー→IF兼業、IF→国 |

判断フロー: 子に独立価値→RESTRICT、親なし無意味→CASCADE、NULLABLE任意→SET NULL。詳細フローチャートは reference.md 参照。

### 10. 監査カラム [HIGH]

全テーブルに4カラムを必須にする。

```sql
created_by BIGINT NOT NULL,
updated_by BIGINT NOT NULL,
created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
```

**例外（3パターン）**:
- 監査ログ自体: `operator_id` / `operated_at` で代替
- システムジョブログ: `started_at` / `finished_at` で代替
- 外部ID一致テーブル: `created_at` / `updated_at` のみ

`updated_at` は全テーブルにBEFORE UPDATEトリガーで自動更新。トリガー実装は reference.md 参照。

### 11. NULL許容ルール [HIGH]

| NULL許容 | 条件 | 例 |
|----------|------|-----|
| NOT NULL | PK、必須FK、監査カラム、業務必須 | influencer_id, created_at |
| NULLABLE | 任意項目、期間終了日、ルートノード | end_at, parent_id, country_id |

集計テーブルの特殊ルール:
- 次元カラム: `NOT NULL` + FK制約（DEFAULTなし）
- 集計値: `NOT NULL DEFAULT 0`

---

## Part 4: 同時実行と履歴 [HIGH]

### 12. 楽観ロック

同時編集が起きうるテーブルに `version INTEGER NOT NULL DEFAULT 1` を追加。

- 対象: ユーザーが直接編集するマスタ、期間管理テーブル
- 非対象: 集計テーブル（バッチ投入）、ログ系（追記のみ）
- アプリ側: `UPDATE ... WHERE id = ? AND version = ?` で競合検出。実装例は reference.md 参照

### 13. ソフトデリート

| 方式 | 用途 | 実装 |
|------|------|------|
| status_id | マスタテーブル全般 | `SMALLINT NOT NULL DEFAULT 1` + COMMENT |
| is_cancelled | 単一フラグで済むケース | `BOOLEAN NOT NULL DEFAULT FALSE` + CHECK |

```sql
-- 請求確定のキャンセル（CHECK制約でデータ整合性を担保）
is_cancelled BOOLEAN NOT NULL DEFAULT FALSE,
CONSTRAINT chk_billing_cancelled CHECK (
  (is_cancelled = FALSE) OR (cancelled_at IS NOT NULL)
)
```

### 14. 期間管理

```sql
start_at DATE NOT NULL,
end_at DATE,  -- NULLは無期限
```

- `end_at IS NULL` = 現在有効
- 重複チェックはアプリ層 or EXCLUDE制約で実施
- 担当割当は `assigned_at` / `unassigned_at` + `is_active` の3点セット

---

## Part 5: 高度なパターン [MEDIUM]

### 15. スナップショット+FK方式

FK（ID整合性）とスナップショットカラム（表示名固定）を両立。マスタ名が変わっても過去の集計値は影響を受けない。

```sql
-- 集計テーブル: FK + スナップショット
partner_name TEXT NOT NULL,      -- 集計時点の名前（非正規化）
partner_id BIGINT NOT NULL,      -- FK制約あり（RESTRICT: 集計データ保全）
```

→ `supabase-postgres-best-practices` のN+1排除と組み合わせると、JOINなしで集計表示が高速化

### 16. ポリモーフィック設計

```sql
-- 通知・ファイル・翻訳など横断的な機能で使用
entity_type TEXT NOT NULL,  -- 'influencer', 'partner', 'ad_content'
entity_id BIGINT NOT NULL,
```

注意: FK制約が張れない。`security-review` でバリデーション漏れをチェック。

### 17. 辞書テーブル判断

| 判断 | 条件 |
|------|------|
| テーブル作る | 階層構造、頻繁な追加・変更、関連属性が複数 |
| COMMENTで管理 | 10個未満、ほぼ固定、名前以外の属性なし |

```sql
COMMENT ON COLUMN t_addresses.address_type_id IS
  '住所タイプID（1: 自宅, 2: お届け先）';
```

### 18. パーティション戦略

| テーブル種別 | 分割単位 | パーティションキー |
|-------------|---------|------------------|
| 日次集計 | 年次 | action_date |
| 監査ログ | 月次 | operated_at |

目安: 単一テーブル1000万行超 or 月次増加100万行超で検討開始。3年超のデータはDETACH PARTITIONでアーカイブ。作成テンプレートは reference.md 参照。

### 19. UPSERT（冪等投入）

バッチ投入やデータパイプラインでは INSERT ... ON CONFLICT で冪等性を担保。

```sql
INSERT INTO t_daily_performance_details (action_date, partner_id, partner_name, count_value)
VALUES ($1, $2, $3, $4)
ON CONFLICT (action_date, partner_id)
DO UPDATE SET count_value = EXCLUDED.count_value,
             updated_at = CURRENT_TIMESTAMP;
```

→ `ci-cd-deployment` のバッチジョブワークフローと組み合わせて定期実行を自動化

### 20. JSONB活用パターン

| 用途 | 例 |
|------|-----|
| 監査ログの操作内容 | `change_detail JSONB` |
| 請求確定の抽出条件 | `filter_conditions JSONB` |
| 外部APIレスポンス保存 | `raw_response JSONB` |

```sql
CREATE INDEX idx_audit_logs_detail ON t_audit_logs USING GIN (change_detail);
SELECT * FROM t_audit_logs WHERE change_detail @> '{"table": "m_influencers"}';
```

ルール: 頻繁にWHEREで使うキーは通常カラムに昇格。JSONBは「構造が事前に決まらない」データ専用。GINインデックスの性能チューニングは `supabase-postgres-best-practices` 参照。

### 21. 多言語対応（翻訳テーブル方式）

既存テーブルを変更せずに多言語化。entity_type + entity_id で汎用参照（#16 と共通パターン）。

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

## Part 6: 型選択ガイド [MEDIUM]

### 22. インデックス設計判断

| 対象 | 優先度 | 理由 |
|------|--------|------|
| 全FK | 必須 | JOINとCASCADE/SET NULLの高速化 |
| 頻出WHERE句 | 必須 | Seq Scan回避 |
| ORDER BY | 推奨 | ソート高速化 |
| 部分インデックス `WHERE is_active = TRUE` | 効果大 | サイズ削減・速度向上 |
| GINインデックス | 特殊 | JSONB/@>演算子用 → #20 |

インデックス作成は `CREATE INDEX CONCURRENTLY`（本番無ロック）。複合インデックスのカラム順序最適化は `supabase-postgres-best-practices` 参照。

### 23. Enum vs SMALLINT+COMMENT

| 判断 | 条件 |
|------|------|
| SMALLINT+COMMENT（標準） | 値が固定（3-5個）、アプリ層で分岐 |
| PostgreSQL ENUM | 可読性重視、追加は `ALTER TYPE ADD VALUE` |
| マスタテーブル | 属性が複数（名前+表示順等）、JOIN先として使う |

SMALLINT+COMMENTを標準とする。ENUMは値の削除・順序変更が困難。

---

## Reference

DDLテンプレート（マスタ/トランザクション/集計/ポリモーフィック/1対1）、トリガー実装、パーティション作成、楽観ロック実装、UPSERTパターン集、チェックリスト、アンチパターン集、マイグレーション手順は [reference.md](reference.md) を参照。
