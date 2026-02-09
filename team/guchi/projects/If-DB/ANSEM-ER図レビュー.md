---
tags: [ANSEM, database, design, review]
created: 2026-02-06
updated: 2026-02-07
status: completed
related: "[[ANSEM-ER図]]"
---

# ANSEM DB設計書 レビュー結果

## レビュー概要

- **対象**: [[ANSEM-ER図|ANSEMプロジェクト データベース設計書 v1.0.0]]
- **レビュー日**: 2026-02-06
- **レビュー観点**: 設計一貫性・命名規則・実装可能性・スケーラビリティ

---

## 良い点

- **設計方針が明文化されている**: TEXT統一・TIMESTAMPTZ統一・監査カラム必須など、ルールが明確
- **パーティション戦略**: 集計テーブルの年次パーティションは実運用を見据えた実践的な設計
- **外部キー制約の方針**: ON DELETE RESTRICT 原則 + 集計テーブルは制約なしの判断が妥当
- **階層構造の設計**: カテゴリ・部署の親子構造がシンプルで扱いやすい
- **認証情報の分離**: セキュリティテーブルを1対1で分離しておりセキュリティ的に正しい
- **初期データ・サンプルクエリの充実**: 実用的で、導入時の参考になる

---

## 指摘事項

### 1. [重要] m_/t_ プレフィックスの分類が不統一

設計方針での定義:
- `m_` = 固定データ、あまり変更されない
- `t_` = 可変データ、状態が変化する

実際の分類と本来あるべき分類:

| テーブル | 現在 | 推奨 | 理由 |
|---------|------|------|------|
| `m_addresses` | m_ | **t_** | IF毎に追加・変更される業務データ |
| `m_bank_accounts` | m_ | **t_** | 同上 |
| `m_billing_info` | m_ | **t_** | 同上 |
| `m_influencer_sns_accounts` | m_ | **t_** | フォロワー数など頻繁に更新される |
| `m_influencer_agent_assignments` | m_ | **t_** | 担当変更=状態変化そのもの |
| `m_account_categories` | m_ | **t_** | アカウントに紐づく可変データ |
| `m_audit_logs` | m_ | **t_** | ログは完全にトランザクションデータ |
| `t_influencers` | t_ | **m_** | プロフィール=マスタ寄りのデータ |

> [!IMPORTANT]
> 分類基準が曖昧だと、後から参加するメンバーが命名規則を正しく適用できなくなる。
> 分類基準を再定義するか、各テーブルのプレフィックスを見直すべき。

---

### 2. [重要] ER図のリレーションに誤りがある

ER図内の以下のリレーション:

```
m_agents ||--o{ m_agent_role_types : "role_type_id"
```

実際のテーブル定義では `m_agents` に `role_type_id` カラムは存在しない。
`role_type_id` を持つのは `m_influencer_agent_assignments` テーブル。

> [!WARNING]
> ER図とDDLの不一致は設計書としての信頼性に関わる致命的な問題。
> ER図を修正し、DDLとの整合性を確認すべき。

---

### 3. [重要] updated_at の自動更新トリガーが未定義

全テーブルに以下の定義があるが:

```sql
updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
```

`DEFAULT` はINSERT時にしか適用されない。UPDATE時に `updated_at` を自動更新するトリガーが設計書に含まれていない。

必要なトリガー定義:

