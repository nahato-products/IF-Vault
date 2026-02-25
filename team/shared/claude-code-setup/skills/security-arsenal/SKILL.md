---
name: security-arsenal
description: "Execute offensive (Red) and defensive (Blue) security operations covering penetration testing, exploitation, system hardening, detection engineering, and incident response. Use when conducting authorized penetration tests, performing red team assessments, hardening servers or applications, building detection rules, responding to security incidents, preparing for CTF competitions, validating security controls through purple team exercises, analyzing attack chains, or testing API and cloud security posture. Do not trigger for secure coding patterns (use security-best-practices), code vulnerability scanning (use security-review), or threat modeling (use security-threat-model). Invoke with /security-arsenal."
user-invocable: true
---

# Security Arsenal

`/security-arsenal` で起動。モード選択:

1. **Red** - 攻撃者視点（ペンテスト・脆弱性実証・CTF）
2. **Blue** - 防御者視点（ハードニング・検知・インシデント対応）
3. **Purple** - 攻防統合（攻撃シナリオ → 防御検証サイクル）

## Ethical Guidelines [CRITICAL]

**認可されたテスト・CTF・教育目的でのみ使用**。違反は法的責任を伴う。

- 書面による明示的許可なしに第三者のシステムをテストしない
- 発見した脆弱性は責任ある開示（Responsible Disclosure）に従う
- 攻撃コードは隔離された検証環境でのみ実行
- スコープ外への横展開は絶対に行わない
- 証拠保全とログ記録を徹底（事後検証に必須）

## When NOT to Apply

- セキュアなコーディングパターン（→ security-best-practices）
- 既存コードの脆弱性スキャン（→ security-review）
- アーキテクチャレベルの脅威モデリング（→ security-threat-model）
- 本番環境への無許可テスト

## Decision Tree

```
目的が攻撃テスト → Red Mode
目的が防御強化 → Blue Mode
攻撃で防御を検証 or 検知ギャップ分析 → Purple Mode
コードの脆弱性修正 → security-review + security-best-practices
設計レベルの分析 → security-threat-model
迷ったら → 「攻撃もしたいし検知も確認したい」= Purple Mode
```

---

## Red Mode [CRITICAL]

### Reconnaissance（偵察）

MITRE ATT&CK TA0043。攻撃面を特定してから手法を選択。

**パッシブ**: OSINT、DNS レコード、証明書透過性ログ、Wayback Machine
**アクティブ**: ポートスキャン、サービスバナー取得、ディレクトリ列挙

```bash
nmap -sV -sC -oN scan.txt target.com          # サービス検出
subfinder -d target.com | httpx -silent        # サブドメイン列挙
feroxbuster -u https://target.com -w common.txt # ディレクトリ探索
```

**判断**: Web アプリが主要面 → Web Attacks / インフラ主要 → Privilege Escalation

### Web Application Attacks

OWASP Top 10 ベース。各攻撃の**防御は Blue Mode**、**ペイロード詳細は reference.md** を参照。

**SQLi (A03)**: Union / Error-based / Blind（Boolean・Time-based）/ Second Order。自動化は `sqlmap`
**XSS (A03)**: Reflected / Stored / DOM の3分類。sink/source 分析で DOM XSS を特定
**SSRF (A10)**: クラウドメタデータ（AWS IMDSv1/v2、GCP、Azure）、`file://`、`gopher://`。DNS Rebinding で回避
**認証・セッション (A07)**: JWT（`alg:none`、弱い鍵、kid インジェクション）、OAuth（redirect_uri 操作、state 欠落）、パスワードリセット poisoning
**IDOR (A01)**: `/api/users/123` → `/api/users/124` で他人のデータアクセス
**SSTI**: `{{7*7}}` → テンプレートエンジン経由 RCE
**Deserialization (A08)**: 信頼されないデータのデシリアライズ → RCE

### API-Specific Attacks

- **GraphQL**: イントロスペクション有効 → スキーマ全取得、ネストクエリで DoS、バッチクエリ悪用
- **Mass Assignment**: リクエストボディに `role=admin` 追加で権限昇格
- **BOLA/BFLA**: API レベルの認可不備（OWASP API Top 10 #1/#5）

### Authentication Attacks

- **Brute Force**: Hydra / Burp Intruder でクレデンシャル総当たり
- **Credential Stuffing**: 流出 DB の再利用パスワード攻撃
- **MFA Bypass**: リアルタイムフィッシング、MFA fatigue（連続プッシュ）
- **Session Fixation**: 認証後にセッション ID が再生成されない問題

### Privilege Escalation

**Linux**:
```bash
find / -perm -4000 2>/dev/null   # SUID バイナリ検索
sudo -l                           # sudo 設定確認 → GTFOBins
cat /etc/crontab                  # cron ジョブ確認
uname -r                          # カーネルバージョン → exploit-db
```

**Windows**:
- Service misconfig: 書き込み可能なサービスパス → バイナリ置換
- Token Impersonation: SeImpersonatePrivilege → Potato 系
- UAC Bypass: auto-elevate バイナリの悪用

### Post-Exploitation

