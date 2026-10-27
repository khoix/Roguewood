extends RefCounted
## The content an attempt is played with (E13, ADR 008): a catalogue, a League (one
## or more Divisions in the DivisionRun format) and a starting kit.
## - "slice": the production catalogue batch E13-S01 and the two-Division House
##   League in content/slice/league.json. The game's default.
## - "lab": the E06–E10 fixture catalogue and single lab Division with the lab kit;
##   mechanism journeys and tests keep using it (`--content=lab`).
## Saves record their content set and only resume with the same one.
const Contracts = preload("res://src/contracts/contracts.gd")
const League = preload("res://src/rules/league_run.gd")
const RunInventory = preload("res://src/rules/run_inventory.gd")
const Generator = preload("res://src/procedural/campaign_generator.gd")
const UnlockGraph = preload("res://src/career/unlock_graph.gd")
const CAMPAIGN_PROFILE := "res://content/campaign/profile.json"
## Career unlock registries (E15, ADR 010): the production graph spans the slice and
## the campaign; the lab fixtures have their own.
const UNLOCKS := "res://content/career/unlocks.json"
const LAB_UNLOCKS := "res://content/fixtures/lab_unlocks.json"
const DEFAULT := "slice"
const SETS := {
	"slice": {"catalogue": "res://content/catalogue.json", "league": "res://content/slice/league.json", "unlocks": UNLOCKS},
	"lab": {"catalogue": "res://content/fixtures/lab_catalogue.json", "division": "res://content/fixtures/lab_division.json", "unlocks": LAB_UNLOCKS},
}
## Lab starting kit (fixture items, not the production kit): ten Wood pins and a deck
## of two copies of three lab ball types plus one tactical card.
const LAB_KIT := {"id": "kit.lab", "name": "Lab Kit", "pins": ["pin.wood", "pin.wood", "pin.wood", "pin.wood", "pin.wood", "pin.wood", "pin.wood", "pin.wood", "pin.wood", "pin.wood"],
	"deck": ["ball.lab_value", "ball.lab_value", "ball.lab_mult", "ball.lab_mult", "ball.lab_coin", "ball.lab_coin", "consumable.lab_focus"], "money": 6}

## The set named on the command line (--content=lab|slice), else the default.
static func requested() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--content="):
			return arg.trim_prefix("--content=")
	return DEFAULT

## {id, name, catalogue, divisions, kit, hashes, unlocks (registry path), errors};
## errors is [] when usable.
static func load_set(set_id: String, seed_value: int = 1) -> Dictionary:
	if set_id == "campaign":
		var out := load_set("slice")
		var profile: Dictionary = Contracts.read_json(CAMPAIGN_PROFILE)
		var schedule := Generator.generate(seed_value, profile, out.catalogue)
		out.errors.append_array(schedule.errors)
		out.id = "campaign"
		out.name = "House Campaign (provisional)"
		out["profile"] = profile
		out["campaign"] = schedule
		out.divisions = schedule.get("divisions", [])
		if schedule.errors.is_empty(): out.errors.append_array(League.validate({"schema_version": 1, "divisions": out.divisions, "championship_reuses_encountered_rule": profile.get("championship_reuses_encountered_rule", false)}, out.catalogue))
		out.hashes.division = FileAccess.get_file_as_string(CAMPAIGN_PROFILE).sha256_text()
		return out
	var out := {"id": set_id, "errors": [], "catalogue": {}, "divisions": [], "kit": {}, "name": "", "hashes": {}, "unlocks": ""}
	if not SETS.has(set_id):
		out.errors.append("unknown content set: " + set_id)
		return out
	var paths: Dictionary = SETS[set_id]
	out.unlocks = paths.unlocks
	out.catalogue = Contracts.read_json(paths.catalogue)
	if not out.catalogue is Dictionary:
		out.errors.append("catalogue unreadable: " + paths.catalogue)
		return out
	out.errors.append_array(Contracts.validate("catalogue", out.catalogue))
	var spec_path: String = paths.get("league", paths.get("division", ""))
	var spec: Variant = Contracts.read_json(spec_path)
	var league: Dictionary
	if paths.has("league"):
		league = spec if spec is Dictionary else {}
	else:
		league = {"schema_version": 1, "id": "league.lab", "name": "House League", "kit": LAB_KIT, "divisions": [spec]}
	out.errors.append_array(League.validate(league, out.catalogue))
	out.divisions = league.get("divisions", [])
	out.kit = league.get("kit", {})
	out.name = league.get("name", "")
	out.errors.append_array(validate_kit(out.kit, out.catalogue))
	# Hashed for save warnings: a changed catalogue or League is reported on load.
	out.hashes = {"catalogue": FileAccess.get_file_as_string(paths.catalogue).sha256_text(),
		"division": FileAccess.get_file_as_string(spec_path).sha256_text()}
	return out

