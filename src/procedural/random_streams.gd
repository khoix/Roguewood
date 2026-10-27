extends RefCounted
## Versioned integer PRNG: JSON-exact states, independent of engine RNG changes.
## Stream derivation is ordered and stable; presentation never gets a stream.
const NAMES := ["shops", "rewards", "lanes", "bosses", "effects"]
const MODULUS := 2147483647
var states: Dictionary = {}

static func create(seed_value: int) -> RefCounted:
	var result = load("res://src/procedural/random_streams.gd").new()
	for stream in NAMES:
		var value := posmod(seed_value, MODULUS - 1) + 1
		for byte in stream.to_utf8_buffer():
			value = (value * 48271 + int(byte)) % MODULUS
		result.states[stream] = maxi(value, 1)
	return result

func draw(stream: String, bound: int) -> int:
	assert(states.has(stream) and bound > 0 and bound < MODULUS)
	# Rejection sampling avoids modulo bias.
	var limit := MODULUS - 1 - (MODULUS - 1) % bound
	while true:
		states[stream] = (int(states[stream]) * 48271) % MODULUS
		var sample := int(states[stream]) - 1
		if sample < limit:
			return sample % bound
	return 0

func to_dict() -> Dictionary:
	return {"version": 1, "states": states.duplicate()}

static func restore(data: Dictionary) -> RefCounted:
	if int(data.get("version", 0)) != 1 or not data.get("states") is Dictionary:
		return null
	var result = load("res://src/procedural/random_streams.gd").new()
	for stream in NAMES:
		var value = data.states.get(stream, 0)
		if not (value is int or value is float) or value != int(value) or value < 1 or value >= MODULUS:
			return null
		result.states[stream] = int(value)
	return result
