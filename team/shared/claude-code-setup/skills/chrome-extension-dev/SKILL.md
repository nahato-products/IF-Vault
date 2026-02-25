---
name: chrome-extension-dev
description: "Use when building Chrome extensions, creating browser extensions, writing content scripts, implementing popup UI, configuring manifest.json, handling chrome.storage API, setting up background service workers, designing message passing architecture, managing permissions and host_permissions, configuring declarativeNetRequest rules, securing web_accessible_resources, scraping Instagram DOM, scraping TikTok DOM, scraping YouTube DOM, intercepting SPA API responses, testing extension content scripts and service worker logic, debugging MV3 extensions, migrating from MV2, publishing to Chrome Web Store, or developing browser automation tools. Covers Manifest V3 structure, content script injection, popup React integration, SNS DOM scraping patterns, network request control, extension testing patterns, security best practices, and WXT framework setup. Does NOT cover web app architecture (nextjs-app-router-patterns) or general security auditing (security-review)."
user-invocable: false
---

# Chrome Extension Development (Manifest V3)

MV3 extension design and implementation patterns. Includes SNS DOM scraping section.

## When to Apply

- Creating or modifying Chrome extensions (MV3)
- Implementing Content Scripts / Background Service Workers
- Building Popup UI with React integration
- SNS site DOM scraping (Instagram / TikTok / YouTube)
- Designing chrome.storage / message passing architecture
- Extension security review → see also `security-review` skill

## When NOT to Apply

- Firefox/Safari-only extensions (WebExtension common parts may still help)
- Desktop apps (Electron / Tauri)
- Web development unrelated to browser extensions

---

## Part 1: Manifest V3 Structure [CRITICAL]

### 1. Required Fields

```json
{
  "manifest_version": 3,
  "name": "Extension Name",
  "version": "1.0.0",
  "description": "What it does"
}
```

### 2. MV2 to MV3 Key Changes

| MV2 | MV3 |
|-----|-----|
| `browser_action` / `page_action` | `action` (unified) |
| `background.scripts` (array) | `background.service_worker` (string) |
| `background.persistent` | Removed (always event-driven) |
| hosts in `permissions` | Separated to `host_permissions` |
| Remote code allowed | Remote code completely prohibited |

### 3. manifest.json Template

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

### 4. Execution World

- **ISOLATED** (default): Cannot access page JS but can manipulate DOM. No collision with other extensions
- **MAIN**: Same environment as page. Can access page JS variables but risk of interference

### 5. run_at Options

| Value | Timing | Use Case |
|-------|--------|----------|
| `document_start` | Before DOM construction | CSS injection |
| `document_end` | Right after DOM ready | DOM manipulation |
| `document_idle` (default) | Around load event | General processing |

### 6. Dynamic Injection

```js
// Dynamic injection from background.js
chrome.scripting.executeScript({
  target: { tabId },
  files: ["content.js"],
  world: "ISOLATED"
});
```

Requires `scripting` permission. More flexible than static declaration but may require user gesture.

---

## Part 3: Background Service Worker [CRITICAL]

### 7. Lifecycle

- **30s idle** auto-terminates; **5min+** processing force-terminates
- Global variables lost on termination → persist with `chrome.storage`
- No `window` object (use `self`)
- No DOM access (use Offscreen Document as workaround, see [reference.md](reference.md))

### 8. State Persistence

```js
// BAD: Global variables lost when SW terminates
let count = 0;

// GOOD: Use chrome.storage
await chrome.storage.session.set({ count: 0 });
```

### 9. Event Registration Rule

**Register at top level synchronously.** Listeners inside conditionals won't re-register on SW restart.

```js
// Always at file top level
chrome.runtime.onInstalled.addListener((details) => { /* ... */ });
chrome.runtime.onMessage.addListener((msg, sender, sendResponse) => { /* ... */ });
```

---

## Part 4: Storage API [HIGH]

### 10. Three Storage Areas

| Storage | Capacity | Persistence | Sync | Use Case |
|---------|----------|-------------|------|----------|
| `local` | 10MB | Survives browser restart | No | Large data, settings |
| `sync` | 100KB | Syncs across Google accounts | Yes | User preferences |
| `session` | 10MB | Browser session only | No | Temp data, secrets |

`unlimitedStorage` permission removes 10MB limit on `local`. See [reference.md](reference.md) for quota details.

### 11. Basic Operations

```js
await chrome.storage.local.set({ key: "value" });
const result = await chrome.storage.local.get(["key"]);

// Watch changes (fires in all contexts)
chrome.storage.onChanged.addListener((changes, area) => {
  if (area === "local" && changes.key) {
    console.log("New:", changes.key.newValue);
  }
});
```

---

## Part 5: Message Passing [HIGH]

### 12. Communication Patterns

```
Content Script <--runtime.sendMessage--> Service Worker
Popup          <--runtime.sendMessage--> Service Worker
Popup          <--tabs.sendMessage-->    Content Script
Page(MAIN)     <--window.postMessage-->  Content Script(ISOLATED)
```

### 13. One-shot Message

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

Use for streaming data or real-time updates. See [reference.md](reference.md) for Page-to-Content Script communication details.

---

## Part 6: Permissions [HIGH]

### 15. Permission Types

| Type | Declared in | Behavior |
|------|------------|----------|
| `permissions` | Required | Shown at install |
| `host_permissions` | Host access | User can allow/deny individually |
| `optional_permissions` | Optional | Requested at runtime |

### 16. activeTab

No permission warning. Grants temporary access to active tab on user gesture (click). Expires on tab close or navigation. Preferred over `<all_urls>`. See [reference.md](reference.md) for permission-to-warning mapping.

