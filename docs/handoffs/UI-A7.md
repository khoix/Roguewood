# UI-A7 — title motion and loader review

Status: DONE — implementation and automated verification (2026-11-16).
Branch: codex/roguewood-build. UI-10 at 81bac7d was already merged by 4ad1e00;
fresh fetch found no further coordinator changes. No PR/main push.

## Delivered

Stationary architecture; no parallax or shake. Existing stars twinkle in sparse
phase groups; four foliage regions gently bend from their bases with offset
phases. Lamp breathing stays faint, drifting dust is removed. A transparent
96×96 nearest-filtered viewport renders the actual House bowling ball and holes,
turning once about Y every 18 seconds. The flat sprite spin is removed. Existing
entrance, tap beat, one-action start, named UI contracts and logo are retained.
Reduced motion is still; hidden title stops rendering its viewport. Bounded
nodes/materials are allocated at setup, with no per-frame resource allocation.

Loader sprite redesign was optional and was not needed: retain UI-10's pixel
ball/pin and IDs. No export_presets.cfg or author_loader.py changes.
Source/provenance plan and bounds: docs/art/ui/UI-A7.md, ASSET-LEDGER.md.

## Evidence

Native review portrait and landscape PASS, including all four input types,
fixed hall transform, no flat sprite rotation, unchanged title node count after
reopen/resize, and pixel-identical reduced captures. 37 motion samples span one
full Y-axis turn. Inspected portrait and landscape frame 004. Comparing landscape
004/010: foliage sample changes 160 pixels, sky sample 12, fixed beam sample 0.

Capture index (ignored, never committed):
- artifacts/ui-a7/{portrait,landscape}/motion_000.png through motion_036.png:
  full turn, twinkle and sway. Compare 004/010 for local hall motion.
- Same folders: reduced_early/late/rotated, tap_acknowledged/beat/fade and review.json.
- artifacts/ui-a7/tour-{portrait,landscape}/: real phone-shaped tours.
- artifacts/ui-a7/loader/{half,complete}.png: exported loader DOM at controlled
  progress (engine scripts omitted by review harness, not changed in product).
- artifacts/e26-w01/headless/: real exported web journey evidence.

Pinned Godot 4.5.2; Mesa software renderer; Xorg :96 with MIT-SHM disabled;
LP_NUM_THREADS=2; temporary XDG dirs and matching Playwright browser outside
source. These are desktop native/browser checks, not hardware phone performance.

## Resume

AV-N3 next (High), then AV-N4, AV-N5 and UI-A6. Read E17-D14/E18-C17 and AV-N1/N2;
list IDs/slots/provenance/captures before art. No remaining item is claimed DONE.

## Final checks and limitations

PASS: unit and content; J01, JUIA1 and JUIA2 headless and rendered; qa.py web (JW01),
including the loader, actual flick, scoring and IndexedDB resume; both phone
tours (31 captures each); portrait/landscape title reviews; controlled loader
capture checks at 50% and 100%.

The first web run lacked the matching browser; after installing it, a concurrent
render run timed out on a slow flick at about 5 FPS. An isolated rerun passed
without changing tests, gestures, timeouts or game values. This environment does
not establish phone frame-rate performance. The tours retain their previously
recorded ObjectDB/one-resource shutdown diagnostic after TOUR_OK and exit 0;
strict journeys passed. Dummy-display V-Sync warnings are nonfatal.

No screenshots committed. Loader and logo/icon/splash sources, export presets,
project settings, input/rules/simulation and catalogue files are untouched.
No new CI step; qa.py, workflow and run_tests were not edited for this item.
