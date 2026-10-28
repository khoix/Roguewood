# E17-D01-ART — visual briefs

Implementation and document verification: **DONE**. Codex / `codex/roguewood-build`.
Delivered after Wave 1 completion `76aaec0`. Coordinator definitions at `0aae352`
were merged with a merge commit `5d9a8c1`; subsequent coordinator `5ecc1f0` was
merged as `1173592`. No branch rebase or force push.

The brief is [docs/art/briefs/E17-D01.md](../art/briefs/E17-D01.md). It covers:

- Balls: Spark, Ghost, Splitter, Gold.
- Pins: Glass, Echo, Fuse, Crown.
- Tacticals: Nudge, Reserve Call, Rule Waiver.

All 11 authored triggers, tag sets and `design.presentation_needs` are retained.
All 74 unique `design.asset_ids` appear exactly once in the slot tables. Each
brief specifies construction/silhouette, correct event and state cues, original
foley direction, reduced motion/flash, rarity and provenance. No extra in-play
asset is invented for the three tacticals that do not define one.

Eleven comparison groups flag likely confusion, including Spark/Fuse, Echo
Pin/Ball, Glass/Ghost/Ruby, Crown/Gold, Gold Ball/House/Hammer, Splitter/Ghost,
Nudge/Reserve and Waiver/Encore/Standing Order. Each has a concrete separating
construction and native-size grayscale/silhouette acceptance check. These are
written directions; visual distinction is not claimed before artwork exists.

Validation: 11/11 definitions and 74/74 exact, unique asset IDs; source triggers,
tags and presentation needs cross-checked; `git diff --check` PASS. Documentation
only: no catalogue flags, mechanics, unlocks, save data or tests changed.

**E19 art for these 11 definitions is READY.** Allocate bounded art child batches
before production. Their in-play/activation slots can only be verified through
real native gameplay after E18 lands each item. E18 owns the choosers, event
attribution, lifecycle and tunable physics values; art reads those contracts.
This does not mark E18, E19 artwork or E20 effects as delivered.

Next pending independent art task: E16-ART (READY, Medium). Ordinary E19 identity
batches: Medium; Spark/Ghost/Splitter's complex presentation: High. Coordinator
owns the central state update; this handoff has no pending-owner review state.
