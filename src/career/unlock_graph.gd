extends RefCounted
## The Career unlock graph (E15, design §16, ADR 010). A registry
## (content/career/unlocks.json) declares every gate with a stable ID and kind, the
## Leagues (access prerequisites and championship awards) and the mastery
## objectives; boss gates come from the League specs' rivals (first_clear.unlocks),
## and catalogue items name the gates they wait for (unlock.prerequisites).
##
## build() joins them and validates the whole graph before any attempt uses it:
## - every ID is unique and well formed; every gate is declared once with one kind,
##   is awarded by at least one source of that kind, and every prerequisite names a
##   declared gate (an item's unlock kind matches its gates' kind);
## - no circular prerequisite (a League needing its own championship, an objective
##   needing its own gate, or any longer loop);
## - everything locked is reachable from a fresh Career by playing: a fixpoint over
##   accessible Leagues, their rivals and championships, and available objectives.
##   A pin-material objective is feasible only with enough pins reachable without
##   its own reward, so no item is needed to unlock itself;
## - every initially accessible League offers, from its first boss Division, a
##   counter to each boss rule that is available from the start (never only behind
##   the rival it is needed to beat).
## Pure data: no scene, file writes or Career state.
const METRICS := {"strikes": ["career", "attempt"], "spares": ["career", "attempt"], "curved_strikes": ["career", "attempt"], "pin_materials": ["attempt"]}
const KINDS := ["boss", "championship", "mastery"]
const COSMETIC_MILESTONES := ["first_clears", "championships", "mastery"]

## The registry file, or {} if unreadable (build() then reports it).
static func read(path: String) -> Dictionary:
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK or not parser.data is Dictionary:
		return {}
	return parser.data

