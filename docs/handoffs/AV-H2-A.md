# AV-H2-A — Trophy Case, Corner Pockets, Late Rally

State: DONE (implementation and local verification).
Codex / codex/roguewood-build. Resumed from c5a4b35 resource checkpoint;
coordinator 0c9d915 already merged. No rebase or force push.

## Delivered

Six resource slots per item retained from c5a4b35; exact source prompt/hash and
procedural sound recipes in ASSET-LEDGER. Added read-only state cards and cues:

- Trophy Case: explicit saved count, illustrated card and small glass display
  with up to six cup marks (numeric count stays exact beyond six). During scoring,
  pre-bank frame growth is shown until the actual after-bank grow_value row,
  when the new cup lands. Shop uses saved growth; restored ownership stays silent.
- Corner Pockets: actual counted positions 7/10 from the resolver-owned frame,
  shown as dark pocket rims around the native numbered rack circles.
- Late Rally: score / half target, ON/off text and lit/dim clock. Uses the
  pre-bank context throughout the explanation, not the already-increased score.
  Only behind in frame 2 lights it; frame 1, threshold/ahead and Practice stay off.

Original geometry is in house_count_cards.gd, trophy_marks.gd, ability_glyph.gd
and the existing rack renderer. Reduced motion uses static cues. Shared audio,
mute and effects controls retained. No gameplay, persistence, League data or
House theme bindings changed. Only the three assigned flags change in catalogue.
No screenshots committed. Tests remain add-only.

## Verification

Native J03C09 checks first-frame zero/off, zero → one trophy after bank, pre-bank
120 / 250 while the match score is 4110, saved count through actual menu/Continue,
no restored growth replay, and one trophy retained on the next spare. Native
corner cues compare highlighted positions against actual rolls. Pure projection
checks supplement native evidence with zero/one/two positions; Late Rally's
negative boundaries are checked directly, not claimed as separate native runs.
Skipped/muted presentation fixtures are silent and cannot rebank the score.
Rendered cards/cues inspected. Desktop llvmpipe only; no phone or subjective
listening gate claimed. Logs: artifacts/av-h2-a/display-validation. Captures:
artifacts/e18-c09/rendered, including c09_first_frame, c09_rally,
c09_restored_trophy, c09_pickup and per-Charm cues.

Validation caught an unsupported %g label format (replaced with string formatting)
and J19A16's frameless presentation fixture (guarded before reading snapshots).
All failed/interrupted checks were rerun successfully; no assertion was weakened.
Final unit/content/physics PASS with the three flags enabled. Physics digest:
75d1a3c0ceb2f8e458f7788de7e938de194633c1720aca1488b68a21eb310c6f.
J03C09 PASS headless/rendered, including native save/resume. Required headless
matrix PASS: J06, J03C01–C10, JAVC03A/B, JAVC04A/B/C, J22L01ART,
J21R03/R04, J11ART, J12V08, J19A16, JAVC07AC/BC, JAVH1AC/BC and JAVH2AC.
J03/J05 PASS with existing values. Scope/add-only audits PASS. No other item
flags changed. Prior resource checkpoint logs remain under av-h2-a/validation.

## Resume exactly here

AV-H2-A is delivered with this commit. Next AV-H2-B: Clean Pickup, House Special and Front
Line. Proposed High effort for Front Line's counted rack positions. Read the
remaining E17-D08 design blocks and E18-C09 handoff, author three briefs and
resource sets, add native displays/checks before flags. AV-H1-A/B remain DONE.
Do not start Wave 9 or change E17-D09/DC-H4 flags/theme bindings.
