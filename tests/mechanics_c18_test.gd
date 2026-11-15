extends RefCounted
## E18-C18 (DC-N4, E17-D15): Neon's two shop upgrades and the Controlled Curve mastery.
## - condition `accurate`; Career metric `controlled_curves` and mastery.controlled_curve;
## - Comet Ball: +6 Mult on an accurate curved roll, hooks 1.2 times as far;
## - Metronome: ×1.5 Mult on a strike released sweet or perfect;
## - Steady Hand: played with a throw, ×2 Mult on an accurate curved roll;
## - Trade-In: a sale returns $1 more, never more than was paid;
## - Specialist Shelf: one more offer, from the League's specialist items only.
const ContentSet = preload("res://src/rules/content_set.gd")
const ItemPhysics = preload("res://src/simulation/item_physics.gd")
const Rules = preload("res://src/rules/frame_rules.gd")
const Career = preload("res://src/persistence/career_profile.gd")
const Lane = preload("res://src/simulation/lane_spec.gd")
const Upgrades = preload("res://src/rules/upgrades.gd")
const Inventory = preload("res://src/rules/run_inventory.gd")
const Shop = preload("res://src/rules/shop.gd")
const Deck = preload("res://src/rules/card_deck.gd")
const SliceTest = preload("res://tests/slice_test.gd")
const C15 = preload("res://tests/mechanics_c15_test.gd")
const MASTERY := ["ball.comet", "charm.metronome", "consumable.steady_hand"]
const UPGRADES := ["shop_upgrade.trade_in", "shop_upgrade.specialist_shelf"]
const GATE := "gate.mastery_controlled_curve"
const ALL := [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
const REST := [7, 8, 9, 10]
const CURVE := 0.6

static func run() -> Array[String]:
	var failures: Array[String] = []
	var content: Dictionary = ContentSet.load_set("neon")
	var catalogue: Dictionary = content.catalogue
	var items := {}
	for item in catalogue.items:
		items[item.id] = item
	_expect(MASTERY.all(func(id): return items.has(id) and items[id].completeness.mechanics and items[id].unlock.kind == "mastery" and items[id].unlock.prerequisites == [GATE]),
		"the three mastery items wait for the Controlled Curve gate", failures)
	_expect(UPGRADES.all(func(id): return items.has(id) and items[id].unlock.kind == "initial" and items[id].category == "shop_upgrade")
		and UPGRADES.map(func(id): return Upgrades.kind(id)) == ["sell_bonus", "specialist_offer"], "the two upgrades are initial and name their effects", failures)
	_expect(ItemPhysics.ball(items["ball.comet"]).spin_response == 1.2 and Deck.kind("consumable.steady_hand") == "tactical", "Comet Ball hooks 1.2 times as far; Steady Hand is played with a throw", failures)
	_comet(catalogue, failures)
	_metronome(catalogue, failures)
	_steady_hand(catalogue, failures)
	_career(failures)
	_trade_in(content, failures)
	_specialist_shelf(content, failures)
	return failures

static func _expect(condition: bool, label: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("mechanics_c18: " + label)

static func _comet(catalogue: Dictionary, failures: Array[String]) -> void:
	var sweet: Dictionary = C15._resolve(catalogue, [C15._rep(1, ALL, ALL, "ball.comet", CURVE, "sweet")])
	var house: Dictionary = C15._resolve(catalogue, [C15._rep(1, ALL, ALL, "ball.house", CURVE, "sweet")])
	_expect(sweet.ok and sweet.mult == house.mult + 6.0 and sweet.lines.any(func(l): return l.contains("Comet Ball") and l.contains("sweet or perfect")), "Comet Ball: +6 Mult on an accurate curved strike", failures)
	var clean: Dictionary = C15._resolve(catalogue, [C15._rep(1, ALL, ALL, "ball.comet", CURVE, "clean")])
	_expect(clean.mult == C15._resolve(catalogue, [C15._rep(1, ALL, ALL, "ball.house", CURVE, "clean")]).mult, "nothing for a clean release", failures)
	var straight: Dictionary = C15._resolve(catalogue, [C15._rep(1, ALL, ALL, "ball.comet", 0.0, "perfect")])
	_expect(straight.mult == C15._resolve(catalogue, [C15._rep(1, ALL, ALL, "ball.house", 0.0, "perfect")]).mult, "nothing for a straight roll", failures)
	# Its own roll must be the accurate one: roll 1 sweet with the House Ball, roll 2 clean with the Comet.
	var own := [C15._rep(1, [1, 2, 3, 4, 5, 6], ALL, "ball.house", CURVE, "sweet"), C15._rep(2, REST, REST, "ball.comet", 0.0, "clean")]
	var plain := [C15._rep(1, [1, 2, 3, 4, 5, 6], ALL, "ball.house", CURVE, "sweet"), C15._rep(2, REST, REST, "ball.house", 0.0, "clean")]
	_expect(C15._resolve(catalogue, own).mult == C15._resolve(catalogue, plain).mult, "on its own roll, accurate means that roll's release", failures)

static func _metronome(catalogue: Dictionary, failures: Array[String]) -> void:
	var none: Dictionary = SliceTest._loadout()
	var beat: Dictionary = SliceTest._loadout({}, ["charm.metronome"])
	var sweet := [C15._rep(1, ALL, ALL, "ball.house", 0.0, "sweet")]
	_expect(C15._resolve(catalogue, sweet, beat).mult == C15._resolve(catalogue, sweet, none).mult * 1.5, "Metronome: ×1.5 Mult on a sweet strike", failures)
	var clean := [C15._rep(1, ALL, ALL)]
	_expect(C15._resolve(catalogue, clean, beat).mult == C15._resolve(catalogue, clean, none).mult, "nothing for a clean strike", failures)
	var spare := [C15._rep(1, [1, 2, 3, 4, 5, 6], ALL, "ball.house", 0.0, "perfect"), C15._rep(2, REST, REST)]
	_expect(C15._resolve(catalogue, spare, beat).mult == C15._resolve(catalogue, spare, none).mult, "nothing for an accurate spare", failures)

static func _steady_hand(catalogue: Dictionary, failures: Array[String]) -> void:
	var curved := [C15._rep(1, ALL, ALL, "ball.house", CURVE, "perfect")]
	var played: Dictionary = C15._resolve(catalogue, curved, SliceTest._loadout(), {1: ["consumable.steady_hand"]})
	# A roll's own effects come before the accuracy bonus (+2 for perfect), which is added after.
	var base: float = C15._resolve(catalogue, curved).mult
	_expect(played.ok and played.mult == (base - 2.0) * 2.0 + 2.0 and played.lines.any(func(l): return l.contains("Steady Hand")), "Steady Hand: ×2 Mult on an accurate curved roll (%s from %s)" % [played.mult, base], failures)
	var clean := [C15._rep(1, ALL, ALL, "ball.house", CURVE, "clean")]
	_expect(C15._resolve(catalogue, clean, SliceTest._loadout(), {1: ["consumable.steady_hand"]}).mult == C15._resolve(catalogue, clean).mult, "nothing for a clean release", failures)
	var bad := {"schema_version": 2, "pins": [], "rolls": [], "charms": [{"item_id": "charm.x", "effects": [{"op": "add_mult", "amount": 1, "trigger": "charm", "scope": "frame", "condition": {"accurate": "yes"}}]}]}
	_expect(Rules.validate(bad).any(func(e): return e.contains("accurate")), "condition.accurate must be a boolean", failures)

static func _stats(spin: float, accuracy: String, category: String = "strike") -> Dictionary:
	return Career.frame_stats(category, [{"launch": {"spin": spin}, "roll_result": {"fallen_positions": [1, 2, 3], "accuracy": accuracy}}], {}, func(s): return Lane.is_curved(s))

static func _career(failures: Array[String]) -> void:
	_expect(_stats(CURVE, "sweet").controlled_curves == 1 and _stats(CURVE, "perfect").controlled_curves == 1, "a curved strike released sweet or perfect is a controlled curve", failures)
	_expect(_stats(CURVE, "clean").controlled_curves == 0 and _stats(0.0, "perfect").controlled_curves == 0 and _stats(CURVE, "sweet", "spare").controlled_curves == 0,
		"not a clean release, a straight strike or a spare", failures)
	var graph: Dictionary = ContentSet.career_graph(ContentSet.UNLOCKS)
	var objective: Array = graph.objectives.filter(func(o): return o.id == "mastery.controlled_curve")
	_expect(graph.errors.is_empty() and objective.size() == 1 and objective[0].metric == "controlled_curves" and int(objective[0].threshold) == 3 and objective[0].scope == "attempt"
		and graph.items_by_gate.get(GATE, []) == MASTERY, "the Controlled Curve objective unlocks Comet Ball, Metronome and Steady Hand", failures)
	var career := Career.fresh()
	var uid := Career.begin_attempt(career)
	var ctx := {"league": "league.neon", "division": 1, "frame_score": 100, "total": 100}
	for frame in range(1, 3):
		Career.bank_frame(career, uid, frame, _stats(CURVE, "sweet"), ctx, graph.objectives)
	Career.bank_frame(career, uid, 3, _stats(CURVE, "clean"), ctx, graph.objectives)
	_expect(not career.mastery.has("mastery.controlled_curve") and Career.progress(career, objective[0], uid) == 2, "two controlled curves and a clean one: not yet", failures)
	var out: Dictionary = Career.bank_frame(career, uid, 4, _stats(CURVE, "perfect"), ctx, graph.objectives)
	_expect(career.mastery.has("mastery.controlled_curve") and GATE in career.unlocked and GATE in out.gates, "the third completes Controlled Curve and opens its gate", failures)

static func _trade_in(content: Dictionary, failures: Array[String]) -> void:
	var run = Inventory.create(content.catalogue, content.kit.pins, content.kit.deck, 100)
	run.place("charm.laser_level", 4, "charm:new")
	run.place("charm.straight_money", 1, "charm:new") # paid $1 (a Clearance Tag's floor)
	var before: Array = [run.sale_value("charm:1"), run.sale_value("charm:2"), run.sale_value("card:card-1")]
	run.place("shop_upgrade.trade_in", 4, "upgrade:new")
	_expect(run.sale_value("charm:1") == before[0] + 1, "Trade-In: a sale returns $1 more (%d to %d)" % [before[0], run.sale_value("charm:1")], failures)
	_expect(run.sale_value("charm:2") == 1, "never more than was paid ($1 paid, $%d back)" % run.sale_value("charm:2"), failures)
	_expect(run.sale_value("card:card-1") == before[2] + 1, "a kit card takes the $1 on its base sale value", failures)

static func _specialist_shelf(content: Dictionary, failures: Array[String]) -> void:
	var run = Inventory.create(content.catalogue, content.kit.pins, content.kit.deck, 100)
	var shop = Shop.create(content.catalogue, 5)
	shop.specialists = content.specialists
	shop.open_visit(run, 1)
	_expect(not shop.offers.any(func(o): return o.slot == Shop.SPECIALIST), "no Specialist offer without the upgrade", failures)
	run.place("shop_upgrade.specialist_shelf", 6, "upgrade:new")
	for visit in 12:
		shop.open_visit(run, 1)
		var extra: Array = shop.offers.filter(func(o): return o.slot == Shop.SPECIALIST)
		_expect(extra.size() == 1 and not extra[0].item_id.is_empty() and shop.is_specialist(run.item(extra[0].item_id)),
			"visit %d: one Specialist offer, a specialist item (%s)" % [visit, str(extra)], failures)
	var house: Dictionary = ContentSet.load_set("house")
	var house_shop = Shop.create(house.catalogue, 5)
	house_shop.specialists = house.get("specialists", {})
	var shelf: Dictionary = house.catalogue.items.filter(func(i): return i.id == "shop_upgrade.specialist_shelf")[0]
	_expect(house_shop.ineligibility(shelf, Inventory.create(house.catalogue, house.kit.pins, house.kit.deck, 100)) == "no specialists in this League", "never offered in a League without specialists", failures)
