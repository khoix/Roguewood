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
	if path.is_empty() or not ResourceLoader.exists(path): return null
	return load(path)

## PERF-4 (the owner's phone log, 2026-11-24: a 180-300 ms frame at almost every new
## aim; its timed steps name dealing the hand): each card's art is a full-size sheet
## (about 1254 px), decoded again every time a card was dealt after leaving the screen
## (20-40 ms each on desktop, more on a phone). The run's own cards and Charms keep
## their art loaded while they are in the run, so dealing never decodes again.
static var _held: Dictionary = {} # path -> art
static var _held_ids: Array = []
static func hold(item_ids: Array) -> void:
	_ensure()
	var ids: Array = item_ids.duplicate()
	ids.sort()
	if ids == _held_ids: return
	_held_ids = ids
	var keep := {}
	for id in ids:
		for slot_name in ["card", "icon"]:
			var path: String = _items.get(id, {}).get("assets", {}).get(slot_name, "")
			if path.is_empty() or keep.has(path): continue
			keep[path] = _held[path] if _held.has(path) else (load(path) if ResourceLoader.exists(path) else null)
	_held = keep # art no longer in the run is released

## The paths held for the run (tests read them).
static func held_paths() -> Array:
	return _held.keys()

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
