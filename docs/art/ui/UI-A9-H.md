# UI-A9-H — House alley-screen celebrations

Status: IN_PROGRESS, 2026-11-23. Twenty scene candidates and three sting candidates
are authored; final integration/verification is not complete.
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

## Authored checkpoint, 2026-11-23

All twenty IDs above now have `.tscn` resources, sharing original source geometry
in `house/prop_kit.gd` and distinct choreography in `house/celebration.gd`.
Stings exist beside them and rebuild with `tools/author_house_celebration_stings.py`.
No live manifest slots have been added. JUIA9H/JUIA9HR select candidates through
AlleyScreen's test override: every scene at 10/45/90 percent in both phone
orientations, exact reduced-still comparisons, normal early/late differences,
correct rival atlas identity, natural end/replay/skip, and real J03 strike/spare/
open-frame input with unchanged independent scoring assertions. JUIA9HB uses
actual House boss wins and verifies rival selection and Division Result gating.

Current CRT: static 0.18 scanline strength, 90 rows, 0.06 curvature, 0.35 glow
and 0.35 vignette. The `flicker` uniform remains for UI-20 compatibility but
never modulates brightness. Power belongs to AlleyScreen; scenes own no audio
or input. Final CRT/performance judgment remains part of completion.

Later League standard: retain the UI-20 canvas/interface, silent scenes, context
names, exactly-once completion, duration and distinct still contract above.
Change original palette/props/choreography/stings per League. Use the new
review's deterministic selection without changing production RNG. Record
renderer, draw mode and sample counts beside wall-frame percentiles; on-demand
QA renders are correctness evidence, not a rendering performance benchmark.
No next-League implementation is included.

## Full-render measurements, timed resume 2026-11-23

JUIA9HP and JUIA9HL split the existing native review by orientation and omit
PNG readbacks; they retain all source-frame, natural completion, replay/skip
and actual strike/spare/open-frame scoring assertions. Run each rendered with
`--draw all`. Timing reports are saved after every scene, with `complete:false`
until the whole journey passes. CI runs these on the art shard and uploads
`artifacts/ui-a9-h/` including the reports.

Both runs completed: portrait 177 s, landscape 158 s. Godot 4.5.2, llvmpipe
(LLVM 19.1.7, 256 bits), LP_NUM_THREADS=1, one native renderer running at a time.
Each variant has 97–181 measured native frame intervals; roll baseline has
1,372 samples per orientation. These are wall times including CPU/render
scheduling, not GPU timer measurements or physical-phone acceptance. The roll
fixture uses reduced-motion assist for deterministic scores, while the scene
review uses normal motion and the aim HUD. Consequently the ratio includes
whole-screen/state differences; it does not isolate celebration overhead.

| Orientation | Roll p50 / p95 / p99 ms | Celebration p95 range ms |
|---|---|---|
| Portrait 450×800 | 20.875 / 26.294 / 31.592 | 35.675–69.484 |
| Landscape 800×450 | 21.910 / 28.788 / 37.008 | 28.802–67.716 |

These software-renderer times do not establish a 60 fps phone budget. Matched
aim-screen controls and target-device measurements are the next performance
refinements if judging effect overhead or phone viability. Raw reports and
summary: artifacts/ui-a9-h/profile-{portrait,landscape}/rendered/frame-times.json
and artifacts/ui-a9-h/performance-summary.{json,md}.

| Variant | Portrait n / p95 ms | Landscape n / p95 ms |
|---|---|---|
| boss_custodian_champion_crown | 181 / 40.005 | 181 / 35.305 |
| boss_custodian_champion_house_lights | 181 / 40.526 | 181 / 37.011 |
| boss_custodian_polish | 181 / 38.920 | 181 / 38.986 |
| boss_custodian_sweep | 181 / 39.965 | 181 / 33.653 |
| boss_old_lou_encore | 181 / 36.723 | 181 / 32.170 |
| boss_old_lou_record | 181 / 39.646 | 181 / 39.644 |
| boss_proprietor_keys | 181 / 39.054 | 181 / 34.356 |
| boss_proprietor_receipt | 181 / 38.067 | 181 / 32.062 |
| boss_surveyor_level | 181 / 45.701 | 181 / 34.291 |
| boss_surveyor_tape | 181 / 38.744 | 181 / 40.225 |
| spare_bookend | 97 / 38.826 | 97 / 67.716 |
| spare_delivery | 97 / 35.884 | 97 / 30.534 |
| spare_lasso | 97 / 35.675 | 97 / 36.929 |
| spare_last_chair | 97 / 49.302 | 97 / 38.890 |
| spare_magnet | 97 / 35.967 | 97 / 45.032 |
| strike_constellation | 109 / 65.379 | 109 / 52.664 |
| strike_curtain | 109 / 65.263 | 109 / 42.143 |
| strike_domino | 109 / 69.484 | 109 / 28.802 |
| strike_pinwheel | 109 / 45.741 | 109 / 36.520 |
| strike_score_stamp | 109 / 50.574 | 109 / 55.384 |

Sound test JUIA9HA uses ephemeral theme entries to verify the production
AlleyScreen → theme → mixer path, correct streams, effects gain, Mute, zero
volume and uninterrupted music. It does not change the shipping manifest.
The final scene holds its portrait as `texture`; path-backed atlas metadata
keeps PERF-2 reloadable without retaining originals. See the ledger generator.


## Phone-size polish and review index — 2026-11-23 late resume

The final staging pass fixes supported/visible spare pins, constellation head
clipping during ascent, and boss prop/name/title collisions. Stable IDs, event
lengths, source portraits and all reduced still identities remain unchanged.

Run JUIA9HM rendered for eight beats (0/10/20/30/45/60/75/90 percent) under default
flash settings; JUIA9H still covers normal motion with reduced flash, and JUIA9HR
covers both accessibility options. All inherit real strike/spare/open scoring,
natural completion, skip/replay and source-frame motion/still assertions.
JUIA9HM's separate 600-second budget covers 320 full-phone captures plus native
CRT crops; original review and performance timeouts are unchanged. Capture only
once per frame, and derive both full frame and crop from that same readback.
Convert logical layout coordinates through the viewport's final transform first:
the game lays out at 540×960 or 1280×720 while evidence is 450×800 or 800×450.

After JUIA9HM and JUIA9HR rendered, run:
`python3 tools/review_house_celebrations.py` (Pillow). It requires the complete set,
checks the reduced CRT stills, and writes artifacts/ui-a9-h/review/index.html,
capture-index.json, 80 eight-/three-beat sheets and four orientation/mode contact
sheets. Review native crops and click through to the whole phone screenshot.
Held timed poses show choreography; they do not claim a live motion recording,
actual-phone validation, or capture-only rendering-performance numbers.

The earlier full-draw timing table belongs to the previous staging revision.
Do not relabel it as a remeasurement of this polish. Stings remain technically
verified but not subjectively auditioned; live manifest entries remain absent.
