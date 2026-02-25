# Chrome Extension MV3 — Reference

Supplementary material for SKILL.md. Detailed API reference, SNS selector investigation, and publishing checklist.

---

## manifest.json Field Reference

| Field | Required | Description |
|-------|----------|-------------|
| `manifest_version` | Required | Must be `3` |
| `name` | Required | Extension name (45 chars max recommended) |
| `version` | Required | Semantic versioning |
| `description` | Recommended | 132 chars max |
| `icons` | Recommended | 16, 32, 48, 128px |
| `action` | Optional | popup, icon, title |
| `background.service_worker` | Optional | SW file path (string) |
| `background.type` | Optional | `"module"` enables ES modules |
| `content_scripts` | Optional | matches, js, css, run_at, world |
| `permissions` | Optional | API permissions |
| `host_permissions` | Optional | Host access permissions |
| `optional_permissions` | Optional | Runtime-requested permissions |
| `web_accessible_resources` | Optional | resources + matches (MV3 format) |
| `content_security_policy` | Optional | extension_pages + sandbox |

---

## Storage Quota Details

| Storage | Capacity | Item Limit | Write Limit |
|---------|----------|------------|-------------|
| `local` | 10MB (`unlimitedStorage` removes limit) | None | None |
| `sync` | 100KB total / 8KB per item | 512 items | 120/min, 1800/hr |
| `session` | 10MB | None | None |

### session Access Level

Not accessible from Content Scripts by default. To change:
```js
chrome.storage.session.setAccessLevel({
  accessLevel: "TRUSTED_AND_UNTRUSTED_CONTEXTS"
});
```

---

## Permission to Warning Text Mapping

| Permission | Warning |
|-----------|---------|
| `storage` | None |
| `activeTab` | None |
| `alarms` | None |
| `scripting` | None |
| `tabs` | "Read your browsing history" |
| `notifications` | "Display notifications" |
| `<all_urls>` | "Read and change all your data on all websites" |
| `bookmarks` | "Read and change your bookmarks" |
| `history` | "Read your browsing history" |

Least privilege principle: Prefer `activeTab` + specific `host_permissions` over `<all_urls>`.

---

## declarativeNetRequest Rule Format

### Rule Structure

```json
{
  "id": 1,
  "priority": 1,
  "action": {
    "type": "block | redirect | allow | modifyHeaders | allowAllRequests"
  },
  "condition": {
    "urlFilter": "||tracking.example.com",
    "resourceTypes": ["script", "image", "xmlhttprequest"],
    "domainType": "thirdParty"
  }
}
```

### URL Filter Syntax

| Pattern | Meaning |
|---------|---------|
| `||` | Domain anchor (matches any scheme) |
| `\|` | Left/right anchor |
| `*` | Wildcard |
| `^` | Separator (non-alphanumeric except `_-.%`) |

### Rule Limits

| Type | Limit |
|------|-------|
| Static rules (per extension) | 300,000 |
| Enabled static rulesets | 50 |
| Dynamic rules | 5,000 |
| Session rules | 5,000 |

### Migration from webRequest

| webRequest (MV2) | declarativeNetRequest (MV3) |
|-------------------|-----------------------------|
| `onBeforeRequest` + `cancel` | `action.type: "block"` |
| `onBeforeRequest` + `redirectUrl` | `action.type: "redirect"` |
| `onHeadersReceived` + modify | `action.type: "modifyHeaders"` |
| Read request body | Not supported (use content script) |

---

## web_accessible_resources Security

### MV2 vs MV3 Format

```json
// MV2: exposed to ALL pages (fingerprinting risk)
"web_accessible_resources": ["injected.js"]

// MV3: scoped by origin
"web_accessible_resources": [{
  "resources": ["injected.js"],
  "matches": ["https://*.target-site.com/*"]
}]
```

### Security Implications

- Any listed resource can be fetched by matching pages via `chrome-extension://<id>/<path>`
- Attackers use this to detect installed extensions (fingerprinting)
- Minimize listed resources and restrict `matches` to necessary origins
- Never expose config files or internal scripts as web-accessible

---

