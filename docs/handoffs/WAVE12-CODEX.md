# Wave 12 — Codex setup checkpoint

Status: IN_PROGRESS; no art batch delivered. The requested fresh checkout is at
`/workspace/Roguewood`, on `codex/roguewood-build`. The coordinator's Wave 12
claims were fetched and merged with a merge commit, without rebasing.

Read: AGENTS.md, the Wave 12 claims and ownership lanes, roadmap Wave 12,
UI-4 and League template, UI-4/E17-L02/WAVE11-CODEX handoffs and neon.json.

## Verification

`python3 tools/qa.py unit` and `python3 tools/qa.py content` were attempted.
Both stopped at the engine-version gate: this environment provides Godot
4.6.3.stable, while the repository requires 4.5.2.stable. Neither suite ran;
no passing result is claimed. No journeys or captures ran. No implementation
files were changed in this checkpoint beyond the coordinator merge.

## Exact resume

1. Install the pinned Godot 4.5.2 standard binary outside tracked files; verify
   against tools/godot-downloads.sha512 and set GODOT_BIN. Configure writable
   XDG cache/data directories. Re-run unit and content.
2. Start UI-A3 (Medium). Before authoring, list the font slots, source and
   provenance plan, affected journeys and captures. Inspect the existing OFL
   and digit outlines, then choose patched digits or a numeric face. Record
   provenance and any reserved-name handling in ASSET-LEDGER.md. Stay in
   assets/ui/fonts/ and docs/art/ui/; a second face's wiring belongs to Claude.
3. Capture the existing phone tour at 780×1688 before the font change, then
   after: score slip, frame review including rack numbers, shop price, money
   slot and throw tuning. Keep captures untracked. Fetch and merge Claude
   again before editing journeys affected by UI-5 navigation/reveal/purchases.
4. Finish UI-A3 validation and docs/handoffs/UI-A3.md, push and verify the
   remote SHA and clean tree. Continue R05 (including the three House plaques),
   R06, R07 and the two E22-L02-ART sessions in that order, with each batch's
   required handoff and checks. Do not begin AV-N1/AV-N2.

## Owner capture index

None yet. UI-A3, E21-R05, E21-R06, E21-R07 and E22-L02-ART remain unimplemented.
This is an early setup checkpoint, not the Wave 12 close.
