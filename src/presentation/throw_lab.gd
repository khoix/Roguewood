extends Control
## Throw lab (E04 straight, E05 spin/curve): elevated behind-ball camera, hold /
## circle / flick gestures, a movable contracting target ring, accessible controls
## and a two-roll frame where survivors are respotted. Every roll runs in a fresh
## World3D so it depends only on its rack state and committed launch.
## Developmental presentation; frame scoring and its display belong to E06.
signal roll_reported(report: Dictionary)
const Lane = preload("res://src/simulation/lane_spec.gd")
const LaneWorld = preload("res://src/simulation/lane_world.gd")
const Dressing = preload("res://src/presentation/lane_dressing.gd")
const AimOverlay = preload("res://src/presentation/aim_overlay.gd")
const SettingsPanel = preload("res://src/presentation/throw_settings_panel.gd")
const AssistPanel = preload("res://src/presentation/assist_panel.gd")
const Flick = preload("res://src/input/flick_gesture.gd")
const Mapper = preload("res://src/input/launch_mapper.gd")
const Ring = preload("res://src/input/target_ring.gd")
const RESULT_HOLD_SEC := 1.2
const AIM_BACK := 2.0
const AIM_HEIGHT := 1.05
const DECK_VIEW_F := Lane.HEAD_PIN_F - 4.0
const TOP_UI_HEIGHT := 96.0 # session bar band; touches there are never throws
const RING_COLORS := {"clean": Color(1.0, 1.0, 1.0), "sweet": Color(0.3, 0.95, 0.85), "perfect": Color(1.0, 0.8, 0.2)}

var state := "aim"
var frame_number := 1
var roll_index := 1
var rack: Dictionary = Lane.fresh_rack()
var start_x := 0.0
var target_x := Lane.DEFAULT_TARGET_X
var ring_radius := Ring.RING_MAX
var frame_reports: Array = []
var history: Array = []
var trials: Array = []
var cancels := 0
var last_cancel := ""
var last_source := ""
var settings: Dictionary = {}
var trial_log_path := "user://throw_trials.jsonl"
var lane: LaneWorld
var status: Label
var next_rack: Button
var settings_panel: SettingsPanel
var assist_panel: AssistPanel
var _viewport: SubViewport
var _camera: Camera3D
var _marker: MeshInstance3D
var _dressing := Dressing.new()
var _flick := Flick.new()
var _touch := -1
var _target_touch := -1
var _hold_source := "touch"
var _hold_start_x := 0.0
var _clock_usec := 0
var _ring_start_usec := 0
var _result_timer := 0.0
var _launch_serial := 0
var _last_input: Dictionary = {}
var _handedness := ""

func _ready() -> void:
	SettingsPanel.with_defaults(settings)
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
	_build_ring()
	var overlay := AimOverlay.new()
	overlay.name = "AimOverlay"
	overlay.lab = self
	add_child(overlay)
	status = Label.new()
	status.name = "ThrowStatus"
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_font_size_override("font_size", 26)
	status.add_theme_color_override("font_outline_color", Color.BLACK)
	status.add_theme_constant_override("outline_size", 6)
	status.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	status.offset_top = TOP_UI_HEIGHT + 4.0
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
	assist_panel = AssistPanel.new()
	assist_panel.throw_requested.connect(_assist_throw)
	assist_panel.preview_changed.connect(_assist_preview)
	add_child(assist_panel)
	settings_panel = SettingsPanel.new()
	settings_panel.settings = settings
	settings_panel.changed.connect(_apply_settings)
	settings_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	settings_panel.hide()
	add_child(settings_panel)
	_apply_settings()
	_new_roll()

## In-world target marker; the readable ring itself is drawn by the aim overlay.
func _build_ring() -> void:
	var arrow := PrismMesh.new()
	arrow.size = Vector3(0.12, 0.14, 0.03)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.no_depth_test = true
	_marker = MeshInstance3D.new()
	_marker.name = "TargetMarker"
	_marker.mesh = arrow
	_marker.material_override = material
	_marker.rotation_degrees = Vector3(0.0, 0.0, 180.0)
	_viewport.add_child(_marker)

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
	start_x = assist_panel.values().start_x if settings.assist else 0.0
	lane.place_ball(start_x)
	state = "aim"
	_ring_start_usec = _clock_usec
	_camera.position = Lane.world(0.0, Lane.BALL_START_F - AIM_BACK, AIM_HEIGHT)
	_camera.look_at(Lane.world(0.0, 11.0, 0.0))
	_update_status()

