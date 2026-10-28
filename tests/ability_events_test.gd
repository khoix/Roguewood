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
	var growth := Slice._score(catalogue,Slice._loadout({1:"pin.grower"},["charm.patient_investor"]),Slice._strike())
	if _ids(growth).count("pin.grower") != 1 or "charm.patient_investor" in _ids(growth): failures.append("growth only at authoritative deferred event; zero Investor stays silent")
	var gold := Slice._score(catalogue,Slice._loadout({1:"pin.gold",3:"pin.gold"},["charm.gold_rush"]),Slice._strike())
	if _ids(gold).count("pin.gold") != 2 or _ids(gold).count("charm.gold_rush") != 1: failures.append("gold cues only deferred payouts and actual counted bonus")
	var no_gold := Slice._score(catalogue,Slice._loadout({},["charm.gold_rush"]),Slice._strike())
	if "charm.gold_rush" in _ids(no_gold): failures.append("Gold Rush stays silent with no Gold")
	var standing := Slice._score(catalogue,Slice._loadout({8:"pin.anchor"},["charm.standing_order","charm.lone_survivor"]),Slice._open([1,2,3,4,5,6,7,9,10],[]))
	for id in ["pin.anchor","charm.standing_order","charm.lone_survivor"]:
		if _ids(standing).count(id) != 1: failures.append("one standing Anchor projects " + id)
	var cleared := Slice._score(catalogue,Slice._loadout({8:"pin.anchor"},["charm.standing_order","charm.lone_survivor"]),Slice._strike())
	for id in ["pin.anchor","charm.standing_order","charm.lone_survivor"]:
		if id in _ids(cleared): failures.append("standing cue must stay silent when cleared: " + id)
	var conditional := ["charm.finisher","charm.turkey_club","charm.last_chance"]
	var active := Slice._score(catalogue,Slice._loadout({},conditional),Slice._strike(),{"strike_streak":2,"match_frame":2})
	for id in conditional:
		if _ids(active).count(id) != 1: failures.append("active multiplier cue " + id)
	var inactive := Slice._score(catalogue,Slice._loadout({},conditional),Slice._open([1],[]),{"strike_streak":0,"match_frame":1})
	for id in conditional:
		if id in _ids(inactive): failures.append("inactive multiplier cue " + id)
	var bonuses := ["charm.flat_bonus","charm.spare_change","charm.house_favorite"]
	var spare := Slice._score(catalogue,Slice._loadout({},bonuses),Slice._spare([1,2,3]))
	for id in bonuses:
		if _ids(spare).count(id) != 1: failures.append("actual flat bonus " + id)
	var other_ball := Slice._score(catalogue,Slice._loadout({},bonuses),Slice._strike("ball.hammer"))
	if "charm.spare_change" in _ids(other_ball) or "charm.house_favorite" in _ids(other_ball): failures.append("spare/House cues are conditional")
	var curved := Slice._score(catalogue,Slice._loadout({4:"pin.ruby",7:"pin.rubber"},["charm.hook_artist"]),Slice._strike("ball.hook",0.25))
	for id in ["pin.wood","pin.ruby","pin.rubber","charm.hook_artist"]:
		if id not in _ids(curved): failures.append("real fallen/curved event projects " + id)
	var straight := Slice._score(catalogue,Slice._loadout({},["charm.hook_artist"]),Slice._strike("ball.hook",0.0))
	if "charm.hook_artist" in _ids(straight): failures.append("straight Hook throw does not invent Hook Artist activation")
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
