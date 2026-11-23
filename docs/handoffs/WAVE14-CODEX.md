# Wave 14 Codex checkpoint

Status: IN_PROGRESS — UI-A9-H remains. Branch: codex/roguewood-build (2026-11-23).

Coordinator be1d045 was merged with merge commit c9ecd381. Includes E05-R5
and UI-9. No rebase, force-push, main push or PR. Initial synchronization
checkpoint: 2b3653e. The owner's session prompt replaces codex-wave14.md;
per-item briefs still apply.

## Items

- AV-T02: DONE; implementation and verification recorded in AV-T02.md.
- AV-T03: DONE; verification and 85 captures in AV-T03.md. Supersedes AV-T02 held-ball visuals.
- UI-A7: DONE; local hall motion, pixel 3D ball, native/web checks and loader review in UI-A7.md.
- AV-N3: DONE; six identities/effects/sounds, required native checks and 64 captures in AV-N3.md.
- AV-N4: DONE; five identities/effects/sounds, the Controlled Curve ribbon,
  203 passing local checks and 52 captures. Details in AV-N4.md.
- AV-N5: DONE; five identities/effects/sounds, two mastery ribbons, 211 distinct
  passing local checks and 64 captures. Details in AV-N5.md.
- UI-A6: DONE; manifest pin-deck hook, static House finish, 35 passing targeted
  checks and 21 native captures. See UI-A6.md.
- AV-FIX1: DONE; transparent Spare Jar and eight native before/after captures,
  with affected checks passing. Seven other cards were fixed by the coordinator.
  See AV-FIX1.md.
- UI-A9-H: NOT_STARTED; House alley-screen celebrations, next after merge checks.
- Salvage art stays outside Wave 14.

## Owner capture index

AV-T03: 85 ignored captures in artifacts/av-t01/rendered/ replace the old
AV-T02 captures. Review depth_normal_swirl_130/135/140.png, then the
model2_flat_normal sequence and depth_motion_full.png. All models/views,
charge stages and accessibility modes: AV-T03.md. No captures committed.

UI-A7: artifacts/ui-a7/{portrait,landscape}/motion_000..036.png, reduced_early/late,
loader/half.png and complete.png, and both 31-capture phone tours. Full index: UI-A7.md.

AV-N3: artifacts/av-n3/{native,reduced}/rendered/, 28 captures each. Review
`n3_side`, `n3_lane`, `n3_hook_shot_armed`, `n3_rescue` and the five `*_paid`
captures; all six shop/Binder identities are included. Contact sheets in
artifacts/av-n3/{contact,contact-b}/rendered/. Full index: AV-N3.md.

AV-N4: artifacts/av-n4/{native,reduced}/rendered/, 22 captures each. Review
`n4_specialist`, `n4_specialist_offer`, `n4_trade_sale`, `n4_comet_trail` and
the three `*_paid` captures. All five shop/Binder identities are included.
Contact sheets and the labelled earned ribbon specimen are in
artifacts/av-n4/{contact,contact-b}/rendered/. Full index and native mastery
limits: AV-N4.md.

AV-N5: artifacts/av-n5/{native,reduced}/rendered/, 28 captures each. Review
`n5_lane_two_tone`, `n5_lane_long_oil`, `n5_lane_house_oil`, `n5_side`,
`n5_rescue` and the five `*_paid` captures. All five shop/Binder identities and
both native Trophies/Goals rows are included. Contact sheets and the labelled
earned ribbon specimens are in artifacts/av-n5/{contact,contact-b}/rendered/.
Full index and native mastery limits: AV-N5.md.

UI-A6: artifacts/ui-a6/rendered/. Review deck_d02_feature, deck_d03_boss and
deck_d08_boss with _portrait, _landscape and _roll suffixes. Eight opener captures
cover Divisions 1–8. Neon comparison: artifacts/e22-l02-art/live/rendered/
live_pin_deck_{normal,reduced}.png. Full index: UI-A6.md.

## Exact resume step

AV-FIX1 and the affected local AV-N4/N5/UI-A6 merge checks are complete.
Comet's rotation visibility is corrected; J02 and JAVN4/JAVN4R pass both modes.
First inspect CI for this checkpoint: prior checkpoint 1ecd20a passed the full
Bootstrap art job and E11 still review, but Bootstrap game and E12 motion jobs
failed without accessible diagnostic logs. Do not assume the Comet correction
resolves those failures. Obtain the actual assertion from the fresh run and fix
only scoped art/test regressions; route coordinator-owned issues in the handoff.
Then UI-A9-H (High): read docs/prompts/codex-wave14-ui-a9.md and UI-20, list the
twenty scene IDs, sound slots, provenance and native captures before authoring.
UI-A9-H is NOT_STARTED. AV-UI1 remains proposed only; no Wave 15 work.
The scheduled twenty-minute continuation was bounded to 08:11:23–08:31:23 UTC
on 2026-11-23. This is its stopping checkpoint; do not continue another item.

## Validation environment

Installed pinned Godot 4.5.2 in /tmp/godot452/ (outside source). Set GODOT_BIN
explicitly. XDG_CONFIG_HOME=/tmp/roguewood-config,
XDG_CACHE_HOME=/tmp/roguewood-cache, XDG_DATA_HOME=/tmp/roguewood-data.
Rendered runs use isolated Xorg dummy display :98 (MIT-SHM disabled) configured by
/tmp/roguewood-xorg.conf. Engine/display may need reinstalling after session
reset. The initially installed 4.6.3 was not used for passing checks.
Local logs: /tmp/t03-*.log (prior checkpoint /tmp/w14-*.log); durable results in the item handoff. Full-wave
regression matrix remains for subsequent items/integration.