func _apply_settings() -> void:
	if settings.handedness != _handedness:
		_handedness = settings.handedness
		target_x = Ring.default_target(_handedness)
		assist_panel.set_target(target_x)
	_flick.sensitivity = settings.sensitivity
	assist_panel.visible = settings.assist
	var left: bool = settings.handedness == "left"
	assist_panel.set_anchors_preset(Control.PRESET_CENTER_LEFT if left else Control.PRESET_CENTER_RIGHT)
	assist_panel.offset_left = 12.0 if left else -312.0
	assist_panel.offset_right = 312.0 if left else -12.0
	assist_panel.offset_top = -40.0
	assist_panel.offset_bottom = 330.0
	if settings.assist and state == "aim" and lane:
		_assist_preview(assist_panel.values())
	_update_status()

func toggle_settings() -> void:
	settings_panel.visible = not settings_panel.visible
	if settings_panel.visible:
		settings_panel.handedness.grab_focus()

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
	var ringing: bool = state == "holding" or (state == "aim" and settings.assist)
	ring_radius = Ring.radius(_clock_usec - _ring_start_usec, settings.reduced_motion) if ringing else Ring.RING_MAX
	_update_ring()
	if state == "holding" and not settings.reduced_motion and lane.state == "ready":
		lane.aim_ball.rotate(Vector3.FORWARD, _flick.charge() * 12.0 * delta)
	if state == "result":
		_result_timer += delta
		if _result_timer >= RESULT_HOLD_SEC:
			_advance()

func _update_ring() -> void:
	_marker.visible = state in ["aim", "holding"]
	if _marker.visible:
		_marker.position = Lane.world(target_x * Lane.LANE_HALF_WIDTH, Lane.TARGET_PLANE_F, 0.55)
		(_marker.material_override as StandardMaterial3D).albedo_color = ring_color()

func ring_color() -> Color:
	return RING_COLORS[Ring.grade(ring_radius)]

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and state == "aim" and _touch == -1 and _target_touch == -1 and not _over_ui(event.position):
			if _on_ball(event.position) and not settings.assist:
				_touch = event.index
				_hold_source = "mouse" if event.device == InputEvent.DEVICE_ID_EMULATION else "touch"
				_hold_start_x = start_x
				_ring_start_usec = _clock_usec
				_flick.begin(_normalized(event.position), _clock_usec)
				state = "holding"
				_update_status()
			elif _in_target_zone(event.position):
				_target_touch = event.index
				_set_target_from(event.position)
			else:
				return
		elif not event.pressed and state == "holding" and event.index == _touch:
			if event.canceled:
				_cancel("touch_canceled")
			else:
				_release(event.position)
		elif not event.pressed and event.index == _target_touch:
			_target_touch = -1
		else:
			return
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		if state == "holding" and event.index == _touch:
			_flick.move(_normalized(event.position), _clock_usec)
			lane.place_ball(_placed_x(_flick.placement(), _flick.origin))
		elif state == "aim" and event.index == _target_touch:
			_set_target_from(event.position)
		else:
			return
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if state == "holding" and what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_WINDOW_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED]:
		_cancel("interrupted")

func _release(position: Vector2) -> void:
	var origin := _flick.origin
	var frozen := Ring.radius(_clock_usec - _ring_start_usec, settings.reduced_motion)
	var flick := _flick.release(_normalized(position), _clock_usec)
	if not flick.committed:
		_cancel(flick.reason)
		return
	var x := _placed_x(flick.placement, origin)
	var launch := Mapper.to_launch(flick, x, "lab-%d" % (_launch_serial + 1), roll_index, target_x, frozen)
	_last_input = {"source": _hold_source, "speed": flick.speed, "screen_angle_deg": flick.angle_deg, "turn_deg": flick.turn_deg,
		"spin": flick.spin, "power": flick.power}
	_commit(launch, _hold_source)

func _assist_throw(controls: Dictionary) -> void:
	if state != "aim" or not settings.assist:
		return
	target_x = controls.target_x
	var frozen := Ring.radius(_clock_usec - _ring_start_usec, settings.reduced_motion)
	var launch := Mapper.from_controls(controls, "lab-%d" % (_launch_serial + 1), roll_index, target_x, frozen)
	_last_input = {"source": "assist", "controls": controls.duplicate()}
	_commit(launch, "assist")

func _assist_preview(controls: Dictionary) -> void:
	if state != "aim":
		return
	start_x = controls.start_x
	target_x = controls.target_x
	lane.place_ball(start_x)

func _commit(launch: Dictionary, source: String) -> void:
	var errors := lane.commit(launch)
	if not errors.is_empty():
		push_error("Rejected lab launch: " + str(errors))
		_cancel("rejected")
		return
	_launch_serial += 1
	start_x = launch.start_x
	_touch = -1
	last_cancel = ""
	last_source = source
	state = "rolling"
	_update_status()

## Cancelling restores the pre-gesture ball and consumes no roll or launch.
func _cancel(reason: String) -> void:
	_flick.cancel()
	_touch = -1
	start_x = _hold_start_x
	lane.place_ball(start_x)
	lane.aim_ball.rotation = Vector3.ZERO
	cancels += 1
	last_cancel = reason
	state = "aim"
	_update_status()

