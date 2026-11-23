# UI-A9-H — House alley-screen celebrations

Status: PREPRODUCTION, 2026-11-23. Implementation is not complete.
Assigned effort: High. Contract: docs/handoffs/UI-20.md; owner brief:
docs/prompts/codex-wave14-ui-a9.md. House only; Neon belongs to Wave 15.

## Identity and source plan before authoring

A warm walnut scoreboard with brass edges, ivory pins, petrol shadows and
small teal accents. Exaggerated pin faces and mechanical stage business supply
the humour. Lettering remains legible on the 252 × 90 canvas. Every variant
has a distinct action, composition and final still; changing a caption or timing
alone does not count as another animation.

Stable IDs below use prefix `celebration.house.`. Scene paths will be
`assets/ui/alley_screen/house/<suffix-with-dots-replaced-by-underscores>.tscn`.
Each scene supplies play(context), duration(), skip(), and one finished signal.
All manifest slots are presentation-only in assets/leagues/house/manifest.json.
Do not add scene paths to that manifest until the complete set is validated:
listing even one enables it in real matches. Keep celebrations_complete absent
until all twenty scenes, audio and accessibility variants are finished.

| ID suffix | Manifest slot | Distinct staging and reduced-motion still |
|---|---|---|
| strike.pinwheel | celebrations.strike | A rolling ball turns a ten-pin windmill into a fan of pins; final fan frames STRIKE! |
| strike.domino | celebrations.strike | Ten face-bearing pins topple left to right, the last ringing a brass bell; final diagonal cascade and bell |
| strike.curtain | celebrations.strike | Walnut stage shutters part; pins take a synchronized tumble and a ball bows; final bow under a theatre arch |
| strike.score_stamp | celebrations.strike | A brass X stamp lands on a paper scoreboard; pins pop from its edges like approval clerks; final stamped slip |
| strike.constellation | celebrations.strike | Pins rise into ten ivory stars, joined into a bowling-ball constellation; final night diagram above the title |
| spare.last_chair | celebrations.spare | The final pin scrambles onto a chair that the ball politely pulls away; final pin sitting on the floor beside the chair |
| spare.magnet | celebrations.spare | A brass horseshoe magnet retrieves a stubborn corner pin; final pin dangling sideways over SPARE! |
| spare.bookend | celebrations.spare | Two scoreboard bookends close around the last pin, which peeks over the top; final squeezed shelf composition |
| spare.delivery | celebrations.spare | A ball delivers the remaining pin in a small handcart, tipping it into a collection box; final cart and labelled SPARE! box |
| spare.lasso | celebrations.spare | A loose lane-marking ribbon loops around the last pin and gently pulls it offstage; final loop and waving pin |
| boss.surveyor.tape | celebrations.boss_defeated[rival.surveyor] | Measuring tape recoils around the portrait frame; final brass tape loop and amused defeated portrait |
| boss.surveyor.level | celebrations.boss_defeated[rival.surveyor] | A spirit-level bubble escapes its tube and carries the ruler away; final empty level and baffled portrait |
| boss.custodian.sweep | celebrations.boss_defeated[rival.custodian] | A broom sweeps pins past the portrait; one pin waves from the dustpan; final broom/dustpan diagonal |
| boss.custodian.polish | celebrations.boss_defeated[rival.custodian] | A polishing cloth buffs the frame into a winner's mirror; the Custodian concedes with a glint; final polished oval |
| boss.proprietor.receipt | celebrations.boss_defeated[rival.proprietor] | A receipt unrolls past the portrait and ends with a brass PAID stamp; final curling receipt and conceding portrait |
| boss.proprietor.keys | celebrations.boss_defeated[rival.proprietor] | A ring of keys spins down onto a cushion beneath the portrait; final keys presented like a prize |
| boss.old_lou.record | celebrations.boss_defeated[rival.old_lou] | An old score plaque rotates to reveal a new blank record plate; Lou tips his frame like a hat; final paired plaques |
| boss.old_lou.encore | celebrations.boss_defeated[rival.old_lou] | Pins become a tiny applauding audience; Lou's portrait takes a respectful bow; final audience below the portrait |
| boss.custodian_champion.crown | celebrations.boss_defeated[rival.custodian_champion] | A crowned broom lowers a brass wreath around the champion's own portrait; final wreath and two crossed brooms |
| boss.custodian_champion.house_lights | celebrations.boss_defeated[rival.custodian_champion] | Two warm rows of scoreboard bulbs light steadily toward a championship crest; final champion portrait between lit arches |

