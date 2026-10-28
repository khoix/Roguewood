extends RefCounted
const Slice = preload("res://tests/slice_test.gd")
const Glass = preload("res://src/presentation/glass_presentation.gd")
const Inventory = preload("res://src/rules/run_inventory.gd")
static func run() -> Array[String]:
	var failures: Array[String] = []
	var catalogue: Dictionary = preload("res://src/rules/content_set.gd").load_set("slice").catalogue
	var pins := {}
	for position in range(1,11): pins[position] = "pin.glass"
	var result := Slice._score(catalogue, Slice._loadout(pins), Slice._strike("ball.echo"))
	var run = Inventory.create(catalogue, pins.values(), [])
	run.effects_state = 1343995987
	run.apply_frame(result, result.frame)
	var scored := {"frame":result.frame, "result":result}
	var before := JSON.stringify([scored,run.to_dict()])
	var broken: Array = run.transformed.map(func(t): return t.position)
	if broken.is_empty() or broken.size() == 10: failures.append("Glass fixture needs breaks and non-breaks")
	for position in range(1,11):
		# Structured saved rows; text is deliberately absent (never parsed).
		var step := {"phase":"rule", "pin":position}
		var actual := Glass.broken_position(scored,run.rack,step,result.events.size())
		if actual != (position if position in broken else 0): failures.append("only confirmed saved conversion dresses Wood")
		if Glass.broken_position(scored,run.rack,step,0) != 0: failures.append("never transform during pre-bank chance/Value rows")
		step.phase = "after_bank"
		if Glass.broken_position(scored,run.rack,step,result.events.size()) != 0: failures.append("20 percent eligibility is not a confirmed crack")
	if Glass.broken_position(scored,run.rack,{"phase":"rule", "pin":0},result.events.size()) != 0: failures.append("boss-bank row is not a Glass crack")
	if JSON.stringify([scored,run.to_dict()]) != before: failures.append("presentation changed saved mechanics")
	# A restored explanation has the saved rack, not the transient transformed list.
	run.transformed.clear()
	for position in broken:
		if Glass.broken_position(scored,run.rack,{"phase":"rule", "pin":position},result.events.size()) != position:
			failures.append("restored explanation retains the confirmed material change")
	return failures
