extends RefCounted
const Contracts = preload("res://src/contracts/contracts.gd")

static func run() -> Array[String]:
	var failures: Array[String] = []
	for kind in ["catalogue", "launch", "roll_result"]:
		var fixture = Contracts.read_json("res://content/fixtures/" + kind + ".json")
		_expect(Contracts.validate(kind, fixture).is_empty(), kind + " valid fixture", failures)
		var roundtrip = JSON.parse_string(JSON.stringify(fixture))
		_expect(roundtrip == fixture and Contracts.validate(kind, roundtrip).is_empty(), kind + " JSON round-trip", failures)
		var bad = fixture.duplicate(true)
		bad.schema_version = 2
		_expect(not Contracts.validate(kind, bad).is_empty(), kind + " unknown version", failures)
		bad = fixture.duplicate(true)
		bad.extra_field = true
		_expect(not Contracts.validate(kind, bad).is_empty(), kind + " unknown field", failures)
		_expect(not Contracts.validate(kind, null).is_empty(), kind + " malformed root", failures)
	var catalogue = Contracts.read_json("res://content/fixtures/catalogue.json")
	var duplicate = catalogue.duplicate(true)
	duplicate.items.append(duplicate.items[0].duplicate(true))
	_expect(not Contracts.validate("catalogue", duplicate).is_empty(), "duplicate ID", failures)
	for mutation in [{"op":"typo"}, {"amount":-1}, {"amount":true}, {"amount":INF}, {"scope":"career"}, {"trigger":"collision"}]:
		var bad = catalogue.duplicate(true)
		bad.items[0].effects[0].merge(mutation, true)
		_expect(not Contracts.validate("catalogue", bad).is_empty(), "malformed effect " + str(mutation), failures)
	var payout = catalogue.duplicate(true)
	payout.items[0].effects[0].op = "payout"
	_expect(Contracts.validate("catalogue", payout).is_empty(), "fallen payout activates then defers", failures)
	payout.items[0].effects[0].op = "add_mult"
	payout.items[0].effects[0].trigger = "after_bank"
	_expect(not Contracts.validate("catalogue", payout).is_empty(), "score mutation after bank", failures)
	var bad_id = catalogue.duplicate(true)
	bad_id.items[0].id = "pin.Wood"
	_expect(not Contracts.validate("catalogue", bad_id).is_empty(), "unstable ID", failures)
	var incomplete = catalogue.duplicate(true)
	incomplete.items[0].completeness.integrated = true
	_expect(not Contracts.validate("catalogue", incomplete).is_empty(), "false completeness", failures)
	var result = Contracts.read_json("res://content/fixtures/roll_result.json")
	result.fallen_positions = [1, 1]
	_expect(not Contracts.validate("roll_result", result).is_empty(), "duplicate pin outcome", failures)
	var launch = Contracts.read_json("res://content/fixtures/launch.json")
	launch.direction_x = 1
	_expect(not Contracts.validate("launch", launch).is_empty(), "invalid direction normalization", failures)
	var valid_launch = Contracts.read_json("res://content/fixtures/launch.json")
	var valid_result = Contracts.read_json("res://content/fixtures/roll_result.json")
	_expect(Contracts.validate_result_for_launch(valid_launch, valid_result).is_empty(), "paired outcome", failures)
	for key in ["launch_id", "ball_id", "roll_index"]:
		var wrong = valid_result.duplicate(true)
		wrong[key] = 2 if key == "roll_index" else "ball.other"
		_expect(not Contracts.validate_result_for_launch(valid_launch, wrong).is_empty(), "mismatched outcome " + key, failures)
	var wrong_ball = valid_launch.duplicate(true)
	wrong_ball.ball_id = "pin.wood"
	_expect(not Contracts.validate("launch", wrong_ball).is_empty(), "launch ball namespace", failures)
	wrong_ball = valid_result.duplicate(true)
	wrong_ball.ball_id = "pin.wood"
	_expect(not Contracts.validate("roll_result", wrong_ball).is_empty(), "result ball namespace", failures)
	var wrong_owner = catalogue.duplicate(true)
	wrong_owner.items[0].effects[0].trigger = "charm"
	_expect(not Contracts.validate("catalogue", wrong_owner).is_empty(), "wrong effect owner", failures)
	return failures

static func _expect(condition: bool, label: String, failures: Array[String]) -> void:
	if not condition: failures.append(label)
