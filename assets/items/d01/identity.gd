extends Node3D
## Cosmetic identity only. E18 attaches this below its own body after native checks.
## No colliders, timers, physics callbacks, score hooks or state mutation.
@export var item_id := "ball.gold"
@export_enum("ready", "solid", "split") var presentation_state := "ready"
const PETROL := Color("173840")
const IVORY := Color("eddfbd")
const BRASS := Color("c39548")
const DARK := Color("172029")
const COPPER := Color("be703d")

func _ready() -> void:
	if item_id.begins_with("pin."): _pin()
	else: _ball()

func _material(color: Color, metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metal
	m.roughness = 0.32
	return m

func _mesh(mesh: Mesh, material: Material, at: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.mesh = mesh
	n.material_override = material
	n.position = at
	add_child(n)
	return n

func _box(dimensions: Vector3, at: Vector3, color: Color, metal: float = 0.5) -> MeshInstance3D:
	var box := BoxMesh.new()
	box.size = dimensions
	return _mesh(box, _material(color,metal), at)

func _ring(radius: float, thickness: float, at: Vector3, color: Color) -> MeshInstance3D:
	var torus := TorusMesh.new()
	torus.inner_radius = radius - thickness
	torus.outer_radius = radius + thickness
	torus.rings = 24
	torus.ring_segments = 8
	return _mesh(torus,_material(color,0.6),at)

func _identity_material(kind: int) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = preload("res://assets/items/d01/identity.gdshader")
	m.set_shader_parameter("identity",kind)
	m.set_shader_parameter("solid",presentation_state == "solid")
	return m

func _ball() -> void:
	var sphere := SphereMesh.new()
	sphere.radius = 0.1086
	sphere.height = 0.2172
	sphere.radial_segments = 48
	sphere.rings = 24
	if item_id == "ball.splitter":
		for side in [-1,1]:
			var half := _mesh(_half_ball(side),_identity_material(3),Vector3(side * (0.08 if presentation_state == "split" else 0.003),0,0))
			half.name = "HalfLeft" if side < 0 else "HalfRight"
			_box(Vector3(0.025,0.013,0.008),Vector3(side * (0.105 if presentation_state == "split" else 0.025),0.023,-0.104),BRASS).rotation.z = side * 0.6
	else:
		_mesh(sphere,_identity_material({"ball.gold":0,"ball.spark":1,"ball.ghost":2}[item_id]))
	if item_id == "ball.spark":
		for i in 4:
			var angle := i * PI * 0.5
			for branch in [-1,1]:
				var pos := Vector2(branch * 0.012,0.066).rotated(angle)
				_box(Vector3(0.009,0.040,0.008),Vector3(pos.x,pos.y,-0.083),COPPER).rotation.z = angle
			var pos := Vector2(0,0.047).rotated(angle)
			_box(Vector3(0.034,0.009,0.008),Vector3(pos.x,pos.y,-0.098),COPPER).rotation.z = angle
	elif item_id == "ball.gold":
		_box(Vector3(0.052,0.008,0.007),Vector3(0,-0.025,-0.106),DARK,0)
		for i in 3:
			_box(Vector3(0.009,0.009,0.007),Vector3((i-1)*0.018,-0.050,-0.096),IVORY)
	# Finger-hole marks share the established visual radius and never cut collisions.
	var offsets := [Vector3(0,0,-1),Vector3(0.26,0.25,-0.94),Vector3(-0.26,0.25,-0.94)]
	if item_id == "ball.splitter": offsets = [Vector3(-0.46,0.1,-0.88),Vector3(-0.30,0.43,-0.85),Vector3(-0.65,0.42,-0.65)]
	for offset in offsets:
		var hole := SphereMesh.new()
		hole.radius = 0.014
		hole.height = 0.028
		var at: Vector3 = offset.normalized()*0.101
		if presentation_state == "split": at.x -= 0.08
		_mesh(hole,_material(DARK),at)

func _pin() -> void:
	var mesh: ArrayMesh = preload("res://src/presentation/lane_dressing.gd").new()._lathe()
	var base: Material = _material(PETROL if item_id == "pin.crown" else IVORY)
	if item_id == "pin.glass": base = _identity_material(4)
	_mesh(mesh,base)
	match item_id:
		"pin.fuse":
			for y in [0.25,0.263,0.276]: _ring(0.031,0.006,Vector3(0,y,0),Color("6d4e30"))
			_ring(0.018,0.007,Vector3(0,0.373,0),DARK)
			_box(Vector3(0.015,0.050,0.015),Vector3(0.008,0.397,0),COPPER).rotation.z = -0.3
			_box(Vector3(0.026,0.010,0.012),Vector3(0.020,0.421,0),COPPER)
		"pin.crown":
			_ring(0.031,0.008,Vector3(0,0.36,0),BRASS)
			for x in [-0.029,0.0,0.029]:
				var point := CylinderMesh.new()
				point.top_radius = 0
				point.bottom_radius = 0.014
				point.height = 0.052 if x == 0 else 0.040
				point.radial_segments = 4
				_mesh(point,_material(BRASS,0.7),Vector3(x,0.387,-0.012))
			for side in [-1,1]: _box(Vector3(0.012,0.064,0.008),Vector3(side*0.016,0.268,-0.029),BRASS).rotation.z = side * -0.55
		"pin.echo":
			for side in [-1,1]:
				_box(Vector3(0.018,0.102,0.032),Vector3(side*0.041,0.286,0),BRASS)
			_box(Vector3(0.098,0.015,0.035),Vector3(0,0.242,0),BRASS)
			for y in [0.13,0.16]:
				for side in [-1,1]: _box(Vector3(0.027,0.008,0.006),Vector3(side*0.010,y,-0.057),PETROL).rotation.z = side * -0.5
		"pin.glass":
			for y in [0.05,0.24,0.31]: _ring(0.028 if y > 0.2 else 0.046,0.002,Vector3(0,y,0),Color("c6e0d8"))

func _half_ball(side: int) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var start := -PI * 0.5 if side > 0 else PI * 0.5
	for row in 24:
		for col in 24:
			var quad: Array[Vector3] = []
			for corner in [Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,1)]:
				var lat: float = -PI*0.5 + PI*(row+corner.y)/24.0
				var lon: float = start + PI*(col+corner.x)/24.0
				quad.append(Vector3(cos(lat)*cos(lon),sin(lat),cos(lat)*sin(lon))*0.1086)
			for index in [0,1,2,0,2,3]:
				tool.set_normal(quad[index].normalized())
				tool.add_vertex(quad[index])
	for i in 48:
		for p in [Vector3.ZERO,Vector3(0,cos(TAU*i/48.0),sin(TAU*i/48.0))*0.1086,Vector3(0,cos(TAU*(i+1)/48.0),sin(TAU*(i+1)/48.0))*0.1086]:
			tool.set_normal(Vector3(-side,0,0))
			tool.add_vertex(p)
	return tool.commit()
