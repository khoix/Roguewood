extends RefCounted
## The Career record kept apart from attempt saves (E10, design §16; E15 extends it
## with the unlock graph, milestones and records). Schema 1:
##   {first_clears: {rival_id: {attempt}}, unlocked: [gate ids], intros_seen: {rival_id: true}}
## Awards are idempotent: recording a first clear twice changes nothing, so a reload
## can never duplicate a reward, and the profile is written before the attempt
## records the victory, so a crash can never lose one.
const SCHEMA_VERSION := 1

static func fresh() -> Dictionary:
	return {"first_clears": {}, "unlocked": [], "intros_seen": {}}

## Fills missing keys (and drops unknown ones) so older in-memory records fit.
static func normalized(data: Dictionary) -> Dictionary:
	var out := fresh()
	for key in out:
		if data.has(key) and typeof(data[key]) == typeof(out[key]):
			out[key] = data[key].duplicate(true)
	return out

## Banks a rival's first clear; returns true only the first time.
static func record_first_clear(career: Dictionary, rival: Dictionary, attempt: int) -> bool:
	if career.first_clears.has(rival.id):
		return false
	career.first_clears[rival.id] = {"attempt": attempt}
	for gate in rival.first_clear.unlocks:
		if gate not in career.unlocked:
			career.unlocked.append(gate)
	return true

static func validate(data: Variant) -> Array[String]:
	var errors: Array[String] = []
	if not data is Dictionary:
		errors.append("not a record")
		return errors
	for key in ["first_clears", "unlocked", "intros_seen"]:
		if not data.has(key):
			errors.append("missing " + key)
	return errors
