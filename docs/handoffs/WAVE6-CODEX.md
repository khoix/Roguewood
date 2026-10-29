# Codex Wave 6 — resumed checkpoint

Resumed on 2026-10-29 from usage checkpoint `6adfde3`, on
`codex/roguewood-build`. No owner-review dependency; unfinished work is explicit.

- Instructions: docs/prompts/codex-wave6.md and docs/AI-HANDOFF.md Wave 6 claims.
- Coordinator `046b04d` was merged with merge commit `257b497` after Wave 5's merge.
- **AV-C04-A DONE**, pushed `e47b7c0fad6c5f010db4406550a3ba4a62790efc`:
  Brass Cap, Gilt Leaf, Keystone. All six IDs each, host badges/overlays, effects,
  sound and flags. Unit/content, physics and 28 regression commands passed;
  final native captures inspected. See AV-C04-A.md. Remote SHA/clean tree verified.
- **AV-C04-B DONE**, completion in this commit: Chalk Grip, Spin Wax, Coin Slot.
  Full native journey headless/rendered and contacts passed, actual captures
  inspected; eighteen paths and six completion flags. Unit/content, A, J03C04
  and J11ART regressions passed. See AV-C04-B.md for exact logs and limitations.
- **AV-C04-C NOT STARTED**: Echo Charge, Lantern (High).
- **E22-L01-ART NOT STARTED**: House theme for eight Divisions, Championship,
  House Oil/Dry Backend lane visuals, music (High). Preview/inspector/contact only;
  author asset-ID/drop-path handoff for Claude's Wave 8 integration.

Start AV-C04-C (High), then House theme (High). B is fully verified. No Wave 7 art, other League themes, E26 or Claude-owned mechanics.
Only assigned catalogue asset/art/effects fields; no batch flags or League spec
edits. qa.py, run_tests and workflow are add-only; keep upload paths inside the
existing list and preserve the 90-minute timeout. No PR to main; coordinator
integrates via claude/roguewood-build. Keep this branch, no milestone branch.

Physics baseline: 75d1a3c0ceb2f8e458f7788de7e938de194633c1720aca1488b68a21eb310c6f.
J03 560/240/70; J05 21060; J06 unchanged. Screenshots remain ignored. Source
images/prompts and provenance are committed. No subagents were used. Do not rely
on temporary /tmp validation drivers; rerun repository qa.py commands directly.
