# AV-H1-A — Head Pin, Wood Grain, Opening Act

State: DONE (implementation and local verification).
Branch: codex/roguewood-build. Coordinator through 0c9d915 (E22-L01) merged
with merge commits. No rebase or force push. Prior checkpoints: 1d5910a identity,
036dcf3 activation/audio resources, 78af929 native displays.

## Delivered

All six slots for each assigned Charm: original identity art, existing common/
uncommon Charm frames, static reduced-motion identity, activation and original
procedural sound. Prompts, source hash and reproduction commands are recorded
in docs/art/ASSET-LEDGER.md; briefs in docs/art/briefs/E17-D07.md.

Head Pin projects position 1 from its eligible resolver event into the rack
highlight. Wood Grain draws one grain mark per resolver count. Opening Act's
marquee is lit in authoritative match frame 1 and dim in frame 2. Counts never
come from animation time. Shared mixer, mute/effects controls and reduced-motion
paths are reused. The three artwork/effects_audio flags are enabled after native
verification. No other item flags or gameplay/League/theme bindings changed.

## Verification

J03C08 additions retain the real purchases and throws and capture each cue while
its original score explanation plays. Head Pin's highlighted position is checked;
Wood Grain's count is compared with actual fallen Wood Pins, with ten and seven
captured. Opening Act is checked lit/dim across frames. Explicit skipped/muted
presentation fixtures are silent and cannot rebank the score. These fixtures
exercise the presentation adapter, not synthetic gameplay resolution.
Final unit/content/physics PASS. Physics digest remains
75d1a3c0ceb2f8e458f7788de7e938de194633c1720aca1488b68a21eb310c6f.
Required headless matrix PASS: J06, J03C01–C10, JAVC03A/B, JAVC04A/B/C,
J22L01ART, J21R03/R04, J11ART, J12V08, J19A16, JAVC07AC/BC.
J03 remains 560/240/70; J05 remains 21060. Catalogue scope/add-only audits PASS.
Headless and rendered J03C08 PASS. Native cue captures and dim marquee inspected.
The rendered ten-mark cue retains a readable numeric count in the score log.
Logs: artifacts/av-h1-a/final-validation. Captures: artifacts/e18-c08/rendered,
including charm_head_pin_1_cue, charm_wood_grain_10_cue,
charm_wood_grain_7_cue, charm_opening_act_0_cue and c08_open.
No screenshots committed. Desktop llvmpipe evidence; no phone or subjective
listening gate claimed. Earlier contact evidence remains under av-h1-a/contact.

## Resume exactly here

AV-H1-A is delivered by this commit. Next session AV-H1-B (Medium): Open House, Strike Fund,
Holdouts. Read their landed E17-D07 design blocks, author three briefs/identities,
effects/audio and native treatments, extend J03C08 add-only and verify before
setting their flags. AV-H2-A/B remain later Wave 8 work. Never set E17-D09/DC-H4
flags or change E22-L01-ART asset bindings.
