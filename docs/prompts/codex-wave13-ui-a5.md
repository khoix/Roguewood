UI-A5 (Wave 13, added by the owner; continue in this session): an art-lead review of the title screen and the icons. Make the adjustments you recommend, and make the title a little more dynamic.
Recommended effort: Medium (High if the review calls for new art).

First, merge `origin/claude/roguewood-build` (`47db070` or later) into `codex/roguewood-build` with a merge commit. That merge brings Claude's UI-8 changes and the Wave 13 close records. Then read:
- docs/AI-HANDOFF.md: your item 4 under "Wave 13 claims", and "Wave 13 closed";
- docs/handoffs/UI-7.md: the title, loading screen and icons as Claude built them, before your UI-A4 art.

Review, as the artistic lead:
- **The title screen's composition** (src/bootstrap/title_screen.gd; presentation code you may edit): the backdrop, the shade into the night, the logo band, the House Ball, the "Tap to start" prompt and the 0.3 s fade out.
- **The icons:** `assets/brand/icon.png`, the favicon and the 180 × 180 apple-touch-icon made from it. Check them on light and dark browser tabs and on an iPhone home screen.
- **The boot splash:** `assets/brand/splash.png`, and its colour.

A little more dynamic (owner, 2026-11-15):
- Motion today is only a slowly rolling ball and a pulsing prompt. Add life suited to the hall at night, for example:
  - an entrance for the logo and the ball;
  - light from the lamps or the window;
  - drifting stars or dust in the light;
  - a gentle parallax on the backdrop;
  - a beat when the player taps, before the fade.
- Keep it light: the title must stay readable at once, never delay the first tap from working, and cost little on a phone (the web build runs single-threaded).
- Reduced motion keeps everything still, as now (`title.open(reduced)`).

Keep (the owner's decisions and what the tests read):
- No subtitle. One action: any tap, click, key or gamepad button starts and opens the Clubhouse. No new buttons or menus.
- The names the journeys use: `title`, `TitleStart` (the full-screen start button), `wordmark` (its text stays "ROGUEWOOD", even when hidden behind the logo), `prompt`, the signal `started`, and `open()`.
- The title shows only when the shell is the running scene. J01 and the web journey pass it with real input.
- The paths `assets/brand/icon.png`, `splash.png`, `logo.png` and `title_art.png`.
- The web journey's checks: the favicon square and at least 192 px, the apple-touch-icon 180 × 180, and the splash 720 × 560. If you change those sizes, update the checks in tests/web/web_journey.mjs and say so.
- **The splash colour:** it is set in project.godot (`application/boot_splash/bg_color`) and in export_presets.cfg's page head (`theme-color` and the body background, #0b1116). If you change it, change all three together and say so in your handoff. This is the one exception to those files being the coordinator's.

Paths:
- assets/brand/;
- tools/author_brand.py (or your exporter);
- src/bootstrap/title_screen.gd;
- the splash colour, as above;
- docs/art/ (a brief docs/art/ui/UI-A5.md);
- docs/art/ASSET-LEDGER.md.

Nothing else in src/, content/ or the tests, apart from the web journey's size checks. Never commit screenshots or rendered captures.

When done:
- Re-run unit, J01 headless and rendered, `qa.py web`, the phone tour in both orientations, and JUIA1 and JUIA2.
- Add UI-A5 to your WAVE13-CODEX.md and write docs/handoffs/UI-A5.md:
  - what you changed and why, and what you left and why;
  - the motion you added and its reduced-motion behaviour;
  - the captures the owner should review: the title in portrait and landscape, a short sequence of the motion, the web loading page, and the icon at 180, 32 and 16 px.
- Push, verify the remote SHA and a clean tree, and report the SHA to the coordinator.
