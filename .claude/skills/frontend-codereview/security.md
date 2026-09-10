    # TSX Security Review

## XSS

**`dangerouslySetInnerHTML`** — always a red flag.
```tsx
// ❌ raw user content → XSS
<div dangerouslySetInnerHTML={{ __html: userInput }} />

// ✅ if HTML is unavoidable, sanitize first
import DOMPurify from "dompurify";
<div dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(userInput) }} />
```

**`href` / `src` with user input** — allows `javascript:` URLs.
```tsx
// ❌
<a href={userUrl}>click</a>

// ✅
const safe = userUrl.startsWith("https://") ? userUrl : "#";
<a href={safe}>click</a>
```

**`eval` / `new Function` / `setTimeout(string)`** — never acceptable in component code.

---

## Sensitive Data Exposure

- Secrets, tokens, API keys in source → move to env vars, never prefix with `REACT_APP_` unless public
- `console.log` of user PII or auth tokens in non-dev code
- Sensitive state stored in `localStorage` without encryption (tokens, SSNs, DOB)
- Prop drilling or context that exposes more than the component needs to know

---

## Auth & Access Control

- UI-only auth guards (`if (!isAdmin) return null`) — always pair with server-side enforcement
- Relying on `localStorage` / `sessionStorage` for session tokens without HttpOnly cookies
- Exposing role/permission data in component props that renders to the DOM as `data-*` attributes

---

## Third-Party & Injection Risk

- `dangerouslySetInnerHTML` fed from a third-party API response without sanitization
- Dynamic `import()` or `require()` with user-controlled strings
- `postMessage` listeners without origin check:
```tsx
// ❌
window.addEventListener("message", (e) => handleData(e.data));

// ✅
window.addEventListener("message", (e) => {
  if (e.origin !== "https://trusted.com") return;
  handleData(e.data);
});
```

---

## React-Specific Leaks

- Unsubscribed async calls updating state after unmount — can leak in-flight request data
- Error boundaries that render raw `error.message` to users (may expose stack traces or internal paths)
- Dev-only logs/debug state left on in production builds (`process.env.NODE_ENV` guard missing)

---

## Quick Severity Guide

| Finding | Severity |
|---|---|
| `dangerouslySetInnerHTML` without sanitize | 🔴 Critical |
| `href`/`src` from unsanitized user input | 🔴 Critical |
| `eval` / `new Function` | 🔴 Critical |
| Hardcoded secret/token in source | 🔴 Critical |
| `postMessage` without origin check | 🟡 High |
| Sensitive data in `localStorage` | 🟡 High |
| UI-only auth gate | 🟡 High |
| `console.log` of PII | 🟠 Medium |
| Error message exposed to UI | 🟠 Medium |
| Dev debug code in production | 🔵 Low |