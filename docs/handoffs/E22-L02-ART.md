# E22-L02-ART — Neon theme handoff

Overall IN_PROGRESS. Session 1 (environment/signage) DONE; session 2 remains.
Codex, `codex/roguewood-build`, base `5566b6b`. Recommended effort: High for both
theme sessions. Latest fetched coordinator commit is `97d6c50`, already merged
at `9d1fe69`; no new coordinator changes were available when this session began.

## Before: scope, sources and evidence

Bounded session 1 IDs, for `division_01` through `division_08` and `championship`:

- `environment.league.neon.<suffix>`: nine cosmetic scenes.
- `signage.league.neon.<suffix>`: nine native sign resources.
- `backdrop.league.neon.<suffix>`: nine atlas textures.

Plan: an original nine-room image sheet, separate native lettering, source and
prompt retained, provenance in ASSET-LEDGER. Read the Neon spec and E17-L02,
E22-L02 and House theme handoffs. The art bible's wood/brass club foundation
continues into cyan/violet light and distinct stage architecture. No borrowed
art, fonts or recordings introduced.

Planned and delivered verification: `J22L02ENV`, native inspector navigation
over all nine scenes, normal/reduced motion, portrait 780x1688 and landscape
1688x780; contact sheet, exact ID/sign bindings and cosmetic-only geometry.
No live Options/shop/reveal journey was edited in this session.

## Delivery and coordinator contract

`assets/leagues/neon/manifest.json` follows House's schema 1 stage/asset shape.
All 27 environment/signage/backdrop IDs resolve. Each scene references its own
sign and texture. Championship is Division 8 with `championship=true`, separate
from Division 8's ordinary stage. Scene world origin/geometry matches House:
back-wall quad 9 x 6 m centred `(0,3,-21)`, native sign near `(0,1.62,-20.75)`.
No collisions, physics, gameplay input, state, camera or light nodes are added
by an environment. All room lighting is static artwork in both motion modes.

Source: unmodified 1254-square PNG, nine 418-square cells. Each AtlasTexture
insets 3 pixels per edge. Source hash, prompt and extraction details:
`assets/leagues/neon/source.environment.txt`; design/binding brief:
`docs/art/briefs/E22-L02-ART.md`. No captures are committed.

**Integration request to Claude:** the room/sign assets are ready to bind by ID.
This manifest is explicitly `delivery_status=environment_signage_only`; its
lane/music sections are empty. Complete those in Codex session 2 before enabling
the whole theme through `LeagueTheme.for_league("league.neon")` and the lab's
theme-loading branch. If integrating rooms earlier, keep music/lane access
guarded against missing entries. Do not describe this checkpoint as a complete
live Neon theme. The inspector uses the existing House Oil floor for context.

The R07 champion bar-height blocker remains open and is independent of these
assets. See E21-R07.md for the exact dimensions, failing J03C13 and draft art
journeys. No coordinator-owned layout, rules or League content was changed.

## Verification and owner captures

Godot 4.5.2, Linux Compatibility/llvmpipe. PASS:

- `python3 tools/qa.py unit` and `content`.
- `python3 tools/qa.py e2e --journey J22L02ENV`, headless and `--rendered`.
- Native Next/Previous/wrap input, all 27 resources, nine distinct regions,
  exact Division names/signs, unchanged ten-pin transforms across room changes,
  no collisions/animations/TIME shader, both orientations' control bounds and
  full backdrop corners in view. Landscape framing was corrected after visual
  review caught the clipped crown; final assertions prevent that regression.
- Rendered normal/reduced world pixels are identical, including after 60 frames.

New CI step is art-shard guarded; qa.py and CI changes are add-only. No existing
journey or check was removed. This isolated inspector does not enter live run
paths. Existing R07 evidence retains the unchanged physics digest and J03/J05
baselines; those were not rerun for this environment-only delivery. Known
J03C13 failure at the current merged coordinator UI remains unresolved, so this
is not a passing full-wave close.

Local evidence (ignored; regenerate with the commands above):

- `artifacts/e22-l02-art/environment/rendered/contact.png`: all nine rooms.
- Same folder: `division_01.png` through `division_08.png` at 780x1688.
- `championship.png`, `reduced.png`: normal/static Championship at 780x1688.
- `landscape.png`: complete Championship elevation at 1688x780.
- `environment/{headless,rendered}/report.json` and `journey.log`: assertions.
- `artifacts/e22-l02-art/validation/`: copied unit/content and journey logs.

Reviewed the actual native contact sheet and Championship in both orientations.
The inspector establishes asset readiness; live camera composition, throws,
League transitions and phone hardware still need the integration checks.
The renderer's unsupported V-Sync warning is unchanged from earlier art runs.

## Exact resume — session 2 (High)

1. Fetch origin; merge the latest `origin/claude/roguewood-build` with a merge
   commit before any journey touching Options/reveals/purchases/Clubhouse.
   If the R07 bar-height fix has landed, follow E21-R07.md to enable Strobe,
   register the two native art journeys and validate R07 without dropping checks.
2. List session 2's IDs/slots, original source/provenance plan and captures.
   Deliver Long Oil (47 ft), Two-Tone (left dry from 34 ft, non-colour cues),
   Narrow Lane edge/rail, Strobe narrowed ring treatment, original music,
   Neon frame-kit variant, flank backdrop/reduced-motion variant and `trophy.neon`.
   Preserve the existing environment/signage coverage when extending the manifest.
3. Request any missing binding hooks from Claude through this handoff. Respect
   input/rules/simulation and shared-UI ownership; do not alter them to consume
   art. Extend the theme inspector and add live League/C13 art coverage once
   hooks exist, maintaining all inherited gameplay/layout checks.
4. Re-run unit/content and affected journeys headless/rendered, record remaining
   gaps accurately, update this handoff and WAVE12-CODEX index, push, verify
   remote SHA and clean tree, report batch/SHA. No AV-N1 or AV-N2.

Push targets only `codex/roguewood-build`; no pull request or main push.
