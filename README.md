# Cursed Browser

A native macOS web browser that has absolutely no idea how to render HTML.

Instead of using a rendering engine like some kind of *nerd*, Cursed Browser asks an LLM to look at the page's HTML and draw what it thinks it would look like. Every page load is a surprise. Every render is a work of art. Nothing is correct. It's perfect.

## How It Works

1. You type a URL and press Enter.
2. The app fetches the page's raw HTML like a normal browser.
3. GPT-5.5 reads the HTML and produces a simplified version (strips scripts, ads, and other non-visual noise).
4. `gpt-image-2` reads the simplified HTML and *draws a picture* of what it thinks the page looks like.
5. That picture is your "rendered" web page.

There is no DOM. There is no layout engine. There is no CSS parser. There is only vibes.

## Requirements

- macOS 14 (Sonoma) or later
- Xcode 16+
- An [OpenAI API key](https://platform.openai.com/api-keys) with access to `gpt-5.5` and `gpt-image-2`

## Build & Run

1. Open `Cursed.xcodeproj` in Xcode.
2. Build and run (Cmd+R).
3. The app launches with a welcome screen. Paste your OpenAI API key and hit Submit.
4. Type a URL in the address bar and press Enter (or click Go).
5. Wait. Marvel at the result. Repeat.

Your API key is stored in memory for the session only. Quit the app and it's gone. There are no settings. There is no settings screen. There is nothing to configure. This is not that kind of browser.

## Features

- **Address bar**: Type URLs. Press Enter. That's it.
- **Back / Forward buttons**: They're there. They don't do anything. They look nice.
- **Error handling**: If something goes wrong, you get an alert. It tells you what happened. You click OK and move on with your life.
- **Aspect ratio lock**: The window maintains a 3:2 aspect ratio because that's what the image model outputs. You can resize, but you can't escape the ratio.

## What It Costs

Each page load makes two OpenAI API calls (one text completion, one image generation). This is not a free hobby. Budget accordingly, or just show it to your friends once and call it a day.

## Roadmap

**V1** (current): Ship it. An LLM looks at HTML and draws what it thinks a browser would show. Technically a browser. Legally, probably also a browser. Morally, questionable.

**V2**: The LLM writes a brand new browser engine from scratch every time you load a page. No bloat -- the engine only supports exactly the features that page needs. Extremely efficient. What could go wrong.
