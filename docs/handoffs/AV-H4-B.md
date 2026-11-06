# AV-H4-B — Cleanup Crew and Lucky Seven

State: DONE (implementation and native verification). Branch: codex/roguewood-build; base bd44d9c (AV-H4-A).
Coordinator checked at ec9cabc, already merged via a83baff.

## Delivered

Six slots for each Common Charm: icon, card, rarity frame, reduced identity,
activation and sound. Original generated atlas and procedural foley; provenance
in docs/art/ASSET-LEDGER.md, briefs in docs/art/briefs/E17-D10.md.

Cleanup Crew sweeps beside an explicit `LEAVE n / 2` caption. n comes from the
resolver's leave fact; the threshold comes from the paid event's condition.
The actual first-roll standing positions are outlined on the score rack. The
crew stays silent on an open frame or a spare after a one-pin leave.

Lucky Seven's identity die has a blank front face. Only its paid open-frame
activation settles on 7, with `7 DOWN`; count comes from committed fallen slots,
and the qualifying resolver event establishes eligibility. No seven on six or
eight down, strike or spare. Reduced mode shows the final static state directly.
The 6-down contact specimen intentionally has a blank face; no runtime effect
is created for that ineligible case.

No rules, physics, production UI, input, persistence or League binding edits.
Catalogue changes are limited to these two entries' six slots and two flags.
qa.py, run_tests.gd and CI are add-only; JAVH4BC runs in the art shard and its
upload folder is inside the existing list.

## Verification

Pinned Godot 4.5.2, Compatibility/Mesa llvmpipe. PASS: qa.py unit/content
with both flags enabled; JAVH4BC and J03C11 headless and rendered.
git diff --check PASS. Full closing matrix follows this checkpoint.
- Unit boundary cases: first-roll leaves 1/2/3/10, exact-seven open frames versus
  0/6/8/9 down, strike/spare silence, and immutable resolver/frame data.
- JAVH4BC headless/rendered: full card, icon and reduced identities; normal and
  reduced cues; a ten-pin leave and a six-down blank-face specimen.
- J03C11 headless/rendered: original five purchases and all independent banks
  retained. Adds actual first-roll leave/threshold/slots/audio assertions and a
  native settled Lucky Seven face with exact down/standing/Mult checks.
  The new die capture waits actual process frames for its final pose; no timer,
  count, event or score is rewritten.

Evidence, never committed:
- artifacts/av-h4-b/contact/rendered/{contact,motion,counted}.png
- artifacts/e18-c11/rendered/h4_{cleanup_crew,lucky_seven}.png
- logs: artifacts/wave10-codex/av-h4-b/

## Resume exactly here

All four Codex Wave 10 children are implemented after this batch. Complete the
closing matrix in codex-wave10.md, then write WAVE10-CODEX.md with the UI-A1-C
layout/backdrop capture set and UI-A2 integration link. No Wave 11 work.
Claude's pre-existing stacked-repeat explanation follow-up is documented in
AV-H4-A.md; exact art attribution is already covered by unit tests.