```sql
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

> [!WARNING]
> 実装フェーズで確実に問題になるため、設計段階でトリガー定義を含めるべき。

---

### 4. [中] カラム命名の不統一

設計方針で「参照先のテーブル名_id 形式」と定めているが、以下が違反している:

| カラム | テーブル | 問題点 | 推奨 |
|-------|---------|--------|------|
| `country_type_id` | m_addresses, m_bank_accounts | 参照先は `m_countries.country_id`。"type" ではない | `country_id` |
| `person_id` | m_ad_contents | 参照先は `m_agents.agent_id` | `agent_id` |

---

### 5. [中] 自己ルール違反: 監査カラム

設計方針「監査カラム（全テーブル必須）」に対して、`m_audit_logs` に `created_by`, `updated_by`, `created_at`, `updated_at` の4カラムがない。

`operator_id` と `operated_at` で代替しているが、ルールとの整合性が取れていない。

**対応案:**
- 監査ログテーブルを例外としてルールに明記する
- または4カラムを追加する（ただし監査ログに監査カラムは冗長）

---

### 6. [中] 自己ルール違反: 主キーのID生成

チェックリストに「主キーはGENERATED ALWAYS AS IDENTITYか」とあるが、以下は手動ID/FK主キー:

- `m_countries` (SMALLINT PK, 手動採番)
- `m_agent_role_types` (SMALLINT PK, 手動採番)
- `m_agent_security` (agent_id PK/FK)
- `m_influencer_security` (influencer_id PK/FK)

例外が存在すること自体は妥当だが、チェックリスト側に例外ルールを明記すべき。

---

### 7. [中] ソフトデリートの方針が不統一

現状、削除表現が3パターン混在している:

1. `is_active` (BOOLEAN) のみ
2. `status_id` で「終了」「削除済」を表現
3. `is_active` と `status_id` の両方を保持（`t_influencers` 等）

パターン3の場合、以下の区別が不明確:
- `is_active = FALSE` の意味
- `status_id = 3（契約終了）` の意味
- 両者の組み合わせルール

> [!NOTE]
> 二重管理になるリスクがある。
> `is_active` は `status_id` から導出可能なケースが多いため、
> どちらをマスターとするか方針を定めるべき。

---

### 8. [中] 排他制御・楽観ロックの仕組みがない

複数ユーザーの同時操作が前提のシステムだが、`version` カラム（楽観ロック用）が全テーブルに存在しない。

特に競合が起きやすいテーブル:
- `t_unit_prices` - 単価変更の同時操作
- `t_campaign_influencers` - ステータス更新
- `t_influencers` - プロフィール編集

**対応案:**

```sql
-- 楽観ロック用カラムを追加
version INTEGER NOT NULL DEFAULT 1

-- UPDATE時にバージョンチェック
UPDATE t_unit_prices
SET unit_price = :new_price, version = version + 1
WHERE unit_price_id = :id AND version = :expected_version;
```

---

### 9. [低] password_salt カラムの必要性

`m_agent_security` と `m_influencer_security` に `password_salt` カラムがあるが、bcrypt / argon2 など現代的なハッシュアルゴリズムはソルトをハッシュ値に内包する。

使用するハッシュアルゴリズムの方針が未定義のまま、中途半端な設計になっている。

**対応案:**
- 使用ハッシュアルゴリズムを明記する
- bcrypt/argon2 採用なら `password_salt` カラムを削除

---

### 10. [低] スケーリング観点の欠如

以下の観点が設計書に含まれていない:

- **コネクションプーリング**: PgBouncer等の利用方針
- **リードレプリカ**: 参照系クエリの分散
- **m_audit_logs の肥大化対策**: 全テーブルの履歴が集中するため、最も早く肥大化するテーブル。パーティション化の検討が必要
- **集計テーブル以外の大規模化対策**: IF数・キャンペーン数が増えた場合の方針

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

#### 11. [重要] ユーザー種別の拡張に弱い

認証テーブルがユーザー種別ごとに分離されている:
- `m_agent_security`（エージェント用）
- `m_influencer_security`（IF用）

将来、以下のようなケースで認証テーブルが増え続ける:
- クライアント側担当者がログインしてレポート閲覧
- パートナー側担当者が実績入力

**改善案**: 共通ユーザーテーブル + ロールベースアクセス制御（RBAC）

```sql
-- 統合ユーザーテーブル
m_users (user_id, user_type, email, ...)
m_user_security (user_id, password_hash, ...)
m_user_roles (user_id, role_id, ...)
```

---

#### 12. [重要] 住所・口座がインフルエンサー専用

`m_addresses` と `m_bank_accounts` の外部キーが `t_influencers` に固定されている。

```sql
CONSTRAINT fk_address_influencer
  FOREIGN KEY (influencer_id) REFERENCES t_influencers
