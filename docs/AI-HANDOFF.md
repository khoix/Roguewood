# Roguewood — agent checkpoint

Updated: 2026-11-20. Current state only; everything older is in docs/AI-HANDOFF-HISTORY.md (moved verbatim by QA-6, owner 2026-11-20, so this file stays under about 200 lines). E01–E16 DONE and merged; E17–E22 IN_PROGRESS; E23–E29 NOT_STARTED. Waves 1–13 are merged (Wave 13 by PR #33). **Wave 14 is open**: its early merges are PRs #34 and #36–#50 (latest: PR #50, main `75d2dfa`, 2026-11-20). PR #51 (UI-30, UI-31) is merged (main `5f4df32`). The plan to release is docs/ROADMAP.md. Provisional decisions: the E07 equipment model, E08 prices, targets (E24). Device gates (E05, E12, E13) and E26 need phone hardware.

## Read first

1. ../AGENTS.md
2. This file; "Testing and CI" below says how to verify a change.
3. EXECUTION-PLAN.md (assigned execution only after overview)
4. ../Roguewood-Game-Plan.md (relevant sections)
5. handoffs/<assigned-task-id>.md when it exists. Older checkpoint entries: AI-HANDOFF-HISTORY.md (read only when you need a past decision or result).

## Testing and CI (QA-1…QA-8, owner 2026-11-20)
The owner asked for tests that take less time and fewer tokens. For both agents:
- **qa.py is quiet.** A pass prints one `PASS … in N s` line; a failure prints its error lines and the last 40 lines, and names the full log. Every engine run's full output is in a log (the journey's own, or `artifacts/qa/`). `--verbose` or `QA_VERBOSE=1` prints everything (CI sets it).
- **Run what a change touches, in parallel:** `python3 tools/qa.py batch unit content J05 J06:rendered` (three at a time; one line each; failures' tails at the end; results in `artifacts/qa/batch/`).
  - Logic, rules or content: `unit`, `integration`, `content`, and the headless journeys that play it (BAL-1 missed `integration` once; CI #538 caught it).
  - A screen or art: those journeys headless and rendered (`Jxx:rendered`), and look at their captures.
  - Docs only: nothing.
- **CI is the full gate.** Every push runs the whole list (`linux-bootstrap (game)` and `(art)`); a pull request shows its head commit's push checks. The full local matrix is no longer run before every PR. Run it (`python3 tools/qa.py matrix`, CI's own list, or `--shard game|art`) for a wave close, when CI is down, or when a change could reach everything.
- **CI:**
  - one run per commit (no `pull_request` trigger);
  - a newer push to a branch cancels its older run (never on main);
  - a push of only docs or Markdown runs nothing;
  - package installs are capped and retried (`tools/ci_retry.sh`), so a mirror outage fails in minutes.
- **Rendered journeys draw only the frames a capture waits for** (plus every 30th), through `src/platform/qa_render.gd` (the `QaRender` autoload, inert in the game). The logic still runs every frame, and `_draw()` errors still surface. `--draw=all` draws every frame. Verified identical captures before it became the default; see handoffs/QA.md.
- **The slice strategy simulation** runs 50 seeded games per strategy by default (it only has to run); `python3 tools/qa.py slice --runs 400` regenerates ADR 008's balance report.
- **Tokens:** read logs and captures only when a check fails or a visual needs judging; use one long background wait, not repeated check-ins.

## Current state
- **Integration:** the owner merges `claude/roguewood-build` into main by PR. Claude restarts or fast-forwards it from main after each merge. Codex pushes `codex/roguewood-build` and opens no PRs.
- **Merged:** PRs #51 (main `5f4df32`), #52 (`4c54786`), #53 (`b78b7c2`), #54 (`2605a3b`) and #55 (`6536427`), 2026-11-20.
- **For the next PR** (merged into `claude/roguewood-build` after #51): QA-1…QA-8, the testing changes above. Full local matrix: 28 min (was 64). CI #533 PASS: game 21 min, art 31 min (were 44–60 and 60–77).
- **UI-32 DONE** (handoffs/UI-32.md; the owner's play notes, 2026-11-20): the shop's **Inventory** (Charms in a drag-to-reorder row on top, the other items below, tap to review or sell) and the payout and rack as a themed slip (payout rows and total; the rack as a triangle of pin art; reserves; Charms and Deck chips). Checks: `unit`, `content` and all 73 shop journeys headless; J05, J06, JTUT, JAVC04B, J03C07–C10 and J11 rendered: PASS.
- **BAL-1 DONE** (handoffs/BAL-1.md; agreed with the owner, 2026-11-20): a release inside the ring adds 10 Value; sweet and perfect add +1 and +2 Mult on top (a plain strike 560 / 600 / 750 / 900). The simulation moves 0–5 points of League wins and 4–9 of Division 1 clears; the targets stay. New fixed values: J03 600/260/70, J05 match 2 25920.
- **UI-33 DONE** (handoffs/UI-33.md; the owner's play notes, 2026-11-20): the ball's finger holes face the bowler, and ivory roll spots mark the rolling circle and the sides, so the held spin and the roll and hook down the lane read. Visual only; physics unchanged.
- **PR #52 merged** (owner, 2026-11-20; main `4c54786`): UI-32, BAL-1, UI-33 and QA-1…QA-8.
- **UI-33b DONE** (handoffs/UI-33.md, follow-up; the owner's play notes after PR #52): the Spare Ball's stripe was fixed to the world, Echo's rings were symmetric about the spin axis, and Laser's line was too thin to see turn. All three now turn visibly with the ball. J02 (rendered) turns every catalogue ball about both axes and requires its own surface to change.
- **PR #53 merged** (owner, 2026-11-20; main `b78b7c2`): UI-33b.
- **UI-34 DONE** (handoffs/UI-34.md; the owner's play notes after PR #53): a tapped Inventory item shows its full rules (effect, tradeoff, modification), with no "sells for $" line; a long press lifts a Charm into a card that follows the finger to its new slot (replacing Godot's drag and drop, which showed nothing moving on a phone).
- **PR #54 merged** (owner, 2026-11-20; main `2605a3b`): UI-34.
- **UI-35 DONE** (handoffs/UI-35.md; the owner's play notes): one scrim (`UiTheme.SCRIM`) behind every overlay; the shop's dim sits under the topmost sheet, so an item over the Inventory darkens it; a tap outside closes only the top sheet.
- **PR #55 merged** (owner, 2026-11-20; main `6536427`): UI-35.
- **UI-36 DONE** (handoffs/UI-36.md; the owner's play notes): the web loader lagged on phones and its knockdown rarely showed. Its spin, bob and roll are now CSS (the browser keeps them playing while the game starts); with no known download size the ball rolls and knocks the pin over in a loop; and when the engine removes its overlay, the knockdown plays out and the overlay fades over about a second. JW01 checks all three. Not tested on a real phone.
- **Codex** has been out of tokens since 2026-11-19 and returns about Friday 2026-11-21. Its Wave 14 queue: AV-N4, AV-N5, UI-A6, then UI-A9-H, and the proposed AV-UI1.

## Decisions and invariants

Title Roguewood; no subtitle. Premium dynamic pixel artwork is mandatory. Behind-ball perspective; hold/spin/flick with curved roll. Named rivals set visible score/rule challenges, never simulated opponent turns. Career persists unlocks and records; Leagues contain eight Divisions. The full catalogue and six themes are release scope, not prototype scope.

Godot 4.5.2 stable / GDScript / Compatibility renderer pinned for bootstrap in decisions/001-foundation.md. E04 physics: Jolt at 120 Hz, a fresh World3D per roll, regulation lane and pins, a gutter-void rule and impulse-based attribution, per decisions/002-throw-lab-physics.md. Primary iOS 16+/iPhone 13 Pro class; secondary Android 10+ and Windows 11; Linux x86-64 development/CI. Device testing remains outstanding. Same-build physics repeatability is shown on x86-64 Linux (E04); device feel, hook, the final deck-loop decision (ADR 004 is provisional; E13 playtest decides), item definitions/values/unlocks and visual target remain later decisions. Resolve through assigned executions; do not repeatedly redesign settled decisions.

## Execution ledger

All NOT_STARTED tasks are dependency-ineligible until their prerequisites are accepted. Batch family status aggregates child statuses; only the coordinator updates this table.

| Family | State | Owner | Worker branch | Evidence / blocker |
|---|---|---|---|---|
| E01 — Architecture and project bootstrap | DONE | Codex | codex/roguewood-build | f50f916; CI 40230415594 PASS; E01 handoff |
| E02 — Headless rules and content contracts | DONE | Codex | codex/roguewood-build | cdb4859; CI40245188289 PASS; E02 handoff |
| E03 — Application shell and E2E harness | DONE | Codex | codex/roguewood-build | 78b1740; CI40256553911 PASS; E03 handoff |
| E04 — Straight throw and pin collision lab | DONE | Claude | claude/roguewood-build → main (PR #2) | 44bbd7e; CI 40262418442 PASS; owner merge |
| E05 — Spin, curve, and mobile gesture feel | DONE (device gate open) | Claude | main (PR #3) | 0ad08c2; CI 40324357857 PASS; owner merge; real-phone trials NOT RUN |
| E06 — Frame scoring and readable resolution | DONE | Claude | main (PR #3) | b325c56; CI 40375789785 PASS; owner merge |
| E07 — Deck draw and cycle experiment | DONE (decision provisional) | Claude | main (PR #5) | bec3341; owner merge; CI 40435623701 PASS (run on `e1c8f9b`, which adds only the checkpoint; artifact `journeys` 12704037055); J04 and experiment output identical to local; ADR 004 provisional; E07 handoff |
| E08 — Shop and match economy | DONE (prices provisional) | Claude | main (PR #6) | 7b57919; owner merge; CI 40442532881 PASS; ADR 005 provisional; E08 handoff |
| E09 — Single Division loop and rival | DONE (targets provisional) | Claude | main (PR #7) | fcea7f3; CI 40451844709 PASS; ADR 006 provisional; E09 handoff |
| E10 — Attempt saves and recovery | DONE | Claude | main (PR #9) | 8e4edd5; CI 40460928513 PASS; ADR 007; E10 handoff |
| E11 — Art bible and representative still scene | DONE | Codex | main (PR #4) | 2882483; E11 CI 40428621822 PASS; owner approval by merge (confirmed 2026-10-27) |
| E12 — Representative motion and visual review | DONE | Codex | main (PR #8) | Implementation 90f5690; handoff 046d109; CI 40444945503 + 40444945245 PASS; merged by PR #8 (main 9225f7c) |
| E13 — Vertical-slice integration | DONE (device play session blocked) | Claude | main (PR #9) | 98cc2aa (with 5aac9d2, aea54e0); CI 40524506207 PASS; ADR 008; E13 handoff |
| E14 — Seeded eight-Division progression | DONE | Codex | codex/roguewood-build | 71b2bd2; local unit/content/integration/physics, J01/J06/J07 and native J09 headless/rendered PASS; handoffs/E14.md |
| E15 — Career persistence and unlock graph | DONE | Claude | main (PR #10) | 2cdedb1 (+ 8c19905); local suites and J01–J10 headless/rendered PASS; CI 40577363221 and 40581437392 PASS; ADR 010; E15 handoff |
| E16 — Clubhouse and collection UI | DONE (core and E16-ART) | Claude core · Codex E16-ART | claude/roguewood-build · codex/roguewood-build | Core b01fb4d; CI 40616441249 PASS; J11; handoffs/E16.md (Art hand-off) |
| E17 — Catalogue and unlock authoring batches | IN_PROGRESS (D01–D09 and L01 DONE; D01-ART to D04-ART DONE) | Claude definitions · Codex visual briefs | claude/roguewood-build · codex/roguewood-build | Split per batch; see Ownership |
| E18 — Content mechanics batches | IN_PROGRESS (C01–C16 DONE) | Claude | claude/roguewood-build | C01: six D02 Charms; C02: transform primitive, Glass Pin and Glass Cutter; C03: five primitives, Crown Pin and the last five D02 Charms; C04: eight modifications; C05: House rules, lanes, two-rule champions; C06: tactical primitives and three cards; C07: shop upgrades and six House upgrades; C08–C10: 18 House items (DC-H1…H3); handoffs/E18-Cxx.md |
| E19 — Final item artwork batches | IN_PROGRESS (A01–A16 and AV-C03 DONE) | Codex | codex/roguewood-build | E13-S01, E17-D01 and E17-D02 identities; artwork set on the seven C01/C02 Charms and Glass Pin; C03 flags (A17) and D03 identities (A18) in Wave 5 |
| E20 — Ability effects and audio batches | IN_PROGRESS (V01–V08, the House AV batches and AV-T01 DONE) | Codex | codex/roguewood-build | E13-S01's 23 abilities; V08: the eight C01/C02 items; C03's six in Wave 5 (V09) |
| E21 — Rival presentation batches | IN_PROGRESS (R01, R02 DONE) | Codex | codex/roguewood-build | Later rivals after E17 defines them |
| E22 — League theme integration batches | IN_PROGRESS (L01 House and L02 Neon live; Neon theme pending) | Claude configuration and integration · Codex theme art | claude/roguewood-build · codex/roguewood-build | One League per roadmap step (docs/ROADMAP.md); L01 House in Waves 6–8 |
| E23 — Starting kits, mastery, difficulty, and endless | NOT_STARTED | Claude · Codex E23-ART | claude/roguewood-build · codex/roguewood-build | Kits per League bundle; tiers, medals and endless in Phase 4 |
| E24 — Economy and procedural balance study | NOT_STARTED | Claude | claude/roguewood-build | See Ownership |
| E25 — Onboarding and accessibility completion | NOT_STARTED | Claude core · Codex E25-ART | claude/roguewood-build · codex/roguewood-build | Split; see Ownership |
| E26 — Platform packaging and performance | NOT_STARTED (BLOCKED: hardware) | Claude · Codex art-budget fixes | claude/roguewood-build | Phase 5; needs phones and toolchains (owner decision in docs/ROADMAP.md) |
| E27 — Content and asset completeness audit | NOT_STARTED | Claude content audit · Codex asset audit | claude/roguewood-build · codex/roguewood-build | Split; see Ownership |
| E28 — Cross-system release candidate | NOT_STARTED | Claude (coordinator) | claude/roguewood-build | See Ownership |
| E29 — Delivery and final handoff | NOT_STARTED | Claude (coordinator) | claude/roguewood-build | See Ownership |

## Ownership, lanes and hand-offs (owner directive, 2026-10-28)

### Waves and merges (owner directive, 2026-10-28)
- **A wave is a fixed set of claims** for both agents, listed under "Wave N claims". Nothing outside it is pushed as part of that wave.
- **One merge path:** `claude/roguewood-build`. Codex pushes `codex/roguewood-build` and reports. The coordinator reviews and integrates it into `claude/roguewood-build`. Codex does not open PRs to main.
- **A wave closes** with a commit titled "Wave N closed" on `claude/roguewood-build`. It records the closing state and the next wave's claims. The owner merges `claude/roguewood-build` into main once that commit's CI passes.
- **Between closure and the owner's merge,** the coordinator does not push next-wave work to `claude/roguewood-build`. That work stays committed locally until the merge, so the PR contains exactly one wave.
- **Codex starts the next wave** from the "Wave N closed" commit (merging it into its branch). It pushes to `codex/roguewood-build` as usual; that branch is never the merge path.

### Art rule
**Codex owns every remaining art component.** That means artwork, illustration, iconography, portraits, environment art, VFX, animation, audio, trophy and cosmetic art, visual briefs and visual review. Claude owns the rules, data, UI logic, persistence, tests and integration code for the milestones in its lane.
- Codex never changes scoring, economy or Career rules.
- Claude never produces final art.
- A rule hook Codex needs that does not exist is requested from Claude through this checkpoint.

### Lanes (revised 2026-10-28; the plan to release is docs/ROADMAP.md)
| Lane | Milestones | Why the same agent |
|---|---|---|
| **Claude: Leagues, content and rules** | E17 (League specs, rival roster, definitions) and E18 (mechanics), written and landed together per League bundle; E22 League configuration and integration; E23; E24 | One agent writes, implements, integrates and tunes each League's rules and items in its own rules code. |
| **Claude: menus, platforms and release** | E25 core; E26 platform packaging and device evidence; E27 content audit; E28; E29 | The coordinator owns cross-system integration; E26's blockers are export, save and suspend code Claude maintains. |
| **Codex: all art** | E19 + E20 as one AV session per 3 landed items (brief, identity art, effects, sound, native check, flags); E21 rivals with their rule badges; E22-Lxx-ART League themes; E23-ART; E25-ART; E27 asset audit; art-budget fixes from E26/E28 | Codex owns the card, motion, effect and audio systems; one session per item set removes repeated native checks. |

- **Changed from the first plan** (coordinator, 2026-10-28, at the owner's request to re-plan): E22's configuration and integration and all of E26 move from Codex to Claude, because Codex's art and effects already made its lane about twice Claude's. Codex keeps every art component, including each League's theme art.
- **Boss-rule art** is made in the rival's E21 session (its rule badge), not as a separate E19 batch.

### Split milestones (two parts, separate states; the family is DONE only when both are)
| Milestone | Claude part | Codex part (`<id>-ART`) |
|---|---|---|
| E16 | DONE | DONE |
| E17/E18 (per League bundle) | League spec, rival roster, definitions and mechanics | Briefs inside each AV session (E17-D04-ART is the last standalone brief batch) |
| E22 (per League `E22-Lxx`) | Configuration: 8 Divisions, rivals, lane pool, weights, kit, branch unlock, full-League journey | Theme: environment, signage, lane-condition visuals, music identity |
| E23 | Kits, difficulty tiers, medals, endless | Kit, medal and cosmetic art |
| E25 | Tutorial, alternate controls, safe areas, touch cancellation, settings persistence, J14 | Readable symbol set, reduced-effects visuals, tutorial visual review |
| E27 | Count, ID, unlock and integration audit | Weakest-asset review, placeholders, licences, provenance |

### Hand-off protocol (every split part and every cross-lane dependency)
1. **Before:** the starting agent's claim names its inputs (milestones or batches and their SHAs) and, for a split, the art part's scope:
   - asset IDs and slots (icon, card, in_play, activation, sound, reduced_motion, trophy…);
   - Codex's drop paths: `assets/` and `docs/art/ASSET-LEDGER.md`, Codex-exclusive;
   - the journeys and capture names showing each slot.
2. **During:** Claude wires every visual slot to a marked placeholder by asset ID, so art needs no code edit. Art completeness flags stay false until Codex sets them.
3. **After:** the finishing agent's handoff ends with a "Hand-off" checklist: what is now ready, for whom, the IDs, and the captures to compare. The coordinator then marks the dependent part READY here.
4. Codex finishing art re-runs the named journeys and records contact sheets, captures and provenance. Code the art reveals as necessary returns to Claude as a scoped follow-up.
5. Claude works on `claude/roguewood-build`, Codex on `codex/roguewood-build`. Neither edits the other's exclusive paths without a recorded claim. Each starts from current `main` after the owner's merges.

### Hand-offs before and after each remaining milestone
| Work (owner) | Needs before starting | Hands off when done |
|---|---|---|
| E17-Lxx League spec (Claude) | The previous League's spec | Rival identities READY for E21; theme brief READY for E22-Lxx-ART; the bundle's item list for E18 |
| E18 primitive session (Claude) | Its League spec | The items that use it, for the next item batch |
| E18 item batch (Claude) | Its primitives | AV batch READY for Codex (item IDs, asset IDs, journeys and captures) |
| AV batch (Codex) | Its items landed | Artwork and effects flags; items count as finished content |
| E21-Rxx (Codex) | The rival's rule landed and its identity in the League spec | Rival presentation for the League integration |
| E22-Lxx-ART (Codex) | Its League spec | Theme assets by ID for the League integration |
| E22-Lxx integration (Claude) | Its spec, rules and items; Codex's theme and rivals bind by ID and can follow | A playable League; the next League's branch unlock |
| E23 (Claude) / E23-ART (Codex) | Six Leagues | Kits, medals and endless for E24 and E25 |
| E24 (Claude) | E18–E23 | Tuned data; exploit fixtures for E28 |
| E25 core (Claude) / E25-ART (Codex) | E16, E22 | J14 for E26 |
| E26-Pxx (Claude) | E25; hardware and toolchains (BLOCKED today) | Installed-build evidence for E28 |
| E27 (both) | E17–E23 | Audit report for E28 |
| E28 → E29 (Claude) | E24–E27 | Release candidate; then delivery |

## Wave 15 queue (owner requests; claimed when Wave 15 opens)
- **UI-A8, Codex** (owner, 2026-11-17; prompt docs/prompts/codex-wave15-ui-a8.md): League backdrops. The space beside and behind the lane is redesigned to push each League's theme forward: ambient, layered, slow and readable under the HUD, with still versions for reduced motion and reduced flash.
  - **Scope:** House and Neon now, every Division and the Championship. Salvage, Royal, Spectral and Foundry follow the standard UI-A8 sets, within their own themes.
  - **Claude:** wires any hook UI-A8 asks for in league_theme.gd.

- **AV-FIX1, Codex** (owner, 2026-11-17; prompt docs/prompts/codex-av-fix1-transparency.md): eight card images have opaque dark backgrounds instead of transparency:
  - **The cards:** Tin Pin, Spare Jar, Consolation Prize, Double Take, Called Shot, Pin Count, Cleanup Crew and Lucky Seven.
  - **Source sheets:** source.AV-H3-B.png and source.AV-H4-A/B.png.
  - **The fix:** a clean alpha matte, ledger entries, and a unit guard that every card is transparent at its border.
  - **When:** in Codex's current queue, ahead of Wave 15 if the owner wants it on the phone sooner.
  - **Update (2026-11-17), at the owner's request:** the coordinator matted seven with tools/author_card_mattes.py (ledger, AV-FIX1). A unit guard (tests/card_transparency_test.gd) now fails on any card with a background plate. **Spare Jar remains for Codex:** its glass needs repainting. Checks: `unit`, `content`, JAVH3BC, JAVH4AC and JAVH4BC (both modes), and J03C08–J03C11: PASS.

## Wave 14 claims (coordinator: Claude, 2026-11-15)
Open: Wave 13 is merged (PR #33, main `4aefda6`). Base: `claude/roguewood-build` at the "Wave 13 closed" commit or later. Codex merges it into `codex/roguewood-build` with a merge commit before starting (prompt: docs/prompts/codex-wave14-session.md, a new session from 2026-11-15 with AV-T02 first; it replaces codex-wave14.md). Scope: docs/ROADMAP.md, the Wave 14 row and "League template" (wave a for Salvage).
- **Claude:**
  1. **E17-L03** (High; moved from Wave 13 by the owner, 2026-11-15): the Salvage League spec, as E17-L02 was for Neon.
     - The League's eight Divisions, its three rivals and champion, their rules, its lanes, kit, rewards and specialist tags.
     - The 33-item plan for its batches (the ROADMAP's Salvage bundle), and the definitions the spec itself needs.
  2. **Salvage's rules and lane conditions** (High, as E18-C13 was for Neon): built and tested before any item uses them.
  3. **E05-R5, the flywheel spin** (High; owner, 2026-11-15): the rotation while charging a curve, after the mobile ball-throwing reference. Codex's reconstruction (PR #35) is reference only and stays unmerged until this is confirmed. Build both options to choose on the phone: A (the swing plus a flywheel) and B (spin in place).
  4. **UI-20** (owner, 2026-11-19; spec handoffs/UI-20.md): the alley screen. Celebrations for strikes, spares and boss wins in the aim magnifier's window, on a small CRT screen, per League from its theme manifest, with placeholders until UI-A9.
- **Codex:**
  1. **AV-N3** (DC-N3's six items; J03C17).
  2. **AV-N4** (DC-N4's five items and the Controlled Curve ribbon; J03C18).
  3. **AV-N5** (DC-N5's five items and the Both Halves and Rebound Rescue ribbons; J03C19).
  - Each with native checks, artwork and effects flags, sounds and reduced-motion versions, as AV-N1 and AV-N2 were.
  4. **UI-A6** (added by the owner's play notes of 2026-11-15; prompt docs/prompts/codex-wave14-ui-a6.md): a themed pin deck for every League. The House League's kickbacks and cushion are still plain, because the pin-deck finish is applied only to Neon. Make the hook manifest-driven and give the House League its finish.
  5. **AV-T02** (owner, 2026-11-15; prompt docs/prompts/codex-wave14-av-t02.md): the spinning held ball's look for the flywheel. Readable spin at every speed, a clear full state, reduced motion still.
  6. **AV-T03** (the owner's play notes, 2026-11-15; prompt docs/prompts/codex-wave14-av-t03.md; next after the item in hand): the charge feedback as a trail of colored particles behind the ball's path, growing with the charge, in place of the text tab and the fixed sparkles.
  7. **UI-A7** (the same notes; prompt docs/prompts/codex-wave14-ui-a7.md; after AV-T03): the title's motion. No shifting or shaking; twinkling stars; plants in a light wind; a pixel-style 3D ball turning about Y. Optionally, the loader's sprites.
  8. **UI-A9-H** (owner, 2026-11-19; prompt docs/prompts/codex-wave14-ui-a9.md; after AV-N4, AV-N5 and UI-A6, once UI-20 is merged): the House celebrations, 20 animations (5 or more strikes, 5 or more spares, 2 per boss including the champion), their stings and the final CRT look. Also the standard the later Leagues follow. UI-A9-N (Neon, 18) is Wave 15.
  - Salvage's rivals and theme follow its spec (Wave 15).
- **Owner:** play UI-8 on the phone, in particular dragging across Binder cards (no touchscreen in the test environment).

## Wave 14 progress
The full log (every entry and its checks) is in AI-HANDOFF-HISTORY.md; each item's handoff has its evidence.
- **Claude, DONE and merged** (PRs #34, #36–#50):
  - E17-L03 (the Salvage spec), E18-C20 (Salvage's rules and lanes), E05-R5 (the flywheel; the owner chose model A);
  - the owner's notes: UI-9 to UI-29, MUSIC-1, the soundtrack;
  - the E12 motion review fix.
- **Codex, DONE and merged:** AV-T02, AV-T03, UI-A7 and AV-N3.
- **Owner's choices on record:** spin model A; at least 5 strike and 5 spare celebrations per League and 2 per boss (UI-A9-H in Wave 14, UI-A9-N in Wave 15); the alley screen (UI-20) stays off until Codex's art.
- **PR #50 merged** (owner, 2026-11-20; main `75d2dfa`): UI-27, UI-28 and UI-29.
- **UI-30 DONE** (handoffs/UI-30.md), owner 2026-11-20: a new pin placed where a modified pin stands takes over its modification (unless they exclude each other); the old pin moves or sells without it, and the placement sheet says so. Held on `claude/gracious-hopper-2npyl2` at the owner's request until #50 merged, then merged into `claude/roguewood-build` for the next PR.
- **UI-31 DONE** (handoffs/UI-31.md), owner 2026-11-20: the award page opens only for real progress (a within-run goal counts only when completed); the fade out is halved (1.5 s + 0.15 s); and a continuous show runs the whole time the award screen is up: fireworks of five kinds, salvos with bottle rockets, confetti from the top, corner cannons and streamers, with their own sounds.
- **Full CI matrix (local) on `90330f6`** (UI-30 and UI-31): 252 of 252 commands PASS.
- **UI-31 follow-up** (owner, 2026-11-20): a League title won again is no new award; it no longer opens or appears on the award page. CI #529 failed on J12R01 because the show's sound throttle used the wall clock; it now counts the ceremony's own time. #528's art job hung in `apt-get update` (Ubuntu mirror) until the 90-minute limit.
- **Next:**
  - Codex's AV-N4, AV-N5 and UI-A6 (AV-T02, AV-T03, UI-A7 and AV-N3 are merged), then UI-A9-H, and the proposed AV-UI1 (the final button sounds);
  - then the full matrix and the "Wave 14 closed" commit.

## Standing user preferences
- Log agent work only; owner merge means approval. Do not mark completed milestones pending the owner. Integration facts are separate.
- Codex uses codex/roguewood-build across milestones, not new milestone branches.
- At the end of each milestone, state the proposed effort level for the next pending milestone.
- At the end of every session, share newly produced screenshots with the user (as files in chat). Never commit screenshots or other rendered captures to the repository; CI's uploaded artifact is their durable copy.

## Blockers and limitations
No local blocker. The native Apple toolchain, signing, the Android SDK and mobile hardware are not available in this Linux execution, so the device gates (E05 trials, E13 play session, E26) stay open until a device build exists. Physical feel, visual review on a phone and balance are NOT VALIDATED.

## Session handoff protocol

Workers copy AGENT-TASK-TEMPLATE.md to docs/handoffs/<task-id>.md on their own branch. Push code and handoff together; send coordinator branch/SHA and validation summary. Coordinator reviews and integrates, records the integrated code SHA and relevant test evidence, clears stale claims, updates the next action, and pushes checkpoint. Preserve unfinished tasks honestly; no running diary.

Do not insert the checkpoint's own future commit SHA. Record already-known implementation commits; the Git history identifies the checkpoint commit. On resume inspect remote changes before accepting an old ownership claim. Stop after the assigned execution is durably saved.
