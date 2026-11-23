# UI-A9-H — House celebrations checkpoint

Status: IN_PROGRESS (twenty authored candidates; live activation withheld).
Date: 2026-11-23. Effort: High. Branch: codex/roguewood-build.
Latest timebox: 18:23:29–18:43:29 UTC; checkpoint/save only after the deadline.
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

1. Fetch, inspect the latest push's Bootstrap game/art and E11/E12, and merge
   new coordinator commits safely. Classify actual assertions before fixes.
2. Review/polish the full normal/reduced contact sheets and motion sequences at
   450×800 and 800×450; small props and choreography still need final judgment.
   All twenty candidates exist: do not restart preproduction.
3. Audition artifacts/ui-a9-h/audio/stings-review.wav (strike, spare, boss).
   The interface could not listen; technical PCM checks and production mixer
   volume/mute checks passed, but subjective sound review remains outstanding.
4. Complete affected rendered/UI-20 regressions (including J22L01, JAVN1/JAVN2),
   then review the timing evidence and performance limits in docs/art/ui/UI-A9-H.md.
   Both bounded full-draw profiles now pass; no need to repeat the old timeout.
   Web passed in isolation. Repeat required checks after subsequent art changes.
5. Only once the whole set is finished, enable twenty paths and three sound
   paths in the House manifest alone, then its completeness flag. Re-run native
   review modes, real triggers and affected checks. Full push CI is the gate;
   UI-A9-H remains IN_PROGRESS until implementation, evidence and checks finish.

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


## Latest timed checkpoint — 2026-11-23, 18:23:29–18:43:29 UTC

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
