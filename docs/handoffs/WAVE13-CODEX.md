# Wave 13 — Codex checkpoint index

Status: IN_PROGRESS. This is an early checkpoint, not Wave 13 completion.
AV-N1 implementation is complete; verification remains IN_PROGRESS (163/165 matrix checks passed). Its record is in
[AV-N1.md](AV-N1.md). AV-N2 and the Neon theme tail remain NOT_STARTED.

Branch: `codex/roguewood-build`. Coordinator UI-6 `333c0af` merged with merge
commit `7dcb506`, including main `cd1cfc9` (PR #30). No rebase, force-push,
main push or pull request. The coordinator integrates this branch and owns the
central claims/progress documents.

## Delivered scope

AV-N1: Oilskin Ball, Laser Ball, Tempo Pin, Neon Sign, Blacklight, Bumper Guard.
Seven asset slots each, artwork/effects_audio flags, native physical/paid cues,
original synthesized audio and reduced effects. See AV-N1's capture index for
all shop, Binder, host, contact, rebound, accuracy and reward images. Sources,
prompts and hashes are in the asset ledger and AV-N1 brief. No captures committed.

## Resume exactly here

0. First finish the interrupted AV-N1 verification. Local checkout:
   `/workspace/work/Roguewood`. Environment setup: source
   `/workspace/work/qa-env.sh` (Godot binary in `/workspace/work/godot452/`,
   XDG directories `/tmp/roguewood-xdg/`, DISPLAY=:99, LP_NUM_THREADS=2).
   The 165-command matrix finished: 163 PASS; JAVC04B rendered timed out at
   900 s and J03C15 rendered emitted XServer BadShmSeg errors. Logs/results:
   `artifacts/wave13/av-n1/`; driver progress log:
   `/workspace/work/regressions-progress.log`. The runner is
   `/workspace/work/run-wave13-regressions.py`; it need not be rerun in full.
   Restart the dummy Xorg display with `-extension MIT-SHM` using the saved
   `/workspace/work/xorg.conf`, or use Xvfb if available, then rerun the two
   failures sequentially. The sandbox separates IPC namespaces, which can
   explain BadShmSeg; do not assume a gameplay defect or waive the failures.
   Also rerun unit/content and JAVN1 rendered after the final attribution and
   effects-off guards; inspect the six Binder/host/reward captures. Update
   AV-N1 to DONE only when these checks pass, then commit/push/verify clean.
   Existing generated images, sources, asset flags and tests are preserved.
   A one-time continuation was scheduled in this conversation for
   2026-11-15 02:51:49 America/New_York; it should continue from this step.
1. Fetch origin, verify `codex/roguewood-build` and its clean tree; merge any
   newer coordinator prerequisite with a merge commit. Read AGENTS.md, Wave 13
   claims and this checkpoint; repo claims still win. Preserve the six delivered
   AV-N1 entries and all existing journeys.
2. AV-N2 (High): read E18-C16 and E17-D13. Group A: `ball.glow`, `pin.prism`,
   `ball_mod.grip_tape`; group B: `pin_mod.spotlight`, `charm.afterimage`,
   `charm.laser_level`. List slots/provenance/journeys/captures before editing.
   Extend J03C16 with native art evidence while retaining independent banks
   1012/2015/720. Observe actual curve/first-direct facts for Glow/Spotlight,
   preserve the host under Grip Tape/Spotlight and keep Laser Level silent on
   curved frames. Only their assets and artwork/effects flags may change.
   `neon_item_glyph.gd`, `neon_item_presentation.gd` and the in_play PackedScene
   attachment binding offer scoped presentation extension points. Missing rule
   hooks go to the coordinator; never edit protected paths to invent one.
3. Neon theme tail (Medium): inspect fresh rendered J22L02LIVEART and J22L02,
   including both lane finishes and the champion portrait/landscape. The AV-N1
   slice captures are not evidence that the live Neon theme tail is finished.
   Address only the remaining developmental art. Update E22-L02-ART.md with
   actual findings, changes, captures and checks; preserve its Wave 12 history.
4. For each completed batch: unit/content and affected journeys in headless and
   rendered modes, provenance, scoped handoff, push and remote-SHA/clean-tree
   verification. Preserve digest 75d1a3c0…, J03 560/240/70 and J05 21060, and all
   named regression/art journeys. CI/qa.py/run_tests.gd remain add-only; new art
   steps use the art-shard guard.
5. Write AV-N2.md. When all claims are complete, turn this checkpoint into the
   Wave 13 completion index, with the final capture review list and SHA report
   to the coordinator. Stop before AV-N3 or the Salvage art.

No effort-level mismatch: AV-N1 High; next AV-N2 High, theme tail Medium.
