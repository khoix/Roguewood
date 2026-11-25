extends "res://assets/ui/backdrops/backdrop_base.gd"
## UI-A8, House: a warm old hall at night, seen past the lane. All original, drawn
## in code. Layers, far to near:
## - a night sky that deepens through the Divisions, with stars;
## - a moon that waxes from a crescent (Division 1) to full (the Championship), and
##   arches across the sky: it rises from the trees at the left, crosses, sets behind
##   the trees at the right, and rises again (MOON_CROSSING; owner, 2026-11-25);
## - slow drifting clouds;
## - a pine treeline with a few cabin windows lit;
## - fireflies drifting in the side zones.
## The Championship adds soft, slow fireworks (no flash; none when reduced). The string
## lights, lanterns and bunting stand in the alley itself (src/presentation/alley_interior.gd).
## Features keep to the side zones (about 0.2–0.33 and 0.67–0.8 of the width), which
## stay visible beside the lane in portrait and landscape.
const SKY_TOP := Color("080f1b")
const SKY_MID := Color("122036")
const DUSK := Color("3d2c35")
const NIGHT_LOW := Color("1a2033")
const HILL := Color("0f1b22")
const PINE := Color("0a1418")
const GROUND := Color("0b1215")
const WARM := Color("ffcf7a")
const MOON := Color("f3e6c8")
## The moon's arch: seconds from rising to setting, then below the trees until it rises
## again. A match starts with it a fifth of the way up (and reduced motion holds it there).
const MOON_CROSSING := 180.0
const MOON_BELOW := 20.0
const MOON_START := 0.2

func paint(c: CanvasItem, s: Vector2, t: float) -> void:
	var w := s.x
	var h := s.y
	var hz := floorf(h * horizon)
	var night := 1.0 if championship else (division - 1) / 7.0
	# Sky: deep blue to a warm dusk at the horizon; later Divisions are later at night.
	bands(c, w, 0.0, hz * 0.55, SKY_TOP, SKY_MID, 8)
	bands(c, w, hz * 0.55, hz, SKY_MID, DUSK.lerp(NIGHT_LOW, night * 0.75), 10)
	# Stars, fewer near the dusk; a third twinkle slowly.
	for i in 90:
		var p := Vector2(rnd(i, 1.0) * w, rnd(i, 2.0) * hz * 0.85)
		var bright := 0.35 + 0.55 * rnd(i, 3.0)
		if i % 3 == 0 and t > 0.0:
			bright *= 0.7 + 0.3 * sin(t * (0.5 + rnd(i, 4.0)) + i)
		var size := 2.0 if i % 17 == 0 else 1.0
		px(c, p.x, p.y, size, size, Color(Color("d9e4e6"), bright * (1.0 - p.y / hz * 0.5)))
	# The moon on its arch, drawn before the hills and pines so it rises and sets behind them.
	var along := moon_along(t)
	if along >= 0.0:
		var at := moon_at(along, w, h, hz, floorf(h * sky_top))
		_moon(c, at, 1.0 if championship else (division - 1) / 7.0, _sky_at(at.y, hz, night))
	if championship: _fireworks(c, w, h, t)
	# Clouds: thin bands drifting slowly across.
	for k in 4:
		var length := 50.0 + rnd(k, 5.0) * 70.0
		var y := floorf(hz * (0.45 + 0.13 * k))
		var x := fposmod(rnd(k, 6.0) * w + t * (1.2 + k * 0.5), w + length) - length
		var shade := Color(Color("8496a8"), 0.10 + 0.04 * k)
		px(c, x + 6, y - 1, length - 12, 1, shade)
		px(c, x, y, length, 2, shade)
		px(c, x + 10, y + 2, length - 24, 1, Color(shade, shade.a * 0.6))
	# Far hills, then pines along the horizon, then the dark field.
	for x in range(0, int(w), 2):
		var top := hz - 7.0 - 5.0 * sin(x * 0.035 + 1.3) - 3.0 * sin(x * 0.11)
		px(c, x, top, 2, hz - top + 1, HILL)
	for i in int(w / 7.0) + 2:
		var x := i * 7.0 + rnd(i, 7.0) * 4.0
		var tall := 8.0 + rnd(i, 8.0) * 14.0
		c.draw_colored_polygon(PackedVector2Array([Vector2(x - 4, hz + 1), Vector2(x, hz - tall), Vector2(x + 4, hz + 1)]), PINE)
	bands(c, w, hz, h, GROUND, Color("060a0c"), 6)
	px(c, 0, hz, w, 1, Color(DUSK, 0.35 * (1.0 - night * 0.6))) # mist on the horizon
	# Cabin windows in the trees, warm.
	for i in 5:
		var x := floorf((0.12 + 0.19 * i + 0.05 * rnd(i, 9.0)) * w)
		var lit := 1.0 if t == 0.0 else 0.75 + 0.25 * sin(t * 0.4 + i * 2.1)
		glow(c, Vector2(x, hz - 3), 4.0, WARM, lit)
		px(c, x - 1, hz - 4, 2, 2, Color(WARM, lit))
	# (The lights stand in the alley itself, in 3D: src/presentation/alley_interior.gd.)
	# Fireflies in the side zones.
	for i in 14:
		var zone := 0.18 if i % 2 == 0 else 0.68
		var base := Vector2((zone + rnd(i, 10.0) * 0.15) * w, hz - 20.0 + rnd(i, 11.0) * 60.0)
		var p := base + (Vector2(sin(t * 0.30 + i) * 10.0, cos(t * 0.37 + i * 1.7) * 5.0) if t > 0.0 else Vector2.ZERO)
		var on := 0.6 if t == 0.0 else maxf(0.0, sin(t * 0.6 + i * 2.3))
		if on <= 0.05: continue
		glow(c, p, 3.0, Color("e8f59a"), on)
		px(c, p.x, p.y, 1, 1, Color(Color("f4ffb8"), on))

