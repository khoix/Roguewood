extends RefCounted
## Developmental E04 lane visuals: plain lit geometry so throws are readable.
## Not final art (E11/E12 own the art bible and premium pixel treatment). Adds
## meshes only; collision belongs to the simulation.
const Lane = preload("res://src/simulation/lane_spec.gd")
const LATHE_SEGMENTS := 24
const STRIPES := [[0.247, 0.262], [0.272, 0.287]]

var _materials: Dictionary = {}
var _pin_mesh: ArrayMesh
var _ball_mesh: SphereMesh

func _material(key: String, color: Color, roughness: float = 0.8, vertex_color: bool = false) -> StandardMaterial3D:
	if not _materials.has(key):
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = roughness
		material.vertex_color_use_as_albedo = vertex_color
		_materials[key] = material
	return _materials[key]

func _mesh_child(parent: Node3D, mesh: Mesh, material: Material, offset: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = offset
	parent.add_child(instance)
	return instance

func dress_static(body: StaticBody3D, size: Vector3, role: String) -> void:
	var colors := {"lane": Color(0.78, 0.55, 0.32), "cap": Color(0.16, 0.13, 0.22), "kickback": Color(0.22, 0.12, 0.3),
		"pit": Color(0.03, 0.02, 0.05), "cushion": Color(0.06, 0.04, 0.09)}
	var box := BoxMesh.new()
	box.size = size
	_mesh_child(body, box, _material(role, colors.get(role, Color.GRAY), 0.55 if role == "lane" else 0.9))
	if role == "lane":
		_lane_markings(body)

func _lane_markings(body: StaticBody3D) -> void:
	# Body origin is the slab center; markings sit just above its top face.
	var top := -body.position.y + 0.001
	var approach := BoxMesh.new()
	approach.size = Vector3(Lane.LANE_HALF_WIDTH * 2.0, 0.001, Lane.APPROACH_LENGTH)
	_mesh_child(body, approach, _material("approach", Color(0.86, 0.68, 0.45)), Lane.world(0.0, -Lane.APPROACH_LENGTH * 0.5, top) - body.position * Vector3(1, 0, 1))
	var foul := BoxMesh.new()
	foul.size = Vector3(Lane.LANE_HALF_WIDTH * 2.0, 0.002, 0.02)
	_mesh_child(body, foul, _material("foul", Color(0.85, 0.12, 0.15)), Lane.world(0.0, 0.0, top) - body.position * Vector3(1, 0, 1))
	var arrow := PrismMesh.new()
	arrow.size = Vector3(0.05, 0.16, 0.002)
	for board in range(-3, 4):
		var marker := _mesh_child(body, arrow, _material("arrow", Color(0.25, 0.12, 0.08)), Lane.world(board * 0.127, 3.7 + (3 - absf(board)) * 0.3, top) - body.position * Vector3(1, 0, 1))
		marker.rotation = Vector3(-PI * 0.5, 0.0, 0.0)
	var deck := BoxMesh.new()
	deck.size = Vector3(Lane.LANE_HALF_WIDTH * 2.0, 0.001, Lane.PIT_F - Lane.HEAD_PIN_F + 0.35)
	_mesh_child(body, deck, _material("deck", Color(0.84, 0.62, 0.38)), Lane.world(0.0, (Lane.HEAD_PIN_F - 0.35 + Lane.PIT_F) * 0.5, top) - body.position * Vector3(1, 0, 1))

func dress_gutter(body: StaticBody3D, faces: PackedVector3Array) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for vertex in faces:
		tool.add_vertex(vertex)
	tool.generate_normals()
	var material := _material("gutter", Color(0.12, 0.11, 0.16), 0.4)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mesh_child(body, tool.commit(), material)

func dress_pin(pin: RigidBody3D) -> void:
	if _pin_mesh == null:
		_pin_mesh = _lathe()
	_mesh_child(pin, _pin_mesh, _material("pin", Color.WHITE, 0.35, true))

func dress_ball(ball: Node3D) -> void:
	if _ball_mesh == null:
		_ball_mesh = SphereMesh.new()
		_ball_mesh.radius = Lane.BALL_RADIUS
		_ball_mesh.height = Lane.BALL_RADIUS * 2.0
	_mesh_child(ball, _ball_mesh, _material("ball", Color(0.1, 0.55, 0.6), 0.25))
	# Finger holes make true roll readable.
	var hole := SphereMesh.new()
	hole.radius = 0.018
	hole.height = 0.036
	for offset in [Vector3(0.0, 0.0, -1.0), Vector3(0.3, 0.25, -0.92), Vector3(-0.3, 0.25, -0.92)]:
		_mesh_child(ball, hole, _material("hole", Color(0.02, 0.03, 0.05)), offset.normalized() * (Lane.BALL_RADIUS - 0.008))

func _lathe() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var profile: Array = Lane.PIN_PROFILE.duplicate()
	profile.push_front([0.0, 0.0])
	profile.append([Lane.PIN_HEIGHT, 0.0])
	for ring in profile.size() - 1:
		var low: Array = profile[ring]
		var high: Array = profile[ring + 1]
		var color := Color(0.8, 0.08, 0.1) if _striped((low[0] + high[0]) * 0.5) else Color(0.96, 0.95, 0.9)
		for segment in LATHE_SEGMENTS:
			var a := TAU * segment / LATHE_SEGMENTS
			var b := TAU * (segment + 1) / LATHE_SEGMENTS
			var quad := [Vector3(cos(a) * low[1], low[0], sin(a) * low[1]), Vector3(cos(b) * low[1], low[0], sin(b) * low[1]),
				Vector3(cos(b) * high[1], high[0], sin(b) * high[1]), Vector3(cos(a) * high[1], high[0], sin(a) * high[1])]
			for index in [0, 1, 2, 0, 2, 3]: # clockwise front faces
				tool.set_color(color)
				tool.add_vertex(quad[index])
	tool.generate_normals()
	return tool.commit()

func _striped(height: float) -> bool:
	for stripe in STRIPES:
		if height >= stripe[0] and height <= stripe[1]:
			return true
	return false
