extends RefCounted
## E08 economy: payout/interest/sale rules, the run inventory (slots, limits,
## replacement, modifications, removal), the seeded shop (eligibility, rarity,
## rerolls, affordability), currency scopes, saves and a no-negative/no-loop fuzz.
const Economy = preload("res://src/rules/economy.gd")
const Inventory = preload("res://src/rules/run_inventory.gd")
const Shop = preload("res://src/rules/shop.gd")
const Deck = preload("res://src/rules/card_deck.gd")
const Builder = preload("res://src/rules/frame_builder.gd")
const Rules = preload("res://src/rules/frame_rules.gd")
const ScoreLog = preload("res://src/rules/score_log.gd")
const Contracts = preload("res://src/contracts/contracts.gd")
const ScoringTest = preload("res://tests/scoring_test.gd")
const STARTER := ["ball.lab_value", "ball.lab_value", "ball.lab_mult", "ball.lab_mult", "ball.lab_coin", "ball.lab_coin", "consumable.lab_focus"]

static func catalogue() -> Dictionary:
	return Contracts.read_json(Builder.LAB_CATALOGUE)

static func fresh(cat: Dictionary, money: int = Economy.STARTING_MONEY):
	var wood: Array = []
	wood.resize(10)
	wood.fill("pin.wood")
	return Inventory.create(cat, wood, STARTER, money)

static func run() -> Array[String]:
	var failures: Array[String] = []
	var cat := catalogue()
	_expect(Contracts.validate("catalogue", cat).is_empty(), "lab catalogue with E08 fixtures validates", failures)
	_rules(cat, failures)
	_inventory(cat, failures)
	_shop(cat, failures)
	_scoring(cat, failures)
	_saves(cat, failures)
	_fuzz(cat, failures)
	return failures

static func _rules(cat: Dictionary, failures: Array[String]) -> void:
	var table := {0: 0, 4: 0, 5: 1, 14: 2, 15: 3, 99: 3, -3: 0}
	_expect(table.keys().all(func(b): return Economy.interest(b) == table[b]), "interest is $1 per $5 held, capped at $3", failures)
	_expect(Economy.match_payout(2) == 3 and Economy.match_payout(1) == 4 and Economy.match_payout(0) == 5, "payout $3 plus $1 per unused frame", failures)
	_expect(Economy.reroll_cost(0) == 2 and Economy.reroll_cost(1) == 3 and Economy.reroll_cost(4) == 6, "rerolls start at $2 and rise by $1", failures)
	_expect(Economy.sale_value(5, 2) == 2 and Economy.sale_value(4, 2) == 2 and Economy.sale_value(0, 1) == 1 and Economy.sale_value(1, 0) == 0,
		"sale is half the paid price rounded down; free items use the base sale value", failures)
	# No buy/sell loop for any offerable item: buying and selling at once always loses or breaks even.
	for item in cat.items:
		if float(item.pool_weight) > 0.0:
			var price := int(item.purchase_price)
			_expect(Economy.sale_value(price, int(item.resale_price)) < price or price == 0, "no buy/sell profit: " + item.id, failures)

