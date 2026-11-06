# UI-A1-C — layout revision and House backdrop alternatives

State: DONE (implementation and native verification).
Branch: codex/roguewood-build; base 9761de9, including coordinator 2864889.

Standalone scene: src/presentation/ui_a1_revision.tscn. It preserves the old
card/frame specimens and supplies the current screen target described in the
new UI-A1-C section of docs/art/ui/UI-A1.md. No production UI or input edits.

Delivered: full-width landscape lane viewport, 19% flank panels, four-card hand,
score slip/rival/Charms at right; narrow landscape fold controls; three-column
landscape shop. Portrait has the two-row HUD, separate money cell, slip/rival
strip, Charms row, full-width viewport, ball framed at two-thirds height,
two-card hand and mirrored thumb-side controls. Values remain static samples.

Two original procedural backdrops: Slow stars (0), Constellations (1). Each has
an explicit static reduced state. No wider environment art or House binding
changes. The exported scene properties select option/reduced/left_handed.

JUIA1 now uses a derived journey retaining every original card, text, frame-kit,
corner and composition assertion/capture. It adds the revised size/backdrop
matrix, hand/shop counts, text widths, actual projected ball height and lane
edges, corridor clearance, reduced phase stability and real folded-button input.
qa.py changes are additive. The existing art-only JUIA1 CI step uploads all new
captures, so no extra gameplay-shard step is needed. JUIA1CSTUDY is also available
as a diagnostic alias. No screenshots are committed.

## Owner review captures

All under artifacts/ui-a1/rendered/:
- 720x1280_{0,1}_{motion,still}_{throw,shop}.png
- 1280x720_{0,1}_{motion,still}_{throw,shop}.png
- 1024x768_{0,1}_{motion,still}_{throw,shop}.png
- folded_hand.png, folded_details.png, left_handed.png

The ten original captures remain as regression specimens. The revision scene,
not the legacy composition scene, is the current screen target. Review the two
backdrop alternatives before Claude integrates the selected one in UI-2.
No subjective owner approval or physical-phone certification is claimed.

## Resume exactly here

After verification/push of this child, continue UI-A2 (Medium–High): shader/layer
foil and rarity treatments, reduced states, House-first frame variants and final
icons. Deliver assets and integration notes; do not edit card_view.gd.
Then AV-H4-A (Double Take, Called Shot, Pin Count) and AV-H4-B (Cleanup Crew,
Lucky Seven), native J03C11 verification before flags. AV-T01 remains Wave 11.
At wave end run the required regression matrix and write WAVE10-CODEX.md with
these capture paths and backdrop options. Coordinator owns central state.


## Verification

Pinned Godot 4.5.2, Linux Compatibility/Mesa llvmpipe: qa.py unit and content
PASS; extended JUIA1 headless and rendered PASS, all 37 required captures present.
Inspected portrait, landscape, 4:3 shop/folded hand, mirrored portrait and both
backdrop styles. Fixed the initial clipped landscape ball, opaque viewport,
compact label contrast and art-window overflow before delivery. No production
rules, physics, input or UI scripts changed; no catalogue flags changed. The
full Wave 10 gameplay/art regression matrix remains a closing-wave task, not
claimed at this isolated UI-A1-C checkpoint. git diff --check PASS.
Logs: artifacts/wave10-codex/ui-a1-c/. Captures remain ignored artifacts.
