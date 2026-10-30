# E22-L01-ART — House League theme

Implementation: DONE. Codex, codex/roguewood-build, base `80eb775`.
AV-C04 is complete and pushed. Effort: High. This is the Wave 6 art handoff;
Claude owns the live E22-L01 integration in Wave 8.

## Before: scope, stable IDs and provenance

Read House's eight-Division spec, Championship and two-lane pool in
content/leagues/house.json, the roster, E17-L01 handoff and the approved art bible.
No League spec, rules, catalogue flag or live game-flow changes.

Owned drop directory: `assets/leagues/house/`. Manifest maps:
- `environment.league.house.division_01` through `_08`: separate cosmetic scenes.
- `environment.league.house.championship`: a distinct ceremonial scene.
- `signage.league.house.division_01` through `_08` and
  `signage.league.house.championship`: native, readable sign data, separate from
  the illustrations. Exact Division names come from House's spec.
- `lane_visual.lane_condition.house_oil` and `.dry_backend`: separate authored
  material resources. Oil end 12.192 m and deck start 17.288 m match LaneSpec;
  House has controlled sheen, Dry Backend a matte/grain break after the oil.
- `music.league.house.after_hours`: original mellow electronic loop, with authored
  harmony, melody, bass and percussion. No borrowed recordings or samples.

Original generated room sheet and prompt/hash retained unchanged, AtlasTexture
regions only. Nine related architectural compositions, not palette variants:
modest old club arch, restored slatted bay, service gallery, vintage truss room,
star-tile colonnade, brass mezzanine, trophy gallery, grand House hall, then a
separate Championship double arch/banners. Quiet walnut, petrol and brass keep
rack silhouettes clear. Sign lettering is native, never generated/baked text.

Original procedural lane materials and music arrangement; source tools and
provenance recorded. The environment and material assets are preview-only until
Claude binds their IDs. The art inspector will show every Division, Championship,
both lane conditions, reduced/static presentation and music controls. Native
portrait/landscape and contact captures, resource/music validation and unit/content
checks precede DONE. Screenshots stay ignored and CI uploads their folder.

## Delivered binding contract

The source of truth is `assets/leagues/house/manifest.json`, schema 1. Resolve
`assets[id]` to a `res://` path; no asset resolver/global schema change is needed
in this art batch. `stages` contains the eight Divisions in order, followed by the
Championship variant. Use the explicit `championship` boolean: the ninth entry's
Division is 8, so do not select it solely by Division number.

| ID | Drop path / resource |
|---|---|
| `environment.league.house.division_01` … `division_08` | `assets/leagues/house/<id>.tscn`, cosmetic Node3D |
| `environment.league.house.championship` | `assets/leagues/house/<id>.tscn`, cosmetic Node3D |
| `signage.league.house.division_01` … `division_08`, `.championship` | `assets/leagues/house/<id>.tres`, sign data |
| `backdrop.league.house.division_01` … `division_08`, `.championship` | `assets/leagues/house/<id>.tres`, AtlasTexture |
| `lane_visual.lane_condition.house_oil` | `assets/leagues/house/<id>.tres`, ShaderMaterial |
| `lane_visual.lane_condition.dry_backend` | `assets/leagues/house/<id>.tres`, ShaderMaterial |
| `music.league.house.after_hours` | `assets/leagues/house/<id>.wav`, looping AudioStreamWAV |

Scenes reference their own backdrop and signage, so a single environment ID
selects the complete room. Attach one at the lane world origin: +X bowler's right,
+Y up, forward = −Z, meters. The 9×6 m back-wall quad is centered at (0,3,−21),
behind the rack/pit. Sign geometry is near (0,1.62,−20.75); lettering is depth
tested, independent of generated artwork, and contains HOUSE plus DIVISION NN or
CHAMPIONSHIP. Remove the previous scene before installing another. Scenes contain
no camera, lighting, colliders, audio, gameplay input or state. The source is a
front-facing architectural backdrop, not a freely explorable room.

