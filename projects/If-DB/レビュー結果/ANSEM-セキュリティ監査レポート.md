---
date: 2026-02-14
tags: [IF-DB, ANSEM, セキュリティ, 監査, PostgreSQL]
status: active
---

# ANSEM DB セキュリティ監査レポート

32テーブル・5つのDDLファイル（001〜005）を対象に、OWASP Top 10とPostgreSQLセキュリティベストプラクティスの観点から監査した。

---

## 総合評価

| 観点 | 評価 |
|------|------|
| データ整合性 | A（FK制約・CHECK制約・UNIQUE制約が網羅的） |
| 監査追跡性 | A（全テーブルにcreated_by/updated_by、t_audit_logsで変更履歴記録） |
| 認証設計 | B（アカウントロックあり、ただしトークンのハッシュ化が未確認） |
| 機密データ保護 | C（銀行口座・PII情報が平文TEXT、暗号化なし） |
| アクセス制御 | D（RLS未設定、GRANT/REVOKE未定義） |
| インフラ安全性 | B（パーティション関数のSQL組み立てが安全、search_pathが未設定） |

---

## CRITICAL（対処必須）

### 1. Row Level Security（RLS）が未設定

どのテーブルにも `ENABLE ROW LEVEL SECURITY` がない。Supabase上で運用する場合、RLS無しだとanon/authenticated roleで全行読み書き可能になる。

アプリケーション層でアクセス制御する設計であっても、DBレベルの防御がないとAPIの認可バイパスで全データ漏洩する。

**対処案**: 最低限、以下のテーブルにRLSポリシーを設定する。
- m_agent_security / m_influencer_security（認証情報）
- t_bank_accounts（銀行口座）
- t_addresses（住所）
- t_billing_info（請求情報）
- t_audit_logs（監査ログ）

### 2. セッショントークンが平文保存

`m_agent_security.session_token` と `m_influencer_security.session_token` が `TEXT` 型でそのまま格納されている。DBダンプやログに平文トークンが残ると、セッションハイジャックに直結する。

**対処案**: トークンはSHA-256でハッシュ化して保存する。検証時もハッシュ比較にする。

```sql
-- 保存時
UPDATE m_agent_security
SET session_token = encode(digest(raw_token, 'sha256'), 'hex')
WHERE agent_id = $1;

-- 検証時
SELECT agent_id FROM m_agent_security
WHERE session_token = encode(digest($1, 'sha256'), 'hex')
  AND session_expires_at > CURRENT_TIMESTAMP;
```

### 3. パスワードリセットトークンが平文保存

`password_reset_token` も同様。リセットトークンが漏洩するとアカウント乗っ取りが可能。

**対処案**: セッショントークンと同じくハッシュ化保存。

### 4. 銀行口座情報が暗号化されていない

`t_bank_accounts` の `account_number`、`iban`、`swift_bic_code`、`routing_number` が全て平文 `TEXT`。金融情報の平文保存はPCI DSSの観点で不適合。

**対処案**: pgcryptoの `pgp_sym_encrypt` / `pgp_sym_decrypt` でカラムレベル暗号化を導入する。暗号化キーはDB外（Vault等）で管理する。

```sql
-- 例: 暗号化して保存
UPDATE t_bank_accounts
SET account_number = pgp_sym_encrypt($1, current_setting('app.encryption_key'))
WHERE bank_account_id = $2;
```

---

## HIGH（早期対処推奨）

### 5. GRANT/REVOKE文が未定義

DDL全体にGRANT/REVOKEが一切ない。デフォルトではスーパーユーザーやpublic roleがフルアクセスを持つ。

**対処案**: 専用ロールを作成して最小権限を割り当てる。

```sql
-- アプリケーション用ロール
CREATE ROLE app_user;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO app_user;
REVOKE DELETE ON m_agent_security FROM app_user;

-- 読み取り専用ロール（レポート用）
CREATE ROLE readonly_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly_user;

-- 監査ログは追記のみ
REVOKE UPDATE, DELETE ON t_audit_logs FROM app_user;
```

### 6. パーティション関数に `search_path` 未設定

`create_audit_log_partition`、`create_daily_partitions`、`list_audit_log_partitions_to_archive` の3関数全てに `SET search_path` がない。search_path操作攻撃でスキーマハイジャックされる可能性がある。

**対処案**: 全関数に `SET search_path = public, pg_temp` を追加。

```sql
CREATE OR REPLACE FUNCTION create_audit_log_partition(target_month DATE)
RETURNS TEXT
LANGUAGE plpgsql
SET search_path = public, pg_temp  -- 追加
AS $$
...
```

### 7. IP アドレスのデータ型

`m_influencers.submission_ip_address` と `t_audit_logs.operator_ip` が `TEXT` 型。PostgreSQLには `INET` 型があり、無効なIPアドレスの格納を防ぎ、CIDR範囲検索もできる。

