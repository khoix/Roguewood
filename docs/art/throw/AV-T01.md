# AV-T01 — held-ball charge

The enamel collar belongs to the held ball, with twelve inset teeth, a compact engraved state tab and stepped, keylined glints. It leaves the ball's material and markings visible. Charging is slate; curve-ready is teal clockwise / coral counterclockwise; full charge is gold with six glints instead of three. The filled teeth also show charge without colour. Dead Straight empties the collar, crosses the ball and says NO SPIN.

`aim_overlay.gd` authors the geometry in rendered-ball units. The screen centre comes from `ball_screen_position()` transformed into overlay coordinates; the radius comes from `_ball_screen_radius()`, which includes `LaneWorld.ball_scale()`. Touch-target accessibility enlargement does not enlarge the art. Normal glints use the held body's actual rotation; there is no independent spin timer, pulse, bloom or looping glow. Either reduced-motion or reduced-flash fixes decorative orientation. The collar still follows the ball and updates its meaningful charge state.

Original deterministic synthesized PCM, generated with the existing local foley tool (no external samples):

```
python3 tools/author_foley.py throw_charge cloth 180 .16
python3 tools/author_foley.py throw_curve_ready glass 660 .24
python3 tools/author_foley.py throw_full_charge glass 990 .38
```

A soft friction onset, short glass-ready accent and higher, longer full accent. Each peaks below -6 dBFS before the existing four-voice mix attenuation. The existing once-per-hold signal owns timing; PresentationAudio owns mute, volume, priorities and voice limits. There is no hold loop. Haptics remain owned by ThrowLab.

JAVT01 holds and swirls through each state at 540×960 in both Depth and Flat, normal / reduced motion / reduced flash. It checks screen anchoring, radius, cue uniqueness, Dead Straight and the existing sound controls. Captures are outputs under `artifacts/av-t01/{headless,rendered}`, never assets. No input, rules, content or simulation changes.
