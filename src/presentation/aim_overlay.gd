extends Control
## Aiming feedback drawn over the lane: the target ring, a short directional guide
## from the ball and a bounded screen-space charge trail. The ring is magnified (RETICLE_PX per
## unit of ring radius) because its true size is a few pixels at 20 m; it keeps the
## true proportions while contracting. The guide bends only qualitatively with
## charged spin and is not a forecast of the roll. Charge art: AV-T03.
const Lane = preload("res://src/simulation/lane_spec.gd")
const NeonArt = preload("res://assets/leagues/neon/rule_overlay.gd")
const GUIDE_LENGTH := 4.5
const GUIDE_BEND := 0.06 # meters of qualitative bend at full spin; Oil Slick halves it
const DASHES := 9
const GUIDE_COLOR := Color(1.0, 1.0, 1.0, 0.55)
const RETICLE_PX := 240.0 # per unit of normalized ring radius, at a 720 px shorter side
const RETICLE_FLATTEN := 0.45

const CAPACITY := 96
const MIN_CHARGE := 0.06
var lab: Control
var trail_positions := PackedVector2Array()
var trail_life := PackedFloat32Array()
var trail_duration := PackedFloat32Array()
var trail_colors := PackedColorArray()
var trail_sizes := PackedFloat32Array()
var guide_points := PackedVector2Array()
var _cursor := 0
var _emission := 0.0
var _previous := Vector2.ZERO
var _previous_angle := 0.0
var _tracking := false
var _viewport_size := Vector2.ZERO
var trail_count := 0
var trail_strength := 0.0
var trail_color := Color("668baf")

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	trail_positions.resize(CAPACITY)
	trail_life.resize(CAPACITY)
	trail_duration.resize(CAPACITY)
	trail_colors.resize(CAPACITY)
	trail_sizes.resize(CAPACITY)
	guide_points.resize(DASHES * 2 + 1)

func _process(delta: float) -> void:
	_update_trail(minf(delta, 0.05))
	queue_redraw()

func _clear_trail() -> void:
	trail_life.fill(0.0)
	trail_colors.fill(Color.TRANSPARENT)
	trail_count = 0
	_emission = 0.0
	_tracking = false

func _update_trail(delta: float) -> void:
	if lab == null or lab.lane == null or lab.state != "holding" or lab.settings.reduced_motion or lab.spin_disabled():
		_clear_trail()
		return
	if size != _viewport_size:
		_clear_trail()
		_viewport_size = size
	trail_strength = absf(lab.held_charge())
	if trail_strength < MIN_CHARGE:
		_clear_trail()
		return
	trail_color = Color("f5cb69") if lab.full_charge() else (Color("64dacb") if lab.curve_ready() else Color("668baf"))
	var center: Vector2 = get_global_transform().affine_inverse() * lab.ball_screen_position()
	var angle: float = lab._flick.body_angle
	if not _tracking:
		_previous = center
		_previous_angle = angle
		_tracking = true
	for i in CAPACITY:
		trail_life[i] = maxf(0.0, trail_life[i] - delta)
	if trail_strength >= MIN_CHARGE:
		var speed := clampf(absf(lab._flick.spin_rate) / 30.0, 0.0, 1.0)
		_emission += delta * lerpf(12.0, 110.0, trail_strength) * lerpf(0.6, 1.0, speed)
		var count := mini(int(_emission), 8)
		_emission -= count
		var radius: float = lab._ball_screen_radius()
		for j in count:
			var t := float(j + 1) / count
			var point := _previous.lerp(center, t)
			if int(lab._flick.tuning.spin_model) == 2:
				point += Vector2.from_angle(lerpf(_previous_angle, angle, t)) * radius * 1.05
			# Deterministic narrow scatter; each point stays where it was emitted.
			var offset := Vector2(sin(_cursor * 2.4), cos(_cursor * 1.7)) * radius * 0.12
			trail_positions[_cursor] = point + offset
			trail_duration[_cursor] = lerpf(0.12, 0.55, trail_strength)
			trail_life[_cursor] = trail_duration[_cursor]
			var alpha := lerpf(0.25, 0.85, trail_strength)
			if lab.settings.get("reduced_flash", false): alpha = minf(alpha, 0.38)
			trail_colors[_cursor] = Color(trail_color, alpha)
			trail_sizes[_cursor] = maxf(1.0, radius / 14.0) * (1.0 + trail_strength)
			_cursor = (_cursor + 1) % CAPACITY
	_previous = center
	_previous_angle = angle
	trail_count = 0
	for i in CAPACITY:
		if trail_life[i] > 0.0: trail_count += 1

