# UI-A9-H — House celebrations checkpoint

Status: IN_PROGRESS (House set LIVE by owner/coordinator; sting audition remains unverified).
Date: 2026-11-24. Effort: High. Branch: codex/roguewood-build.
Latest timebox: 2026-11-24 11:23:51–11:38:51 UTC (15 minutes).
Earlier 13:12:11–13:32:11 session is retained below as history.

## Earlier session implementation

- Fresh checkout of e1cae49; fetched origin and merged coordinator 3dcd75a
  with merge commit 22aab8b. No conflicts; both sides of documentation retained.
- Confirmed e1cae49 Bootstrap #563 (45170994557): game job 137680173020 and
  art job 137680173338 SUCCESS. E12 #104 (45170994021) and E11 #170
  (45170994034) SUCCESS. No scoped CI repair required.
- Original display-sized pixel prop kit and all twenty planned scene resources
  in assets/ui/alley_screen/house/. Each has its own gag and final reduced still.
  Names come from context; champion uses its own RivalArt atlas identity.
- Three deterministic sting candidates with reproducible generator, hashes and
  provenance in ASSET-LEDGER.md. Audio has not been auditioned or enabled.
- CRT temporal brightness wobble removed in all modes; existing power/flicker
  interface retained. Other CRT settings remain the baseline, pending final review.
- JUIA9H/JUIA9HR: real game + AlleyScreen test override, all twenty scenes at
  10/45/90 percent in 450×800 portrait and 800×450 landscape; correct portraits;
  reduced early/late exact pixel equality; normal early/late differences;
  durations, natural completion, replay/skip and hidden viewport shutdown.
  Also real strike/spare/open-frame input and independent J03 scoring assertions.
- JUIA9HB: actual eight-Division House boss wins using the candidate lists;
  checks per-rival selection, once-per-win trigger and Division Result gating.
- Unit coverage for every scene's duration, exactly-once finish, replay and
  input ownership; sting resource loading and duration bounds.
- Add-only QA registrations, unit registration and art-only CI step/captures.
  No live House manifest entries or completeness flag. No Wave 15 work.

## Checks and evidence

PASS: unit, content; JUIA9H and JUIA9HR headless/rendered for all twenty scenes;
JUIA9HB headless/rendered; J03, J06, J11, J22L01, J22L02, JAVN1, JAVN2 headless;
physics digest 75d1a3c0ceb2f8e458f7788de7e938de194633c1720aca1488b68a21eb310c6f.
Python compilation and git diff whitespace check passed.

Initial review assertions incorrectly set Reduced Flash only in event context;
corrected to use the actual settings UI, then both modes passed. The initial
batch rendered launcher could not run because xvfb-run is absent; direct
rendered QA commands on isolated Xorg :90 passed. No production behavior was
changed to accommodate either environment/test issue.

Owner review (ignored captures, not committed):
- artifacts/ui-a9-h/normal/contact.png and reduced/contact.png (twenty each).
- artifacts/ui-a9-h/{normal,reduced}/rendered/: <scene>_{portrait,landscape}_{10,45,90}.png;
  120 storyboard captures plus five real-play captures per mode.
- artifacts/ui-a9-h/boss/{headless,rendered}/: actual boss journey evidence.
- Frame-time JSON is emitted by the review tool; check draw_all before using
  it as performance evidence. Capture-only/default QA rendering is NOT a
  rendering benchmark. Full-draw run status is recorded below at checkpoint.

Visual inspection: event words remain readable at the requested sizes; champion
name is split at its comma into two lines. The spare poses and some small boss
props still merit deliberate polish/animation review. These are candidates,
not a claim of final premium-art acceptance. Physical-phone testing not run.

## Environment

Pinned Godot 4.5.2: /tmp/roguewood-tools/Godot_v4.5.2-stable_linux.x86_64.
Set GODOT_BIN explicitly (system default is 4.7.2). XDG directories:
/tmp/roguewood-xdg/{cache,data,config}; isolated Xorg :90, MIT-SHM disabled,
LP_NUM_THREADS=1. CLI network and Godot/local displays required execution
outside the default sandbox; no repository settings changed.

