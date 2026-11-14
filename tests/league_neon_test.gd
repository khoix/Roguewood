extends RefCounted
## E22-L02: the Neon League is live beside the House League.
## - The `neon` content set loads content/leagues/neon.json on the production catalogue
##   and registry: eight Divisions, the House League's targets, recurring rivals.
## - Openers keep House Oil; features and bosses play their listed lane by Division.
## - The Neon Kit (two Hook, two Glow, two Spare Ball cards, $6) is landed and open.
## - The registry lists the League, open from the start, with its four rival gates
##   and its title; the five DC-N1 rewards wait for those gates and are reachable.
const ContentSet = preload("res://src/rules/content_set.gd")
const LeagueTheme = preload("res://src/presentation/league_theme.gd")
const UiTheme = preload("res://src/presentation/house_ui_theme.gd")
const Shop = preload("res://src/rules/shop.gd")
const UnlockGraph = preload("res://src/career/unlock_graph.gd")
const REWARDS := {"ball.oilskin": "gate.slick_cleared", "ball.laser": "gate.laser_lena_cleared", "pin.tempo": "gate.dj_flicker_cleared",
	"charm.neon_sign": "gate.neon_champion_cleared", "ball_mod.blacklight": "gate.neon_champion"}

static func run() -> Array[String]:
	var failures: Array[String] = []
	var neon: Dictionary = ContentSet.load_set("neon")
	var house: Dictionary = ContentSet.load_set("house")
	_expect(neon.errors.is_empty() and neon.league_id == "league.neon" and neon.name == "Neon League" and neon.divisions.size() == 8
		and neon.unlocks == ContentSet.UNLOCKS and neon.catalogue.items.size() == house.catalogue.items.size(),
		"the Neon League (eight Divisions) loads on the production catalogue and registry: %s" % str(neon.errors), failures)
	var targets := func(set_data): return set_data.divisions.map(func(d): return d.matches.map(func(m): return int(m.target)))
	_expect(targets.call(neon) == targets.call(house), "its provisional targets follow the House League's", failures)
	_expect(neon.divisions.all(func(d): return not d.matches[0].has("lane_condition")), "openers keep House Oil", failures)
	var lanes: Array = neon.divisions.map(func(d): return [d.matches[1].get("lane_condition", ""), d.matches[2].get("lane_condition", "")])
	_expect(lanes == [["", "lane_condition.house_oil"], ["lane_condition.long_oil", "lane_condition.house_oil"], ["lane_condition.two_tone", "lane_condition.two_tone"],
		["lane_condition.long_oil", "lane_condition.long_oil"], ["lane_condition.two_tone", "lane_condition.two_tone"], ["lane_condition.long_oil", "lane_condition.long_oil"],
		["lane_condition.two_tone", "lane_condition.two_tone"], ["lane_condition.long_oil", "lane_condition.two_tone"]],
		"features and bosses play their listed lanes: %s" % str(lanes), failures)
	_expect(neon.divisions.map(func(d): return d.matches[2].rival) == ["rival.slick", "rival.laser_lena", "rival.dj_flicker", "rival.slick", "rival.laser_lena",
		"rival.dj_flicker", "rival.slick", "rival.dj_flicker_champion"], "Slick, Laser Lena and DJ Flicker recur; the champion is last", failures)
	var deck: Array = neon.kit.deck.duplicate()
	deck.sort()
	_expect(neon.kits.size() == 1 and neon.kit.id == "kit.neon" and neon.kit.unlock == "initial" and int(neon.kit.money) == 6
		and deck == ["ball.glow", "ball.glow", "ball.hook", "ball.hook", "ball.spare_ball", "ball.spare_ball"] and ContentSet.validate_kit(neon.kit, neon.catalogue).is_empty(),
		"the Neon Kit: two Hook, two Glow and two Spare Ball cards, $6", failures)
	var items := {}
	for item in neon.catalogue.items:
		items[item.id] = item
	_expect(items["kit.neon"].completeness.mechanics, "the Neon Kit is landed", failures)
	for id in REWARDS:
		_expect(items[id].unlock.kind != "initial" and items[id].unlock.prerequisites == [REWARDS[id]], "%s waits for %s" % [id, REWARDS[id]], failures)
	var graph: Dictionary = ContentSet.career_graph()
	_expect(graph.get("errors", []).is_empty() and graph.leagues.has("league.neon") and graph.get("league_of_set", {}).get("neon", "") == "league.neon",
		"the registry lists the Neon League: %s" % str(graph.get("errors", [])), failures)
	var fresh := {"unlocked": [], "first_clears": {}, "championships": {}, "mastery": {}, "records": {}}
	_expect(UnlockGraph.league_access(graph, fresh, "league.neon").is_empty(), "it is open to a new Career", failures)
	for gate in REWARDS.values():
		_expect(graph.gates.has(gate), "%s is registered" % gate, failures)
	_specialists(neon, house, failures)
	_theme(neon, failures)
	return failures

