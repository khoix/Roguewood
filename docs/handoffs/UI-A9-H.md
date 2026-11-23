# UI-A9-H — House celebrations checkpoint

Status: IN_PROGRESS (twenty authored candidates; live activation withheld).
Date: 2026-11-23. Effort: High. Branch: codex/roguewood-build.
Timebox: 13:12:11–13:32:11 UTC; checkpoint/save only after the deadline.

## Implemented this window

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

1. Fetch, inspect this push's full Bootstrap/E11/E12 CI, and safely merge any
   coordinator update. Classify actual failing assertions before fixes.
2. Review the normal/reduced contact sheets and complete motion sequences;
   refine small prop readability and choreography before treating candidates
   as final. Keep existing stable IDs and source provenance.
3. Audition the three stings and check AlleyScreen playback at effects volume
   and mute. Scenes remain silent. No audio-live claim has been made.
4. Finish per-variant full-render frame-time comparison against ordinary rolls;
   inspect renderer/draw mode/sample counts and repeat in isolation if needed.
   Complete rendered affected gameplay/UI-20 checks and Web validation.
5. Only when the whole set is finished, enable twenty paths and three sound
   paths in the House theme manifest alone, then its completeness flag. Rerun
   unit/content, native review modes, real trigger checks and affected journeys.
   Push; full CI is the gate. Until then UI-A9-H remains IN_PROGRESS.

Changed scope: assets/ui/alley_screen/{house/,crt.gdshader}; four new celebration
 test/journey scripts; tools/author_house_celebration_stings.py; add-only
 tools/qa.py, tests/run_tests.gd, .github/workflows/bootstrap.yml; asset ledger,
 art plan, this handoff and WAVE14-CODEX.md. Protected gameplay files unchanged.

## Final timed checkpoint

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
