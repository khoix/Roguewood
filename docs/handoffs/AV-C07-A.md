# AV-C07-A — Punch Card, Pin Caddy, Clearance Tag

State: DONE (implementation and local verification).
Codex / codex/roguewood-build, resumed from e7f5a3a. Coordinator branch already
merged. AV-C06 and E21-R03/R04 remain complete.

## Delivered

The three identity sets and shop-license frames from e7f5a3a are retained.
Added six exact activation/sound slots, original deterministic paper/wood/metal
foley, and a read-only upgrade_art.gd observer. Purchase cues use existing identity
art, shared effects/mute/volume controls and static reduced motion. Restored
ownership initializes silently; entering another shop does not replay purchases.

- Punch Card: loyalty-card icon on reroll, Reroll free when cost is zero, then
  the authoritative dollar cost. The reroll action and price calculation are unchanged.
- Pin Caddy: illustrated case next to the rack summary and three labeled pockets,
  with the new third pocket highlighted and its actual reserve contents visible.
- Clearance Tag: red price tags with struck-through catalogue originals alongside
  the actual discounted prices, including unsold License offers. Sold/empty offers
  have no discount tag; floor prices and resale calculations remain authoritative.

No rules, economy, persistence, scoring or League files changed. Only these
three catalogue items' activation/sound slots and six artwork/effects_audio flags,
set after native verification.
No batch flags or flags on Claude's House items. No screenshots committed.

## Verification

J03C07 checks the native License purchase, fixture-granted remaining upgrades,
separate activation/audio captures, original/current clearance prices, third
pocket, real reserve placement, free-then-paid rerolls and silent save restoration.
The existing journey explicitly grants the upgrades not offered in its first
License; this is not a claim that all three were bought through natural stock.
Native captures inspected for caddy, free reroll and price-tag readability.

Final unit/content PASS with flags enabled. Physics PASS, digest unchanged:
75d1a3c0ceb2f8e458f7788de7e938de194633c1720aca1488b68a21eb310c6f.
J03C07 PASS headless and rendered. Required headless regressions PASS:
J03C05–J03C10, JAVC03A/B, JAVC04A/B/C, J22L01ART, J11ART, J12V08,
J19A16 and J06.
Logs: artifacts/av-c07-a/validation. Captures: artifacts/e18-c07/rendered,
including c07_free_reroll and per-upgrade activation captures. Existing CI runs
and uploads J03C07. qa.py, run_tests.gd and CI are unchanged in this completion.

The regression matrix caught reserve-pocket decoration shifting sell controls
before Pin Caddy was owned. The row is now limited to owned upgrades or an active
purchase cue; the failed journeys were rerun rather than weakening their checks.
The free-reroll assertion waits for the presentation refresh before reading text.

Provenance/foley commands: docs/art/ASSET-LEDGER.md. Desktop llvmpipe evidence;
no phone gate or subjective listening claim. Shared controls are reused.

## Resume exactly here

AV-C07-A is delivered. Fetch origin and merge any
newer coordinator work with a merge commit, keeping codex/roguewood-build.
Next AV-C07-B (Medium): Savings Book, Extra Shelf, Spotlight Sign. Reuse the
shop-license frame and upgrade observer; author the three remaining identity sets,
activation/audio and E17-D06's settlement cap/passbook, sixth-shelf and spotlight
rarity treatments. Check J03C07 natively and only then set those three flags/slots.
Do not edit shop rules, pricing, stock logic or saves. No House item flags this wave.
Finish the Wave 7 handoff after B; coordinator owns central progress and integration.
