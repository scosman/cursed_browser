# Cursed Browser: Rendering Engine using Visual-LLMs

Instead of using a rendering engine like some kind of *nerd*, Cursed Browser asks an LLM to look at the page's HTML and draw what it thinks it looks like. Every page load is a surprise. Every render is a work of art. It's better than correct, it's *AI Native*.

## Examples: Cursed vs Safari

<p align="center">
  <img src="https://github.com/user-attachments/assets/27d2d637-6fc0-49b7-9b11-37991b1ba889" width="45%" alt="wikipedia rendered by cursed" />
  <img src="https://github.com/user-attachments/assets/10987507-bd12-4fe3-a060-fdc3efea0732" width="45%" alt="wikipedia rendered by safari"/>
</p>

<p align="center">
  <img src="https://github.com/user-attachments/assets/8bbf04e4-fb69-4d3c-b2f3-f0ea3a141854" width="45%" alt="hacker news rendered by cursed"/>
  <img src="https://github.com/user-attachments/assets/da9e6740-3973-4935-a50e-5d0bdcae65c3" width="45%" alt="hacker news rendered by safari"/>
</p>

<p align="center">
  <img src="https://github.com/user-attachments/assets/444b9fd3-2998-4ff0-aa94-de2e06680858" width="45%" alt="cbc.ca rendered by cursed"/>
  <img src="https://github.com/user-attachments/assets/132b9726-43bd-44af-bbde-057540d37066" width="45%" alt="cbc.ca rendered by safari"/>
</p>

<p align="center">
  <img src="https://github.com/user-attachments/assets/115e8a55-4f6f-4a9e-9d7f-c230e0cb760b" width="45%" alt="acid 3 test rendered by cursed"/>
  <img src="https://github.com/user-attachments/assets/ae6a313f-6a27-4a65-b9a7-01fcdc72778b" width="45%" alt="acid 3 test rendered by safari"/>
</p>

<p align="center">
  <img src="https://github.com/user-attachments/assets/5c61594d-4477-429a-9702-c0a6e376a9bd" width="45%" alt="scosman.net homepage rendered by cursed"/>
  <img src="https://github.com/user-attachments/assets/3b6bcc0c-b803-4deb-8a5b-64bc3b334804" width="45%" alt="scosman.net homepage rendered by safari"/>
</p>

## Compared to other "AI native" browsers

| Feature | Arc | Dia | Comet | Atlas | **Cursed** |
|---|:-:|:-:|:-:|:-:|:-:|
| HTML parsed by an LLM token-by-token | ❌ | ❌ | ❌ | ❌ | ✅ |
| CSS interpreted via next-token prediction | ❌ | ❌ | ❌ | ❌ | ✅ |
| Pixels hallucinated by a VLM | ❌ | ❌ | ❌ | ❌ | ✅ |

## Roadmap

**V1** (current, open-source): Ship it. An LLM looks at HTML and draws what it thinks a browser would show. Technically a browser. Legally, probably also a browser. Morally, questionable.

**V2**: (oversubscribed $200m pre-seed, enterprise) The LLM writes a brand new browser engine from scratch every time you load a page. No bloat -- the engine only supports exactly the features that page needs. Extremely efficient.
