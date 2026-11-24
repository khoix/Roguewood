# Wave 14 Codex checkpoint

Status: IN_PROGRESS — UI-A9-H remains. Branch: codex/roguewood-build (2026-11-24).

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
- UI-A9-H: IN_PROGRESS; twenty scene candidates, three sting candidates, original
  prop kit and native normal/reduced/boss review journeys. Live manifest was
  enabled by the coordinator at the owner's go-ahead (017ac8a). Scope, checks and exact resume: UI-A9-H.md.
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

Resume UI-A9-H at High effort from its 2026-11-24 11:23:51–11:38:51 UTC timed
checkpoint in UI-A9-H.md (15 minutes). Coordinator 1c6bc40 merged as 1cc7943.
The House set is LIVE by the owner's go-ahead, via coordinator 017ac8a; preserve
all manifest paths/IDs. Prior 1e30632 Bootstrap #582 game/art, E11 #178 and E12 #108
passed. Fresh push CI pending. Older activation-withheld instructions are history.

Visual staging review completed for all twenty. Delivery's opening ball now
clears its caption, with a native pixel regression and fresh captures. The latest
checkpoint records exact tests. Earlier full-render tables precede PERF-3 and this
small motion change; inspect new CI's bounded profile artifacts. The original
three stings are individually playable in the ignored review page; subjective
listening remains unverified. PCM/mixer checks are not an audition.

Next: inspect fresh CI and any explicitly pending checks, then complete sting
audition when listening is available. The active-Web observer hook request is in
UI-A9-H.md. Keep IN_PROGRESS until verification is complete; no extra owner
approval queue, manifest rollback, Wave 15 or AV-UI1.
Owner evidence: artifacts/ui-a9-h/review/index.html (440 visual crops and sting
players), live/rendered real rolls, boss/rendered actual wins, audio/rendered,
and profile-{portrait,landscape}/rendered/frame-times.json. No captures committed.

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

Final local E12 verification in the ten-minute window: PASS,
`ROGUEWOOD_E12_MATRIX_OK`. All four native modes pass their unchanged J08
assertions, with seven fresh captures each (28 total). Both encoded movies
pass ffprobe dimensions: portrait-full 720 × 1280 and landscape-reduced
1280 × 720. Temporary override.cfg was removed normally; project.godot and
export_presets.cfg remain unchanged. Python compilation and git diff checks
pass. Evidence: artifacts/wave14/resume-10min-20261123/ and artifacts/e12/.
The new push's CI is a separate gate; inspect it at the next resume. UI-A9-H
preproduction is recorded in its own handoff; no celebration art is complete.

UI-A9-H timed continuation (2026-11-23): coordinator 3dcd75a merged as 22aab8b.
e1cae49 Bootstrap #563 game/art, E11 #170 and E12 #104 confirmed successful.
Twenty original candidate scenes, three deterministic sound candidates and
normal/reduced/actual-boss review tools authored. Unit/content, normal/reduced/actual-boss
reviews headless/rendered, J03/J06/J11/J22L01/J22L02/JAVN1/JAVN2 headless and
physics passed. All twenty reduced tableaux compare identically across time.
Physics digest remains 75d1a3c0… . Full limitations and final run statuses are
in UI-A9-H.md. Live manifest absent; final audio, Web, performance and CI gate
remain. No DONE claim.

Final UI-A9-H check: actual boss review passes both modes (rendered 94 s).
Full-draw normal performance run timed out at 300 s, after all storyboards and
strike/spare checks; no final timing report, so performance remains incomplete.
See UI-A9-H.md for preserved failure log and exact continuation.

## Latest UI-A9-H checkpoint — 2026-11-24 04:34:27–04:49:27 UTC

Coordinator 77a591d merged as 624a439; owner-authorized live manifest retained.
e8223a6 Bootstrap #574 game/art, E11 #175 and E12 #107 all SUCCESS. Fresh CI
will be pending at this timed stop. Both isolated full-draw profiles passed
(179/153 s), with current per-variant table in docs/art/ui/UI-A9-H.md; software
whole-state timing is not physical-phone or isolated effect overhead evidence.

New JUIA9HV passed headless/rendered for real manifest strike/spare/open input,
active stings and independent scoring. Boss/audio journeys now use live manifest
without overrides; boss passed both modes. Live audio exposed an empty-name
PackedStringArray indexing error in one boss scene. Scoped RIVAL fallback and
all-boss empty-name draw regression added; final unit and normal/audio headless
and rendered checks pass. The earlier ten-check headless batch also passed.
No protected source edits or changed assertions/thresholds. Physics unchanged.