## registry: the unlocks file. catalogue: the shared catalogue. sources: league id ->
## {rivals: [rival dicts that can appear], bosses: [{rule, division}], kit: {deck,
## pins}} from the League's content set. Returns {errors, gates, leagues,
## objectives, league_of_set, items_by_gate, availability}.
static func build(registry: Dictionary, catalogue: Dictionary, sources: Dictionary) -> Dictionary:
	var graph := {"errors": [], "gates": {}, "leagues": {}, "objectives": [], "league_of_set": {}, "items_by_gate": {}, "availability": {}, "counters": {},
		"rivals": {}, "cosmetics": []}
	var errors: Array = graph.errors
	if int(registry.get("schema_version", 0)) != 1:
		errors.append("unlock registry needs schema_version 1")
		return graph
	var ids := {}
	var claim := func(id: Variant, prefix: String, what: String) -> bool:
		if not id is String or not String(id).begins_with(prefix) or String(id).length() <= prefix.length():
			errors.append("%s id must start with %s: %s" % [what, prefix, str(id)])
			return false
		if ids.has(id):
			errors.append("duplicate id: " + id)
			return false
		ids[id] = true
		return true
	for gate in registry.get("gates", []):
		if not gate is Dictionary or not claim.call(gate.get("id"), "gate.", "gate"):
			continue
		if gate.get("kind") not in KINDS:
			errors.append("%s: kind must be one of %s" % [gate.id, str(KINDS)])
		if not gate.get("name") is String or String(gate.name).is_empty():
			errors.append(gate.id + ": needs a name")
		graph.gates[gate.id] = gate.merged({"sources": []})
	for league in registry.get("leagues", []):
		if not league is Dictionary or not claim.call(league.get("id"), "league.", "League"):
			continue
		var champion: Variant = league.get("championship")
		if not league.get("content_set") is String or not league.get("access") is Array or not champion is Dictionary or not champion.get("gates") is Array:
			errors.append(league.id + ": needs content_set, access and championship {gates, text}")
			continue
		graph.leagues[league.id] = league
		graph.league_of_set[league.content_set] = league.id
		if not sources.has(league.id):
			errors.append(league.id + ": its content set %s did not load" % league.content_set)
	for objective in registry.get("objectives", []):
		if not objective is Dictionary or not claim.call(objective.get("id"), "mastery.", "objective"):
			continue
		var metric: String = str(objective.get("metric", ""))
		if not METRICS.has(metric):
			errors.append("%s: unknown metric %s" % [objective.id, metric])
		elif objective.get("scope") not in METRICS[metric]:
			errors.append("%s: %s cannot be counted with scope %s" % [objective.id, metric, str(objective.get("scope"))])
		var threshold: Variant = objective.get("threshold")
		if not (threshold is float or threshold is int) or float(threshold) != floorf(float(threshold)) or int(threshold) < 1:
			errors.append(objective.id + ": threshold must be a positive integer")
		for key in ["name", "text", "reward"]:
			if not objective.get(key) is String or String(objective.get(key)).is_empty():
				errors.append("%s: needs %s" % [objective.id, key])
		if not objective.get("gates") is Array or objective.gates.is_empty() or not objective.get("prerequisites") is Array:
			errors.append(objective.id + ": needs gates (at least one) and prerequisites")
			continue
		graph.objectives.append(objective)
	# Club cosmetics (E16, design §16): milestone decorations with no gameplay effect.
	for cosmetic in registry.get("cosmetics", []):
		if not cosmetic is Dictionary or not claim.call(cosmetic.get("id"), "deco.", "cosmetic"):
			continue
		var needs: Variant = cosmetic.get("requires")
		if not needs is Dictionary or needs.size() != 1 or needs.keys()[0] not in COSMETIC_MILESTONES or not (needs.values()[0] is float or needs.values()[0] is int) or int(needs.values()[0]) < 1:
			errors.append("%s: requires one milestone count from %s" % [cosmetic.id, str(COSMETIC_MILESTONES)])
		if not cosmetic.get("name") is String or String(cosmetic.name).is_empty():
			errors.append(cosmetic.id + ": needs a name")
		graph.cosmetics.append(cosmetic)
	var counters: Variant = registry.get("counters", {})
	graph.counters = counters if counters is Dictionary else {}
	if not errors.is_empty():
		return graph
	# Sources of each gate, and every prerequisite naming a declared gate.
	var award := func(gate_id: Variant, kind: String, source: String) -> void:
		if not graph.gates.has(gate_id):
			errors.append("%s awards undeclared gate %s" % [source, str(gate_id)])
			return
		if graph.gates[gate_id].kind != kind:
			errors.append("%s is a %s gate but %s awards it" % [gate_id, graph.gates[gate_id].kind, source])
		graph.gates[gate_id].sources.append(source)
	var need := func(gate_id: Variant, who: String) -> void:
		if not graph.gates.has(gate_id):
			errors.append("%s requires undeclared gate %s" % [who, str(gate_id)])
	for league_id in graph.leagues:
		var league: Dictionary = graph.leagues[league_id]
		for gate in league.access:
			need.call(gate, league_id)
		for gate in league.championship.gates:
			award.call(gate, "championship", league_id)
		for rival in sources.get(league_id, {}).get("rivals", []):
			# Names for the Clubhouse (E16); provisional encounter fixtures get no plaque.
			graph.rivals[rival.id] = {"name": rival.get("name", rival.id), "league": league_id, "plaque": not league.get("provisional_rivals", false)}
			for gate in rival.get("first_clear", {}).get("unlocks", []):
				award.call(gate, "boss", "%s:%s" % [league_id, rival.id])
	for objective in graph.objectives:
		for gate in objective.prerequisites:
			need.call(gate, objective.id)
		for gate in objective.gates:
			award.call(gate, "mastery", objective.id)
	var items: Dictionary = {}
	for item in catalogue.get("items", []):
		items[item.id] = item
		var unlock: Dictionary = item.get("unlock", {})
		for gate in unlock.get("prerequisites", []):
			need.call(gate, item.id)
			if graph.gates.has(gate):
				if graph.gates[gate].kind != unlock.kind:
					errors.append("%s is a %s unlock but waits for %s gate %s" % [item.id, unlock.kind, graph.gates[gate].kind, gate])
				if not graph.items_by_gate.has(gate):
					graph.items_by_gate[gate] = []
				graph.items_by_gate[gate].append(item.id)
	for gate_id in graph.gates:
		if graph.gates[gate_id].sources.is_empty():
			errors.append("gate %s is never awarded" % gate_id)
	if not errors.is_empty():
		return graph
	errors.append_array(_cycles(graph, items))
	if not errors.is_empty():
		return graph
	errors.append_array(_reachability(graph, items, sources))
	errors.append_array(_counters(graph, items, sources))
	graph.availability = availability(catalogue)
	return graph

## Gates met by a fresh Career, then everything reachable by playing.
static func reachable(graph: Dictionary, items: Dictionary, sources: Dictionary, excluded_gates: Array = []) -> Dictionary:
	var met := {}
	var flag := {"changed": true} # lambdas capture locals by value; a Dictionary is shared
	while flag.changed:
		flag.changed = false
		var gain := func(gate: String) -> void:
			if not met.has(gate) and gate not in excluded_gates:
				met[gate] = true
				flag.changed = true
		for league_id in graph.leagues:
			var league: Dictionary = graph.leagues[league_id]
			if not league.access.all(func(g): return met.has(g)):
				continue
			for gate in league.championship.gates:
				gain.call(gate)
			for rival in sources.get(league_id, {}).get("rivals", []):
				for gate in rival.get("first_clear", {}).get("unlocks", []):
					gain.call(gate)
		for objective in graph.objectives:
			if objective.prerequisites.all(func(g): return met.has(g)) and _feasible(objective, met, items, excluded_gates + objective.gates):
				for gate in objective.gates:
					gain.call(gate)
	return met

