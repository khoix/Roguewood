# AV-C06 — Nudge chooser checkpoint

State: IN_PROGRESS. Codex / codex/roguewood-build, resumed from dc6950f.
Fetch/merge found no newer coordinator work. E21-R03/R04 remain complete.

Implemented a numbered flat rack diagram in TacticSheet for Nudge. Existing
choices and their indices remain unchanged. Gold filled pins identify selectable
sources; outlined gold spots identify legal empty destinations. Diagram buttons
emit the same deferred choice index as the original list. The diagram is hidden
for Reserve Call and Rule Waiver. No gameplay, save, rules or content edits.

J03C06 now checks that the diagram has ten spots and highlights exactly the
rule-provided adjacent empty destinations, captures the chooser, then taps a
real diagram button and verifies the pin moves on the lane. The existing list
still selects the source pin, covering both input paths.

Source/provenance: original Godot UI geometry in tactic_sheet.gd; no external
images or audio. No catalogue assets or completeness flags changed. This is
only the chooser portion of AV-C06, not a completed tactical-card art batch.

Validation: qa.py unit and content PASS; J03C06 headless and --rendered PASS.
The chooser capture was visually inspected. A test type-inference error was
fixed before the successful native reruns. Captures remain ignored under
artifacts/e18-c06/rendered; logs under artifacts/av-c06.

## Resume exactly here

Finish AV-C06 before starting upgrades. Read E18-C06 and E17-D01 presentation
needs. Add activation and sound for Nudge, Reserve Call and Rule Waiver through
tactic_played(action); a persistent this-frame-only swap marker; and a visibly
waived rule badge for the frame. Respect mute/volume/effects/reduced-motion
controls. Preserve chooser ordering. Verify the three cards natively, including
save/reload and frame-boundary cleanup, before setting only their artwork and
effects_audio flags and applicable slots. Record provenance in ASSET-LEDGER.
Then AV-C07 in two three-upgrade sessions (Medium). No House item flags this wave.
