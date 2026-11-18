extends PanelContainer
## UI-14 (owner, 2026-11-18): while the player moves the target reticle, the top HUD
## area becomes a magnifier: a close, low view of the front of the rack, with the
## reticle drawn at its true size (the band the ball's centre must cross at the
## target line), so the target can be placed precisely against the pins.
## Shown only while the reticle is being moved: a drag on the lane, a touch held
## on it, or the assist panel's target slider. A quick tap that just places the
## target does not open it. It fades in and out quickly, and while hidden it
## renders nothing.
## The view is a second camera on the lab's own 3D world (the lab gives each roll a
## fresh world, which the magnifier follows); nothing in the lane changes. The
## camera holds still over the lane's centre and the reticle moves across it, as it
## moves across the lane.
const Lane = preload("res://src/simulation/lane_spec.gd")
const UiTheme = preload("res://src/presentation/house_ui_theme.gd")
const FADE_SECONDS := 0.12
const SHOW_AFTER := 0.15 # a touch held this long opens it; one that drags the reticle opens it at once
## The panel: the top bar's left edge and width, made taller to this aspect so
## the view is deep enough for the target line and the pins together; in
## landscape, where the bar is a thin strip, a box at its left end instead.
const ASPECT := 2.8
const MAX_SCREEN_SHARE := 0.24 # of the screen's height
## The camera: behind the target line and above the deck. It frames the target
## line's near side (the ring's near edge) up to the head pin's top, and the whole
## lane's width.
const BACK_M := 1.2
const EYE_M := 0.45
const FRAME_MARGIN := 1.1
const SIDE_MARGIN_M := 0.05

var lab: Control
var view: SubViewport
var camera: Camera3D
var overlay: Control
var alpha := 0.0
var _slider_drag := false
var _touch_seconds := 0.0
var _touch_x := NAN

func _ready() -> void:
	name = "AimMagnifier"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_level = true # placed in screen space over the top HUD
	add_theme_stylebox_override("panel", UiTheme.frame("hud", 6.0, 6.0))
	var holder := SubViewportContainer.new()
	holder.name = "MagnifierView"
	holder.stretch = true
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(holder)
	view = SubViewport.new()
	view.transparent_bg = false
	view.render_target_update_mode = SubViewport.UPDATE_DISABLED
	holder.add_child(view)
	camera = Camera3D.new()
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.near = 0.05
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("0b1116")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.55, 0.52, 0.65)
	environment.ambient_light_energy = 0.7
	camera.environment = environment
	view.add_child(camera)
	camera.current = true
	overlay = Control.new()
	overlay.name = "MagnifierReticle"
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.draw.connect(_draw_reticle)
	holder.add_child(overlay)
	modulate.a = 0.0
	hide()
	var slider: HSlider = lab.assist_panel.target_slider if lab.assist_panel != null else null
	if slider != null:
		slider.drag_started.connect(func(): _slider_drag = true)
		slider.drag_ended.connect(func(_changed): _slider_drag = false)

## True while the player is moving the reticle: dragging it, holding a touch on
## the lane, or dragging the assist slider. Not for a quick tap.
func aiming() -> bool:
	if lab.state != "aim":
		return false
	if _slider_drag:
		return true
	return lab._target_touch != -1 and (_touch_seconds >= SHOW_AFTER or absf(lab.target_x - _touch_x) > 0.002)

func _process(delta: float) -> void:
	if lab == null or lab.lane == null:
		return
	if lab._target_touch == -1:
		_touch_seconds = 0.0
		_touch_x = NAN
	elif is_nan(_touch_x):
		_touch_x = lab.target_x # where the touch put it
	else:
		_touch_seconds += delta
	alpha = move_toward(alpha, 1.0 if aiming() else 0.0, delta / FADE_SECONDS)
	modulate.a = alpha
	var showing := alpha > 0.0
	visible = showing
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS if showing else SubViewport.UPDATE_DISABLED
	if not showing:
		return
	_place()
	if view.world_3d != lab._viewport.world_3d:
		# Each roll's fresh world. Hold the old one through the swap: the engine drops
		# its reference before detaching the view from the old scenario, and when this
		# view held the last reference that scenario would already be freed.
		var previous: World3D = view.world_3d
		view.world_3d = lab._viewport.world_3d
		previous = null
	_frame()
	overlay.queue_redraw()

## Over the top HUD: the bar's left edge and width, ASPECT wide, never shorter than
## the bar nor taller than MAX_SCREEN_SHARE of the screen.
func _place() -> void:
	var bar: Rect2 = lab.hud.bar.get_global_rect()
	var screen: Vector2 = get_viewport_rect().size
	var height := maxf(bar.size.y, minf(bar.size.x / ASPECT, screen.y * MAX_SCREEN_SHARE))
	position = bar.position
	size = Vector2(minf(bar.size.x, height * ASPECT), height)

## Fit the camera to this panel's shape: the ring's near edge low in the view, the
## head pin's top high in it, and the lane's full width across.
func _frame() -> void:
	var aspect: float = maxf(1.0, float(view.size.x) / maxf(1.0, float(view.size.y)))
	var camera_f := Lane.TARGET_PLANE_F - BACK_M
	var ring_m: float = lab.ring_radius * Lane.LANE_HALF_WIDTH
	var low := atan2(EYE_M, Lane.TARGET_PLANE_F - ring_m - camera_f)
	var high := atan2(EYE_M - Lane.PIN_HEIGHT, Lane.HEAD_PIN_F - camera_f)
	var pitch := (low + high) * 0.5
	var across := 2.0 * atan((Lane.LANE_HALF_WIDTH + SIDE_MARGIN_M) / Vector2(BACK_M, EYE_M).length())
	var vertical := maxf((low - high) * FRAME_MARGIN, 2.0 * atan(tan(across * 0.5) / aspect))
	camera.fov = rad_to_deg(vertical)
	camera.position = Lane.world(0.0, camera_f, EYE_M)
	camera.look_at(Lane.world(0.0, camera_f + cos(pitch), EYE_M - sin(pitch)))

## The reticle's centre on the deck, in world space.
func target_point() -> Vector3:
	return Lane.world(lab.target_x * Lane.LANE_HALF_WIDTH, Lane.TARGET_PLANE_F, 0.0)

## The ring at its true size (radii are a fraction of the lane half-width), in the
## magnifier's perspective, with a small centre mark.
func _draw_reticle() -> void:
	if not visible or camera == null:
		return
	var centre := target_point()
	var radius: float = lab.ring_radius * Lane.LANE_HALF_WIDTH
	var points := PackedVector2Array()
	for i in 49:
		var angle := TAU * i / 48.0
		var world := centre + Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
		if camera.is_position_behind(world):
			continue
		points.append(camera.unproject_position(world))
	if points.size() > 2:
		overlay.draw_polyline(points, Color(0, 0, 0, 0.55), 5.0, true)
		overlay.draw_polyline(points, lab.ring_color(), 2.5, true)
	var mark := camera.unproject_position(centre)
	overlay.draw_line(mark + Vector2(-6, 0), mark + Vector2(6, 0), lab.ring_color(), 2.0)
	overlay.draw_line(mark + Vector2(0, -6), mark + Vector2(0, 6), lab.ring_color(), 2.0)

## Where the reticle's centre appears in the magnifier (local to the panel), for tests.
func reticle_position() -> Vector2:
	return overlay.get_global_rect().position - global_position + camera.unproject_position(target_point())

## Where a lane point appears in the magnifier (local to the panel), for tests.
func lane_position(world: Vector3) -> Vector2:
	return overlay.get_global_rect().position - global_position + camera.unproject_position(world)
