extends RefCounted
const Slice = preload("res://tests/slice_test.gd")
const Events = preload("res://src/presentation/ability_events.gd")
static func run() -> Array[String]:
	var failures: Array[String] = []
	var catalogue: Dictionary = preload("res://src/rules/content_set.gd").load_set("slice").catalogue
	var echo := Slice._score(catalogue,Slice._loadout({1:"pin.ruby"},["charm.encore"]),Slice._strike("ball.echo"))
	var before := JSON.stringify(echo)
	var ids := _ids(echo)
	if ids.count("ball.echo") != 1 or ids.count("charm.encore") != 1:
		failures.append("Echo repeats one direct pin; Encore adds its actual Mult once")
	if JSON.stringify(echo) != before: failures.append("event projection mutated authoritative input")
	var plain := Slice._score(catalogue,Slice._loadout({},["charm.encore"]),Slice._strike())
	if "ball.echo" in _ids(plain) or "charm.encore" in _ids(plain): failures.append("inactive retriggers stay silent")
	if Events.owner(echo.frame,"charm:100") != "": failures.append("invalid source is not guessed")
	return failures
static func _ids(result: Dictionary) -> Array:
	var keys := {}
	var out := []
	for event in result.events:
		for activation in Events.project(result.frame,event):
			if keys.has(activation.key): continue
			keys[activation.key] = true
			out.append(activation.id)
	return out