func _on_roll_finished(report: Dictionary) -> void:
	frame_reports.append(report)
	history.append(report)
	_log_trial(report)
	state = "result"
	_result_timer = 0.0
	_update_status()
	roll_reported.emit(report)

## One JSON line per committed roll: what the player did and what happened. Device
## trials (docs/playtests) read this file; nothing here affects play.
func _log_trial(report: Dictionary) -> void:
	var hook := Lane.hook_at_target(report.launch, report.knockdown_log)
	var entry := {"schema_version": 1, "clock_usec": _clock_usec, "frame": frame_number, "roll": roll_index, "input": _last_input,
		"launch": report.launch, "curved": Lane.is_curved(report.launch.spin), "hook_m": null if is_nan(hook) else hook,
		"fallen": report.roll_result.fallen_positions, "standing": report.knockdown_log.standing, "gutter": report.knockdown_log.gutter,
		"accuracy": report.roll_result.accuracy, "settings": settings.duplicate(), "viewport": [size.x, size.y]}
	trials.append(entry)
	if trial_log_path.is_empty():
		return
	var file := FileAccess.open(trial_log_path, FileAccess.READ_WRITE)
	if file == null:
		file = FileAccess.open(trial_log_path, FileAccess.WRITE)
	if file == null:
		push_warning("Trial log unavailable: " + trial_log_path)
		return
	file.seek_end()
	file.store_line(JSON.stringify(entry, "", true, true))

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

## Lab-local screen position of a lane point (overlay drawing, automated input).
func screen_point(point: Vector3) -> Vector2:
	return _screen(point)

## Moves the target to the lane x under the finger on the ring's plane.
func _set_target_from(position: Vector2) -> void:
	var local := position * Vector2(_viewport.size) / size
	var origin := _camera.project_ray_origin(local)
	var direction := _camera.project_ray_normal(local)
	if absf(direction.z) < 1e-6:
		return
	var t := (-Lane.TARGET_PLANE_F - origin.z) / direction.z
	if t <= 0.0:
		return
	target_x = Ring.clamp_target((origin.x + direction.x * t) / Lane.LANE_HALF_WIDTH)
	assist_panel.set_target(target_x)
	_update_status()

func _in_target_zone(position: Vector2) -> bool:
	return position.y < _screen(lane.ball_position()).y - ball_touch_radius() * 1.2

func _over_ui(position: Vector2) -> bool:
	if position.y < TOP_UI_HEIGHT:
		return true
	var global := get_global_transform() * position
	for control in [settings_panel, assist_panel, next_rack]:
		if control.visible and control.get_global_rect().has_point(global):
			return true
	return false

## Canvas position of the ball, for touch hit-testing and automated input.
func ball_screen_position() -> Vector2:
	return get_global_transform() * _screen(lane.ball_position())

func ball_touch_radius() -> float:
	var center := _screen(lane.ball_position())
	var edge := _screen(lane.ball_position() + _camera.global_transform.basis.x * Lane.BALL_RADIUS)
	var factor := 2.6 if settings.large_targets else 1.8
	var minimum := 0.1 if settings.large_targets else 0.07
	return maxf(center.distance_to(edge) * factor, minimum * minf(size.x, size.y))

func _on_ball(position: Vector2) -> bool:
	return lane != null and position.distance_to(_screen(lane.ball_position())) <= ball_touch_radius()

## Spin shown by the meter and guide: live gesture charge or the assist setting.
func charged_spin() -> float:
	if state == "holding":
		return _flick.charge()
	return assist_panel.values().spin if settings.assist and state == "aim" else 0.0

func _update_status() -> void:
	if status == null:
		return
	var lead := "Frame %d · Roll %d · Target %+.2f" % [frame_number, roll_index, target_x]
	match state:
		"aim":
			if settings.assist:
				status.text = lead + "\nSet position, aim, power and spin, then Throw."
			else:
				status.text = lead + "\nHold the ball · circle to spin · flick up. Tap the lane to move the target."
			if not last_cancel.is_empty():
				status.text += "\nNo throw (%s) — nothing used." % last_cancel.replace("_", " ")
		"holding":
			status.text = lead + "\nCircle to spin, flick up to release. Let go without a flick to cancel."
		"rolling":
			var spin: float = lane.launch.get("spin", 0.0)
			status.text = lead + "\nRolling… " + ("curved %s" % ("right" if spin > 0.0 else "left") if Lane.is_curved(spin) else "straight")
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
	var text := "%d down %s · %s" % [fallen.size(), str(fallen), report.roll_result.accuracy]
	if not knockdowns.standing.is_empty():
		text += " · standing %s" % str(knockdowns.standing)
	return text
