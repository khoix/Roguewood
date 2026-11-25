extends "res://assets/ui/backdrops/backdrop_base.gd"
## UI-A8, Neon: the city at night beyond the alley. All original, drawn in code.
## Layers, far to near:
## - a violet sky with a magenta haze at the horizon, and a soft colour sweep;
## - a far skyline with lit windows, a few changing slowly;
## - two slow searchlights;
## - near buildings in the side zones, each with a neon sign for its Division's
##   room (its art intent), whose tubes breathe gently;
## - a neon grid floor receding to the horizon (the celebrations' floor).
## The Championship turns the signs and lights gold. No strobe in any mode. Under
## `reduced` (reduced motion, or reduced flash) everything holds still.
const SKY_TOP := Color("07051a")
const SKY_MID := Color("1a0f3d")
const HAZE := Color("4a1656")
const BUILDING := Color("130c2c")
const NEAR := Color("0d0820")
const GRID := Color("3a2a7a")
const MAGENTA := Color("ff4fd8")
const CYAN := Color("3ff2ff")
const VIOLET := Color("b48cff")
const GOLD := Color("f5cb69")
const WHITE := Color("fff6ff")

func paint(c: CanvasItem, s: Vector2, t: float) -> void:
	var w := s.x
	var h := s.y
	var hz := floorf(h * 0.47)
	var main: Color = GOLD if championship else MAGENTA
	var second: Color = WHITE if championship else CYAN
	bands(c, w, 0.0, hz * 0.6, SKY_TOP, SKY_MID, 8)
	bands(c, w, hz * 0.6, hz, SKY_MID, HAZE.lerp(Color("5a3a1a"), 0.5) if championship else HAZE, 10)
	# A few far stars, dimmed by the city glow.
	for i in 40:
		px(c, rnd(i, 21.0) * w, rnd(i, 22.0) * hz * 0.5, 1, 1, Color(VIOLET, 0.25 + 0.35 * rnd(i, 23.0)))
	# The colour sweep: a soft band of light crossing the sky (none when still).
	if t > 0.0:
		var x := fposmod(t * w / 16.0, w * 1.6) - w * 0.3
		for k in 6:
			px(c, x + k * 4.0, 0, 4, hz, Color(main.lerp(second, k / 5.0), 0.025))
	# Searchlights from behind the skyline, slowly sweeping.
	for side in [0, 1]:
		var origin := Vector2(w * (0.22 if side == 0 else 0.78), hz)
		var swing := 0.0 if t == 0.0 else sin(t * 0.33 + side * 2.0) * 0.28
		var angle := -PI / 2.0 + (-0.35 if side == 0 else 0.35) + swing
		var dir := Vector2.from_angle(angle)
		var normal := dir.orthogonal()
		var tip := origin + dir * h * 0.6
		c.draw_colored_polygon(PackedVector2Array([origin - normal, tip - normal * 14.0, tip + normal * 14.0, origin + normal]),
			Color(second if side == 0 else main, 0.06))
	# The far skyline, shorter near the middle (behind the lane), taller at the sides.
	var x := 0.0
	var i := 0
	while x < w:
		var bw := 7.0 + floorf(rnd(i, 24.0) * 12.0)
		var centre := absf((x + bw * 0.5) / w - 0.5) * 2.0
		var bh := 8.0 + rnd(i, 25.0) * 26.0 + centre * 30.0
		px(c, x, hz - bh, bw - 1.0, bh + 1.0, BUILDING)
		for wy in range(int(hz - bh + 3.0), int(hz - 2.0), 3):
			for wx in range(int(x + 2.0), int(x + bw - 2.0), 3):
				var key := float(wy * 131 + wx * 7)
				var on := rnd(key, 26.0) < 0.28
				if t > 0.0 and rnd(key, 27.0) < 0.04:
					on = fposmod(t / (6.0 + rnd(key, 28.0) * 8.0) + rnd(key, 29.0), 1.0) < 0.5
				if on:
					var pick := rnd(key, 30.0)
					px(c, wx, wy, 1, 1, Color(CYAN if pick < 0.4 else (MAGENTA if pick < 0.7 else GOLD), 0.55))
		x += bw
		i += 1
	# The grid floor, receding to the vanishing point behind the lane.
	bands(c, w, hz, h, Color("0c0822"), Color("05030f"), 6)
	var scroll := 0.0 if t == 0.0 else fposmod(t * 0.35, 1.0)
	for k in 9:
		var f := (k + scroll) / 9.0
		var y := hz + pow(f, 2.0) * (h - hz)
		px(c, 0, y, w, 1, Color(GRID, 0.35 + 0.55 * f))
	for k in range(-10, 11):
		c.draw_line(Vector2(w * 0.5 + k * 6.0, hz), Vector2(w * 0.5 + k * w * 0.11, h), Color(GRID, 0.55), 1.0)
	px(c, 0, hz, w, 1, Color(main, 0.5))
	# Near buildings in the side zones, each with the Division's sign.
	for side in [0, 1]:
		var bx := w * (0.18 if side == 0 else 0.64)
		var bw := w * 0.18
		var top := floorf(h * 0.18)
		px(c, bx, top, bw, hz - top + 2.0, NEAR)
		c.draw_line(Vector2(bx, top), Vector2(bx + bw, top), Color(VIOLET, 0.35), 1.0)
		var breathe := 1.0 if t == 0.0 else 0.8 + 0.2 * sin(t * 1.3 + side * 1.7)
		var sign_at := Vector2(bx + bw * 0.5, top + (hz - top) * 0.38)
		_sign(c, sign_at, side, main, second, breathe)