## Exact resume

1. Fetch and inspect this push's Bootstrap game/art and E11/E12; merge coordinator
   updates safely. The House set is already LIVE, enabled by the coordinator in
   017ac8a at the owner's go-ahead. Preserve manifest paths/IDs and completeness.
   The old activation-withheld instructions below are historical and superseded.
2. Read the latest timed checkpoint below and its current-revision timing/check
   outcomes. Reuse completed evidence rather than restart authoring or profiling.
3. Audition the three original stings via artifacts/ui-a9-h/review/index.html
   (separate players) or audio/stings-review.wav (combined). Listening capability
   was unavailable here; PCM and production mixer verification are not listening.
   This is an unperformed review, not an owner-approval queue or reason to disable
   the owner's live manifest. Record the actual result when audition is possible.
4. The latest timed visual review is complete, including the delivery caption fix.
   Complete explicitly pending CI results below. Review any further changes at
   450×800 and 800×450. Keep both accessibility
   modes, all twenty stable variants and silent scene ownership. No Wave 15/AV-UI1.
   Mark DONE only when implementation, captures and affected checks are complete.

Changed scope: assets/ui/alley_screen/{house/,crt.gdshader}; four new celebration
 test/journey scripts; tools/author_house_celebration_stings.py; add-only
 tools/qa.py, tests/run_tests.gd, .github/workflows/bootstrap.yml; asset ledger,
 art plan, this handoff and WAVE14-CODEX.md. Protected gameplay files unchanged.

## Earlier timed checkpoint (superseded by latest checkpoint)

JUIA9HB rendered PASS (94 s), completing its headless/rendered coverage.
The normal `--draw all` benchmark timed out at its unchanged 300-second limit,
after all twenty variants in both orientations and the real strike/spare frames,
during the open-frame roll. No assertion failure was reported. The full-draw
performance check is NOT passed and emitted no final frame-times.json.
Preserved log: artifacts/ui-a9-h/normal/full-draw-timeout.log. It also overwrote
normal/rendered/journey.log from the earlier passing capture-only run.
Reduced/rendered/frame-times.json is capture-only evidence; do not use its
percentiles as full-render performance. On resume, make the benchmark emit
partial timing reports incrementally and run it in isolation in bounded parts
or with an explicitly appropriate benchmark budget. Do not relax correctness
assertions or claim a phone performance result.

All implementation/testing stops at the 13:32:11 UTC deadline. Only checkpoint
commit/push and remote-SHA/clean-tree verification follow. Fresh push CI remains
pending; no wait for it in this window. UI-A9-H remains IN_PROGRESS.


## Previous timed checkpoint — 2026-11-23, 18:23:29–18:43:29 UTC

Synchronized coordinator a1f704d with merge commit aaaabd1. Confirmed prior
cec80a1 Bootstrap #565 (45184936750), E11 #172 (45184936441) and E12 #105
(45184936569) all successful. No prior-push CI repair was needed.

Completed this window:
- Incremental frame-time JSON now survives interruption. JUIA9HP/JUIA9HL split
  the full-render measurement by orientation without weakening gameplay checks.
  Both passed in isolation (177 s portrait, 158 s landscape), all twenty scenes
  plus ordinary rolls, complete reports and 97–181 scene samples each.
- Portrait baseline p95 26.294 ms; scene p95 35.675–69.484 ms. Landscape baseline
  p95 28.788 ms; scene p95 28.802–67.716 ms. Software llvmpipe desktop, whole-state
  timing, reduced-motion assisted baseline: NOT an isolated art-cost measurement
  or physical-phone/60fps claim. Timing preceded the final path-backed portrait
  change; its pixels/regions are unchanged. Full method/table in the art standard.
- JUIA9HA exercises actual AlleyScreen/theme/effects mixer: all three correct
  stings, half-volume gain, Mute/zero-volume suppression, picture/music retained.
  Headless and rendered pass. PCM checks pass; listening is still outstanding.
