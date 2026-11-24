extends "res://src/presentation/lane_dressing.gd"
## E11 materials on real E04 bodies. Meshes only: never alter collision or mass.
const ArtShader = preload("res://assets/art_direction/material.gdshader")
const PinIdentity = preload("res://src/presentation/pin_identity.gd")

## PERF-3: one material per finish for the whole session (it was a new one for
## every pin on every roll).
var _surfaces: Dictionary = {}
func surface(kind: int, color: Color) -> ShaderMaterial:
	var key := "%d:%s" % [kind, color.to_html()]
	if not _surfaces.has(key):
		var mat := ShaderMaterial.new()
		mat.shader = ArtShader
		mat.set_shader_parameter("kind",kind)
		mat.set_shader_parameter("base",color)
		_surfaces[key] = mat
	return _surfaces[key]

## PERF-3: the mural's shader was written anew for every roll, so the GPU compiled it
## again before each aim (slow on a phone's WebGL). It, its material and the rails'
## are made once.
var _mural_mesh: QuadMesh
var _mural_material: ShaderMaterial
var _rail_mesh: BoxMesh
var _rail_material: StandardMaterial3D
func _mural() -> void:
	if _mural_material != null: return
	_mural_mesh = QuadMesh.new()
	_mural_mesh.size = Vector2(4.5,2.7)
	_mural_material = ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = "shader_type spatial; render_mode unshaded; uniform sampler2D art:source_color,filter_nearest; void fragment(){ ALBEDO=texture(art,vec2(UV.x,UV.y*0.25)).rgb; }"
	_mural_material.shader = shader
	_mural_material.set_shader_parameter("art",load("res://assets/art_direction/lane.png"))
	_rail_mesh = BoxMesh.new()
	_rail_mesh.size = Vector3(0.025,0.025,20)
	_rail_material = StandardMaterial3D.new()
	_rail_material.albedo_color = Color("377d83")
	_rail_material.emission_enabled = true
	_rail_material.emission = Color("377d83")

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
		# Architecture belongs to this roll's nodes and is freed with them; its mesh,
		# shader and materials are kept for the session (PERF-3).
		_mural()
		_mesh_child(body,_mural_mesh,_mural_material,Lane.world(0,20.5,2.0)-body.position)
		for side in [-1,1]:
			_mesh_child(body,_rail_mesh,_rail_material,Lane.world(side*0.77,10,0.06)-body.position)

## Remaining E13 developmental finishes. Catalogue identities take precedence;
## A02 supplies Wood/Ruby/Gold/Anchor; Grower/Rubber are the next art batch.
const PIN_FINISHES := {"pin.grower": [2, "95d9cb"], "pin.rubber": [4, "8976cf"]}

func dress_pin(pin: RigidBody3D) -> void:
	super.dress_pin(pin)
	var item_id := String(pin.get_meta("item_id", ""))
	if PinIdentity.dress(pin, item_id): return
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
