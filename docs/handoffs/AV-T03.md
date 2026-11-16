# AV-T03 — charge particles following the held ball

Status: DONE (implementation and automated verification, 2026-11-16).
Branch: codex/roguewood-build. Coordinator UI-10 (81bac7d) merged with a
merge commit before work. No input, launch, tuning, sound or vibration changes.

## Source and scope

Presentation ID AV-T03 replaces the AV-T01/AV-T02 collar; no catalogue IDs or
slots. Original procedural pixel particles, no external sources; provenance
in ASSET-LEDGER.md. Existing throw.charge, throw.curve_ready, throw.full_charge
and throw.spin_tick cues retained. Native journey: JAVT01; regression: J02,
physics, J03 and J05. Capture plan below covers both models and both views.

## Implementation

Removed SWING/CURVE/FULL/NO SPIN tabs, collar teeth, fixed stars, arcs and seal.
A bounded 96-slot pool records historical screen positions. Emission rate,
lifetime (0.12–0.55 s) and opacity rise with charge; spin rate contributes to
emission density. Blue-grey building particles step to cyan at curve-ready
and brass at full. Each particle stays at its emission point and fades with
age. A emits along the moving ball path; B emits from its rotating rim using
the real body angle, leaving a short-lived trace even with a stationary center.
Below 0.06 charge, Dead Straight, cancellation and leaving hold clear the pool.
Resize clears old screen coordinates. No random generator, particle nodes,
resource creation, growing arrays or per-frame dictionaries. The existing aim
guide now reuses a preallocated point buffer too.

Reduced motion clears all particles and preserves the still ball. Because the
old charge meter was the removed collar, its function is relocated to a small
stationary lower-screen bar, only in reduced motion. Reduced flash retains
the path but caps opacity at 0.38, with no bursts or flashes.

## Captures

85 ignored PNGs in artifacts/av-t01/rendered/ (no captures committed).
For A, prefix is empty; for B, `model2_`. Each prefix has:
`{depth,flat}_{normal,motion,flash}_{charging,building,ready,full}.png` and
`{depth,flat}_{normal,motion,flash}_swirl_{130,135,140}.png`.
`charging` means initial zero charge. `disabled.png` covers Dead Straight.
Building captures wait for the first visible particle unless reduced motion.
Review the three successive normal swirl frames to see deposited particles
remain behind as the ball moves. These are desktop native captures, not a
phone performance or hardware feel claim.

## Resume

UI-A7 next (Medium–High), per docs/prompts/codex-wave14-ui-a7.md. Then resume
AV-N3, AV-N4, AV-N5 and UI-A6. UI-A7 has not been implemented in this checkpoint.

## Verification

Pinned Godot 4.5.2, Linux Compatibility/Mesa software rendering, isolated Xorg
:98/:97 with MIT-SHM disabled, LP_NUM_THREADS=2 and writable XDG directories
under /tmp. UI-10 merge commit: 4ad1e00.

PASS: qa.py unit, content, physics; J02 headless and rendered; J03 and J05
headless; JAVT01 headless and rendered. Final rendered run produced all 85 captures.
Physics digest: 75d1a3c0ceb2f8e458f7788de7e938de194633c1720aca1488b68a21eb310c6f.
J03 remains 560/240/70; J05 remains 21060.

JAVT01 checks bounded pool size, empty rest/cancel/Dead Straight/reduced-motion
states, full-charge emission, brightness cap, historical particle positions,
correct ball radius/coordinates, stationary reduced-motion ball and the original
once-per-hold audio cues. Both models and both views run with normal, reduced
motion and reduced flash. All original capture requirements remain; QA changes
are add-only. Existing art-shard CI already runs JAVT01; no workflow edits.

Initial reduced-flash test exposed stale slot colors; clearing colors along with
lifetimes fixed it. Initial rendered launch found the old display stopped;
restarting isolated Xorg resolved it. Jolt's job-limit warning and dummy-display
V-Sync warning remain nonfatal. Full-wave matrix and web/phone performance are
not claimed here; UI-A7's web and tour checks remain for that item.
