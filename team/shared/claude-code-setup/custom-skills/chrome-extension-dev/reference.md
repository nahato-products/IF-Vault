# Chrome Extension MV3 — Reference

SKILL.md の補足資料。詳細なAPIリファレンス、SNSセレクタ、公開チェックリスト。

---

## manifest.json フィールドリファレンス

| フィールド | 必須 | 説明 |
|-----------|------|------|
| `manifest_version` | 必須 | `3` 固定 |
| `name` | 必須 | 拡張名（45文字以内推奨） |
| `version` | 必須 | セマンティックバージョニング |
| `description` | 推奨 | 132文字以内 |
| `icons` | 推奨 | 16, 32, 48, 128px |
| `action` | 任意 | popup, icon, title |
| `background.service_worker` | 任意 | SW ファイルパス（文字列） |
| `background.type` | 任意 | `"module"` でES modules有効 |
| `content_scripts` | 任意 | matches, js, css, run_at, world |
| `permissions` | 任意 | API権限 |
| `host_permissions` | 任意 | ホストアクセス権限 |
| `optional_permissions` | 任意 | ランタイム要求権限 |
| `web_accessible_resources` | 任意 | resources + matches（MV3形式） |
| `content_security_policy` | 任意 | extension_pages + sandbox |

---

## Storage Quota 詳細

| Storage | 容量上限 | アイテム上限 | 書込み制限 |
|---------|---------|------------|-----------|
| `local` | 10MB（`unlimitedStorage` で無制限） | なし | なし |
| `sync` | 100KB合計 / 8KB per item | 512アイテム | 120回/分, 1800回/時 |
| `session` | 10MB | なし | なし |

### session のアクセスレベル

Content Script からデフォルトでアクセス不可。変更するには:
```js
chrome.storage.session.setAccessLevel({
  accessLevel: "TRUSTED_AND_UNTRUSTED_CONTEXTS"
});
```

---

## パーミッション → 警告テキスト

| パーミッション | 警告 |
|--------------|------|
| `storage` | なし |
| `activeTab` | なし |
| `alarms` | なし |
| `scripting` | なし |
| `tabs` | 「閲覧履歴を読み取る」 |
| `notifications` | 「通知を表示する」 |
| `<all_urls>` | 「すべてのウェブサイトのデータを読み取る/変更する」 |
| `bookmarks` | 「ブックマークを読み取る/変更する」 |
| `history` | 「閲覧履歴を読み取る」 |

最小権限原則: `<all_urls>` より `activeTab` + 具体的な `host_permissions` を推奨。

---

## SNS セレクタ詳細

**注意: DOMは頻繁に変更される。実装時にDevToolsで確認すること。**

### Instagram

```js
// 投稿要素
document.querySelectorAll("article");

// いいね数（テキストベース検索が最も安定）
[...document.querySelectorAll("section span")]
  .find(el => el.textContent.match(/\d+.*likes?/i));

// class名はビルドごとにハッシュ化 → APIインターセプト推奨
```

### TikTok

```js
// data-e2e 属性が比較的安定
document.querySelectorAll("[data-e2e='recommend-list-item-container']");
document.querySelector("[data-e2e='like-count']");
document.querySelector("[data-e2e='comment-count']");
document.querySelector("[data-e2e='share-count']");

// メタデータは __NEXT_DATA__ スクリプトタグ内のJSONにも格納
const nextData = JSON.parse(
  document.querySelector("#__NEXT_DATA__")?.textContent || "{}"
);
```

### YouTube

```js
// Polymer/Lit ベースのカスタム要素（最も安定）
document.querySelector("h1.ytd-watch-metadata yt-formatted-string"); // タイトル
document.querySelectorAll("ytd-comment-thread-renderer"); // コメント

// コメント要素の内部
comment.querySelector("#author-text");   // 投稿者
comment.querySelector("#content-text");  // 本文
comment.querySelector("#vote-count-middle"); // いいね数

// メタデータは ytInitialData グローバル変数にも格納
```

### URL変更検出（全SNS共通）

```js
// MAIN world で実行
const orig = history.pushState;
history.pushState = function(...args) {
  orig.apply(this, args);
  window.dispatchEvent(new CustomEvent("urlchange", { detail: args[2] }));
};
window.addEventListener("popstate", () => {
  window.dispatchEvent(new CustomEvent("urlchange"));
});
```

---

## Offscreen Document

Service Worker でDOM操作が必要な場合のワークアラウンド。

```js
await chrome.offscreen.createDocument({
  url: "offscreen.html",
  reasons: ["DOM_SCRAPING"],
  justification: "Parse DOM content"
});
```

- `chrome.runtime` メッセージングAPIのみ利用可能
- 用途: DOM パース、Canvas操作、音声再生

---

## Page ↔ Content Script 通信

```js
// Page (MAIN world) → Content Script (ISOLATED)
window.postMessage({ source: "MY_EXT", type: "DATA", payload: {...} }, "*");

// Content Script で受信
window.addEventListener("message", (event) => {
  if (event.source !== window) return;
  if (event.data?.source === "MY_EXT") {
    chrome.runtime.sendMessage(event.data); // Backgroundに転送
  }
});
```

---

## Chrome Web Store 公開チェックリスト

### 事前準備
- [ ] Developer Dashboard 登録（$5 一回限り）
- [ ] 2段階認証有効化
- [ ] プライバシーポリシー準備（データ収集がある場合）

### 素材
- [ ] アイコン 128x128px
- [ ] スクリーンショット 最低1枚（1280x800 or 640x400）
- [ ] 明確な機能説明文

### 審査
- 通常1-3営業日（MV3は早い傾向）
- 自動チェック + 人間レビュー

### よくあるリジェクト理由
1. 過剰なパーミッション（`<all_urls>` を使って特定ドメインしか使わない）
2. 不明確な説明文
3. プライバシーポリシーの欠如
4. 単一目的の原則違反（無関係な複数機能）
5. リモートコード実行

---

## プロジェクト構成例（WXT + React）

```
my-extension/
├── wxt.config.ts
├── entrypoints/
│   ├── popup/         # Popup UI (React)
│   │   ├── App.tsx
│   │   └── main.tsx
│   ├── background.ts  # Service Worker
│   └── content.ts     # Content Script
├── public/
│   └── icons/
├── package.json
└── tsconfig.json
```

---

## トラブルシューティング

| 問題 | 原因 | 対策 |
|------|------|------|
| SW が何度も再起動 | アイドル30秒で終了 | chrome.storage で状態永続化 |
| Content Script が動かない | matches パターン不一致 | DevTools > Extensions でマッチ確認 |
| 署名検証エラー | CSP違反 | インラインスクリプト排除 |
| storage.sync 書込み失敗 | レート制限超過 | debounce で書込み頻度削減 |
| SPA でDOM取得失敗 | ページ遷移後の再注入 | MutationObserver + URL監視 |
