# Wave 13 — Codex completion index

State: DONE for all current Codex Wave 13 claims: AV-N1, AV-N2, E22-L02-ART
(theme tail), UI-A4 and the owner's UI-A5 extension. Stop here; no AV-N3 or
Salvage art was started.

Branch: codex/roguewood-build. AV-N1's initial checkpoint is bd084d4. Coordinator
UI-6 333c0af was merged at 7dcb506; later DC-N3/UI-7/UI-A4 claim 254a921 was merged
with merge commit 81cda95. No rebase, force-push, main push or PR. The delivery
SHA is the commit containing this completed index (reported with the final push).
The coordinator owns central state and the sole integration path to main.
UI-A5 subsequently merged coordinator da92784 (UI-8 and Wave 13 close records,
including required 47db070) with merge commit 4a2b542. Earlier delivery 503dab6
is preserved; the latest delivery adds only UI-A5's scoped presentation/docs.

## Delivered batches

- **AV-N1 (High):** Oilskin Ball, Laser Ball, Tempo Pin, Neon Sign, Blacklight,
  Bumper Guard. Seven slots each, artwork/effects_audio flags, actual physical
  and paid cues, sounds and reduced effects. Bumper Guard's real rebound has a
  visible rail/inward arrow; Tempo's reward shows the actual accurate count and
  Value. [AV-N1.md](AV-N1.md).
- **AV-N2 (High):** Glow Ball, Prism Pin, Grip Tape, Spotlight, Afterimage and
  Laser Level. Seven slots each and flags; native trail, host belt/lamp, actual
  first direct curved hit, exact paid counts/amounts and sounds. No invented
  Grip Tape score award. [AV-N2.md](AV-N2.md).
- **E22-L02-ART tail (Medium):** fresh live review of all Neon rooms, finishes,
  Champion and trophy; static authored kickback/cushion panels replace the
  remaining plain surfaces in Neon only. Existing shapes/materials/physics and
  House surfaces are unchanged. [E22-L02-ART.md](E22-L02-ART.md).
- **UI-A4 (Medium, repository claim added this wave):** original logo, app icon
  and splash at UI-7's fixed paths, with a deterministic production exporter.
  No subtitle or title-flow changes. The existing authored House title backdrop
  remains. Source icon 111430 bytes; exported favicon 118732 bytes.
  [UI-A4.md](UI-A4.md).
- **UI-A5 (High, owner extension):** refined title composition and night fade,
  gentle logo/ball entrance, lamp breath/dust/parallax and a small tap response
  within the original 0.3 s exit. Fully still reduced motion and immediate input.
  Reviewed and retained the existing logo, icon, splash and #0b1116 colour.
  [UI-A5.md](UI-A5.md).

Original sources, exact image-generation prompts, synthesis recipes and hashes
are in docs/art/ASSET-LEDGER.md and the batch briefs. No captures are committed.
The font and all existing glyphs are untouched. Catalogue edits are confined to
our twelve entries' assets and artwork/effects_audio flags. Protected gameplay,
League configurations, project and export settings are not directly edited.
QA/CI/run_tests additions preserve all old checks; every new CI art step has the
art-shard guard. No missing presentation hook request remains.

## Verification

Pinned Godot 4.5.2, Linux Compatibility/llvmpipe, Xorg :100 with MIT-SHM disabled,
Dummy audio, LP_NUM_THREADS=2. Playwright 1.63.0 Chromium for JW01. No physical
phone, hardware-audio or device-performance trial is claimed.

- The initial 165-command regression matrix passed 163; JAVC04B rendered and
  J03C15 rendered passed on resume at their unchanged timeouts. Post-merge
  unit/content and final JAVN1 rendered also passed. Original failure logs remain.
- AV-N2: unit/content/physics; JAVN2/JAVN2C/JAVN2BC and J03C16/J03C17/JUIA2
  headless/rendered PASS. Fixed-fps headless audio is paced only in the art test,
  retaining every required sound assertion and the real four-voice mixer limit.
- Theme: corrected unit test, J22L02LIVEART and J22L02 headless/rendered PASS.
  All 24 matches, independent banks, save/resume, gates/title/trophy and attempt-2
  reward checks remain. The two new captures are real normal/reduced rolls.
- Brand/final tree: unit, content, physics, J01 headless/rendered and JW01 PASS.
  Both phone tours completed 30 captures. Landscape emitted a one-resource
  shutdown warning after successful completion; this non-asserting capture-tool
  limitation is explicit in UI-A4.md. Strict J01 and JW01 logs are clean.
