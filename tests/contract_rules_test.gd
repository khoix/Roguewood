extends RefCounted
## Integration test across authored data, simulation boundary, and pure rules.
const Contracts = preload("res://src/contracts/contracts.gd")
const Rules = preload("res://src/rules/frame_rules.gd")

static func run() -> Array[String]:
	var failures: Array[String] = []
	var catalogue = Contracts.read_json("res://content/fixtures/catalogue.json")
	var launch = Contracts.read_json("res://content/fixtures/launch.json")
	var result = Contracts.read_json("res://content/fixtures/roll_result.json")
	failures.append_array(Contracts.validate("catalogue", catalogue))
	failures.append_array(Contracts.validate_result_for_launch(launch, result))
	if not failures.is_empty(): return failures
	var pins: Array = []
	for position in range(1, 11):
		pins.append({"position": position, "item_id": catalogue.items[0].id, "effects": catalogue.items[0].effects.duplicate(true)})
	var roll_one := {"roll_index": result.roll_index, "ball_id": result.ball_id,
		"fallen_positions": result.fallen_positions.duplicate(), "accuracy": result.accuracy, "effects": []}
	var roll_two := {"roll_index": 2, "ball_id": "ball.house", "fallen_positions": [], "accuracy": "miss", "effects": []}
	var frame := {"schema_version": 1, "pins": pins, "rolls": [roll_one, roll_two], "charms": []}
	var snapshot := frame.duplicate(true)
	var resolved := Rules.resolve(frame)
	if not resolved.ok or resolved.get("score") != 60: failures.append("fixture boundary expected 3 Wood pins × (1 + Sweet1) = 60")
	if frame != snapshot: failures.append("resolution mutated consumed records")
	var restored = JSON.parse_string(JSON.stringify(frame))
	if Rules.resolve(restored) != resolved: failures.append("persisted fixture altered resolution")
	var decoded = JSON.parse_string(JSON.stringify(resolved))
	if not _equivalent(decoded, resolved): failures.append("resolved events did not round-trip")
	return failures

# JSON has one number type; Godot decodes numbers as floats. Compare values and
# array order recursively, while retaining strict distinctions for booleans.
static func _equivalent(a: Variant, b: Variant) -> bool:
	if a is Dictionary and b is Dictionary:
		if a.size() != b.size(): return false
		for key in a:
			if not b.has(key) or not _equivalent(a[key], b[key]): return false
		return true
	if a is Array and b is Array:
		if a.size() != b.size(): return false
		for i in a.size():
			if not _equivalent(a[i], b[i]): return false
		return true
	if typeof(a) in [TYPE_INT, TYPE_FLOAT] and typeof(b) in [TYPE_INT, TYPE_FLOAT]:
		return a == b
	return typeof(a) == typeof(b) and a == b