static func validate_kit(kit: Dictionary, catalogue: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var items := {}
	for entry in catalogue.get("items", []):
		items[entry.id] = entry
	var pins: Array = kit.get("pins", [])
	if pins.size() != RunInventory.RACK_SIZE:
		errors.append("a kit racks exactly ten pins")
	for id in pins:
		if items.get(id, {}).get("category", "") != "pin":
			errors.append("kit pin is not a catalogue pin: " + str(id))
	var deck: Array = kit.get("deck", [])
	if deck.size() > RunInventory.DECK_CAP:
		errors.append("kit deck exceeds the deck cap")
	var copies := {}
	for id in deck:
		if items.get(id, {}).get("category", "") not in ["ball", "consumable"]:
			errors.append("kit card is not a ball or tactical card: " + str(id))
		copies[id] = int(copies.get(id, 0)) + 1
		if copies[id] > RunInventory.CARD_COPIES:
			errors.append("kit holds more than %d copies of %s" % [RunInventory.CARD_COPIES, id])
	if "ball.house" in deck:
		errors.append("the House ball stays outside the deck")
	if int(kit.get("money", -1)) < 0:
		errors.append("kit money must be set")
	return errors

## What a content set contributes to the unlock graph: the rivals that can appear
## (each may carry first-clear gates), each boss rule with the Division it first
## plays in, and the kit.
static func graph_source(content: Dictionary) -> Dictionary:
	var rivals: Array = []
	var bosses: Array = []
	if content.id == "campaign":
		# Any profile boss can be drawn for any Division, so each counts from Division 1.
		for boss in content.profile.get("bosses", []):
			rivals.append(boss)
			bosses.append({"rule": boss.rule, "division": 1})
	else:
		for spec in content.divisions:
			for rival in spec.get("rivals", []):
				rivals.append(rival)
				bosses.append({"rule": rival.rule, "division": int(spec.get("division", 1))})
	return {"rivals": rivals, "bosses": bosses, "kit": content.kit}

## The validated Career graph for a registry: every League it names is loaded through
## its content set. {errors, ...} as UnlockGraph.build, plus league_of_set.
static func career_graph(registry_path: String = UNLOCKS) -> Dictionary:
	var registry := UnlockGraph.read(registry_path)
	var sources := {}
	var catalogue := {}
	var errors: Array = []
	for league in registry.get("leagues", []):
		if not league is Dictionary or not league.get("content_set") is String:
			continue
		var content := load_set(league.content_set)
		if not content.errors.is_empty():
			errors.append("%s: content set %s invalid" % [league.get("id", "?"), league.content_set])
			continue
		if not catalogue.is_empty() and content.catalogue != catalogue:
			errors.append("%s: Leagues of one registry must share a catalogue" % league.get("id", "?"))
		catalogue = content.catalogue
		sources[league.get("id", "")] = graph_source(content)
	if registry.is_empty():
		errors.append("unlock registry unreadable: " + registry_path)
	var graph := UnlockGraph.build(registry, catalogue, sources)
	graph.errors = errors + graph.errors
	graph["catalogue"] = catalogue
	return graph