static func _inventory(cat: Dictionary, failures: Array[String]) -> void:
	var inv = fresh(cat)
	_expect(inv.money == 6 and inv.cards.size() == 7 and inv.charms.is_empty() and inv.reserves == [null, null], "starting kit: $6, ten Wood pins, seven cards", failures)
	_expect(not inv.can_sell("rack:1") and not inv.sell("rack:1").is_empty() and inv.money == 6, "rack pins cannot be sold empty", failures)
	_expect(inv.owned_count("ball.lab_value") == 2 and inv.copy_limit("ball.lab_value") == 2 and inv.copy_limit("pin.wood") == 12, "copy limits per identity", failures)
	_expect(inv.sell("card:card-1").is_empty() and inv.money == 8 and not inv.cards.has("card-1"), "a free starter card sells for its base value", failures)
	# Pins: a free reserve takes the displaced pin; full reserves turn placement into a sale.
	var options: Array = inv.placements("pin.lab_gold")
	_expect(options.size() == 12 and options[0].moves_to == "reserve:1" and options[0].replaces.is_empty(), "a new pin can displace a rack pin into a free reserve", failures)
	_expect(inv.pay(4, "purchase", "pin.lab_gold").is_empty() and inv.place("pin.lab_gold", 4, "rack:1").is_empty(), "place a pin", failures)
	_expect(inv.rack[1].item_id == "pin.lab_gold" and inv.reserves[0].item_id == "pin.wood", "displaced Wood waits in reserve", failures)
	inv.reserves[1] = Inventory._entry("pin.wood", 0)
	var full: Array = inv.placements("pin.lab_gold")
	_expect(full.all(func(o): return not o.replaces.is_empty() and o.sale >= 0), "with reserves full every pin placement is an explicit replacement", failures)
	var before: int = inv.money
	inv.place("pin.lab_gold", 4, "rack:2")
	_expect(inv.money == before + 1 and inv.rack[2].item_id == "pin.lab_gold", "replacing a Wood pin sells it for $1", failures)
	_expect(inv.swap_pins("rack:1", "reserve:1").is_empty() and inv.rack[1].item_id == "pin.wood" and inv.reserves[0].item_id == "pin.lab_gold", "rack editing swaps rack and reserve", failures)
	inv.reserves[1] = null
	_expect(not inv.swap_pins("rack:3", "reserve:2").is_empty(), "a rack position cannot be emptied", failures)
	# Charms: five ordered slots, then explicit replacement.
	for id in ["charm.lab_tally", "charm.lab_purse", "charm.lab_crown", "charm.lab_double", "charm.lab_tally"]:
		inv.place(id, 4, "charm:new")
	_expect(inv.charms.size() == 5 and inv.placements("charm.lab_miser").size() == 5 and inv.placements("charm.lab_miser").all(func(o): return o.replaces.begins_with("charm:")),
		"full Charm slots offer only replacements", failures)
	_expect(not inv.place("charm.lab_miser", 6, "charm:new").is_empty() and inv.charms.size() == 5, "no sixth Charm", failures)
	_expect(inv.incompatible("charm.lab_miser") and not inv.incompatible("charm.lab_double"), "incompatibility is checked both ways", failures)
	# Deck cap and copy limits.
	var deck = fresh(cat)
	while deck.cards.size() < Inventory.DECK_CAP:
		deck._add_card("consumable.lab_spark", 3)
	_expect(deck.placements("ball.lab_mult").all(func(o): return o.target != "card:new" and o.replaces.begins_with("card:")), "a full 16-card deck needs a replacement", failures)
	_expect(deck.remove_card("card-1").is_empty() and deck.cards.size() == 15 and deck.placements("ball.lab_mult")[0].target == "card:new", "removal frees a deck slot", failures)
	# Modifications: one per host, compatible hosts only, and sold with the host.
	var mods = fresh(cat)
	_expect(mods.mod_hosts("ball_mod.lab_wax").size() == 6 and mods.mod_hosts("pin_mod.lab_oak").size() == 10, "mods fit balls and pins of the right kind", failures)
	mods.place("ball_mod.lab_wax", 4, "card:card-3")
	_expect(mods.card_mod("card-3") == "ball_mod.lab_wax" and "card:card-3" not in mods.mod_hosts("ball_mod.lab_wax"), "one modification per item", failures)
	_expect(mods.sale_value("card:card-3") == 2 + 2, "a modded card sells with its modification", failures)
	mods.place("pin.lab_gold", 4, "rack:5")
	_expect("rack:5" not in mods.mod_hosts("pin_mod.lab_gilded") and "rack:4" in mods.mod_hosts("pin_mod.lab_gilded"), "incompatible hosts are excluded", failures)
	_expect(not mods.incompatible("pin.lab_gold") and mods.mod_hosts("pin_mod.lab_gilded").size() == 10, "mod incompatibility is per host, not global", failures)

