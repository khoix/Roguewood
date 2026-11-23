extends RefCounted
## Presentation-only manifest. Never aliases provisional campaign rivals.
const STATES := ["entrance", "confident", "impressed", "threatened", "defeated", "victorious"]
static var _manifest: Dictionary = {}
## PERF-2: portraits are kept only while something shows them (a weak reference), so a
## rival's full-size sheet is freed once no portrait draws from it.
static var _textures: Dictionary = {}
static func entry(id: String) -> Dictionary:
	if _manifest.is_empty():
		_manifest = JSON.parse_string(FileAccess.get_file_as_string("res://assets/rivals/manifest.json"))
	return _manifest.get(id, {})
static func portrait(id: String, state: String) -> Texture2D:
	var data := entry(id)
	if data.is_empty() or state not in STATES: return null
	var key := id + ":" + state
	var kept: Texture2D = _textures[key].get_ref() if _textures.has(key) else null
	if kept == null:
		var atlas := AtlasTexture.new()
		atlas.atlas = load(data.source)
		var cell := Vector2(atlas.atlas.get_width() / 3.0, atlas.atlas.get_height() / 2.0)
		var index := STATES.find(state)
		atlas.region = Rect2(Vector2(index % 3, index / 3) * cell, cell)
		if data.has("regions"):
			var r: Array = data.regions[index]
			atlas.region = Rect2(r[0],r[1],r[2],r[3])
		atlas.filter_clip = true
		_textures[key] = weakref(atlas)
		kept = atlas
	return kept

## Rule artwork is independent of portrait identity (champions carry two rules).
static func rule_badge(rule: String) -> Texture2D:
	if rule in ["boss_rule.house_rules", "boss_rule.house_pins", "boss_rule.oil_slick", "boss_rule.narrow_lane", "boss_rule.strobe"]:
		return load("res://assets/rivals/rules/" + rule.trim_prefix("boss_rule.") + ".svg")
	return preload("res://src/presentation/item_assets.gd").slot(rule, "in_play") as Texture2D
