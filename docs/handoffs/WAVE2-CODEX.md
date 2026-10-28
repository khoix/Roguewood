# Codex Wave 2 — final delivery

Implementation and scoped verification: **DONE**. Codex / `codex/roguewood-build`.
Coordinator `8322457` was integrated with merge commit `c9c205a`; no rebase or
force push. The containing commit identifies the delivered work. Owner merge is
approval; there is no pending-owner milestone state. Coordinator owns the central
AI-HANDOFF.md update; this file and the child handoffs report Codex's results.

| Batch | Delivered | Verification |
|---|---|---|
| E16-ART | Ten trophy/ribbon/plaque/decoration PNGs, Clubhouse masthead/tabs/shelves, four explicit binder states, E12 static Mastered foil | Original J01/J11 and extended J11ART headless/rendered; 720×1280 and 1280×720; 120px contact sheet |
| E19-A08 | Gold Ball, Glass, Fuse, Crown | J19A08 headless/rendered; color/gray/silhouette and named comparison items |
| E19-A09 | Echo Pin, Nudge, Reserve Call, Rule Waiver | J19A09 headless/rendered; distinct pin, tile, trays and permit constructions |
| E19-A10 | Spark Ball | J19A10 headless/rendered; conductor forks versus Fuse wick / Echo rings |
| E19-A11 | Ghost Ball | J19A11 headless/rendered; transparent shell identity, static ready/solid model previews; final curved-band rerun PASS |
| E19-A12 | Splitter Ball | J19A12 headless/rendered; seam/chevrons, assembled/separated model previews; attached hardware/holes rerun PASS |

Twenty-one original transparent source PNGs, exact generation prompts and SHA-256
hashes are recorded in ASSET-LEDGER. All 52 D01 identity asset paths use the exact
`design.asset_ids`. The 22 activation/audio paths remain empty. All authored flags
remain unchanged/false for artwork, mechanics and effects. No D01 definition was
added to the playable catalogue. Art is READY for E18 integration; actual in-play,
activation, non-trigger and lifecycle verification must follow each implementation.
This is the explicitly assigned Wave 2 art boundary, not unfinished E20 work.

D01 in-play assets are cosmetic PackedScenes, not replacement rigid bodies. They
contain original meshes/materials and static identity states, no colliders or
behavior. The child handoffs explain origin/scale/state setup. Scene resources
must be attached to E18's authoritative bodies and must never change collision,
mass, scores or saved state. No full-family E19/E20/release completion is claimed.

## Checks and evidence

Godot 4.5.2, Linux x86-64, Xvfb/llvmpipe. Unit, content, integration, smoke and
physics PASS. J03/J05/J06 headless PASS with unchanged scoring/awards; J03 still
560/240/70 and J05 21060. Physics digest:
`75d1a3c0ceb2f8e458f7788de7e938de194633c1720aca1488b68a21eb310c6f`.
All ten batch preview checks pass, plus J01/J11/J11ART in both modes. The final
Clubhouse layout and Ghost/Splitter preview refinements were rerun and inspected.

Scope audit against `8322457` passes: only the 52 allowed asset paths differ in
E17-D01.json; no authored definitions, flags, design IDs or triggers changed.
Playable catalogue, rules, simulation, persistence, Career, procedural code,
throw_lab, bootstrap and clubhouse_model are unchanged. Shared qa.py/workflow
edits are add-only; run_tests.gd is unchanged. The owner explicitly authorized the
two-line missing-art fixture correction in clubhouse_test.gd, preserving its
fallback assertion now that trophy.house is real artwork. No other shared tests
were edited. PNG alpha/provenance checks and `git diff --check` pass.

Logs: `artifacts/wave2/validation/{previews,regressions}.json` and individual logs.
New captures: `artifacts/e16-art/` and `artifacts/e19-a08…a12/preview/rendered/`.
Each batch has 192px cards, 48px color/gray/silhouette icons, comparison sheets and
portrait/landscape inspector-style previews. Clubhouse captures use the actual
unlock/restart/shop/collection journey. Screenshots are ignored, never committed.
Bootstrap now regenerates these journeys and uploads their evidence.

Viewport readability is verified; physical phones, GPU performance, audio latency
and installed mobile builds remain E26. D01 previews do not measure gameplay feel
or verify the E18 mechanics. No claim of device certification is made.

## Hand-off

Coordinator can record E16-ART and E19-A08…A12 DONE within their assigned scopes.
E16 core plus this art completes E16. E18 can consume D01 identity resources and
set catalogue artwork flags only after its native checks. D01 effects/audio still
wait for E18 and a subsequent E20 claim. No E22 work was started.

The next available Codex task is E17-D02-ART (twelve Charm briefs), READY in the
coordinator handoff, recommended Medium effort. Wave 2 stops here as instructed.