static func _shop(cat: Dictionary, failures: Array[String]) -> void:
	var inv = fresh(cat)
	var shop = Shop.create(cat, 99)
	shop.open_visit(inv)
	_expect(shop.offers.size() == 5 and shop.offers.all(func(o): return not o.item_id.is_empty()), "five offers", failures)
	for i in 5:
		var category: String = inv.item(shop.offers[i].item_id).category
		_expect(category in Shop.SLOTS[i], "slot %d offers %s" % [i, category], failures)
	var ids: Array = shop.offers.map(func(o): return o.item_id)
	_expect(ids.size() == _unique(ids).size(), "no duplicate offers", failures)
	var twin = Shop.create(cat, 99)
	twin.open_visit(fresh(cat))
	_expect(twin.offers == shop.offers, "same seed, same shop", failures)
	# Eligibility across many visits.
	var seen := {}
	var probe = Shop.create(cat, 5)
	for v in 300:
		probe.open_visit(fresh(cat))
		for o in probe.offers:
			seen[o.item_id] = true
	_expect(not seen.has("charm.lab_crown") and not seen.has("ball.house"), "legendary and zero-weight items never appear", failures)
	_expect(not seen.has("charm.lab_double"), "items from a later Division stay out", failures)
	_expect(not seen.has("pin.lab_lead"), "locked items stay out", failures)
	_expect(seen.has("charm.lab_tally") and seen.has("pin_mod.lab_oak") and seen.has("ball_mod.lab_wax"), "eligible items appear", failures)
	var later = Shop.create(cat, 5)
	later.unlocked = ["gate.lab_rival"]
	var late_seen := {}
	for v in 300:
		later.open_visit(fresh(cat), 2)
		for o in later.offers:
			late_seen[o.item_id] = true
	_expect(late_seen.has("charm.lab_double") and late_seen.has("pin.lab_lead"), "Division 2 and unlocked items join the pool", failures)
	var owner = fresh(cat)
	owner.place("charm.lab_purse", 5, "charm:new")
	var check = Shop.create(cat, 1)
	_expect(check.ineligibility(owner.item("charm.lab_purse"), owner) == "owned limit" and check.ineligibility(owner.item("charm.lab_miser"), owner) == "incompatible with owned items",
		"owned limits and incompatibilities exclude offers", failures)
	_expect(check.ineligibility(owner.item("ball.lab_value"), owner) == "owned limit", "two copies of a card identity is the limit", failures)
	# Rarity: renormalized over eligible rarities (slot 0 has common Tally, uncommon Purse/Miser; rare Double from Division 2).
	_expect(_share(cat, 1, "rare") == 0.0 and absf(_share(cat, 1, "common") - 55.0 / 85.0) < 0.05, "Division 1 Charm rarity renormalizes to common 65%", failures)
	_expect(absf(_share(cat, 2, "rare") - 12.0 / 97.0) < 0.04, "Division 2 Charm rarity gives rare about 12%", failures)
	# Rerolls: escalating, visible, refused when unaffordable.
	var money_before: int = inv.money
	var previous: Array = shop.offers.map(func(o): return o.item_id)
	_expect(shop.reroll_cost() == 2 and shop.reroll(inv).is_empty() and inv.money == money_before - 2 and shop.reroll_cost() == 3, "reroll costs $2, then $3", failures)
	# The lab pool has an unseen alternative for the first Charm, equipment, tactical
	# and workshop slots, so those must all show something new on every reroll.
	var repeats := 0
	for seed_value in range(1, 21):
		var r_inv = fresh(cat, 50)
		var r_shop = Shop.create(cat, seed_value)
		r_shop.open_visit(r_inv)
		var before_ids: Array = r_shop.offers.map(func(o): return o.item_id)
		r_shop.reroll(r_inv)
		for i in [0, 2, 3, 4]:
			if r_shop.offers[i].item_id in before_ids: repeats += 1
	_expect(repeats == 0, "a reroll visibly replaces offers where the pool allows (%d repeats)" % repeats, failures)
	var broke = fresh(cat, 2)
	var poor = Shop.create(cat, 3)
	poor.open_visit(broke)
	poor.rerolls = 1
	var offers_before: Array = poor.offers.duplicate(true)
	_expect(not poor.reroll(broke).is_empty() and broke.money == 2 and poor.offers == offers_before and poor.rerolls == 1, "unaffordable reroll changes nothing", failures)
	poor.open_visit(broke)
	_expect(poor.reroll_cost() == 2, "reroll price resets each visit", failures)
	# Buying: refusal, purchase, sold, replacement and cancel.
	var buyer = fresh(cat, 3)
	var store = Shop.create(cat, 8)
	store.open_visit(buyer)
	var pricey := -1
	for i in 5:
		if store.offers[i].price > buyer.money: pricey = i
	if pricey >= 0:
		var snapshot: Dictionary = buyer.to_dict()
		_expect(store.plan(pricey, buyer).reason == "insufficient funds" and not store.buy(pricey, "charm:new", buyer).is_empty() and buyer.to_dict() == snapshot, "insufficient funds refuses without change", failures)
	# With both tactical cards at their copy limit (no $3 tactical offer), $3 still
	# buys Wood or Oak, so every shop must show one of them.
	var unaffordable := 0
	for seed_value in range(1, 41):
		var cheap = fresh(cat, 3)
		for id in ["consumable.lab_focus", "consumable.lab_spark", "consumable.lab_spark"]:
			cheap._add_card(id, 0)
		var g = Shop.create(cat, seed_value)
		g.open_visit(cheap)
		if not g.offers.any(func(o): return not o.item_id.is_empty() and o.price <= 3): unaffordable += 1
	_expect(unaffordable == 0, "an affordable offer is guaranteed when one exists (%d shops without)" % unaffordable, failures)
	var rich = fresh(cat, 40)
	var mall = Shop.create(cat, 8)
	mall.open_visit(rich)
	var charm_plan: Dictionary = mall.plan(0, rich)
	_expect(charm_plan.ok and charm_plan.placements[0].target == "charm:new", "a free Charm slot", failures)
	var price: int = mall.offers[0].price
	_expect(mall.buy(0, "charm:new", rich).is_empty() and rich.money == 40 - price and rich.charms.size() == 1 and mall.offers[0].sold, "buy a Charm", failures)
	_expect(not mall.buy(0, "charm:new", rich).is_empty() and rich.money == 40 - price, "a sold offer cannot be bought again", failures)
	for id in ["charm.lab_crown", "charm.lab_crown", "charm.lab_crown", "charm.lab_crown"]:
		rich.charms.append(Inventory._entry(id, 6))
	var other := 1 if mall.ineligibility(rich.item(mall.offers[1].item_id), rich).is_empty() else -1
	if other > 0:
		var snap: Dictionary = rich.to_dict()
		var full_plan: Dictionary = mall.plan(other, rich)
		_expect(full_plan.ok and full_plan.placements.size() == 5 and rich.to_dict() == snap, "a full slot plans replacements; planning (and cancel) changes nothing", failures)
		_expect(not mall.buy(other, "charm:new", rich).is_empty() and rich.to_dict() == snap, "no silent sixth Charm", failures)
		var sale: int = rich.sale_value("charm:3")
		var cost: int = mall.offers[other].price
		var m: int = rich.money
		_expect(mall.buy(other, "charm:3", rich).is_empty() and rich.money == m - cost + sale and rich.charms[2].item_id == mall.offers[other].item_id, "replacement sells the replaced Charm", failures)
	# Removal service.
	var remover = fresh(cat, 3)
	var service = Shop.create(cat, 1)
	_expect(service.remove_card("card-2", remover).is_empty() and remover.money == 0 and not remover.cards.has("card-2"), "removal costs $3", failures)
	_expect(not service.remove_card("card-3", remover).is_empty() and remover.cards.has("card-3"), "removal needs $3", failures)
	# A modification offer always has a host, and its purchase targets one.
	var workshop = fresh(cat, 30)
	var w = Shop.create(cat, 4)
	w.open_visit(workshop)
	var mod_plan: Dictionary = w.plan(4, workshop)
	_expect(mod_plan.ok and not mod_plan.placements.is_empty() and mod_plan.placements.all(func(o): return o.target.begins_with("rack:") or o.target.begins_with("card:")), "workshop offers target hosts", failures)

