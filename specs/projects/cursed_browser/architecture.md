---
status: complete
---

# Architecture: Cursed Browser

Small project. Single architecture doc. No component-design files.

## Tech Stack

- **Language**: Swift 5.x.
- **UI**: SwiftUI for the entire app (window, toolbar, welcome view, canvas).
- **Min macOS**: 14 (Sonoma). Modern enough for current SwiftUI; no need to support older.
- **Build / packaging**: Xcode project (`Cursed.xcodeproj`). App bundle, signed locally for dev. No Mac App Store concerns.
- **Networking & OpenAI calls**: `URLSession` directly. No third-party SDK. The OpenAI HTTP API is small enough that adding a dependency isn't worth it for a gag.
- **Concurrency**: Swift `async/await` throughout.
- **Tests**: A handful of unit tests around URL normalization and the prompt assembly. Skip UI tests. Skip live-network tests. This is a joke; we don't need a coverage target.

## App Structure

Single SwiftUI app target. Approximate file layout:

```
Cursed/
  CursedApp.swift           // @main, defines the Scene
  AppState.swift            // ObservableObject — apiKey, currentImage, isLoading, currentURL
  ContentView.swift         // Root view: chrome bar + canvas, switches between welcome/loading/image
  ChromeBar.swift           // Back, Forward, URL field, Go button
  WelcomeView.swift         // API-key entry view (used when apiKey == nil)
  CanvasView.swift          // Hosts either the rendered Image, the spinner, or the welcome view
  URLNormalizer.swift       // Bare-host → https:// logic, basic validation
  PageFetcher.swift         // URLSession wrapper that GETs a URL → returns body String
  OpenAIClient.swift        // Two methods: simplifyHTML(_:) and renderImage(html:)
  RenderPipeline.swift      // Orchestrates fetch → simplify → render → image, surfaces errors
  Errors.swift              // CursedError enum
Cursed/Assets.xcassets/     // App icon
CursedTests/
  URLNormalizerTests.swift
  OpenAIClientPromptTests.swift  // verifies prompt strings include the HTML body
```

Total expected size: well under 1000 lines.

## Data Model

There is essentially no model. App state lives in one `ObservableObject`:

```swift
@MainActor
final class AppState: ObservableObject {
    @Published var apiKey: String? = nil          // session-only
    @Published var urlText: String = ""           // bound to URL field
    @Published var isLoading: Bool = false
    @Published var currentImage: NSImage? = nil   // last successful render

    let pipeline: RenderPipeline
    init() { self.pipeline = RenderPipeline() }
}
```

Nothing persisted. Nothing on disk. No history list (back/forward are decorative).

## Window & Sizing

- `WindowGroup` with a single window.
- Canvas has a fixed **3:2 aspect ratio** (matches `gpt-image-2` output at 1536×1024). The window is **resizable** but the canvas's aspect ratio is locked, so the user can scale freely while keeping the rendered image undistorted. Default launch size: smaller than 1536×1024 so it fits on typical screens (~1100×~733 canvas + toolbar). PNGs are scaled to fit the canvas at draw time; native PNG is always the same 1536×1024.
- The canvas always shows one of three things, in this priority: welcome view (if no API key), spinner (if `isLoading`), the current PNG (if any), otherwise blank.

## Render Pipeline

`RenderPipeline.load(url:apiKey:)` is the orchestrator. Pseudocode:

```swift
func load(url rawURL: String, apiKey: String) async throws -> NSImage {
    let url = try URLNormalizer.normalize(rawURL)        // throws .invalidURL
    let html = try await PageFetcher.fetch(url)          // throws .network / .httpStatus
    let simplified = try await openAI.simplifyHTML(html, apiKey: apiKey)  // throws .openAI
    let pngData = try await openAI.renderImage(html: simplified, apiKey: apiKey)  // throws .openAI
    guard let image = NSImage(data: pngData) else { throw CursedError.badImageData }
    return image
}
```

Called from a SwiftUI `Task` triggered by URL submission. While running, `AppState.isLoading = true`. On success, `currentImage = result`. On failure, present an `NSAlert`.

### URL Normalization

