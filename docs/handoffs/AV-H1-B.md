# AV-H1-B — Open House, Strike Fund, Holdouts

State: DONE (implementation and local verification).
Codex / codex/roguewood-build, base c5fd29b. Coordinator 0c9d915 already merged;
fetch found no newer integration work. AV-H1-A remains DONE.

## Delivered

Six slots per assigned Charm: original icon/card/static reduced-motion identity,
common Charm rarity frame, activation recipe and original procedural sound.
Exact prompt, original source hash and reproducible foley commands are in
ASSET-LEDGER; briefs are in docs/art/briefs/E17-D07.md.

- Open House: walnut door and welcome mat; its eligible open-frame resolver cue
  swings a hinged door over the identity, held static in reduced motion.
- Strike Fund: X-marked coin-slot jar; a single animated coin on the after-bank
  strike payout event. The existing score log carries the authoritative income.
- Holdouts: folded-arm pins; the cue draws exactly one figure per resolver
  standing count, capped at ten rack positions. Figures never count animation
  completions. Existing score log keeps the number and Value calculation visible.

The existing ability adapter supplies events/phase/count/amount and bounded
mixer controls. No scoring, economy, persistence, League or theme bindings changed.
Only these three items' six slots and artwork/effects_audio flags changed in the
catalogue. No flags in batch files or on E17-D09/DC-H4 items. No screenshots
committed. J03C08, qa.py and CI changes are add-only; CI contact is on art shard.

## Verification

J03C08 PASS headless and rendered: real shop purchases/throws, separate native
captures for all three cues, reduced-motion assertion, open-frame trigger,
strike after-bank $1 condition, and one figure per actual standing pin. Explicit
skipped/muted presentation fixtures remain silent. Gameplay banks continue to
match independent resolution. The original AV-H1-A assertions remain intact.
JAVH1BC PASS headless/rendered; 180px/48px contact inspected. Native captures
inspected: door, coin with after-bank log, three figures with 3 × +8 log.
Final unit/content/physics PASS with completion flags set. Physics digest remains
75d1a3c0ceb2f8e458f7788de7e938de194633c1720aca1488b68a21eb310c6f.
Required headless matrix PASS: J06, J03C01–C10, JAVC03A/B, JAVC04A/B/C,
J22L01ART, J21R03/R04, J11ART, J12V08, J19A16, JAVC07AC/BC and JAVH1AC.
J03 remains 560/240/70; J05 remains 21060. Scope and add-only audits PASS.
No phone or subjective listening gate claimed; desktop llvmpipe only.

Logs: artifacts/av-h1-b/validation. Contact:
artifacts/av-h1-b/contact/rendered/contact.png. Native cues under
artifacts/e18-c08/rendered/charm_{open_house,strike_fund,holdouts}_cue.png.

## Resume exactly here

AV-H1-B is delivered with this commit; AV-H1-A/B are complete. Next session AV-H2-A:
Trophy Case, Corner Pockets, Late Rally (High, due to counted/growing displays).
Read E17-D08 landed design blocks and E18-C09 handoff; build the three briefs,
identity sets, effects/audio and resolver-driven displays. Extend J03C09 add-only,
verify natively before flags. AV-H2-B follows. No Wave 9 flags or theme changes.
