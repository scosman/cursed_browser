---
status: complete
---

# Phase 4: OpenAI Pipeline + Image Render

## Overview

Add the two-call OpenAI pipeline that turns a fetched HTML page into a rendered PNG. `OpenAIClient.swift` handles the HTTP calls (simplify HTML via GPT-5.5 chat completions, render image via gpt-image-2). `RenderPipeline.swift` orchestrates fetch -> simplify -> render -> NSImage. The canvas displays the rendered image. Unit tests verify prompt assembly.

## Steps

1. Create `Cursed/OpenAIClient.swift`:
   - Define small Codable request/response structs scoped to the file for chat completions and image generation.
   - `static func buildSimplifyPrompt(html: String) -> String` -- builds the user-message prompt with fenced HTML.
   - `static func buildRenderPrompt(html: String) -> String` -- builds the image-generation prompt with fenced HTML.
   - `static func simplifyHTML(_ html: String, apiKey: String) async throws -> String` -- POST to `/v1/chat/completions`, model `gpt-5.5`, returns `choices[0].message.content` with code fences stripped.
   - `static func renderImage(html: String, apiKey: String) async throws -> Data` -- POST to `/v1/images/generations`, model `gpt-image-2`, size `1536x1024`, `response_format: "b64_json"`, returns decoded PNG Data.
   - `static func stripCodeFences(_ text: String) -> String` -- helper to remove markdown code fences from model output.
   - Both API methods throw `.openAI(message:)` on non-2xx or parse failure.

2. Create `Cursed/RenderPipeline.swift`:
   - `func load(url rawURL: String, apiKey: String) async throws -> NSImage`
   - Orchestrates: normalize URL -> fetch HTML -> simplify via OpenAI -> render via OpenAI -> decode NSImage.
   - Throws `CursedError.badImageData` if PNG data can't be decoded to NSImage.

3. Update `Cursed/AppState.swift`:
   - Add `let pipeline = RenderPipeline()` property.
   - Replace the placeholder `submitURL()` body: call `pipeline.load(url:apiKey:)` and assign result to `currentImage`.

4. Update `Cursed/CanvasView.swift`:
   - Add a branch to display `appState.currentImage` when present (after loading is done and API key exists).
   - Image should scale to fit the canvas while preserving aspect ratio.

5. Add `OpenAIClient.swift` and `RenderPipeline.swift` to the Cursed target in `project.pbxproj`.

6. Create `CursedTests/OpenAIClientPromptTests.swift`:
   - Test that `buildSimplifyPrompt` includes the input HTML inside fenced code blocks.
   - Test that `buildRenderPrompt` includes the input HTML inside fenced code blocks.
   - Test that `stripCodeFences` correctly strips ```html ... ``` wrappers.
   - Test that `stripCodeFences` correctly strips bare ``` ... ``` wrappers.
   - Test that `stripCodeFences` passes through text without fences unchanged.

7. Add `OpenAIClientPromptTests.swift` to the CursedTests target in `project.pbxproj`.

## Tests

- `testSimplifyPromptContainsHTML`: verifies the simplify prompt embeds the HTML in fenced code blocks
- `testSimplifyPromptContainsInstruction`: verifies the simplify prompt includes the instruction text
- `testRenderPromptContainsHTML`: verifies the render prompt embeds the simplified HTML in fenced code blocks
- `testRenderPromptContainsInstruction`: verifies the render prompt includes the instruction text
- `testStripCodeFencesWithHTMLTag`: strips ```html\n...\n``` wrappers
- `testStripCodeFencesWithBareFence`: strips bare ```\n...\n``` wrappers
- `testStripCodeFencesNoFences`: passes through unfenced text unchanged
