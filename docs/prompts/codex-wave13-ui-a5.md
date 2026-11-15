Roguewood — Codex Wave 13, UI-A5: an art-lead review of the title screen and the icons, with the adjustments you recommend.
Recommended effort: Medium (High if the review calls for new art).

Repository: https://github.com/khoix/Roguewood (your branch: `codex/roguewood-build`; the coordinator's: `claude/roguewood-build`; never push to `main` and open no pull requests).

The owner asks you, as the project's artistic lead, to review what the coordinator built for the title and the icons, and to change whatever you judge should change. This runs after Wave 13's close matrix and before its PR to main.

Begin:
1. Clone the repository if this session has no checkout, then fetch origin. On `codex/roguewood-build`, merge `origin/claude/roguewood-build` (`05e491f` or later) with a merge commit. Do not rebase or force-push.
2. Read AGENTS.md, then docs/AI-HANDOFF.md: "Wave 13 claims" (your item 4, UI-A5) and "Wave 13 closed".
3. Read docs/handoffs/UI-7.md (the title screen, loading screen and icons as the coordinator built them) and your own UI-A4.md.
4. Look at it all first:
   - J01 rendered: artifacts/e03/rendered/title.png.
   - `qa.py web`: artifacts/e26-w01/headless/web_loading.png and web_title.png.
   - The phone tour in both orientations (01_title.png; see docs/DEVELOPMENT.md).
   - The icon at 180, 32 and 16 px.

What is in scope:
- **The title screen's composition:** src/bootstrap/title_screen.gd. It is presentation code, and you may edit it. Its parts:
  - the backdrop (the House hall, or `assets/brand/title_art.png` if present);
  - the shade into the night;
  - the logo band;
  - the rolling House Ball;
  - the "Tap to start" prompt, its size, colour and pulse;
  - the 0.3 s fade.
- **The icons:** `assets/brand/icon.png`, the favicon and the 180 × 180 apple-touch-icon made from it. Check that they read on light and dark browser tabs and on an iPhone home screen.
- **The boot splash:** `assets/brand/splash.png`, and its background colour.
  - The colour is set in project.godot (`application/boot_splash/bg_color`) and in export_presets.cfg's page head (`theme-color` and the body background, #0b1116).
  - If you want a different colour, change all three places together and say so in your handoff. This is the one exception to those files being the coordinator's.

Keep (the owner's decisions and what the tests read):
- No subtitle. One action: any tap, click, key or gamepad button starts and opens the Clubhouse. No new buttons or menus.
- The node names and fields the journeys use: `title`, `TitleStart` (the full-screen start button), `wordmark` (its text stays "ROGUEWOOD", even when hidden behind the logo), `prompt`, `started`, `open()`.
- Reduced motion keeps the title still. The title shows only when the shell is the running scene.
- The paths `assets/brand/icon.png`, `splash.png`, `logo.png` and `title_art.png`.
- These checks: the web journey reads the favicon as square and at least 192 px, the apple-touch-icon at 180 × 180, and the splash at 720 × 560. If you change those sizes, update the checks in tests/web/web_journey.mjs and say so.

Ownership and limits:
- Paths:
  - assets/brand/;
  - tools/author_brand.py (or your exporter);
  - src/bootstrap/title_screen.gd;
  - the splash colour in project.godot and export_presets.cfg, as above;
  - docs/art/ (a brief docs/art/ui/UI-A5.md);
  - docs/art/ASSET-LEDGER.md.
- Nothing else in src/, content/ or the tests, apart from the web journey's size checks as above.
- Never commit screenshots or rendered captures.
- These must keep passing: unit, J01 headless and rendered, the web journey, the phone tour in both orientations, and JUIA1 and JUIA2.

After:
- Re-run those checks.
- Write docs/handoffs/UI-A5.md: what you reviewed, what you changed and why, what you left and why, and the captures the owner should review (the title in portrait and landscape, the web loading page, and the icon at 180, 32 and 16 px).
- Push, verify the remote SHA and a clean tree, and report the SHA to the coordinator.