- PERF-2-compatible texture property and five generated path-backed AtlasTexture
  views restore Normal correctly after Low frees the original view, including
  held reduced stills. Exact source/region/filter identity checked. No PNG edits.
  Coordinator follow-up: unnamed runtime AtlasTexture originals have no reload
  path after their WeakRef expires; this art uses path-backed views locally.
  No edits to Graphics or RivalArt were made.
- Added art-only CI steps for audio and isolated full-draw profiles; provenance
  and the later-League standard updated. Live manifest remains absent.

Validation: final unit/content, JUIA9H/JUIA9HR headless, JUIA9HA headless/rendered,
JUIA9HR, J06 and J11 rendered pass. Earlier in this window JUIA9HB, J06, J11, J22L01,
JAVN1/JAVN2 headless pass. Prior full boss rendered evidence remains available.
JW01 Web passes in isolation with no script errors, save/reload/context recovery.
The concurrent Web attempt failed the coordinator-owned loader assertion
“at 100% the pin falls only once the ball reaches it” (pinDown true); isolated
retry passed (pinDown false). No loader edits or assertion relaxations. Retain
this as a contention-sensitive test observation for the coordinator.
Physics code untouched; prior digest 75d1a3c0… remains the recorded reference,
not a newly executed physics result. Fresh push full CI is pending; do not wait
past the time limit. Remaining rendered checks/final art and sound judgment
prevent DONE/live activation.

Owner evidence (ignored, never committed):
- Existing normal/reduced contact.png and rendered storyboard sequences; boss
  wins in artifacts/ui-a9-h/boss/rendered/.
- artifacts/ui-a9-h/profile-{portrait,landscape}/rendered/frame-times.json;
  artifacts/ui-a9-h/performance-summary.{json,md}.
- artifacts/ui-a9-h/audio/stings-review.wav, pcm-report.json and rendered/
  audio_{strike,spare,boss_defeated}.png.
- artifacts/qa/web_journey.log (passing isolated run); concurrent failure copy:
  artifacts/ui-a9-h/resume-20261123/web-concurrent-failure.log.

