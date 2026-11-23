extends PanelContainer
## UI-14 (owner, 2026-11-18): while the player moves the target reticle, the top HUD
## area becomes a magnifier: a zoomed-in view of exactly what the player sees down
## the lane ("just with better quality"): the same camera, the same reticle and
## target marker, cropped around the pin deck and rendered at full resolution
## (the lane itself renders at half resolution for its pixel look).
## Shown only while the reticle is being moved: a drag on the lane, a touch held
## on it, or the assist panel's target slider. A quick tap that just places the
## target does not open it. It fades in and out quickly, and while hidden it
## renders nothing.
## How: a second camera on the lab's own 3D world copies the lane camera's pose and
## uses an off-axis frustum, so its picture is an exact crop of the lane's. Over
## it, a second copy of the lane's aim overlay is drawn scaled by the same zoom.
## Nothing in the lane changes; the lab gives each roll a fresh world, which the
## magnifier follows.
const Lane = preload("res://src/simulation/lane_spec.gd")
const UiTheme = preload("res://src/presentation/house_ui_theme.gd")
const AimOverlay = preload("res://src/presentation/aim_overlay.gd")
const FADE_SECONDS := 0.12
const SHOW_AFTER := 0.15 # a touch held this long opens it; one that drags the reticle opens it at once
## The crop (the owner's reference framing): the lane at the head pin spans this
## share of the magnifier's width, and the head pin's base sits this far down it.
const LANE_SHARE := 0.44
const PIN_BASE_AT := 0.75
## The panel: the top bar's left edge and width, made taller to this aspect; in
## landscape, where the bar is a thin strip, a box at its left end instead.
const ASPECT := 2.8
const MAX_SCREEN_SHARE := 0.24 # of the screen's height

var lab: Control
var view: SubViewport
var camera: Camera3D
var overlay: Control
var zoomed: Control # the lane's aim overlay, scaled to the crop
var crop := Rect2() # the part of the lane's view shown, in lab coordinates
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
	view.render_target_update_mode = SubViewport.UPDATE_DISABLED
	holder.add_child(view)
	view.transparent_bg = true # the lane's view is transparent too
	camera = Camera3D.new()
	camera.environment = lab._camera.environment
	view.add_child(camera)
	camera.current = true
	overlay = Control.new()
	overlay.name = "MagnifierReticle"
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.clip_contents = true
	holder.add_child(overlay)
	zoomed = AimOverlay.new()
	zoomed.name = "ZoomedAim"
	zoomed.lab = lab
	overlay.add_child(zoomed)
	zoomed.set_anchors_preset(Control.PRESET_TOP_LEFT)
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
	if lab.alley_screen != null and lab.alley_screen.playing():
		return false # the alley screen has the window (UI-20)
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
	zoomed.set_process(showing)
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

## Over the top HUD: the bar's left edge and width, ASPECT wide, never shorter than
## the bar nor taller than MAX_SCREEN_SHARE of the screen.
func _place() -> void:
	var rect := panel_rect(lab, get_viewport_rect().size)
	position = rect.position
	size = rect.size

## The window over the top HUD, in screen space; the alley screen (UI-20) uses the same.
static func panel_rect(lab_node: Control, screen: Vector2) -> Rect2:
	var bar: Rect2 = lab_node.hud.bar.get_global_rect()
	var height := maxf(bar.size.y, minf(bar.size.x / ASPECT, screen.y * MAX_SCREEN_SHARE))
	return Rect2(bar.position, Vector2(minf(bar.size.x, height * ASPECT), height))

## The crop of the lane's view, in lab coordinates: centred on the lane at the
## head pin, LANE_SHARE of its width the lane, with the head pin's base at
## PIN_BASE_AT of its height; shaped like the magnifier.
func crop_rect() -> Rect2:
	var shape: Vector2 = overlay.size if overlay.size.y > 0.0 else size
	var left: Vector2 = lab.screen_point(Lane.world(-Lane.LANE_HALF_WIDTH, Lane.HEAD_PIN_F, 0.0))
	var right: Vector2 = lab.screen_point(Lane.world(Lane.LANE_HALF_WIDTH, Lane.HEAD_PIN_F, 0.0))
	var width: float = (right.x - left.x) / LANE_SHARE
	var height: float = width * shape.y / maxf(1.0, shape.x)
	var base: Vector2 = (left + right) * 0.5
	return Rect2(Vector2(base.x - width * 0.5, base.y - height * PIN_BASE_AT), Vector2(width, height))

## The magnification: magnifier pixels per lab pixel.
func zoom() -> float:
	return overlay.size.x / maxf(1.0, crop.size.x)

## The lane camera's pose, with an off-axis frustum that sees only the crop; and
## the lane's overlay, scaled and shifted by the same crop.
func _frame() -> void:
	var lane_camera: Camera3D = lab._camera
	var lab_size: Vector2 = lab.size
	var lane_aspect: float = float(lab._viewport.size.x) / maxf(1.0, float(lab._viewport.size.y))
	crop = crop_rect()
	camera.global_transform = lane_camera.global_transform
	var half := lane_camera.near * tan(deg_to_rad(lane_camera.fov) * 0.5)
	var half_height := half / lane_aspect if lane_camera.keep_aspect == Camera3D.KEEP_WIDTH else half
	var half_width := half_height * lane_aspect
	var centre := crop.get_center() / lab_size
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.set_frustum(crop.size.y / lab_size.y * 2.0 * half_height,
		Vector2((centre.x * 2.0 - 1.0) * half_width, (1.0 - centre.y * 2.0) * half_height),
		lane_camera.near, lane_camera.far)
	var k := zoom()
	zoomed.size = lab_size
	zoomed.scale = Vector2(k, k)
	zoomed.position = -crop.position * k
	zoomed.queue_redraw()

## The reticle's centre on the deck, in world space.
func target_point() -> Vector3:
	return Lane.world(lab.target_x * Lane.LANE_HALF_WIDTH, Lane.TARGET_PLANE_F, 0.0)

## Where the reticle's centre appears in the magnifier (local to the panel), for tests.
## (The zoomed overlay's ring, which must sit where the 3D view shows the target.)
func reticle_position() -> Vector2:
	return overlay.get_global_rect().position - global_position + (lab.screen_point(target_point()) - crop.position) * zoom()

## Where a lane point appears in the magnifier (local to the panel), for tests.
func lane_position(world: Vector3) -> Vector2:
	return overlay.get_global_rect().position - global_position + camera.unproject_position(world)
