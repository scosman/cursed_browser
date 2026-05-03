---
status: complete
---

# Phase 3: URL Normalization + Page Fetching + Events Wired

## Overview

Add the first real logic to the app: URL normalization with validation, HTTP page fetching, an error enum, and wire the Go/Enter action in the chrome bar to trigger a fetch. The full render pipeline does not exist yet -- this phase uses a placeholder that logs the fetched HTML length. The spinner, cancellation, and error alerts are all wired up.

## Steps

1. Create `Cursed/Errors.swift` -- `CursedError` enum conforming to `LocalizedError` with cases: `invalidURL`, `network(underlying: Error)`, `httpStatus(Int)`, `openAI(message: String)`, `badImageData`, `unknown(Error)`. Each case provides a user-facing `errorDescription`.

2. Create `Cursed/URLNormalizer.swift` -- enum with a single static method `normalize(_ raw: String) throws -> URL`. Trims whitespace, prepends `https://` if no scheme, validates via `URL(string:)` and checks `.host != nil`.

3. Create `Cursed/PageFetcher.swift` -- enum with a single static async method `fetch(_ url: URL) async throws -> String`. Uses `URLSession.shared.data(from:)`, rejects non-2xx with `.httpStatus(code)`, decodes body as UTF-8 with ISO-Latin-1 fallback.

4. Update `Cursed/AppState.swift`:
   - Add `var currentError: CursedError? = nil` (published, drives alert)
   - Add `var currentTask: Task<Void, Never>? = nil` (not published, for cancellation)
   - Add `func submitURL()` that normalizes, fetches, logs HTML length, with loading/error state management and cancellation of prior task

5. Update `Cursed/ChromeBar.swift`:
   - Wire Go button action to `appState.submitURL()`
   - Wire `.onSubmit` on the URL TextField to `appState.submitURL()`
   - Disable Go button also when `appState.isLoading`

6. Update `Cursed/CanvasView.swift`:
   - Show `ProgressView` spinner when `appState.isLoading`
   - Keep showing welcome view when no API key

7. Update `Cursed/ContentView.swift`:
   - Add `.alert` modifier driven by `appState.currentError` to show error dialogs

8. Update `project.yml` to add a `CursedTests` test target depending on `Cursed`, with source directory `CursedTests`.

9. Create `CursedTests/URLNormalizerTests.swift` with comprehensive unit tests.

10. Regenerate Xcode project via `xcodegen generate`.

## Tests

- `testBareHostGetsPrefixed`: `google.com` -> `https://google.com`
- `testHostWithPathGetsPrefixed`: `google.com/search` -> `https://google.com/search`
- `testHttpsURLUnchanged`: `https://google.com` -> `https://google.com`
- `testHttpURLUnchanged`: `http://example.com` -> `http://example.com`
- `testWhitespaceIsTrimmed`: `  google.com  ` -> `https://google.com`
- `testEmptyStringThrows`: `` -> throws `CursedError.invalidURL`
- `testWhitespaceOnlyThrows`: `   ` -> throws `CursedError.invalidURL`
- `testInvalidURLThrows`: various invalid inputs -> throws `CursedError.invalidURL`
