extends RefCounted
## JSON-compatible contracts; no scene, physics, presentation or RNG dependencies.
const SCHEMA_ROOT = "res://content/schemas/"

static func read_json(path: String) -> Variant:
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK:
		return null
	return parser.data

static func validate(kind: String, record: Variant) -> Array[String]:
	var errors: Array[String] = []
	if kind not in ["catalogue", "launch", "roll_result", "knockdown_log"]:
		errors.append("Unknown contract: " + kind)
		return errors
	var schema = read_json(SCHEMA_ROOT + kind + ".schema.json")
	if not schema is Dictionary:
		errors.append("Missing or invalid schema: " + kind)
		return errors
	_check(schema, record, "$", errors)
	if not errors.is_empty():
		return errors
	if kind == "catalogue":
		_catalogue(record.items, errors)
	elif kind == "roll_result":
		var seen := {}
		for position in record.fallen_positions:
			if seen.has(int(position)):
				errors.append("Duplicate fallen position: " + str(position))
			seen[int(position)] = true
	elif kind == "knockdown_log":
		_knockdown_log(record, errors)
	elif kind == "launch":
		var length_squared: float = record.direction_x * record.direction_x + record.direction_forward * record.direction_forward
		if absf(length_squared - 1.0) > 0.0001:
			errors.append("Launch direction must be a normalized forward vector")
	return errors

static func validate_result_for_launch(launch: Variant, result: Variant) -> Array[String]:
	var errors := validate("launch", launch)
	errors.append_array(validate("roll_result", result))
	if not errors.is_empty(): return errors
	for key in ["launch_id", "ball_id", "roll_index"]:
		if launch[key] != result[key]: errors.append("Result does not match launch: " + key)
	return errors

## A knockdown log must credit exactly the result's fallen pins for the same roll.
static func validate_log_for_result(result: Variant, knockdown_log: Variant) -> Array[String]:
	var errors := validate("roll_result", result)
	errors.append_array(validate("knockdown_log", knockdown_log))
	if not errors.is_empty(): return errors
	for key in ["launch_id", "ball_id", "roll_index"]:
		if knockdown_log[key] != result[key]: errors.append("Log does not match result: " + key)
	var credited: Array = knockdown_log.knockdowns.map(func(entry): return int(entry.position))
	var fallen: Array = result.fallen_positions.map(func(position): return int(position))
	credited.sort()
	fallen.sort()
	if credited != fallen: errors.append("Log knockdowns differ from result fallen_positions")
	return errors

static func _knockdown_log(record: Dictionary, errors: Array[String]) -> void:
	var seen := {}
	var previous_tick := -1
	for index in record.knockdowns.size():
		var entry: Dictionary = record.knockdowns[index]
		var position := int(entry.position)
		if seen.has(position): errors.append("Pin credited twice: " + str(position))
		seen[position] = true
		if int(entry.sequence) != index + 1: errors.append("Knockdown sequence must count 1..n in order")
		if int(entry.tick) < previous_tick: errors.append("Knockdown ticks must not decrease")
		previous_tick = int(entry.tick)
		var source := int(entry.source_position)
		var depth := int(entry.chain_depth)
		match entry.cause:
			"ball":
				if source != 0 or depth != 1: errors.append("Ball knockdown must be depth 1 without source pin")
			"pin":
				if source == 0 or source == position or depth < 2: errors.append("Pin knockdown needs another source pin and depth >= 2")
			"environment":
				if source != 0 or depth != 0: errors.append("Environment knockdown has no source or depth")
	for position in record.standing:
		if seen.has(int(position)): errors.append("Pin both standing and credited: " + str(position))
		seen[int(position)] = true
	for entry in record.knockdowns:
		if int(entry.source_position) > 0 and not seen.has(int(entry.source_position)): errors.append("Knockdown source pin was not racked")
	if record.gutter and not record.knockdowns.is_empty(): errors.append("Gutter ball cannot credit pinfall")
	if not record.gutter and not record.voided_positions.is_empty(): errors.append("Only a gutter ball voids pinfall")
	for position in record.voided_positions:
		if int(position) not in record.standing.map(func(p): return int(p)): errors.append("Voided pins are respotted standing")
	if not record.target_crossed and record.target_offset != 0: errors.append("Uncrossed target has no offset")

