extends Node3D
## Independent static art scene: exact E04 pin locations and profile, no physics.
const Lane = preload("res://src/simulation/lane_spec.gd")
const Dressing = preload("res://src/presentation/lane_dressing.gd")
const Surface = preload("res://assets/art_direction/material.gdshader")
var pin_positions: Array[Vector2] = []

func material(color: Color, kind: int = -1) -> Material:
	if kind >= 0:
		var shader := ShaderMaterial.new()
		shader.shader = Surface
		shader.set_shader_parameter("kind", kind)
		shader.set_shader_parameter("base", color)
		return shader
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.4
	return mat

func mesh(shape: Mesh, mat: Material, at: Vector3, parent: Node3D = self) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.mesh = shape
	item.material_override = mat
	item.position = at
	parent.add_child(item)
	return item

func block(size: Vector3, at: Vector3, color: Color) -> MeshInstance3D:
	var shape := BoxMesh.new()
	shape.size = size
	return mesh(shape, material(color), at)

func glow(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.4
	return mat

func _ready() -> void:
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("101820")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("95b7c0")
	env.environment.ambient_light_energy = 0.5
	add_child(env)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-55, -25, 0)
	key.light_color = Color("ffe1aa")
	key.light_energy = 0.85
	key.shadow_enabled = true
	add_child(key)
	var rim := OmniLight3D.new()
	rim.position = Vector3(0, 1.1, -19.2)
	rim.light_color = Color("70dfd0")
	rim.light_energy = 0.65
	rim.omni_range = 5
	add_child(rim)
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(Lane.LANE_HALF_WIDTH*2,0.08,24)
	mesh(floor_mesh,material(Color.WHITE,0),Vector3(0,-0.04,-10))
	var carpet := block(Vector3(4,0.1,25),Vector3(0,-0.15,-10),Color("17363d"))
	carpet.material_override = material(Color.WHITE,5)
	for side in [-1,1]:
		block(Vector3(0.2,0.04,24),Vector3(side*0.64,-0.06,-10),Color("101820"))
		block(Vector3(0.1,0.08,24),Vector3(side*0.8,0,-10),Color("573a2e"))
		var rail := BoxMesh.new()
		rail.size=Vector3(0.015,0.015,24)
		mesh(rail,glow(Color("377d83")),Vector3(side*0.76,0.05,-10))
		for z in [-15.0,-17.0,-19.8]:
			block(Vector3(0.12,2.4,0.15),Vector3(side*1.2,1.05,z),Color("573a2e"))
			block(Vector3(0.035,2.35,0.04),Vector3(side*1.12,1.05,z+0.09),Color("876c42"))
			block(Vector3(0.25,0.12,0.3),Vector3(side*1.2,0.02,z),Color("573a2e"))
			var lamp := SphereMesh.new()
			lamp.radius=0.055
			lamp.height=0.15
			mesh(lamp,glow(Color("c58a49")),Vector3(side*1.07,0.62,z))
	block(Vector3(2.4,0.2,0.2),Vector3(0,2.2,-19.8),Color("573a2e"))
	# A source-art mural is allowed; equipment and lane remain separate meshes.
	var mural := QuadMesh.new()
	mural.size=Vector2(2.15,1.4)
	var mural_material := ShaderMaterial.new()
	var mural_shader := Shader.new()
	mural_shader.code="shader_type spatial; render_mode unshaded; uniform sampler2D art: source_color, filter_nearest; void fragment(){ ALBEDO=texture(art,vec2(UV.x,UV.y*0.25)).rgb; }"
	mural_material.shader=mural_shader
	mural_material.set_shader_parameter("art",load("res://assets/art_direction/lane.png"))
	mesh(mural,mural_material,Vector3(0,1.35,-19.75))
	var pin_mesh: ArrayMesh = Dressing.new()._lathe()
	var colors := [Color("f4e6cd"),Color("be4b60"),Color("17363d"),Color("95d9cb"),Color("8976cf")]
	for number in range(1,11):
		var spot := Lane.spot(number)
		pin_positions.append(spot)
		var family := (number-1)%5
		var pin := Node3D.new()
		pin.name = "Pin%d" % number
		pin.position = Lane.world(spot.x,spot.y)
		add_child(pin)
		mesh(pin_mesh,material(colors[family],6 if family==3 else (2 if family==0 else (3 if family==1 else 4))),Vector3.ZERO,pin)
		if family == 1: # Ruby inset: separate faceted geometry, not a flat recolor.
			var jewel := PrismMesh.new()
			jewel.size=Vector3(0.055,0.085,0.025)
			mesh(jewel,material(Color("ee6986"),3),Vector3(0,0.13,0.055),pin)
		elif family == 2: # Anchor foot collar.
			var collar := CylinderMesh.new()
			collar.top_radius=0.052
			collar.bottom_radius=0.063
			collar.height=0.045
			mesh(collar,material(Color("e7bc70"),3),Vector3(0,0.028,0),pin)
		elif family == 4: # Echo double ring relief.
			for height in [0.11,0.16]:
				var ring := TorusMesh.new()
				ring.inner_radius=0.055
				ring.outer_radius=0.064
				mesh(ring,material(Color("e7bc70"),3),Vector3(0,height,0),pin)
	assert(pin_positions.size()==10)
	var ball := SphereMesh.new()
	ball.radius=Lane.BALL_RADIUS
	ball.height=Lane.BALL_RADIUS*2
	var ball_root := Node3D.new()
	ball_root.position=Lane.world(-0.06,16.85,Lane.BALL_RADIUS)
	add_child(ball_root)
	mesh(ball,material(Color.WHITE,1),Vector3.ZERO,ball_root)
	for direction in [Vector3(0,0.8,0.6),Vector3(-0.28,0.56,0.78),Vector3(0.28,0.56,0.78)]:
		var hole:=SphereMesh.new()
		hole.radius=0.016
		hole.height=0.032
		mesh(hole,material(Color("080e13")),direction.normalized()*0.1,ball_root)
	# Contact shadows stay local and never change physics.
	for body in get_children():
		if body is Node3D and str(body.name).begins_with("Pin"):
			var disc:=CylinderMesh.new()
			disc.top_radius=0.075
			disc.bottom_radius=0.075
			disc.height=0.001
			mesh(disc,material(Color("765332")),Vector3(body.position.x,0.001,body.position.z+0.015))
	var camera:=Camera3D.new()
	camera.position=Vector3(0,1.55,-14.5)
	camera.fov=42
	add_child(camera)
	camera.look_at(Vector3(0,0.35,-18))
	camera.current=true