```

パートナーやクライアントにも住所・口座が必要になった場合、テーブルの複製か構造変更が必要。

**改善案**: ポリモーフィック関連

```sql
m_addresses (
  owner_type TEXT,  -- 'influencer', 'partner', 'client'
  owner_id BIGINT,
  ...
)
```

---

#### 13. [中] 単価設定の柔軟性が低い

`t_unit_prices` は `site_id` + `content_id` + `client_id` の組み合わせのみ。

将来的に必要になりうる単価パターン:
- IF別の単価（人気IFは単価UP）
- カテゴリ別の単価
- 時間帯別の単価
- ボリュームディスカウント（月100件以上で単価DOWN）

現在の構造ではカラム追加 or テーブル追加が必要。

**改善案**: 単価ルールテーブルの分離

```sql
t_pricing_rules (
  rule_id, rule_type,  -- 'site', 'content', 'influencer', 'volume'
  condition JSONB,      -- 柔軟な条件定義
  unit_price DECIMAL,
  priority INTEGER,     -- 優先順位
  ...
)
```

---

#### 14. [中] キャンペーン構造が単純すぎる

現実の広告運用で必要になる構造:
- キャンペーン → 複数のフライト（配信期間）
- フライト → 予算配分
- IF1人が複数のコンテンツを配信
- KPI目標値の管理

現在の `t_campaigns` → `t_campaign_influencers` は1階層のみで、複雑な運用に耐えられない。

---

#### 15. [中] 多言語対応ができない

名前カラムが全テーブルで単一言語のみ:

```sql
category_name TEXT  -- 日本語のみ
platform_name TEXT  -- 日本語のみ
```

国マスタ（ISO準拠）で国際化の基盤はあるが、UIレベルの多言語対応は不可能。

**改善案**:

```sql
-- JSONB方式
category_name JSONB  -- {"ja": "ファッション", "en": "Fashion"}

-- または翻訳テーブル方式
m_translations (table_name, record_id, column_name, lang, value)
```

---

#### 16. [低] ファイル・メディア管理がない

以下のようなファイル管理テーブルが存在しない:
- IFのプロフィール画像
- 広告素材（クリエイティブ）
- 契約書PDF
- キャンペーン関連資料

実運用では確実に必要になる領域。

---

#### 17. [低] 通知・メッセージ機能がない

キャンペーンのワークフロー（依頼→承諾→完了）は `status_id` で管理されているが、通知履歴や連絡メッセージを管理する仕組みがない。

---

### 拡張性の総合評価

| 観点 | 評価 | 理由 |
|------|------|------|
| マスタデータの追加 | 高い | INSERTで対応可能な構造 |
| 新しいユーザー種別 | **低い** | 認証テーブルがユーザー種別固定 |
| 住所・口座の共有化 | **低い** | IF専用の外部キー |
| 単価設定の複雑化 | 中 | カラム追加で対応可能だが限界あり |
| キャンペーンの深化 | 中 | 中間テーブル追加で対応可能 |
| 多言語対応 | **低い** | テーブル構造の変更が必要 |
| データ量の増加 | 高い | パーティション対応済み |
| ファイル管理 | **なし** | テーブル自体が存在しない |
| 通知・メッセージ | **なし** | テーブル自体が存在しない |

> [!IMPORTANT]
> 「今あるものの量を増やす」のは得意だが、「今ないものを新しく入れる」のは構造変更を伴うケースが多い。
> 特にユーザー認証の統合と、住所・口座のポリモーフィック化は、早期に対応するほど影響範囲が小さい。

---

## 総評

| 観点 | 評価 |
|------|------|
| 体裁・網羅性 | 高い。初期データ・サンプルクエリまで充実 |
| 設計方針の明確さ | 高い。ルールが明文化されている |
| ルールとの一貫性 | **低い。自分で定めたルールを複数箇所で違反** |
| 命名の統一性 | 中。一部不統一あり |
| 実装可能性 | 中。トリガー・楽観ロック等の欠如あり |
| 拡張性 | **中〜低。量の拡張は得意だが、新機能追加に構造変更が必要** |
| スケーラビリティ | 低。将来の成長に対する考慮が不足 |

設計書としての体裁と網羅性はかなり高い。
ただし、**自分で定めたルールとの一貫性** が最大の弱点。
命名規則・m_/t_分類・監査カラムルールなど、定義したルールに対する違反が複数存在する。
これではルールを定めた意義が薄れ、レビュー側も「どこまでがルールでどこからが例外か」判断できない。

**最優先で対応すべき項目:**
1. m_/t_ プレフィックス分類の見直し
2. ER図とDDLの整合性確認
3. updated_at 自動更新トリガーの追加
4. ユーザー認証の統合設計（RBAC化）
5. 住所・口座のポリモーフィック化検討

---

**レビュー日**: 2026-02-06
**レビュアー**: Claude Code (AI Review)