## Share of slot-0 offers at a rarity over many fresh visits.
static func _share(cat: Dictionary, division: int, rarity: String) -> float:
	var shop = Shop.create(cat, 17 + division)
	for v in 2000:
		shop.open_visit(fresh(cat, 0), division)
	var picks: Array = shop.selection_log.filter(func(e): return e.slot == 0 and not e.has("guarantee"))
	return float(picks.filter(func(e): return e.rarity == rarity).size()) / maxf(picks.size(), 1)

static func _scoring(cat: Dictionary, failures: Array[String]) -> void:
	var inv = fresh(cat, 50)
	inv.place("charm.lab_tally", 4, "charm:new")
	inv.place("pin_mod.lab_oak", 3, "rack:3")
	inv.place("pin.lab_gold", 4, "rack:1")
	var all := range(1, 11)
	var strike: Dictionary = ScoringTest.report(1, all, all)
	var built := Builder.build(inv.loadout(), cat, [strike], {1: ["ball_mod.lab_wax"]})
	var result := Rules.resolve(built.frame) if built.ok else {}
	_expect(built.ok and result.score == (40 + 90 + 10) * (4 + 1 + 2), "Charms, pin and ball modifications score", failures)
	var names := {}
	for item in cat.items:
		names[item.id] = item.name
	var texts: Array = ScoreLog.steps(result, built.frame, names, built.owners).map(func(s): return s.text)
	for text in ["Pin 3 Lab Oak +10 Value", "Pin 3 Wood +10 Value", "Roll 1 Lab Wax +1 Mult", "Charm 1 Lab Tally +2 Mult", "After bank: Pin 1 Lab Gold +$1 (frame)"]:
		_expect(text in texts, "log names " + text, failures)
	_expect(not Builder.build({"pins": inv.loadout().pins, "charms": [], "pin_mods": {1: "charm.lab_tally"}}, cat, [strike]).ok, "only pin modifications attach to pins", failures)
	# Currency: payouts credit once each, never retriggered, into the run wallet.
	var frame: Dictionary = built.frame.duplicate(true)
	frame.pins[0].retriggers = 3
	var retriggered := Rules.resolve(frame)
	var before: int = inv.money
	_expect(inv.credit_frame(retriggered, frame) == 1 and inv.money == before + 1 and inv.ledger[-1].item_id == "pin.lab_gold", "a retriggered Gold pin pays once", failures)
	var m: int = inv.money
	var summary: Dictionary = inv.settle_match(2)
	_expect(summary.interest == Economy.interest(m) and summary.payout == 3 and inv.money == m + summary.interest + 3 and summary.item_income == 1, "settle: interest on the held balance, then payout", failures)
	_expect(inv.match_number == 2 and inv.stats(1).gross_income == 1 + summary.interest + 3 and inv.stats(2).gross_income == 0, "ledger rows belong to their match", failures)
	var run_stats: Dictionary = inv.stats()
	_expect(run_stats.net == inv.money - 50 and run_stats.savings == inv.money, "run net equals the change in the wallet", failures)
	_expect(fresh(cat).money == Economy.STARTING_MONEY, "a new attempt starts a new wallet", failures)

