# UI-A7 — title motion and loader review

Status: DONE — implementation and automated verification (2026-11-16).
Branch: codex/roguewood-build. UI-10 at 81bac7d was already merged by 4ad1e00;
fresh fetch found no further coordinator changes. No PR/main push.

## Delivered

Stationary architecture; no parallax or shake. Existing stars twinkle in sparse
phase groups; four foliage regions gently bend from their bases with offset
phases. Lamp breathing stays faint, drifting dust is removed. A transparent
192×192 nearest-filtered viewport renders the original title ball illustration
on a sphere, turning once about Y every 18 seconds (owner correction below). The flat sprite spin is removed. Existing
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

## Owner correction — restore the original hero (2026-11-16)

The owner requested the prior larger ball, same design and reflective finish,
using their screenshot. Replaced the gameplay identity shader with a title-only
illustration-derived material sourcing the original unmodified a01-source.png.
Front pose restores the teal/gold veins, upper-right holes, lower diamond, broad
top highlight and cyan rim. The camera now fills 98% of the ball box (previously
77%); viewport resolution rises from 96 to 192 to retain the illustrated finish.
Removed redundant geometry holes and lighting nodes. Surface details turn about
Y; broad highlight/rim stay in view space. The unseen rear is reconstructed from
an unmarked enamel region of the same source, without duplicate holes or diamond.
The source does not supply an authored back view; this is a stylized reconstruction.
Prompt clearance adapts to the larger silhouette on shorter screens.

Final review captures: artifacts/ui-a7-revision/final-{portrait,landscape}/,
37-frame full turns plus pixel-identical reduced early/late captures and input
checks. Review reduced_early.png for the original reference pose and motion_009,
018 and 027 for the other quarters. Temporary exploratory captures in quarters/
and earlier revision folders are superseded by the final folders.
Final correction checks PASS: portrait and landscape full-turn/input reviews,
pixel-identical reduced captures, J01 headless/rendered, unit, content and qa.py
web (JW01: loader, actual throw, scoring and IndexedDB reload; no script errors).
JUIA1/JUIA2 headless/rendered and both 31-capture phone tours also passed during
this revision. The final reflection/spacing refinements were rechecked through
the final title reviews, J01 and web. Tour shutdown diagnostics remain the same
known ObjectDB/one-resource warning recorded above. Final logs: /tmp/a7r-final-*.log.
No claim of physical-phone performance. No input, rules, game-ball material,
loader, export preset or source bitmap changes.
