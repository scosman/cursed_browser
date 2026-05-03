---
status: complete
---

# Functional Spec: Cursed Browser

## Summary

A native macOS app that imitates a web browser, except instead of using a real rendering engine it asks an LLM to simplify the page's HTML, then asks an image model to "render" that HTML as a PNG, which is displayed in the window. It is a gag.

## Window & Chrome

- Single window. No tabs.
- Window holds three things, top-to-bottom:
  - **Chrome bar** with: Back button, Forward button, URL text field, Go button (or Enter to submit).
  - **Canvas area** showing the rendered PNG (or welcome / loading / nothing).
- **Canvas aspect ratio**: locked at **3:2 landscape** (the size supported by `gpt-image-2`, which generates at 1536×1024 native). The window is resizable, but the canvas always preserves the 3:2 aspect ratio — the user can scale the window up or down freely. Default launch size is smaller than 1536×1024 so the app fits on typical laptop screens. PNGs are drawn scaled-to-fit; the underlying image is always native 1536×1024.
- Back / Forward buttons are present for visual fidelity. They do **not** need to function — clicking them is a no-op (or they may be permanently disabled). No history navigation is implemented.

## App Lifecycle

- On every launch, the app starts with **no API key**.
- The canvas shows a built-in **"Enter Key" welcome view** — a native SwiftUI view (text field + submit button + a friendly "enter your OpenAI API key" prompt) drawn in place of the rendered PNG.
- The URL bar is **disabled** until a key has been entered.
- Once the user enters a key (somewhere in the welcome view — a text field + submit button), the URL bar becomes enabled. The key lives in memory for the session only.
- There is **no persistence**: closing the app forgets the key. Next launch starts at the welcome page again.
- No "settings" screen, no menu item to change the key, no Keychain integration.

## URL Handling

- The URL bar accepts whatever the user types. Two acceptable forms:
  - Full URL: `https://google.com` → use as-is.
  - Bare host or host+path: `google.com` or `google.com/foo` → prepend `https://`.
- No search, no autocomplete, no smart parsing. Anything else → alert dialog "Invalid URL" and do nothing.
- Pressing Enter in the URL bar (or clicking Go) triggers a render.

## Render Pipeline

The pipeline is **two OpenAI calls**: first a text model simplifies the HTML, then an image model "renders" the simplified HTML.

1. User submits a URL.
2. Show a spinner over the canvas (covers any previous render).
3. App performs an HTTP GET against the URL using the default networking stack. Follow redirects. No custom user-agent or special headers.
4. Take the response body as-is (assumed HTML, treated as plain text). **No client-side preprocessing**.
5. **Call 1 — Simplify (GPT 5.5)**. Send the raw HTML to OpenAI's text completion API with a prompt asking it to produce a shorter, render-equivalent HTML stripped of non-visual elements (scripts, etc.). See "Prompt: Simplify" below.
6. **Call 2 — Render (`gpt-image-2`)**. Send the simplified HTML to OpenAI's image generation API at size `1536x1024`. See "Prompt: Render" below.
7. Receive the PNG, display it in the canvas at native resolution. Replace the spinner.

### Prompt: Simplify (Call 1, GPT 5.5)

Roughly:

> Write simplified HTML for this page. One that renders the same, without elements unrelated to rendering: javascript, etc. Simplify to get it down to a reasonable facsimile, but short and sweet.
>
> ```
> {raw HTML}
> ```

The model's output is taken as the simplified HTML and passed to call 2. (No parsing or extraction — we use the response body as-is. If the model wraps it in code fences, we strip the fences; otherwise pass through.)

### Prompt: Render (Call 2, `gpt-image-2`)

Roughly:

> Render this HTML to PNG. Don't render it using an HTML renderer — read it and draw me an image of what it would render as. No SVGs, no code. Just read and draw.
>
> ```
> {simplified HTML}
> ```

Implicit: the canvas is `1536x1024`, content beyond that is simply cut off (the model is instructed to draw a single frame at that size; whatever doesn't fit doesn't fit). For `<img>` tags, the model uses the `alt` attribute as the visual cue (we don't fetch images). In V1 there is no CSS in the input.

## Errors

All errors surface as **native macOS alert dialogs**. The canvas state is unchanged (whatever was last rendered remains, or stays on the welcome page).

Failure modes covered:

- Invalid URL (can't be parsed even after `https://` prepend).
- Network failure (DNS, timeout, no connection).
- Non-2xx response from the target site.
- OpenAI API error (auth failure, rate limit, server error, timeout).
- Anything else unexpected.

A single generic message per category is fine; we do not need fine-grained error UX. The dialog says what went wrong in plain text and dismisses with "OK".

## Out of Scope (V1)

- Tabs, bookmarks, history, downloads.
- Settings, preferences, key management.
- CSS rendering (added in a later implementation phase — see implementation plan).
- Image fetching (alt text only, forever).
- Forward/back navigation (buttons exist but do nothing).
- Search providers.
- Keyboard shortcuts beyond Enter-to-submit.
- Persistence of any kind.
- Stop / Reload buttons.

## Joke Roadmap (in README)

- **V1**: This release.
- **V2**: The LLM writes a browser engine each time we need to render a page. Highly efficient — the browser will only have the needed features, no bloat!
