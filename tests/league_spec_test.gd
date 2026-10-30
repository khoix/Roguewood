extends RefCounted
## E17-L01: the rival roster and the House League spec validate against the
## prospective catalogue (shipped catalogue plus authored batches), and each rule
## refuses a mutated copy: a rule shared or left without a rival, the wrong number of
## rivals for a League, seven Divisions, a falling boss target, a lane outside the
## pool, a champion with another League's rule, a missing reaction, an unknown kit.
## The D05 boss rules' counter tags are met by an initially available item.
const Leagues = preload("res://src/content/league_specs.gd")
const Authored = preload("res://src/content/authored_batches.gd")
const ContentSet = preload("res://src/rules/content_set.gd")
const Graph = preload("res://src/career/unlock_graph.gd")

static func run() -> Array[String]:
	var failures: Array[String] = []
	var catalogue: Dictionary = ContentSet.load_set("slice").catalogue
	var ahead: Dictionary = catalogue.duplicate(true)
	ahead.items.append_array(Authored.items(Authored.load_all()))
	var roster: Dictionary = Leagues.roster()
	var specs: Array = Leagues.load_all()
	var house: Dictionary = specs.filter(func(s): return s.data.get("id") == "league.house")[0].data if specs.any(func(s): return s.data.get("id") == "league.house") else {}
	_expect(Leagues.validate_roster(roster, ahead).is_empty(), "the roster validates: %s" % str(Leagues.validate_roster(roster, ahead)), failures)
	_expect(roster.rivals.size() == 20 and ahead.items.filter(func(i): return i.category == "boss_rule").size() == 20, "20 rivals for 20 boss rules", failures)
	_expect(not house.is_empty() and Leagues.validate_spec(house, roster, ahead, "house.json").is_empty(), "the House spec validates: %s" % str(Leagues.validate_spec(house, roster, ahead, "house.json")), failures)
	if house.is_empty():
		return failures
	_expect(house.divisions[7].matches[2].rival == "rival.custodian_champion" and house.divisions.map(func(d): return int(d.matches[2].target)) == [800, 2400, 5000, 9000, 15000, 24000, 38000, 60000],
		"eight Divisions; the slice's first two targets kept; Division 8 is the championship", failures)
	_roster_refusals(roster, ahead, failures)
	_spec_refusals(house, roster, ahead, failures)
	_counters(catalogue, failures)
	return failures

static func _expect(condition: bool, label: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(label)

static func _roster_refusals(roster: Dictionary, ahead: Dictionary, failures: Array[String]) -> void:
	var refuses := func(change: Callable, text: String, label: String) -> void:
		var copy: Dictionary = roster.duplicate(true)
		change.call(copy)
		var errors := Leagues.validate_roster(copy, ahead)
		_expect(errors.any(func(e): return e.contains(text)), "%s is refused (%s): %s" % [label, text, str(errors)], failures)
	refuses.call(func(r): r.rivals[3].rule = r.rivals[2].rule, "one rival per rule", "two rivals sharing a rule")
	refuses.call(func(r): r.rivals.pop_back(), "has no rival", "a boss rule without a rival")
	refuses.call(func(r): r.rivals[4].league = "league.house", "the plan sets", "a League with the wrong number of rivals")
	refuses.call(func(r): r.rivals[0].rule = "charm.encore", "needs a boss rule", "a rival whose rule is not a boss rule")

static func _spec_refusals(house: Dictionary, roster: Dictionary, ahead: Dictionary, failures: Array[String]) -> void:
	var refuses := func(change: Callable, text: String, label: String) -> void:
		var copy: Dictionary = house.duplicate(true)
		change.call(copy)
		var errors := Leagues.validate_spec(copy, roster, ahead, "house.json")
		_expect(errors.any(func(e): return e.contains(text)), "%s is refused (%s): %s" % [label, text, str(errors)], failures)
	refuses.call(func(h): h.divisions.pop_back(), "a League has 8 Divisions", "seven Divisions")
	refuses.call(func(h): h.divisions[4].matches[2].target = 100; h.divisions[4].matches[1].target = 90; h.divisions[4].matches[0].target = 80, "rises across the League", "a falling boss target")
	refuses.call(func(h): h.divisions[0].matches[2].lanes = ["lane_condition.neon_glow"], "from the League's pool", "a lane outside the pool")
	refuses.call(func(h): h.divisions[7].rivals[0].extra_rules = ["boss_rule.oil_slick"], "extra rules from the same League", "a champion with another League's rule")
	refuses.call(func(h): h.divisions[2].rivals[0].reactions.erase("defeated"), "needs every reaction", "a missing reaction")
	refuses.call(func(h): h.kits[1].id = "kit.nope", "is not a kit item", "an unknown kit")
	refuses.call(func(h): h.divisions[3].matches[2].rival = "rival.slick"; h.divisions[3].rivals = [roster.rivals.filter(func(r): return r.id == "rival.slick")[0]], "not one of this League's roster rivals", "another League's rival")

## D05's nine boss rules: counter tags in the registry, each met by an initially available item.
static func _counters(catalogue: Dictionary, failures: Array[String]) -> void:
	var counters: Dictionary = Graph.read(ContentSet.UNLOCKS).counters
	var d05: Array = Authored.load_all().filter(func(b): return b.data.batch == "E17-D05")
	var rules: Array = d05[0].data.definitions.filter(func(d): return d.item.category == "boss_rule").map(func(d): return d.item.id) + d05[0].data.landed.filter(func(l): return l.id.begins_with("boss_rule.")).map(func(l): return l.id) if not d05.is_empty() else []
	_expect(rules.size() == 9, "D05 writes nine boss rules (House Pins landed by E18-C05)", failures)
	for id in rules:
		var tags: Array = counters.get(id, [])
		var answer: bool = catalogue.items.any(func(i): return i.unlock.kind == "initial" and float(i.pool_weight) > 0 and i.synergy_tags.any(func(t): return t in tags))
		_expect(not tags.is_empty() and answer, "%s has counter tags met by an initially available item" % id, failures)
