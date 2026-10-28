# Codex Wave 3 — final delivery

**Implementation and scoped verification: DONE.** Branch: `codex/roguewood-build`.
Coordinator `fede206` (includes requested `a78e73b` and CI upload fix `973ba00`)
was integrated with merge commit `3ff8e71`. The containing commit identifies this
delivery. Coordinator integrates this branch into `claude/roguewood-build`; no
Codex PR to main is opened. Central coordination state remains Claude's file.

| Claim | Delivered | Evidence |
|---|---|---|
| E17-D02-ART | Twelve briefs, all 72 exact design IDs from definitions and landed, trigger/tag/presentation requirements, four requested look-alike flags | Brief and child handoff; comparisons in A13/A14 |
| E19-A13 | Pin Counter, Hot Streak, Last Stand, Tip Jar | J19A13 and J19A13N, headless/rendered; four native-checked catalogue artwork flags |
| E19-A14 | Banana Ball, Plumb Line, Glass Cutter, Split Specialist | J19A14 and J19A14N, headless/rendered; first two native-checked flags, last two authored paths only |
| E19-A15 | Sweet Spot, Back Row, Underdog, Crown Jewel | J19A15 headless/rendered; authored paths only; Epic full-card foil/static reduced preview |

Twelve original transparent source PNGs and 48 identity resources use the exact
design IDs. Sources are unchanged; prompts and SHA-256 hashes are in ASSET-LEDGER.
The 24 activation/audio paths remain empty. No separate in-play IDs are invented:
EquipmentArtStrip falls back to the declared icon for Charms without an in-play
texture. Existing entries keep their existing in-play textures.

The six playable artwork flags were enabled only after both native modes passed
and captures were inspected. Each item appeared as a real shop offer, was bought
through the UI, displayed in inventory, and appeared in its binder entry. The
fixture grants a wallet and shop eligibility, without inserting owned items.
The following real throw's bank matches independent rule resolution. Authored
entries remain outside the playable catalogue; their flags are unchanged.

## Verification

Godot 4.5.2, Linux x86-64, Xvfb/llvmpipe. All ten new art checks PASS: three batch
previews and two native journeys, each headless/rendered. Captures cover 192px
cards, 48px color/grayscale/silhouette contacts, named look-alike comparisons,
portrait/landscape layouts, real shop/inventory/binder and reduced motion.
No requested pair remains an unresolved visual blocker; the child handoffs record
the concrete separating shapes. This is viewport evidence, not phone testing.

Unit and content PASS with final artwork flags. Integration, physics and smoke
PASS. J03/J05/J06 headless PASS; J03 retains 560/240/70, J05 retains 21060.
J03C01 and J11ART PASS headless/rendered, including the six now-required binder
icons. Existing J08A01 rendered PASS checks the earlier hand-card/shop art path.
Physics digest remains
`75d1a3c0ceb2f8e458f7788de7e938de194633c1720aca1488b68a21eb310c6f`.

Scope audit against `fede206`: catalogue changes are exactly 24 identity paths
and six artwork flags; batch changes are exactly 24 authored identity paths.
Definitions, design IDs, all other completeness flags and gameplay data match
the base. No rules, physics, persistence, Career, procedural, throw_lab,
bootstrap, clubhouse_model or shared tests changed. qa.py and workflow additions
are inside their existing dictionaries/lists. A parsed YAML comparison confirms
the old workflow is identical after removing the new step and three upload paths;
`if-no-files-found: warn` remains a sibling of `path`. `git diff --check` passes.

Ignored logs/manifests: `artifacts/wave3/validation/` (`art-checks.json`,
`regressions.json`, `headless-final.json`, `rendered-final.json`, `scope.json`).
Native captures: `artifacts/e19-a13/native/rendered/` and
`artifacts/e19-a14/native/rendered/`. Contacts and inspector previews:
`artifacts/e19-a13…a15/preview/rendered/`. CI regenerates/uploads the ten new
checks in the existing Bootstrap workflow. No screenshots are committed.

## Coordinator integration

Record these four claims DONE within their assigned scope. Merge the Codex
branch through the established coordinator path. Claude's concurrent E18-C02
may move Glass Cutter out of the authored batch: retain its four identity paths
on the new catalogue entry, and complete its native checks before setting its
artwork flag. A14's native journey includes any newly landed item in that batch.

The six authored identities are READY for E18 consumption; native integration
and trigger/lifecycle checks follow their mechanics. Activation/audio is future
E20 work. Physical-device readability and performance remain E26. No E20 or
next-wave implementation was started. Next proposed Codex task: E17-D03-ART
when the coordinator opens Wave 4, recommended Medium effort.
