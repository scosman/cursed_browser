---
status: complete
---

# Cursed — The Browser

A gag project. "Cursed" the browser.

**Process note:** This is a joke project — skip CRs (code reviews) during `/spec implement`. Coding agent → commit, no CR loop.

The idea is simple: instead of rendering HTML/CSS using a browser engine, we just send it all to a VLM and get it to render a PNG.

Will it be good? No.
Will it be funny? Yes.

## Basic scope

- macOS app that looks like a browser. URL bar, forward, back. No need for tabs — it's a joke.
- Takes an API key: OpenAI API key on startup. Calls the OpenAI API, GPT 5.5.
- Renders a standard dimension each time (4:3). System prompt instructs it to truncate content below that. Window stays at that aspect resolution.
- README: write a funny, semi-serious readme.
- TBD: download CSS files or not? Start with just the page HTML; make CSS a later phase.

## Out of scope

- Image downloading: we don't download linked images. We just instruct the VLM to render any images using the alt text.

## Roadmap (funny bit of readme)

- **V1**: This release.
- **V2**: The LLM writes a browser engine each time we need to render a page. Highly efficient — the browser will only have the needed features, no bloat!
