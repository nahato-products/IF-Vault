---
date: 2026-02-14
tags: [Moltbot, LINE, ANSEM, API設計, 連携]
status: draft
---

# Moltbot × ANSEM 連携設計メモ

LINEボット（Moltbot）からANSEMのインフルエンサーデータを照会・登録するための設計メモ。Phase 1実装が始まったら具体化する。

## 狙い

営業チームがLINEから直接インフルエンサー情報を引ける。PCを開かなくてもスマホでサクッと確認・登録できる状態を作る。管理画面にログインする手間がなくなるだけで、日常の問い合わせ対応速度が上がる。

## ユースケース

### UC1: インフルエンサー検索

営業がLINEで「田中」と送ると、該当するインフルエンサーの一覧が返る。

```
ユーザー: IF検索 田中
Bot: 3件見つかりました
  1. 田中太郎（Instagram: @tanaka_t / YouTube: TanakaCH）
  2. 田中花子（TikTok: @hanako_tnk）
  3. 田中一郎（Instagram: @ichiro_tanaka）
→ 詳細を見るには番号を送信
```

検索対象: m_influencers.display_name, t_influencer_sns_accounts.account_name

### UC2: インフルエンサー詳細

```
ユーザー: 1
Bot: 田中太郎
  ステータス: 有効
  担当: 山田（メイン）、鈴木（サブ）
  SNS:
    Instagram: @tanaka_t（フォロワー: 50,000）
    YouTube: TanakaCH（登録者: 120,000）
  カテゴリ: 美容, ファッション
  最終更新: 2026-02-10
```

### UC3: ステータス変更

```
ユーザー: IF更新 田中太郎 ステータス 休止
Bot: 田中太郎のステータスを「休止」に変更しました
  変更前: 有効 → 変更後: 休止
  変更者: 山田（agent_id: 5）
```

### UC4: 簡易登録

```
ユーザー: IF登録
Bot: 新規インフルエンサー登録を開始します
  名前を入力してください
ユーザー: 佐藤美咲
Bot: SNSアカウントを入力してください（例: Instagram @account）
ユーザー: Instagram @misaki_sato
Bot: カテゴリを選択してください
  1. 美容  2. ファッション  3. グルメ  4. 旅行  5. その他
ユーザー: 1
Bot: 登録内容を確認します
  名前: 佐藤美咲
  Instagram: @misaki_sato
  カテゴリ: 美容
  → 登録する場合は「OK」を送信
```

## アーキテクチャ

```
LINE → Moltbot → ANSEM API → PostgreSQL
                    ↑
              認証ミドルウェア
              (JWT or API Key)
```

### コンポーネント

| レイヤー | 技術 | 役割 |
|---------|------|------|
| チャネル | LINE Messaging API | ユーザーインターフェース |
| Bot | Moltbot（既存） | メッセージ解析・ルーティング |
| API | ANSEM REST API（新規） | データCRUD |
| DB | PostgreSQL | データストア |
| 認証 | JWT or API Key | BotからAPIへのアクセス制御 |

### ANSEM API エンドポイント案

| メソッド | パス | 用途 |
|---------|------|------|
| GET | /api/v1/influencers?q={name} | 検索 |
| GET | /api/v1/influencers/{id} | 詳細取得 |
| POST | /api/v1/influencers | 新規登録 |
| PATCH | /api/v1/influencers/{id}/status | ステータス変更 |
| GET | /api/v1/influencers/{id}/sns-accounts | SNS一覧 |
| GET | /api/v1/categories | カテゴリ一覧 |

### 認証フロー

BotからAPIへのアクセスはサービス間認証。ユーザー認証ではない。

1. Moltbotに固定のAPI Keyを設定
2. リクエストヘッダーに `Authorization: Bearer {api_key}` を付与
3. API側でキーを検証、操作ログに `created_by` / `updated_by` としてBot用のagent_idを記録

Bot用エージェント: m_agentsに `agent_id = 999`（Moltbot）を事前登録しておく。

## LINE Bot SDK連携

### Flex Messageでリッチ表示

検索結果や詳細はFlex Messageで見やすく返す。テキストだけだと情報量が多いときに読みにくい。

```json
{
  "type": "bubble",
  "body": {
    "type": "box",
    "layout": "vertical",
    "contents": [
      { "type": "text", "text": "田中太郎", "weight": "bold", "size": "xl" },
      { "type": "text", "text": "Instagram: @tanaka_t", "size": "sm", "color": "#999999" },
      { "type": "text", "text": "フォロワー: 50,000", "size": "sm" }
    ]
  }
}
```

### クイックリプライ

カテゴリ選択やステータス変更にクイックリプライボタンを使う。ユーザーの入力ミスを減らせる。

## セキュリティ考慮

- APIキーは環境変数で管理（LINE Bot設定のシークレットと同様）
- 個人情報（銀行口座、請求先）はBot経由で返さない
- 操作ログはt_audit_logsに全て記録
- Bot経由の操作は `operator_type = 'bot'` で識別

## 実装ロードマップ

| フェーズ | 内容 | 前提 |
|---------|------|------|
| Phase 0 | ANSEM REST API設計・認証基盤 | ANSEM Phase 1完了後 |
| Phase 1 | IF検索 + 詳細表示 | API GET系エンドポイント |
| Phase 2 | ステータス変更 | API PATCH系エンドポイント |
| Phase 3 | 簡易登録（対話形式） | API POST系エンドポイント |
| Phase 4 | リッチUI（Flex Message）+ 通知連携 | LINE Flex Message SDK |

## 開発メモ

- Moltbotの既存アーキテクチャに乗せる。新規Botは作らない
- コマンドプレフィックス: `IF検索`, `IF詳細`, `IF更新`, `IF登録`
- セッション管理: 対話形式の登録フローはRedisかメモリでステート管理
- レート制限: LINE APIの送信制限（無料プラン: 200通/月）に注意

---

_最終更新: 2026-02-14_
