extends RefCounted
## Between-match shop (E08, design §10/§15, ADR 005). Five slots: two Charms, one
## ball/pin card, one tactical card and one workshop modification. Each slot picks
## a category, rolls an eligible rarity, then picks an item by pool weight; offers
## that the run cannot use are removed before sampling and weights renormalized.
## Its RNG is a dedicated seeded stream: physics, the deck and animation never
## consume it, and its state saves with the run. Every pick is logged.
const Economy = preload("res://src/rules/economy.gd")
const SCHEMA_VERSION := 1
const SLOTS := [["charm"], ["charm"], ["ball", "pin"], ["consumable"], ["pin_mod", "ball_mod"]]
const SLOT_NAMES := ["Charm", "Charm", "Equipment", "Tactical", "Workshop"]
## Provisional ordinary-shop rarity weights (percent). Legendary is reward-only.
const RARITY_WEIGHTS := {"common": 55, "uncommon": 30, "rare": 12, "epic": 3, "legendary": 0}
const RARITIES := ["common", "uncommon", "rare", "epic", "legendary"]

var offers: Array = [] # {slot, item_id ("" = nothing eligible), price, sold}
var visit := 0
var rerolls := 0 # this visit
var division := 1
var unlocked: Array = [] # unlock prerequisites already met (E15 supplies these)
var selection_log: Array = []
var rng_seed := 0
var _rng := RandomNumberGenerator.new()
var _catalogue: Dictionary = {}

static func create(catalogue: Dictionary, shop_seed: int) -> RefCounted:
	var shop = load("res://src/rules/shop.gd").new()
	shop._catalogue = catalogue
	shop.rng_seed = shop_seed
	shop._rng.seed = shop_seed
	return shop

## Why an item cannot be offered to this run now, or "" when it can.
func ineligibility(item: Dictionary, inventory) -> String:
	if float(item.pool_weight) <= 0.0 or item.rarity == "legendary":
		return "not in the shop pool"
	if item.unlock.kind != "initial" and not item.unlock.prerequisites.all(func(p): return p in unlocked):
		return "locked"
	if int(item.earliest_division) > division:
		return "later Division"
	if inventory.owned_count(item.id) >= inventory.copy_limit(item.id):
		return "owned limit"
	if inventory.slot_kind(item.category) == "mod":
		if inventory.mod_hosts(item.id).is_empty():
			return "nothing to modify"
	elif inventory.incompatible(item.id):
		return "incompatible with owned items"
	return ""

func _pool(categories: Array, inventory, excluded: Array) -> Array:
	var pool: Array = []
	for item in _catalogue.get("items", []):
		if item.category in categories and item.id not in excluded and ineligibility(item, inventory).is_empty():
			pool.append(item)
	return pool

## New visit after a match: fresh offers, reroll price back to the base.
func open_visit(inventory, at_division: int = 1) -> void:
	visit += 1
	rerolls = 0
	division = at_division
	_generate(inventory, [])

func reroll_cost() -> int:
	return Economy.reroll_cost(rerolls)

## Replaces every offer, avoiding the previous items wherever the pool allows.
func reroll(inventory) -> Array[String]:
	var errors: Array[String] = inventory.pay(reroll_cost(), "reroll")
	if not errors.is_empty():
		return errors
	rerolls += 1
	_generate(inventory, offers.map(func(o): return o.item_id))
	return errors

func _generate(inventory, previous: Array) -> void:
	offers = []
	for slot in SLOTS.size():
		var taken: Array = offers.map(func(o): return o.item_id)
		var pick := _pick_slot(slot, inventory, taken + previous)
		if pick.is_empty():
			pick = _pick_slot(slot, inventory, taken) # the pool allows no visible change
		offers.append({"slot": slot, "item_id": pick.get("id", ""), "price": int(pick.get("purchase_price", 0)), "sold": false})
	_guarantee_affordable(inventory)

## Category first, then rarity among those present, then pool weight.
func _pick_slot(slot: int, inventory, excluded: Array) -> Dictionary:
	var categories: Array = []
	for category in SLOTS[slot]:
		if not _pool([category], inventory, excluded).is_empty():
			categories.append(category)
	var entry := {"visit": visit, "reroll": rerolls, "slot": slot, "category": "", "rarity": "", "eligible": 0, "item_id": ""}
	if categories.is_empty():
		selection_log.append(entry)
		return {}
	var category: String = categories[_rng.randi_range(0, categories.size() - 1)]
	var pool := _pool([category], inventory, excluded)
	var rarity := _roll_rarity(pool)
	var choice := _weighted(pool.filter(func(i): return i.rarity == rarity))
	entry.merge({"category": category, "rarity": rarity, "eligible": pool.size(), "item_id": choice.id}, true)
	selection_log.append(entry)
	return choice