Modified scope this window: celebration.gd; five portraits/*.tres; new portrait
metadata generator; main celebration art journey; audio/profile journey scripts
and UIDs; add-only tools/qa.py and bootstrap.yml; asset ledger, art standard and
both handoffs. No protected gameplay edits; no captures committed. Pinned Godot
4.5.2 and Xorg :90 as above; Web requires PLAYWRIGHT_BROWSERS_PATH=/home/agent/.cache/ms-playwright.

Implementation/testing ended before the 18:43:29 UTC deadline. Final rendered
J06 (55 s) and J11 (61 s) passed. Only checkpoint save/push and remote-SHA/clean-tree
verification follow; full CI on this push remains pending. Exact resume is above.


## Previous timed checkpoint — 2026-11-23, 23:28:44–23:48:44 UTC

Merged coordinator c74aace as c895c5d (UI-40–46/PERF-2b updates); no conflicts.
Confirmed 744be2a Bootstrap #569 (45241313372): game job 137926401699 and art job
137926402504 successful; E11 #174 (45241313448), E12 #106 (45241313503) successful.
No prior-push CI repair required. Coordinator-owned source changes arrived only
through the merge, including src/rules/content_set.gd; no worker edits there.

Art changes: grounded bookend pin and scorebooks, visible delivered pin/arc,
constellation pins shrinking inside the top border, clearer boss text/prop spacing,
smaller broom props, raised Encore audience, and Proprietor keys settling
below the name. All stable IDs, twenty scenes, durations, original portrait pixels,
stings and CRT parameters are retained. Source hashes/provenance in ASSET-LEDGER.
No live manifest entries; no Wave 15 or AV-UI1 work.

Review tooling: JUIA9HM adds eight beats per scene/orientation under default flash
settings. JUIA9H retains normal/reduced-flash coverage; JUIA9HR both accessibility
settings. The capture helper saves full phone frames and native CRT crops from
one readback, converting logical coordinates via the viewport final transform.
An initial logical-coordinate crop error was fixed; superseded captures are not
final evidence. tools/review_house_celebrations.py builds the ignored HTML index,
80 storyboard sheets, four contact sheets, and a 440-crop index, including reduced
CRT equality checks. Timed held frames are not live video/performance evidence.

Validated after merge: unit/content, J03, JUIA9H/JUIA9HR/JUIA9HA headless; J03,
J06, J22L01, JAVN1/JAVN2 rendered; JUIA9HA and actual House boss JUIA9HB rendered.
Final scoped unit/content and JUIA9HM/JUIA9HR headless passed before the last keys
coordinate adjustment; normal motion/reduced rendered also passed. Latest capture
refresh/check outcomes are recorded below before stopping. Physics freshly PASS:
75d1a3c0ceb2f8e458f7788de7e938de194633c1720aca1488b68a21eb310c6f (123 simulations).

One concurrent J11 rendered failure: “PERF-1b: the texture sweep costs 0.054 ms a
frame (worst 185.4 ms)”. Saved artifacts/ui-a9-h/resume-2330/j11-concurrent-failure.log.
No platform/test threshold changes. Isolated retry outcome follows below. Initial
rendered launches failed because the previous X server had exited; restored :91,
then reran them. Two capture runs were deliberately stopped after later art fixes
superseded their source. They are not claimed passing.

Evidence: artifacts/ui-a9-h/review/index.html, capture-index.json,
{motion,reduced}_{portrait,landscape}_contact.png and <variant>_<orientation>_<mode>.png;
raw full phone/crop frames in motion/rendered and reduced/rendered; actual boss
captures in boss/rendered; source audition clip in audio/stings-review.wav.
All artifacts ignored, never committed. Godot 4.5.2 and temporary XDG paths as
above, isolated Xorg :91. Fresh push full CI is pending; no waiting past deadline.
Modified worker files: House celebration.gd/prop_kit.gd; main/motion art journeys
and new UID; new review-sheet tool; add-only qa.py/bootstrap.yml; ledger, art
standard, this handoff and WAVE14-CODEX.md. No protected worker source edits.

Isolated J11 rendered retry PASS (53 s), with its performance assertion unchanged.
The concurrent failure is retained as a load-sensitive observation, not a claimed
platform fix. Review-index generation passed: 440 native crops, 80 storyboard
sheets, four contact sheets; all reduced CRT crops byte-identical across beats.

Web JW01 PASS in isolation on the final art revision (62 s): export, loader,
actual mouse throw, save/reload continuation and lost-context recovery; no script
errors. As the live manifest is still off, this is export/platform coverage, not
a claim of live House celebration playback in Web.

Visual judgment: twenty portrait motion storyboards and both orientation contact
sheets reviewed at native crop scale; all five strike and spare gags and each
rival's two endings remain distinct, main event words/rival names readable. The
small captions/props are secondary; original warm palette and restrained static
CRT retained. Constellation and key early-frame corrections came from this review.
No physical-phone trial or real-time video judgment is claimed.

Final unit/content and JUIA9HM/JUIA9HR headless PASS after the last keys adjustment
(4/4). Early/middle/final key frames inspected: the ring remains below the rival
name and settles on the cushion; reduced end pose is unchanged by this adjustment.
Pending work is audition, current-revision full-draw timing review, activation and
post-activation verification. The native evidence has not been called phone
hardware testing. No full CI wait in this timebox.

Final rendered JUIA9H PASS (106 s) and JUIA9HM PASS (129 s) after the keys fix.
JUIA9HR rendered PASS (103 s) on the same final stills; the later keys change only
affects motion before t=1. Final review index regenerated successfully from all
440 crops. No implementation/test process remains running. Implementation and
testing stopped before 23:48:44 UTC; only checkpoint save/push/SHA verification
follow. Fresh push Bootstrap/E11/E12 are pending. UI-A9-H remains IN_PROGRESS.


## Previous timed checkpoint — 2026-11-24, 04:34:27–04:49:27 UTC

Merged coordinator 77a591d as 624a439. Includes owner-authorized live House
manifest (017ac8a), UI-47 touch/Charm quick view and PERF-2c. All twenty paths,
three stings and celebrations_complete were already enabled; retained unchanged.
This supersedes older “keep absent/activate next” text, not the recorded fact that
subjective sting audition remains unavailable. No new art source/pixel changes.

Confirmed e8223a6 Bootstrap #574 (45291780349): game job 138102070633 and art job
138102070773 SUCCESS; E11 #175 (45291780390), E12 #107 (45291780393) SUCCESS.
The art artifact download returned HTTP 403; no CI failure was inferred from that.
Bounded full-draw profiles were therefore run locally, one renderer at a time.
Results are appended below. Pinned Godot 4.5.2, Xorg :92, LP_NUM_THREADS=1 and
previous temporary XDG directories; prior X server was no longer running.

Live verification work:
- JUIA9HV drives actual House strike/spare/open-frame input through the shipping
  manifest, with no variant override; verifies correct event selection and active
  sting voice, accessibility context, native tap-skip/natural end, and inherited
  independent J03 scoring assertions.
- JUIA9HB now uses the real boss manifest without an override and checks both
  declared endings for each rival. Coordinator's boss-only counting and queued
  strike/boss ordering checks are preserved.
- JUIA9HA reads the actual sound slots and random scene selection instead of
  inserting test sound entries/variants. Its gain, Mute/zero-volume suppression,
  music retention and Low/Normal texture-restoration checks remain intact.
- Art-only CI step added for live trigger journey; existing steps unchanged.
- Review-page generator copies the three original WAVs byte-for-byte into ignored
  review/audio, supplies separate players, and records hashes/durations in
  review/audio-index.json. No listening claim, source resynthesis or manifest edit.

Modified worker scope: celebration.gd empty-name guard, normal/audio/boss
journeys, new live journey/UID, add-only qa.py/bootstrap.yml, review-page tool,
asset ledger, art standard and two handoffs. No protected
source edits or screenshots committed. Timer governs this session; full push CI
may remain pending. Exact final checks and evidence follow below.

Full-draw JUIA9HP/JUIA9HL PASS (179/153 s), complete reports for all twenty
variants plus ordinary rolls; all assertions retained. Current summary and
per-variant table: docs/art/ui/UI-A9-H.md and ignored
artifacts/ui-a9-h/performance-20261124.{json,md}. Both ran alone; numbers remain
software-renderer wall times in the slice fixture, not phone/effect-only costs.

Live JUIA9HV PASS headless/rendered (23/36 s), including active sting voices on
actual rolls, native tap skip, spare natural completion and unchanged independent
scoring. Live JUIA9HB PASS headless/rendered (44/87 s) without boss overrides.
The first live JUIA9HA rendered run exposed SCRIPT ERROR: Out of bounds get index
0 (PackedStringArray), celebration.gd:_boss_story, from an empty rival_name on a
muted direct event. Fixed the scoped art fallback to RIVAL and added deterministic
render coverage of empty names on all ten boss scenes. Supplied names/geometry
are unchanged. Results after that fix follow below. Full-draw timing above was
measured before this defensive guard, with valid named contexts throughout; no
claim of a new performance run after the guard. CI reruns both profiles on push.

Final checks after the fallback: unit PASS (42 s), JUIA9H headless PASS (27 s)
and rendered PASS (53 s), JUIA9HA headless PASS (9 s) and rendered PASS
(no script errors). All ten earlier batch checks passed: unit/content,
JUIA9HV/JUIA9HA/JUIA9HB, J03/J06/J22L01/JAVN1/JAVN2 headless. Actual-boss
rendered PASS and live strike/spare rendered PASS are recorded above. Python
compilation and git diff --check pass. No correctness/timing thresholds relaxed.

Owner evidence: artifacts/ui-a9-h/review/index.html has 440 indexed native crops,
80 story sheets, four contacts, and three separate sting players. Audio copies
are byte-identical to original sources; review/audio-index.json records hashes
and durations (strike 0.85 s, spare 0.65 s, boss 1.25 s). Additional current
captures/logs: live/rendered/, audio/rendered/, boss/rendered/, normal/rendered/
under artifacts/ui-a9-h/. Prior motion/reduced evidence remains available.
Subjective audition is still unrun; no audio perception or physical-phone test
is claimed. Existing physics reference remains 75d1a3c0…; no new physics run in
this window, no physics source changes. UI-A9-H remains IN_PROGRESS.

Exact next resume: inspect this checkpoint's Bootstrap game/art and E11/E12,
including fresh profile artifacts; preserve coordinator-authorized live manifest.
Audition the three individual review players or audio/stings-review.wav when an
audio listening capability is available; record an actual listening judgment.
Review the native contact/story evidence and rerun affected checks after any
further art/sound changes. Finish remaining affected rendered/UI-20 validation
and the full push CI gate before DONE. Do not restart preproduction or Wave 15.

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


## Latest timed checkpoint — 2026-11-24, 11:23:51–11:38:51 UTC

Merged coordinator 1c6bc40 as 1cc7943 (PERF-3 shared per-roll resources/logging,
UI-48 Late Rally wording). House manifest remains live and unchanged. Follow-up
PERF-3 note about d04 overlay shader reuse is recorded by coordinator; this session
does not touch that unrelated file or begin Wave 15.

Previous checkpoint 1e30632 full CI confirmed successful: Bootstrap #582,
run 45329032660, art job 138225433140 and game job 138225433298; E11 #178,
run 45329032678; E12 #108, run 45329032633. No failing assertion to repair.

Reviewed every variant's eight-beat portrait story sheet and the complete normal
landscape/reduced portrait contact sheets. Distinct gags, correct rival identity,
champion's two-line name, quiet scanlines and separate final stills remain legible.
One concrete polish defect: delivery's opening ball crossed its small caption.
Moved only the cart's starting x (141→168), retaining final x=179 and the delivery
arc/ending, event duration, sound and reduced still. Added a native pixel-region
assertion that the delivery caption remains identical across the held beats.
This is staging/readability review, not live video or physical-phone evidence.

Own modified files: assets/ui/alley_screen/house/celebration.gd,
tests/house_celebration_art_journey.gd, docs/art/ASSET-LEDGER.md,
docs/art/ui/UI-A9-H.md and both handoffs. No manifest, protected gameplay,
project settings, source audio or screenshots changed. Final checks follow below.

Prior full-draw timing tables describe the earlier source revision and precede
PERF-3; do not call them a remeasurement of this tiny motion adjustment. The new
push's art CI reruns JUIA9HP/JUIA9HL; inspect those complete reports next. Sting
listening remains technically unavailable/unperformed, not an approval queue.
The sound files, PCM/mixer evidence and separate review players are unchanged.


Final-revision checks so far: unit/content and JUIA9H/JUIA9HR/J06 headless PASS
(5/5). JUIA9HM rendered PASS (127 s), including unobscured caption assertions in
both orientations. New opening CRT crops inspected at native size: the whole
SPECIAL DELIVERY line is clear, ball/cart remain separate, pin readable.
The earlier merged-tree batch also passed all seven checks (unit/content,
JUIA9H/JUIA9HR/JUIA9HA/JUIA9HV/J22L02); source chronology is retained rather
than calling the earlier unit run verification of the later caption edit.

Visual review conclusion: the polished set's twenty distinct scenes and final
CRT pass this desktop phone-size staging review. Spare gags retain their own
silhouettes; boss props preserve portrait/name hierarchy and distinct endings.
The final delivery pose is unchanged; all reduced stills remain distinct and
static. No unresolved visual defect identified in the held-beat evidence. This
does not stand in for actual audio listening, live-video or target-device review.

Technical coverage boundary for coordinator: current Web QA status in
src/platform/web_qa.gd exposes lab state/history but no alley event/path/playing
state. Generic JW01 remains export/platform coverage, not exhaustive active
House animation playback in Web. If adding an automated browser celebration
assertion, a read-only QA status hook for those fields and screen bounds belongs
to the coordinator; no such hook was added or production state driven here.

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
