# E11 source and provenance register

All paths below are original source assets, not screenshots of the game. Captures
belong in ignored `artifacts/e11/` and must never be committed.

| Source | Origin / date | Rights and status |
|---|---|---|
| `assets/art_direction/lane.png` | OpenAI image generation, 2026-10-26; original Roguewood prompt, corrected rack edit | Generated candidate; no third-party reference image used. Not approved final art or separately rigged equipment. |
| `assets/art_direction/card-art.png` | OpenAI image generation, 2026-10-26; five equal-width illustration panels | Generated candidate; original matte pin, copper pin, ghost ball, echo fork and pin crown. Not final catalogue assets. |
| `assets/art_direction/still.gd` | Original GDScript authored for this repository | Native review composition and labels; follows repository licensing status. |
| Native fallback typography | Godot 4.5.2 bundled Noto Sans | SIL Open Font License 1.1, bundled with engine. No font binary added. See Godot third-party license notices. |

Generated output is governed by the applicable OpenAI service terms; this register
does not claim exclusive copyright or a separate third-party asset license.
No copied Balatro/Pokémon art, brand marks, audio, downloaded textures or external
fonts. The repository has no project-wide LICENSE at authoring time; no license
grant is invented here. Resolve distribution licensing before release.

## Reproduction briefs

Lane: elevated behind-ball worn cosmic bowling alley, warm maple, ivory/red,
engraved brass and dark enamel pins, teal marbled three-hole ball, indigo arch
architecture, gold pendants, restrained cyan gutter lights, celestial mural.
Portrait 1024×1536. No UI or text. First image had only eight readable heads;
an image edit requested exactly ten distinct heads in regulation 1/2/3/4 rows.
Accepted candidate was inspected for ten heads; this is not physics geometry.

Cards: single wide atlas, five equal-width panels, no text/frames; matte ivory
pin on parquet, engraved copper pin, cyan-phase ghost ball, gold tuning fork
with echo rings, gold crown of ivory pins orbiting teal planet. Increasing
material complexity, crisp pixel clusters, dark backing. AtlasTexture regions
select each fifth without modifying the original image.

Prompts and generator are not deterministic asset build inputs. The checked-in
PNG files are the reproducible source; SHA256 values live in `assets.json`.
Godot labels and frame geometry are deterministic and do not use generated text.
