extends RefCounted
## E17 authored-definition batches (content/catalogue/batches/E17-Dxx.json). A
## batch holds at most 12 definitions written ahead of their mechanics. Each one
## is a full catalogue v2 item (prices, pool, limits, unlock, tradeoff, tags,
## compatibility) plus a design block: the exact trigger text, the new effect
## primitives E18 must build, the pool note, presentation needs for Codex's visual
## brief, and the stable asset IDs per slot.
##
## Batches never enter content/catalogue.json, a shop pool, the binder or a save;
## E18 moves each item into the catalogue when its mechanics land (completeness
## mechanics then becomes true) and keeps its design block in the batch under
## `landed: [{id, landed_in, design}]`, so the trigger text, presentation needs and
## asset IDs stay with the batch while the item itself lives only in the catalogue. validate() checks every batch against the shipped
## catalogue and the prospective unlock graph, so an authored unlock that would be
## unreachable, circular or self-unlocking is refused now, not after art is made.
const Contracts = preload("res://src/contracts/contracts.gd")
const DIRECTORY := "res://content/catalogue/batches/"
const BATCH_LIMIT := 12
## Design §15 release targets (270 definitions; six League specs are separate).
const TARGETS := {"ball": 24, "pin": 32, "ball_mod": 16, "pin_mod": 16, "charm": 100, "consumable": 24, "shop_upgrade": 16,
	"lane_condition": 12, "boss_rule": 20, "kit": 10}
## Provisional purchase bands (design §15); legendary is reward-only.
const NOT_SOLD := ["boss_rule", "lane_condition", "kit"]
const PRICE_BANDS := {"common": [3, 5], "uncommon": [5, 7], "rare": [7, 10], "epic": [10, 14]}
## Asset slots each category needs (asset IDs are "<slot>.<item id>").
const SLOTS := {"ball": ["icon", "card", "in_play", "rarity_treatment", "activation", "sound", "reduced_motion"],
	"pin": ["icon", "card", "in_play", "rarity_treatment", "activation", "sound", "reduced_motion"],
	"default": ["icon", "card", "rarity_treatment", "activation", "sound", "reduced_motion"]}

## Every batch file, sorted by name: [{path, data}].
static func load_all(directory: String = DIRECTORY) -> Array:
	var out: Array = []
	var names := Array(DirAccess.get_files_at(directory)).filter(func(n): return String(n).ends_with(".json"))
	names.sort()
	for file_name in names:
		out.append({"path": directory.path_join(file_name), "data": Contracts.read_json(directory.path_join(file_name))})
	return out

## The catalogue items of every batch, in order.
static func items(batches: Array) -> Array:
	var out: Array = []
	for batch in batches:
		if batch.data is Dictionary:
			for definition in batch.data.get("definitions", []):
				if definition is Dictionary and definition.get("item") is Dictionary:
					out.append(definition.item)
	return out

## Errors for all batches together with the shipped catalogue. graph_errors: the
## prospective unlock graph's errors (ContentSet.career_graph with these items).
static func validate(batches: Array, catalogue: Dictionary, graph_errors: Array = []) -> Array[String]:
	var errors: Array[String] = []
	var shipped := {}
	for item in catalogue.get("items", []):
		shipped[item.id] = true
	var signatures := {}
	for batch in batches:
		var data: Variant = batch.data
		var label: String = String(batch.path).get_file()
		if not data is Dictionary or int(data.get("schema_version", 0)) != 1:
			errors.append(label + ": needs schema_version 1")
			continue
		if data.get("batch") != label.get_basename() or not RegEx.create_from_string("^E17-D\\d\\d$").search(String(data.get("batch", ""))):
			errors.append(label + ": batch id must be E17-Dxx and match the file name")
		var definitions: Array = data.get("definitions", [])
		var landed: Array = data.get("landed", [])
		if definitions.size() + landed.size() == 0 or definitions.size() + landed.size() > BATCH_LIMIT:
			errors.append("%s: 1 to %d definitions" % [label, BATCH_LIMIT])
		for entry in landed:
			if not entry is Dictionary or not shipped.has(entry.get("id")) or not RegEx.create_from_string("^E18-C\\d\\d$").search(str(entry.get("landed_in", ""))) or not entry.get("design") is Dictionary:
				errors.append("%s: a landed entry names a catalogue item, its E18-Cxx batch and its design: %s" % [label, str(entry.get("id") if entry is Dictionary else entry)])
		for definition in definitions:
			errors.append_array(_definition(definition, shipped, signatures, label))
	# Schema, IDs, prefixes, triggers and incompatibilities as one prospective catalogue.
	var combined: Array = catalogue.get("items", []).duplicate() + items(batches)
	for e in Contracts.validate("catalogue", {"schema_version": 2, "items": combined}):
		errors.append("prospective catalogue: " + e)
	for e in graph_errors:
		errors.append("prospective unlock graph: " + str(e))
	return errors

