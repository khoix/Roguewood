extends Control
## UI-24 (owner, 2026-11-19): one picture for Talk the Talk, drawn from its spec in
## content/glossary.json (kinds in Glossary.KINDS). Drawn, not painted, in the
## House palette, and in the game's own visual language: the rack is the frame
## review's (roll 1 orange, roll 2 blue, a standing pin ivory), the ring's grades
## are the target ring's colours, cards are the card faces' icons, rivals and
## trophies are their Clubhouse art. Pictures of a throw follow the player's hand.
const Lane = preload("res://src/simulation/lane_spec.gd")
const BOX := Vector2(168, 120) # the drawing's own units, scaled to fit
const IVORY := Color("f4e6cd")
const BRASS := Color("e7bc70")
const SEA_GLASS := Color("95d9cb")
const INK := Color("101820")
const MUTED := Color("9aa8a6")
const PIN_RED := Color("c8463c")
const ROLL_COLORS := [Color(0.95, 0.55, 0.25), Color(0.35, 0.8, 1.0)] # as ScorePanel
const RING_COLORS := {"clean": Color(1.0, 1.0, 1.0), "sweet": Color(0.3, 0.95, 0.85), "perfect": Color(1.0, 0.8, 0.2)} # as ThrowLab
const MULT_RED := Color(1.0, 0.45, 0.45)
const SCORE_GOLD := Color(1.0, 0.9, 0.3)
const CARD_DIR := "res://assets/ui/cards/"

var spec: Dictionary = {}
var handedness := "right" # pictures of a throw are mirrored for a left-hander
var _textures := {}

func _init(diagram: Dictionary = {}, hand: String = "right") -> void:
	spec = diagram
	handedness = hand
	custom_minimum_size = BOX
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func kind() -> String:
	return String(spec.get("kind", ""))

func set_handedness(hand: String) -> void:
	if hand == handedness: return
	handedness = hand
	queue_redraw()

## +1 for a right-hander, -1 for a left-hander: the side a throw comes from.
func side() -> float:
	return -1.0 if handedness == "left" else 1.0

func _draw() -> void:
	var s := minf(size.x / BOX.x, size.y / BOX.y)
	draw_set_transform((size - BOX * s) * 0.5, 0.0, Vector2(s, s))
	_rounded(Rect2(Vector2.ZERO, BOX), Color(INK, 0.85), 8.0)
	match kind():
		"rack": _rack()
		"sheet": _sheet()
		"ladder": _ladder()
		"target": _target()
		"lane": _lane()
		"charge": _charge()
		"ring": _ring()
		"formula": _formula()
		"retrigger": _retrigger()
		"cards": _cards()
		"art": _art()
	draw_set_transform(Vector2.ZERO)

# --- The rack: ten spots, head pin nearest ---

## A rack spot's centre: the frame review's layout, the head pin at the bottom.
static func spot(position: int, centre: Vector2 = Vector2(84, 98), pin_gap: float = 30.0, row_gap: float = 26.0) -> Vector2:
	var at := Lane.spot(position)
	return centre + Vector2(at.x / Lane.PIN_SPACING * pin_gap, -(at.y - Lane.HEAD_PIN_F) / Lane.ROW_SPACING * row_gap)

