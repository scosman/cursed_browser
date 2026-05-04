---
status: complete
---

# Implementation Plan: Cursed Browser

## Phases

- [x] Phase 1: SwiftUI project scaffold + browser chrome — create `Cursed.xcodeproj`, `CursedApp.swift`, `AppState.swift`, `ContentView.swift`, `ChromeBar.swift` (Back, Forward, URL field, Go button — wired to UI state only, no fetching yet), `CanvasView.swift` (blank placeholder), fixed window sizing (1536×1024 + toolbar), `.gitignore`. Verify the app builds and launches with the chrome visible and a blank canvas.
- [x] Phase 2: Welcome screen + API key entry — `WelcomeView.swift` (text field + submit), wire it into the canvas so it appears when `apiKey == nil`, disable the URL field until a key is entered. Session-only storage in `AppState.apiKey`. No persistence. Verify the URL bar enables after key submission.
- [x] Phase 3: URL normalization + page fetching + events wired — `URLNormalizer.swift` with full unit tests, `PageFetcher.swift` (URLSession GET, UTF-8 with ISO-Latin-1 fallback, non-2xx → error), `Errors.swift` (`CursedError` enum), wire Go/Enter from `ChromeBar` to trigger a fetch through a placeholder pipeline that just returns the raw HTML length to a console log. Spinner shown via `AppState.isLoading` while the fetch runs. Cancellation of in-flight task on new submission. Alert on errors.
- [x] Phase 4: OpenAI pipeline + image render — `OpenAIClient.swift` with `simplifyHTML(_:apiKey:)` (POST `/v1/chat/completions`, model `gpt-5.5`, strip code fences) and `renderImage(html:apiKey:)` (POST `/v1/images/generations`, model `gpt-image-2`, size `1536x1024`, b64 PNG). `RenderPipeline.swift` orchestrates fetch → simplify → render → `NSImage`. `CanvasView` displays `currentImage` when present, spinner while loading, welcome when no key. Unit tests for prompt assembly (`OpenAIClientPromptTests`). Full end-to-end working render.
- [x] Phase 5: README — funny, semi-serious README at repo root. Includes the joke roadmap (V1 = this; V2 = LLM writes a browser engine per page). Brief setup/run instructions. Link or note about needing an OpenAI API key.
- [ ] Phase 6 (optional): CSS support — extend `PageFetcher` (or add a `StylesheetFetcher`) to find `<link rel="stylesheet">` hrefs in the fetched HTML, GET each, and inline their contents into the simplification prompt so the renderer has style information to work with. Resolve relative URLs against the page URL. Cap total fetched CSS size to a reasonable limit (e.g. 200KB) to avoid blowing the context window. Tests for the link-extraction helper.