## SNS DOM Scraping

**SNS DOM selectors change frequently. Never hardcode specific selectors. Always verify current DOM structure with DevTools before implementation.**

### Platform Characteristics

| SNS | Selector Stability | Notes |
|-----|-------------------|-------|
| Instagram | Low | Class names hashed per build. API intercept recommended |
| TikTok | Medium | `data-e2e` attributes relatively stable but may change |
| YouTube | High | `ytd-*` custom elements relatively stable but internal structure may vary |

### Selector Investigation Procedure

1. Open DevTools (F12) > Elements panel
2. Right-click target element > "Inspect" to locate
3. Prioritize: `data-*` attributes, custom element names, semantic tags (`article`, `section`)
4. Avoid hashed class names (e.g., `x1abc2de`)
5. API intercept (SKILL.md #18) is often more stable than DOM selectors

### URL Change Detection (All SNS)

```js
// Run in MAIN world
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

Workaround when Service Worker needs DOM access.

```js
await chrome.offscreen.createDocument({
  url: "offscreen.html",
  reasons: ["DOM_SCRAPING"],
  justification: "Parse DOM content"
});
```

- Only `chrome.runtime` messaging API available
- Use cases: DOM parsing, Canvas operations, audio playback

---

## Page to Content Script Communication

```js
// Page (MAIN world) → Content Script (ISOLATED)
window.postMessage({ source: "MY_EXT", type: "DATA", payload: {...} }, "*");

// Content Script receives
window.addEventListener("message", (event) => {
  if (event.source !== window) return;
  if (event.data?.source === "MY_EXT") {
    chrome.runtime.sendMessage(event.data); // Forward to Background
  }
});
```

---

## Chrome Web Store Publishing Checklist

### Prerequisites
- [ ] Developer Dashboard registration ($5 one-time)
- [ ] 2FA enabled
- [ ] Privacy policy prepared (if collecting data)

### Assets
- [ ] Icon 128x128px
- [ ] At least 1 screenshot (1280x800 or 640x400)
- [ ] Clear feature description

### Review Process
- Automated checks + human review
- MV3 extensions tend to be reviewed faster

### Common Rejection Reasons
1. Excessive permissions (`<all_urls>` when only specific domains needed)
2. Unclear description
3. Missing privacy policy
4. Single-purpose principle violation (unrelated features bundled)
5. Remote code execution

---

## Project Structure Example (WXT + React)

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

## Chrome API Mock Examples

Use `vi.mock` (Vitest) to stub `chrome.*` APIs in unit tests for content-logic and SW-handler modules.

### chrome.storage.local

```ts
const store: Record<string, unknown> = {};
vi.stubGlobal('chrome', {
  storage: {
    local: {
      get: vi.fn(async (keys: string[]) =>
        Object.fromEntries(keys.map(k => [k, store[k]]))
      ),
      set: vi.fn(async (items: Record<string, unknown>) => {
        Object.assign(store, items);
      }),
    },
  },
});
```

### chrome.runtime.sendMessage

```ts
vi.stubGlobal('chrome', {
  runtime: {
    sendMessage: vi.fn().mockResolvedValue({ ok: true }),
    onMessage: {
      addListener: vi.fn(),
    },
  },
});
```

### chrome.tabs.query

```ts
vi.stubGlobal('chrome', {
  tabs: {
    query: vi.fn().mockResolvedValue([
      { id: 1, url: 'https://example.com', active: true },
    ]),
    sendMessage: vi.fn().mockResolvedValue(undefined),
  },
});
```

Combine stubs as needed. Reset with `vi.restoreAllMocks()` in `afterEach`.

---

## Troubleshooting

| Problem | Cause | Solution |
|---------|-------|----------|
| SW keeps restarting | 30s idle termination | Persist state with chrome.storage |
| Content Script not running | matches pattern mismatch | Check match in DevTools > Extensions |
| Signature verification error | CSP violation | Remove inline scripts |
| storage.sync write failure | Rate limit exceeded | Debounce write frequency |
| DOM retrieval fails in SPA | No re-injection after navigation | MutationObserver + URL monitoring |
