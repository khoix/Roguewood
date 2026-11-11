# E22-L02-ART — Neon theme

Session 1: environment and signage for eight Divisions and the Championship.
Original OpenAI generation, no external donor art; exact prompt and SHA256 in
`assets/leagues/neon/source.environment.txt`. Source remains unaltered. This is
a partial theme delivery, not the live League integration or session 2 assets.

## IDs and slots

For each suffix `division_01` through `division_08`, plus `championship`:

- `environment.league.neon.<suffix>`: cosmetic Node3D scene.
- `signage.league.neon.<suffix>`: native League/Division lettering data.
- `backdrop.league.neon.<suffix>`: AtlasTexture region from the source sheet.

The manifest maps all 27 IDs explicitly. Its stages preserve Division names
from neon.json and use Division 8 plus `championship=true` for the final room,
matching the House theme contract. `delivery_status=environment_signage_only`
marks the partial manifest; lane and music slots await session 2.

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
It does not claim Neon lane art, throws, live League navigation or device feel.
Live binding must follow the coordinator's E22-L02 hook; this session does not
register the incomplete manifest in LeagueTheme or change throw_lab.