- Physics digest remains
  `75d1a3c0ceb2f8e458f7788de7e938de194633c1720aca1488b68a21eb310c6f`.
  J03 remains 560/240/70; J05 21060. J03C15 banks 70/1650/1200; J03C16
  1012/2015/720. Resource/audio/brand regeneration is byte-identical.
- UI-A5 after merge 4a2b542: unit, J01/JUIA1/JUIA2 headless and rendered,
  qa.py web PASS. Both phone tours completed 31 captures with exit 0; both
  emitted the previously noted ObjectDB/one-resource shutdown diagnostic.
  Standalone native motion/input/reduced/reopen/resize checks pass in both
  orientations. Actual light/dark Chromium tab review and 180/32/16 icon
  studies completed; iPhone home-screen mask/size review is simulated.
  Evidence: artifacts/ui-a5/checks/{results,platform-results}.json and
  icons-final.log; native review.json in title-{portrait,landscape}/.

Local evidence: artifacts/wave13/av-n1/ (original matrix and resume/), av-n2/
(results.json), theme-tail/complete/ (final live art), theme-tail/final/ (J22L02),
and ui-a4/final/complete-results.json (final unit/content/physics/J01/web/tours).
These results distinguish the baseline matrix from the affected final reruns;
no unrun remote CI or device test is claimed.

## Owner capture review

Regenerate journeys with `python3 tools/qa.py e2e --journey ID --rendered`.
All paths below are local ignored output. Full indexes are in the batch handoffs.

- **Twelve cards / icon scale:** JAVN1C and JAVN1BC,
  artifacts/av-n1/contact{,-b}/rendered/count_2.png; JAVN2C and JAVN2BC,
  artifacts/av-n2/contact{,-b}/rendered/count_2.png. count_0/count_1/motion show
  other count specimens and normal/reduced cues.
- **AV-N1 in play:** artifacts/av-n1/native/rendered/n1_rebound_live.png,
  n1_tempo_paid.png, n1_laser_beam.png, n1_laser_paid.png, n1_neon_sign_paid.png,
  n1_blacklight_paid.png, n1_bumper_guard_paid.png and n1_oil_hold.png.
  n1_host_{blacklight,bumper_guard}, six n1_shop_* and six n1_binder_* PNGs.
- **AV-N2 in play:** artifacts/av-n2/native/rendered/n2_glow_trail.png,
  n2_spotlight_hit.png, n2_grip_hook_reduced.png, n2_host_grip.png and
  n2_{glow,prism,spotlight,afterimage,laser_level}_paid.png. Six n2_shop_* and
  six n2_binder_* PNGs show each identity in real UI.
- **Live Neon:** artifacts/e22-l02-art/live/rendered/live_pin_deck_{normal,reduced},
  live_d02_feature, live_d03_feature, live_champion_normal,
  live_champion_landscape, j22n_champion and j22n_attempt2 PNGs.
- **Brand:** artifacts/e03/rendered/title.png;
  artifacts/e26-w01/headless/{web_loading,web_title}.png;
  artifacts/ui-a4/tour-{portrait,landscape}/01_title.png;
  artifacts/ui-a4/brand/icon_sizes.png and icon_{180,32,16}.png.
- **Audio:** assets/audio/sound.<stable-item-id>.wav for all twelve items.
- **UI-A5 title/motion:** artifacts/ui-a5/tour-{portrait,landscape}/01_title.png;
  title-{portrait,landscape}/motion.mp4 (five seconds), tap_beat.png,
  reduced_early.png / reduced_late.png. These last directories are also under
  artifacts/ui-a5/. Web loading/title are the e26-w01 captures above.
- **UI-A5 icons:** artifacts/ui-a5/icons/tabs_{light,dark}.png,
  sizes_{light,dark}.png (180/32/16 px), iphone_simulated_{light,dark}.png.
  Actual browser chrome and explicitly labelled iPhone size/mask simulation.

## Coordinator / resume

Merge this completed checkpoint into claude/roguewood-build, then run the normal
integration CI and update central claims. Optional capture-tool follow-up is the
tour shutdown diagnostic recorded in UI-A4 and UI-A5. No unfinished Codex Wave 13
art claim remains. The next item art batch is AV-N3 in Wave 14, proposed High
effort after its coordinator claim; do not begin it from this checkpoint.
