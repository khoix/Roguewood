# AV-H2-A — Trophy Case, Corner Pockets, Late Rally

State: resource checkpoint; batch NOT complete.
Codex / codex/roguewood-build. Base 180f1d9; coordinator 0c9d915 already merged,
fetch found no newer integration work. AV-H1-A/B remain DONE.

## Delivered

Briefs for these three Charms in docs/art/briefs/E17-D08.md; original transparent
identity atlas, prompt/hash provenance and procedural foley reproduction commands
in ASSET-LEDGER. Six slots each: icon, card, rarity_treatment, reduced_motion,
activation and sound. Uncommon Charm frames reuse Opening Act's frame geometry.
Existing ability projection/mixer consume the resources; no gameplay edits.

JAVH2AC adds a 180px/48px contact on CI's art shard. J03C09 additions capture
native cues during the original score explanation and assert all three resolver
activations and reduced motion. Existing purchases, score checks and fixtures
are retained, including the $8000 wallet and House Special's gate in this
attempt's pool. Tests, qa.py and CI changes are add-only.

Not delivered: saved trophy count/card fill, new trophy landing after bank,
counted corner-pocket overlays and Late Rally's conditional score/half-target
display. Both completion flags remain false. No other catalogue items, batch
flags, House theme bindings, rules or League files changed. No screenshots
committed. No subjective audio listening or phone gate claimed.

## Verification

Unit/content/physics PASS. Exact physics digest:
75d1a3c0ceb2f8e458f7788de7e938de194633c1720aca1488b68a21eb310c6f.
JAVH2AC and J03C09 PASS headless/rendered. Identity contact inspected at both
sizes; native Trophy Case after-bank capture inspected with the growth log.
Required headless regressions PASS: J06, J03C01–C10, JAVC03A/B, JAVC04A/B/C,
J22L01ART, J21R03/R04, J11ART, J12V08, J19A16, JAVC07AC/BC, JAVH1AC/BC.
J03/J05 PASS; scope/unchanged flags/add-only audits PASS. No test errors in logs.
Logs: artifacts/av-h2-a/validation.
Contact: artifacts/av-h2-a/contact/rendered/contact.png.
Native cue captures: artifacts/e18-c09/rendered/charm_*_cue.png.

## Resume exactly here

Fetch and merge newer coordinator work with a merge commit if needed. Complete
AV-H2-A before AV-H2-B; reuse these resources rather than reauthoring them.
1. Trophy Case: read saved growth for the card count, use pre-bank frame state
   for the scoring count, and reveal the new trophy only on the grow_value
   after-bank event. Verify zero → one and persistence, with no premature score.
2. Corner Pockets: project actual counted positions 7/10 and render lit pocket
   rims at those spots in the native flat rack. Verify one/two/zero cases.
3. Late Rally: show pre-bank score against half the target; light only behind
   in frame 2, not frame 1, ahead, or Practice. Read facts/context, not the
   post-bank match score or animation time.
4. Add native state/cue/silent skip/mute assertions and captures to J03C09,
   inspect headless/rendered evidence, run affected checks and required matrix,
   then set only these three artwork/effects_audio flags and mark DONE.
5. Commit/push and verify remote SHA/clean tree. Next effort High. AV-H2-B stays
   pending; never set E17-D09/DC-H4 flags or change E22-L01-ART bindings.
