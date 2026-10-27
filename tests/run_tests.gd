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
	elif mode == "unit":
		failures = ContractTests.run()
		for path in ["res://tests/rules_test.gd", "res://tests/simulation_test.gd", "res://tests/input_test.gd", "res://tests/scoring_test.gd", "res://tests/deck_test.gd", "res://tests/economy_test.gd"]:
			var suite = load(path)
			if suite == null:
				failures.append("Missing tests: " + path)
			else:
				failures.append_array(suite.run())
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
