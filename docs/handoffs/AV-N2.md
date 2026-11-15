# AV-N2 — Glow, Prism, Grip Tape, Spotlight, Afterimage, Laser Level

State: DONE (implementation and verification).
Branch: codex/roguewood-build, based on merge 81cda95 of coordinator 254a921.
AV-N1 is preserved. No rebase, force-push, main push or pull request.

## Delivered

High effort, two three-item groups. All seven asset slots and artwork/effects_audio
flags for ball.glow, pin.prism, ball_mod.grip_tape, pin_mod.spotlight,
charm.afterimage and charm.laser_level. Other catalogue fields are untouched.
Source contract, identities and effects: docs/art/briefs/AV-N2.md. Exact prompts,
unchanged source atlases, synthesized audio recipes and hashes are in the ledger.

Glow's curved trail, Prism's curved fall, Grip Tape's committed hook and
Spotlight's actual first direct hit read existing authoritative facts. Paid
effects display the resolver's amounts; Laser Level includes the actual fallen
count. Both attachments retain the host; Charms populate the live rail. Reduced
motion/flash keeps static information and ability-effects-off suppresses effects.

## Verification

Pinned Godot 4.5.2, Linux Compatibility / llvmpipe, Xorg :100 with MIT-SHM disabled,
LP_NUM_THREADS=2, writable XDG directories under /tmp. Dummy audio, no hardware trial.

Unit/content/physics PASS with flags enabled. JAVN2, JAVN2C and JAVN2BC PASS
headless and rendered. J03C16, J03C17 and JUIA2 PASS headless and rendered after
integration. JAVN2 retains native purchases, placements, explanations and the
independent banks 1012 / 2015 / 720. The additional reduced Grip Tape frame
independently banks 1012. Native shop/Binder, host, trail, first-hit and exact
Laser Level captures were visually inspected. Physics digest remains
75d1a3c0ceb2f8e458f7788de7e938de194633c1720aca1488b68a21eb310c6f.

A flags-enabled headless rerun exposed fixed-fps simulation outrunning Dummy's
wall-clock audio mixer. The art journey now paces its headless process at 16 ms;
it still requires every assigned paid sound and preserves the four-voice limit.
The corrected run PASS; the failure log is retained, not waived. Production
sound/physics are unchanged. Results and logs: artifacts/wave13/av-n2/ plus
/workspace/work/n2-{rendered,contact,contactb}.log. Regeneration of resources,
audio and brand exports was byte-identical (artifacts/wave13/regeneration.json).

The earlier AV-N1 165-command regression matrix passed all checks after the two
render retries on :100. QA registrations, CI art-shard steps and run_tests.gd
are add-only. No protected gameplay, League, project or export settings edited.

## Capture index

All are local ignored outputs; regenerate via qa.py e2e --journey ID --rendered.

- JAVN2: artifacts/av-n2/native/rendered/: original c16_shop, c16_spare,
  c16_glow_strike and c16_straight; n2_glow_trail, n2_spotlight_hit,
  n2_grip_hook_reduced and n2_host_grip.
- Same directory: n2_glow_paid, n2_prism_paid, n2_spotlight_paid,
  n2_afterimage_paid and n2_laser_level_paid.
- n2_shop_<item-id-with-underscores> and n2_binder_<item-id-with-underscores>:
  every assigned card in its real UI, with the selected Binder entry visible.
- JAVN2C: artifacts/av-n2/contact/rendered/{count_0,count_1,count_2,motion}.png:
  Glow, Prism, Grip Tape canonical cards, 44px identity and reduced/normal effects.
- JAVN2BC: same filenames under contact-b/rendered/: Spotlight, Afterimage,
  Laser Level (0/5/10 fallen count specimens).
- Audio: assets/audio/sound.<stable-item-id>.wav, six original cues.

## Coordinator / next step

No missing hook request. No DC-N3 onward art. The coordinator owns central
state and integration to main. WAVE13-CODEX.md indexes this batch, the live Neon
theme tail and UI-A4, with the wave checkpoint and capture list.
