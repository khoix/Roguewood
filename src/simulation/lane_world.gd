extends Node3D
## One roll's physics: static lane, standing pins and the House ball. Callers build a
## fresh instance inside a fresh World3D for every roll, so a roll is a function of
## its rack state and committed launch only. Outcomes leave as copied JSON data.
## Aiming moves a visual-only ball; the physical ball enters the world at the launch
## tick, so how long or where the player aimed never touches the physics history.
signal roll_finished(report: Dictionary)
const Lane = preload("res://src/simulation/lane_spec.gd")
const Tracker = preload("res://src/simulation/knockdown_tracker.gd")
const Contracts = preload("res://src/contracts/contracts.gd")
const HULL_SEGMENTS := 12
const SEPARATION := 2.0 * Lane.PIN_BELLY_RADIUS + 0.002
const GUTTER_SEGMENTS := 8
const CONTACT_IMPULSE := 1e-4

var ball: RigidBody3D
var aim_ball: Node3D
var pins: Dictionary = {}
var tracker: Tracker
var launch: Dictionary = {}
var report: Dictionary = {}
var state := "ready"
var _tokens: Dictionary = {}
var _pending := false
var _dressing: Object
var _rack_in: Array = []
var _ball_material: PhysicsMaterial
var _zone_friction := 0.0

## dressing (optional) attaches presentation meshes; it never adds collision.
func setup(rack_state: Dictionary, dressing: Object = null) -> void:
	_dressing = dressing
	# One seamless surface from approach to pit: abutting boxes create internal
	# edges that make a rolling ball hop. The oil pattern is the ball's friction (ADR 003).
	# Jolt combines friction by minimum and bounce by sum (measured E04): pin-pin
	# restitution is 2 x PIN_BOUNCE, ball-pin is BALL_BOUNCE + PIN_BOUNCE.
	var surface := _material(Lane.SURFACE_FRICTION, 0.0)
	var wall := _material(0.3, 0.2)
	var pit := _material(0.6, 0.0)
	var h := Lane.LANE_HALF_WIDTH
	var g := Lane.GUTTER_WIDTH
	_box("lane", -Lane.APPROACH_LENGTH, Lane.PIT_F, -h, h, -0.2, 0.0, surface, "lane")
	for side in [-1.0, 1.0]:
		var outer: float = side * (h + g)
		_gutter(side, surface)
		# A continuous cap; kickbacks stand back so no wall corner lies within Jolt's
		# speculative contact distance of a gutter ball (corners there cause ghost hits).
		var cap_edge: float = outer + side * 0.1
		_box("cap", 0.0, Lane.PIT_F + Lane.PIT_LENGTH, minf(outer, cap_edge), maxf(outer, cap_edge), -Lane.GUTTER_DEPTH, 0.03, wall, "cap")
		var back: float = outer + side * Lane.KICKBACK_SETBACK
		var back_edge: float = back + side * 0.1
		_box("kickback", Lane.KICKBACK_START_F, Lane.PIT_F + Lane.PIT_LENGTH, minf(back, back_edge), maxf(back, back_edge), -Lane.PIT_DEPTH, Lane.KICKBACK_HEIGHT, wall, "kickback")
	var w := h + g + Lane.KICKBACK_SETBACK
	_box("pit", Lane.PIT_F, Lane.PIT_F + Lane.PIT_LENGTH, -w, w, -Lane.PIT_DEPTH - 0.1, -Lane.PIT_DEPTH, pit, "pit")
	_box("cushion", Lane.PIT_F + Lane.PIT_LENGTH, Lane.PIT_F + Lane.PIT_LENGTH + 0.1, -w, w, -Lane.PIT_DEPTH, 1.0, pit, "cushion")
	_rack_in = resolve_overlaps(rack_state.standing)
	for entry in _rack_in:
		_add_pin(int(entry.position), float(entry.x), float(entry.f))
	_add_ball()

func _material(friction: float, bounce: float) -> PhysicsMaterial:
	var material := PhysicsMaterial.new()
	material.friction = friction
	material.bounce = bounce
	return material

