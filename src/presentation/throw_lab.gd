extends Control
## E04 throw lab: elevated behind-ball camera, straight hold/drag/flick, and a
## two-roll frame where survivors are respotted. Every roll runs in a fresh
## World3D so it depends only on its rack state and committed launch.
## Developmental presentation; frame scoring and its display belong to E06.
signal roll_reported(report: Dictionary)
const Lane = preload("res://src/simulation/lane_spec.gd")
const LaneWorld = preload("res://src/simulation/lane_world.gd")
const Dressing = preload("res://src/presentation/lane_dressing.gd")
const Flick = preload("res://src/input/flick_gesture.gd")
const Mapper = preload("res://src/input/launch_mapper.gd")
const RESULT_HOLD_SEC := 1.2
const AIM_BACK := 2.0
const AIM_HEIGHT := 1.05
const DECK_VIEW_F := Lane.HEAD_PIN_F - 4.0
const BALL_TOUCH_SCALE := 1.8
const MIN_TOUCH_RADIUS := 0.07 # of the shorter viewport side

var state := "aim"
var frame_number := 1
var roll_index := 1
var rack: Dictionary = Lane.fresh_rack()
var start_x := 0.0
var frame_reports: Array = []
var history: Array = []
var cancels := 0
var last_cancel := ""
var lane: LaneWorld
var status: Label
var next_rack: Button
var _viewport: SubViewport
var _camera: Camera3D
var _dressing := Dressing.new()
var _flick := Flick.new()
var _touch := -1
var _hold_start_x := 0.0
var _clock_usec := 0
var _result_timer := 0.0
var _launch_serial := 0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var container := SubViewportContainer.new()
	container.name = "LaneView"
	container.stretch = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(container)
	_viewport = SubViewport.new()
	container.add_child(_viewport)
	_camera = Camera3D.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.05, 0.04, 0.1)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.55, 0.52, 0.65)
	environment.ambient_light_energy = 0.7
	_camera.environment = environment
	_viewport.add_child(_camera)
	_camera.current = true
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50.0, 25.0, 0.0)
	light.light_energy = 1.1
	_viewport.add_child(light)
	status = Label.new()
	status.name = "ThrowStatus"
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_font_size_override("font_size", 26)
	status.add_theme_color_override("font_outline_color", Color.BLACK)
	status.add_theme_constant_override("outline_size", 6)
	status.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	status.offset_top = 100
	status.offset_left = 24
	status.offset_right = -24
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(status)
	next_rack = Button.new()
	next_rack.name = "NextRack"
	next_rack.text = "Next Rack"
	next_rack.custom_minimum_size = Vector2(320, 72)
	next_rack.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	next_rack.position = Vector2(-160, -36)
	next_rack.pressed.connect(_next_rack)
	next_rack.hide()
	add_child(next_rack)
	_new_roll()

func _new_roll() -> void:
	if lane:
		_viewport.remove_child(lane)
		lane.free()
	# Keep the old world alive until the viewport has detached from its scenario.
	var retired := _viewport.world_3d
	_viewport.world_3d = World3D.new()
	retired = null
	lane = LaneWorld.new()
	lane.name = "Lane"
	_viewport.add_child(lane)
	lane.setup(rack, _dressing)
	lane.roll_finished.connect(_on_roll_finished)
	start_x = 0.0
	lane.place_ball(start_x)
	state = "aim"
	_camera.position = Lane.world(0.0, Lane.BALL_START_F - AIM_BACK, AIM_HEIGHT)
	_camera.look_at(Lane.world(0.0, 11.0, 0.0))
	_update_status()

func _process(delta: float) -> void:
	_clock_usec += int(round(delta * 1000000.0))
	_camera.keep_aspect = Camera3D.KEEP_WIDTH if size.y > size.x else Camera3D.KEEP_HEIGHT
	_camera.fov = 44.0 if size.y > size.x else 50.0
	if state in ["rolling", "result", "frame_done"]:
		var ball_f: float = -lane.ball_position().z
		var cam_f := clampf(ball_f - 2.6, Lane.BALL_START_F - AIM_BACK, DECK_VIEW_F)
		var target := Lane.world(0.0, cam_f, lerpf(AIM_HEIGHT, 1.25, inverse_lerp(0.0, DECK_VIEW_F, cam_f)))
		_camera.position = _camera.position.lerp(target, 1.0 - exp(-8.0 * delta))
		_camera.look_at(Lane.world(0.0, minf(_camera.position.z * -1.0 + 6.0, Lane.HEAD_PIN_F + 0.35), 0.12))
	if state == "result":
		_result_timer += delta
		if _result_timer >= RESULT_HOLD_SEC:
			_advance()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and state == "aim" and _on_ball(event.position):
			_touch = event.index
			_hold_start_x = start_x
			_flick.begin(_normalized(event.position), _clock_usec)
			state = "holding"
			_update_status()
		elif not event.pressed and state == "holding" and event.index == _touch:
			if event.canceled:
				_cancel("touch_canceled")
			else:
				_release(event.position)
		else:
			return
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and state == "holding" and event.index == _touch:
		_flick.move(_normalized(event.position), _clock_usec)
		lane.place_ball(_placed_x(_flick.placement(), _flick.origin))
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if state == "holding" and what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_WINDOW_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED]:
		_cancel("interrupted")

