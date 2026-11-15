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

## Ownership and limits
- **Never edit:**
  - src/rules/, src/simulation/, src/persistence/, src/career/, src/procedural/, src/content/ or src/input/;
  - content/leagues/ or content/career/;
  - content/catalogue.json, outside your own items' `assets` slots and flags;
  - export_presets.cfg or project.godot.
- **Allowed in src/presentation/league_theme.gd:** only UI-A6's pin-deck hook.
- **A hook you need that does not exist** goes to the coordinator as a request in your handoff.
- **Add-only:** tools/qa.py, the CI workflow and run_tests.gd. Every new art step has `if: matrix.shard == 'art'`.
- **These must stay identical:** the physics digest `75d1a3c0…`; J03 560/240/70; J05 21060.
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
