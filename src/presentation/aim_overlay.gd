extends Control
## Aiming feedback drawn over the lane: the target ring, a short directional guide
## from the ball and a spin meter around it. The ring is magnified (RETICLE_PX per
## unit of ring radius) because its true size is a few pixels at 20 m; it keeps the
## true proportions while contracting. The guide bends only qualitatively with
## charged spin and is not a forecast of the roll. Developmental look (E12 owns VFX).
const Lane = preload("res://src/simulation/lane_spec.gd")
const GUIDE_LENGTH := 4.5
const GUIDE_BEND := 0.06 # meters of qualitative bend at full spin; Oil Slick halves it
const GUARD_COLOR := Color(1.0, 0.25, 0.85, 0.9) # Narrow Lane's guard lines (developmental; E21/E22 art replaces them)
const DASHES := 9
const GUIDE_COLOR := Color(1.0, 1.0, 1.0, 0.55)
const CLOCKWISE_COLOR := Color(1.0, 0.55, 0.35)
const COUNTER_COLOR := Color(0.35, 0.85, 1.0)
const FULL_COLOR := Color(1.0, 0.85, 0.3)
const RETICLE_PX := 240.0 # per unit of normalized ring radius, at a 720 px shorter side
const RETICLE_FLATTEN := 0.45

var lab: Control

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if lab == null or lab.lane == null or lab.state not in ["aim", "holding"]:
		return
	var target: Vector2 = lab.screen_point(Lane.world(lab.target_x * Lane.LANE_HALF_WIDTH, Lane.TARGET_PLANE_F, 0.0))
	var reticle: float = lab.ring_radius * RETICLE_PX * minf(size.x, size.y) / 720.0
	draw_set_transform(target, 0.0, Vector2(1.0, RETICLE_FLATTEN))
	draw_arc(Vector2.ZERO, reticle, 0.0, TAU, 48, Color(0, 0, 0, 0.5), 7.0, true)
	draw_arc(Vector2.ZERO, reticle, 0.0, TAU, 48, lab.ring_color(), 4.0, true)
	draw_set_transform(Vector2.ZERO)
	# Narrow Lane (E17-L02): guard lines at the new gutter edges, from the ball to the deck.
	var edge: float = lab.lane.gutter_edge()
	if edge < Lane.LANE_HALF_WIDTH:
		for side in [-1.0, 1.0]:
			draw_line(lab.screen_point(Lane.world(side * edge, Lane.BALL_START_F, 0.002)), lab.screen_point(Lane.world(side * edge, Lane.HEAD_PIN_F - 0.6, 0.002)), GUARD_COLOR, 4.0, true)
	var spin: float = lab.charged_spin() * lab.hook_scale()
	var ball: Vector3 = lab.lane.ball_position()
	var points: Array[Vector2] = []
	for i in DASHES * 2 + 1:
		var t := float(i) / (DASHES * 2)
		var bend := spin * GUIDE_BEND * t * t
		points.append(lab.screen_point(Lane.world(ball.x + bend, Lane.BALL_START_F + Lane.BALL_RADIUS * 2.0 + GUIDE_LENGTH * t, 0.002)))
	for dash in DASHES:
		draw_line(points[dash * 2], points[dash * 2 + 1], GUIDE_COLOR, 4.0, true)
	if lab.state != "holding":
		return
	# The meter shows the held charge as it builds; it lights up once the throw
	# will curve (the sparkle state, E05-R1b) and turns gold at full charge.
	var center: Vector2 = lab.screen_point(lab.lane.ball_position())
	var radius: float = lab.ball_touch_radius() * 0.8
	var charge: float = lab.held_charge()
	var ready: bool = lab.curve_ready()
	var color := CLOCKWISE_COLOR if charge > 0.0 else COUNTER_COLOR
	if lab.full_charge():
		color = FULL_COLOR
	elif not ready:
		color = color.darkened(0.45)
	draw_arc(center, radius, 0.0, TAU, 48, Color(0, 0, 0, 0.35), 6.0, true)
	if charge != 0.0:
		var start := -PI * 0.5
		var end := start + charge * TAU
		draw_arc(center, radius, minf(start, end), maxf(start, end), 48, color, 8.0, true)
		var tip := center + Vector2(cos(end), sin(end)) * radius
		var tangent := Vector2(-sin(end), cos(end)) * signf(charge)
		var normal := Vector2(cos(end), sin(end))
		draw_colored_polygon(PackedVector2Array([tip + tangent * 16.0, tip - tangent * 4.0 + normal * 10.0, tip - tangent * 4.0 - normal * 10.0]), color)
	if ready:
		# Placeholder sparkle until AV-T01: small diamonds orbiting the ball.
		var count := 8 if lab.full_charge() else 5
		var turn := 0.0 if lab.settings.reduced_motion else Time.get_ticks_msec() / 1000.0 * signf(charge) * 2.5
		for i in count:
			var a := turn + TAU * i / count
			var p := center + Vector2(cos(a), sin(a)) * radius * 1.25
			var r := 7.0 if lab.full_charge() else 5.0
			draw_colored_polygon(PackedVector2Array([p + Vector2(0, -r), p + Vector2(r * 0.6, 0), p + Vector2(0, r), p + Vector2(-r * 0.6, 0)]), color.lightened(0.3))
	var label := "Swing to charge"
	if charge != 0.0:
		label = ("Full %s" if lab.full_charge() else ("Curve %s %d%%" if ready else "Charging %s %d%%")) % (["↻" if charge > 0.0 else "↺"] + ([] if lab.full_charge() else [roundi(absf(charge) * 100.0)]))
	if lab.spin_disabled():
		label = "Spin disabled ⊘" # Dead Straight: the committed launch has no spin
	var font := get_theme_default_font()
	var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
	draw_string_outline(font, center + Vector2(-width * 0.5, -radius - 18.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, 6, Color.BLACK)
	draw_string(font, center + Vector2(-width * 0.5, -radius - 18.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, color if ready else Color.WHITE)
