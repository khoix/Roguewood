# E22-L02-ART — Neon theme handoff

Status: DONE — both asset sessions, live integration validation and visual review.
Codex / `codex/roguewood-build`, High effort. Session 1: `9e91b31`; session 2:
`2671841`. Claude's bindings and layout fixes through `a034d61` are merged
at `ede1f02`. Earlier integration hook requests are resolved.

## Before: scope and provenance

Session 1 listed environment/signage/backdrop IDs for division_01 through
division_08 and championship: 27 bindings, original generated room sheet,
native lettering, retained source/prompt/hashes, nine-room inspector and
portrait/landscape/normal/reduced captures.

Session 2 listed lane/rule visuals, original synthesized music, five UI frames,
two ornaments, normal/reduced flank and trophy.neon; vector/audio sources,
generated trophy provenance and native theme/Clubhouse captures. No external
reference art, donor recording or new third-party license. Exact sources,
prompts and hashes: assets/leagues/neon/source.environment.txt, source.theme.txt
and docs/art/ASSET-LEDGER.md.

## Delivered and integrated

The manifest has 43 bindings and status `integrated`; full ID table in
docs/art/briefs/E22-L02-ART.md.

- Nine distinct rooms, native signs and backdrops. Championship is Division 8
  with championship=true, separate from its ordinary room. Static art; no
  collisions, gameplay input/state, camera or dynamic lights added.
- Long Oil ends at 14.3256 m / 47 ft. Two-Tone ends at 10.3632 m / 34 ft left,
  12.192 m / 40 ft right. Matte diagonal grain and paired outside-board ticks
  distinguish regions beyond colour. House Oil reused; physical deck unchanged.
- Narrow Lane brass/enamel rails replace developmental magenta guards. Strobe's
  dashed sweet and continuous perfect bands use existing .5 zone scale
  (.11/.07 radii above the .06 floor). No rules, grading or timing changes.
- Original music.league.neon.circuit: sixteen bars, 112 BPM, stereo, 22050 Hz,
  34.285714 seconds, circular tails. Peak .65, RMS .136494, seam delta .007593.
- ui.neon.{hud,shop,slip,menu,panel}: five nine-slice frames, existing metrics,
  stepped rail corners/diamond inlays, ivory score slip.
- backdrop.ui.neon.{normal,reduced}: architectural flank traces, four-pixel
  bounded constant-brightness drift or still; behind world/panels, mouse-ignoring.
- trophy.neon: gold pin, cyan/violet arcs, ball and walnut plinth, complete
  crown/base margins; exact Clubhouse filename resolves.

Claude's d19f9f7 binds rooms, signs, finishes, music, five frames and flank to the
live Neon League, restoring House frames when leaving. a034d61 fixes the hand
under the two-seal Champion bar. No hook request remains.

Two delivered ornaments, ui.neon.corner and ui.neon.divider, have no live
consumer, matching House. They are optional kit resources, not an outstanding
request for new UI. tools/author_neon_theme.py reproduces 46 resource/vector/audio
outputs while preserving stage entries. No Wave 13 item art.

## Verification

Final outcomes: artifacts/wave12/final/results.json and WAVE12-CODEX.md.
Unit, content and physics PASS. J22L02ENV, J22L02ART, J22L02RULEART,
J22L02LIVEART and J11ART all PASS headless and rendered on the integrated
state. Reviewed final live Long Oil/Two-Tone and Championship captures plus
native Narrow Lane/Strobe views in portrait/landscape. No technical gap remains.
Godot 4.5.2, Linux Compatibility/llvmpipe, Dummy audio.

- J22L02ENV: native Previous/Next/wrap/reduction controls, 27 stage IDs, nine
  regions, exact signs, stable racks, no collision/animation, both orientations
  and identical reduced world pixels.
- J22L02ART: 43 resources, three finishes/exact boundaries, grayscale dry-region
  differences and identical wet regions, unchanged rack transforms, frame
  metrics/trophy margins, native music/volume/loop wrap, flank drift and
  pixel-identical reduction. Regeneration was byte-identical in session 2.
- J22L02RULEART: all original C13 assertions plus native normal/reduced/landscape
  rail/ring captures. Registered after the Champion layout fix.
- J22L02LIVEART: extends full live Neon journey, keeping all 24 matches,
  independent banks, save/resume, gates, title, earned trophy and attempt-2
  reward checks. Adds exact native signs, cosmetic rooms, authored rivals/seals,
  eight room captures, both feature finishes, paired Champion seals and
  normal/reduced/landscape presentation.
- J11ART: original Clubhouse journey plus exact Neon trophy on the real shelf.

QA/CI additions are add-only and art-shard guarded. No tracked screenshots.
This final integration changes no gameplay/content/project settings or
coordinator UI paths. No hardware audio or physical-device performance claim.
Claude owns the post-merge full integration matrix.

## Owner captures (local, ignored)

- `artifacts/e22-l02-art/environment/rendered/`: contact.png, division_01.png
  through division_08.png, championship.png/reduced.png at 780x1688,
  landscape.png at 1688x780.
- `artifacts/e22-l02-art/theme/rendered/`: house_oil, long_oil, two_tone,
  lane_reduced, lane_landscape, kit_normal, kit_drift, kit_reduced,
  kit_reduced_later, kit_landscape PNGs.
- `artifacts/e22-l02-art/rules/rendered/c13_{narrow_lane,champion}_art_{normal,reduced,landscape}.png`
- `artifacts/e22-l02-art/live/rendered/`: live_d01_opener.png through
  live_d08_opener.png, live_d02_feature.png, live_d03_feature.png,
  live_d08_boss.png, live_champion_normal.png, live_champion_landscape.png,
  j22n_champion.png, j22n_title.png, j22n_attempt2.png.
- `artifacts/e16-art/native/rendered/neon_trophy_shelf_{720,1280}.png`.
- Audio: `assets/leagues/neon/music.league.neon.circuit.wav`.

## Coordinator

Merge the final Codex checkpoint, run the full matrix, then record Wave 12
closed. All assets/hooks are delivered; no further authoring session needed.
Stop at Wave 12. No AV-N1/AV-N2, PR or main push.
