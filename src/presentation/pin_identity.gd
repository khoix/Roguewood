extends RefCounted
## Authored visual accents follow the real body. No collision shapes or physics writes.
const Assets = preload("res://src/presentation/item_assets.gd")

static func dress(pin: RigidBody3D, item_id: String) -> bool:
	if pin.get_meta("art_item_id", "") == item_id: return true
	var resource := Assets.slot(item_id, "in_play")
	if resource == null: return false
	var previous := pin.get_node_or_null("CatalogueIdentity")
	if previous != null:
		pin.remove_child(previous)
		previous.queue_free()
	if resource is PackedScene:
		# Replace only the development mesh, preserving the actual rigid body and
		# every collision child. D01 scenes use the same base origin and pin profile.
		for child in pin.get_children():
			if child is MeshInstance3D: child.hide()
		var identity: Node3D = resource.instantiate()
		identity.name = "CatalogueIdentity"
		pin.add_child(identity)
		pin.set_meta("art_item_id", item_id)
		return true
	var material := resource as Material
	if material == null: return false
	for child in pin.get_children():
		if child is MeshInstance3D:
			child.show()
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
	elif item_id == "pin.rubber":
		for ring in [[0.081, 0.058], [0.117, 0.063], [0.153, 0.059]]:
			var rib := TorusMesh.new()
			rib.inner_radius = ring[1] - 0.010
			rib.outer_radius = ring[1] + 0.003
			rib.rings = 24
			rib.ring_segments = 8
			var accent := MeshInstance3D.new()
			accent.name = "RubberRib"
			accent.mesh = rib
			accent.position.y = ring[0]
			var rubber := StandardMaterial3D.new()
			rubber.albedo_color = Color("18232d")
			rubber.roughness = 0.85
			accent.material_override = rubber
			pin.add_child(accent, true)
	return true