Boss portraits come from the existing assets/rivals/manifest.json using the
existing RivalArt.portrait(rival_id, state) loader. It respects the authored atlas
regions. Do not substitute regular Custodian for the champion. Rival names are
live context text, never baked into images; title fitting must cover the longest
champion name without clipping. All comeuppance is playful, not cruel.

Source/provenance plan: an original House pixel prop kit (pins with expressions,
ball, brass hardware, paper, stage wood, small confetti), authored specifically
for the canvas. Reuse existing portrait sources unchanged with ledger references.
If generated source art is used, retain original output, exact prompts and hashes;
any derived crops/scaling must be reproducible and documented. No borrowed alley
animations, characters, layouts or stock audio. Record every new source/output
in ASSET-LEDGER.md when created; this plan claims no assets already exist.

Three sound IDs/slots: sound.celebration.house.strike, .spare, .boss_defeated,
under celebration_sounds.strike/spare/boss_defeated. Original deterministic
synthesis: short wood/brass percussion cadence, two-note spare answer, and a
warmer boss fanfare. Peak-normalized PCM with reproducible generator/seed/hash.
Scenes remain silent; AlleyScreen owns playback and the effects-volume setting.

## Motion and CRT standard

Strike 1.8 s, spare 1.6 s, boss 3.0 s. Establish the gag immediately, resolve it
before the final third, and hold the event wording through the last third.
Use bounded prepared sprites/props and small confetti pools, with no per-frame
node creation or random source-pixel shimmer. Share a kit, not one choreography.

Each reduced-motion variant is its own final tableau from the table, held for
its whole duration with identical early/late pixels. No movement, power effect
or animated glow. Reduced flash removes brightness variation; ordinary motion
also has no strobes or repeated full-screen flashes. All titles stay readable.

Final CRT shader target: one cheap pass, fixed subtle scanlines, small barrel
curve, soft edge vignette and restrained phosphor spread. Start from UI-20's
baseline, measure at actual portrait size, and retain its power/flicker parameter
contract. Do not add per-frame noise or extend the scene's lifetime. The shared
screen owns power-on/off and disables them under reduced motion.

Later Leagues follow the same canvas, interface, event lengths, accessibility,
manifest completeness and evidence contract. Their palette, props, jokes and
stings change; UI-A9-N is not implemented here.

## Verification and capture plan

Proposed art journey JUIA9H and reduced companion JUIA9HR must use the real
AlleyScreen with the finished manifest and its existing event context. A review
loop may select each scene deterministically for evidence; real play keeps the
existing uniform picker. Do not alter RNG, rules or saved progress.

- Every variant at its peak in portrait and landscape: 40 normal captures.
- Every variant's distinct reduced still in both orientations: 40 captures;
  compare early/late renders for exact stillness rather than saving redundant files.
- Contact sheets for normal and reduced sets; short sequences for all distinct
  gags, plus reduced-flash checks and text-fit captures for champion names.
- Native J03 strike/spare and J22L01 actual boss wins must exercise the shipping
  trigger/queue/skip paths. Review title visibility and the real portrait.
- Unit contract checks: duration, exactly-once completion, skip/replay, no input
  or audio ownership. Existing uniform selection assertions remain unchanged.
- Required checks: unit/content, J03, J22L01/J22L02 and affected art journeys,
  headless/rendered, physics and web. New captures await frame_post_draw.
- Measure per-variant frame time versus an ordinary roll in the same run;
  report renderer/device, sample counts and percentile limits. Software rendering
  is not a physical-phone performance claim.

No captures committed. Final handoff includes all paths, provenance, frame times,
remaining device limits and the standard above. No new hook is presently needed.
