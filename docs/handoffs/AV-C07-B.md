# AV-C07-B — Savings Book, Extra Shelf, Spotlight Sign

State: DONE (implementation and local verification).
Codex / codex/roguewood-build, resumed from 34296b2. Coordinator branch fetched
and already merged; no rebase or force push.

## Delivered

All six asset slots for each of the three remaining shop upgrades: original
identity art, license-category rarity frame, static reduced-motion identity,
activation recipe and original procedural sound. Exact generation prompt,
source hash and foley commands are in docs/art/ASSET-LEDGER.md.

- Savings Book: passbook beside the settlement line; raised interest cap uses
  the existing economy and upgrade constants. The paid interest remains the
  authoritative settlement text.
- Extra Shelf: a distinct lower shelf lip on the sixth offer, retaining its
  existing Extra Shelf label and authoritative offer contents.
- Spotlight Sign: illustrated sign above the offer grid; unsold offers have
  brighter rarity-coloured frames. Existing written rarity remains visible.

The read-only ownership observer handles all six upgrades, shared mixer controls
and static reduced motion. Saved ownership initializes silently. No economy,
stock, scoring, save, League or gameplay implementation changed. Catalogue edits
are limited to these three items' six asset slots and artwork/effects_audio flags,
set after successful native checks. No flags in batch files or on House items.
qa.py and CI additions register JAVC07BC and its artifact directory; run_tests.gd
is unchanged. No screenshots are committed.

## Verification

J03C07 PASS headless and rendered. It tests the actual first License purchase and
explicit inventory fixtures for the other five upgrades, with individual native
activation/audio captures. Fixture grants now leave 450ms between acquisitions
so the four-voice mixer drains, matching separate purchases; no mixer behavior
was altered. Checks cover settlement cap/passbook, sixth shelf, spotlight frames,
real purchases/rerolls, reserve placement and silent save restoration.
JAVC07BC PASS headless and rendered; contact inspected at 180px and 48px.
Rendered feature shop inspected for readable text, prices and controls.

Logs: artifacts/av-c07-b/validation. Captures: artifacts/e18-c07/rendered and
artifacts/av-c07-b/contact/rendered. Desktop llvmpipe evidence; no phone gate or
subjective listening claim. Existing CI runs and uploads J03C07 captures.
Catalogue scope and add-only audits PASS. Final unit/content PASS with flags
set. Required headless regressions PASS: J03C05–J03C10, JAVC03A/B,
JAVC04A/B/C, J22L01ART, J11ART, J12V08, J19A16 and J06. Physics PASS;
digest unchanged at 75d1a3c0ceb2f8e458f7788de7e938de194633c1720aca1488b68a21eb310c6f.
Godot emitted a non-fatal Jolt job-pool warning during physics; no failing check.
Rendered runs emitted the existing llvmpipe V-Sync warning.

## Resume exactly here

AV-C07-B is delivered with this commit. Codex's Wave 7 claims are complete.
See WAVE7-CODEX.md for the completion index. Coordinator owns
integration and central progress. Do not start Wave 8 or set House art flags.