## A pin-material objective needs that many distinct pins in the pool without its own reward.
static func _feasible(objective: Dictionary, met: Dictionary, items: Dictionary, without: Array) -> bool:
	if objective.metric != "pin_materials":
		return true
	var pins := 0
	for item in items.values():
		if item.category == "pin" and item.unlock.prerequisites.all(func(g): return met.has(g) and g not in without):
			pins += 1
	return pins >= int(objective.threshold)

static func _reachability(graph: Dictionary, items: Dictionary, sources: Dictionary) -> Array:
	var errors: Array = []
	var met := reachable(graph, items, sources)
	for league_id in graph.leagues:
		if not graph.leagues[league_id].access.all(func(g): return met.has(g)):
			errors.append("League %s can never be entered" % league_id)
	for objective in graph.objectives:
		if not objective.gates.all(func(g): return met.has(g)):
			errors.append("objective %s can never be completed (prerequisites or pins out of reach)" % objective.id)
	for item in items.values():
		var waiting: Array = item.unlock.prerequisites.filter(func(g): return not met.has(g))
		if not waiting.is_empty():
			errors.append("%s is unreachable: %s never met" % [item.id, ", ".join(waiting)])
	return errors

## Requirement edges: League -> access gates, objective -> prerequisite gates, gate
## -> each source (a League or objective), item -> its gates. Any loop is refused.
static func _cycles(graph: Dictionary, items: Dictionary) -> Array:
	var edges := {}
	for league_id in graph.leagues:
		edges[league_id] = graph.leagues[league_id].access.duplicate()
	for objective in graph.objectives:
		edges[objective.id] = objective.prerequisites.duplicate()
	for gate_id in graph.gates:
		edges[gate_id] = graph.gates[gate_id].sources.map(func(s): return String(s).get_slice(":", 0))
	for item in items.values():
		if not item.unlock.prerequisites.is_empty():
			edges[item.id] = item.unlock.prerequisites.duplicate()
	var errors: Array = []
	var state := {} # 1 visiting, 2 done
	var path: Array = []
	var visit := func(node: String, visit_ref: Callable) -> void:
		if int(state.get(node, 0)) == 2:
			return
		if int(state.get(node, 0)) == 1:
			var loop: Array = path.slice(path.find(node)) + [node]
			errors.append("circular prerequisite: " + " -> ".join(loop))
			return
		state[node] = 1
		path.append(node)
		for next in edges.get(node, []):
			visit_ref.call(next, visit_ref)
		path.pop_back()
		state[node] = 2
	var nodes: Array = edges.keys()
	nodes.sort()
	for node in nodes:
		visit.call(node, visit)
	return errors

## Each boss rule of an initially accessible League has a counter in the opening
## pool (or the kit) by the Division its first boss plays in.
static func _counters(graph: Dictionary, items: Dictionary, sources: Dictionary) -> Array:
	var errors: Array = []
	for league_id in graph.leagues:
		if not graph.leagues[league_id].access.is_empty():
			continue
		var source: Dictionary = sources.get(league_id, {})
		var kit_items: Array = source.get("kit", {}).get("deck", []) + source.get("kit", {}).get("pins", [])
		for boss in source.get("bosses", []):
			var tags: Variant = graph.counters.get(boss.rule)
			if not tags is Array or tags.is_empty():
				errors.append("%s: boss rule %s declares no counter tags" % [league_id, boss.rule])
				continue
			var found := false
			for item in items.values():
				var offered: bool = item.unlock.kind == "initial" and float(item.pool_weight) > 0.0 and item.rarity != "legendary" and int(item.earliest_division) <= int(boss.division)
				if (offered or item.id in kit_items) and item.synergy_tags.any(func(t): return t in tags):
					found = true
					break
			if not found:
				errors.append("%s: no initially available counter to %s by Division %d" % [league_id, boss.rule, int(boss.division)])
	return errors

## Per category: how many definitions are available from the start and how many are
## locked, for the §16 allocation targets (12 of 24 balls, 16 of 32 pins, 60 of 100
## Charms initially). A report, not a gate: E17 authors toward the targets.
static func availability(catalogue: Dictionary) -> Dictionary:
	var out := {}
	for item in catalogue.get("items", []):
		if not out.has(item.category):
			out[item.category] = {"initial": 0, "locked": 0}
		out[item.category]["initial" if item.unlock.kind == "initial" else "locked"] += 1
	return out

## "" when the Career may enter the League, else why not.
static func league_access(graph: Dictionary, career: Dictionary, league_id: String) -> String:
	var league: Dictionary = graph.get("leagues", {}).get(league_id, {})
	if league.is_empty():
		return "unknown League"
	var missing: Array = league.access.filter(func(g): return g not in career.get("unlocked", []))
	if missing.is_empty():
		return ""
	return "Locked: needs " + ", ".join(missing.map(func(g): return graph.gates.get(g, {}).get("name", g)))
