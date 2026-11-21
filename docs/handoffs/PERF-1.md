# Agent task handoff — PERF-1, Graphics settings for phones (owner, 2026-11-21)

## Assignment
- **Owner:** Claude, from the owner's play notes on an iPhone:
  - "Immediately following a release, the game animation occasionally locks up temporarily … while the music continues."
  - "The game occasionally throws a WebGL error" (Safari: "WebGL context lost, please reload the page").
- **The owner's direction:** go ahead with the four proposals, with Resolution and Texture Detail as settings (Low, Normal, High; Normal is today's and the default; High at Claude's discretion), and the performance log as a setting, not a web address.
- **State:** DONE (implementation and checks). Not tried on a phone.
- **Branch:** `claude/roguewood-build`.
- **Paths:**
  - new `src/platform/graphics.gd` (autoload `Graphics` in project.godot);
  - `src/bootstrap/bootstrap.gd` (menu entries), `src/platform/web_qa.gd` (status);
  - `tools/author_loader.py` and the generated `export_presets.cfg`;
  - tests: `tests/clubhouse_journey.gd` (J11), `tests/neon_c18_journey.gd` (J03C18), `tests/web/web_journey.mjs` (JW01).

## What was measured (headless Chromium at iPhone size, and a rendered native run)
- **Canvas:** at 3× density an iPhone's canvas is 1170×2532.
- **GPU memory** (the engine's own figures): about 49 MB at the title and 142 MB in a House match, mostly textures. Large source art drawn small accounts for much of it: 1254 px trophies and cards, 724 px icons, the 2172 px logo and the 1024×1536 lane art.
- **At release:** no shader compiles and no texture uploads, for plain and swirled throws; frames normal. Compiles come when a match opens (66) and at the second roll's aim (24). In-match sounds are short and preloaded.
- **Not reproducible here:** Safari's own stalls (it may finish a shader at first draw) and its memory limit. The Performance log is how to see the real cause on the phone.

## What changes for the player
A **Graphics** page in the match menu and the Clubhouse menu (after Sound & Effects). Its settings are saved on the device (`graphics.json` in the save folder), so they survive a reload.

| Setting | Low | Normal (default, as before) | High |
|---|---|---|---|
| Resolution | At most 2× the screen's pixel density (a 3× iPhone's canvas: 780×1688, 56% fewer pixels) | The screen's own density | The screen's density plus 2× anti-aliasing on the 3D lane |
| Texture Detail | Art larger than 512 px is drawn from a copy at most 512 px | The art as made | Art larger than 512 px is drawn with smoothed mipmaps |

- **GPU memory, rendered native run, House match:** Normal 142 MB; Low 77 MB (−46%); High 172 MB (+21%). At the title: 49, 30 and 63 MB.
- **Performance Log** (Off by default): records each frame over 150 ms with the time, where the game was (screen, match state and roll) and GPU memory, plus any lost WebGL context. A corner readout shows the frame rate, the long-frame count and GPU memory. The page lists the latest entries, with **Copy Log** (the full log to the clipboard, to send) and **Clear**. The log is saved, so it survives a reload.
- **A lost WebGL context:** instead of the engine's alert, the page shows "The lane lost its picture", explains that the run is saved after every roll, and offers **Tap to Reload**. It notes the loss, and where the game last was, for the Performance log.
- **Before the engine starts:** the page applies a saved Low resolution (a `localStorage` copy of the setting), so the first frames are light too. The game's own saved setting rules once it starts.

## How it works
- **Resolution (web):** the engine reads `window.devicePixelRatio` every frame. The page's early script wraps it with a cap (`window.rwDensity`); Graphics sets the cap. High sets the root viewport's `msaa_3d`.
- **Texture Detail:** at Low or High, Graphics sweeps the tree (new nodes, plus a slow sweep, 120 nodes a frame). It gives `TextureRect`, `Sprite2D`/`Sprite3D`, `NinePatchRect`, `TextureButton` and `Button` icons, and textures in canvas shader materials and 3D `material_override`s, a copy of large art. Atlas regions are kept in a scaled sheet.
  - Each node remembers its own art by path (a weak reference for art made at runtime), so the full-size texture is freed. The first version kept a strong reference and used more memory, not less.
  - Normal restores each node's art and filter.
- **At the defaults nothing runs:** no sweep, no readout, nothing changed, so every existing test and capture is unaffected.

## Tests
- **J11 (Clubhouse menu):**
  - Graphics starts at Normal, Normal, log off;
  - the page opens from the menu at Normal, and each choice explains itself;
  - Low and Low are saved in `graphics.json`;
  - rendered only: a large image is drawn from a 512 px copy, and Normal puts the original back;
  - a long frame (forced) is logged with "menu" as its place; Copy and Clear work;
  - Escape returns to the menu.
- **J03C18:** the match menu lists Graphics; it opens over the paused lane; Escape returns to the menu.
- **JW01 (web):**
  - the canvas follows a density cap live (0.5 halves it);
  - a saved Low caps the density at 2× while the engine loads, and the game's setting then rules;
  - a real lost context (`WEBGL_lose_context`) shows the reload screen with no alert dialog;
  - the reload's Performance log records the loss.
- **PASS:** `unit`, `integration`, `web`, J01, J03C18, J06, JTUT, J11 headless and rendered.
- **Not tested:** a phone. Whether Low and Low stop the freezes and the lost contexts is for the owner's phone trial, with the Performance log on.

## Follow-up
- With the log from the phone, find the long frames' cause (shader warm-up at match start, or memory).
- **Codex:** large source art drawn small costs GPU memory on phones. The art pipeline could ship display-sized copies.

## Follow-up, PERF-1b: the texture sweep's cost (owner, 2026-11-21)
- **The note:** "Putting textures on anything but normal drops the game to under 20 FPS, making the game almost unplayable. All performance settings stay around 60 FPS."
- **Cause:** every 2 s the sweep walked the whole tree, and for each node already drawing a copy it reloaded the original by path (`_recall` → `load`). The original had been freed on purpose, so each pass decoded and uploaded every full-size image again. It also re-read each shader's uniform list.
- **Fix:**
  - Art already at the current level is skipped without loading anything (`_settled`).
  - Only nodes that can hold art are followed (weak references), revisited every 3 s, 40 a frame.
  - Each shader's texture uniforms are read once.
  - At most one new copy is made a frame, by halving steps instead of one Lanczos pass; a node waiting for its copy is retried next frame.
- **Measured** (rendered native run, House match): the sweep now costs 0.03 ms a frame (Low) and 0.05 ms (High), worst 18 ms when a copy is made. GPU memory is unchanged: Low 76.5 MB, Normal 142 MB.
- **J11 (rendered):** after the swap, the sweep must average under 0.3 ms a frame, worst under 60 ms.
- **Not tested:** the phone's frame rate at Low and High textures.