## Rarities with nothing eligible are dropped and the rest renormalized.
func _roll_rarity(pool: Array) -> String:
	var present := {}
	for item in pool:
		present[item.rarity] = true
	var total := 0.0
	for rarity in RARITIES:
		if present.has(rarity): total += RARITY_WEIGHTS[rarity]
	if total <= 0.0:
		return pool[0].rarity
	var roll := _rng.randf() * total
	for rarity in RARITIES:
		if not present.has(rarity) or RARITY_WEIGHTS[rarity] <= 0:
			continue
		roll -= RARITY_WEIGHTS[rarity]
		if roll < 0.0:
			return rarity
	for rarity in RARITIES:
		if present.has(rarity) and RARITY_WEIGHTS[rarity] > 0: return rarity
	return pool[0].rarity

func _weighted(pool: Array) -> Dictionary:
	pool.sort_custom(func(a, b): return a.id < b.id)
	var total := 0.0
	for item in pool:
		total += float(item.pool_weight)
	var roll := _rng.randf() * total
	for item in pool:
		roll -= float(item.pool_weight)
		if roll < 0.0:
			return item
	return pool[-1]

## If nothing on offer is affordable but something eligible is, one slot offers it.
func _guarantee_affordable(inventory) -> void:
	if offers.any(func(o): return not o.item_id.is_empty() and o.price <= inventory.money):
		return
	var taken: Array = offers.map(func(o): return o.item_id)
	var candidates: Array = []
	for slot in SLOTS.size():
		var affordable := _pool(SLOTS[slot], inventory, taken).filter(func(i): return int(i.purchase_price) <= inventory.money)
		if not affordable.is_empty():
			candidates.append([slot, affordable])
	if candidates.is_empty():
		return
	var pick: Array = candidates[_rng.randi_range(0, candidates.size() - 1)]
	var choice := _weighted(pick[1])
	offers[pick[0]] = {"slot": pick[0], "item_id": choice.id, "price": int(choice.purchase_price), "sold": false}
	selection_log.append({"visit": visit, "reroll": rerolls, "slot": pick[0], "category": choice.category, "rarity": choice.rarity,
		"eligible": pick[1].size(), "item_id": choice.id, "guarantee": true})

## Everything a purchase would do, without doing it: price, affordability and the
## explicit placements (including replacements that sell what they replace).
func plan(index: int, inventory) -> Dictionary:
	if index < 0 or index >= offers.size():
		return {"ok": false, "reason": "no such offer"}
	var offer: Dictionary = offers[index]
	if offer.item_id.is_empty() or offer.sold:
		return {"ok": false, "reason": "sold" if offer.sold else "nothing on offer"}
	var item: Dictionary = inventory.item(offer.item_id)
	var reason := ineligibility(item, inventory)
	if not reason.is_empty():
		return {"ok": false, "reason": reason}
	if offer.price > inventory.money:
		return {"ok": false, "reason": "insufficient funds"}
	var options: Array = inventory.placements(offer.item_id)
	if options.is_empty():
		return {"ok": false, "reason": "no place for it"}
	return {"ok": true, "price": offer.price, "item_id": offer.item_id, "placements": options}

## Buys an offer into a target chosen from plan().placements. Refused requests
## change nothing; cancelling is simply not calling this.
func buy(index: int, target: String, inventory) -> Array[String]:
	var errors: Array[String] = []
	var p := plan(index, inventory)
	if not p.ok:
		errors.append(p.reason)
		return errors
	if not p.placements.any(func(o): return o.target == target):
		errors.append("not a valid place: " + target)
		return errors
	errors = inventory.pay(p.price, "purchase", p.item_id)
	if not errors.is_empty():
		return errors
	errors = inventory.place(p.item_id, p.price, target)
	if not errors.is_empty(): # cannot happen after plan(); refund so state stays whole
		inventory.credit(p.price, "refund", p.item_id)
		return errors
	offers[index].sold = true
	return errors

## Removal service: pay to take a deck card out of the run.
func remove_card(uid: String, inventory) -> Array[String]:
	var errors: Array[String] = []
	if not inventory.cards.has(uid):
		errors.append("not a deck card: " + uid)
		return errors
	errors = inventory.pay(Economy.REMOVAL_PRICE, "removal", inventory.cards[uid].item_id)
	if errors.is_empty():
		inventory.remove_card(uid)
	return errors

func to_dict() -> Dictionary:
	return {"schema_version": SCHEMA_VERSION, "offers": offers.duplicate(true), "visit": visit, "rerolls": rerolls, "division": division,
		"unlocked": unlocked.duplicate(), "selection_log": selection_log.duplicate(true), "seed": str(rng_seed), "rng_state": str(_rng.state)}

static func from_dict(data: Dictionary, catalogue: Dictionary) -> RefCounted:
	var shop = create(catalogue, int(data.seed))
	shop.offers = data.offers.map(func(o): return {"slot": int(o.slot), "item_id": o.item_id, "price": int(o.price), "sold": bool(o.sold)})
	shop.visit = int(data.visit)
	shop.rerolls = int(data.rerolls)
	shop.division = int(data.division)
	shop.unlocked = data.unlocked.duplicate()
	shop.selection_log = data.selection_log.duplicate(true)
	shop._rng.state = int(data.rng_state)
	return shop