- **Lateral Movement**: Pass-the-Hash、PSExec、WinRM、SSH ピボット
- **Persistence**: cron / Task Scheduler、SSH キー追加、Web シェル
- **Exfiltration**: DNS トンネリング、HTTPS 経由、ステガノグラフィ
- **Cleanup**: ログ痕跡の確認（⚠️ CTF/ラボ環境のみ。実環境では証拠保全優先）

---

## Blue Mode [CRITICAL]

### Hardening（堅牢化）

**OS**:
- 不要サービス無効化、最小権限の原則
- SSH: パスワード認証無効 + 鍵認証 + ポート変更 + fail2ban
- ファイアウォール: デフォルト deny → 必要ポートのみ allow
- パッチ管理: 自動更新 + unattended-upgrades

**アプリケーション**:
- CSP: `default-src 'self'; script-src 'self'`（XSS 緩和の最重要ヘッダー）
- CORS: `Access-Control-Allow-Origin: *` は**絶対禁止**
- Rate Limiting: 認証 EP はより厳格に（アプリ特性に応じて設定）
- ヘッダー: HSTS / X-Frame-Options / X-Content-Type-Options

**DB**:
- Prepared Statements 徹底（SQLi の根本対策）
- 最小権限 DB ユーザー（アプリ用に DROP 権限を与えない）
- 接続暗号化（TLS 必須）

チェックリスト完全版は [reference.md](reference.md) を参照。

### Detection & Monitoring（検知）

**ログ戦略**:
- 認証: 全ログイン試行（成功/失敗）+ IP + UA
- アクセス: 異常パス・パラメータ（SQLi/XSS シグネチャ）
- 変更監視: ファイル整合性チェック（AIDE / OSSEC）

**検知ルール例**:

| 攻撃 | シグネチャ | 閾値 |
|------|-----------|------|
| SQLi | `UNION SELECT`, `OR 1=1`, `'; DROP` | 1回で即アラート |
| XSS | `<script>`, `onerror=`, `javascript:` | 1回で即アラート |
| Brute Force | 同一IP のログイン失敗 | 5分間に10回以上 |
| SSRF | 内部IP帯へのリクエスト（10.0/8, 172.16/12, 169.254） | 1回で即アラート |

**ツール**: WAF（ModSecurity CRS）、SIEM（Elastic / Wazuh）、EDR（CrowdStrike / Defender）

### Incident Response（インシデント対応）

NIST SP 800-61 ベースの 4 フェーズ:

1. **Preparation**: IR 計画・連絡網・ツール準備・定期訓練
2. **Detection & Analysis**: アラート確認・トリアージ・影響範囲特定・証拠保全
3. **Containment → Eradication → Recovery**:
   - 封じ込め: 感染ホスト隔離（ネットワーク切断）
   - 除去: マルウェア駆除・パッチ適用・認証情報リセット
   - 復旧: バックアップからの段階的サービス再開
4. **Post-Incident**: 教訓文書化・再発防止策・IR 計画更新

**最初の1時間**（ゴールデンタイム）: メモリダンプ取得 → タイムライン作成開始 → 経営層初期報告

IR 詳細プレイブックは [reference.md](reference.md) を参照。

---

## Purple Mode [HIGH]

### Attack-Defense Cycle

Red と Blue を組み合わせた検証サイクル:

```
1. 脅威シナリオ定義（security-threat-model の攻撃ツリー出力をインポート）
2. Red: 攻撃実行（認可済み環境で）
3. Blue: 検知確認 → アラート発火したか？
4. Gap 分析: 検知できなかった攻撃を特定
5. Blue: 検知ルール追加・調整
6. Red: 回避テクニックで再テスト
7. → 3 に戻る（収束まで繰り返し）
```

### MITRE ATT&CK カバレッジ

| Tactic | 代表 Technique | Red テスト | Blue 検知 |
|--------|---------------|-----------|----------|
| 偵察 TA0043 | Active Scanning | nmap | ポートスキャン検知 |
| 初期アクセス TA0001 | Exploit Public App | SQLi/XSS | WAF + ログ監視 |
| 実行 TA0002 | Command Scripting | Web シェル | プロセス監視 |
| 永続化 TA0003 | Scheduled Task | cron バックドア | ファイル整合性 |
| 権限昇格 TA0004 | Abuse Elevation | sudo/SUID | 権限変更監視 |
| 横展開 TA0008 | Remote Services | SSH ピボット | 異常接続検知 |
| 持ち出し TA0010 | Exfil Over C2 | DNS トンネル | DNS 異常検知 |

**カバレッジ目標**: 主要 Tactic ごとに最低1つの Technique をテスト + 検知確認済みにする。

---

## Reference

攻撃ペイロード集、フィルター回避テクニック、ハードニングチェックリスト、IR プレイブック、CTF テクニック集は [reference.md](reference.md) を参照。

## Cross-references

- **security-best-practices**: 脆弱性修正のコーディングパターン
- **security-review**: 自動検知パイプライン構築時のコードスキャン
- **security-threat-model**: Purple Mode の脅威シナリオ入力

### Referenced by

- **_security-review**: 脆弱性検出との連携
- **_security-best-practices**: セキュアコーディングの防御側
- **_security-threat-model**: 脅威モデルに基づく攻撃シナリオ