static func _saves(cat: Dictionary, failures: Array[String]) -> void:
	var inv = fresh(cat, 20)
	var shop = Shop.create(cat, 77)
	shop.open_visit(inv)
	shop.buy(0, "charm:new", inv)
	inv.place("ball_mod.lab_wax", 4, "card:card-2")
	var inv2 = Inventory.from_dict(JSON.parse_string(JSON.stringify(inv.to_dict())), cat)
	var shop2 = Shop.from_dict(JSON.parse_string(JSON.stringify(shop.to_dict())), cat)
	_expect(JSON.stringify(inv2.to_dict()) == JSON.stringify(inv.to_dict()) and inv2.loadout() == inv.loadout(), "inventory JSON round trip", failures)
	shop.reroll(inv)
	shop2.reroll(inv2)
	_expect(shop2.offers == shop.offers and inv2.money == inv.money, "a restored shop rerolls identically", failures)
	# The deck follows the collection between matches and keeps its own RNG stream.
	var deck = Deck.create_with(inv.deck_cards(), 5)
	deck.start_frame()
	inv.sell("card:card-4")
	inv.place("ball.lab_mult", 5, "card:new")
	deck.sync(inv.deck_cards())
	deck.start_match()
	var seen: Array = deck.draw_pile + deck.hand + deck.discard + deck.exhausted
	_expect(seen.size() == inv.cards.size() and "card-4" not in seen and deck.cards.size() == inv.cards.size(), "deck sync adds and removes cards", failures)

