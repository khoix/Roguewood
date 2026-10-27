extends RefCounted
## One League attempt as saved state (E10, ADR 007). Everything that decides what
## happens next is captured together, so one write is one transaction: the session
## seed, the content it was made with, the run inventory (wallet and ledger), the
## shop (offers and RNG), the equipment deck (piles and RNG), the Division, and the
## lab's frame state, including a committed launch that has not resolved yet.
## Presentation (animation, armed-but-unthrown cards, the aim ring) is not saved.
##
## Phases say where play resumes:
##   aim            a roll is ready to throw (nothing committed)
##   committed      a launch is committed; resume re-simulates exactly that launch
##   roll_resolved  a roll finished; resume continues to the next roll or scoring
##   frame_done     a frame is scored and banked; resume shows it, never rescoring
##   shop           in the Pro Shop after the settlement
##   intro          the boss match is about to begin
##   division_over  the attempt has ended (result recorded)
const RunInventory = preload("res://src/rules/run_inventory.gd")
const Shop = preload("res://src/rules/shop.gd")
const Deck = preload("res://src/rules/card_deck.gd")
const Direct = preload("res://src/rules/direct_loadout.gd")
const Division = preload("res://src/rules/division_run.gd")
const League = preload("res://src/rules/league_run.gd")
## v2 (E13, ADR 008): the content set is recorded and the Division became a League
## (a chain of Divisions). v1 saves were all lab content with one Division.
const SCHEMA_VERSION := 2
const PHASES := ["aim", "committed", "roll_resolved", "frame_done", "shop", "intro", "division_over"]
const LAB_KEYS := ["frame_number", "roll_index", "match_number", "match_frame", "total_score", "launch_serial", "rack",
	"frame_reports", "frame_tactics", "frame_mods", "kept_last_frame", "equipment_model", "settlement", "last_scored", "pending", "result"]

## Content the snapshot was made with: a changed catalogue or Division spec is
## reported, and the save is refused if it names items that no longer exist.
static func content_hashes(catalogue_path: String, division_path: String) -> Dictionary:
	return {"catalogue": FileAccess.get_file_as_string(catalogue_path).sha256_text(),
		"division": FileAccess.get_file_as_string(division_path).sha256_text()}

## parts: {attempt, seed, phase, lab (LAB_KEYS), run, shop, division (League or
## Division run), equipment}. content_set names the ContentSet ("lab" by default).
static func build(parts: Dictionary, content: Dictionary, content_set: String = "lab") -> Dictionary:
	var lab := {}
	for key in LAB_KEYS:
		lab[key] = parts.lab.get(key)
	return {"attempt": int(parts.attempt), "seed": int(parts.seed), "phase": parts.phase, "content": content.duplicate(),
		"content_set": content_set, "lab": lab, "run": parts.run.to_dict(), "shop": parts.shop.to_dict(),
		"division": league_dict(parts.division.to_dict()), "equipment": parts.equipment.to_dict()}

## A League dict from either a League's or a single Division run's to_dict().
static func league_dict(data: Dictionary) -> Dictionary:
	if data.has("current"):
		return data
	return {"schema_version": League.SCHEMA_VERSION, "index": 0, "practice": bool(data.get("practice", false)), "done": [], "current": data}

## Attempt v1 -> v2: every v1 save was made with the lab content and one Division.
static func migrate_v1(payload: Dictionary) -> Dictionary:
	var out := payload.duplicate(true)
	out["content_set"] = "lab"
	if out.get("division") is Dictionary:
		out.division = league_dict(out.division)
	return out

## Problems that make a loaded payload unusable with the current content. A
## content_set, when given, must match the one the attempt was made with.
static func validate(payload: Dictionary, catalogue: Dictionary, content_set: String = "") -> Array[String]:
	var errors: Array[String] = []
	for key in ["attempt", "seed", "phase", "content", "lab", "run", "shop", "division", "equipment"]:
		if not payload.has(key):
			errors.append("missing " + key)
	if not errors.is_empty():
		return errors
	if not content_set.is_empty() and String(payload.get("content_set", "lab")) != content_set:
		errors.append("made with the %s content, not %s" % [payload.get("content_set", "lab"), content_set])
		return errors
	if payload.phase not in PHASES:
		errors.append("unknown phase " + str(payload.phase))
	for key in LAB_KEYS:
		if not payload.lab.has(key):
			errors.append("missing lab." + key)
	if payload.phase == "committed" and not payload.lab.get("pending") is Dictionary:
		errors.append("a committed phase needs its launch")
	var known := {}
	for item in catalogue.get("items", []):
		known[item.id] = true
	for id in referenced_items(payload):
		if not known.has(id):
			errors.append("item no longer exists: " + id)
	return errors

static func referenced_items(payload: Dictionary) -> Array:
	var ids := {}
	var run: Dictionary = payload.get("run", {})
	for entry in run.get("rack", {}).values() + run.get("reserves", []) + run.get("charms", []) + run.get("cards", {}).values():
		if entry is Dictionary:
			ids[entry.item_id] = true
			if not String(entry.get("mod", "")).is_empty():
				ids[entry.mod] = true
	for offer in payload.get("shop", {}).get("offers", []):
		if not String(offer.get("item_id", "")).is_empty():
			ids[offer.item_id] = true
	return ids.keys()

## Rebuilds the pure objects: {run, shop, division (a League run), equipment, lab,
## warnings}. divisions: the content set's Division specs (or one spec).
static func restore(payload: Dictionary, catalogue: Dictionary, divisions: Variant, content: Dictionary) -> Dictionary:
	var specs: Array = divisions if divisions is Array else [divisions]
	var warnings: Array = []
	for key in ["catalogue", "division"]:
		if payload.content.get(key) != content.get(key):
			warnings.append("%s changed since this attempt was saved" % key)
	var equipment: RefCounted
	if payload.equipment.get("model", "deck") == "direct":
		equipment = Direct.from_dict(payload.equipment)
	else:
		equipment = Deck.from_dict(payload.equipment)
	return {"run": RunInventory.from_dict(payload.run, catalogue), "shop": Shop.from_dict(payload.shop, catalogue),
		"division": League.from_dict(league_dict(payload.division), specs), "equipment": equipment,
		"lab": normalized_lab(payload.lab), "warnings": warnings}

## JSON gives every number as a float and every key as a string; the lab wants ints.
static func normalized_lab(lab: Dictionary) -> Dictionary:
	var out: Dictionary = lab.duplicate(true)
	for key in ["frame_number", "roll_index", "match_number", "match_frame", "total_score", "launch_serial"]:
		out[key] = int(out[key])
	for key in ["frame_tactics", "frame_mods"]:
		var fixed := {}
		for roll in out[key]:
			fixed[int(roll)] = out[key][roll]
		out[key] = fixed
	for report in out.frame_reports:
		_int_launch(report.launch)
		report.roll_result.roll_index = int(report.roll_result.roll_index)
	if out.pending is Dictionary:
		_int_launch(out.pending.launch)
	return out

static func _int_launch(launch: Dictionary) -> void:
	for key in ["schema_version", "roll_index"]:
		launch[key] = int(launch[key])