func _rack() -> void:
	var roll1: Array = spec.get("roll1", [])
	var roll2: Array = spec.get("roll2", [])
	var glow: Array = spec.get("glow", [])
	var special: Array = spec.get("special", [])
	var font := get_theme_default_font()
	var centre := Vector2(84, 98) if not spec.has("mark") else Vector2(74, 98)
	for position in range(1, 11):
		var at := spot(position, centre)
		if glow.has(position):
			draw_circle(at, 14.0, Color(BRASS, 0.28))
			draw_arc(at, 13.0, 0.0, TAU, 28, BRASS, 2.0, true)
		if roll1.has(position) or roll2.has(position):
			# Down: the roll that took it, as in the frame review.
			draw_circle(at, 9.0, ROLL_COLORS[0 if roll1.has(position) else 1])
		elif special.has(position):
			draw_circle(at, 10.0, Color("8e2d4a"))
			draw_arc(at, 10.0, 0.0, TAU, 24, BRASS, 2.5, true)
			draw_arc(at, 5.5, 0.0, TAU, 20, BRASS, 1.5, true)
			_sparkle(at + Vector2(9, -9), 4.0, BRASS)
		else:
			_pin_top(at)
		if spec.get("numbers", false):
			var label := str(position)
			var ink := INK if not (roll1.has(position) or roll2.has(position)) else Color.BLACK
			_text(font, label, at + Vector2(0, 4), 11, ink)
	if spec.get("pocket", false):
		_pocket(centre)
	if spec.has("mark"):
		_score_box(Rect2(132, 10, 28, 22), String(spec.mark))
	if not roll1.is_empty() and not roll2.is_empty():
		_legend()

## The frame's mark, as the score sheet writes it (X, a count and /, or two counts).
func _score_box(rect: Rect2, mark: String) -> void:
	var font := get_theme_default_font()
	var parts := mark.split(" ")
	var cells := parts.size() if parts.size() > 1 else 1
	var w := 16.0
	var x0 := rect.end.x - w * cells
	for i in cells:
		var cell := Rect2(x0 + i * w, rect.position.y, w, 16)
		var text: String = parts[i] if parts.size() > 1 else mark
		var special := text == "X" or text == "/"
		if special: draw_rect(cell, Color(BRASS, 0.3))
		draw_rect(cell, IVORY, false, 1.0)
		_text(font, text, cell.get_center() + Vector2(0, 5), 13, BRASS if special else IVORY)

## A standing pin from above: ivory, its neck stripes a red ring.
func _pin_top(at: Vector2) -> void:
	draw_circle(at, 9.0, IVORY)
	draw_arc(at, 5.5, 0.0, TAU, 20, PIN_RED, 2.0, true)
	draw_arc(at, 9.0, 0.0, TAU, 24, Color(0, 0, 0, 0.35), 1.0, true)

## The strike ball meeting the head pin on the pocket side, with its curving line.
func _pocket(centre: Vector2) -> void:
	var head := spot(1, centre)
	var beside := spot(3 if side() > 0 else 2, centre)
	var hit := head.lerp(beside, 0.5) + Vector2(0, 8)
	var start := Vector2(centre.x + side() * 60.0, 118)
	var bend := Vector2(centre.x + side() * 58.0, 104)
	var points := PackedVector2Array()
	for i in 13:
		var t := i / 12.0
		points.append(start.lerp(bend, t).lerp(bend.lerp(hit, t), t))
	for i in range(0, points.size() - 2, 2):
		draw_line(points[i], points[i + 1], Color(SEA_GLASS, 0.9), 2.0, true)
	draw_circle(hit, 7.0, Color("2b3a55"))
	draw_arc(hit, 7.0, 0.0, TAU, 20, SEA_GLASS, 1.5, true)
	draw_circle(hit + Vector2(-2, -2), 1.5, Color(1, 1, 1, 0.7))

