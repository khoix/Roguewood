# E22-L02-ART — Neon theme handoff

Overall IN_PROGRESS: both sessions' assets are delivered; live theme binding
and the inherited C13 layout blocker remain. Session 1 is `9e91b31`; session 2
starts from that commit. Codex, `codex/roguewood-build`, High effort. Latest
fetched coordinator commit is still `97d6c50`, already merged at `9d1fe69`.
The additional merge check returned already up to date; no rebase/force push.

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
All 27 environment/signage/backdrop IDs remain; session 2 extends the manifest
to 43 bindings. Each scene references its own
sign and texture. Championship is Division 8 with `championship=true`, separate
from Division 8's ordinary stage. Scene world origin/geometry matches House:
back-wall quad 9 x 6 m centred `(0,3,-21)`, native sign near `(0,1.62,-20.75)`.
No collisions, physics, gameplay input, state, camera or light nodes are added
by an environment. All room lighting is static artwork in both motion modes.

Source: unmodified 1254-square PNG, nine 418-square cells. Each AtlasTexture
insets 3 pixels per edge. Source hash, prompt and extraction details:
`assets/leagues/neon/source.environment.txt`; design/binding brief:
`docs/art/briefs/E22-L02-ART.md`. No captures are committed.

**Integration request to Claude:** the complete asset manifest is now ready at
`assets/leagues/neon/manifest.json`, marked
`assets_ready_live_theme_hook_pending`. Lane/music sections are populated.
Please add `league.neon` to LeagueTheme's manifest map and load the theme for
the live Neon content set. Existing stage/dress_lane/play_music methods can
consume these entries. Preserve Championship's Division-8 boolean distinction,
existing music settings and cosmetic-only lane assignment. Session 1's inspector
keeps its House Oil context; the new theme inspector switches all three finishes.

The UI and flank need their own coordinator binding: select frames from
`assets/ui/neon/manifest.json` for Neon HUD/shop/slip/menu/panel consumers;
choose `backdrop.ui.neon.normal` or `.reduced`, or set the script's `reduced`
property for either reduction option. Keep the flank behind panels/world and
mouse-ignoring. The current House UI theme and throw_lab are unchanged here.

The R07 champion bar-height blocker remains open and is independent of these
assets. See E21-R07.md for the exact dimensions, failing J03C13 and draft art
journeys. No coordinator-owned layout, rules or League content was changed.

## Session 2 assets and hooks

See the full ID table in `docs/art/briefs/E22-L02-ART.md`. Before authoring,
the bounded scope was lane/rule visuals, original music, five UI frame slots,
normal/reduced flank and the Neon trophy, with original vector/audio sources,
generated trophy provenance and native theme/Clubhouse captures.

- Long Oil ends at 14.3256 m / 47 ft. Two-Tone ends at 10.3632 m / 34 ft on
  the left and 12.192 m / 40 ft on the right. Dry grain hatching, matte finish
  and twin outside-board ticks distinguish them beyond colour. House Oil reuses
  its existing material. The deck and physical geometry remain unchanged.
- Narrow Lane brass/enamel rails replace developmental magenta lines in
  aim_overlay. Strobe's dashed sweet band and continuous perfect band use the
  existing .5 zone scale, giving .11/.07 radii above the .06 floor. These are
  already bound through existing art hooks, with no input/rules/physics edits.
- `music.league.neon.circuit`: original 16-bar 112 BPM stereo loop, 34.285714 s,
  22050 Hz PCM; synthesized pads, plucks, bass and percussion, circular tails.
  Peak .65, RMS .136494, seam delta .007593. Native player looping is checked;
  no hardware speaker/headphone listening or device performance is claimed.
- `ui.neon.{hud,shop,slip,menu,panel}`: matching nine-slice metrics with new
  stepped rail corners/diamond inlays. Ivory score slip retains dark lettering.
- `backdrop.ui.neon.{normal,reduced}`: architectural traces outside the central
  lane corridor, slow four-pixel bounded drift at constant brightness, frozen
  by reduction. No game state or input.
- `trophy.neon`: generated gold pin with cyan/violet curve arcs, three-hole ball
  and walnut plinth. A framing edit restores clear crown/base margins. The
  existing Clubhouse resolver binds the filename now; no progression edits.

`tools/author_neon_theme.py` reproduces resource/vector/audio outputs while
preserving the nine stage entries. Sources/hashes/prompts are recorded in
`assets/leagues/neon/source.theme.txt` and ASSET-LEDGER. No Wave 13 item art.

## Session 1 verification and owner captures

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

## Session 2 verification and captures

Pinned Godot 4.5.2, Linux Compatibility/llvmpipe, Dummy audio. PASS:

- `qa.py unit`, `content`, `physics`; physics digest remains
  `75d1a3c0ceb2f8e458f7788de7e938de194633c1720aca1488b68a21eb310c6f`.
- J22L02ART and J22L02ENV headless/rendered. All 43 resources load, all 27
  environment IDs stay distinct, all three finishes match LaneSpec boundaries,
  ten rack transforms stay unchanged. The extended environment test preserves
  its 27-stage-asset check while allowing the new non-stage manifest entries.
- Two-Tone left dry-region mean grayscale difference versus Long Oil is
  .040557; right wet and upstream oil regions are pixel-identical (0 difference).
  Long Oil beyond 40 ft differs from Two-Tone's dry right by .051417 grayscale.
  Reduction preserves lane pixels exactly.
- Five frame sizes/insets/tiled edges, trophy visible alpha margins, native
  mode/finish/music/volume controls, actual 34.285714 s audio wrap. Reduced flank
  pixels stay identical at different phases; normal drift changes only flanks
  and leaves the central corridor unchanged. Final runs include the bound that
  keeps traces outside the centre on narrower canvases.
- JAVT01 and J02 headless/rendered: shared charge art, aiming and input remain.
- Expanded J11ART headless/rendered: original two-stage Clubhouse journey plus
  exact Neon trophy resource on the real shelf in both orientations.
- Regeneration of 46 resource/vector/audio outputs is byte-identical; unchanged
  session-1 stages. Ownership scan finds no prohibited paths or tracked captures.

**Still failing:** J03C13 headless/rendered reproduces only the known two-rule
bar overlap, measured at `(12,12), (452,136)`. All original physics/score/bank
checks still run. The additional `neon_rule_art_journey.gd` retains every C13
check and exercises native normal/reduced/landscape rail/ring captures, hiding
and restoring assist controls through Options. It is kept unregistered until
the inherited layout failure is fixed. Both final extension runs fail only that
same bar assertion; all new art/mode checks and inherited bank checks pass.
Reviewed final lane/kit/trophy captures and both native rule views in portrait
and landscape. No check is deleted or suppressed.
The initial draft's sweet-threshold expectation was corrected from .10 to .11;
the art always read the correct LaneSpec function. This is not a full-wave pass.
J03/J05 standalone score baselines remain as verified in R07; they were not
rerun for this cosmetic-only overlay change. No full historical art-matrix or
hardware audio/device validation is claimed.

Final local evidence:

- `artifacts/e22-l02-art/theme/rendered/`: `house_oil`, `long_oil`, `two_tone`,
  `lane_reduced`, `lane_landscape`, `kit_normal`, `kit_drift`, `kit_reduced`,
  `kit_reduced_later`, `kit_landscape` PNGs; report.json includes pixel/audio data.
- `artifacts/e22-l02-art/rules/{headless,rendered}/journey.log` and rendered
  `c13_{narrow_lane,champion}_art_{normal,reduced,landscape}.png`: native art
  evidence alongside the inherited champion layout failure.
- `artifacts/e16-art/native/rendered/neon_trophy_shelf_{720,1280}.png`: unearned
  Neon trophy, correctly dimmed and explicitly labelled by the real shelf.
- `artifacts/e22-l02-art/validation/`: every QA log, session2-results.json,
  final J22L02ART logs, rule-art-results.json, authoring.json and scope report.

New CI art step is shard-guarded; qa.py/CI edits add only. No screenshots are
committed. The only live presentation code edit is aim_overlay's rail/ring
drawing; catalogue, content, rules, simulation, input and project settings
remain untouched. Renderer V-Sync and a physics Jolt job-pool warning appeared;
neither changed the successful physics digest or native assertions above.

## Exact resume — integration and completion (High)

1. Fetch origin; merge the latest `origin/claude/roguewood-build` with a merge
   commit before any journey touching Options/reveals/purchases/Clubhouse.
   If the R07 bar-height fix has landed, follow E21-R07.md to enable Strobe,
   register the two native art journeys and validate R07 without dropping checks.
2. Integrate Claude's environment/lane/music and UI/flank bindings requested
   above. All assets exist; do not regenerate them or begin another art batch.
3. Register `neon_rule_art_journey.gd` only once its inherited champion layout
   assertion passes, using neon_c13 and the C13 success marker. Add live-theme
   assertions/captures to a J22L02 art extension after its hooks exist. Keep all
   original bank, geometry, progression, reduced-motion and layout checks.
4. Re-run unit/content and affected journeys headless/rendered, record remaining
   gaps accurately, update this handoff and WAVE12-CODEX index, push, verify
   remote SHA and clean tree, report batch/SHA. No AV-N1 or AV-N2.

Push targets only `codex/roguewood-build`; no pull request or main push.
