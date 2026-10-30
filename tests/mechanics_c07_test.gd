extends RefCounted
## E18-C07: the shop-upgrade system and the six House upgrades (E17-D06).
## - Owning: an upgrade is placed as "upgrade:new", owned once, never sold, saved.
## - License offer: one per Division, kept through rerolls and visits (sold or not),
##   redrawn in the next Division; content without upgrades has none.
## - Effects: Punch Card (first reroll free), Pin Caddy (a third reserve slot),
##   Clearance Tag ($1 off every offer, never under $1, at once), Savings Book
##   (interest cap $5), Extra Shelf (a sixth offer), Spotlight Sign (rarer odds).
const Upgrades = preload("res://src/rules/upgrades.gd")
const Inventory = preload("res://src/rules/run_inventory.gd")
const Shop = preload("res://src/rules/shop.gd")
const Economy = preload("res://src/rules/economy.gd")
const ContentSet = preload("res://src/rules/content_set.gd")
const ScoreLog = preload("res://src/rules/score_log.gd")
const IDS := ["shop_upgrade.punch_card", "shop_upgrade.pin_caddy", "shop_upgrade.clearance_tag", "shop_upgrade.savings_book", "shop_upgrade.extra_shelf", "shop_upgrade.spotlight_sign"]

static func run() -> Array[String]:
	var failures: Array[String] = []
	var content: Dictionary = ContentSet.load_set("slice")
	var items := {}
	for item in content.catalogue.items:
		items[item.id] = item
	_expect(IDS.all(func(id): return items.has(id) and items[id].category == "shop_upgrade" and items[id].completeness.mechanics and int(items[id].limits.max_owned) == 1),
		"the six House upgrades are in the catalogue, one of each", failures)
	_expect(IDS.map(func(id): return Upgrades.kind(id)) == ["free_reroll", "reserve_slot", "discount", "interest_cap", "extra_offer", "rarity_shift"], "each upgrade names its effect", failures)
	_expect(ScoreLog.item_text(items["shop_upgrade.savings_book"]) == "Interest cap $3 → $5 · kept" and ScoreLog.item_text(items["consumable.nudge"]).begins_with("Before roll 2"),
		"upgrades and instant tactics describe themselves on cards and offers", failures)
	_owning(content, failures)
	_license(content, failures)
	_effects(content, failures)
	_rarity(content, failures)
	return failures