func _legend() -> void:
	var font := get_theme_default_font()
	for roll in 2:
		var at := Vector2(10 + roll * 40, 113)
		draw_circle(at, 4.0, ROLL_COLORS[roll])
		draw_string(font, at + Vector2(7, 4), "roll %d" % (roll + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, MUTED)

# --- The score sheet ---

func _sheet() -> void:
	var marks: Array = spec.get("marks", [])
	var labels: Array = spec.get("labels", [])
	var font := get_theme_default_font()
	var w := 44.0
	var gap := 6.0
	var total := marks.size() * w + (marks.size() - 1) * gap
	var x0 := (BOX.x - total) * 0.5
	var top := 26.0 if spec.has("bracket") else 30.0
	for i in marks.size():
		var box := Rect2(x0 + i * (w + gap), top, w, 46)
		draw_rect(box, Color(IVORY, 0.08))
		draw_rect(box, IVORY, false, 1.5)
		for roll in 2:
			var cell := Rect2(box.position + Vector2(w - 32 + roll * 16, 0), Vector2(16, 16))
			var mark := String(marks[i][roll])
			if mark == "X" or mark == "/": draw_rect(cell, Color(BRASS, 0.3))
			draw_rect(cell, IVORY, false, 1.0)
			if not mark.is_empty():
				_text(font, mark, cell.get_center() + Vector2(0, 5), 13, BRASS if mark in ["X", "/"] else IVORY)
		if i < labels.size():
			_text(font, String(labels[i]), Vector2(box.get_center().x, box.end.y + 14), 10, MUTED)
		var name := _frame_name(marks[i])
		_text(font, name, box.get_center() + Vector2(0, 12), 10, BRASS if name != "Open" else IVORY)
	if spec.has("bracket"):
		var y := top + 58
		draw_line(Vector2(x0, y), Vector2(x0 + total, y), BRASS, 2.0)
		draw_line(Vector2(x0, y), Vector2(x0, y - 5), BRASS, 2.0)
		draw_line(Vector2(x0 + total, y), Vector2(x0 + total, y - 5), BRASS, 2.0)
		_text(font, String(spec.bracket), Vector2(BOX.x * 0.5, y + 16), 12, BRASS)

static func _frame_name(rolls: Array) -> String:
	if String(rolls[1]) == "X": return "Strike"
	if String(rolls[1]) == "/": return "Spare"
	return "Open"

# --- A League's or a Division's steps ---

func _ladder() -> void:
	var steps := int(spec.get("steps", 3))
	var labels: Array = spec.get("labels", [])
	var glow := int(spec.get("glow", -1))
	var progress := int(spec.get("progress", 0))
	var font := get_theme_default_font()
	var trophy: bool = spec.get("trophy", false)
	var left := 26.0 if steps == 3 else 14.0
	var right := 142.0 if steps == 3 else (136.0 if trophy else 154.0)
	var y := 62.0
	var xs: Array = []
	for i in steps:
		xs.append(lerpf(left, right, float(i) / maxf(1.0, steps - 1)))
	draw_line(Vector2(left, y), Vector2(right + (16.0 if trophy else 0.0), y), Color(IVORY, 0.35), 3.0)
	for i in steps:
		var at := Vector2(xs[i], y)
		var boss := steps == 3 and i == 2
		var r := (13.0 if boss else 10.0) if steps == 3 else 6.5
		var cleared := progress > 0 and i + 1 < progress
		var fill := Color(SEA_GLASS, 0.85) if cleared else Color(INK.lightened(0.18))
		if glow == i:
			draw_circle(at, r + 5.0, Color(BRASS, 0.3))
			fill = BRASS
		draw_circle(at, r, fill)
		draw_arc(at, r, 0.0, TAU, 24, BRASS if (glow == i or boss) else Color(IVORY, 0.7), 2.0, true)
		if boss: _crown(at + Vector2(0, -r - 7), BRASS if glow == i or glow < 0 else Color(BRASS, 0.55))
		if steps == 8:
			_text(font, str(i + 1), at + Vector2(0, 20), 10, IVORY if glow < 0 else MUTED)
		if i < labels.size():
			_text(font, String(labels[i]), at + Vector2(0, r + 18), 12, BRASS if glow == i else (IVORY if glow < 0 else MUTED))
	if progress > 0:
		var here := Vector2(xs[progress - 1], y - 18)
		draw_circle(here, 5.0, Color("2b3a55"))
		draw_arc(here, 5.0, 0.0, TAU, 16, SEA_GLASS, 1.5, true)
		_text(font, "you", here + Vector2(0, -9), 10, SEA_GLASS)
	if trophy:
		_cup(Vector2(right + 18.0, y), 1.0)
	if steps == 8:
		_text(font, "8 Divisions", Vector2(BOX.x * 0.5, 104), 11, MUTED)

func _crown(at: Vector2, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([at + Vector2(-8, 4), at + Vector2(-8, -3), at + Vector2(-4, 1), at + Vector2(0, -5),
		at + Vector2(4, 1), at + Vector2(8, -3), at + Vector2(8, 4)]), color)

func _cup(at: Vector2, scale_by: float) -> void:
	var k := scale_by
	draw_colored_polygon(PackedVector2Array([at + Vector2(-9, -12) * k, at + Vector2(9, -12) * k, at + Vector2(6, -1) * k, at + Vector2(2, 2) * k,
		at + Vector2(2, 6) * k, at + Vector2(6, 9) * k, at + Vector2(-6, 9) * k, at + Vector2(-2, 6) * k, at + Vector2(-2, 2) * k, at + Vector2(-6, -1) * k]), BRASS)
	draw_arc(at + Vector2(-9, -7) * k, 4.0 * k, PI * 0.5, PI * 1.5, 10, BRASS, 2.0)
	draw_arc(at + Vector2(9, -7) * k, 4.0 * k, -PI * 0.5, PI * 0.5, 10, BRASS, 2.0)

# --- A match's target ---

func _target() -> void:
	var font := get_theme_default_font()
	var score := float(spec.get("score", 0))
	var goal := float(spec.get("target", 1))
	var bar := Rect2(14, 50, 140, 16)
	_rounded(bar, Color(IVORY, 0.12), 4.0)
	_rounded(Rect2(bar.position, Vector2(bar.size.x * clampf(score / goal, 0.0, 1.0), bar.size.y)), SEA_GLASS, 4.0)
	draw_rect(bar, Color(IVORY, 0.6), false, 1.0)
	var flag := Vector2(bar.end.x, bar.position.y)
	draw_line(flag, flag + Vector2(0, -26), BRASS, 2.0)
	draw_colored_polygon(PackedVector2Array([flag + Vector2(0, -26), flag + Vector2(-16, -21), flag + Vector2(0, -16)]), BRASS)
	_text(font, "Target %d" % int(goal), Vector2(bar.end.x - 40, 26), 11, BRASS)
	_text(font, "%d" % int(score), Vector2(bar.position.x + bar.size.x * score / goal, 82), 12, SEA_GLASS)
	for i in 2:
		var pip := Rect2(52 + i * 36, 92, 28, 18)
		draw_rect(pip, Color(IVORY, 0.1 if i == 1 else 0.3))
		draw_rect(pip, IVORY, false, 1.0)
		_text(font, "F%d" % (i + 1), pip.get_center() + Vector2(0, 4), 10, IVORY)
	_text(font, "2 frames", Vector2(140, 105), 10, MUTED)

# --- The lane, seen from above, foul line at the bottom ---

func _lane() -> void:
	var font := get_theme_default_font()
	var path := String(spec.get("path", "none"))
	var zone := String(spec.get("zone", ""))
	var width := 78.0 if zone == "boards" else 40.0
	var cx := BOX.x * 0.5
	var top := 10.0
	var foul := 112.0
	var lane := Rect2(cx - width * 0.5, top, width, foul - top)
	var gutter := 6.0
	draw_rect(Rect2(lane.position.x - gutter, top, gutter, lane.size.y), Color("1d242c"))
	draw_rect(Rect2(lane.end.x, top, gutter, lane.size.y), Color("1d242c"))
	draw_rect(lane, Color("b98a55"))
	var board := width / 39.0
	for i in 39:
		if i % 2 == 1:
			draw_rect(Rect2(lane.position.x + i * board, top, board, lane.size.y), Color(0, 0, 0, 0.07))
	var oil_y := foul - (foul - top) * (Lane.OIL_END_F / Lane.HEAD_PIN_F)
	if spec.get("oil", false):
		draw_rect(Rect2(lane.position.x, oil_y, width, foul - oil_y), Color(SEA_GLASS, 0.32))
		_bracket(Vector2(lane.end.x + gutter + 4, oil_y), Vector2(lane.end.x + gutter + 4, foul), "oil", SEA_GLASS)
		_bracket(Vector2(lane.end.x + gutter + 4, top + 14), Vector2(lane.end.x + gutter + 4, oil_y), "dry", IVORY)
	if zone == "backend":
		draw_rect(Rect2(lane.position.x, top + 14, width, oil_y - top - 14), Color(BRASS, 0.22))
		_bracket(Vector2(lane.position.x - gutter - 4, top + 14), Vector2(lane.position.x - gutter - 4, oil_y), "backend", BRASS, -1.0)
	# The pins, small, at the far end.
	for position in range(1, 11):
		var at := spot(position, Vector2(cx, top + 16), 5.0 if zone != "boards" else 8.0, 3.6)
		draw_circle(at, 1.6, IVORY)
	draw_line(Vector2(lane.position.x, foul), Vector2(lane.end.x, foul), PIN_RED, 1.5)
	if zone == "boards":
		var edge := lane.end.x if side() > 0 else lane.position.x
		var two := Vector2(edge - side() * board * 2.0, foul + 2)
		draw_rect(Rect2(minf(edge, two.x), top, board * 2.0, foul - top), Color(BRASS, 0.45))
		_text(font, "2 boards", Vector2(cx + side() * (width * 0.5 + 26), 60), 10, BRASS)
		_text(font, "39 boards", Vector2(cx, foul + 7), 9, IVORY)
	match path:
		"straight": _roll(_straight_line(cx, foul, top), IVORY)
		"hook": _roll(_hook_line(cx, foul, top, oil_y), SEA_GLASS)
		"both":
			_roll(_straight_line(cx, foul, top), IVORY, false)
			_roll(_hook_line(cx, foul, top, oil_y), SEA_GLASS)
			_text(font, "straight", Vector2(cx - side() * 46, 70), 10, IVORY)
			_text(font, "curved", Vector2(cx + side() * 46, 70), 10, SEA_GLASS)
		"gutter":
			var points := PackedVector2Array()
			var gx := lane.end.x + gutter * 0.5 if side() > 0 else lane.position.x - gutter * 0.5
			for i in 17:
				var t := i / 16.0
				var y := lerpf(foul, top + 20, t)
				var x := lerpf(cx + side() * 6.0, gx, smoothstep(0.0, 0.45, t))
				points.append(Vector2(x, y))
			_roll(points, Color(MULT_RED, 0.95))
			_text(font, "gutter", Vector2(gx + side() * 22, 44), 10, MULT_RED)

func _straight_line(cx: float, foul: float, top: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 13:
		points.append(Vector2(cx + side() * 2.0, lerpf(foul, top + 22, i / 12.0)))
	return points

## A hook: it skids nearly straight through the oil, then curves into the pocket.
func _hook_line(cx: float, foul: float, top: float, oil_y: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 17:
		var t := i / 16.0
		var y := lerpf(foul, top + 22, t)
		var past := clampf((oil_y - y) / (oil_y - top - 22), 0.0, 1.0) # 0 in the oil, 1 at the pins
		var x := cx + side() * (11.0 + 3.0 * t - 12.0 * past * past)
		points.append(Vector2(x, y))
	return points

## A ball's line as dots, and the ball at its end.
func _roll(points: PackedVector2Array, color: Color, with_ball: bool = true) -> void:
	for i in range(points.size() - 1):
		if i % 2 == 0:
			draw_line(points[i], points[i + 1], color, 1.6, true)
	if with_ball:
		var at := points[points.size() - 1]
		draw_circle(at, 4.0, Color("2b3a55"))
		draw_arc(at, 4.0, 0.0, TAU, 14, color, 1.2, true)

func _bracket(from: Vector2, to: Vector2, label: String, color: Color, facing: float = 1.0) -> void:
	draw_line(from, to, color, 1.5)
	draw_line(from, from - Vector2(facing * 3, 0), color, 1.5)
	draw_line(to, to - Vector2(facing * 3, 0), color, 1.5)
	var font := get_theme_default_font()
	var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
	var x := from.x + 4.0 if facing > 0 else from.x - 4.0 - width
	draw_string(font, Vector2(x, (from.y + to.y) * 0.5 + 3), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, color)

# --- Charging the held ball ---

func _charge() -> void:
	var font := get_theme_default_font()
	var at := Vector2(62, 62)
	draw_circle(at, 24.0, Color("2b3a55"))
	draw_arc(at, 24.0, 0.0, TAU, 40, SEA_GLASS, 2.0, true)
	for hole in [Vector2(-6, -8), Vector2(5, -9), Vector2(0, 2)]:
		draw_circle(at + hole, 3.0, INK)
	draw_circle(at + Vector2(-10, -12), 3.0, Color(1, 1, 1, 0.5))
	# The swirl: an arc around the ball with an arrowhead.
	var turn := side()
	var start := -PI * 0.75
	var end := start + turn * PI * 1.5
	draw_arc(at, 34.0, minf(start, end), maxf(start, end), 36, BRASS, 3.0, true)
	var tip := at + Vector2.from_angle(end) * 34.0
	var along := Vector2.from_angle(end + turn * PI * 0.5)
	draw_colored_polygon(PackedVector2Array([tip + along * 7.0, tip + along.rotated(PI * 0.5) * 5.0 - along * 2.0, tip - along.rotated(PI * 0.5) * 5.0 - along * 2.0]), BRASS)
	_text(font, "swirl", at + Vector2(0, 50), 11, BRASS)
	var meter := Rect2(124, 22, 14, 76)
	_rounded(meter, Color(IVORY, 0.12), 3.0)
	var fill := 0.82
	for i in 16:
		var t := float(i) / 16.0
		if t >= fill: break
		draw_rect(Rect2(meter.position.x + 2, meter.end.y - 2 - (i + 1) * (meter.size.y - 4) / 16.0, meter.size.x - 4, (meter.size.y - 4) / 16.0 - 1), SEA_GLASS.lerp(BRASS, t))
	draw_rect(meter, IVORY, false, 1.0)
	_text(font, "charge", Vector2(meter.get_center().x, meter.end.y + 13), 10, IVORY)

# --- The target ring's grades ---

func _ring() -> void:
	var font := get_theme_default_font()
	var at := Vector2(56, 60)
	var unit := 48.0 / 0.30 # the widest ring (0.30, TargetRing.RING_MAX) draws at 48
	draw_circle(at, 0.30 * unit, Color(RING_COLORS.clean, 0.06))
	draw_arc(at, 0.30 * unit, 0.0, TAU, 48, RING_COLORS.clean, 2.0, true)
	draw_circle(at, Lane.SWEET_RING * unit, Color(RING_COLORS.sweet, 0.16))
	draw_arc(at, Lane.SWEET_RING * unit, 0.0, TAU, 40, RING_COLORS.sweet, 2.0, true)
	draw_circle(at, Lane.PERFECT_RING * unit, Color(RING_COLORS.perfect, 0.45))
	draw_arc(at, Lane.PERFECT_RING * unit, 0.0, TAU, 32, RING_COLORS.perfect, 2.0, true)
	# It shrinks while the ball is held.
	for a in [0.25, 1.25]:
		var dir := Vector2.from_angle(PI * a)
		var outer := at + dir * (0.30 * unit + 9.0)
		draw_line(outer, outer - dir * 7.0, IVORY, 1.5)
		draw_colored_polygon(PackedVector2Array([outer - dir * 9.0, outer - dir * 5.0 + dir.orthogonal() * 3.0, outer - dir * 5.0 - dir.orthogonal() * 3.0]), IVORY)
	var rows := [["Clean", "+0", RING_COLORS.clean], ["Sweet", "+1 Mult", RING_COLORS.sweet], ["Perfect", "+2 Mult", RING_COLORS.perfect]]
	for i in rows.size():
		var y := 34.0 + i * 24.0
		draw_circle(Vector2(114, y - 4), 4.0, rows[i][2])
		draw_string(font, Vector2(122, y), rows[i][0], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, rows[i][2])
		draw_string(font, Vector2(122, y + 11), rows[i][1], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, MUTED)

# --- Value × Mult ---

func _formula() -> void:
	var font := get_theme_default_font()
	var glow := String(spec.get("glow", ""))
	var value := int(spec.get("value", 140))
	var mult := int(spec.get("mult", 4))
	var boxes := [["Value", str(value), IVORY, "value", Rect2(8, 38, 50, 44)], ["Mult", str(mult), MULT_RED, "mult", Rect2(74, 38, 34, 44)],
		["Bank", str(value * mult), SCORE_GOLD, "score", Rect2(118, 38, 44, 44)]]
	for b in boxes:
		var rect: Rect2 = b[4]
		var lit: bool = glow == b[3]
		if lit:
			_rounded(rect.grow(4.0), Color(BRASS, 0.3), 7.0)
		_rounded(rect, Color(INK.lightened(0.12)), 5.0)
		draw_rect(rect, BRASS if lit else Color(IVORY, 0.4), false, 2.0 if lit else 1.0)
		_text(font, b[0], Vector2(rect.get_center().x, rect.position.y - 6), 10, BRASS if lit else MUTED)
		_text(font, b[1], rect.get_center() + Vector2(0, 7), 18 if b[1].length() < 4 else 15, b[2] if lit or glow.is_empty() else Color(b[2], 0.55))
	_text(font, "×", Vector2(66, 66), 16, IVORY)
	_text(font, "=", Vector2(113, 65), 12, IVORY)
	var icon: Texture2D = _texture(CARD_DIR + ("mult" if glow == "mult" else "value") + ".svg")
	if icon != null and glow != "score":
		var r: Rect2 = boxes[1 if glow == "mult" else 0][4]
		draw_texture_rect(icon, Rect2(r.get_center().x - 9, r.end.y + 8, 18, 18), false)

# --- A retrigger: the pin scores twice ---

func _retrigger() -> void:
	var font := get_theme_default_font()
	_pin_side(Vector2(70, 96), 1.0, Color(IVORY, 0.35))
	_pin_side(Vector2(84, 100), 1.0, IVORY)
	_text(font, "+10", Vector2(118, 46), 14, IVORY)
	_text(font, "+10", Vector2(130, 70), 14, BRASS)
	_text(font, "×2", Vector2(36, 40), 16, BRASS)

## A pin from the side: its shape traced from a profile, base at `foot`.
func _pin_side(foot: Vector2, k: float, color: Color) -> void:
	var profile := [[0, 4.5], [8, 7.0], [20, 9.0], [32, 8.0], [42, 5.0], [50, 3.6], [56, 4.6], [62, 5.2], [68, 4.0], [72, 0.0]]
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for p in profile:
		left.append(foot + Vector2(-p[1], -p[0]) * k)
		right.append(foot + Vector2(p[1], -p[0]) * k)
	right.reverse()
	draw_colored_polygon(left + right, color)
	var stripe := Color(PIN_RED, color.a)
	for y in [47.0, 52.0]:
		draw_line(foot + Vector2(-4.0, -y) * k, foot + Vector2(4.0, -y) * k, stripe, 2.0)

# --- Cards ---

func _cards() -> void:
	var icons: Array = spec.get("icons", [])
	var tags: Array = spec.get("tags", [])
	var font := get_theme_default_font()
	var card := Vector2(34, 48)
	var face: Texture2D = _texture(CARD_DIR + "face-common.svg")
	if spec.get("grid", false):
		for i in icons.size():
			var at := Vector2(50 + (i % 2) * 40, 10 + int(i / 2) * 54)
			_card(Rect2(at, card), face, String(icons[i]))
		return
	var n := icons.size()
	var gap := 10.0
	var total := n * card.x + (n - 1) * gap
	var x0 := (BOX.x - total) * 0.5
	var y := 26.0 if not tags.is_empty() else 32.0
	if spec.get("order", false): y = 20.0
	for i in n:
		var rect := Rect2(Vector2(x0 + i * (card.x + gap), y), card)
		if spec.get("fan", false):
			var angle := (i - (n - 1) * 0.5) * 0.22
			var pivot := Vector2(BOX.x * 0.5, 120)
			rect.position = pivot + (Vector2(0, -62)).rotated(angle) - card * 0.5
			_card_rotated(rect, face, String(icons[i]), angle)
			draw_set_transform_matrix(_base())
			continue
		_card(rect, face, String(icons[i]))
		if i < tags.size():
			var tag := Rect2(rect.get_center().x - 18, rect.end.y + 6, 36, 16)
			_rounded(tag, BRASS, 3.0)
			_text(font, String(tags[i]), tag.get_center() + Vector2(0, 4), 10, INK)
	if spec.get("order", false):
		var y2 := y + card.y + 14
		for i in n:
			_text(font, str(i + 1), Vector2(x0 + i * (card.x + gap) + card.x * 0.5, y2 + 4), 12, BRASS)
		draw_line(Vector2(x0 + 4, y2 + 16), Vector2(x0 + total - 4, y2 + 16), BRASS, 2.0)
		var tip := Vector2(x0 + total - 2, y2 + 16)
		draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-7, -4), tip + Vector2(-7, 4)]), BRASS)

