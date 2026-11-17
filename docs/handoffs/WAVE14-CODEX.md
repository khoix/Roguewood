# Wave 14 Codex checkpoint

Status: IN_PROGRESS. Branch: codex/roguewood-build (2026-11-17).

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
- UI-A6: not started. No DONE handoff to skip.
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

## Exact resume step

AV-N5 is complete; see AV-N5.md for verification and fixture limits. Coordinator
8bafa27 (UI-13) was merged by 0cbd9a4 before authoring. Stop at this completed
checkpoint. Next UI-A6 (Medium): fetch/merge the latest coordinator
with a merge commit, read updated claims and docs/prompts/codex-wave14-ui-a6.md,
then implement the manifest pin-deck hook and House finish. Check Divisions 1–8
and the Championship, preserving Neon's finish.

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