## E22-L02-ART bound live: a stage for every Division and the Championship, a finish
## for every listed lane, the music, the flank backdrop and the five-frame kit.
static func _theme(neon: Dictionary, failures: Array[String]) -> void:
	var theme = LeagueTheme.for_league("league.neon")
	_expect(theme != null, "the Neon League has a theme", failures)
	if theme == null:
		return
	_expect(range(1, 9).all(func(d): return theme.stage(d, false).environment_id == "environment.league.neon.division_%02d" % d)
		and theme.stage(8, true).environment_id == "environment.league.neon.championship"
		and theme.manifest.stages.all(func(s): return ResourceLoader.exists(theme._asset(s.environment_id))), "stages: each Division's room and the Championship resolve", failures)
	var listed := {}
	for d in neon.divisions:
		for m in d.matches:
			if m.has("lane_condition"): listed[m.lane_condition] = true
	var finishes: Array = theme.manifest.lanes.map(func(l): return l.condition_id)
	_expect(listed.keys().all(func(c): return c in finishes) and theme.manifest.lanes.all(func(l): return ResourceLoader.exists(theme._asset(l.visual_id))),
		"every lane the League lists has a finish: %s" % str(listed.keys()), failures)
	_expect(ResourceLoader.exists(theme._asset(theme.manifest.music.asset_id)), "the music resolves", failures)
	var flank: Control = theme.flank()
	_expect(flank != null and "reduced" in flank and flank.get_meta("backdrop_id") == "backdrop.ui.neon.normal", "the flank backdrop loads and can be stilled", failures)
	if flank != null: flank.free()
	theme.free()
	UiTheme.use_kit("league.neon")
	var neon_frames: Array = ["hud", "panel", "slip", "menu", "shop"].map(func(k): return (UiTheme.frame(k) as StyleBoxTexture).texture.resource_path)
	UiTheme.use_kit("league.salvage")
	var house_frame: String = (UiTheme.frame("hud") as StyleBoxTexture).texture.resource_path
	_expect(neon_frames == ["hud", "panel", "slip", "menu", "shop"].map(func(k): return "res://assets/ui/neon/%s.svg" % k) and house_frame.begins_with("res://assets/ui/house/")
		and UiTheme.kit_id() == "house", "the Neon kit has all five frames; a League without a kit keeps the House frames: %s" % str(neon_frames), failures)

## Specialist weights: Neon's tags count twice within a category and rarity; the
## House League picks exactly as before; nothing is excluded.
static func _specialists(neon: Dictionary, house: Dictionary, failures: Array[String]) -> void:
	_expect(neon.specialists.tags == ["curve", "hook", "accuracy", "precision", "straight"] and int(neon.specialists.weight) == 2 and house.specialists.is_empty(),
		"Neon names its specialist tags; the House League has none", failures)
	var plain = Shop.create(neon.catalogue, 11)
	var biased = Shop.create(neon.catalogue, 11)
	biased.specialists = neon.specialists
	var items := {}
	for item in neon.catalogue.items:
		items[item.id] = item
	_expect(biased.pool_weight(items["ball.glow"]) == 2.0 and biased.pool_weight(items["charm.laser_level"]) == 2.0 and biased.pool_weight(items["charm.trophy_case"]) == 1.0
		and plain.pool_weight(items["ball.glow"]) == 1.0, "a specialist counts twice here and once elsewhere", failures)
	var commons: Array = neon.catalogue.items.filter(func(i): return i.category == "charm" and i.rarity == "common" and float(i.pool_weight) > 0.0)
	var counts := {"plain": 0, "biased": 0}
	var seen := {}
	for i in 4000:
		if biased.pool_weight(plain._weighted(commons.duplicate())) > 1.0: counts.plain += 1
		var chosen: Dictionary = biased._weighted(commons.duplicate())
		seen[chosen.id] = true
		if biased.pool_weight(chosen) > 1.0: counts.biased += 1
	_expect(counts.biased > counts.plain and seen.size() == commons.size(), "specialists are picked more often (%d against %d of 4000) and every common Charm still appears (%d of %d)" % [counts.biased, counts.plain, seen.size(), commons.size()], failures)

static func _expect(condition: bool, label: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(label)