static func _check(schema: Dictionary, value: Variant, path: String, errors: Array[String]) -> void:
	var kind: String = schema.type
	var numeric := typeof(value) in [TYPE_INT, TYPE_FLOAT]
	var valid := false
	match kind:
		"object": valid = value is Dictionary
		"array": valid = value is Array
		"string": valid = value is String
		"boolean": valid = typeof(value) == TYPE_BOOL
		"number": valid = numeric and is_finite(float(value))
		"integer": valid = numeric and is_finite(float(value)) and float(value) == floor(float(value))
	if not valid:
		errors.append(path + ": expected " + kind)
		return
	if schema.has("enum") and not _in_enum(value, schema["enum"]):
		errors.append(path + ": unsupported value " + str(value))
	match kind:
		"object":
			for key in schema.get("required", []):
				if not value.has(key): errors.append(path + ": missing " + key)
			for key in value:
				if not schema.properties.has(key):
					errors.append(path + ": unknown field " + str(key))
				else:
					_check(schema.properties[key], value[key], path + "." + key, errors)
		"array":
			if value.size() < schema.get("minItems", 0) or value.size() > schema.get("maxItems", 1000):
				errors.append(path + ": invalid item count")
			for i in value.size(): _check(schema.items, value[i], path + "[" + str(i) + "]", errors)
		"string":
			if value.length() < schema.get("minLength", 0): errors.append(path + ": empty string")
			if schema.has("pattern"):
				var regex := RegEx.new()
				regex.compile(schema.pattern)
				if regex.search(value) == null: errors.append(path + ": invalid stable ID")
		"number", "integer":
			if value < schema.get("minimum", -INF) or value > schema.get("maximum", INF):
				errors.append(path + ": number outside contract bounds")

## Schemas decode numbers as floats; engine-built records may hold ints. Compare
## numbers by value, everything else by type and value (true never equals 1).
static func _in_enum(value: Variant, options: Array) -> bool:
	var numeric := typeof(value) in [TYPE_INT, TYPE_FLOAT]
	for option in options:
		if numeric and typeof(option) in [TYPE_INT, TYPE_FLOAT]:
			if float(option) == float(value): return true
		elif typeof(option) == typeof(value) and option == value:
			return true
	return false

static func _catalogue(items: Array, errors: Array[String]) -> void:
	var ids := {}
	for item in items:
		if ids.has(item.id): errors.append("Duplicate item ID: " + item.id)
		ids[item.id] = true
		if not item.id.begins_with(item.category + "."): errors.append(item.id + ": ID prefix must match category")
		if item.resale_price > item.purchase_price: errors.append(item.id + ": resale exceeds purchase")
		if item.rarity == "legendary" and item.pool_weight != 0: errors.append(item.id + ": legendary is reward-only")
		if item.unlock.kind == "initial" and not item.unlock.prerequisites.is_empty(): errors.append(item.id + ": initial unlock cannot have prerequisites")
		if item.unlock.kind != "initial" and item.unlock.prerequisites.is_empty(): errors.append(item.id + ": locked item needs prerequisites")
		for effect in item.effects:
			var allowed := {"pin": ["fallen", "standing", "after_bank"], "ball": ["ball", "after_bank"], "charm": ["charm", "after_bank"]}
			if allowed.has(item.category) and effect.trigger not in allowed[item.category]: errors.append(item.id + ": effect trigger does not match category")
			if effect.op not in ["payout", "grow_value"] and effect.trigger == "after_bank": errors.append(item.id + ": score mutation cannot follow banking")
			if effect.op == "multiply_mult" and effect.amount <= 0: errors.append(item.id + ": multiplier must be positive")
		if item.completeness.artwork:
			for key in ["icon", "card", "rarity_treatment"]:
				if item.assets[key].is_empty(): errors.append(item.id + ": artwork marked complete without " + key)
			if item.category in ["pin", "ball"] and item.assets.in_play.is_empty(): errors.append(item.id + ": missing in-play asset")
		if item.completeness.integrated:
			for flag in item.completeness:
				if not item.completeness[flag]: errors.append(item.id + ": integrated with unfinished " + flag)
	for item in items:
		for other in item.incompatibilities:
			if other == item.id or not ids.has(other): errors.append(item.id + ": invalid incompatibility " + other)
