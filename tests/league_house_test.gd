extends RefCounted
## E22-L01: the eight-Division House League is the live production League.
## - The `house` content set loads content/leagues/house.json: eight Divisions with
##   rising targets, recurring rivals (rivals_recur), and two kits with loadouts.
## - Each boss plays one of its listed lanes, chosen by Division number.
## - Rival recurrence is refused without the League's opt-in.
## - The first clears of The Proprietor and Old Lou unlock House Special and Wood Grain.
## - The theme binds each Division's environment, the Championship stage and the lane
##   surfaces by manifest id.
const ContentSet = preload("res://src/rules/content_set.gd")
const League = preload("res://src/rules/league_run.gd")
const LeagueTheme = preload("res://src/presentation/league_theme.gd")
const Contracts = preload("res://src/contracts/contracts.gd")

static func run() -> Array[String]:
	var failures: Array[String] = []
	var house: Dictionary = ContentSet.load_set("house")
	_expect(house.errors.is_empty() and ContentSet.DEFAULT == "house" and house.league_id == "league.house" and house.divisions.size() == 8,
		"the House League (eight Divisions) is the game's default content: %s" % str(house.errors), failures)
	var bosses: Array = house.divisions.map(func(d): return d.matches[2])
	_expect(bosses.map(func(b): return b.lane_condition) == ["lane_condition.house_oil", "lane_condition.dry_backend", "lane_condition.house_oil", "lane_condition.dry_backend",
		"lane_condition.house_oil", "lane_condition.dry_backend", "lane_condition.dry_backend", "lane_condition.dry_backend"],
		"each boss plays one of its listed lanes by Division: %s" % str(bosses.map(func(b): return b.lane_condition)), failures)
	_expect(house.divisions.all(func(d): return d.matches.slice(0, 2).all(func(m): return not m.has("lane_condition"))), "openers and features keep the standard pattern", failures)
	_expect(bosses.map(func(b): return b.rival) == ["rival.surveyor", "rival.custodian", "rival.proprietor", "rival.old_lou", "rival.surveyor", "rival.proprietor", "rival.old_lou", "rival.custodian_champion"],
		"the House rivals, three of them recurring, and the champion last", failures)
	_expect(house.kits.size() == 2 and house.kit.id == "kit.house" and house.kits[1].id == "kit.tournament" and house.kits[1].deck.size() == 4 and int(house.kits[1].money) == 10
		and house.kits[1].unlock == "gate.house_champion", "two kits: House (the default) and Tournament after the title", failures)
	var spec: Dictionary = Contracts.read_json("res://content/leagues/house.json")
	var strict := spec.duplicate(true)
	strict.erase("rivals_recur")
	_expect(League.validate(spec, house.catalogue).is_empty() and League.validate(strict, house.catalogue).any(func(e): return e.contains("boss repeated")),
		"rivals recur only with the League's opt-in", failures)
	var slice: Dictionary = ContentSet.load_set("slice")
	_expect(slice.errors.is_empty() and slice.divisions.size() == 2 and slice.unlocks == ContentSet.SLICE_UNLOCKS, "the two-Division slice stays, with its own registry", failures)
	var campaign: Dictionary = ContentSet.load_set("campaign", 7)
	_expect(campaign.errors.is_empty() and campaign.unlocks == ContentSet.UNLOCKS, "the campaign builds on the House content and the production registry", failures)
	var items := {}
	for item in house.catalogue.items:
		items[item.id] = item
	_expect(items["charm.house_special"].unlock.prerequisites == ["gate.proprietor_cleared"] and items["charm.wood_grain"].unlock.prerequisites == ["gate.old_lou_cleared"]
		and items["kit.tournament"].completeness.mechanics, "the two rival rewards wait for their gates; the Tournament Kit is landed", failures)
	_theme(failures)
	return failures

static func _expect(condition: bool, label: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(label)

static func _theme(failures: Array[String]) -> void:
	var theme = LeagueTheme.for_league("league.house")
	_expect(theme != null and LeagueTheme.for_league("league.neon") == null, "the House League has a theme; Leagues without one have none", failures)
	if theme == null:
		return
	_expect(theme.stage(3, false).environment_id == "environment.league.house.division_03" and theme.stage(8, false).environment_id == "environment.league.house.division_08"
		and theme.stage(8, true).environment_id == "environment.league.house.championship", "stages: each Division, and the Championship for the final boss", failures)
	var stages: Array = theme.manifest.stages
	_expect(stages.all(func(s): return ResourceLoader.exists(theme._asset(s.environment_id))) and ResourceLoader.exists(theme._asset(theme.manifest.music.asset_id)),
		"every stage's environment and the music resolve", failures)
	theme.free()
