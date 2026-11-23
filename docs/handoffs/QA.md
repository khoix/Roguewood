# Agent task handoff — QA-1 to QA-8, faster tests and fewer tokens (owner, 2026-11-20)

## Assignment
- **Owner:** Claude, at the owner's request: "look for ways to optimize tests so they don't take as long to run or use up unnecessary tokens", with https://code.claude.com/docs/en/costs; then "Do all of them. Make sure to verify the approach where appropriate (like with 8) and update Codex on any new process."
- **State:** DONE.
- **Branch:** held on `claude/gracious-hopper-2npyl2` while PR #51 is open; it joins `claude/roguewood-build` for the next PR.
- **Paths:**
  - CI: `.github/workflows/bootstrap.yml`, `e11-art.yml`, `e12-motion.yml`, and `tools/ci_retry.sh`;
  - tooling: `tools/qa.py`, and `src/platform/qa_render.gd` with its autoload in `project.godot`;
  - docs: docs/AI-HANDOFF.md (split), docs/AI-HANDOFF-HISTORY.md, AGENTS.md, docs/prompts/codex-wave14-session.md and ADR 008.

## What was measured first (full matrix m31, 252 commands, 3 workers, 64 min wall)
- **Rendered journeys:** 142 of 187 test-minutes (76%). A rendered run took 4 to 27 times its headless twin; JAVC04B took 692 s against 26 s.
- **The local matrix duplicated CI:** it was generated from the same workflow file.
- **CI ran twice per commit** while a PR was open (#521 and #522, #523 and #524), and ran in full for docs-only commits (#529, 77 min).
- **Tokens:**
  - qa.py printed every engine run's full output, even on a pass: 4.8 KB on average, 285 KB for `export`;
  - docs/AI-HANDOFF.md, which every session reads first, was 1,076 lines (159 KB, about 40k tokens).

## Changes
1. **QA-1, one CI run per commit:**
   - The `pull_request` trigger is gone; a PR shows its head commit's push checks.
   - A newer push to a branch cancels its older run (`concurrency`, never on main).
   - `e11-art.yml` drops its duplicate pull-request trigger too.
2. **QA-2, docs-only pushes run nothing** (`paths-ignore: docs/**, **.md`). Verified first that no test, tool or game file reads anything under docs/.
3. **QA-3, package installs that cannot hang a job:**
   - `tools/ci_retry.sh` runs `apt` and the Playwright browser install with three attempts of at most 5 minutes each. A failed index update (one mirror down) is tolerated.
   - One time-limited step installs the display packages for both shards. #524 (mirror refusing) and #528 (`apt-get update` hung until the 90-minute limit) would now fail or recover in minutes.
4. **QA-4, CI is the full gate:**
   - Locally, `qa.py batch` runs just what a change touches, three at a time, one line each, with failures' tails at the end.
   - `qa.py matrix [--shard game|art]` runs CI's own list locally, read from the workflow, for wave closes or a CI outage.
   - AGENTS.md and docs/AI-HANDOFF.md ("Testing and CI") state the rule.
5. **QA-5, qa.py is quiet:**
   - A pass prints `PASS <what> in N s`. A failure prints its error lines, the last 40 lines and the log's path.
   - Every engine run's full output is in a log (the journey's own, or `artifacts/qa/`).
   - `--verbose` or `QA_VERBOSE=1` restores the old output; CI sets it, so CI logs are unchanged.
6. **QA-6, the checkpoint is split:**
   - docs/AI-HANDOFF.md holds the current state only: 1,076 → 204 lines (159 → 26 KB).
   - Everything older moved verbatim to docs/AI-HANDOFF-HISTORY.md. A line-by-line check confirms every old line is in one of the two files.
   - The sections Codex's prompts name ("Wave 14 claims", "Wave 14 progress", "Ownership, lanes and hand-offs") stay in the short file.
7. **QA-7, the long poles:**
   - **The slice strategy simulation** has no pass or fail thresholds; it writes ADR 008's balance report. `qa.py slice` now runs 50 seeded games per strategy (it only has to run), and `--runs 400` regenerates the report. ADR 008 notes it.
   - **JAVC04B** was slow only because of drawing (27× its headless run), so QA-8 fixes it.
