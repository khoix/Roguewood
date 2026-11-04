extends RefCounted
const Slice = preload("res://tests/slice_test.gd")
const Events = preload("res://src/presentation/ability_events.gd")
const State = preload("res://src/presentation/spare_jar_state.gd")
static func run() -> Array[String]:
	var failures: Array[String] = []
	var catalogue: Dictionary = preload("res://src/rules/content_set.gd").load_set("slice").catalogue
	for reports in [Slice._strike(),Slice._spare([1,2,3]),Slice._open([1,2],[3])]:
		var scored := Slice._score(catalogue,Slice._loadout({6:"pin.tin"},["charm.spare_jar","charm.consolation_prize"]),reports)
		var snapshot := JSON.stringify(scored)
		var state := State.new()
		state.begin(scored.frame)
		var cues: Array = []
		for index in scored.events.size():
			var event: Dictionary = scored.events[index]
			cues.append_array(Events.project(scored.frame,event,scored.facts))
			if event.phase != "after_bank" and state.count != 0: failures.append("jar growth leaked before bank")
			state.reveal(scored.frame,event,index)
			var count: int = state.count
			state.reveal(scored.frame,event,index)
			if state.count != count: failures.append("repeated reveal duplicated jar growth")
		if state.count != (1 if scored.category == "spare" else 0): failures.append("jar growth category")
		if cues.any(func(c): return c.id == "charm.consolation_prize") != (scored.category == "open"): failures.append("ribbon must only cue open income")
		var tin: Array = cues.filter(func(c): return c.id == "pin.tin")
		if tin.size() != 1 or tin[0].phase != ("after_bank" if scored.category == "open" else "fallen"): failures.append("Tin fallen/standing cues must be exclusive")
		if JSON.stringify(scored) != snapshot: failures.append("keepsake projection mutated scored state")
	state_large(failures)
	return failures
static func state_large(failures: Array[String]) -> void:
	var state := State.new()
	state.begin({"charms":[{"item_id":"charm.spare_jar","growth":27}]})
	if state.count != 27: failures.append("jar count must not cap at visual specimen limit")
	state.begin({"charms":[{"item_id":"charm.spare_jar","growth":0}]})
	if state.count != 0: failures.append("new jar must reset snapshot")
