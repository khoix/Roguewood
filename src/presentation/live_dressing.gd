extends "res://src/presentation/lane_dressing.gd"
## E11 materials on real E04 bodies. Meshes only: never alter collision or mass.
const ArtShader = preload("res://assets/art_direction/material.gdshader")

func surface(kind: int, color: Color) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = ArtShader
	mat.set_shader_parameter("kind",kind)
	mat.set_shader_parameter("base",color)
	return mat

func dress_static(body: StaticBody3D, dimensions: Vector3, role: String) -> void:
	super.dress_static(body,dimensions,role)
	if role in ["kickback", "cushion", "cap"]:
		for child in body.get_children():
			if child is MeshInstance3D:
				child.material_override = _material("e12_"+role, Color("17363d") if role != "cap" else Color("573a2e"), 0.6)
	if role == "lane":
		for child in body.get_children():
			if child is MeshInstance3D and child.mesh is BoxMesh and child.mesh.size.z > 0.2:
				child.material_override = surface(0,Color.WHITE)
		# Architecture belongs to this roll and is freed with it.
		var mural := QuadMesh.new()
		mural.size = Vector2(4.5,2.7)
		var mat := ShaderMaterial.new()
		var shader := Shader.new()
		shader.code = "shader_type spatial; render_mode unshaded; uniform sampler2D art:source_color,filter_nearest; void fragment(){ ALBEDO=texture(art,vec2(UV.x,UV.y*0.25)).rgb; }"
		mat.shader = shader
		mat.set_shader_parameter("art",load("res://assets/art_direction/lane.png"))
		_mesh_child(body,mural,mat,Lane.world(0,20.5,2.0)-body.position)
		for side in [-1,1]:
			var rail := BoxMesh.new()
			rail.size=Vector3(0.025,0.025,20)
			var light_mat := StandardMaterial3D.new()
			light_mat.albedo_color=Color("377d83")
			light_mat.emission_enabled=true
			light_mat.emission=Color("377d83")
			_mesh_child(body,rail,light_mat,Lane.world(side*0.77,10,0.06)-body.position)

## Slice pin materials (E13): finish and colour per catalogue pin, so a Ruby or
## Anchor reads as itself on the lane. Developmental: final pin art is E19.
const PIN_FINISHES := {"pin.wood": [2, "f4e6cd"], "pin.ruby": [4, "b8323f"], "pin.gold": [3, "e7bc70"],
	"pin.anchor": [4, "17363d"], "pin.grower": [2, "95d9cb"], "pin.rubber": [4, "8976cf"]}

func dress_pin(pin: RigidBody3D) -> void:
	super.dress_pin(pin)
	var item_id := String(pin.get_meta("item_id", ""))
	if PIN_FINISHES.has(item_id):
		for child in pin.get_children():
			if child is MeshInstance3D:
				child.material_override = surface(PIN_FINISHES[item_id][0], Color(PIN_FINISHES[item_id][1]))
		return
	# Wood remains Wood mechanically; alternate finishes are a presentation study.
	var number := str(pin.name).to_int()
	var colors := [Color("f4e6cd"),Color("e7bc70"),Color("17363d"),Color("95d9cb"),Color("8976cf")]
	var family := (maxi(number,1)-1)%5
	for child in pin.get_children():
		if child is MeshInstance3D:
			child.material_override = surface(2 if family==0 else (6 if family==3 else 4),colors[family])

func dress_ball(ball: Node3D) -> void:
	super.dress_ball(ball)
	for child in ball.get_children():
		if child is MeshInstance3D:
			child.material_override = surface(1,Color.WHITE)
			break