func _draw() -> void:
	if lab == null or lab.lane == null or lab.state not in ["aim", "holding"]:
		return
	var target: Vector2 = lab.screen_point(Lane.world(lab.target_x * Lane.LANE_HALF_WIDTH, Lane.TARGET_PLANE_F, 0.0))
	draw_reticle(self, lab, target, minf(size.x, size.y))
	# Authored enamel/brass rail at the existing Narrow Lane gutter boundary.
	var edge: float = lab.lane.gutter_edge()
	if edge < Lane.LANE_HALF_WIDTH:
		NeonArt.rails(self, lab.screen_point, edge, maxf(1.0, minf(size.x, size.y) / 720.0))
	var spin: float = lab.charged_spin() * lab.hook_scale()
	var ball: Vector3 = lab.lane.ball_position()

	for i in DASHES * 2 + 1:
		var t := float(i) / (DASHES * 2)
		var bend := spin * GUIDE_BEND * t * t
		guide_points[i] = lab.screen_point(Lane.world(ball.x + bend, Lane.BALL_START_F + Lane.BALL_RADIUS * 2.0 + GUIDE_LENGTH * t, 0.002))
	for dash in DASHES:
		draw_line(guide_points[dash * 2], guide_points[dash * 2 + 1], GUIDE_COLOR, 4.0, true)
	if lab.state != "holding":
		return
	_draw_charge()

## The target reticle as the lane shows it, centred at `at` on `canvas`, sized for a
## screen whose shorter side is `short_side`. The aim magnifier (UI-14) draws this
## same ring, so it looks identical in both.
static func draw_reticle(canvas: CanvasItem, lab, at: Vector2, short_side: float) -> void:
	var pixels: float = RETICLE_PX * short_side / 720.0
	var reticle: float = lab.ring_radius * pixels
	canvas.draw_set_transform(at, 0.0, Vector2(1.0, RETICLE_FLATTEN))
	if lab.zone_scale() < 1.0:
		NeonArt.zones(canvas, pixels, lab.zone_scale())
	canvas.draw_arc(Vector2.ZERO, reticle, 0.0, TAU, 48, Color(0, 0, 0, 0.5), 7.0, true)
	canvas.draw_arc(Vector2.ZERO, reticle, 0.0, TAU, 48, lab.ring_color(), 4.0, true)
	canvas.draw_set_transform(Vector2.ZERO)

## Diagnostic snapshot used by the native journey, not the frame loop.
func charge_pose() -> Dictionary:
	return {"center": get_global_transform().affine_inverse() * lab.ball_screen_position(),
		"radius": lab._ball_screen_radius(), "particles": trail_count,
		"state": "disabled" if lab.spin_disabled() else ("full" if lab.full_charge() else ("ready" if lab.curve_ready() else "charging")),
		"reduced": lab.settings.reduced_motion}

func _draw_charge() -> void:
	if lab.spin_disabled(): return
	if lab.settings.reduced_motion:
		# Relocate the former collar meter to a stationary lower-screen rail.
		var rail := Rect2(Vector2(size.x * 0.35, size.y * 0.82), Vector2(size.x * 0.3, 6))
		draw_rect(rail.grow(2), Color("101b2d"))
		draw_rect(rail, Color("53687c"))
		var charge := absf(lab.held_charge())
		var color := Color("f5cb69") if lab.full_charge() else (Color("64dacb") if lab.curve_ready() else Color("668baf"))
		rail.size.x *= charge
		draw_rect(rail, color)
		return
	for i in CAPACITY:
		if trail_life[i] <= 0.0: continue
		var fade := trail_life[i] / trail_duration[i]
		var color := trail_colors[i]
		color.a *= fade * fade
		var width := trail_sizes[i]
		var at := trail_positions[i].round()
		draw_rect(Rect2(at - Vector2.ONE * width * 0.5, Vector2.ONE * width), color)
