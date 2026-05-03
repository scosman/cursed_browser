---
status: complete
---

# Phase 2: Welcome Screen + API Key Entry

## Overview

Add a welcome screen that prompts for an OpenAI API key when the app launches. The welcome view displays inside the canvas area. The URL field and Go button in the chrome bar are disabled until a valid key is entered. The key is stored in memory only (session-only, no persistence).

## Steps

1. Create `Cursed/WelcomeView.swift` -- a centered SwiftUI view containing:
   - A title/heading ("Welcome to Cursed")
   - A brief description ("Enter your OpenAI API key to get started")
   - A SecureField for the API key input (bound to local state)
   - A Submit button that writes the entered key to `appState.apiKey`
   - The submit button is disabled when the text field is empty

2. Update `Cursed/CanvasView.swift` to:
   - Accept `appState` as an `@ObservedObject`
   - Show `WelcomeView` when `appState.apiKey == nil`
   - Show the blank canvas background when a key has been entered

3. Update `Cursed/ContentView.swift` to pass `appState` through to `CanvasView`.

4. Update `Cursed/ChromeBar.swift` to:
   - Disable the URL TextField when `appState.apiKey == nil`
   - Disable the Go button when `appState.apiKey == nil`
   - Back/Forward remain always-disabled as before

5. Regenerate the Xcode project with `xcodegen generate` (new file added).

6. Build with `xcodebuild` and iterate until clean.

## Tests

- No tests for Phase 2 (UI-only changes, no testable logic). Tests begin in Phase 3 with URLNormalizer.
