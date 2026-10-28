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
	material.albedo_color = Color("bfa16b") if theme.lane == "alignment" else Color("bce6de")
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
	# Emblem on the backboard is independent of physics and keeps the rack clear.
	var emblem := Sprite3D.new()
	emblem.texture = preload("res://src/presentation/item_assets.gd").slot(theme.rule,"icon")
	emblem.pixel_size = 0.0012
	emblem.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	emblem.position = Lane.world(0,20.2,2.0)
	art.add_child(emblem)