func _box(label: String, f0: float, f1: float, x0: float, x1: float, y0: float, y1: float, material: PhysicsMaterial, role: String) -> void:
	var body := StaticBody3D.new()
	body.name = label.capitalize().replace(" ", "")
	body.physics_material_override = material
	var size := Vector3(x1 - x0, y1 - y0, f1 - f0)
	body.position = Lane.world((x0 + x1) * 0.5, (f0 + f1) * 0.5, (y0 + y1) * 0.5)
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	shape.shape.size = size
	body.add_child(shape)
	add_child(body, true)
	_tokens[body.get_instance_id()] = "static"
	if _dressing:
		_dressing.dress_static(body, size, role)

## Concave arc channel (regulation width/depth) running the full lane length. Its
## long faces run parallel to travel, so a gutter ball meets no internal edges.
func _gutter(side: float, material: PhysicsMaterial) -> void:
	var chord := Lane.GUTTER_WIDTH * 0.5
	var radius := (chord * chord + Lane.GUTTER_DEPTH * Lane.GUTTER_DEPTH) / (2.0 * Lane.GUTTER_DEPTH)
	var center_x := side * (Lane.LANE_HALF_WIDTH + chord)
	var center_y := radius - Lane.GUTTER_DEPTH
	var half_angle := asin(chord / radius)
	var faces := PackedVector3Array()
	for segment in GUTTER_SEGMENTS:
		var angles := [lerpf(-half_angle, half_angle, float(segment) / GUTTER_SEGMENTS), lerpf(-half_angle, half_angle, float(segment + 1) / GUTTER_SEGMENTS)]
		var near: Array[Vector3] = []
		var far: Array[Vector3] = []
		for angle in angles:
			var x: float = center_x + sin(angle) * radius
			var y: float = center_y - cos(angle) * radius
			near.append(Lane.world(x, 0.0, y))
			far.append(Lane.world(x, Lane.PIT_F, y))
		faces.append_array([near[0], far[0], far[1], near[0], far[1], near[1]])
	var shape := ConcavePolygonShape3D.new()
	shape.backface_collision = true
	shape.set_faces(faces)
	var body := StaticBody3D.new()
	body.name = "GutterLeft" if side < 0.0 else "GutterRight"
	body.physics_material_override = material
	var holder := CollisionShape3D.new()
	holder.shape = shape
	body.add_child(holder)
	add_child(body, true)
	_tokens[body.get_instance_id()] = "static"
	if _dressing:
		_dressing.dress_gutter(body, faces)

static func hull_points(first: int, last: int) -> PackedVector3Array:
	var points := PackedVector3Array()
	for index in range(first, last + 1):
		var ring: Array = Lane.PIN_PROFILE[index]
		for segment in HULL_SEGMENTS:
			var angle := TAU * segment / HULL_SEGMENTS
			points.append(Vector3(cos(angle) * ring[1], ring[0], sin(angle) * ring[1]))
	return points

func _add_pin(position: int, x: float, f: float) -> void:
	var pin := RigidBody3D.new()
	pin.name = "Pin%d" % position
	pin.mass = Lane.PIN_MASS
	pin.center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	pin.center_of_mass = Vector3(0.0, Lane.PIN_CENTER_OF_MASS_Y, 0.0)
	pin.physics_material_override = _material(0.35, Lane.PIN_BOUNCE)
	pin.continuous_cd = true
	pin.contact_monitor = true
	pin.max_contacts_reported = 8
	pin.linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
	pin.linear_damp = Lane.PIN_LINEAR_DAMP
	pin.angular_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
	pin.angular_damp = Lane.PIN_ANGULAR_DAMP
	pin.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	pin.freeze = true
	pin.position = Lane.world(x, f)
	for part in [[0, Lane.PIN_NECK_INDEX], [Lane.PIN_NECK_INDEX, Lane.PIN_PROFILE.size() - 1]]:
		var shape := CollisionShape3D.new()
		shape.shape = ConvexPolygonShape3D.new()
		shape.shape.points = hull_points(part[0], part[1])
		pin.add_child(shape)
	add_child(pin, true)
	pins[position] = pin
	_tokens[pin.get_instance_id()] = position
	if _dressing:
		_dressing.dress_pin(pin)