**対処案**: `TEXT` → `INET` に変更。ただし既存データがある場合はマイグレーション時に無効データを事前クリーニングする。

### 8. URL系カラムの検証なし

| テーブル | カラム | リスク |
|----------|--------|--------|
| t_billing_info | evidence_url | SSRF（サーバサイドリクエスト偽造） |
| t_notifications | link_url | オープンリダイレクト |
| t_partner_sites | site_url | フィッシングURL格納 |
| t_influencer_sns_accounts | account_url | 同上 |

DB側でURL検証する必要はないが、アプリケーション側でプロトコル制限（https://のみ）とドメインバリデーションを実施しているか確認が必要。

---

## MEDIUM（計画的に対処）

### 9. JSONB カラムに機密データが混入するリスク

| テーブル | カラム | リスク |
|----------|--------|--------|
| t_audit_logs | old_value / new_value | パスワードハッシュ変更時のbefore/afterが記録される可能性 |
| t_billing_runs | filter_conditions | 抽出条件にPIIが含まれる可能性 |
| ingestion_logs | parameters | BQ接続情報が含まれる可能性 |

**対処案**: audit_logのトリガー実装時に、password_hash・session_token等の機密カラムを除外するフィルタリングを入れる。

### 10. t_files.storage_path のパストラバーサルリスク

`storage_path` がフリーテキスト。アプリケーション側でパス結合に直接使うと、`../../etc/passwd` のような攻撃パスを格納される可能性がある。

**対処案**: CHECK制約で `..` を含むパスを排除する。

```sql
ALTER TABLE t_files
ADD CONSTRAINT chk_storage_path_safe
CHECK (storage_path NOT LIKE '%..%');
```

### 11. m_partners_division に created_by/updated_by がない

他の全テーブルには監査用の `created_by` / `updated_by` があるが、`m_partners_division` だけ欠落している。誰がデータを変更したか追跡できない。

**対処案**: `created_by BIGINT NOT NULL` と `updated_by BIGINT NOT NULL` を追加。

### 12. t_audit_logs の old_value/new_value に GIN インデックス

`idx_audit_logs_old_value` と `idx_audit_logs_new_value` のGINインデックスは、パスワードハッシュ等の機密値がインデックス内に格納される。インデックスファイルから逆引きされるリスクがある。

**対処案**: 機密カラムの変更をaudit_logに記録しないルールを徹底すれば、GINインデックスは維持して問題ない。

---

## LOW（認識しておく）

### 13. created_by/updated_by にFK制約なし

全テーブルの `created_by` / `updated_by` が `BIGINT NOT NULL` だがFK制約がない。存在しないagent_idの値が入る可能性がある。

意図的な設計判断の可能性が高い（システム管理者ID=1等のハードコード値を使うため）。FK制約を追加するとデータ投入やバッチ処理で制約違反になりやすい。現状維持で問題ない。

### 14. 楽観ロックの version カラム

`m_influencers`、`m_campaigns`、`t_unit_prices` の3テーブルだけに `version` がある。他のテーブルで同時更新の競合が起きても検知できない。

ただし、楽観ロックが必要なのはユーザーが同時編集する可能性が高いテーブルだけなので、現在の3テーブル選定は妥当。

### 15. password_changed_at インデックス

`m_agent_security` と `m_influencer_security` の `password_changed_at` にインデックスがある。パスワード有効期限チェック用だが、NULLを含むカラムのフルインデックスはストレージ効率が悪い。

**対処案**: 部分インデックスにする（必須ではない）。

```sql
CREATE INDEX idx_agent_security_password_changed
ON m_agent_security(password_changed_at)
WHERE password_changed_at IS NOT NULL;
```

---

## セキュリティ改善の優先順位

| 順位 | 項目 | 工数感 | 影響 |
|------|------|--------|------|
| 1 | RLSポリシー設定 | 大 | データ漏洩防止の最終防衛線 |
| 2 | セッション/リセットトークンのハッシュ化 | 小 | アプリ側の変更も必要 |
| 3 | GRANT/REVOKE設定 | 中 | ロール設計が先 |
| 4 | 銀行口座情報の暗号化 | 中 | pgcrypto導入 + キー管理 |
| 5 | 関数のsearch_path設定 | 小 | DDL修正のみ |
| 6 | audit_logの機密フィルタ | 小 | トリガー実装時に対応 |
| 7 | storage_pathのCHECK制約 | 小 | ALTER TABLEのみ |

---

## 評価対象外

以下はDDL監査のスコープ外。別途確認が必要。
- アプリケーション層のSQL Injection対策（パラメタライズドクエリの使用状況）
- TLS/SSL接続の強制設定
- バックアップの暗号化
- ログ出力における機密データマスキング
- WAFやレートリミットの設定

---

_最終更新: 2026-02-14_