## How far along its arch the moon is at `t` (0 rising, 1 setting), or -1 while it is
## below the trees.
static func moon_along(t: float) -> float:
	var cycle := fposmod(t + MOON_START * MOON_CROSSING, MOON_CROSSING + MOON_BELOW)
	return cycle / MOON_CROSSING if cycle <= MOON_CROSSING else -1.0

## The moon's centre on its arch: from behind the trees at the left edge, up to its
## peak, down behind the trees at the right. The peak keeps the whole moon below
## `sky_y` (where the HUD ends, in canvas pixels) when the sky allows, but always
## rises well clear of the trees.
const MOON_RADIUS := 9.0
static func moon_at(along: float, w: float, h: float, hz: float, sky_y: float = 0.0) -> Vector2:
	var x := lerpf(w * 0.04, w * 0.96, along)
	var top := maxf(minf(h * 0.08, hz * 0.3), sky_y + MOON_RADIUS + 3.0)
	top = minf(top, hz - 2.0 * MOON_RADIUS - 6.0)
	var y := hz + 6.0 - sin(along * PI) * (hz + 6.0 - top)
	return Vector2(x, y).floor()

## The sky's colour at height y, as the bands paint it (for the moon's dark side).
func _sky_at(y: float, hz: float, night: float) -> Color:
	if y < hz * 0.55: return SKY_TOP.lerp(SKY_MID, clampf(y / (hz * 0.55), 0.0, 1.0))
	return SKY_MID.lerp(DUSK.lerp(NIGHT_LOW, night * 0.75), clampf((y - hz * 0.55) / (hz * 0.45), 0.0, 1.0))

## A moon of `phase` 0 (thin crescent) to 1 (full), with a soft halo; `dark` is the sky
## behind it.
func _moon(c: CanvasItem, at: Vector2, phase: float, dark: Color) -> void:
	var r := MOON_RADIUS
	glow(c, at, 26.0, MOON, 1.2)
	c.draw_circle(at, r, MOON)
	c.draw_circle(at + Vector2(-3, -2), 2.0, Color("d9cba9"))
	c.draw_circle(at + Vector2(2, 3), 1.5, Color("d9cba9"))
	var shift := lerpf(5.0, 2.0 * r + 2.0, phase)
	if shift < 2.0 * r:
		c.draw_circle(at + Vector2(shift, -1.0), r, dark)

## Slow, soft fireworks far in the sky: rings of sparks that open and fade (no flash).
func _fireworks(c: CanvasItem, w: float, h: float, t: float) -> void:
	if t == 0.0: return
	var spots := [Vector2(0.20, horizon * 0.55), Vector2(0.80, horizon * 0.45), Vector2(0.72, horizon * 0.75)]
	var colors := [Color("e9b768"), Color("e98aa0"), Color("8fd6c9")]
	for k in 3:
		var age := fposmod(t / 3.2 + k / 3.0, 1.0)
		if age > 0.7: continue
		var u := age / 0.7
		var centre := Vector2(spots[k].x * w, spots[k].y * h)
		for j in 14:
			var dir := Vector2.from_angle(j * TAU / 14.0)
			var p := centre + dir * (3.0 + u * 18.0) + Vector2(0, u * u * 6.0)
			px(c, p.x, p.y, 1, 1, Color(colors[k], 0.75 * (1.0 - u)))
