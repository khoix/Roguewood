# Codex Wave 6 — usage checkpoint

Paused at the owner's request on 2026-10-29. Resume on `codex/roguewood-build`.
No owner-review dependency is recorded; unfinished implementation remains explicit.
The containing checkpoint commit is the resume head.

- Instructions: docs/prompts/codex-wave6.md and docs/AI-HANDOFF.md Wave 6 claims.
- Coordinator `046b04d` was merged with merge commit `257b497` after Wave 5's merge.
- **AV-C04-A DONE**, pushed `e47b7c0fad6c5f010db4406550a3ba4a62790efc`:
  Brass Cap, Gilt Leaf, Keystone. All six IDs each, host badges/overlays, effects,
  sound and flags. Unit/content, physics and 28 regression commands passed;
  final native captures inspected. See AV-C04-A.md. Remote SHA/clean tree verified.
- **AV-C04-B IN_PROGRESS**, saved in this checkpoint: Chalk Grip, Spin Wax,
  Coin Slot. Resources/code authored, unit and headless native pass, contact
  both modes pass. Full rendered native run stopped for this usage checkpoint;
  completion flags stay false. Exact resume steps/evidence are in AV-C04-B.md.
- **AV-C04-C NOT STARTED**: Echo Charge, Lantern (High).
- **E22-L01-ART NOT STARTED**: House theme for eight Divisions, Championship,
  House Oil/Dry Backend lane visuals, music (High). Preview/inspector/contact only;
  author asset-ID/drop-path handoff for Claude's Wave 8 integration.

Start with AV-C04-B's full rendered native run. Finish and push B before C; then
House theme. No Wave 7 art, other League themes, E26 or Claude-owned mechanics.
Only assigned catalogue asset/art/effects fields; no batch flags or League spec
edits. qa.py, run_tests and workflow are add-only; keep upload paths inside the
existing list and preserve the 90-minute timeout. No PR to main; coordinator
integrates via claude/roguewood-build. Keep this branch, no milestone branch.

Physics baseline: 75d1a3c0ceb2f8e458f7788de7e938de194633c1720aca1488b68a21eb310c6f.
J03 560/240/70; J05 21060; J06 unchanged. Screenshots remain ignored. Source
images/prompts and provenance are committed. No subagents were used. Do not rely
on temporary /tmp validation drivers; rerun repository qa.py commands directly.
