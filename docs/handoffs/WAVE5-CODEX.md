# Codex Wave 5 — final delivery

Implementation and scoped verification: **DONE**. All three Wave 5 claims complete.
Branch: `codex/roguewood-build`. Coordinator `2299a3a` was merged with `5609c16`
after Wave 4's owner merge (PR #15). Each three-item AV session was committed,
pushed and its remote SHA/clean tree verified before starting the next session.
The containing final handoff commit identifies the final delivery head.

| Claim/session | Delivery commit | Scope |
|---|---|---|
| AV-C03-A | `53ae250` | Crown Pin, Crown Jewel, Split Specialist: native artwork checks, effects/sound, flags |
| AV-C03-B | `e6246bc` | Sweet Spot, Back Row, Underdog: native artwork checks, effects/sound, flags |
| E17-D04-ART | `b15371d` | Twelve modification briefs; 72 exact source asset IDs; five required look-alike flags |

## Result and scope

All six C03 identities were already authored. Real shop offers, purchases,
placement/inventory and binder were checked before artwork flags. Crown's exact
cosmetic scene is on the real rigid body, with unchanged body/mass/collision.
Six original activation recipes and six original synthesized PCM sounds now use
the exact landed design IDs. Effects flags followed active native cues and actual
AudioStreamPlayer starts in both modes. Source provenance/hashes are in ASSET-LEDGER.

Crown's +40 and silent explicit 0 follow the actual last-fallen result; Jewel
shares that last-pin identity. Split shows the saved first-roll leave. Sweet Spot
shows actual roll grades/count, Back Row highlights the actual counted positions
in the native rack diagram, and Underdog compares saved score to half the target.
The explicit Crown zero rows are mapped separately from resolver events so they
cannot shift later Charm cues. No text parsing or animation-derived outcomes.

The D04 briefs cover six ball and six pin modifications, including both `landed`
and `definitions`. Badges/overlays preserve host identity. Echo Charge/Echo Ball,
Lead Core/Hammer Ball, Gilt Leaf/Gold Pin, Lead Weight/Anchor Pin and Spearhead/
Crown Pin are explicitly flagged with shape-based distinctions and future proofs.
No in_play design IDs are invented; future AV binding must use the declared
resources and presentation adapter, coordinating a new contract only if needed.

Exact scope audit against `2299a3a`: six artwork flags, six effects_audio flags,
twelve activation/sound paths. Every D01–D05 batch file is byte-identical. C04
modification flags and all future work are untouched. No changes to rules,
simulation, persistence, Career, procedural/content code, throw_lab or
clubhouse_model. qa.py/run_tests edits are add-only; parsed YAML preserves the
existing workflow after removing the two new steps and two upload paths. New
paths remain inside `with.path`, before `if-no-files-found`.

## Verification and evidence

Unit/content with final flags PASS; integration/smoke PASS. D04 unit/content and
exact source audit PASS. Physics retains digest
`75d1a3c0ceb2f8e458f7788de7e938de194633c1720aca1488b68a21eb310c6f`.
J03 retains 560/240/70, J05 21060, J06 its existing outcomes (headless PASS).

New JAVC03A/B and their 64px contact checks PASS headless/rendered. A's real split
banks 1680 (leave 4, Crown 8 last), its strike 1280 (Crown 6 last), its double
gutter cues none. B's actual two-sweet-release spare banks 1728; the half-target
fixture gives a real strike bank of 656 with Underdog quiet; a partial back row
banks 72 and highlights 7/9; a later double gutter banks 0 with all three quiet.
The half/above-half cases use explicitly logged pre-frame score fixtures, not
fabricated roll reports, events or outcomes. Perfect-grade and Practice boundary
coverage is unit evidence; native timing shots were sweet.

Every native cue is checked against its own explanation row. 4× replay preserves
cue order/details; mute, zero volume, effects toggle, reduced motion/flash and
silent Skip preserve bank/inventory. World glyph/audio limits remain four; new
native rendered fixtures used at most three audio voices. Every bank matches
independent FrameBuilder/Rules resolution. CPU process/physics/draw metrics are
recorded in the native JSON, under two-CPU Xvfb/llvmpipe conditions. These are
not GPU timings, a 60 FPS claim or physical-phone performance certification.
Dummy audio verifies playback starts/PCM/controls, not audible device mix/latency.
Physical-device checks remain Claude's E26.

Wave-wide headless/rendered regressions PASS: J03C01/C02/C03/C04, J11ART, J12V08,
J19A16, J12 and JAVC03A. Final result manifests are under
`artifacts/wave5/validation/`; all listed checks passed. The final contact fixture
uses each item’s correct illustrative award (Back Row: two pins, +12); both
contact journeys were re-run headless/rendered and inspected after that correction.
No full local CI matrix is claimed. Branch pushes trigger the full workflow.

Ignored captures/metrics (inspected; no screenshots committed):

- `artifacts/av-c03-a/native/rendered/`: Crown rack detail, +40/0, Split/Jewel,
  shop/binder/inventory, reduced/landscape and metrics.json.
- `artifacts/av-c03-b/native/rendered/`: timed grades, actual target check,
  counted full/partial back-row slots, shop/binder/inventory, reduced/landscape.
- `artifacts/av-c03-{a,b}/contact/rendered/contact.png`: normal/static constructions.
- `artifacts/wave5/validation/`: per-command logs, final/scope/source/audio manifests.

## Hand-off and boundary

AV-C03 and E17-D04-ART are DONE within their fixed Wave 5 claims.
Coordinator integrates through claude/roguewood-build and owns the central state
update. No PR to main or pending-user approval status is created.

Stop after Wave 5. AV-C04's eight landed modifications follow the Wave 6 claim,
recommended Medium per three-item session (High for a complex binding/retrigger
case); House theme art is High. No AV-C04 art, House themes/rivals, D03 boss art,
E21 or E22 implementation was started. Platform work belongs to Claude.
