extends RefCounted
## Authored visual accents follow the real body. No collision shapes or physics writes.
const Assets = preload("res://src/presentation/item_assets.gd")

static func dress(pin: RigidBody3D, item_id: String) -> bool:
	var material := Assets.slot(item_id, "in_play") as Material
	if material == null: return false
	for child in pin.get_children():
		if child is MeshInstance3D:
			child.material_override = material
			pin.set_meta("art_item_id", item_id)
			break
	if item_id == "pin.anchor":
		var collar := CylinderMesh.new()
		collar.top_radius = 0.051
		collar.bottom_radius = 0.041
		collar.height = 0.050
		collar.radial_segments = 24
		# Bake the offset into the visual vertices so the same local shader markings
		# line up on body and collar, including when the physical pin lies down.
		var arrays := collar.get_mesh_arrays()
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		for i in vertices.size(): vertices[i].y += 0.026
		arrays[Mesh.ARRAY_VERTEX] = vertices
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var accent := MeshInstance3D.new()
		accent.name = "AnchorCollar"
		accent.mesh = mesh
		accent.material_override = material
		pin.add_child(accent)
	return true