func _release(position: Vector2) -> void:
	var origin := _flick.origin
	var flick := _flick.release(_normalized(position), _clock_usec)
	if not flick.committed:
		_cancel(flick.reason)
		return
	var x := _placed_x(flick.anchor, origin)
	var launch := Mapper.to_launch(flick, x, "lab-%d" % (_launch_serial + 1), roll_index)
	var errors := lane.commit(launch)
	if not errors.is_empty():
		push_error("Rejected lab launch: " + str(errors))
		_cancel("rejected")
		return
	_launch_serial += 1
	start_x = x
	_touch = -1
	last_cancel = ""
	state = "rolling"
	_update_status()

## Cancelling restores the pre-gesture ball and consumes no roll or launch.
func _cancel(reason: String) -> void:
	_flick.cancel()
	_touch = -1
	start_x = _hold_start_x
	lane.place_ball(start_x)
	cancels += 1
	last_cancel = reason
	state = "aim"
	_update_status()

func _on_roll_finished(report: Dictionary) -> void:
	frame_reports.append(report)
	history.append(report)
	state = "result"
	_result_timer = 0.0
	_update_status()
	roll_reported.emit(report)

func _advance() -> void:
	var report: Dictionary = frame_reports[-1]
	if roll_index == 1 and not report.knockdown_log.standing.is_empty():
		roll_index = 2
		rack = report.rack_after
		_new_roll()
	else:
		state = "frame_done"
		next_rack.show()
		next_rack.grab_focus()
		_update_status()

func _next_rack() -> void:
	if state != "frame_done":
		return
	frame_number += 1
	roll_index = 1
	frame_reports = []
	rack = Lane.fresh_rack()
	next_rack.hide()
	_new_roll()

func _normalized(position: Vector2) -> Vector2:
	return position / minf(size.x, size.y)

## Ball lane x for a finger position: the ball follows sideways finger travel at
## the ball's own depth, so the lane under the finger stays under the finger.
func _placed_x(finger: Vector2, origin: Vector2) -> float:
	var left := _screen(Lane.world(-Lane.LANE_HALF_WIDTH, Lane.BALL_START_F, Lane.BALL_RADIUS))
	var right := _screen(Lane.world(Lane.LANE_HALF_WIDTH, Lane.BALL_START_F, Lane.BALL_RADIUS))
	var lane_units_per_norm := 2.0 * minf(size.x, size.y) / maxf(right.x - left.x, 1.0)
	return clampf(_hold_start_x + (finger.x - origin.x) * lane_units_per_norm, -Lane.MAX_START_X, Lane.MAX_START_X)

func _screen(point: Vector3) -> Vector2:
	return _camera.unproject_position(point) * size / Vector2(_viewport.size)

## Canvas position of the ball, for touch hit-testing and automated input.
func ball_screen_position() -> Vector2:
	return get_global_transform() * _screen(lane.ball_position())

func ball_touch_radius() -> float:
	var center := _screen(lane.ball_position())
	var edge := _screen(lane.ball_position() + _camera.global_transform.basis.x * Lane.BALL_RADIUS)
	return maxf(center.distance_to(edge) * BALL_TOUCH_SCALE, MIN_TOUCH_RADIUS * minf(size.x, size.y))

func _on_ball(position: Vector2) -> bool:
	return lane != null and position.distance_to(_screen(lane.ball_position())) <= ball_touch_radius()

func _update_status() -> void:
	var lead := "Frame %d · Roll %d" % [frame_number, roll_index]
	match state:
		"aim":
			status.text = lead + "\nHold the ball, drag to line up, flick up to throw."
			if not last_cancel.is_empty():
				status.text += "\nNo throw (%s) — nothing used." % last_cancel.replace("_", " ")
		"holding":
			status.text = lead + "\nFlick up to release. Let go without a flick to cancel."
		"rolling":
			status.text = lead + "\nRolling…"
		"result":
			status.text = lead + "\n" + _describe(frame_reports[-1])
		"frame_done":
			var parts: Array = frame_reports.map(func(r): return str(r.roll_result.fallen_positions.size()))
			status.text = "Frame %d complete · %s" % [frame_number, " / ".join(parts)]
			if frame_reports[0].roll_result.fallen_positions.size() == 10:
				status.text += " · Strike!"
			elif frame_reports[-1].knockdown_log.standing.is_empty():
				status.text += " · Spare!"

func _describe(report: Dictionary) -> String:
	var knockdowns: Dictionary = report.knockdown_log
	if knockdowns.gutter:
		return "Gutter — pinfall doesn't count; rack respotted."
	var fallen: Array = report.roll_result.fallen_positions
	var text := "%d down %s" % [fallen.size(), str(fallen)]
	if not knockdowns.standing.is_empty():
		text += " · standing %s" % str(knockdowns.standing)
	return text