```swift
enum URLNormalizer {
    static func normalize(_ raw: String) throws -> URL {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw CursedError.invalidURL }
        let withScheme = trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://")
            ? trimmed
            : "https://\(trimmed)"
        guard let url = URL(string: withScheme), url.host != nil else {
            throw CursedError.invalidURL
        }
        return url
    }
}
```

### Page Fetcher

`URLSession.shared.data(from:)`. Default headers (so we get whatever Apple sends — fine). Decode response body as UTF-8 with a fallback to ISO-Latin-1 if UTF-8 fails (some sites lie about encoding; this avoids erroring on garbage). Reject non-2xx with `.httpStatus(code)`.

### OpenAI Client

Two methods, both POST `application/json` to `api.openai.com`, `Authorization: Bearer <apiKey>`:

**`simplifyHTML(_:apiKey:) async throws -> String`**
- Endpoint: `POST /v1/chat/completions`
- Model: `gpt-5.5`
- Single user message body:
  ```
  Write simplified HTML for this page. One that renders the same, without elements unrelated to rendering: javascript, etc. Simplify to get it down to a reasonable facsimile, but short and sweet.

  ```
  {raw HTML}
  ```
  ```
- Returns `choices[0].message.content`. If wrapped in fenced code blocks (```html ... ``` or ``` ... ```), strip the fences. Otherwise return as-is.

**`renderImage(html:apiKey:) async throws -> Data`**
- Endpoint: `POST /v1/images/generations`
- Model: `gpt-image-2`
- Size: `1536x1024`
- Response format: base64 PNG (`response_format: "b64_json"`).
- Prompt body:
  ```
  Render this HTML to PNG. Don't render it using an HTML renderer — read it and draw me an image of what it would render as. No SVGs, no code. Just read and draw.

  ```
  {simplified HTML}
  ```
  ```
- Returns the decoded PNG `Data`.

Both methods decode JSON with `JSONDecoder` and small `Codable` structs scoped to the file. On non-2xx OpenAI responses, throw `.openAI(message:)` with whatever error string the API returned (or "OpenAI request failed" if we can't parse).

## Error Handling

Single enum, mapped to alerts:

```swift
enum CursedError: LocalizedError {
    case invalidURL
    case network(underlying: Error)
    case httpStatus(Int)
    case openAI(message: String)
    case badImageData
    case unknown(Error)

    var errorDescription: String? { ... }  // user-facing string per case
}
```

The pipeline throws; `ContentView` catches at the call site, sets `isLoading = false`, and shows an `NSAlert` with the localized description. Canvas state is unchanged on error (per spec).

No retries. No backoff. No telemetry. No logging beyond `print` for dev.

## Concurrency Notes

- All UI state on `@MainActor` (the AppState).
- Pipeline functions are `nonisolated` async; they hop back to MainActor only when updating state.
- Cancellation: if the user submits a new URL while one is in flight, cancel the prior task. Trivial to do with structured concurrency — keep a `Task?` in `AppState` and `cancel()` it before starting a new one.

## Testing

Two small test files. Both pure, no network.

- **`URLNormalizerTests`**: `google.com` → `https://google.com`; `https://google.com` unchanged; `   ` → throws; `not a url ☹` → throws or returns something benign (assert behavior either way).
- **`OpenAIClientPromptTests`**: extract the prompt-building helpers as testable functions; verify the simplify prompt and the render prompt both contain the input HTML inside fenced code blocks.

That's the whole test suite. Live API tests are unnecessary; the gag works or it doesn't.

## Out-of-Scope Reaffirmed

- No Keychain, no UserDefaults, no settings, no preferences.
- No CSS handling in V1 (later phase will add: include the linked stylesheet content in the simplification prompt).
- No image fetching, ever.
- No real history. Back/Forward buttons render but are no-ops (or `.disabled(true)` — pick whichever looks fine).
- No tabs, bookmarks, downloads, find-in-page, dev tools, etc.

## Notes for Implementation Plan

This is a small enough project that 2 phases is plenty:

1. **Phase 1**: Working V1 — welcome view, chrome bar, fetch + two-call OpenAI pipeline, render PNG, basic error alerts, README.
2. **Phase 2 (optional)**: CSS support — fetch linked stylesheets and include their content in the simplification prompt.
