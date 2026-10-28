extends RefCounted
## Read-only presentation adapter. Catalogue assets are paths, never gameplay data.
## Hand and shop views carry stable item_id (coordinator contract c611dea).
## Empty IDs intentionally have no artwork; display text is never an identifier.
static var _items: Dictionary = {}

static func _ensure() -> void:
	if not _items.is_empty(): return
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://content/catalogue.json"))
	for item in data.get("items", []):
		_items[item.id] = item

static func identify(view: Dictionary) -> String:
	_ensure()
	return str(view.get("item_id", ""))

static func slot(item_id: String, name: String) -> Resource:
	_ensure()
	var path: String = _items.get(item_id, {}).get("assets", {}).get(name, "")
	return load(path) if not path.is_empty() and ResourceLoader.exists(path) else null

static func rarity_mark(item_id: String) -> String:
	_ensure()
	var rarity: String = _items.get(item_id, {}).get("rarity", "common")
	return {"common": "■ Common", "uncommon": "Ⅱ Uncommon", "rare": "◆ Rare", "epic": "✦ Epic", "legendary": "♛ Legendary"}.get(rarity, rarity.capitalize())

static func dress_ball(body: Node3D, item_id: String) -> void:
	if not is_instance_valid(body) or body.get_meta("art_item_id", "") == item_id: return
	var material := slot(item_id, "in_play") as Material
	if material == null: return
	for child in body.get_children():
		if child is MeshInstance3D:
			child.material_override = material
			body.set_meta("art_item_id", item_id)
			return # holes retain their dark material; physics children are untouched
