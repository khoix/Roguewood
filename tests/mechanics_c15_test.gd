extends RefCounted
## E18-C15 (DC-N1, E17-D12 with Bumper Guard from E17-D04): the first six Neon items.
## - Oilskin Ball: holds its hook on any oil (physics; the roll is physics_test's).
## - Laser Ball: +3 Mult per accurate roll, thrown with it; hooks a quarter as far.
## - Tempo Pin: +20 Value per accurate roll when it falls.
## - Neon Sign: +4 Mult per accurate roll in a curved frame.
## - Blacklight: ×1.5 Mult on a curved strike thrown with its card.
## - Bumper Guard: one gutter rebound a frame; a rescued roll loses 2 Mult, never below 1.
const ContentSet = preload("res://src/rules/content_set.gd")
const Builder = preload("res://src/rules/frame_builder.gd")
const Rules = preload("res://src/rules/frame_rules.gd")
const ItemPhysics = preload("res://src/simulation/item_physics.gd")
const ScoreLog = preload("res://src/rules/score_log.gd")
const Authored = preload("res://src/content/authored_batches.gd")
const SliceTest = preload("res://tests/slice_test.gd")
const IDS := ["ball.oilskin", "ball.laser", "pin.tempo", "charm.neon_sign", "ball_mod.blacklight", "ball_mod.bumper_guard"]
const ALL := [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
const CURVE := 0.6

static func run() -> Array[String]:
	var failures: Array[String] = []
	var catalogue: Dictionary = ContentSet.load_set("slice").catalogue
	var items := {}
	for item in catalogue.items:
		items[item.id] = item
	_expect(IDS.all(func(id): return items.has(id) and items[id].completeness.mechanics and not items[id].completeness.artwork and not items[id].completeness.effects_audio),
		"the six items are in the catalogue with mechanics; their art flags wait for Codex", failures)
	# The five rewards are initial until E22-L02 registers their gates and assigns them.
	_expect(IDS.all(func(id): return items[id].unlock.kind == "initial"), "the Neon rewards land as initial items (E22-L02 assigns their gates)", failures)
	_physics(items, failures)
	_laser_and_tempo(catalogue, failures)
	_neon_sign(catalogue, failures)
	_blacklight(catalogue, failures)
	_bumper_guard(catalogue, failures)
	return failures

static func _expect(condition: bool, label: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("mechanics_c15: " + label)

## A report with a grade and, optionally, a rebound.
static func _rep(roll: int, fallen: Array, racked: Array, ball: String = "ball.house", spin: float = 0.0, accuracy: String = "clean", rebounded: bool = false) -> Dictionary:
	var r: Dictionary = SliceTest._rep(roll, fallen, racked, ball, spin)
	r.roll_result.accuracy = accuracy
	if rebounded:
		r.knockdown_log["rebounded"] = true
	return r

static func _resolve(catalogue: Dictionary, reports: Array, loadout: Dictionary = SliceTest._loadout(), extras: Dictionary = {}) -> Dictionary:
	var built := Builder.build(loadout, catalogue, reports, extras, {})
	if not built.ok:
		return {"ok": false, "score": -1, "mult": -1.0, "pin_value": -1.0, "errors": built.errors}
	var result := Rules.resolve(built.frame)
	if result.ok:
		var names := {}
		for entry in catalogue.items:
			names[entry.id] = entry.name
		result["lines"] = ScoreLog.steps(result, built.frame, names, built.owners).map(func(s): return s.text)
	return result

static func _physics(items: Dictionary, failures: Array[String]) -> void:
	_expect(ItemPhysics.roll_rules(items["ball.oilskin"]) == {"oil_hold": true} and ItemPhysics.ball(items["ball.oilskin"]).spin_response == 1.3,
		"Oilskin Ball: holds its hook on any oil and hooks 1.3 times the House Ball", failures)
	_expect(ItemPhysics.ball(items["ball.laser"]).spin_response == 0.25 and ItemPhysics.roll_rules(items["ball.laser"]).is_empty(), "Laser Ball hooks a quarter as far", failures)
	_expect(ItemPhysics.roll_rules(items["ball.hook"], items["ball_mod.bumper_guard"]) == {"gutter_rebound": true}
		and ItemPhysics.roll_rules(items["ball.hook"], items["ball_mod.bumper_guard"], true).is_empty(), "Bumper Guard gives its card's roll one rebound a frame", failures)
	_expect(ItemPhysics.roll_rules(items["ball.oilskin"], items["ball_mod.bumper_guard"]) == {"oil_hold": true, "gutter_rebound": true}, "an Oilskin card with Bumper Guard has both", failures)
	_expect(ItemPhysics.roll_rules(items["ball.hook"], items["ball_mod.blacklight"]).is_empty(), "Blacklight changes nothing in the roll itself", failures)

static func _laser_and_tempo(catalogue: Dictionary, failures: Array[String]) -> void:
	var base: Dictionary = _resolve(catalogue, [_rep(1, ALL, ALL, "ball.house", 0.0, "sweet")])
	var laser: Dictionary = _resolve(catalogue, [_rep(1, ALL, ALL, "ball.laser", 0.0, "sweet")])
	_expect(base.ok and laser.ok and laser.mult == base.mult + 3.0 and laser.lines.any(func(l): return l.contains("Laser Ball")), "Laser Ball: +3 Mult on a sweet strike (%s vs %s)" % [str(laser.mult), str(base.mult)], failures)
	var clean: Dictionary = _resolve(catalogue, [_rep(1, ALL, ALL, "ball.laser")])
	_expect(clean.ok and clean.mult == _resolve(catalogue, [_rep(1, ALL, ALL)]).mult, "nothing on a clean release", failures)
	var rest := [7, 8, 9, 10]
	var twice: Dictionary = _resolve(catalogue, [_rep(1, [1, 2, 3, 4, 5, 6], ALL, "ball.house", 0.0, "perfect"), _rep(2, rest, rest, "ball.laser", 0.0, "sweet")])
	var twice_base: Dictionary = _resolve(catalogue, [_rep(1, [1, 2, 3, 4, 5, 6], ALL, "ball.house", 0.0, "perfect"), _rep(2, rest, rest, "ball.house", 0.0, "sweet")])
	_expect(twice.ok and twice.mult == twice_base.mult + 6.0, "it counts every accurate roll of the frame: two give +6", failures)
	# Tempo Pin at 1 and at 7.
	var tempo: Dictionary = SliceTest._loadout({1: "pin.tempo", 7: "pin.tempo"})
	var sweet: Dictionary = _resolve(catalogue, [_rep(1, ALL, ALL, "ball.house", 0.0, "sweet")], tempo)
	var plain: Dictionary = _resolve(catalogue, [_rep(1, ALL, ALL, "ball.house", 0.0, "sweet")])
	var wood: float = 10.0 # a Wood Pin's own Value, which a Tempo Pin does not have
	_expect(sweet.ok and sweet.pin_value == plain.pin_value - 2 * wood + 2 * 20.0, "Tempo Pin: +20 Value each on a sweet strike (%s vs %s)" % [str(sweet.pin_value), str(plain.pin_value)], failures)
	var dull: Dictionary = _resolve(catalogue, [_rep(1, ALL, ALL)], tempo)
	_expect(dull.ok and dull.pin_value == _resolve(catalogue, [_rep(1, ALL, ALL)]).pin_value - 2 * wood, "and nothing on a clean release", failures)
	var one_down: Dictionary = _resolve(catalogue, [_rep(1, [1, 2, 3], ALL, "ball.house", 0.0, "perfect"), _rep(2, [], [4, 5, 6, 7, 8, 9, 10])], tempo)
	_expect(one_down.ok and one_down.lines.filter(func(l): return l.contains("Tempo Pin")).size() == 1, "only a fallen Tempo Pin pays", failures)

static func _neon_sign(catalogue: Dictionary, failures: Array[String]) -> void:
	var sign: Dictionary = SliceTest._loadout({}, ["charm.neon_sign"])
	var none: Dictionary = SliceTest._loadout()
	var curved_sweet := [_rep(1, ALL, ALL, "ball.house", CURVE, "sweet")]
	var lit: Dictionary = _resolve(catalogue, curved_sweet, sign)
	_expect(lit.ok and lit.mult == _resolve(catalogue, curved_sweet, none).mult + 4.0 and lit.lines.any(func(l): return l.contains("Neon Sign")), "Neon Sign: +4 Mult for a sweet roll in a curved frame", failures)
	var straight := [_rep(1, ALL, ALL, "ball.house", 0.0, "perfect")]
	_expect(_resolve(catalogue, straight, sign).mult == _resolve(catalogue, straight, none).mult, "nothing in a straight frame, however accurate", failures)
	var sloppy := [_rep(1, ALL, ALL, "ball.house", CURVE)]
	_expect(_resolve(catalogue, sloppy, sign).mult == _resolve(catalogue, sloppy, none).mult, "nothing for a curved frame with no accurate roll", failures)
	var rest := [7, 8, 9, 10]
	var both := [_rep(1, [1, 2, 3, 4, 5, 6], ALL, "ball.house", CURVE, "sweet"), _rep(2, rest, rest, "ball.house", 0.0, "perfect")]
	_expect(_resolve(catalogue, both, sign).mult == _resolve(catalogue, both, none).mult + 8.0, "two accurate rolls, one of them curved: +8", failures)

static func _blacklight(catalogue: Dictionary, failures: Array[String]) -> void:
	var curved := [_rep(1, ALL, ALL, "ball.hook", CURVE)]
	var with: Dictionary = _resolve(catalogue, curved, SliceTest._loadout(), {1: ["ball_mod.blacklight"]})
	var without: Dictionary = _resolve(catalogue, curved)
	_expect(with.ok and with.mult == without.mult * 1.5 and with.lines.any(func(l): return l.contains("Blacklight")), "Blacklight: ×1.5 Mult on a curved strike thrown with its card", failures)
	var straight := [_rep(1, ALL, ALL, "ball.hook")]
	_expect(_resolve(catalogue, straight, SliceTest._loadout(), {1: ["ball_mod.blacklight"]}).mult == _resolve(catalogue, straight).mult, "nothing on a straight strike", failures)
	var rest := [7, 8, 9, 10]
	var spare := [_rep(1, [1, 2, 3, 4, 5, 6], ALL, "ball.hook", CURVE), _rep(2, rest, rest)]
	_expect(_resolve(catalogue, spare, SliceTest._loadout(), {1: ["ball_mod.blacklight"]}).mult == _resolve(catalogue, spare).mult, "nothing on a curved spare", failures)

static func _bumper_guard(catalogue: Dictionary, failures: Array[String]) -> void:
	var guard := {1: ["ball_mod.bumper_guard"]}
	var saved := [_rep(1, ALL, ALL, "ball.hook", 0.0, "clean", true)]
	var rescued: Dictionary = _resolve(catalogue, saved, SliceTest._loadout(), guard)
	var same: Dictionary = _resolve(catalogue, [_rep(1, ALL, ALL, "ball.hook")], SliceTest._loadout(), guard)
	_expect(rescued.ok and same.ok and rescued.mult == same.mult - 2.0 and rescued.lines.any(func(l): return l.contains("Bumper Guard") and l.contains("never below 1")),
		"Bumper Guard: a rescued strike loses 2 Mult, and the explanation says so (%s vs %s)" % [str(rescued.mult), str(same.mult)], failures)
	_expect(not same.lines.any(func(l): return l.contains("Bumper Guard")), "a roll that stays on the lane costs nothing", failures)
	var open_reports := [_rep(1, [1, 2, 3], ALL, "ball.hook", 0.0, "clean", true), _rep(2, [], [4, 5, 6, 7, 8, 9, 10])]
	var open: Dictionary = _resolve(catalogue, open_reports, SliceTest._loadout(), guard)
	_expect(open.ok and open.mult == 1.0, "an open frame's Mult of 1 stays 1", failures)
	var rest := [7, 8, 9, 10]
	var spare: Dictionary = _resolve(catalogue, [_rep(1, [1, 2, 3, 4, 5, 6], ALL, "ball.hook", 0.0, "clean", true), _rep(2, rest, rest)], SliceTest._loadout(), guard)
	_expect(spare.ok and spare.mult == 1.0, "a rescued spare's Mult of 2 falls to 1", failures)
	# The design in the batch and the landed item agree.
	var d04: Dictionary = Authored.load_all().filter(func(b): return b.data.batch == "E17-D04")[0].data
	_expect(d04.landed.any(func(l): return l.id == "ball_mod.bumper_guard" and l.landed_in == "E18-C15" and "physics.gutter_rebound" in l.design.primitives),
		"E17-D04 records Bumper Guard as landed on physics.gutter_rebound", failures)