---

## Part 7: SNS DOM Scraping [HIGH]

### 17. SPA Handling Basics

All SNS sites are SPAs. Standard page load events are insufficient.

```js
// Monitor DOM changes with MutationObserver
const observer = new MutationObserver((mutations) => {
  for (const m of mutations) {
    for (const node of m.addedNodes) {
      if (node.nodeType === Node.ELEMENT_NODE) processNewElement(node);
    }
  }
});
observer.observe(document.body, { childList: true, subtree: true });
```

### 18. API Intercept (Most Stable) [CRITICAL]

DOM selectors change per build. Intercepting API responses is more stable. Must run in MAIN world.

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

### 19. Platform Hints

| SNS | Selector Stability | Recommended Approach |
|-----|-------------------|---------------------|
| Instagram | Low (hashed class names) | API intercept |
| TikTok | Medium (`data-e2e` attributes) | `data-e2e` selectors + API |
| YouTube | High (`ytd-*` custom elements) | Custom element selectors |

See [reference.md](reference.md) for selector investigation procedure and URL change detection pattern.

---

## Part 8: Network Request Control [HIGH]

### 20. declarativeNetRequest (MV3)

MV3 replaces `webRequest` blocking with declarative rules. No access to request body.

```json
{
  "permissions": ["declarativeNetRequest"],
  "declarative_net_request": {
    "rule_resources": [{
      "id": "ruleset_1",
      "enabled": true,
      "path": "rules.json"
    }]
  }
}
```

```json
[{
  "id": 1,
  "priority": 1,
  "action": { "type": "block" },
  "condition": { "urlFilter": "tracking.js", "resourceTypes": ["script"] }
}]
```

Use `updateDynamicRules` for runtime changes. Max 5000 dynamic rules. See [reference.md](reference.md) for rule format and migration from webRequest.

### 21. web_accessible_resources (MV3 Format)

MV3 requires explicit `matches` to restrict which pages can access extension resources.

```json
{
  "web_accessible_resources": [{
    "resources": ["injected.js", "style.css"],
    "matches": ["https://*.example.com/*"]
  }]
}
```

Omitting `matches` or using `<all_urls>` exposes resources to all sites — enables fingerprinting. Restrict to necessary origins only.

---

## Part 9: Security [CRITICAL]

### 22. CSP (MV3 Default)

`script-src 'self'; object-src 'self'` -- `unsafe-inline`, `unsafe-eval`, remote code all prohibited.

### 23. Sanitization

```js
// BAD: innerHTML with user data
element.innerHTML = userHTML;

// GOOD: Use textContent
element.textContent = userText;
```

### 24. eval Prohibition

`eval()`, `new Function()`, `setTimeout(string)` all prohibited in MV3. Use arrow functions instead.

For broader security review, see `security-review` skill.

---

## Part 10: Dev Environment [MEDIUM]

### 25. Framework Selection

| Framework | Recommendation | Features |
|-----------|---------------|----------|
| **WXT** | Best | HMR, cross-browser, auto-import, TypeScript |
| Vite+React | Advanced | Full control, more config required |
| Plasmo | Good | High-level abstraction, less stable |

### 26. WXT Setup

```bash
npx wxt@latest init my-extension --template react
cd my-extension && npm install && npm run dev
```

For React component patterns within popup UI, see `react-component-patterns` skill. For TypeScript configuration, see `typescript-best-practices` skill.

---

## Part 11: Extension Testing Patterns [HIGH]

### 27. Testing Content Scripts

Content scripts run in isolated or main world — test them outside the browser with extracted logic.

```ts
// Extract testable logic from content script
// content-logic.ts (pure functions, testable)
export function extractPostData(element: Element): PostData | null {
  const text = element.querySelector('[data-testid="post-text"]')?.textContent;
  return text ? { text, timestamp: Date.now() } : null;
}

// content.ts (thin shell, hard to test — keep minimal)
import { extractPostData } from './content-logic';
document.querySelectorAll('article').forEach(el => {
  const data = extractPostData(el);
  if (data) chrome.runtime.sendMessage({ type: 'POST', data });
});
```

### 28. Testing Service Worker Logic

Same pattern as #27: extract handlers into testable modules. Key differences from content scripts:

- **State via `chrome.storage`** (globals lost on SW termination) — mock storage in tests
- **Async message handlers** must `return true` to keep `sendResponse` channel open
- Register listeners at top level (thin `background.ts` shell, not unit-tested)

Mock `chrome.*` APIs with vi.mock (see reference.md "Chrome API Mock Examples"). For testing methodology (TDD cycle, AAA pattern, mock boundaries), see `testing-strategy` skill.

---

## Cross-references

- `security-review` — Audit extension for CSP violations, permission over-granting, unsafe innerHTML in popup/content scripts, hardcoded secrets in storage
- `react-component-patterns` — Popup UI component composition, state management within popup context
- `typescript-best-practices` — Type chrome.runtime message payloads with discriminated unions, Zod validation at message boundaries
- `testing-strategy` — TDD cycle and AAA pattern for content-logic / SW-handler unit tests (Part 11); mock boundary rules for chrome.* API stubs
- `ci-cd-deployment` — Automate CRX build, run extension E2E tests, publish to Chrome Web Store via CI

## Reference

manifest.json full field list, Storage quota details, permission-to-warning mapping, SNS selector investigation, Offscreen Document, Page-Content communication, declarativeNetRequest rule format, web_accessible_resources security, Chrome Web Store publishing checklist, WXT project structure, and troubleshooting guide are in [reference.md](reference.md).
