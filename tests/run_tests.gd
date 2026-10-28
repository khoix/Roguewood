extends SceneTree
const Contracts = preload("res://src/contracts/contracts.gd")
const ContractTests = preload("res://tests/contracts_test.gd")

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var mode := args[0] if not args.is_empty() else "unit"
	var failures: Array[String] = []
	if mode == "physics":
		call_deferred("_physics", args)
		return
	if mode == "content":
		failures = Contracts.validate("catalogue", Contracts.read_json("res://content/catalogue.json"))
		# Each content set: catalogue, League (Divisions, rivals, rules) and kit (E13).
		for set_id in ["slice", "lab"]:
			for e in load("res://src/rules/content_set.gd").load_set(set_id).errors:
				failures.append("%s: %s" % [set_id, e])
		# The Career unlock graphs (E15, ADR 010): production and lab fixtures.
		var content_set = load("res://src/rules/content_set.gd")
		for registry in [content_set.UNLOCKS, content_set.LAB_UNLOCKS]:
			var graph: Dictionary = content_set.career_graph(registry)
			for e in graph.errors:
				failures.append("%s: %s" % [registry, e])
			print("Unlock graph %s: %d gates, %d objectives, availability %s" % [registry, graph.gates.size(), graph.objectives.size(), str(graph.availability)])
		# E17 authored batches: valid against the catalogue and the prospective graph.
		var authored = load("res://src/content/authored_batches.gd")
		var batches: Array = authored.load_all()
		var production: Dictionary = content_set.load_set("slice").catalogue
		var prospective: Dictionary = content_set.career_graph(content_set.UNLOCKS, authored.items(batches))
		for e in authored.validate(batches, production, prospective.errors):
			failures.append(e)
		print("Authored batches: %d; counts (implemented/authored/target) %s" % [batches.size(), str(authored.counts(production, batches))])
		print("Primitives for E18: %s" % str(authored.primitives(batches)))
		# E17-L League specs and the rival roster, against the prospective catalogue.
		var leagues = load("res://src/content/league_specs.gd")
		var catalogue_ahead: Dictionary = production.duplicate(true)
		catalogue_ahead.items.append_array(authored.items(batches))
		var roster: Dictionary = leagues.roster()
		for e in leagues.validate_roster(roster, catalogue_ahead):
			failures.append(e)
		var specs: Array = leagues.load_all()
		for spec in specs:
			for e in leagues.validate_spec(spec.data, roster, catalogue_ahead, String(spec.path).get_file()):
				failures.append(e)
		print("League specs: %s" % leagues.summary(specs, roster))
	elif mode == "unit":
		failures = ContractTests.run()
		for path in ["res://tests/rules_test.gd", "res://tests/simulation_test.gd", "res://tests/input_test.gd", "res://tests/scoring_test.gd", "res://tests/deck_test.gd", "res://tests/economy_test.gd", "res://tests/division_test.gd", "res://tests/save_test.gd", "res://tests/slice_test.gd", "res://tests/campaign_generator_test.gd", "res://tests/campaign_integration_test.gd", "res://tests/career_test.gd", "res://tests/clubhouse_test.gd", "res://tests/authored_test.gd", "res://tests/mechanics_c02_test.gd", "res://tests/mechanics_c03_test.gd", "res://tests/mechanics_c04_test.gd", "res://tests/league_spec_test.gd"]:
			var suite = load(path)
			if suite == null:
				failures.append("Missing tests: " + path)
			else:
				failures.append_array(suite.run())
		failures.append_array(load("res://tests/ability_events_test.gd").run())
		failures.append_array(load("res://tests/glass_presentation_test.gd").run())
		failures.append_array(load("res://tests/ability_v08_test.gd").run())
	elif mode == "integration":
		var suite = load("res://tests/contract_rules_test.gd")
		failures = suite.run()
	else:
		failures.append("Unknown test mode")
	for failure in failures: printerr("FAIL: " + failure)
	if failures.is_empty(): print("ROGUEWOOD_" + mode.to_upper() + "_OK")
	quit(0 if failures.is_empty() else 1)

## Physics fixtures need live physics ticks; run with --fixed-fps for speed.
func _physics(args: Array) -> void:
	var report := ""
	for arg in args:
		if arg.begins_with("--report="): report = arg.trim_prefix("--report=")
	var suite = load("res://tests/physics_test.gd").new()
	var failures: Array[String] = await suite.run(self, report)
	for failure in failures: printerr("FAIL: " + failure)
	if failures.is_empty(): print("ROGUEWOOD_PHYSICS_OK")
	quit(0 if failures.is_empty() else 1)
