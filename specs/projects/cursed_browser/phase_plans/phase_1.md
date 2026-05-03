---
status: draft
---

# Phase 1: SwiftUI Project Scaffold + Browser Chrome

## Overview

Create the Xcode project structure and the basic browser chrome UI. The app should build and launch, displaying a non-resizable window with a toolbar (Back, Forward, URL field, Go button) and a blank 1536x1024 canvas area. No networking, no OpenAI, no welcome view -- just the scaffold and chrome.

## Steps

1. Create `.gitignore` at repo root for Xcode/Swift projects (DerivedData, xcuserdata, .DS_Store, build/, *.xcuserstate, etc.)

2. Create `Cursed/` source directory and `Cursed/Assets.xcassets/` with minimal asset catalog structure (Contents.json + AppIcon.appiconset placeholder).

3. Create `Cursed/AppState.swift`:
   ```swift
   @MainActor
   final class AppState: ObservableObject {
       @Published var apiKey: String? = nil
       @Published var urlText: String = ""
       @Published var isLoading: Bool = false
       @Published var currentImage: NSImage? = nil
   }
   ```

4. Create `Cursed/ChromeBar.swift` -- a horizontal bar with:
   - Back button (SF Symbol `chevron.left`, disabled)
   - Forward button (SF Symbol `chevron.right`, disabled)
   - URL TextField bound to `appState.urlText`
   - Go button (SF Symbol `arrow.right`, no-op for now)

5. Create `Cursed/CanvasView.swift` -- a blank placeholder view, fixed at 1536x1024 using `Color.white` or `Color(nsColor: .windowBackgroundColor)`.

6. Create `Cursed/ContentView.swift` -- vertical stack: ChromeBar on top, CanvasView below.

7. Create `Cursed/CursedApp.swift` -- `@main` App struct with a `WindowGroup` scene, using `.windowResizability(.contentSize)` to enforce non-resizable window.

8. Create `project.yml` for xcodegen at repo root, targeting macOS 14+, Swift 5, bundleId `com.cursed.browser`, source `Cursed/`.

9. Run `xcodegen generate` to produce `Cursed.xcodeproj`.

10. Build with `xcodebuild -project Cursed.xcodeproj -scheme Cursed build -destination 'platform=macOS'` and iterate until clean.

## Tests

- No tests for Phase 1 (scaffold only, no logic to test). Tests begin in Phase 3.
