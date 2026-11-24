# Agent task handoff — PERF-2, GPU memory at Low and a clearer log (owner, 2026-11-23)

## Assignment
- **Owner:** Claude, from the owner's PERF-1 phone log (iPhone, Web; Resolution Low, Texture Detail Low, density 2.0; 2026-11-21 16:39–16:42).
- **State:** DONE (implementation and checks). Not tried on a phone.
- **Branch:** `claude/roguewood-build`.
- **Paths:** `src/platform/graphics.gd`, `src/presentation/rival_art.gd`, `src/presentation/motion_director.gd`, `src/presentation/shop_panel.gd`; tests `tests/perf2_test.gd` (unit), `tests/clubhouse_journey.gd` (J11), `tests/run_tests.gd`.

## What the log showed
- The MB column is GPU memory (`RENDER_VIDEO_MEM_USED`). In one run it climbed to 385 MB by roll 19 (rolls count across a Division's matches). PERF-1 measured 77 MB for a House match at Low.
- At roll 19, every frame in `frame_done` (the frame review and keep-a-card hand) took 170–230 ms for at least six seconds.
- Then the page reloaded (title at 71 MB, 27 s later) with no "WebGL context lost" entry. The loader records a context loss before it reloads, so the tab most likely restarted for memory (iOS ends a page that uses too much).
- After resuming (roll 3), the first frames took 917, 690 and 450 ms. That is Low making its copies of the match's art, one GPU read-back each. At roll 4, frame_done again showed runs of 150–220 ms frames.
- The log kept only its last 60 entries, so the earlier freeze after a release had already been dropped.

## Causes found (native rendered House League, Textures Low, probes not committed)
1. **The Low copy cache never let go.** `_copies` held every copy ever made, so every sheet seen in the session stayed in GPU memory at 512 px; Normal frees art once nothing draws it. Over one House League, copies went 24 → 223; across runs, shops and the Clubhouse they kept growing.
2. **Originals kept alive beside their copies.** At Division 3, 22–23 full-size sheets (132–135 MB, 6 MB each) stayed loaded although Low drew copies. Holders found:
   - `RivalArt._textures`: a static cache of every portrait shown, each holding its 1536×1024 sheet;
   - the HUD's reaction and intro portraits, and Codex's `ability_glyph.gd`, draw from a script variable (`texture`, `identity`) the sweep did not follow;
   - the shop's Sell list kept each item's icon in metadata (`own_icon`);
   - `MotionDirector` made a new texture for every reaction (twice a roll), and the cache kept each one.
3. **The sweep itself is cheap** (about 0.1 ms a frame). Its copies happen when art is first shown (about 24 ms each here, more on a phone).

The steady 175 ms frames in frame_done could not be reproduced here. In software rendering, frame_done costs about 1.8× a rolling frame (camera close on the pins, the score panel, the tall keep-card hand), and the desktop numbers do not grow with the roll count. On the phone it is most likely GPU-bound under memory pressure; the new log fields will show whether that is so.

## Changes
- **Copies live while drawn:** the copy cache holds weak references, plus the most recent copies (24 MB, 96 at most) so art that comes back soon is not copied again. Freed copies are forgotten at each revisit (`_prune`).
- **Portraits:** `RivalArt` keeps a portrait only while something shows it. `MotionDirector` makes each of its three reaction frames once, also held weakly.
- **Scripted views:** the sweep also follows a scripted node's own `texture` and `identity` properties.
- **Shop:** the Sell list keeps the item's id and reloads its icon when a preview ends.
- **Sweep budget:** a frame's sweep stops after 8 ms. Returning to Normal after Low now reloads originals from disk (Low freed them), which once took 100 ms in a single frame.
- **Log:**
  - It keeps 200 entries.
  - A run of long frames at one place within 2 s is one line: count, end time and the longest frame.
  - Each line notes the frame's CPU time (scripts and physics) and draw calls. A frame far longer than its CPU time is waiting on the GPU.
  - Old saved logs still read.

## Measured after (same League, Textures Low)
- Large originals kept loaded: 16, 93–96 MB (were 22–23, 132–135 MB).
- Texture memory at Divisions 2 and 4: 165 and 166 MB (were 213 and 224 MB).
- Copies over the League: steady at about 105–120 (were 223 and climbing).
- End of the League: 178 MB (was 212 MB).

## Still holding originals (follow-ups)
- **Codex:**
  - `neon_n3_presentation.gd` (`_chart`), `neon_n4_presentation.gd` (`metronome`, `hand`) and `neon_n5_presentation.gd` (`icons`) keep item icons in variables;
  - `assets/leagues/house/environment.gd` keeps its `backdrop` atlas.
  - The fix is to hold them in a `texture` or `identity` property the sweep follows, or as an id to reload.
- **Claude, later:** the lane art and the ball and pin sheets used in 3D, and rival sheets still held through the HUD. About 90 MB of originals remain at Low.

## Checks
- `unit` (with `tests/perf2_test.gd`), `content`, `integration`.
- J05 (both modes), JTUT, J06, J08, J11 (both modes), J12R01, J21R04, J22L01, J22L02, JAVN4: PASS.
- J11 (rendered) now checks that a Low copy stays while recent, then is freed with the last node that drew it. It also checks that two long frames make one log line with CPU time and draw calls. Both checks were confirmed to fail when their condition is inverted.

## For the owner
Try Low and Low again with the Performance Log on and send the log. Each line now says whether the long frames were CPU or GPU, and the log covers a whole session.

## Follow-up PERF-2b: the readout out of iOS's top-edge blur (owner, 2026-11-23)
- **The owner's note:** "Now the top of the game screen is blurred. Can't see the perf stats." (Screenshot of the Home Screen app: the readout blurred, the logo below it sharp.)
- **Cause:** since iOS 26, an installed web app gets a system blur over the status bar and the band below it. Developers report that no CSS or meta tag turns it off, and that the remedy is to keep content out of the band. This comes from community reports, not Apple documentation. The readout sat 4 px from the top, inside the band.
- **Change:** the readout sits in the bottom-left corner, left of the home indicator. J11 checks its position.
- **Not checked:** whether the band also softens the top edge of the match's top bar on the owner's phone. That is to confirm on the phone; if it does, the layouts take a top inset in the installed app.
- **Checks:** J11 (both modes), `unit`: PASS.

## Follow-up PERF-2c: the readout in the bottom-right corner (owner, 2026-11-24)
- **The owner's note:** "Now the perf stats aren't fully visible at the bottom" (bottom-left, by the rounded corner and over the Clubhouse footer), then "Just move the perf stats to the bottom right."
- **Change:** the readout is right-aligned in the bottom-right corner, 28 px in from the right edge and 30 px up from the bottom, clear of the rounded corner and the home indicator. J11 checks its place.
- **Asked about the top blur:** it is iOS 26's own, drawn over installed web apps; no page setting turns it off. Developers report an opaque fixed strip at the top may stop it; that is unconfirmed on a device and was not adopted.
- **Checks:** J11 (both modes): PASS.