static func _definition(definition: Variant, shipped: Dictionary, signatures: Dictionary, label: String) -> Array[String]:
	var errors: Array[String] = []
	if not definition is Dictionary or not definition.get("item") is Dictionary or not definition.get("design") is Dictionary:
		errors.append(label + ": each definition needs item and design")
		return errors
	var item: Dictionary = definition.item
	var design: Dictionary = definition.design
	var id: String = str(item.get("id", "?"))
	if shipped.has(id):
		errors.append("%s: %s is already in the catalogue (move it out of the batch when E18 lands it)" % [label, id])
	var flags: Dictionary = item.get("completeness", {})
	if flags.get("authored") != true or flags.get("unlock_assigned") != true or flags.get("mechanics") != false or flags.get("integrated") != false:
		errors.append(id + ": an authored definition is authored and unlock-assigned, with no mechanics or integration yet")
	if flags.get("artwork") == true or flags.get("effects_audio") == true:
		errors.append(id + ": art and effects are not complete before the item exists")
	var rarity: String = str(item.get("rarity", ""))
	var price := int(item.get("purchase_price", -1))
	var category: String = str(item.get("category", ""))
	if category in NOT_SOLD:
		# Boss rules, lane conditions and kits are never sold.
		if float(item.get("pool_weight", 1)) != 0.0 or price != 0 or int(item.get("resale_price", -1)) != 0:
			errors.append(id + ": %s is never sold (pool weight 0, price 0)" % category)
		if category == "boss_rule" and String(design.get("counterplay", "")).length() < 20:
			errors.append(id + ": a boss rule names its counterplay")
	elif rarity == "legendary":
		if float(item.get("pool_weight", 1)) != 0.0:
			errors.append(id + ": legendary is reward-only (pool weight 0)")
	elif PRICE_BANDS.has(rarity):
		var band: Array = PRICE_BANDS[rarity]
		if price < band[0] or price > band[1]:
			errors.append("%s: %s price $%d outside $%d–%d" % [id, rarity, price, band[0], band[1]])
	if category not in NOT_SOLD and int(item.get("resale_price", -1)) != price / 2:
		errors.append(id + ": resale is half the price, rounded down")
	if String(item.get("downside", "")).length() < 20:
		errors.append(id + ": needs a real tradeoff")
	if item.get("synergy_tags", []).is_empty():
		errors.append(id + ": needs synergy tags")
	var trigger: String = str(design.get("trigger", ""))
	if trigger.length() < 60:
		errors.append(id + ": needs an exact trigger")
	var primitives: Array = design.get("primitives", [])
	for primitive in primitives:
		if not primitive is String or not RegEx.create_from_string("^[a-z]+\\.[a-z_]+$").search(primitive):
			errors.append("%s: primitive names look like area.name: %s" % [id, str(primitive)])
	if primitives.is_empty() and item.get("effects", []).is_empty() and not item.has("physics"):
		errors.append(id + ": does nothing (no effects, physics or primitives)")
	for key in ["pool", "presentation_needs"]:
		if String(design.get(key, "")).is_empty():
			errors.append("%s: design needs %s" % [id, key])
	var slots: Array = SLOTS.get(str(item.get("category", "")), SLOTS.default)
	var assets: Variant = design.get("asset_ids")
	if not assets is Dictionary or assets.keys().size() != slots.size():
		errors.append(id + ": asset IDs for " + ", ".join(slots))
	else:
		for slot in slots:
			if assets.get(slot) != "%s.%s" % [slot, id]:
				errors.append("%s: asset ID %s.%s" % [id, slot, id])
	# Not a recolor: no two definitions of a category may share effects, physics and primitives.
	var copy: Array = primitives.duplicate()
	copy.sort()
	var signature := JSON.stringify([item.get("category"), item.get("effects", []), item.get("physics", {}), copy])
	if signatures.has(signature):
		errors.append("%s: same behaviour as %s (a recolor is not a new type)" % [id, signatures[signature]])
	signatures[signature] = id
	return errors

## Per category: implemented (in the catalogue), authored (in batches) and the target.
static func counts(catalogue: Dictionary, batches: Array) -> Dictionary:
	var out := {}
	for category in TARGETS:
		out[category] = {"implemented": 0, "authored": 0, "target": TARGETS[category]}
	for item in catalogue.get("items", []):
		if out.has(item.category):
			out[item.category].implemented += 1
	for item in items(batches):
		if out.has(item.category):
			out[item.category].authored += 1
	return out

## New effect primitives the batches need, with the items needing each (for E18).
## Design blocks by item ID, for authored and landed definitions alike.
static func designs(batches: Array) -> Dictionary:
	var out := {}
	for batch in batches:
		for definition in batch.data.get("definitions", []):
			out[definition.item.id] = definition.design
		for entry in batch.data.get("landed", []):
			out[entry.id] = entry.design
	return out

static func primitives(batches: Array) -> Dictionary:
	var out := {}
	for batch in batches:
		for definition in batch.data.get("definitions", []):
			for primitive in definition.design.get("primitives", []):
				if not out.has(primitive):
					out[primitive] = []
				out[primitive].append(definition.item.id)
	return out