func _add_ball() -> void:
	aim_ball = Node3D.new()
	aim_ball.name = "AimBall"
	add_child(aim_ball, true)
	ball = RigidBody3D.new()
	ball.name = "Ball"
	ball.mass = Lane.BALL_MASS
	_zone_friction = Lane.ball_friction(Lane.BALL_START_F)
	_ball_material = _material(_zone_friction, Lane.BALL_BOUNCE)
	ball.physics_material_override = _ball_material
	ball.continuous_cd = true
	ball.contact_monitor = true
	ball.max_contacts_reported = 8
	ball.linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
	ball.linear_damp = 0.04
	ball.angular_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
	ball.angular_damp = 0.04
	var shape := CollisionShape3D.new()
	shape.shape = SphereShape3D.new()
	shape.shape.radius = Lane.BALL_RADIUS
	ball.add_child(shape)
	_tokens[ball.get_instance_id()] = "ball"
	place_ball(0.0)
	if _dressing:
		_dressing.dress_ball(aim_ball)
		_dressing.dress_ball(ball)

## Aim-time placement of the visual ball only; ignored after commit.
func place_ball(start_x: float) -> void:
	if state == "ready":
		aim_ball.position = Lane.world(clampf(start_x, -Lane.MAX_START_X, Lane.MAX_START_X) * Lane.LANE_HALF_WIDTH, Lane.BALL_START_F, Lane.BALL_RADIUS)

## Where the player sees the ball: the aim ball until launch, then the rolling ball.
func ball_position() -> Vector3:
	return ball.global_position if ball.get_parent() == self else aim_ball.global_position

## Validates and queues the launch for the next physics tick. Nothing changes on error.
func commit(record: Dictionary) -> Array[String]:
	var errors := Contracts.validate("launch", record)
	if state != "ready":
		errors.append("Lane already committed")
	if errors.is_empty():
		if absf(record.start_x) > Lane.MAX_START_X + 1e-9:
			errors.append("start_x places the ball off the lane")
		if record.ball_id not in Lane.SIMULATED_BALLS:
			errors.append("Ball is not simulated yet: " + record.ball_id)
	if errors.is_empty():
		launch = record.duplicate(true)
		state = "committed"
		_pending = true
	return errors

func _apply_launch() -> void:
	var direction := Vector3(launch.direction_x, 0.0, -launch.direction_forward).normalized()
	var velocity := direction * Lane.ball_speed(launch.power)
	remove_child(aim_ball)
	aim_ball.free()
	ball.position = Lane.world(launch.start_x * Lane.LANE_HALF_WIDTH, Lane.BALL_START_F, Lane.BALL_RADIUS)
	add_child(ball, true)
	ball.linear_velocity = velocity
	# True forward roll plus side rotation about the travel axis (positive hooks right).
	ball.angular_velocity = Vector3.UP.cross(velocity) / Lane.BALL_RADIUS + direction * Lane.side_spin(launch.spin)
	for position in pins:
		pins[position].freeze = false
	tracker = Tracker.new(pins.keys())
	state = "rolling"

func _physics_process(_delta: float) -> void:
	if _pending:
		_pending = false
		_apply_launch()
	elif state == "rolling" and tracker.step(observe()):
		_finish()
	if state == "rolling":
		_oil_pattern()

## Sets the ball's friction for the zone it is in before the next step.
func _oil_pattern() -> void:
	var friction := Lane.ball_friction(-ball.global_position.z)
	if friction != _zone_friction:
		_zone_friction = friction
		_ball_material.friction = friction

