extends RefCounted
## E18-C11 (DC-H4, E17-D10): House's last five items.
## - Double Take: the throw it is played with repeats its first direct pin once.
## - Called Shot: ×2 Mult when the frame it is played in ends as a strike.
## - Pin Count: +5 Value per pin down in the frame it is played in.
## - Cleanup Crew: +5 Mult on a spare after a first-roll leave of 2+.
## - Lucky Seven: +7 Mult on an open frame with exactly three pins standing.
const ContentSet = preload("res://src/rules/content_set.gd")
const Builder = preload("res://src/rules/frame_builder.gd")
const Rules = preload("res://src/rules/frame_rules.gd")
const Deck = preload("res://src/rules/card_deck.gd")
const Tactics = preload("res://src/rules/tactics.gd")
const ScoreLog = preload("res://src/rules/score_log.gd")
const SliceTest = preload("res://tests/slice_test.gd")
const IDS := ["consumable.double_take", "consumable.called_shot", "consumable.pin_count", "charm.cleanup_crew", "charm.lucky_seven"]

static func run() -> Array[String]:
	var failures: Array[String] = []
	var catalogue: Dictionary = ContentSet.load_set("slice").catalogue
	var items := {}
	for item in catalogue.items:
		items[item.id] = item
	_expect(IDS.all(func(id): return items.has(id) and items[id].completeness.mechanics and items[id].unlock.kind == "initial"),
		"the five D10 items are in the catalogue with mechanics, in the initial pool", failures)
	_expect(IDS.slice(0, 3).all(func(id): return Deck.kind(id) == "tactical" and Tactics.kind(id).is_empty() and items[id].limits.exhaustion == "consume"),
		"the three cards are tactical cards played with a throw (not instant tactics), exhausted on use", failures)
	_expect(catalogue.items.filter(func(i): return i.category == "consumable").size() == 6, "House's six tactical cards", failures)
	_cards(catalogue, failures)
	_charms(catalogue, failures)
	return failures

static func _expect(condition: bool, label: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(label)

## Resolves with `extras` (roll index -> tactical ids), as the lab does for a played card.
static func _played(catalogue: Dictionary, reports: Array, extras: Dictionary, charms: Array = []) -> Dictionary:
	var built := Builder.build(SliceTest._loadout({}, charms), catalogue, reports, extras, {})
	return Rules.resolve(built.frame) if built.ok else {"ok": false, "score": -1, "errors": built.errors}

static func _base(catalogue: Dictionary, reports: Array) -> Dictionary:
	return SliceTest._score(catalogue, SliceTest._loadout(), reports, {})

static func _cards(catalogue: Dictionary, failures: Array[String]) -> void:
	var strike := SliceTest._strike()
	var b := _base(catalogue, strike)
	var first: int = int(strike[0].knockdown_log.knockdowns[0].position) if not strike[0].knockdown_log.knockdowns.is_empty() else 0
	var echo := _played(catalogue, SliceTest._strike(), {1: ["consumable.double_take"]})
	_expect(echo.ok and echo.retriggers == 1 and echo.score == int((b.pin_value + 10) * b.mult), "Double Take: the first direct pin scores once more (+10 Value on a Wood strike; pin %d)" % first, failures)
	var names0 := {}
	for item in catalogue.items:
		names0[item.id] = item.name
	var echo_built := Builder.build(SliceTest._loadout(), catalogue, SliceTest._strike(), {1: ["consumable.double_take"]}, {})
	var echo_lines: Array = ScoreLog.steps(Rules.resolve(echo_built.frame), echo_built.frame, names0, echo_built.owners).map(func(s): return s.text)
	_expect(echo_lines.any(func(l): return l.contains("(retrigger 1 · Roll 1 Double Take)")), "the repeat is credited to Double Take: %s" % str(echo_lines), failures)
	var called := _played(catalogue, SliceTest._strike(), {1: ["consumable.called_shot"]})
	_expect(called.score == int(b.pin_value * b.mult * 2), "Called Shot: ×2 on a strike", failures)
	var missed := _played(catalogue, SliceTest._spare([1, 2, 3]), {1: ["consumable.called_shot"]})
	_expect(missed.score == _base(catalogue, SliceTest._spare([1, 2, 3])).score, "and nothing on a spare", failures)
	var counted := _played(catalogue, SliceTest._open([1, 2, 3], [4, 5]), {2: ["consumable.pin_count"]})
	var o := _base(catalogue, SliceTest._open([1, 2, 3], [4, 5]))
	_expect(counted.score == int((o.pin_value + 25) * o.mult), "Pin Count: five pins down add +25 Value, played on either roll", failures)
	var names := {}
	for item in catalogue.items:
		names[item.id] = item.name
	var built := Builder.build(SliceTest._loadout(), catalogue, SliceTest._strike(), {1: ["consumable.called_shot"]}, {})
	var lines: Array = ScoreLog.steps(Rules.resolve(built.frame), built.frame, names, built.owners).map(func(s): return s.text)
	_expect(lines.any(func(l): return l.contains("Called Shot")), "the explanation names the card: %s" % str(lines), failures)

static func _charms(catalogue: Dictionary, failures: Array[String]) -> void:
	var wide := SliceTest._spare([1, 2, 3, 4, 5, 6, 7, 8])
	var w := _base(catalogue, wide)
	_expect(_played(catalogue, wide, {}, ["charm.cleanup_crew"]).score == int(w.pin_value * (w.mult + 5)), "Cleanup Crew: +5 Mult on a spare after a two-pin leave", failures)
	var single := SliceTest._spare([1, 2, 3, 4, 5, 6, 7, 8, 9])
	_expect(_played(catalogue, single, {}, ["charm.cleanup_crew"]).score == _base(catalogue, single).score, "nothing on a one-pin spare", failures)
	var seven := SliceTest._open([1, 2, 3, 4, 5], [6, 7])
	var s := _base(catalogue, seven)
	_expect(_played(catalogue, seven, {}, ["charm.lucky_seven"]).score == int(s.pin_value * (s.mult + 7)), "Lucky Seven: +7 Mult with exactly seven down", failures)
	var six := SliceTest._open([1, 2, 3, 4, 5], [6])
	_expect(_played(catalogue, six, {}, ["charm.lucky_seven"]).score == _base(catalogue, six).score, "nothing with six down", failures)