8. **QA-8, rendered journeys draw only the frames a capture waits for:**
   - **How:** the `QaRender` autoload (`src/platform/qa_render.gd`) turns the render loop off. It draws a frame when something waits on `RenderingServer.frame_post_draw` (every capture does), and every 30th frame besides.
   - **Inert in the game:** it frees itself unless qa.py passes `--qa-render-on-demand` to a rendered run.
   - **Fixed frame rate only:** qa.py passes it only to journeys with `--fixed-fps` (110 of 111 rendered journeys). Their timing never depends on how long a frame takes to draw. J01, which has no fixed rate, draws every frame.
   - **Override:** `--draw=all` draws every frame.

## Verifying QA-8 (both draw modes, captures compared pixel by pixel)
| Journey | Every frame | On demand | Frames drawn | Captures |
|---|---|---|---|---|
| J05 (shop, lab content) | 32 s | 14 s | 65 of 1,630 | 12 of 12 identical |
| J22L01ART (House theme; reads pixels) | 21 s | 11 s | 35 of 661 | 14 of 14 identical |
| J22L02ART (Neon theme; reads pixels) | 17 s | 10 s | 41 of 931 | 10 of 10 identical |
| JAVC03A | 144 s | 36 s | 132 of 3,567 | 15 of 15 identical |
| J06 (the slice, awards) | 253 s | 51 s | 192 of 5,551 | same differences as two ordinary runs (below) |
| JAVC04B (the slowest) | 590 s | 59 s | 212 of 5,746 | 22 of 23 identical; the 23rd is a random rival line |

- **A first version broke the lane.** The lane's SubViewport (UPDATE_WHEN_VISIBLE) renders only if the last drawn frame showed it. With frames skipped, the capture's draw left it black in House-themed captures (J06, JAVC03A, JAVC04B).
  - **Fix:** in this mode, such viewports update at every drawn frame (UPDATE_ALWAYS). Frames not drawn still render nothing.
  - **After the fix:** the rows above.
- **J06's remaining differences are the game's own randomness:**
  - Two ordinary runs differ on the same captures: the award fireworks, and the rival line picked at random (UI-21).
  - One capture differs by 3 pixels.
- **Drawing bugs still surface:** a `_draw()` that errors raises the same SCRIPT ERROR with frames skipped, because `_draw` runs every frame whether or not the frame is drawn. Shaders still compile at the frames that are drawn.
- **Pixel-reading journeys:** every one reads its image right after waiting for a drawn frame, so it reads a current frame. J22L01ART and J22L02ART read pixels and pass identically.

## Tests
- `py_compile` on qa.py; YAML parse of every workflow; `bash -n` on ci_retry.sh.
- `qa.py unit` (quiet: `PASS unit in 57 s`); J01 with `--inject-failure` prints the failure excerpt and the log path.
- `qa.py batch content J01 J01:rendered`: 3 of 3.
- `qa.py matrix` reproduces CI's 252 commands exactly (75 game, 177 art).
- The QA-8 comparisons above.
- **Full local matrix with the new defaults, and CI on the holding branch:** see "Result" below.

## Result
- **Full local matrix with the new defaults (`qa.py matrix`, `d8c46bd`):**
  - **Time:** 28 min wall, against 64 min before (m31). That is 81 test-minutes against 187: rendered journeys 142 → 41, headless 32 → 35, the slice simulation 595 → 82 s.
  - **Result:** 251 of 252. The web journey (JW01) failed with a real bug: the Web and desktop exports exclude `tools/`, so the `QaRender` autoload could not load in the shipped game ("Attempt to open script 'res://tools/qa_render.gd' … File not found"). CI's game shard (#532) failed on the same check.
  - **Fix:** the autoload moved to `src/platform/qa_render.gd`, which ships, and is inert there.
  - **Recheck:** `web`, `export`, J01 and J05 rendered (drawing on demand): PASS.
- **CI #532** (holding branch, `d8c46bd`) proved the new install steps:
  - `ci_retry.sh apt` installed the display packages;
  - `ci_retry.sh playwright` installed Chromium;
  - the game shard then failed only on the bug above.
- **CI #533** (`b96f113`, the fix) PASS:
  - **game:** 21 min, against 44–60 before;
  - **art:** 31 min, against 60–77 before, well inside the 90-minute limit.
- **QA-1 verified:** pushing `b96f113` cancelled #532, the older run on the same branch.
- **QA-2:** this docs-only commit started no Bootstrap run (checked after the push).