## The Division's sign: its room's motif in neon tubes (E22-L02's art intents).
func _sign(c: CanvasItem, at: Vector2, side: int, main: Color, second: Color, lit: float) -> void:
	var color: Color = main if side == 0 else second
	var shapes: Array = []
	match 9 if championship else division:
		1: # entry lounge: a cocktail glass
			shapes = [[Vector2(-7, -6), Vector2(7, -6), Vector2(0, 2), Vector2(-7, -6)], [Vector2(0, 2), Vector2(0, 8)], [Vector2(-4, 8), Vector2(4, 8)]]
		2: # precision gallery: a crosshair
			shapes = [_ring(Vector2.ZERO, 7.0), [Vector2(-10, 0), Vector2(10, 0)], [Vector2(0, -10), Vector2(0, 10)]]
		3: # listening room: equaliser bars
			for k in 5:
				var tall: float = [6.0, 10.0, 14.0, 9.0, 5.0][k]
				shapes.append([Vector2(-10 + k * 5, 7), Vector2(-10 + k * 5, 7 - tall)])
		4: # oil hall: a drop
			shapes = [[Vector2(0, -9), Vector2(5, 0), Vector2(4, 5), Vector2(0, 7), Vector2(-4, 5), Vector2(-5, 0), Vector2(0, -9)]]
		5: # prism salon: a prism and its fan
			shapes = [[Vector2(-8, 6), Vector2(0, -8), Vector2(8, 6), Vector2(-8, 6)], [Vector2(8, 0), Vector2(13, -3)], [Vector2(8, 2), Vector2(13, 2)], [Vector2(8, 4), Vector2(13, 7)]]
		6: # DJ balcony: a record
			shapes = [_ring(Vector2.ZERO, 8.0), _ring(Vector2.ZERO, 3.0), [Vector2(6, -9), Vector2(11, -2)]]
		7: # colonnade: receding arches
			for k in 3:
				var r := 8.0 - k * 2.5
				shapes.append(_arch(Vector2(0, 7), r, 14.0 - k * 4.0))
		8: # title antechamber: a trophy
			shapes = [[Vector2(-6, -7), Vector2(6, -7), Vector2(4, 0), Vector2(-4, 0), Vector2(-6, -7)], [Vector2(0, 0), Vector2(0, 5)], [Vector2(-5, 7), Vector2(5, 7)]]
		_: # the Championship: a crown
			shapes = [[Vector2(-9, 6), Vector2(-9, -4), Vector2(-4, 1), Vector2(0, -8), Vector2(4, 1), Vector2(9, -4), Vector2(9, 6), Vector2(-9, 6)]]
	for shape in shapes:
		var points := PackedVector2Array()
		for p in shape: points.append((at + p).floor())
		for wide in [5.0, 3.0]:
			c.draw_polyline(points, Color(color, 0.12 * lit), wide)
		c.draw_polyline(points, Color(color.lerp(WHITE, 0.3), lit), 1.0)
	glow(c, at, 16.0, color, lit)

static func _ring(centre: Vector2, r: float) -> Array:
	var out := []
	for k in 17: out.append(centre + Vector2.from_angle(k * TAU / 16.0) * r)
	return out

static func _arch(base: Vector2, r: float, tall: float) -> Array:
	var out := [base + Vector2(-r, 0), base + Vector2(-r, -tall + r)]
	for k in 9: out.append(base + Vector2(0, -tall + r) + Vector2.from_angle(PI + k * PI / 8.0) * r)
	out.append(base + Vector2(r, 0))
	return out
