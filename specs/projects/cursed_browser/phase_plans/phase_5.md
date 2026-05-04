---
status: draft
---

# Phase 5: README

## Overview

Add a funny, semi-serious README to the repo root. The README should explain what Cursed Browser is, how to build and run it, note the OpenAI API key requirement, and include the joke roadmap from the functional spec.

## Steps

1. Create `README.md` at the repo root with:
   - Project title and one-liner description
   - A humorous but informative explanation of what this app does
   - Requirements section (macOS 14+, Xcode, OpenAI API key)
   - How to build and run (open Xcode project, build, launch, enter API key, browse)
   - How it works (the two-call pipeline: simplify HTML with GPT-5.5, render with gpt-image-2)
   - The joke roadmap (V1 = this, V2 = LLM writes a browser engine per page)

## Tests

- NA: This is a documentation-only change. No code or tests to write.
