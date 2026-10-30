extends RefCounted
## Adds mesh-only architecture outside the playing surface, once per actual roll.
const Lane = preload("res://src/simulation/lane_spec.gd")
static func dress(lane: Node3D, rival_id: String) -> void:
	if lane.has_node("RivalLaneArt"): return
	var theme := preload("res://src/presentation/rival_art.gd").entry(rival_id)
	if theme.is_empty(): return
	var art := Node3D.new()
	art.name = "RivalLaneArt"
	art.set_meta("rival_id", rival_id)
	lane.add_child(art)
	var material := StandardMaterial3D.new()
	material.albedo_color = {"alignment": Color("bfa16b"), "polish": Color("bce6de"), "keys": Color("cda159"), "woodgrain": Color("ad7647")}.get(theme.lane, Color.WHITE)
	material.roughness = 0.4
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for side in [-1, 1]:
		for index in range(12):
			var mesh := BoxMesh.new()
			mesh.size = Vector3(0.12 if index % 3 == 0 else 0.055, 0.012, 0.025)
			if theme.lane == "polish": mesh.size = Vector3(0.08,0.012,0.13)
			var node := MeshInstance3D.new()
			node.mesh = mesh
			node.material_override = material
			node.position = Lane.world(side * 0.85, 4.0 + index * 1.2, 0.075)
			if theme.lane == "polish": node.rotation.y = PI * 0.25
			art.add_child(node)
	if theme.lane in ["keys", "woodgrain"]:
		_house_trim(art, theme.lane, material)
	# Emblem on the backboard is independent of physics and keeps the rack clear.
	var emblem := Sprite3D.new()
	emblem.texture = preload("res://src/presentation/rival_art.gd").rule_badge(theme.rule)
	emblem.pixel_size = 0.01 if theme.lane in ["keys", "woodgrain"] else 0.0012
	emblem.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	emblem.position = Lane.world(0,20.2,2.0)
	art.add_child(emblem)

## Decorative rails stay outside the lane and contain no physics bodies.
static func _house_trim(art: Node3D, style: String, material: Material) -> void:
	var inset := StandardMaterial3D.new()
	inset.albedo_color = Color("263d42") if style == "keys" else Color("513626")
	inset.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for side in [-1, 1]:
		for station in [5.0, 10.0, 15.0]:
			var center := Lane.world(side * 0.88, station, 0.085)
			if style == "keys":
				var bow := TorusMesh.new()
				bow.inner_radius = 0.045
				bow.outer_radius = 0.067
				bow.rings = 12
				bow.ring_segments = 8
				_piece(art, bow, center, material)
				_box(art, Vector3(0.027,0.015,0.22), center + Vector3(0,0,0.14), material)
				for tooth in [0.19, 0.24]:
					_box(art, Vector3(0.06,0.015,0.025), center + Vector3(side*0.02,0,tooth), material)
			else:
				_box(art, Vector3(0.20,0.025,0.72), center, material)
				for grain in [-0.06, -0.02, 0.025, 0.07]:
					_box(art, Vector3(0.008,0.004,0.60-absf(grain)), center + Vector3(grain,0.015,0), inset)
				var peg := CylinderMesh.new()
				peg.top_radius = 0.025
				peg.bottom_radius = 0.025
				peg.height = 0.006
				_piece(art, peg, center + Vector3(0,0.017,0.25), inset)

static func _box(parent: Node3D, dimensions: Vector3, at: Vector3, material: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	_piece(parent, mesh, at, material)

static func _piece(parent: Node3D, mesh: Mesh, at: Vector3, material: Material) -> void:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	node.position = at
	parent.add_child(node)
