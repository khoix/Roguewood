# AV-C03-B — Sweet Spot, Back Row, Underdog

Implementation and scoped verification: **DONE**. Codex, `codex/roguewood-build`; second three-item
session of Wave 5 AV-C03, following AV-C03-A `53ae250`.

## Before: scope, provenance and evidence

- Exact IDs: `charm.sweet_spot`, `charm.back_row`, `charm.underdog`.
- Preserve original D02 identities and rarity treatments. Check real shop offers,
  payment, owned inventory and binder before artwork flags.
- Exact activation/sound design IDs; original vector glyphs and deterministic PCM
  from author_c03_effects.py / author_foley.py, no samples or recordings.
- Sweet Spot: two visible grade medallions (sweet/perfect versus uncounted) and
  actual event count; reads frame roll grades and result.facts.accurate.
- Back Row: position-marked four-pin bracket and actual fallen back-row count;
  highlight the corresponding positions in the native score rack diagram.
- Underdog: score/half-target comparison with the actual pre-frame values and ×2;
  no cue at exactly half, above half or in Practice.
- JAVC03B buys all three, plays timed real throws for nonzero grade counts and
  full/partial/empty back-row coverage. A logged pre-frame score fixture covers
  the half-target boundary; no fabricated reports, resolver events or outcomes.
- Native audio starts, row alignment, 4×/Skip, reduced motion/flash, mute/volume,
  effects controls, immutable banks/inventory and bounded pools. Contact sheet
  compares normal/reduced cues at 64px. Unit tests cover zero/one/two grades,
  exact positions and target boundaries. Flags follow native evidence only.

## Delivered and verified

Three exact activation/sound pairs and their artwork/effects_audio flags are set
only after final headless/rendered native passes. Existing D02 illustrations,
icons, reduced resources and rarity treatments are unchanged. JAVC03B buys all
three from real offers with an explicit wallet/eligibility fixture, verifies real
payment, equipped inventory and binder, then plays real physical throws.

- Two timed native sweet releases (ring radius 0.1299966) produce the four-pin-leave
  spare: Sweet Spot displays S/S, count 2 and +6; Back Row shows slots 7–10, count 4
  and +24; Underdog compares 0 with half of 500. Bank 1728 independently matches
  the resolver's actual Charm order.
- A logged pre-frame score fixture sets the active match to 400 of 800. The real
  steady-mode strike banks 656: no Underdog at equality, no Sweet Spot on clean.
- Above half (551 of 1100), a real split shot followed by a gutter banks 72. Only
  Back Row cues, highlighting actual slots 7 and 9. The subsequent double gutter
  at 623 of 1100 banks 0 and all three stay quiet.

Grades come from frame rolls and result.facts.accurate; the displayed count and
award come from the resolver event. Underdog reads the saved pre-frame facts.
Back Row's read-only overlay draws rings and short caps outside the actual counted
rack slots, retaining numbers, roll colours and standing outlines. It clears when
the cue expires or effects are off; no score-panel/rule logic is changed.

Every cue is checked against its own explanation row. Native 4× replay preserves
cue order/details, silent Skip leaves audio count unchanged, and mute, zero volume,
effects toggles, reduced motion/flash and landscape preserve bank and inventory.
Rendered max audio voices: 3 (limit 4). Final original metal latch and grade-ring
animation were included in both final native passes before flags were enabled.

Unit/content with final flags PASS; integration PASS. Unit cases also cover one
and two graded rolls including perfect, no grades, partial back-row positions,
exactly-half/above-half/Practice boundaries and immutable inputs. Perfect and
Practice boundaries are unit evidence; the native timing shots were both sweet.
JAVC03BC contact checks PASS headless/rendered; native and contact captures were
inspected. Wave-wide regression evidence is recorded in WAVE5-CODEX at closure.

Evidence (ignored): `artifacts/av-c03-b/native/{headless,rendered}/metrics.json`,
shop/binder/inventory/activation captures, `back_row_partial.png`, reduced and
landscape views; `contact/rendered/contact.png`. Godot 4.5.2, Linux, Xvfb/llvmpipe,
Dummy audio: AudioStreamPlayer starts, PCM and controls are checked, not physical
speaker mix/latency or phone performance. Those remain Claude's E26. Exact audio
hashes and original synthesis parameters are in ASSET-LEDGER. No screenshots commit.

## Hand-off

The containing commit delivers AV-C03-B on codex/roguewood-build for coordinator
integration. Together with AV-C03-A `53ae250`, all six AV-C03 items are complete.
Next: E17-D04-ART briefs (Medium), then stop at the Wave 5 boundary.