func observe() -> Dictionary:
	var contacts := {}
	for position in pins:
		contacts[position] = []
	for token in touching(ball):
		if typeof(token) == TYPE_INT:
			contacts[token].append("ball")
	for position in pins:
		for token in touching(pins[position]):
			contacts[position].append(token)
			if typeof(token) == TYPE_INT:
				contacts[token].append(position)
	var seen := {}
	for position in pins:
		var pin: RigidBody3D = pins[position]
		var up := pin.global_transform.basis.y.normalized()
		var base := pin.global_position
		seen[position] = {"tilt": rad_to_deg(acos(clampf(up.dot(Vector3.UP), -1.0, 1.0))), "x": base.x, "y": base.y, "f": -base.z,
			"linear": pin.linear_velocity.length(), "angular": pin.angular_velocity.length(), "contacts": contacts[position]}
	var at := ball.global_position
	return {"ball": {"x": at.x, "y": at.y, "f": -at.z, "speed": ball.linear_velocity.length()}, "pins": seen}

## Contacts that carried impulse in the last step. Jolt also reports speculative
## contacts up to 2 cm apart; those are near misses, not touches.
func touching(body: RigidBody3D) -> Array:
	var direct := PhysicsServer3D.body_get_direct_state(body.get_rid())
	var found: Array = []
	for index in direct.get_contact_count():
		if direct.get_contact_impulse(index).length() > CONTACT_IMPULSE:
			found.append(_tokens.get(direct.get_contact_collider_id(index), "static"))
	return found

func _notification(what: int) -> void:
	# An uncommitted ball is not our child, so free it with the lane.
	if what == NOTIFICATION_PREDELETE and ball and ball.get_parent() == null:
		ball.free()

func _finish() -> void:
	state = "finished"
	var fallen: Array = tracker.sequence.duplicate()
	fallen.sort()
	var survivors: Array = []
	for position in tracker.standing():
		var base: Vector3 = pins[position].global_position
		survivors.append({"position": position, "x": base.x, "f": -base.z})
	if tracker.gutter:
		survivors = _rack_in.duplicate(true)
	var final_state := {}
	for position in pins:
		var body: RigidBody3D = pins[position]
		final_state[str(position)] = _pose(body)
	final_state["ball"] = _pose(ball)
	report = {
		"launch": launch.duplicate(true),
		"roll_result": {"schema_version": 1, "launch_id": launch.launch_id, "ball_id": launch.ball_id, "roll_index": launch.roll_index,
			"fallen_positions": fallen, "accuracy": Lane.grade_accuracy(tracker.target_crossed, tracker.target_offset() - launch.target_x, launch.ring_radius)},
		"knockdown_log": {"schema_version": 1, "launch_id": launch.launch_id, "ball_id": launch.ball_id, "roll_index": launch.roll_index,
			"knockdowns": tracker.knockdowns(), "standing": tracker.standing(), "gutter": tracker.gutter, "voided_positions": tracker.voided, "target_crossed": tracker.target_crossed,
			"target_offset": tracker.target_offset(), "settle": tracker.settle, "ticks": tracker.tick},
		"rack_after": {"schema_version": 1, "standing": resolve_overlaps(survivors)},
		"final_state": final_state,
	}
	for position in pins:
		pins[position].freeze = true
	ball.freeze = true
	roll_finished.emit(report.duplicate(true))

static func _pose(body: Node3D) -> Array:
	var q := body.global_transform.basis.get_rotation_quaternion()
	var p := body.global_position
	return [p.x, p.y, p.z, q.x, q.y, q.z, q.w]

## Pinsetter rule: survivors are re-spotted upright at their base. Deterministically
## separates any pair that would interpenetrate when set upright.
static func resolve_overlaps(standing: Array) -> Array:
	var result: Array = standing.duplicate(true)
	result.sort_custom(func(a, b): return a.position < b.position)
	for _pass in 4:
		for i in result.size():
			for j in range(i + 1, result.size()):
				var a := Vector2(result[i].x, result[i].f)
				var b := Vector2(result[j].x, result[j].f)
				var gap := a.distance_to(b)
				if gap < SEPARATION:
					var axis := Vector2.RIGHT if gap < 1e-9 else (b - a) / gap
					var push := axis * (SEPARATION - gap) * 0.5
					result[i].x = a.x - push.x
					result[i].f = a.y - push.y
					result[j].x = b.x + push.x
					result[j].f = b.y + push.y
	return result