## Random shop sessions: the wallet never goes negative and always equals the
## ledger, and no sequence of purchases and sales makes money.
static func _fuzz(cat: Dictionary, failures: Array[String]) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2024
	var bad := 0
	for run in 60:
		var inv = fresh(cat, rng.randi_range(0, 25))
		var shop = Shop.create(cat, run)
		shop.open_visit(inv)
		var earned := 0
		for step in 40:
			var before: int = inv.money
			match rng.randi_range(0, 5):
				0, 1:
					var i := rng.randi_range(0, 4)
					var p: Dictionary = shop.plan(i, inv)
					if p.ok:
						shop.buy(i, p.placements[rng.randi_range(0, p.placements.size() - 1)].target, inv)
				2:
					var sellable: Array = inv.entries().filter(func(e): return inv.can_sell(e.ref))
					if not sellable.is_empty():
						inv.sell(sellable[rng.randi_range(0, sellable.size() - 1)].ref)
				3:
					shop.reroll(inv)
				4:
					if not inv.cards.is_empty():
						shop.remove_card(inv.cards.keys()[0], inv)
				5:
					var income: Dictionary = inv.settle_match(rng.randi_range(1, 2))
					earned += income.interest + income.payout
					shop.open_visit(inv)
			if inv.money < 0:
				bad += 1
		var s: Dictionary = inv.stats()
		var starting: int = int(inv.ledger[0].amount)
		if inv.money != starting + s.net:
			bad += 1
		# Sales can only return part of what was paid (plus the starting kit's base values).
		var kit_value := 0
		for id in STARTER:
			kit_value += int(inv.item(id).resale_price)
		kit_value += 10 * int(inv.item("pin.wood").resale_price)
		if s.sales > kit_value + floori(_paid_total(inv) / 2.0):
			bad += 1
	_expect(bad == 0, "fuzz: no negative balance, ledger matches wallet, no profit from trading (%d violations)" % bad, failures)

static func _paid_total(inv) -> int:
	var total := 0
	for row in inv.ledger:
		if row.kind == "purchase": total += int(row.amount)
	return total

static func _unique(values: Array) -> Dictionary:
	var out := {}
	for v in values:
		out[v] = true
	return out

static func _expect(condition: bool, label: String, failures: Array[String]) -> void:
	if not condition: failures.append(label)
