# UI-A1-A — the card

State: DONE (Session A implementation and verification). UI-A1 as a whole remains
IN_PROGRESS: Session B is not implemented. Branch: `codex/roguewood-build`.
Base: merge `ef903a0`, including Claude `3af873b` (claims `28d763f` and E26-W01).
No main merge or owner visual approval is claimed.

## Delivery

- Five 210×300 rounded House frame masters (common through legendary), a card
  back, Value/Mult/$ icons and five category marks. Fourteen SVG resources with
  an original deterministic source generator under `assets/ui/cards/`.
- Real existing illustrations: `ball.house`, `pin.ruby`, `charm.crown_jewel`,
  `consumable.nudge`, `shop_upgrade.spotlight_sign`. Art occupies 51.7% of each
  face. Names, rule hints and rarity seals are native text. No catalogue changes.
- Standalone `src/presentation/ui_a1_preview.tscn` with a keyboard/button-operated
  switch between real catalogue rarities and explicitly labelled material studies
  (including Legendary, which has no current catalogue item).
- JUIA1 in `tools/qa.py`, art-only CI step and upload folder, all additive.
  No existing UI scripts, game rules, inputs, theme IDs or bindings changed.
- Dimensions, safe areas, layer order, state/motion specifications and scope in
  `docs/art/ui/UI-A1.md`; provenance in `docs/art/ASSET-LEDGER.md`.

## Evidence

Godot 4.5.2 stable, Linux, Compatibility renderer / Mesa llvmpipe.
`qa.py unit`, `content`, `physics`, JUIA1 headless and rendered PASS.
Physics digest remains `75d1a3c0ceb2f8e458f7788de7e938de194633c1720aca1488b68a21eb310c6f`.
JUIA1 `--inject-failure` correctly exits 1. JUIA1 verifies actual
portrait/landscape bounds, non-overlap, text metrics, minimum 14 px type, native
mode-switch input, loaded illustrations and contained art windows occupying
more than half the face. The initial rendered check exposed source-size texture
overflow; fixed before delivery and covered by a containment assertion.

Captures, inspected at native size, under `artifacts/ui-a1/rendered/`:

- `portrait_cards.png` — 720×1280, five categories with catalogue rarities + back.
- `landscape_cards.png` — 1280×720, same collection.
- `portrait_studies.png` — five material tiers; does not alter item rarity.
- `landscape_studies.png` — material comparison and typography at 210×300.

Captures are ignored outputs and CI artifacts, never committed. Physical-phone
readability is not claimed. Dynamic foil, state animations and production UI
integration are not implemented here. Font remains the provisional engine
fallback until UI-A1-B. Existing whole-game journeys were not rerun in this
isolated visual session; their existing CI steps remain intact.

## Hand-off

Ready for Claude to inspect as Session A of UI-A1. Owner reviews the completed
UI-A1 target before UI-1 integration. Do not integrate this preview as live UI.
The card target is source-backed and replayable with the two JUIA1 qa commands.
No AV-H3 artwork/effects flags have been advanced.

## Resume exactly here

1. Fetch origin and inspect the remote branch; resume this checkpoint on
   `codex/roguewood-build`. Merge newer Claude work with a merge commit if needed.
2. UI-A1-B (High): create House nine-slice HUD/shop/score-slip/menu/panel kit,
   choose and check in a licensed pixel font with its licence and ledger entry,
   build portrait and landscape throw/shop compositions. Extend this preview and
   JUIA1 additively; finish UI-A1.md with nine-slice margins and actual font sizes.
3. Then AV-H3-A (Spare Ball, Workhorse, Oak Pin), followed by AV-H3-B (Tin Pin,
   Spare Jar, Consolation Prize), reading E18-C10 and E17-D09 landed needs.
   Native checks must precede both flags. Workhorse/Spare Jar need authoritative
   counted presentation; use High effort for these sessions.
4. Run the required final regression matrix, write both AV handoffs and
   WAVE9-CODEX.md with the full UI-A1 capture index, push and verify remote/clean
   tree. Wave 9 is not complete at this Session A checkpoint.
