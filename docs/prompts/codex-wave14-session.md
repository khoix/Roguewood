Roguewood — Codex Wave 14, new session: AV-T02 first, then AV-N3, AV-N4, AV-N5 and UI-A6.
This prompt replaces docs/prompts/codex-wave14.md. The per-item briefs it points to (codex-wave14-av-t02.md and codex-wave14-ui-a6.md) still apply.
Recommended effort: Medium for AV-T02 and UI-A6; High for each of AV-N3 to AV-N5.

Repository: https://github.com/khoix/Roguewood.
- **Your branch:** `codex/roguewood-build`.
- **The coordinator's:** `claude/roguewood-build`.
- Never push to `main` and open no pull requests.

## Begin
1. **Get up to date:** clone the repository if this session has no checkout, then fetch origin. On `codex/roguewood-build`, merge `origin/claude/roguewood-build` (`2afb620` or later, with E05-R5 and UI-9) with a merge commit. Do not rebase or force-push.
2. **The rules:** read AGENTS.md, then docs/ROADMAP.md (the Wave 14 row).
3. **Your assignment:** read docs/AI-HANDOFF.md, "Wave 14 claims", "Wave 14 progress" and "Ownership, lanes and hand-offs". Those claims are your assignment and limits; repo state wins over this prompt.
4. **Check what is already done:** look in docs/handoffs/ for AV-N3.md, AV-N4.md, AV-N5.md, UI-A6.md, AV-T02.md and WAVE14-CODEX.md, and skip any item already DONE.

## New since your last session: testing and CI (owner, 2026-11-20)
The owner asked for tests that take less time and fewer tokens. The details are in docs/AI-HANDOFF.md, "Testing and CI"; in short:
- **docs/AI-HANDOFF.md is now short** (current state only, about 200 lines). Older entries are in docs/AI-HANDOFF-HISTORY.md; read it only when you need a past result.
- **qa.py is quiet:** a pass prints one `PASS` line; a failure prints its error lines, the last 40 lines and the log's path. `--verbose` or `QA_VERBOSE=1` prints everything.
- **Check what your item touches, in parallel:** `python3 tools/qa.py batch unit content J03C18 J03C18:rendered JAVN3BC:rendered`, for example. It runs three at a time, prints one line each, and ends with any failure's tail.
- **CI is the full gate.** You no longer re-run every art journey locally; push, and the art shard runs them all. `python3 tools/qa.py matrix --shard art` runs CI's own art list locally if CI is down.
- **Rendered journeys draw only the frames a capture waits for** (and every 30th), through the `QaRender` autoload in project.godot. It is inert in the game. Captures are pixel-identical to drawing every frame. If an art step ever needs every frame drawn (a timing-sensitive capture without `await RenderingServer.frame_post_draw`), pass `--draw=all` and tell the coordinator.
- **New captures:** wait for `RenderingServer.frame_post_draw` before reading `root.get_texture()`, as the existing journeys do.
- **CI:**
  - one run per push (no separate pull-request run);
  - a newer push to your branch cancels the older run;
  - pushes of only docs or Markdown run nothing;
  - package installs go through `tools/ci_retry.sh`. Use it in any new step that installs packages.

## Order
### 1. AV-T02 (next; Medium): the spinning held ball's look
- **Brief:** docs/prompts/codex-wave14-av-t02.md. Context: docs/handoffs/E05-R5.md and ADR 011, "Revision: the flywheel".
- **What changed:** the held ball now spins on its own flywheel, up to about 30 rad/s at full charge.
  - It keeps spinning briefly after the finger stops.
  - Two spin models are on the tuning page: A (the swing plus a flywheel; the default) and B (spin in place).
  - The ball is drawn turning at exactly `HeldBall.spin_rate` / `body_angle`.
- **The work:**
  - Make it read as spin at every speed, not a strobe: a streak or blur that grows with spin, or markings that resolve into rings.
  - Add a clear full-charge state on top of AV-T01's curve-ready sparkle.
  - Cover depth and flat view, A and B, normal and reduced motion. Reduced motion: no streak or strobe; the ball stays still and the meter and sparkle carry it.
- **Checks:**
  - Extend JAVT01, or add a journey, with captures at rest, curve-ready and full, in both views, normal and reduced motion.
  - J02 and JAVT01 must pass.
- **Why first:** the owner is choosing between A and B on the phone, so this lands before the defaults are set.

### 2. AV-N3 (High): DC-N3's six items, checked natively through J03C17
- **Items:** Dry Side, Lane Reader, Hook Shot, Line Call, Bounce Back and Straight Money.
- **Moments the play must show:**
  - Dry Side's side reading at 34 ft;
  - Lane Reader's lane;
  - Hook Shot's stretched aim guide;
  - Bumper Guard's rescue paying Bounce Back.

