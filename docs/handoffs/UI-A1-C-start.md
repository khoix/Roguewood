# UI-A1-C — Wave 10 starting checkpoint

State: IN PROGRESS. This checkpoint merges coordinator `2864889` into
`codex/roguewood-build` with a merge commit. It does not deliver the revised
layouts or backdrop options. No Wave 10 completion flags have been changed.

## Reconciled assignment

The Wave 10 prompt and ROADMAP owner decisions supersede the Wave 9 composition
coordinates in UI-A1.md. UI-A1-C comes first; UI-A2, AV-H4-A and AV-H4-B follow.
AV-T01 is Wave 11. Existing production UI and input remain Claude's exclusive
paths. The old WAVE9-CODEX.md resume ordering is superseded by this claim.

The existing composition scene is isolated and reusable, but throw_page uses a
narrow lane, portrait has three cards, landscape has two, and landscape shop has
four columns. All four differ from the new assignment. Preserve the shared card
factory and its tested rarity-footer clearance while rebuilding the composition.

## Implementation and evidence plan

- Landscape 1280×720: full-width lane viewport behind the top bar and flank
  panels; four-card hand at left, slip/rival/Charms at right. Each flank targets
  19% width. Test the actual projected corridor, not the viewport rectangle,
  against panel bounds.
- Narrow landscape 1024×768: shrink flanks only while content fits; otherwise
  fold into the top bar with native controls to expose each folded panel.
  Preserve the central corridor and minimum readable text/action sizes.
- Portrait 720×1280: two-row top bar with a separate money slot, slip/rival
  strip, Charms row, full-width lane, two-card hand and thumb-side controls.
  Include mirrored left-handed controls. Check the projected ball sits near
  two-thirds of the lane viewport height.
- Landscape shop: three columns at both aspect ratios. Existing portrait shop
  remains subject to text and safe-area checks.
- Proposed original procedural House backdrop options: sparse slow stars,
  subdued constellation lines, and static petrol vignette. Each must offer an
  explicit reduced state. These are proposals to implement and capture, not
  delivered assets or an owner selection. Keep all options behind lane/panels;
  do not broaden House environment art or change League asset bindings.
- Sources: existing House frame kit, existing item illustrations and Pixelify
  Sans; new backdrop code under assets/ui with provenance in ASSET-LEDGER.md.
  No external art or new font dependency is planned.
- Extend JUIA1 without removing its ten existing captures. Add throw/shop
  captures for portrait, 16:9 and 4:3 for each option, plus reduced states and
  folded-panel/left-handed evidence. Add assertions for hand counts, separate
  money bounds, three shop columns, lane corridor clearance and stable reduced
  backdrop output. qa.py and CI remain add-only; art steps stay in the art shard.

## Resume exactly here

1. Inspect this checkpoint and the baseline logs under
   artifacts/wave10-codex/baseline/. These checks cover the merged existing UI,
   not the as-yet unimplemented C revision.
2. Implement UI-A1-C in ui_a1_composition.gd and its standalone scene, new
   assets/ui backdrop resources and tests/ui_a1_journey.gd. Keep production UI
   scripts and input untouched. Preserve earlier card and frame-kit assertions.
3. Render every new composition, inspect it, update docs/art/ui/UI-A1.md to
   replace the obsolete coordinates, record provenance and write UI-A1-C.md.
4. Run unit/content and JUIA1 headless/rendered, then commit/push and verify
   remote SHA and clean tree. Owner review of the resulting captures precedes
   Claude's UI-2 integration; no approval is being requested at this checkpoint.
5. Continue UI-A2, AV-H4-A/B, then the required closing matrix and
   WAVE10-CODEX.md. Recommended next effort: Medium for UI-A1-C.

## Baseline verification

On the merged tree, pinned Godot 4.5.2: qa.py unit and content PASS;
JUIA1 headless and rendered PASS. This is existing Wave 9 preview evidence only.
No new layout, backdrop or AV-H4 asset is claimed. Full Wave 10 regression
verification remains for the implemented batches and closing checkpoint.
