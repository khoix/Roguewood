extends RefCounted
## E18-C04: the eight landed D04 modifications through the real run inventory.
## Each is bought, attached to a legal host and scored through FrameBuilder the way
## the lab does it (ball modifications through the thrown card, pin modifications
## through the rack position). Checks one modification per host, the contradictory
## host refusals, payouts credited once, sale value and a save round trip.
const Rules = preload("res://src/rules/frame_rules.gd")
const Builder = preload("res://src/rules/frame_builder.gd")
const Inventory = preload("res://src/rules/run_inventory.gd")
const ContentSet = preload("res://src/rules/content_set.gd")
const SliceTest = preload("res://tests/slice_test.gd")
const BALL_MODS := ["ball_mod.chalk_grip", "ball_mod.spin_wax", "ball_mod.coin_slot", "ball_mod.echo_charge"]
const PIN_MODS := ["pin_mod.brass_cap", "pin_mod.gilt_leaf", "pin_mod.lantern", "pin_mod.keystone"]

static func run() -> Array[String]:
	var failures: Array[String] = []
	var catalogue: Dictionary = ContentSet.load_set("slice").catalogue
	var ids: Array = catalogue.items.map(func(i): return i.id)
	_expect((BALL_MODS + PIN_MODS).all(func(id): return id in ids), "all eight C04 modifications are in the slice catalogue", failures)
	_expect((BALL_MODS + PIN_MODS).all(func(id): return _item(catalogue, id).completeness.mechanics), "each has mechanics", failures)
	_attachment(catalogue, failures)
	_ball_mods(catalogue, failures)
	_pin_mods(catalogue, failures)
	return failures