static func _expect(condition: bool, label: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(label)

static func _run(content: Dictionary, money: int = 100):
	return Inventory.create(content.catalogue, content.kit.pins, content.kit.deck, money)

static func _grant(run, id: String) -> void:
	var errors: Array[String] = run.place(id, 0, "upgrade:new")
	assert(errors.is_empty())

static func _owning(content: Dictionary, failures: Array[String]) -> void:
	var run = _run(content)
	var shop = Shop.create(content.catalogue, 7)
	_expect(run.placements("shop_upgrade.pin_caddy") == [{"target": "upgrade:new", "replaces": "", "sale": 0, "moves_to": ""}], "an upgrade has one place: the run's upgrades", failures)
	run.place("shop_upgrade.pin_caddy", 4, "upgrade:new")
	_expect(run.entry_at("upgrade:1").item_id == "shop_upgrade.pin_caddy" and not run.can_sell("upgrade:1") and run.sell("upgrade:1").size() == 1,
		"an owned upgrade cannot be sold", failures)
	_expect(shop.ineligibility(content.catalogue.items.filter(func(i): return i.id == "shop_upgrade.pin_caddy")[0], run) == "owned limit", "an owned upgrade is never offered again", failures)
	var back = Inventory.from_dict(JSON.parse_string(JSON.stringify(run.to_dict())), content.catalogue)
	_expect(back.upgrades.size() == 1 and back.reserves.size() == 3 and Upgrades.owned(back, "reserve_slot"), "upgrades and the extra reserve slot survive a save", failures)
	var older: Dictionary = _run(content).to_dict()
	_expect(not older.has("upgrades") and Inventory.from_dict(older, content.catalogue).upgrades.is_empty(), "a run without upgrades saves as before", failures)

static func _license(content: Dictionary, failures: Array[String]) -> void:
	var run = _run(content)
	var shop = Shop.create(content.catalogue, 11)
	shop.open_visit(run, 1)
	var license: Dictionary = shop.offers[-1]
	_expect(shop.offers.size() == 6 and license.slot == Shop.LICENSE and license.division == 1 and Upgrades.kind(license.item_id) != ""
		and int(content.catalogue.items.filter(func(i): return i.id == license.item_id)[0].earliest_division) == 1, "the shop adds a Division 1 License offer: %s" % str(license), failures)
	shop.reroll(run)
	_expect(shop.offers[-1].item_id == license.item_id and shop.offers.size() == 6, "a reroll keeps the License offer", failures)
	var errors: Array[String] = shop.buy(5, "upgrade:new", run)
	_expect(errors.is_empty() and run.upgrades.size() == 1 and shop.offers[-1].sold, "the License offer is bought into the run's upgrades", failures)
	shop.reroll(run)
	shop.open_visit(run, 1)
	_expect(shop.offers[-1].item_id == license.item_id and shop.offers[-1].sold, "it stays sold for the rest of the Division", failures)
	shop.open_visit(run, 2)
	_expect(shop.offers[-1].division == 2 and not shop.offers[-1].sold and shop.offers[-1].item_id != license.item_id, "the next Division draws a new License offer", failures)
	var lab: Dictionary = ContentSet.load_set("lab")
	var lab_shop = Shop.create(lab.catalogue, 11)
	lab_shop.open_visit(_run(lab), 1)
	_expect(lab_shop.offers.size() == 5 and not lab_shop.offers.any(func(o): return o.slot == Shop.LICENSE), "content without upgrades has no License offer", failures)
	var saved = Shop.from_dict(JSON.parse_string(JSON.stringify(shop.to_dict())), content.catalogue)
	_expect(saved.offers == shop.offers, "the License offer and its Division survive a save", failures)

static func _effects(content: Dictionary, failures: Array[String]) -> void:
	# Punch Card
	var run = _run(content)
	var shop = Shop.create(content.catalogue, 3)
	shop.open_visit(run, 1)
	_expect(shop.reroll_cost(run) == 2, "without Punch Card the first reroll costs $2", failures)
	_grant(run, "shop_upgrade.punch_card")
	var money: int = run.money
	_expect(shop.reroll_cost(run) == 0 and shop.reroll(run).is_empty() and run.money == money and shop.reroll_cost(run) == 2 and shop.reroll(run).is_empty() and run.money == money - 2
		and shop.reroll_cost(run) == 3, "Punch Card: the first reroll is free, then $2, $3", failures)
	shop.open_visit(run, 1)
	_expect(shop.reroll_cost(run) == 0, "and free again next visit", failures)
	# Pin Caddy
	run = _run(content)
	_grant(run, "shop_upgrade.pin_caddy")
	_expect(run.reserves.size() == 3 and run.placements("pin.ruby").any(func(o): return o.target == "reserve:3") and run.place("pin.ruby", 5, "reserve:3").is_empty()
		and run.entry_at("reserve:3").item_id == "pin.ruby", "Pin Caddy: a third reserve slot that holds a pin", failures)
	# Clearance Tag: prices drop at once, never under $1; sales stay half the price paid.
	run = _run(content)
	shop = Shop.create(content.catalogue, 5)
	shop.open_visit(run, 2)
	var before: Array = shop.offers.map(func(o): return o.price)
	_grant(run, "shop_upgrade.clearance_tag")
	shop.reprice(run)
	_expect(range(shop.offers.size()).all(func(i): return shop.offers[i].item_id.is_empty() or shop.offers[i].price == maxi(1, before[i] - 1)), "Clearance Tag: every offer costs $1 less: %s -> %s" % [str(before), str(shop.offers.map(func(o): return o.price))], failures)
	_expect(Upgrades.price(1, run) == 1 and Upgrades.price(4, run) == 3 and Upgrades.price(4, null) == 4, "never under $1", failures)
	var charm := -1
	for i in shop.offers.size():
		if charm < 0 and run.item(shop.offers[i].item_id).get("category", "") == "charm": charm = i
	if charm >= 0:
		var paid: int = shop.offers[charm].price
		shop.buy(charm, "charm:new", run)
		_expect(run.sale_value("charm:1") == paid / 2 and run.sale_value("charm:1") < paid, "a discounted purchase sells for half what was paid", failures)
	# Savings Book
	run = _run(content, 40)
	var plain: int = _run(content, 40).settle_match(2).interest
	_grant(run, "shop_upgrade.savings_book")
	_expect(plain == 3 and run.settle_match(2).interest == 5 and Upgrades.interest(12, run) == 2, "Savings Book: $40 held pays $5 interest, not $3", failures)
	# Extra Shelf
	run = _run(content)
	shop = Shop.create(content.catalogue, 9)
	shop.open_visit(run, 2)
	_expect(shop.offers.filter(func(o): return o.slot != Shop.LICENSE).size() == 5, "five ordinary offers", failures)
	_grant(run, "shop_upgrade.extra_shelf")
	shop.reroll(run)
	var regular: Array = shop.offers.filter(func(o): return o.slot != Shop.LICENSE)
	_expect(regular.size() == 6 and regular[5].slot == Shop.EXTRA and not regular[5].item_id.is_empty() and shop.offers[-1].slot == Shop.LICENSE,
		"Extra Shelf: a sixth offer from the next stock, before the License", failures)
	var ids: Array = regular.map(func(o): return o.item_id)
	_expect(ids.all(func(id): return ids.count(id) == 1), "the extra offer never repeats another", failures)

static func _rarity(content: Dictionary, failures: Array[String]) -> void:
	var pool: Array = []
	for rarity in ["common", "uncommon", "rare", "epic"]:
		pool.append({"id": "x." + rarity, "rarity": rarity, "pool_weight": 1})
	var run = _run(content)
	var counts := {}
	for spotlight in [false, true]:
		if spotlight: _grant(run, "shop_upgrade.spotlight_sign")
		var shop = Shop.create(content.catalogue, 21)
		var tally := {}
		for i in 4000:
			var r: String = shop._roll_rarity(pool, Upgrades.rarity_weights(Shop.RARITY_WEIGHTS, run))
			tally[r] = int(tally.get(r, 0)) + 1
		counts[spotlight] = tally
	_expect(counts[true].rare > counts[false].rare * 1.3 and counts[true].common < counts[false].common and absf(counts[true].rare / 4000.0 - 0.18) < 0.03,
		"Spotlight Sign: rare offers about 18%% instead of 12%% (%s vs %s)" % [str(counts[true]), str(counts[false])], failures)