UI-A7 environment: Xorg :96; matching Playwright browser in /tmp/a7-browsers,
web templates installed under the temporary XDG data directory. Logs /tmp/a7-*.log.

UI-A7 owner correction: restored original illustrated ball design and reflective
finish at larger scale. Latest captures are artifacts/ui-a7-revision/
final-{portrait,landscape}/; see UI-A7.md's owner-correction section. Remaining
item order is unchanged.

AV-N3 environment: pinned Godot 4.5.2, Xorg :94 with MIT-SHM disabled. UI-11
coordinator 5f38708 merged by 61cc43e before work. The environment restarted
during regression checks; passing results were retained and unfinished checks
resumed. Logs/results: artifacts/wave14/av-n3/ and /tmp/n3-*.log.

AV-N3 required checks pass. The supplementary matrix recorded 72 passing checks;
remaining full-wave coverage is listed in AV-N3.md and is not claimed complete.

AV-N4 environment: pinned Godot 4.5.2, Xorg :93 with MIT-SHM disabled, same
temporary XDG directories and LP_NUM_THREADS=2. Logs/results and the asset
reproduction audit: artifacts/wave14/av-n4/. Final verification is recorded in
AV-N4.md; the central claims/progress file remains the coordinator's.
Additional rendered art checks used isolated displays :91/:92 with one llvmpipe
thread each. All 203 local checks passed, including all 167 configured art-shard
journey modes and the protected gameplay batch. These results supersede AV-N3's
incomplete art-matrix coverage on this merged tree. Full CI/Web and remaining
gameplay integration are still the coordinator's wave-closing work.

AV-N5 environment: pinned Godot 4.5.2, Xorg :90 with MIT-SHM disabled and the same
temporary XDG directories; extra art checks used isolated :91/:92. Coordinator
8bafa27 was merged by 0cbd9a4 before authoring. Results, capture manifests and
asset/scope audits are in artifacts/wave14/av-n5/. The broad matrix has 211
distinct passing checks, including all 175 configured art-shard journey modes.
JAVC04B rendered timed out under concurrent software rendering, then passed
alone with its original 900-second timeout. Final label checks and full details
are recorded in AV-N5.md. No captures are committed. Full CI/Web and wave
closure remain the coordinator's work.

UI-A6: pinned Godot 4.5.2, isolated Xorg :90, same temporary XDG directories.
All 35 targeted checks pass; results and audits are in artifacts/wave14/ui-a6/.
Physics digest and J03/J05 pinned scores remain unchanged. This targeted run
includes both League journeys and their art journeys in both modes; it does not
claim a fresh full art-shard or full CI/Web run. See UI-A6.md for scope and limits.

AV-FIX1 completion: artifacts/av-fix1/{binder,shop}/{before,after}/rendered/
contains eight reviewed native captures. The before specimens use original art
in current UI; they are not old-build screenshots. All four new journeys pass
headless/rendered. Unit/content/physics, J03C10 and the three House contacts pass;
J11 and J11ART pass both modes; J11 rendered needed an isolated rerun of its timing budget.
Coordinator 329447e merged by 489c007; all three UI-33b ball shaders retained.

Merge re-verification checkpoint, 2026-11-23: required unit/content, J03C18,
J03C19, J11, J22L01 and J22L02 pass (journeys in both modes). Physics digest
75d1a3c0ceb2f8e458f7788de7e938de194633c1720aca1488b68a21eb310c6f unchanged;
BAL-1 J03 600/260/70 and J05 match 2 25920 pass both modes. JAVN5/JAVN5R,
JUIA6 and J22L02LIVEART pass both modes. UI-A6's art journey now presses Resume
after Throw Settings. AV-N4's rendered audio check needed a 100 ms interval
before a separate Sell action (QaRender accelerated it inside the wall-clock
debounce); production audio is unchanged. Final JAVN4/JAVN4R now pass both modes.
Results and original failures: artifacts/wave14/resume-20261123/. No fresh full
local matrix; full push CI remains the gate.

Comet correction, timed continuation 2026-11-23: original mesh-local shader
now has a broad oblique cyan sweep and gold star, preserving its palette and
reflectivity. J02 surface changes improve from 0.00/0.03 to 0.27/0.35 under
roll/spin. All ten balls pass; the coordinator's three UI-33b shaders are
unchanged. Eight targeted checks pass: unit/content, J02/JAVN4/JAVN4R both modes.
Fresh turn sheet and normal/reduced Comet captures reviewed. Owner review:
artifacts/e04/rendered/ball_turns.png (last row) and
artifacts/av-n4/{native,reduced}/rendered/n4_comet_trail.png.
Evidence: artifacts/wave14/timed-20261123/comet-checks/. Prior CI full art job
passed; game/motion failures remain unclassified pending accessible fresh CI.
No full local matrix was rerun. See AV-N4.md for exact limits and next steps.

Supplementary checks in this window: physics and J08 headless/rendered PASS.
Digest: 75d1a3c0ceb2f8e458f7788de7e938de194633c1720aca1488b68a21eb310c6f.
The first attempt stopped at editor import because the sandbox denied local
sockets; the unchanged checks passed with the required execution access.
Evidence: artifacts/wave14/timed-20261123/{motion-sandbox-attempt,motion-checks}/.
This brings the final targeted total to 11 passes. J08 passing locally does not
substitute for E12's separate movie-capture workflow. No new test thresholds,
scoring/input/audio behavior or protected gameplay files were changed.
