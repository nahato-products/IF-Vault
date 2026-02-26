# Deep Research — Reference

Gemini Deep Research スキルで使うリサーチプロンプトテンプレート、品質チェックリスト、引用フォーマットガイドのリファレンス集。

---

## Quick Commands（再掲）

```bash
# 基本リサーチ
python3 scripts/research.py --query "topic"

# リアルタイム進捗表示
python3 scripts/research.py --query "topic" --stream

# 構造化フォーマット指定
python3 scripts/research.py --query "topic" --format "1. 概要\n2. 比較表\n3. 推奨"

# ステータス確認 / 完了待ち / 継続
python3 scripts/research.py --status <id>
python3 scripts/research.py --wait <id>
python3 scripts/research.py --continue <id> --query "follow-up"

# JSON出力 / 一覧表示
python3 scripts/research.py --query "topic" --json
python3 scripts/research.py --list
```

**コスト目安**: ~$2-5/タスク、2-10分、250k-900k input tokens

---

## Research Prompt Templates

### 1. 市場分析（Market Analysis）

```
--query "
[市場名] の市場分析を行ってください。

調査項目:
1. 市場規模（TAM/SAM/SOM）と成長率（過去5年 + 予測）
2. 主要プレイヤー（上位5社）のシェアと差別化ポイント
3. 顧客セグメントと主要ニーズ
4. 参入障壁と規制環境
5. 技術トレンドとディスラプション要因
6. 日本市場固有の特徴（該当する場合）

出力形式:
- Executive Summary（3-5文）
- 市場規模テーブル（年度別）
- 競合比較マトリクス
- SWOT分析
- 機会と脅威のまとめ
"

--format "1. Executive Summary\n2. Market Size & Growth\n3. Competitive Landscape\n4. Customer Segments\n5. Technology Trends\n6. Opportunities & Risks\n7. Sources"
```

### 2. 技術比較（Technology Comparison）

```
--query "
[技術A] vs [技術B] vs [技術C] の技術比較を行ってください。

評価軸:
1. パフォーマンス（ベンチマーク、レイテンシ、スループット）
2. 開発体験（学習曲線、ドキュメント、エコシステム）
3. スケーラビリティ（水平/垂直スケーリング、制限事項）
4. コスト（ライセンス、インフラ、運用コスト）
5. コミュニティとサポート（GitHub Stars、リリース頻度、企業サポート）
6. セキュリティ（既知の脆弱性、セキュリティ実績）
7. ユースケース適合性（[具体的なユースケースを記述]）

出力形式:
- 比較サマリーテーブル
- 各技術の強み/弱み
- ユースケース別の推奨
- 移行コスト（既存技術からの場合）
"

--format "1. Summary Table\n2. Detailed Comparison\n3. Use Case Recommendations\n4. Migration Considerations\n5. Verdict\n6. Sources"
```

### 3. 文献レビュー（Literature Review）

```
--query "
[テーマ] に関する文献レビューを行ってください。

対象:
- 学術論文、技術ブログ、公式ドキュメント、カンファレンス発表
- 期間: [過去N年]
- 言語: 英語 + 日本語

調査ポイント:
1. 主要な研究動向と理論フレームワーク
2. 合意が形成されている知見
3. 論争点や未解決の課題
4. 実務への応用事例
5. 今後の研究方向

出力形式:
- テーマの概観（背景と重要性）
- 主要研究のサマリーテーブル（著者、年、主要発見）
- 知見の統合と分析
- ギャップと今後の方向性
- 参考文献リスト
"

--format "1. Introduction & Background\n2. Key Studies Summary\n3. Synthesis\n4. Gaps & Future Directions\n5. References"
```

### 4. デューデリジェンス（Due Diligence）

```
--query "
[企業名/サービス名] のデューデリジェンス調査を行ってください。

調査項目:
1. 企業概要（設立、本社、従業員数、資金調達）
2. プロダクト/サービスの概要と技術スタック
3. ビジネスモデルと収益構造
4. 競合ポジショニング
5. 評判（ユーザーレビュー、SNS評価、障害履歴）
6. セキュリティ/コンプライアンス（SOC2、GDPR、ISMS等）
7. リスク要因

出力形式:
- 1ページサマリー
- 詳細レポート
- リスク/懸念事項リスト
- 推奨アクション
"
```

### 5. トレンド調査（Trend Research）

```
--query "
[分野] における最新トレンド（[年度]）を調査してください。

調査スコープ:
1. 注目されている技術/手法（トップ5-10）
2. 業界の採用状況と成熟度
3. 主要企業の動向と発表
4. オープンソースの注目プロジェクト
5. 日本国内での採用事例
6. 今後12ヶ月の予測

出力形式:
- トレンドマップ（カテゴリ × 成熟度）
- 各トレンドの概要（100-200字）
- 実務への影響度評価
- 推奨アクション
"
```

---

## Citation Format Guide

### 引用の書き方

リサーチ結果を設計ドキュメントやPRに引用する際のフォーマット。

