---
name: chrome-extension-dev
description: Chrome Extension development with Manifest V3. Covers manifest structure, content scripts, background service workers, popup UI, storage API, message passing, permissions, and SNS DOM scraping patterns. Use when building Chrome extensions, creating browser extensions, writing content scripts, implementing popup UI, handling chrome.storage, setting up service workers, scraping Instagram, scraping TikTok, or building MV3 browser tools. Do not trigger for Firefox/Safari-only extensions, Electron/Tauri desktop apps, or general web development unrelated to browser extensions.
user-invocable: false
triggers:
  - Chrome拡張を作る
  - Content Scriptを書く
  - Manifest V3で実装する
  - chrome.storageを使う
  - SNSのDOM操作をする
---

# Chrome Extension Development (Manifest V3)

MV3 拡張機能の設計・実装パターン集。SNS DOM 操作に特化したセクションあり。

## When to Apply

- Chrome拡張の新規作成・改修
- Content Script / Background Service Worker の実装
- Popup UI の設計・React統合
- SNSサイト（Instagram/TikTok/YouTube）のDOM操作
- chrome.storage / メッセージパッシングの設計
- 拡張機能のセキュリティレビュー

## When NOT to Apply

- Firefox/Safari専用の拡張（WebExtension共通部分は参考になる）
- Electron/Tauri等のデスクトップアプリ
- ブラウザ拡張と無関係なWeb開発

---

## Part 1: Manifest V3 構造 [CRITICAL]

### 1. 必須フィールド

```json
{
  "manifest_version": 3,
  "name": "Extension Name",
  "version": "1.0.0",
  "description": "What it does"
}
```

### 2. MV2→MV3 の主要変更

| MV2 | MV3 |
|-----|-----|
| `browser_action` / `page_action` | `action`（統一） |
| `background.scripts` (配列) | `background.service_worker` (文字列) |
| `background.persistent` | 削除（常にイベント駆動） |
| `permissions` に host | `host_permissions` に分離 |
| リモートコード可 | リモートコード完全禁止 |

### 3. manifest.json テンプレート

```json
{
  "manifest_version": 3,
  "name": "My Extension",
  "version": "1.0.0",
  "action": {
    "default_popup": "popup.html",
    "default_icon": { "16": "icons/16.png", "128": "icons/128.png" }
  },
  "background": {
    "service_worker": "background.js",
    "type": "module"
  },
  "content_scripts": [{
    "matches": ["https://*.example.com/*"],
    "js": ["content.js"],
    "run_at": "document_idle"
  }],
  "permissions": ["storage", "activeTab"],
  "host_permissions": ["https://*.example.com/*"]
}
```

---

## Part 2: Content Scripts [CRITICAL]

### 4. 実行ワールド

- **ISOLATED** (デフォルト): ページJSに触れないがDOM操作可能。他拡張と衝突しない
- **MAIN**: ページと同じ環境。ページのJS変数にアクセス可能だが干渉リスクあり

### 5. run_at オプション

| 値 | タイミング | 用途 |
|----|----------|------|
| `document_start` | DOM構築前 | CSS注入 |
| `document_end` | DOM完成直後 | DOM操作 |
| `document_idle` (デフォルト) | load前後 | 一般的な処理 |

### 6. 動的インジェクション

```js
// background.js から動的に注入
chrome.scripting.executeScript({
  target: { tabId },
  files: ["content.js"],
  world: "ISOLATED"
});
```

`scripting` パーミッション必須。静的宣言より柔軟だが、ユーザージェスチャが必要な場合あり。

---

## Part 3: Background Service Worker [CRITICAL]

### 7. ライフサイクル

- **30秒のアイドル**で自動終了、**5分以上**の処理で強制終了
- グローバル変数は終了時に消失 → `chrome.storage` で永続化
- `window` オブジェクトなし（`self` を使用）
- DOM アクセス不可（Offscreen Document で代替）

### 8. ステート永続化

```js
// NG: グローバル変数はSW終了で消える
let count = 0;

// OK: chrome.storage を使う
await chrome.storage.session.set({ count: 0 });
```

### 9. イベント登録の鉄則

**トップレベルで同期的に登録する**。条件分岐の中に入れると再起動時にリスナーが登録されない。

```js
// 必ずファイルのトップレベルに
chrome.runtime.onInstalled.addListener((details) => { /* ... */ });
chrome.runtime.onMessage.addListener((msg, sender, sendResponse) => { /* ... */ });
```

---

## Part 4: Storage API [HIGH]

### 10. 3つのStorage

| Storage | 容量 | 永続性 | 同期 | 用途 |
|---------|------|--------|------|------|
| `local` | 10MB | ブラウザ再起動後も永続 | なし | 大きなデータ、設定 |
| `sync` | 100KB | Googleアカウント間同期 | あり | ユーザー設定 |
| `session` | 10MB | ブラウザセッション中のみ | なし | 一時データ、機密情報 |