func _card(rect: Rect2, face: Texture2D, icon_name: String) -> void:
	if face != null:
		draw_texture_rect(face, rect, false)
	else:
		_rounded(rect, IVORY, 4.0)
	var icon: Texture2D = _texture(CARD_DIR + icon_name + ".svg")
	if icon != null:
		var side_len := rect.size.x * 0.62
		draw_texture_rect(icon, Rect2(rect.get_center() - Vector2(side_len, side_len) * 0.5, Vector2(side_len, side_len)), false)

func _card_rotated(rect: Rect2, face: Texture2D, icon_name: String, angle: float) -> void:
	var centre := rect.get_center()
	draw_set_transform_matrix(_base() * Transform2D(angle, centre))
	_card(Rect2(-rect.size * 0.5, rect.size), face, icon_name)

## The drawing's base transform (fit to the control), for nesting rotations.
func _base() -> Transform2D:
	var s := minf(size.x / BOX.x, size.y / BOX.y)
	return Transform2D(0.0, Vector2(s, s), 0.0, (size - BOX * s) * 0.5)

# --- Clubhouse and rival art ---

func _art() -> void:
	var textures: Array = spec.get("textures", [])
	var n := textures.size()
	for i in n:
		var tex: Texture2D = _texture(String(textures[i]))
		if tex == null: continue
		var slot := Rect2(8 + i * (152.0 / n), 8, 152.0 / n - (6.0 if n > 1 else 0.0), 104)
		var aspect := float(tex.get_width()) / maxf(1.0, tex.get_height())
		var fit := slot.size
		if fit.x / fit.y > aspect: fit.x = fit.y * aspect
		else: fit.y = fit.x / aspect
		draw_texture_rect(tex, Rect2(slot.get_center() - fit * 0.5, fit), false)

# --- Helpers ---

func _texture(path: String) -> Texture2D:
	if not _textures.has(path):
		_textures[path] = load(path) if ResourceLoader.exists(path) else null
	return _textures[path]

func _text(font: Font, text: String, centre: Vector2, font_size: int, color: Color) -> void:
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(font, Vector2(centre.x - width * 0.5, centre.y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _rounded(rect: Rect2, color: Color, radius: float) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(int(radius))
	draw_style_box(box, rect)

func _sparkle(at: Vector2, r: float, color: Color) -> void:
	draw_line(at + Vector2(-r, 0), at + Vector2(r, 0), color, 1.5)
	draw_line(at + Vector2(0, -r), at + Vector2(0, r), color, 1.5)