### 3. AV-N4 (High): DC-N4's five items and a ribbon, checked natively through J03C18
- **Items:** Trade-In, Specialist Shelf, Comet Ball, Metronome and Steady Hand, plus the Controlled Curve ribbon (`ribbon.mastery.controlled_curve`).
- **Moment the play must show:** Specialist Shelf's marked Specialist offer in the shop (slot 7, "Specialist").

### 4. AV-N5 (High): DC-N5's five items and two ribbons, checked natively through J03C19
- **Items:** Compass Pin, Split Pattern, Dry Run, Long Game and Second Chance, plus the Both Halves and Rebound Rescue ribbons (`ribbon.mastery.both_halves`, `ribbon.mastery.rebound_rescue`).
- **Moments the play must show:**
  - Dry Run's side reading;
  - Split Pattern's, Long Game's and the Compass Pin's lane;
  - Bumper Guard's rescue paying Second Chance.

For each of AV-N3 to AV-N5:
- **The art:** fill each item's `assets` slots and set its artwork and effects_audio flags. Add its scoring effect and sound, and reduced-motion versions, as AV-N1 and AV-N2 did.
- **The references:**
  - Asset ids and presentation needs are in the batches E17-D14, D15 and D16.
  - The items, journeys and captures are in docs/handoffs/E18-C17.md, E18-C18.md and E18-C19.md.
  - The pattern to follow is your WAVE13-CODEX.md, AV-N1.md and AV-N2.md.

### 5. UI-A6 (Medium): a themed pin deck for every League
- **Brief:** docs/prompts/codex-wave14-ui-a6.md.
- **Why:** the House League's kickbacks and cushion are plain, because `LeagueTheme._dress_pin_deck` only dresses Neon.
- **The work:**
  - Make the pin-deck finish a manifest entry per League, and give the House League its own: static, on presentation meshes only.
  - Check every House stage: Divisions 1 to 8 and the Championship.
  - Neon's finish must stay unchanged.

## Already changed by the coordinator (on `claude/roguewood-build`)
- **UI-8:**
  - The Binder opens a tapped card in a preview overlay (`binder_art` and `binder_detail` live in it), and its categories are tabs.
  - The end screen is sections (`result_view`).
  - The session menu button sits inside the top bar.
