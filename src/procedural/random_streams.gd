extends RefCounted
## Versioned integer PRNG: JSON-exact states, independent of engine RNG changes.
## Stream derivation is ordered and stable; presentation never gets a stream.
const NAMES := ["shops", "rewards", "lanes", "bosses", "effects"]
const MODULUS := 2147483647
var states: Dictionary = {}

static func create(seed_value: int) -> RefCounted:
	var result = load("res://src/procedural/random_streams.gd").new()
	for stream in NAMES:
		var value := 1
		for byte in (str(seed_value) + ":" + stream).to_utf8_buffer():
			value = (value * 48271 + int(byte)) % MODULUS
		result.states[stream] = maxi(value, 1)
	return result

func draw(stream: String, bound: int) -> int:
	if not states.has(stream) or bound <= 0 or bound >= MODULUS:
		return -1 # release-safe refusal, without consuming randomness
	# Rejection sampling avoids modulo bias.
	var limit := MODULUS - 1 - (MODULUS - 1) % bound
	while true:
		states[stream] = (int(states[stream]) * 48271) % MODULUS
		var sample := int(states[stream]) - 1
		if sample < limit:
			return sample % bound
	return 0

func to_dict() -> Dictionary:
	return {"version": 2, "states": states.duplicate()}

static func restore(data: Dictionary) -> RefCounted:
	if data.get("version") != 2 or not data.get("states") is Dictionary:
		return null
	var result = load("res://src/procedural/random_streams.gd").new()
	for stream in NAMES:
		var value = data.states.get(stream, 0)
		if not (value is int or value is float) or not is_finite(float(value)) or value < 1 or value >= MODULUS or value != int(value):
			return null
		result.states[stream] = int(value)
	return result
