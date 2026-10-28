extends "res://tests/art_d01_preview.gd"
## D02 includes both live entries and authored definitions; previews never land items.
const COMPARISONS := {
"E19-A13":["charm.flat_bonus","charm.turkey_club","charm.lone_survivor","charm.standing_order","charm.gold_rush","charm.spare_change"],
"E19-A14":["charm.hook_artist","charm.house_favorite","boss_rule.dead_straight","charm.back_row"],
"E19-A15":["charm.last_chance","charm.split_specialist","charm.turkey_club","pin.crown"]}
func run() -> void:
	batch = "E19-A13"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--artifact-dir="): destination = arg.trim_prefix("--artifact-dir=")
	for candidate in ["E19-A13","E19-A14","E19-A15"]:
		if destination.to_lower().contains(candidate.to_lower()): batch = candidate
	if destination.is_empty(): destination = "res://artifacts/"+batch.to_lower()+"/preview"
	DirAccess.make_dir_recursive_absolute(destination)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://content/catalogue/batches/E17-D02.json"))
	var catalogue: Array = JSON.parse_string(FileAccess.get_file_as_string("res://content/catalogue.json")).items
	var all_items := {}
	var designs := {}
	for item in catalogue: all_items[item.id] = item
	for d in data.definitions:
		all_items[d.item.id] = d.item
		designs[d.item.id] = d.design
		check(not d.item.completeness.artwork and not d.item.completeness.mechanics,"authored flags unchanged")
	for d in data.landed: designs[d.id] = d.design
	var ids: Array = JSON.parse_string(FileAccess.get_file_as_string("res://assets/items/d02/batches.json"))[batch]
	for id in ids:
		var item: Dictionary = all_items[id]
		items.append(item)
		check(item.assets.in_play.is_empty(),"no invented in-play ID")
		if not item.completeness.mechanics:
			check(item.assets.activation.is_empty() and item.assets.sound.is_empty(),"authored effects wait for E18/E20")
		for slot in designs[id].asset_ids:
			if slot in ["activation","sound"]: continue
			var path: String = item.assets[slot]
			check(path.get_file().get_basename()==designs[id].asset_ids[slot],"exact ID "+id+"/"+slot)
			check(ResourceLoader.exists(path),"resource "+path)
			var resource = load(path)
			check(resource is StyleBoxFlat if slot == "rarity_treatment" else resource is Texture2D,"resource type "+slot)
	if DisplayServer.get_name() != "headless" and failures.is_empty():
		root.size = Vector2i(1280,720)
		root.content_scale_size = root.size
		_make_contact(items)
		await capture("contact")
		var compare := items.duplicate()
		for id in COMPARISONS[batch]:
			if all_items.has(id): compare.append(all_items[id])
			else:
				var d01: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://content/catalogue/batches/E17-D01.json"))
				for d in d01.definitions:
					if d.item.id == id: compare.append(d.item)
		_make_comparison(compare)
		await capture("comparison")
		for item in items:
			for dimensions in [Vector2i(720,1280),Vector2i(1280,720)]:
				root.size = dimensions
				root.content_scale_size = dimensions
				_make_inspector(item,dimensions)
				await capture(item.id.replace(".","_")+"_"+str(dimensions.x))
	if failures.is_empty(): print("ROGUEWOOD_D02_ART_OK "+batch)
	for i in 6: await process_frame
	quit(0 if failures.is_empty() else 1)
func picture(parent: Node, texture: Texture2D, side: int, mode: int = 0) -> TextureRect:
	var rect := super.picture(parent,texture,side,mode)
	if mode == 0 and texture.resource_path.contains("card.charm.crown_jewel"):
		var foil := ShaderMaterial.new()
		foil.shader = preload("res://assets/motion/foil.gdshader")
		foil.set_shader_parameter("strength",0.8)
		foil.set_shader_parameter("border_only",false)
		foil.set_shader_parameter("tilt",Vector2.ZERO)
		rect.material = foil
	return rect
