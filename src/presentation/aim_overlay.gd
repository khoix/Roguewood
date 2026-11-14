extends Control
## Aiming feedback drawn over the lane: the target ring, a short directional guide
## from the ball and an enamel charge collar around it. The ring is magnified (RETICLE_PX per
## unit of ring radius) because its true size is a few pixels at 20 m; it keeps the
## true proportions while contracting. The guide bends only qualitatively with
## charged spin and is not a forecast of the roll. Charge art: AV-T01.
const Lane = preload("res://src/simulation/lane_spec.gd")
const NeonArt = preload("res://assets/leagues/neon/rule_overlay.gd")
const GUIDE_LENGTH := 4.5
const GUIDE_BEND := 0.06 # meters of qualitative bend at full spin; Oil Slick halves it
const DASHES := 9
const GUIDE_COLOR := Color(1.0, 1.0, 1.0, 0.55)
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
	if lab.zone_scale() < 1.0:
		NeonArt.zones(self, RETICLE_PX * minf(size.x, size.y) / 720.0, lab.zone_scale())
	draw_arc(Vector2.ZERO, reticle, 0.0, TAU, 48, Color(0, 0, 0, 0.5), 7.0, true)
	draw_arc(Vector2.ZERO, reticle, 0.0, TAU, 48, lab.ring_color(), 4.0, true)
	draw_set_transform(Vector2.ZERO)
	# Authored enamel/brass rail at the existing Narrow Lane gutter boundary.
	var edge: float = lab.lane.gutter_edge()
	if edge < Lane.LANE_HALF_WIDTH:
		NeonArt.rails(self, lab.screen_point, edge, maxf(1.0, minf(size.x, size.y) / 720.0))
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
	_draw_charge()

## AV-T01: enamel charge collar, directional vanes and stepped star clusters.
## Geometry uses the rendered radius, never the enlarged touch target.
func charge_pose() -> Dictionary:
	return {"center": get_global_transform().affine_inverse() * lab.ball_screen_position(),
		"radius": lab._ball_screen_radius(),
		"state": "disabled" if lab.spin_disabled() else ("full" if lab.full_charge() else ("ready" if lab.curve_ready() else "charging")),
		"reduced": lab.settings.reduced_motion or lab.settings.get("reduced_flash", false)}

func _draw_charge() -> void:
	var pose := charge_pose()
	var center: Vector2 = pose.center
	var r: float = pose.radius
	var unit := maxf(1.0, r / 18.0)
	var ink := Color("101b2d")
	var color := Color("53687c")
	if pose.state == "ready": color = Color("64dacb") if lab.held_charge() > 0 else Color("ee9476")
	if pose.state == "full": color = Color("f5cb69")
	# Twelve inset enamel teeth retain a readable silhouette without bloom.
	var count := ceili(absf(lab.held_charge()) * 12.0)
	for i in 12:
		var a := -PI / 2 + (i + 0.5) * TAU / 12 * (1 if lab.held_charge() >= 0 else -1)
		var radial := Vector2.from_angle(a)
		var tangent := radial.orthogonal()
		var p := center + radial * r * 1.2
		var points := PackedVector2Array([p-radial*unit*2-tangent*unit*2, p+radial*unit*2-tangent*unit*2, p+radial*unit*2+tangent*unit*2, p-radial*unit*2+tangent*unit*2])
		draw_colored_polygon(points, color if i < count else ink)
		draw_line(points[1], points[2], color.lightened(0.3) if i < count else Color("53687c"), unit)
	if pose.state in ["ready", "full"]:
		# No independent orbit clock: the accents turn with the actual pinned body.
		# Both accessibility switches freeze this decorative layer completely.
		var turn: float = 0.0 if pose.reduced else lab._spin_angle
		for i in (6 if pose.state == "full" else 3):
			var a := turn + i * TAU / (6 if pose.state == "full" else 3)
			var p := center + Vector2.from_angle(a) * r * 1.55
			_star(p.snapped(Vector2.ONE * unit), unit, color, pose.state == "full")
	# Compact engraved tab replaces the floating percentage label.
	var text := {"charging":"SWING", "ready":"CURVE", "full":"FULL", "disabled":"NO SPIN"}[pose.state] as String
	var font := get_theme_default_font()
	var fs := 16
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var tab := Rect2(center + Vector2(-width/2-8, -r*1.85-24), Vector2(width+16, 24))
	draw_style_box(_tab_style(ink, color), tab)
	draw_string(font, tab.position + Vector2(8,18), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color.lightened(0.35))
	if pose.state == "disabled":
		draw_line(center + Vector2(-r, r), center + Vector2(r, -r), ink, unit*4)
		draw_line(center + Vector2(-r, r), center + Vector2(r, -r), color, unit*2)

func _tab_style(ink: Color, color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = ink
	style.border_color = color
	style.set_border_width_all(1)
	style.corner_radius_top_left = 4
	style.corner_radius_bottom_right = 4
	return style

func _star(p: Vector2, u: float, color: Color, full: bool) -> void:
	# Hand-built stepped glint: dark keyline, coloured shoulders, cream core.
	var length := 4.0 if full else 3.0
	for axis in [Vector2(1,0), Vector2(0,1)]:
		draw_line(p-axis*u*(length+1), p+axis*u*(length+1), Color("101b2d"), u*3)
		draw_line(p-axis*u*length, p+axis*u*length, color, u)
	draw_rect(Rect2(p-Vector2.ONE*u, Vector2.ONE*u*2), Color("fff1ce"))
