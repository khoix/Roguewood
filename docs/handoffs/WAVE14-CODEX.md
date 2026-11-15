# Wave 14 Codex checkpoint

Status: IN_PROGRESS — synchronization checkpoint only (2026-11-15).

Merged coordinator `be1d045ce1a7ad4992dd1880a906e43cc92f7ac5` into
`codex/roguewood-build` with merge commit
`c9ecd3811979af00345f285b37a9fbbe986584c5`. Includes E05-R5 and UI-9.
No PR opened; no main push. No implementation changes in this checkpoint.

Read AGENTS.md, the roadmap, Wave 14 claims/progress and ownership sections.
No existing DONE handoff for AV-T02, AV-N3, AV-N4, AV-N5 or UI-A6.
The owner's session prompt replaces codex-wave14.md; item briefs still apply.

## Validation

Attempted `python3 tools/qa.py unit` and `python3 tools/qa.py content`.
Both stop before tests: expected Godot 4.5.2.stable, installed
4.6.3.stable.official.7d41c59c4. Neither is a passing test run.
No journeys or captures produced. No physics or score invariants verified yet.

## Exact resume step

Install Godot 4.5.2 outside tracked files and set `GODOT_BIN` to it; rerun
unit/content baseline. Read E05-R5 and ADR 011's flywheel revision, inspect
AV-T01 presentation and JAVT01, and list asset IDs/slots, provenance and
capture plan before implementing AV-T02. Preserve gesture/launch values and
existing cues. Capture rest, curve-ready and full in depth/flat, A/B and
normal/reduced motion; run J02 and JAVT01 headless and rendered plus physics.
Write AV-T02.md and provenance, push and verify remote SHA and clean tree.
Then AV-N3, AV-N4, AV-N5, UI-A6 in that order, following their briefs and
per-item validation/handoffs. All five items remain unfinished.

## Owner capture index

None yet. Populate with actual rendered capture paths as items complete;
never commit captures.