Review artifacts/ui-a9-h/review/index.html now includes byte-identical individual
sting players and audio-index.json alongside native contact/story captures.
Listening remains unverified, not an approval queue. Exact continuation and
complete evidence/check details are in UI-A9-H.md: inspect new CI, audition when
possible, finish affected validation; preserve live manifest and IN_PROGRESS.

Final isolated Web PASS (65 s) on the live-manifest merged tree, including
export/loader, mouse throw, IndexedDB reload and lost-context recovery with no
script errors (artifacts/qa/web_journey.log). This generic Web journey does not
claim exhaustive browser playback of all twenty House variants. Native live
strike/spare portrait captures inspected: legible CRT title, props inside frame.

Final isolated J11 rendered PASS (55 s), without changing timing assertions.
Implementation and testing stopped at 04:49:10 UTC, before the 04:49:27 deadline.
No test process remains running. Only checkpoint save, push and remote-SHA/clean
tree verification follow. Fresh Bootstrap game/art and E11/E12 remain pending;
subjective sting audition remains unrun. Resume at the Exact resume above.


## Latest continuation — 2026-11-24 11:23:51–11:38:51 UTC

Coordinator 1c6bc40 merged as 1cc7943 (PERF-3/UI-48). Previous checkpoint 1e30632:
Bootstrap #582 game/art, E11 #178 and E12 #108 all SUCCESS. Live House manifest
retained unchanged. Reviewed all twenty portrait story sequences and complete
landscape/reduced contacts. Fixed delivery's starting ball crossing its caption;
final pose/duration/sound unchanged. Native caption-region regression added.
Final JUIA9HM rendered PASS (127 s); native portrait/landscape opening crops show
the whole subtitle clear. Final unit/content/JUIA9H/JUIA9HR/J06 headless PASS.

See UI-A9-H.md latest checkpoint for subsequent rendered checks and evidence.
Visual staging review is complete; actual sting audition remains unperformed
because listening is unavailable. This is no additional owner-approval queue.
The new CI gate is pending; previous timing tables precede PERF-3/this motion
adjustment, so inspect this push's JUIA9HP/JUIA9HL reports before using numbers.
The existing browser observer lacks alley state; a read-only status hook for
active Web celebration coverage is routed to coordinator in UI-A9-H.md.

Final-revision JUIA9H/JUIA9HR rendered PASS (54/45 s); reduced CRT still
comparisons and the caption regression pass. Merged-tree J22L01/J22L02 and
JAVN1/JAVN2 rendered PASS (81/71/32/32 s). Review index regenerated from all
440 native crops after both modes. The slice-review no-art assertion is unchanged;
its label now explicitly names the slice fixture to avoid confusing it with the
live House manifest. Last source edit after these checks changes comments/assertion wording only.

Final isolated Web PASS (64 s) on the merged tree and caption revision;
export/loader, real mouse throw, IndexedDB reload and context-loss recovery.
No script errors. Evidence: artifacts/qa/web_journey.log and artifacts/e26-w01/.
This remains generic platform coverage with the active-celebration boundary above.

Final isolated J11 rendered PASS (53 s), unchanged timing assertions. No
other engine ran during Web/J11. Final review artifacts regenerated successfully.
All scoped correctness checks passed; one final portrait full-draw profile was
started in isolation before stopping. Its explicit outcome follows below.
Landscape remeasurement is deferred to fresh CI; older numbers are not relabelled.

Runtime this window: pinned Godot4.5.2, live isolated Xorg :93, LP_NUM_THREADS=1,
/tmp/roguewood-xdg/{cache,data,config}, Web Playwright browser cache as before.

Final isolated JUIA9HP --draw all PASS (171 s): complete=true, draw_all=true,
no failures, twenty scene buckets and the ordinary-roll comparison. Portrait
roll n=1372, p50/p95/p99=21.591/27.279/35.853 ms;
scene p95 range 36.388–45.094 ms; delivery
n=97, p95=36.650 ms. Godot4.5.2/X11/llvmpipe, LP_NUM_THREADS=1,
one engine running. Whole-state software wall-frame comparison, not isolated
art overhead or a phone/60fps claim. Final report preserved separately at
artifacts/ui-a9-h/resume-1123/final-portrait-frame-times.json; prior portrait saved
as prior-portrait-frame-times.json. Landscape is NOT remeasured here; inspect
fresh CI for a matched final-revision pair. No mixed-revision performance table.

Implementation/testing stopped at 11:37:39 UTC within the 11:38:51 deadline.
Only checkpoint save/push/remote verification and the requested future scheduling
follow. UI-A9-H remains IN_PROGRESS: actual sting audition and fresh full CI
remain outstanding; active-Web observation hook is routed to the coordinator.
Next resume: inspect this push CI and both profile reports, retain live manifest,
audition the three stings if listening is possible, then resolve genuine remaining
validation gaps. Do not restart completed visual polish or start Wave 15.