`unlimitedStorage` パーミッションで `local` の10MB制限を撤廃可能。

### 11. 基本操作

```js
await chrome.storage.local.set({ key: "value" });
const result = await chrome.storage.local.get(["key"]);

// 変更監視（全コンテキストで発火）
chrome.storage.onChanged.addListener((changes, area) => {
  if (area === "local" && changes.key) {
    console.log("New:", changes.key.newValue);
  }
});
```

---

## Part 5: Message Passing [HIGH]

### 12. 通信パターン

```
Content Script <--runtime.sendMessage--> Service Worker
Popup          <--runtime.sendMessage--> Service Worker
Popup          <--tabs.sendMessage-->    Content Script
Page(MAIN)     <--window.postMessage-->  Content Script(ISOLATED)
```

### 13. 一発メッセージ

```js
// Content → Background
const res = await chrome.runtime.sendMessage({ type: "GET_DATA", id: 123 });

// Background → Content
const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
await chrome.tabs.sendMessage(tab.id, { type: "UPDATE" });
```

### 14. Long-lived Connection

```js
const port = chrome.runtime.connect({ name: "stream" });
port.postMessage({ type: "SUBSCRIBE" });
port.onMessage.addListener((msg) => { /* ... */ });
```

ストリーミングデータやリアルタイム更新に使う。

---

## Part 6: Permissions [HIGH]

### 15. パーミッション種別

| 種別 | 宣言場所 | 特徴 |
|------|---------|------|
| `permissions` | 必須権限 | インストール時に表示 |
| `host_permissions` | ホスト権限 | ユーザーが個別に許可/拒否可能 |
| `optional_permissions` | 任意権限 | ランタイムでリクエスト |

### 16. activeTab

権限警告なし。ユーザージェスチャ（クリック等）で一時的にアクティブタブへアクセス。タブ閉じ or ナビゲーションで失効。`<all_urls>` の代替として推奨。

---

## Part 7: SNS DOM スクレイピング [HIGH]

### 17. SPA対応の基本

SNSは全てSPA。通常のページロードイベントだけでは不十分。

```js
// MutationObserver でDOM変更を監視
const observer = new MutationObserver((mutations) => {
  for (const m of mutations) {
    for (const node of m.addedNodes) {
      if (node.nodeType === Node.ELEMENT_NODE) processNewElement(node);
    }
  }
});
observer.observe(document.body, { childList: true, subtree: true });
```

### 18. API インターセプト（最も安定）

DOMセレクタはビルドごとに変わる。APIレスポンスを傍受する方が安定。MAIN worldで実行が必要。

```js
const originalFetch = window.fetch;
window.fetch = async function(...args) {
  const response = await originalFetch.apply(this, args);
  const url = typeof args[0] === "string" ? args[0] : args[0]?.url;
  if (url?.includes("/api/v1/")) {
    const clone = response.clone();
    const data = await clone.json();
    window.postMessage({ source: "MY_EXT", data }, "*");
  }
  return response;
};
```

### 19. プラットフォーム別ヒント

| SNS | セレクタの安定性 | 推奨手法 |
|-----|---------------|---------|
| Instagram | 低（class名ハッシュ化） | APIインターセプト |
| TikTok | 中（`data-e2e` 属性あり） | `data-e2e` セレクタ + API |
| YouTube | 高（`ytd-*` カスタム要素） | カスタム要素セレクタ |

詳細なセレクタ例は [reference.md](reference.md) を参照。

---

## Part 8: セキュリティ [CRITICAL]

### 20. CSP（MV3デフォルト）

`script-src 'self'; object-src 'self'` — `unsafe-inline`, `unsafe-eval`, リモートコード全て禁止。

### 21. サニタイゼーション

```js
// NG: innerHTML でユーザーデータ直接挿入
element.innerHTML = userHTML;

// OK: textContent を使う
element.textContent = userText;
```

### 22. eval禁止

`eval()`, `new Function()`, `setTimeout(string)` は全てMV3で禁止。アロー関数で代替。

---

## Part 9: 開発環境 [MEDIUM]

### 23. フレームワーク選択

| FW | 推奨度 | 特徴 |
|----|-------|------|
| **WXT** | 最推奨 | HMR、cross-browser、auto-import |
| Vite+React | 中級向け | 完全な制御、設定多め |
| Plasmo | 良 | 高レベル抽象化、やや不安定 |

### 24. WXT セットアップ

```bash
npx wxt@latest init my-extension --template react
cd my-extension && npm install && npm run dev
```

---

## Reference

manifest.json全フィールド、Storage quota詳細、パーミッション→警告テキスト対応表、SNSセレクタ詳細、Chrome Web Store公開チェックリストは [reference.md](reference.md) を参照。

## Cross-references

- **typescript-best-practices**: Content Script の型安全な実装
- **_security-review**: 拡張機能のパーミッション・CSPレビュー
