# E22-L02-ART — Neon theme

Session 1: environment and signage for eight Divisions and the Championship.
Original OpenAI generation, no external donor art; exact prompt and SHA256 in
`assets/leagues/neon/source.environment.txt`. Source remains unaltered. Session
2 adds the remaining assets below; live League integration is still separate.

## IDs and slots

For each suffix `division_01` through `division_08`, plus `championship`:

- `environment.league.neon.<suffix>`: cosmetic Node3D scene.
- `signage.league.neon.<suffix>`: native League/Division lettering data.
- `backdrop.league.neon.<suffix>`: AtlasTexture region from the source sheet.

The manifest maps all 27 IDs explicitly. Its stages preserve Division names
from neon.json and use Division 8 plus `championship=true` for the final room,
matching the House theme contract. Session 1's partial manifest has been extended
by session 2 without removing any of these stage bindings.

## Architecture and presentation

| Stage | Silhouette and material identity |
|---|---|
| 1 | Stepped entry arch, twin tubes, walnut booths |
| 2 | Tall paired light fins and slim brass columns |
| 3 | Round speaker niches and concentric ring canopy |
| 4 | Industrial oil pipes and ribbed service gate |
| 5 | Triangular mirrored facets and diagonal light beams |
| 6 | Raised DJ balcony and tiered speaker towers |
| 7 | Receding arches and tall colonnade |
| 8 | Velvet antechamber and trophy niches |
| Championship | Crown fan, laureled columns and sweeping balconies |

Amber wood and brass retain the club identity; cyan/violet tubes establish
Neon. Architecture, silhouette and material distinguish rooms without relying
on colour. The lower centre stays dark behind native signage and the rack.
The environment scene uses the existing House world-origin convention:
9 x 6 backdrop centred at `(0,3,-21)`, sign in front at about z=-20.7.
The square source cell is presented as a wide stage elevation. Texture sampling
is nearest; the inspector renders the world at half native resolution and
lettering remains separately authored Label3D text, never generated glyphs.

All environments are static in both normal and reduced-motion modes: no
animated lights, TIME shader, particles, collision or rule/input handling.
The reduced inspector control demonstrates the identical still presentation.
These scene backdrops are not the separate UI flank backdrop due in session 2.

## Evidence and integration boundary

`J22L02ENV` exercises actual Previous/Next/wrap and reduction controls, all
resource bindings, League names, scene-only geometry, stable rack transforms,
portrait/landscape control bounds and rendered pixel identity across reduction
and sixty frames. Nine room captures, reduced Championship, landscape and a
contact sheet are written under `artifacts/e22-l02-art/environment/`.

The inspector borrows the existing House Oil floor and Wood rack as context.
That environment inspector does not claim throws, live League navigation or
device feel; session 2 has a separate inspector for Neon lane finishes.
Live binding must follow the coordinator's E22-L02 hook; this session does not
register the manifest in LeagueTheme or change throw_lab.

## Session 2 — lane, rule and UI theme contract

The expanded theme manifest now has 43 bindings and status
`assets_ready_live_theme_hook_pending`. It retains all 27 stage bindings and
adds the following delivered IDs:

| ID | Asset and application |
|---|---|
| `lane_visual.lane_condition.long_oil` | World-space finish: oil ends 14.3256 m / 47 ft on both halves |
| `lane_visual.lane_condition.two_tone` | Left ends 10.3632 m / 34 ft; right 12.192 m / 40 ft |
| `lane_visual.lane_condition.house_oil` | Existing House Oil resource reused for Neon openers |
| `rule_visual.boss_rule.narrow_lane` | Brass/enamel rails at the supplied gutter edge; transverse ivory caps |
| `rule_visual.boss_rule.strobe` | Dashed sweet boundary, continuous perfect boundary and four inward teeth |
| `music.league.neon.circuit` | Original 112 BPM, sixteen-bar stereo loop |
| `ui.neon.{hud,shop,slip,menu,panel}` | Five nine-slice frames; separate native lettering |
| `ui.neon.{corner,divider}` | Two architectural ornaments |
| `backdrop.ui.neon.{normal,reduced}` | Flank scene variants; slow constant-brightness drift or static |
| `trophy.neon` | Gold pin, cyan/violet orbital arcs, three-hole ball and walnut plinth |

Dry lane regions use matte diagonal hatching and cross-grain scuffs; paired
edge ticks show each oil end without placing marks through the aim corridor.
The shader uses world positions so moving a cosmetic slab cannot shift oil
boundaries. Pin deck begins at 17.288 m, unchanged. No collision or physics
material is added. All lane appearances are static in either motion mode.

The rule painter is already called by aim_overlay through its existing
`gutter_edge()` and `zone_scale()` hooks. It replaces developmental magenta
guard lines. Strobe art is threshold-based, not flashing: with scale .5 the
perfect/sweet boundaries are .07/.11, measured from the .06 floor. The existing
contracting ring and grade colour remain; drawing changes no ring timing,
grading, launch, gutter detection or input handling. Ring art is distinct from
the R07 rule badge, whose binding still awaits the champion bar-height fix.

The five UI frames keep the House kit's 64px sources, 12/16px slice borders,
20/24px content insets and 40/48px minimums. Stepped rail corners and diamond
inlays give Neon its own silhouette. The score slip remains ivory with dark
text. `assets/ui/neon/manifest.json` is the binding authority for the kit.
Flank art stays within the outer fifths; the lane corridor is undecorated.
For either reduced-motion or reduced-flash settings use the reduced scene or
set `reduced=true`. Normal drift is bounded to four logical pixels and does not
change brightness. Keep the backdrop behind the world viewport and all panels.

Music uses original motifs, harmonic pads, FM plucks and synthesized drums;
full source and metrics are in `source.theme.txt`. Play the imported forward
loop through existing music settings, using the House theme's quiet base gain.
No per-frame restart, new audio bus or project configuration is needed.

`J22L02ART` adds native lane/music/view controls, material boundaries and
grayscale comparisons, normal/reduced backdrop pixel comparisons, frame resource
contracts, trophy margins and actual audio wrap. J11ART additionally validates
the native Neon trophy shelf texture. `neon_rule_art_journey.gd` preserves all
C13 assertions and adds normal/reduced/landscape rail/ring captures; its
registration awaits the known champion layout fix. None of these previews
claim live environment/lane/music/frame/flank integration or phone performance.
