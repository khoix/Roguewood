extends SceneTree
const Contracts = preload("res://src/contracts/contracts.gd")
const ContractTests = preload("res://tests/contracts_test.gd")

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var mode := args[0] if not args.is_empty() else "unit"
	var failures: Array[String] = []
	if mode == "content":
		failures = Contracts.validate("catalogue", Contracts.read_json("res://content/catalogue.json"))
	elif mode == "unit":
		failures = ContractTests.run()
		var rules_tests = load("res://tests/rules_test.gd")
		if rules_tests == null:
			failures.append("Missing rules tests")
		else:
			failures.append_array(rules_tests.run())
	elif mode == "integration":
		var suite = load("res://tests/contract_rules_test.gd")
		failures = suite.run()
	else:
		failures.append("Unknown test mode")
	for failure in failures: printerr("FAIL: " + failure)
	if failures.is_empty(): print("ROGUEWOOD_" + mode.to_upper() + "_OK")
	quit(0 if failures.is_empty() else 1)