- **UI-9:**
  - **The Clubhouse:**
    - The logo heads it, and the tabs are segmented.
    - The Career is a scoreboard plate, and the play card has a brass action.
    - League records and unlocks are cards; `records_label` and `latest_label` are hidden but keep the full text.
    - Pages have no scroll bars, and rows pass drags to the page.
  - **The boss introduction** is in parts:
    - `intro_kicker`, `intro_title` (the rival's name only), `intro_portrait` and `intro_quote`;
    - `intro_rules` (one card per rule, with its seal), `intro_facts` and `intro_reward`;
    - a "Scouting report +" toggle;
    - `intro_body`, hidden but keeping the full text.

    Landscape sets two columns. `intro_button` keeps the rule seal.
  - **Keep cards** fill their section.
- **Boss introductions wait for Begin.** The shared `_aim()` helpers press `lab.hud.intro_button`.
- **Salvage:** E17-L03 and E18-C20 are done. Salvage's rivals and theme are Wave 15; do not start them.

- **UI-32 (2026-11-20):** the shop's Sell sheet is now the Inventory. Charms sit in a drag-to-reorder row (`charm_row`, tiles `Sell_charm_N`) above the other items. Find a tile with `shop_panel.sell_button(ref)`. Payout & Rack is a slip (`ledger`); `summary` and `rack_label` stay, hidden, with the text.
- **BAL-1 (2026-11-20):** a release inside the ring adds 10 Value (FrameRules.INSIDE_VALUE). Expected scores in your journeys should come from the actual release grade.
- **UI-33b (2026-11-20, at the owner's request):** three of your ball shaders changed. The Spare Ball's stripe is now painted on the ball (it was world-fixed). Echo's rings lean off the spin axis. Laser's line is wider. J02 (rendered) now turns every ball about the roll and spin axes and requires its surface to change; keep new ball looks in the ball's own coordinates.
- **UI-33 (2026-11-20):** the ball's finger holes face the bowler, and small ivory roll spots mark its rolling circle and sides (lane_dressing.gd), so spin and roll read. A final ball look may restyle them, but must keep a marker that turns with the ball.

- **PERF-1 (2026-11-21):** a `Graphics` autoload (src/platform/graphics.gd) adds Resolution and Texture Detail settings. At Low, art larger than 512 px is drawn from a 512 px copy (and High, smoothed mipmaps); Normal, the default and what every journey runs, draws your art untouched. Large source art drawn small costs phones GPU memory; display-sized copies would help.

## Ownership and limits
- **Never edit:**
  - src/rules/, src/simulation/, src/persistence/, src/career/, src/procedural/, src/content/ or src/input/;
  - content/leagues/ or content/career/;
  - content/catalogue.json, outside your own items' `assets` slots and flags;
  - export_presets.cfg or project.godot.
- **Allowed in src/presentation/league_theme.gd:** only UI-A6's pin-deck hook.
- **A hook you need that does not exist** goes to the coordinator as a request in your handoff.
- **Add-only:** tools/qa.py, the CI workflow and run_tests.gd. Every new art step has `if: matrix.shard == 'art'`.
- **These must stay identical:** the physics digest `75d1a3c0…`; J03 600/260/70 and J05's match 2 at 25920 (BAL-1, 2026-11-20: a release inside the ring adds 10 Value; these were 560/240/70 before).
- **These must keep passing:**
  - J02, JAVT01, J06, J08, J11, J11ART, J22L01 and J22L02;
  - J03C13, J03C15 to J03C20;
  - JAVN1, JAVN2, JUIA1 and JUIA2;
  - every art journey in the art shard.
- **Provenance** goes in docs/art/ASSET-LEDGER.md. Never commit screenshots or rendered captures.
- **PR #35** (the throw reconstruction) is reference only. Do not merge it, and do not copy its code or values into the game.

## Per item
- **Before:** list the IDs and slots, the source and provenance plan, the journeys and the captures.
- **After:**
  - Re-run `qa.py unit`, `content` and the affected journeys, headless and `--rendered`.
  - Write docs/handoffs/<item>.md (AV-T02, AV-N3, AV-N4, AV-N5, UI-A6).
  - Push, verify the remote SHA and a clean tree, and report the SHA and item to the coordinator.
- **At the end of the wave:** write docs/handoffs/WAVE14-CODEX.md as an index, listing the captures the owner should review.

Stop after the Wave 14 claims, or earlier at a coherent pushed checkpoint with the exact resume step recorded.

## Coordinator integration (2026-11-23)
`codex/roguewood-build` at `e1cae49` is merged into `claude/roguewood-build`: AV-N4, AV-N5, UI-A6, AV-FIX1, the Comet markings (`b5338c9`) and the E12 capture-list repair. Reviewed against the rules above; no changes were needed. Next: UI-A9-H (docs/prompts/codex-wave14-ui-a9.md). Merge `claude/roguewood-build` into your branch with a merge commit before starting.

## Coordinator note: PERF-2 (2026-11-23)
At Low texture detail the sweep (src/platform/graphics.gd) now draws copies, and a full-size sheet is freed once nothing holds it. It follows a scripted node's own `texture` and `identity` properties. Four of your files still hold item or backdrop art in other variables, which keeps 6 MB sheets loaded: `neon_n3_presentation.gd` (`_chart`), `neon_n4_presentation.gd` (`metronome`, `hand`), `neon_n5_presentation.gd` (`icons`) and `assets/leagues/house/environment.gd` (`backdrop`). When you next touch them, hold such art in a `texture` or `identity` property, or keep its id and reload it. Details: docs/handoffs/PERF-2.md. UI-A9-H's celebrations should follow the same rule.

## Coordinator note: UI-A9-H is live (2026-11-24)
The owner asked for the celebrations to be enabled once viable. The coordinator merged `e8223a6`, reviewed the twenty scenes, and listed them, the three stings and `celebrations_complete` in assets/leagues/house/manifest.json. Two test changes outside your art:
- tests/slice_journey.gd: `_focus_accept` waits for Division Result while a boss celebration plays.
- tests/house_celebration_boss_journey.gd: counts only `boss_defeated` scenes, and waits for the boss scene's turn, since strikes now play their own scenes.

Remaining for you: art polish (the spare poses, small boss props) and the sting audition. Keep the manifest's paths and ids stable. Merge `claude/roguewood-build` before you continue.

## Coordinator note: PERF-3 (2026-11-24)
The phone hitched before every aim partly because shaders were created anew each roll. The lane dressing now keeps one of each. `assets/items/d04/overlay.gd` still writes a new `Shader` for every decal (`_decal`). When you next touch it, keep one shared shader (a static or preloaded `.gdshader`) and give each decal only its own ShaderMaterial. The same applies to any new per-roll art. Details: docs/handoffs/PERF-3.md.

## Coordinator note: UI-A9-N and AV-UI1 moved to Claude (2026-11-24)
- **The owner reassigned them while you were out:** UI-A9-N (the Neon celebrations) and AV-UI1 (the button sounds) are Claude's now. Do not start either.
- **UI-A9-N is live:** 18 scenes and three stings in `assets/ui/alley_screen/neon/` (handoffs/UI-A9-N.md), with JUIA9N and JUIA9NB in the art shard.
- **UI-A9-H** stays yours: polish only, no sting choice pending; the owner reviews the live stings in play.
