# E17-D04-ART — modification briefs

State: **DONE** (briefs). Codex / `codex/roguewood-build`; Wave 5 claim, coordinator
base `2299a3a`. Source: E17-D04.json under both definitions and landed, E17-D04
handoff, design §15 and current roadmap. Follows AV-C03-A/B.

## Before

Twelve briefs and their exact six asset IDs each (72 total), including all eight
landed C04 modifications and four still authored. Cover modification card/icon,
host badge and cosmetic overlay, activation, sound, rarity and reduced motion.
Keep base host identity legible. Explicitly flag Echo Charge/Echo Ball, Lead Core/
Hammer Ball, Gilt Leaf/Gold Pin, Lead Weight/Anchor Pin, Spearhead/Crown Pin.
No art, resource paths, mechanics or completeness flags are changed by this claim.
Validate every brief against source IDs, trigger, presentation needs and tags;
run unit/content after authoring. Next-wave AV-C04 performs actual art and checks.

## Delivered

`docs/art/briefs/E17-D04.md` covers all twelve modifications from both source
collections, with exact triggers/presentation needs, rarity/tags/downside,
compatibility exclusions and all 72 asset IDs. Each has a distinct object
construction, a small host-preserving overlay, causal activation/audio brief,
reduced motion/flash and recognition checks. All five required look-alike pairs
are explicitly flagged, plus Brass Cap/Crown, Lantern/Hot Streak and related risks.

No new in_play asset IDs are invented: the source supplies six IDs per modification
and no in_play design ID. Future AV binding uses the badge/icon and cosmetic
presentation adapter, with a coordinated contract only if a separate asset slot
is actually needed. Chalk Grip's release dust is identity feedback, never a
prediction that the frame will become a spare; its award waits for the resolver.

## Validation

- Exact source audit PASS: 12 headings/definitions, 72 IDs, every authored trigger
  and presentation need retained verbatim; eight landed and four still authored.
- `qa.py unit` and `qa.py content` PASS after the briefs, with current C03 flags.
- Scope audit PASS: D01–D05 batch files byte-identical to coordinator `2299a3a`;
  no modification paths/flags, game logic or shared contracts changed.
- Evidence: ignored `artifacts/wave5/validation/d04-source-audit.json`,
  `d04-unit.log`, `d04-content.log`, `scope.json`.

## Hand-off

The containing commit delivers E17-D04-ART on codex/roguewood-build. AV-C04 in
Wave 6 makes/checks the eight landed modifications; recommended Medium for each
bounded three-item session, with High if the binding/retrigger interaction needs
it. Four authored modifications wait for their primitives and later claims.
No modification illustrations, effects, audio or completeness flags were produced
in Wave 5. D03 boss art remains in rival sessions. Stop at the Wave 5 boundary.
