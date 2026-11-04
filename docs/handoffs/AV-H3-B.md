# AV-H3-B — Tin Pin, Spare Jar, Consolation Prize

State: DONE (implementation and native verification).
Branch: `codex/roguewood-build`; base `f4acab7` (UI-A1 footer fix), with Claude
`1f1f34d` already merged. No main merge or coordinator Wave 9 closure is claimed.

## Delivered

Only `pin.tin`, `charm.spare_jar`, `charm.consolation_prize` receive asset paths
and both `artwork` / `effects_audio` flags. Tin fills seven slots; each Charm
fills its six required slots and leaves the unused in_play slot empty.

- Tin Pin: dented pewter illustration, petrol rings, common frame, static
  reduced image and original three-tap metal rattle. A shader adds visual dents,
  metal patches and solder seam to the real pin without changing its collisions.
  Fallen +5 Value gets a low arc; its standing after-bank payout releases a coin.
- Spare Jar: empty teal glass identity, live ivory pin specimens and exact count
  on the actual read-only inventory card, score card and owned-shop card. During
  explanation, the frame's pre-bank growth remains visible until the resolver's
  after_bank grow_value event is revealed. Each event advances the count once;
  a 0.55 s drop is cosmetic only. Reduced motion/flash shows the final pin;
  Skip advances the count silently without a drop. Sale removes the jar and
  repurchase starts empty. Original glass clink. Up to nine specimens are drawn;
  the numeral is uncapped (0/3/27 contact examples).
- Consolation Prize: cream/petrol participation rosette, oxblood tails and brass
  bowling-pin medallion. Only open-frame income settles and fastens the ribbon.
  Static fastened state in reduced mode; original quiet cloth rustle.

Original source, retained prompt and provenance: `docs/art/briefs/E17-D09.md`,
`docs/art/briefs/AV-H3-B-source-prompt.txt`, `docs/art/ASSET-LEDGER.md` and
`assets/items/d09/`. The final source intentionally uses the dark House ground.
It is an unchanged generated illustration, not a rendered game capture.

Presentation adapters only: no production UI script, input, rules, physics,
economy, persistence, Career, content source, project/export setting or House
theme binding changed. Existing shared cue/mixer mute, priority and Skip handling
are preserved. The source of counts is never animation time or screen text.

## Verification

Pinned Godot 4.5.2, Linux Compatibility / Mesa llvmpipe:

| Check | Result |
|---|---|
| `qa.py unit` | PASS, including exclusive Tin triggers, negative ribbon cases, immutable score projection, repeated reveal, uncapped and reset jar counts |
| `qa.py content` | PASS; final flags checked again by the Wave 9 validation run |
| `qa.py physics` | PASS; digest `75d1a3c0ceb2f8e458f7788de7e938de194633c1720aca1488b68a21eb310c6f` |
| J03C10 headless/rendered | PASS; original banks 660/750/78/612, open income $2 unchanged |
| JAVH3BC headless/rendered | PASS; large/icon/reduced identities, normal/static activations, sound resources and jar count specimens |
| Scope / whitespace | Catalogue changes limited to the three assigned asset sets and two flags; `git diff --check` PASS |

J03C10 retains every earlier purchase, placement, original throw, bank, assertion
and capture. Added observations check actual Tin identity and both exclusive
triggers, native audio for all three items, correct reduced-motion state, no
pre-bank count leak, later-frame +8 per growth, normal post-bank drop, inventory
and shop counts. Two additional real spare frames exercise a second growth and
Skip, then real Sell/reroll/buy taps prove the reset. No inventory fixture was
added beyond the journey's existing logged $2000 purchase grant.

Both flags stayed false for native verification and were set only after the
headless/rendered journeys passed and captures were inspected. No batch-file
flags or E17-D10 flags changed. New JAVH3BC runs only in the CI art shard and its
upload folder is inside the existing path list. qa.py, run_tests.gd, workflow
and the existing J03C10 are add-only.

Native captures (ignored, never committed):

- `artifacts/av-h3-b/contact/rendered/{contact,motion,counted}.png`.
- `artifacts/e18-c10/rendered/pin_tin_fallen.png`, `pin_tin_after_bank.png`.
- `charm_spare_jar_after_bank.png`, `charm_spare_jar_charm.png`,
  `charm_consolation_prize_after_bank.png` in that native folder.
- `jar_before_bank.png`, `jar_drop.png`, `jar_inventory.png`, `jar_skipped.png`,
  `jar_shop.png`, `jar_rebought.png`, plus all previous A and C10 captures.

Subjective speaker/headphone listening and physical-phone certification are not
claimed. The current production UI remains its existing developmental layout;
UI-A1 is the standalone target for the next wave's integration.

## Hand-off / resume exactly here

AV-H3-B is ready for Claude to inspect/integrate. All six AV-H3 items now have
their assigned artwork/effects. No Wave 10 work started.

The full Wave 9 regression matrix is the remaining closing task at this batch
checkpoint. Its logs/results are under `artifacts/wave9-codex/validation/`.
Complete and inspect that matrix, then write `docs/handoffs/WAVE9-CODEX.md`
with exact results and the ten UI-A1 owner-review captures. Commit/push that
index, verify remote SHA and clean tree. If the index exists on the latest
pushed checkpoint, its resume instructions supersede this paragraph.

Recommended effort for the closing validation session: High. Stop at the Wave 9
claims; UI-A2, AV-H4 and AV-T01 remain unclaimed Wave 10 work.