```markdown
## インライン引用
「React Server Components は〜を実現する [1]」のように番号参照。

## 参考文献リスト（レポート末尾）

### Web記事
[1] 著者名, "記事タイトル", サイト名, 公開日.
    URL: https://example.com/article

### 学術論文
[2] 著者名 et al., "論文タイトル", ジャーナル名, vol.X, no.Y, pp.Z, 年.
    DOI: 10.xxxx/xxxxx

### 公式ドキュメント
[3] "ページタイトル", プロジェクト名 Documentation, 最終アクセス日.
    URL: https://docs.example.com/page

### GitHub リポジトリ
[4] 著者/組織, "リポジトリ名", GitHub, 最終アクセス日.
    URL: https://github.com/org/repo
    Stars: X, Last commit: YYYY-MM-DD

### カンファレンス発表
[5] 発表者名, "発表タイトル", カンファレンス名, 開催年.
    URL: https://example.com/talk（スライド/動画）
```

### 引用品質チェック

| チェック項目 | 合格基準 |
|-------------|---------|
| ソースの鮮度 | 技術系は2年以内、学術系は5年以内が望ましい |
| ソースの信頼性 | 公式ドキュメント > 査読論文 > 技術ブログ > SNS |
| URL の有効性 | リンク切れでないことを確認 |
| 著者の明示 | 「〜によると」ではなく具体的な著者名/組織名 |
| 一次ソース | 可能な限り二次情報ではなく原典を参照 |

---

## Research Quality Checklist

リサーチ結果を受け取った後、以下の観点で品質を検証する。

### 必須チェック（Must）

- [ ] **網羅性**: 調査項目が全てカバーされているか
- [ ] **根拠の明示**: 主張に対してソースが紐づいているか
- [ ] **バイアスの確認**: 特定のベンダー/技術に偏っていないか
- [ ] **鮮度**: 情報が古くないか（特に技術系は変化が速い）
- [ ] **矛盾の有無**: レポート内で矛盾する記述がないか

### 推奨チェック（Should）

- [ ] **定量データ**: 数値（市場規模、ベンチマーク等）に出典があるか
- [ ] **反証の提示**: メリットだけでなくデメリット/リスクも記載されているか
- [ ] **実務との接続**: 調査結果がアクションにつながる形で整理されているか
- [ ] **日本市場の考慮**: グローバルデータだけでなく日本固有の事情が反映されているか
- [ ] **前提条件の明示**: 「〜の場合に限り」等の条件が明確か

### フォローアップ判断

```
リサーチ結果に不足がある場合:
  → --continue <id> --query "不足点を具体的に指示" で深掘り

品質が十分な場合:
  → brainstorming スキルに引き継いで設計フェーズへ
  → または docs/research/YYYY-MM-DD-<topic>.md に保存
```

---

## Example: Research Brief

リサーチ依頼時に整理しておくと精度が上がるブリーフテンプレート。

```markdown
# Research Brief: [テーマ]

## 背景
- なぜこの調査が必要か（1-2文）
- どの意思決定に使うか

## 調査の問い（Research Questions）
1. [主要な問い]
2. [補足の問い]
3. [補足の問い]

## スコープ
- 対象: [技術/市場/企業等]
- 期間: [過去N年 / 現在 / 将来予測]
- 地域: [グローバル / 日本 / 特定地域]
- 除外: [調査しないもの]

## 期待する出力
- 形式: [比較表 / レポート / SWOT / 推奨リスト]
- 分量: [概要のみ / 詳細レポート]
- 用途: [社内共有 / 設計判断 / クライアント提案]

## 既知の情報
- [すでに把握していること]
- [仮説や前提]
```

### 実例: 認証ライブラリの技術比較

```markdown
# Research Brief: Next.js 認証ライブラリ比較

## 背景
- 新規プロジェクトで認証基盤を選定する必要がある
- Supabase Auth vs NextAuth.js vs Clerk の3候補

## 調査の問い
1. 各ライブラリの機能差（OAuth, MFA, セッション管理）は？
2. Next.js App Router との統合度はどう違う？
3. コスト構造（無料枠、スケール時の費用）は？

## スコープ
- 対象: Supabase Auth, NextAuth.js v5, Clerk
- 期間: 2025-2026年の最新情報
- 除外: Firebase Auth, Auth0（候補外）

## 期待する出力
- 形式: 比較表 + 推奨（Decision Matrix 形式）
- 用途: チーム内の技術選定会議で使用
```

---

## Output Handling

| 出力形式 | フラグ | 用途 |
|----------|--------|------|
| Markdown（デフォルト） | なし | 人間が読むレポート |
| JSON | `--json` | プログラムからの利用、データ加工 |
| Raw | `--raw` | デバッグ、API レスポンス確認 |

### レポート保存先

```
docs/research/YYYY-MM-DD-<topic>.md    — プロジェクト内に保存
~/.claude/tmp/research-<topic>.md      — 一時的な調査結果
```

---

## Cross-references

| 関連スキル | 用途 |
|-----------|------|
| `brainstorming` | リサーチ結果を元に設計ブレストへ移行 |
| `security-threat-model` | セキュリティ関連のリサーチ結果を脅威モデルに反映 |
| `nextjs-app-router-patterns` | 技術比較結果を実装パターンに接続 |
| `natural-japanese-writing` | 日本語レポートの品質向上 |