static func _expect(condition: bool, label: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(label)

static func _item(catalogue: Dictionary, id: String) -> Dictionary:
	for i in catalogue.items:
		if i.id == id:
			return i
	return {}

static func _run(catalogue: Dictionary) -> RefCounted:
	return Inventory.create(catalogue, SliceTest.ALL.map(func(_p): return "pin.wood"), ["ball.hook", "ball.echo"], 50)

static func _card(run: RefCounted, ball: String) -> String:
	for owned in run.entries():
		if owned.ref.begins_with("card:") and owned.entry.item_id == ball:
			return owned.ref
	return ""

## Scores reports thrown with one card (its modification joins every roll) on the run's loadout.
static func _score(run: RefCounted, catalogue: Dictionary, reports: Array, card_ref: String = "") -> Dictionary:
	var extras := {}
	if not card_ref.is_empty():
		var mod: String = run.card_mod(card_ref.trim_prefix("card:"))
		if not mod.is_empty():
			for r in reports:
				extras[int(r.roll_result.roll_index)] = [mod]
	var built := Builder.build(run.loadout(), catalogue, reports, extras)
	var result := Rules.resolve(built.frame) if built.ok else {"ok": false, "score": -1}
	result["frame"] = built.get("frame", {})
	return result

static func _attachment(catalogue: Dictionary, failures: Array[String]) -> void:
	var run := _run(catalogue)
	var hook := _card(run, "ball.hook")
	var echo := _card(run, "ball.echo")
	_expect(hook in run.mod_hosts("ball_mod.echo_charge") and echo not in run.mod_hosts("ball_mod.echo_charge"), "Echo Charge fits Hook Ball but never Echo Ball", failures)
	_expect(not run.mod_hosts("ball_mod.chalk_grip").any(func(r): return r.begins_with("rack:")) and not run.mod_hosts("pin_mod.keystone").any(func(r): return r.begins_with("card:")),
		"ball modifications go on ball cards, pin modifications on rack pins", failures)
	_expect(run.place("pin_mod.keystone", 8, "rack:5").is_empty() and run.loadout().pin_mods.get(5) == "pin_mod.keystone", "Keystone attaches to rack position 5", failures)
	_expect("rack:5" not in run.mod_hosts("pin_mod.brass_cap"), "one modification per host", failures)
	_expect(run.sale_value("rack:5") == 4, "selling the pin returns the modification's sale value too (%d)" % run.sale_value("rack:5"), failures)
	var gold := Inventory.create(catalogue, ["pin.gold"] + range(2, 11).map(func(_p): return "pin.wood"), [], 50)
	_expect("rack:1" not in gold.mod_hosts("pin_mod.gilt_leaf") and "rack:2" in gold.mod_hosts("pin_mod.gilt_leaf"), "Gilt Leaf never gilds a Gold pin", failures)
	run.place("ball_mod.chalk_grip", 4, hook)
	var restored = Inventory.from_dict(JSON.parse_string(JSON.stringify(run.to_dict())), catalogue)
	_expect(restored.loadout().pin_mods.get(5) == "pin_mod.keystone" and restored.card_mod(hook.trim_prefix("card:")) == "ball_mod.chalk_grip", "attachments survive a save round trip", failures)

static func _ball_mods(catalogue: Dictionary, failures: Array[String]) -> void:
	var spare := SliceTest._spare([1, 2, 3, 4, 5, 6, 7])
	var strike := SliceTest._strike()
	var plain := _run(catalogue)
	var mult := func(r: Dictionary, k: float) -> int: return int(r.pin_value * (r.mult + k))
	var chalk := _run(catalogue)
	chalk.place("ball_mod.chalk_grip", 4, _card(chalk, "ball.hook"))
	_expect(_score(chalk, catalogue, spare, _card(chalk, "ball.hook")).score == mult.call(_score(plain, catalogue, spare), 4)
		and _score(chalk, catalogue, spare).score == _score(plain, catalogue, spare).score, "Chalk Grip: +2 Mult per roll thrown with the chalked card in a spare; nothing when another card is thrown", failures)
	var wax := _run(catalogue)
	wax.place("ball_mod.spin_wax", 5, _card(wax, "ball.hook"))
	var curved: Array = SliceTest._strike("ball.house", 0.6)
	_expect(_score(wax, catalogue, curved, _card(wax, "ball.hook")).score == mult.call(_score(plain, catalogue, curved), 4)
		and _score(wax, catalogue, strike, _card(wax, "ball.hook")).score == _score(plain, catalogue, strike).score, "Spin Wax: +4 Mult in a curved frame only", failures)
	var coin := _run(catalogue)
	coin.place("ball_mod.coin_slot", 6, _card(coin, "ball.hook"))
	var paid: Dictionary = _score(coin, catalogue, strike, _card(coin, "ball.hook"))
	var before: int = coin.money
	_expect(paid.score == _score(plain, catalogue, strike).score and coin.credit_frame(paid, paid.frame) == 2 and coin.money == before + 2,
		"Coin Slot: a strike pays $2 once, credited with the frame income; the score is unchanged", failures)
	var echo := _run(catalogue)
	echo.place("ball_mod.echo_charge", 9, _card(echo, "ball.hook"))
	var direct := [SliceTest._rep(1, SliceTest.ALL.duplicate(), SliceTest.ALL)]
	_expect(_score(echo, catalogue, direct, _card(echo, "ball.hook")).retriggers == 1 and _score(plain, catalogue, direct).retriggers == 0, "Echo Charge: the first direct pin retriggers once", failures)

static func _pin_mods(catalogue: Dictionary, failures: Array[String]) -> void:
	var strike := SliceTest._strike()
	var open := SliceTest._open([1, 2, 3], [4])
	var plain := _run(catalogue)
	var with := func(id: String, position: int) -> RefCounted:
		var run := _run(catalogue)
		run.place(id, 5, "rack:%d" % position)
		return run
	var s0: Dictionary = _score(plain, catalogue, strike)
	var o0: Dictionary = _score(plain, catalogue, open)
	_expect(_score(with.call("pin_mod.brass_cap", 5), catalogue, strike).score == int(s0.pin_value * (s0.mult + 1)), "Brass Cap: +1 Mult when its pin falls", failures)
	var gilt: RefCounted = with.call("pin_mod.gilt_leaf", 1)
	var g: Dictionary = _score(gilt, catalogue, open)
	_expect(g.score == o0.score and gilt.credit_frame(g, g.frame) == 1, "Gilt Leaf: $1 when its pin falls; no score", failures)
	_expect(_score(with.call("pin_mod.lantern", 9), catalogue, open).score == int(o0.pin_value * (o0.mult + 6))
		and _score(with.call("pin_mod.lantern", 9), catalogue, strike).score == s0.score, "Lantern: +1 Mult per standing pin while it stands", failures)
	_expect(_score(with.call("pin_mod.keystone", 5), catalogue, strike).score == int((s0.pin_value + 40) * s0.mult)
		and _score(with.call("pin_mod.keystone", 9), catalogue, open).score == o0.score, "Keystone: +4 Value per pin down when it falls; nothing while it stands", failures)
