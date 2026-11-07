# UI-A2 — House card materials and final icons

State: DONE (asset implementation and native verification).
Branch: codex/roguewood-build. Started from UI-A1-C 5fb5cec; merged Claude UI-1
2c7ffd5 with merge commit d51149c before authoring. No card_view.gd or other
production UI edits by Codex. No catalogue or completeness flag changes.

## Delivered

- Five House rarity overlays and five reduced resources: matte Common, brass
  Uncommon, sea-glass border Rare, faceted Epic, engraved prism Legendary base.
- Explicit progress input, no TIME-driven animation; static reduced states for
  reduced motion or flash. Materials must be duplicated per card.
- League-keyed manifest binds the five approved House frames, overlay resources
  and reduced versions. House is the authored first family; unprovided Leagues
  explicitly fall back to House. No Neon/future League art is claimed.
- Final icon registry: eight stable score/category symbols plus nine original
  action/state icons (Cycle, Inspect, deck, discard, Options, target, lock,
  armed, sold). Original deterministic generator and provenance in the ledger.
- Integration contract: docs/art/ui/UI-A2.md. A full-face ColorRect overlay,
  above the illustration but below all live text, badges, stamps and prices.
  Do not assign it as the illustration's texture shader. Disable the inspector's
  older foil when integrating this layer to avoid double coating. Compact layouts
  need their art masks mapped, or rim-only/no overlay until that is done.

The Legendary material is a reusable substrate, not a replacement for individual
Legendary art/reveals. No current catalogue item is assigned Legendary rarity.
The contact sheet explicitly presents material studies.

## Owner sky feedback — UI-A1-C follow-up

The starfield now has 240 mostly dim points (previously 90). Repeated zigzag
constellations are replaced with four individually drawn schematic patterns:
Orion, Cassiopeia, Cygnus and Ursa Major's Big Dipper asterism. Each appears once,
with a different shape and position. These are recognizable decorative drawings,
not an astronomical coordinate chart. Static reduced versions remain available.
This refines UI-A1-C; no wider House environment or theme binding changes.

## Verification

Pinned Godot 4.5.2, Compatibility/Mesa llvmpipe:
- qa.py unit and content PASS on the merged UI-1 tree.
- JUIA2 headless and rendered PASS. Pixel checks verify phase response for shiny
  tiers, matte Common, identical reduced images across phase changes, and no
  coating over name/rule/rarity/category regions relative to the base image.
- JUIA1 headless/rendered PASS after the material additions; re-run after the
  owner-requested sky refinement. All original and revised captures retained.
- Generator reproduces all ten materials, manifest and nine icons byte-for-byte.
- git diff --check PASS. qa.py and CI additions only; JUIA2 is art-shard-only and
  its folder is inside the existing artifact upload list.

Captures: artifacts/ui-a2/rendered/{phase_a,phase_b,base}.png. Top row responds
to phase, bottom row uses reduced resources. Icon row follows manifest order.
Updated sky captures: artifacts/ui-a1/rendered/1280x720_{0,1}_{motion,still}_throw.png
and the corresponding portrait/4:3 images. Never committed screenshots.
Logs: artifacts/wave10-codex/ui-a2/. Production integration, phone certification
and the full Wave 10 closing regression matrix are not claimed by this batch.

## Resume exactly here

UI-A2 assets are ready for Claude's card-component integration using the linked
contract. UI-A1-C's two updated backdrop choices remain available for owner review.
Next: AV-H4-A, High recommended because Pin Count is counted feedback and Double
Take needs causal attribution. Read E18-C11, landed E17-D10 design blocks and the
latest J03C11 (UI-1 removed direct selection). Deliver Double Take, Called Shot,
Pin Count art/activation/sound and native evidence before setting both flags.
Then AV-H4-B (Cleanup Crew, Lucky Seven), followed by the required full matrix
and WAVE10-CODEX.md. No AV-T01 or future League work this wave.
