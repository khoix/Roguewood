# UI-A5 — title and icon art-lead review

State: DONE (implementation and local verification).
Owner-directed Wave 13 extension, High effort. Branch codex/roguewood-build.
Coordinator da92784 (47db070 or later, UI-8/close records/claim included) merged
with merge commit 4a2b542. Prior Wave 13 deliveries are preserved.

## Changed and retained

Title composition now keeps more of the hall around the ball, blends fully into
night without exposing the moving image edge, and brings the portrait prompt
closer to the ball. The prompt stays readable at 80–100% opacity. The original
logo, House Ball, backdrop, palette, one-action structure and 0.3 s exit remain.

Motion: a subtle 0.7 s logo/ball settling entrance; much slower ball rotation;
bounded hall parallax; two faint breathing lamp pools and twelve slow dust pixels;
one small tap response inside the existing fade budget. No blocking introduction.
`open(true)` resets every transform and stops processing, freezes atmosphere and
skips the exit. Reopen cancels a pending fade. No particles, full-screen shaders,
blur, new audio or dynamic lights. See docs/art/ui/UI-A5.md for exact bounds.

Retained UI-A4's logo/icon/splash bitmaps and exporter. The splash remains 720×560
on #0b1116; all fixed asset paths, named controls, signal/open contract and input
methods remain. No project, export, content or test files are directly changed.
Only title_screen.gd and assigned art/handoff paths are edited after the merge.

At 16 px the three ivory holes and gold diagonal still distinguish the ball;
at 32 and 180 px the silhouette and timber field remain clear. The dark border
works against both browser themes. The simulated iPhone rounded mask trims only
the outer field, preserving the ball. No icon redraw would improve this identity
enough to justify changing it. The quiet wordmark-only loading page remains a
clear bridge into the richer title; its background matches the boot splash.

## Verification and limitations

Final unit, J01 headless/rendered, JUIA1 headless/rendered, JUIA2
headless/rendered and qa.py web PASS. Both phone tours completed 31 captures
and exited 0. Both emitted the capture tool's ObjectDB/one-resource shutdown
diagnostic after ROGUEWOOD_TOUR_OK; that diagnostic was also recorded in UI-A4's
landscape tour. This is an explicit remaining capture-tool limitation, not a
claim of clean shutdown. No strict journey failure occurred.

Native standalone art-review runs in both orientations PASS: actual shell
entrance, first tap during entrance, one start emission per action, all four
touch/mouse/key/pad inputs, reopen/resize and pixel-identical reduced views.
Actual Chromium light/dark tab and icon study captures PASS. Review-page UTF-8
and height were corrected and its captures regenerated after final inspection.
Evidence: artifacts/ui-a5/checks/{results,platform-results}.json,
icons-final.log, title-{portrait,landscape}/review.json and icons/review.json.
Brand PNG SHA256 values remain identical to the UI-A4 ledger. No runtime changes
followed the passing final unit/journey matrix. Physics/content regression
results in WAVE13-CODEX.md refer to the prior art delivery, not a new UI-A5 run.

Icon review includes real light/dark Chromium browser tabs. iPhone home-screen
review is a labelled size/mask simulation: no physical iPhone is attached.
No physical-device performance, installed home-screen or mobile Safari trial is
claimed. Pinned Godot 4.5.2, Linux Compatibility/llvmpipe, Dummy audio,
Playwright 1.63.0 Chromium, Xorg :100 without MIT-SHM, LP_NUM_THREADS=2.

## Owner capture index

Local ignored outputs, never committed:

- artifacts/ui-a5/tour-portrait/01_title.png and tour-landscape/01_title.png:
  real phone-tour title at 360×780 and 780×360.
- artifacts/ui-a5/title-{portrait,landscape}/motion.mp4: five-second motion
  sequence, encoded from motion_000.png through motion_059.png at 12 fps.
- Same directories: tap_acknowledged.png, tap_beat.png, tap_fade.png;
  reduced_early.png / reduced_late.png (identical pixels), reduced_rotated.png.
- artifacts/e03/rendered/title.png and
  artifacts/e26-w01/headless/{web_loading,web_title}.png.
- artifacts/ui-a5/icons/browser_{light,dark}.png and tabs_{light,dark}.png:
  actual headed Chromium window and tab strip with the exported favicon.
- sizes_{light,dark}.png: actual exported 180, 32 and 16 px icon views.
- iphone_simulated_{light,dark}.png: labelled 60pt / 3× density home-screen
  icon studies using the exported apple-touch-icon, not physical-device captures.

## Coordinator

Delivery SHA is the commit containing this completed record, reported after push
and remote/clean-tree verification. Merge codex/roguewood-build into the
coordinator branch and update central Wave 13 claims. No missing hook request.
The coordinator owns central state and integration to main. Stop after UI-A5;
no Wave 14 item art here. Optional follow-up: investigate the tour shutdown
diagnostic in the coordinator-owned capture tool. Next art batch AV-N3: High
effort, under its separate Wave 14 claim.