Apply either lane material to the cosmetic lane surface, preserving its physics
material and geometry. The shader computes world-space forward distance and
changes only the backend interval [12.192,17.288) m. House Oil has a polished
backend; Dry Backend has a lighter matte/grain break and subdued wear. The oiled
section and pin deck remain identical. LaneSpec's DECK_ZONE_F is 17.288 m; no
new mechanical boundary or lane condition is introduced. Keep existing aiming
marks and gameplay overlays above the surface when integrating.

Play the music through the existing music bus/settings at integration. The asset
loops in its import metadata; do not use a per-frame restart. Preview defaults to
music off and approximately −18 dB. The original 16-bar 90 BPM arrangement is
42⅔ seconds, stereo 22050 Hz PCM, with circular release/delay tails. Both theme
and lane atmosphere are static in regular/reduced modes: no flashes, moving
reflections or required decorative motion. Turning reduced motion on preserves
all signs and condition information.

## Native inspector and verification

Open `src/presentation/house_theme_preview.tscn` in Godot, or run:

```sh
$GODOT_BIN --path . res://src/presentation/house_theme_preview.tscn
python tools/qa.py e2e --journey J22L01ART
python tools/qa.py e2e --journey J22L01ART --rendered
```

Previous/Next visits each room and wraps; the lane selector switches exact
material IDs. Lane finish shows the oil boundary from above at native 2× pixel
scale. Music toggle and keyboard-accessible volume slider start/mute/restore/stop
the actual player. Native 720×1280 and 1280×720 controls fit without clipping.
J22L01ART drives these controls with input events. It validates all 30 bindings,
exact League Division names, distinct regions/signs, cosmetic scenes, lane
boundaries, preserved pin transforms, audio import duration/stereo/loop mode,
and an actual wrap from near the track end. The native backend pixel difference
is 0.106684 mean summed RGB; oiled-region difference is exactly zero.

Rendered captures under `artifacts/e22-l01-art/rendered/`:
`division_01.png` … `division_08.png`, `championship.png`, `house_oil.png`,
`dry_backend.png`, `reduced.png`, `landscape.png`, `contact.png`. The contact is
composed in Godot from native viewport captures. All nine room captures, the
Championship portrait/landscape, and both finish close-ups were visually checked.
Screenshots are ignored, never committed; CI uploads the folder inside its
existing artifact path list. CI timeout remains 90 minutes.

Local evidence (Godot 4.5.2, Linux Compatibility/llvmpipe, Dummy audio):
- `artifacts/wave6/validation/House-final-headless.log`,
  `House-final-rendered.log`: J22L01ART PASS.
- `artifacts/e22-l01-art/{headless,rendered}/report.json`: checks and native
  lane/audio observations. Headless cleanup lets the audio thread release its
  playback reference; final runs have no leaked-resource errors.
- `House-authoring.json`: byte-identical regeneration of 32 source/derived
  files, PCM peak/DC/RMS/seam measurements. Original PNG is never edited.
- `House-unit.log`, `House-content.log`: final repository unit/content PASS.
- `House-scope.json`: isolated new art/inspector/test plus add-only QA/CI and
  ledger/handoffs; no League spec, catalogue, rules or gameplay-source changes.

The AV-C04-C handoff retains the full Wave 6 physics/regression evidence at
`80eb775`: physics digest `75d1a3c0ceb2f8e458f7788de7e938de194633c1720aca1488b68a21eb310c6f`,
fourteen headless and five affected rendered regressions, J03/J05/J06 baselines.
This isolated preview does not enter those game paths.

## Limits and integration facts

This completes the assigned Wave 6 art delivery; live League selection/camera
composition, bus mixing and device performance belong to Claude's E22-L01 Wave 8
integration. Preview evidence does not claim live League progression, platform
exports, hardware performance or speaker/headphone listening. The software
renderer reports its usual unsupported V-Sync warning. No catalogue or batch
completion flags are set by this theme delivery.

Commit/push is on `codex/roguewood-build`; coordinator integrates through
`claude/roguewood-build`. No PR to main and no owner-review status dependency.
Do not start Wave 7 from this handoff. Next assigned Wave 7 art is recommended
High effort once dispatched; the current Wave 6 scope stops here.
