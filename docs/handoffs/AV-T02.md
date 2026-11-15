# AV-T02 — held flywheel presentation

Status: DONE (implementation and automated verification). Owner: Codex. Branch: codex/roguewood-build.

## Scope and provenance

Read the per-item brief, E05-R5 and ADR 011's flywheel revision. Merged
coordinator be1d045 with merge commit c9ecd381 before implementation.
Presentation ID: AV-T02, extending AV-T01's AimOverlay; no catalogue IDs or
asset slots added. Existing cues throw.charge, throw.curve_ready,
throw.full_charge and throw.spin_tick, including vibration, are unchanged.
Source plan and implementation: original procedural geometry, recorded in
ASSET-LEDGER.md; no external assets. Journey: JAVT01, with J02 regression.
Capture plan: A/B × depth/flat × normal/reduced motion/reduced flash ×
rest/curve-ready/full, plus the existing Dead Straight fixture.

## Implementation

Three stationary swept arcs grow in length, thickness and opacity with the
absolute live flywheel spin, resolving into rings at speed. They follow its
coast without a second animation clock. The ball's existing body-angle rotation
is preserved. Sparkles stay stationary to avoid their rapid rotational aliasing.
A steady brass outer seal makes full charge distinct from curve-ready.
Reduced motion and reduced flash suppress the swept arcs; the existing meter,
label and stationary sparkles plus full seal carry the state. Reduced motion
retains the existing still-ball behavior. No input, launch, physics, scoring,
audio or tuning values changed.

JAVT01 drives actual touch circles for both models. It checks rest, readiness,
full rings, bounded intensity, accessibility suppression, still reduced-motion
ball, coast decay, correct screen alignment and once-per-hold audio cues.
The QA capture contract is extended add-only; the existing art-shard CI step
runs the expanded journey without a new workflow step.

## Capture review

37 ignored PNGs under artifacts/av-t01/rendered/:
- A: `{depth,flat}_{normal,motion,flash}_{charging,ready,full}.png`.
- B: `model2_{depth,flat}_{normal,motion,flash}_{charging,ready,full}.png`.
- `disabled.png`.

`charging` is the initial stationary hold. Inspected depth_normal_full,
depth_motion_full and model2_flat_normal_full at phone resolution. Phone
hardware/refresh-rate feel remains unmeasured; these are desktop native captures.
No captures committed. Existing item markings remain visible beneath the new
streak envelope; this is a drawn spin cue, not a temporal renderer blur.

## Verification

Godot 4.5.2 on Linux; rendered checks on Xorg dummy display :99, Mesa software
rendering. Writable temporary XDG directories; engine path in WAVE14-CODEX.md.
PASS: qa.py unit and content; physics; J02 and JAVT01 headless and rendered;
J08, J03 and J05 headless. JAVT01 produces all 37 required captures. Final
headless rerun includes the rest/coast/still-ball assertions, as does the
rendered run. No assertions or timeouts weakened.

Physics digest: 75d1a3c0ceb2f8e458f7788de7e938de194633c1720aca1488b68a21eb310c6f.
J03 banks: 560/240/70. J05 score: 21060. Full-wave regression matrix has not
been rerun in this checkpoint. No phone hardware or V-Sync validation claimed.
Jolt reported a job-capacity warning but physics completed with no failures;
the dummy display reports unsupported V-Sync control.

## Resume

AV-N3 next, High effort: E17-D14 and E18-C17, following AV-N1/AV-N2.
AV-N4, AV-N5 and UI-A6 follow. See WAVE14-CODEX.md for exact scope and setup.
