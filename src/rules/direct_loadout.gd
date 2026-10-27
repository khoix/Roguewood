extends RefCounted
## Comparison model for E07 (ADR 004): the original direct-selection equipment. The
## House ball plus up to two special ball types are always visible, each special
## with USES_PER_MATCH uses per match; tactical items are picked directly and
## exhausted when used (one per roll). No draw, retain or cycle. Same interface as
## the card deck, so the lab can swap models.
const MODEL := "direct"
const SCHEMA_VERSION := 1
const MAX_SPECIALS := 2
const USES_PER_MATCH := 2

var specials: Array = [] # ball item ids
var uses: Dictionary = {} # item_id -> uses left this match
var tacticals: Dictionary = {} # uid -> item_id, not yet used
var exhausted: Array = []
var frame := 0
var tactical_rolls: Array = []

## tactical_uids optionally names each tactical (a run's card uids), so a used one
## can be dropped from the collection.
static func create(ball_ids: Array, tactical_ids: Array, tactical_uids: Array = []) -> RefCounted:
	var loadout = load("res://src/rules/direct_loadout.gd").new()
	loadout.specials = ball_ids.slice(0, MAX_SPECIALS)
	for index in tactical_ids.size():
		var uid: String = tactical_uids[index] if index < tactical_uids.size() else "tactical-%d" % (index + 1)
		loadout.tacticals[uid] = tactical_ids[index]
	loadout.start_match()
	return loadout

func start_match() -> void:
	uses = {}
	for item_id in specials:
		uses[item_id] = USES_PER_MATCH
	frame = 0
	tactical_rolls = []

func start_frame(_retain: String = "") -> Array[String]:
	frame += 1
	tactical_rolls = []
	var none: Array[String] = []
	return none

func options() -> Array:
	var out: Array = []
	for item_id in specials:
		if uses[item_id] > 0:
			out.append({"uid": item_id, "item_id": item_id, "kind": "ball", "uses": uses[item_id]})
	for uid in tacticals:
		out.append({"uid": uid, "item_id": tacticals[uid], "kind": "tactical", "uses": 1})
	return out

func play(uid: String, roll_index: int) -> Array[String]:
	var errors: Array[String] = []
	if uses.get(uid, 0) > 0:
		uses[uid] -= 1
	elif tacticals.has(uid):
		if roll_index in tactical_rolls:
			errors.append("only one tactical card per roll")
		else:
			exhausted.append(uid)
			tacticals.erase(uid)
			tactical_rolls.append(roll_index)
	else:
		errors.append("not available: " + uid)
	return errors

func can_cycle() -> bool:
	return false

func cycle(_uid: String) -> Array[String]:
	var errors: Array[String] = ["direct selection has no cycle"]
	return errors

func can_retain() -> bool:
	return false

func counts() -> Dictionary:
	var left := 0
	for item_id in uses:
		left += uses[item_id]
	return {"special_uses": left, "tactical": tacticals.size(), "exhausted": exhausted.size()}

func to_dict() -> Dictionary:
	return {"schema_version": SCHEMA_VERSION, "model": MODEL, "specials": specials.duplicate(), "uses": uses.duplicate(),
		"tacticals": tacticals.duplicate(), "exhausted": exhausted.duplicate(), "frame": frame, "tactical_rolls": tactical_rolls.duplicate()}

static func from_dict(data: Dictionary) -> RefCounted:
	var loadout = load("res://src/rules/direct_loadout.gd").new()
	loadout.specials = data.specials.duplicate()
	for item_id in data.uses:
		loadout.uses[item_id] = int(data.uses[item_id])
	loadout.tacticals = data.tacticals.duplicate()
	loadout.exhausted = data.exhausted.duplicate()
	loadout.frame = int(data.frame)
	loadout.tactical_rolls = data.tactical_rolls.map(func(r): return int(r))
	return loadout
