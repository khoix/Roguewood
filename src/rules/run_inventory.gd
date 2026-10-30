extends RefCounted
## What a League attempt owns (E08): a run-scoped wallet and ledger, the rack (ten
## positions) and two reserves, five ordered Charm slots, the equipment deck's card
## collection, and modifications attached to pins and ball cards. Pure and
## JSON-serializable for saves (E10). Never Career-scoped: a new attempt starts a
## new inventory.
##
## Every owned thing is an entry {item_id, paid, mod, mod_paid, growth}: paid is the
## price actually paid (0 for the starting kit), so sale values can never exceed it;
## growth is the entry's run-persistent counter (a Grower pin's knockdowns, Patient
## Investor's completed matches; ADR 008). It travels with the entry and is lost
## when the entry is sold. strike_streak counts consecutive strikes across the run.
## Places are refs: "rack:3", "reserve:1", "charm:2", "card:card-4", "upgrade:1".
## E18-C07: shop upgrades are owned for the rest of the attempt and never sold; Pin
## Caddy adds a reserve slot (the reserves array's size is the run's capacity).
const Economy = preload("res://src/rules/economy.gd")
const Upgrades = preload("res://src/rules/upgrades.gd")
const SCHEMA_VERSION := 1
const RACK_SIZE := 10
const RESERVE_SLOTS := 2
const CHARM_SLOTS := 5
const DECK_CAP := 16
const CARD_COPIES := 2 # per reusable card identity, initially (design §15)
## Ledger kinds that count as earned income, and as spending.
const INCOME := ["payout", "interest", "item_income"]
const SPEND := ["purchase", "reroll", "removal"]

var money := 0
var match_number := 1
var rack: Dictionary = {} # position (int) -> entry
var reserves: Array = [] # RESERVE_SLOTS (or more, with Pin Caddy) entries or null
var charms: Array = [] # ordered entries, at most CHARM_SLOTS
var cards: Dictionary = {} # uid -> entry
var upgrades: Array = [] # E18-C07: owned shop upgrades, in purchase order
var next_card := 1
var ledger: Array = [] # {match, kind, amount, item_id}
var strike_streak := 0
var _catalogue: Dictionary = {}
var _items: Dictionary = {}

## E18-C02: the attempt's effects stream (RandomStreams' Lehmer generator), used only
## for after-bank chances such as Glass breaking. Saved with the run, so a reload
## never rerolls; 0 means not seeded (fixtures without chance effects).
const Streams = preload("res://src/procedural/random_streams.gd")
var effects_state := 0
## Pins changed after the last frame banked: [{position, from, into, roll}].
var transformed: Array = []

## Seeds the effects stream from the attempt seed (or a campaign's saved state).
func seed_effects(seed_value: int, state: int = 0) -> void:
	effects_state = state if state > 0 else int(Streams.create(seed_value).states.effects)

func _draw_effect(bound: int) -> int:
	if effects_state <= 0:
		seed_effects(1)
	var streams = Streams.new()
	streams.states = {"effects": effects_state}
	var value: int = streams.draw("effects", bound)
	effects_state = int(streams.states.effects)
	return value

static func create(catalogue: Dictionary, pins: Array, deck: Array, starting_money: int = Economy.STARTING_MONEY) -> RefCounted:
	var inventory = load("res://src/rules/run_inventory.gd").new()
	inventory._index(catalogue)
	for position in range(1, RACK_SIZE + 1):
		inventory.rack[position] = _entry(pins[position - 1], 0)
	inventory.reserves = []
	inventory.reserves.resize(RESERVE_SLOTS)
	for item_id in deck:
		inventory._add_card(item_id, 0)
	inventory.money = starting_money
	inventory.ledger.append({"match": 1, "kind": "start", "amount": starting_money, "item_id": ""})
	return inventory

static func _entry(item_id: String, paid: int) -> Dictionary:
	return {"item_id": item_id, "paid": paid, "mod": "", "mod_paid": 0, "growth": 0}

func _index(catalogue: Dictionary) -> void:
	_catalogue = catalogue
	_items = {}
	for entry in catalogue.get("items", []):
		_items[entry.id] = entry

func item(item_id: String) -> Dictionary:
	return _items.get(item_id, {})

func name_of(item_id: String) -> String:
	return item(item_id).get("name", item_id)

func _add_card(item_id: String, paid: int) -> String:
	var uid := "card-%d" % next_card
	next_card += 1
	cards[uid] = _entry(item_id, paid)
	return uid

# --- Queries ---------------------------------------------------------------

## Every owned entry with its ref, in a stable order.
func entries() -> Array:
	var out: Array = []
	for position in range(1, RACK_SIZE + 1):
		out.append({"ref": "rack:%d" % position, "entry": rack[position]})
	for i in reserves.size():
		if reserves[i] != null:
			out.append({"ref": "reserve:%d" % (i + 1), "entry": reserves[i]})
	for i in charms.size():
		out.append({"ref": "charm:%d" % (i + 1), "entry": charms[i]})
	for i in upgrades.size():
		out.append({"ref": "upgrade:%d" % (i + 1), "entry": upgrades[i]})
	var uids: Array = cards.keys()
	uids.sort_custom(func(a, b): return int(a.trim_prefix("card-")) < int(b.trim_prefix("card-")))
	for uid in uids:
		out.append({"ref": "card:" + uid, "entry": cards[uid]})
	return out

func entry_at(ref: String) -> Variant:
	var parts := ref.split(":")
	match parts[0]:
		"rack": return rack.get(int(parts[1]))
		"reserve":
			var i := int(parts[1]) - 1
			return reserves[i] if i >= 0 and i < reserves.size() else null
		"charm":
			var i := int(parts[1]) - 1
			return charms[i] if i >= 0 and i < charms.size() else null
		"card": return cards.get(parts[1])
		"upgrade":
			var i := int(parts[1]) - 1
			return upgrades[i] if i >= 0 and i < upgrades.size() else null
	return null

## Copies owned, counting attached modifications.
func owned_count(item_id: String) -> int:
	var count := 0
	for owned in entries():
		if owned.entry.item_id == item_id: count += 1
		if owned.entry.mod == item_id: count += 1
	return count

## Where an item goes: deck cards, pins, Charms, or a modification on a host.
static func slot_kind(category: String) -> String:
	match category:
		"ball", "consumable": return "card"
		"pin": return "pin"
		"charm": return "charm"
		"pin_mod", "ball_mod": return "mod"
		"shop_upgrade": return "upgrade"
	return ""

func copy_limit(item_id: String) -> int:
	var limit: int = int(item(item_id).get("limits", {}).get("max_owned", 1))
	return mini(limit, CARD_COPIES) if slot_kind(item(item_id).get("category", "")) == "card" else limit

## True when this item and an owned item exclude each other. Modifications are
## checked against their host instead (mod_hosts), so a Gilded pin elsewhere does
## not stop a Gold pin being bought.
func incompatible(item_id: String) -> bool:
	var listed: Array = item(item_id).get("incompatibilities", [])
	for owned in entries():
		var owned_id: String = owned.entry.item_id
		if owned_id in listed or item_id in item(owned_id).get("incompatibilities", []):
			return true
	return false

## A modification fits a host of the right kind with no modification yet, whose own
## item does not exclude it.
func mod_hosts(mod_id: String) -> Array:
	var category: String = item(mod_id).get("category", "")
	var hosts: Array = []
	for owned in entries():
		var host_category: String = item(owned.entry.item_id).get("category", "")
		var fits: bool = (category == "pin_mod" and host_category == "pin") or (category == "ball_mod" and host_category == "ball")
		if not fits or not owned.entry.mod.is_empty():
			continue
		var host_id: String = owned.entry.item_id
		if host_id in item(mod_id).get("incompatibilities", []) or mod_id in item(host_id).get("incompatibilities", []):
			continue
		hosts.append(owned.ref)
	return hosts

## Ways to take a new item: [{target, replaces (ref or ""), sale, moves_to}]. A full
## slot is offered only as an explicit replacement that sells what it replaces;
## nothing is ever dropped silently.
func placements(item_id: String) -> Array:
	var out: Array = []
	match slot_kind(item(item_id).get("category", "")):
		"card":
			if cards.size() < DECK_CAP:
				out.append({"target": "card:new", "replaces": "", "sale": 0, "moves_to": ""})
			else:
				for owned in entries():
					if owned.ref.begins_with("card:"):
						out.append({"target": owned.ref, "replaces": owned.ref, "sale": sale_value(owned.ref), "moves_to": ""})
		"charm":
			if charms.size() < CHARM_SLOTS:
				out.append({"target": "charm:new", "replaces": "", "sale": 0, "moves_to": ""})
			else:
				for i in charms.size():
					var ref := "charm:%d" % (i + 1)
					out.append({"target": ref, "replaces": ref, "sale": sale_value(ref), "moves_to": ""})
		"pin":
			var free := reserves.find(null)
			for position in range(1, RACK_SIZE + 1):
				var ref := "rack:%d" % position
				if free >= 0:
					out.append({"target": ref, "replaces": "", "sale": 0, "moves_to": "reserve:%d" % (free + 1)})
				else:
					out.append({"target": ref, "replaces": ref, "sale": sale_value(ref), "moves_to": ""})
			for i in reserves.size():
				var ref := "reserve:%d" % (i + 1)
				if reserves[i] == null:
					out.append({"target": ref, "replaces": "", "sale": 0, "moves_to": ""})
				else:
					out.append({"target": ref, "replaces": ref, "sale": sale_value(ref), "moves_to": ""})
		"mod":
			for ref in mod_hosts(item_id):
				out.append({"target": ref, "replaces": "", "sale": 0, "moves_to": ""})
		"upgrade":
			out.append({"target": "upgrade:new", "replaces": "", "sale": 0, "moves_to": ""})
	return out

## Sale value of an owned entry, including its modification. The House ball is
## never owned here, so it can never be sold.
func sale_value(ref: String) -> int:
	var entry = entry_at(ref)
	if entry == null:
		return 0
	var value := Economy.sale_value(int(entry.paid), int(item(entry.item_id).get("resale_price", 0)))
	if not String(entry.mod).is_empty():
		value += Economy.sale_value(int(entry.mod_paid), int(item(entry.mod).get("resale_price", 0)))
	return value

## Rack pins hold the lineup, so they are replaced or swapped, never sold empty.
## Shop upgrades are kept for the attempt.
func can_sell(ref: String) -> bool:
	return entry_at(ref) != null and not ref.begins_with("rack:") and not ref.begins_with("upgrade:")

# --- Money -----------------------------------------------------------------

func _record(kind: String, amount: int, item_id: String = "") -> void:
	ledger.append({"match": match_number, "kind": kind, "amount": amount, "item_id": item_id})

## Spending never takes the balance below zero; the call is refused instead.
func pay(amount: int, kind: String, item_id: String = "") -> Array[String]:
	var errors: Array[String] = []
	if amount < 0:
		errors.append("negative price")
	elif amount > money:
		errors.append("insufficient funds: need $%d, have $%d" % [amount, money])
	if errors.is_empty():
		money -= amount
		_record(kind, amount, item_id)
	return errors

func credit(amount: int, kind: String, item_id: String = "") -> void:
	if amount <= 0:
		return
	money += amount
	_record(kind, amount, item_id)

## Item payouts from one resolved frame. FrameRules defers payouts to after the
## bank and never retriggers them, so each activation pays exactly once.
func credit_frame(result: Dictionary, frame: Dictionary) -> int:
	var total := 0
	var owners := {}
	for pin in frame.pins:
		owners["pin:%d" % int(pin.position)] = pin.item_id
	for roll in frame.rolls:
		owners["roll:%d" % int(roll.roll_index)] = roll.ball_id
	for i in frame.charms.size():
		owners["charm:%d" % (i + 1)] = frame.charms[i].item_id
	for event in result.get("future_effects", []):
		if event.op != "payout":
			continue
		var amount := int(event.amount)
		credit(amount, "item_income", owners.get(event.source, ""))
		total += amount
	return total

## After a frame resolves: growth effects add to their owners' counters (deferred,
## never retriggered) and the run's strike streak follows the frame. Returns the
## growth applied as [{ref, item_id, amount}].
func apply_frame(result: Dictionary, frame: Dictionary) -> Array:
	var grown: Array = []
	for event in result.get("future_effects", []):
		if event.op != "grow_value":
			continue
		var parts: PackedStringArray = String(event.source).split(":")
		var ref := ""
		match parts[0]:
			"pin": ref = "rack:" + parts[1]
			"charm": ref = "charm:" + parts[1]
		var entry = entry_at(ref) if not ref.is_empty() else null
		if entry == null:
			continue
		entry.growth = int(entry.get("growth", 0)) + int(event.amount)
		grown.append({"ref": ref, "item_id": entry.item_id, "amount": int(event.amount)})
	# Transforms (Glass breaking): one draw per event, in the resolver's stable order.
	# The pin keeps its rack slot and modification; its growth and paid price reset.
	transformed = []
	for event in result.get("future_effects", []):
		if event.op != "transform":
			continue
		var position := int(String(event.source).get_slice(":", 1))
		var roll := _draw_effect(100)
		if roll < int(event.amount) and rack.has(position):
			var before: Dictionary = rack[position]
			var after := _entry(String(event.into), 0)
			after.mod = before.mod
			after.mod_paid = before.mod_paid
			rack[position] = after
			transformed.append({"position": position, "from": before.item_id, "into": after.item_id, "roll": roll})
	strike_streak = int(result.get("strike_streak", 0))
	return grown

## Completed-match growth: every owned Charm with a match_end grow_value effect.
func grow_after_match() -> Array:
	var grown: Array = []
	for i in charms.size():
		for effect in item(charms[i].item_id).get("effects", []):
			if effect.trigger == "match_end" and effect.op == "grow_value":
				charms[i].growth = int(charms[i].get("growth", 0)) + int(effect.amount)
				grown.append({"ref": "charm:%d" % (i + 1), "item_id": charms[i].item_id, "amount": int(effect.amount)})
	return grown

## Match end: growth for the completed match, interest on the balance held, then
## the match payout. Returns the summary.
func settle_match(frames_used: int) -> Dictionary:
	var earned := 0
	for row in ledger:
		if row.match == match_number and row.kind == "item_income":
			earned += int(row.amount)
	var summary := {"match": match_number, "balance_before": money, "interest": Upgrades.interest(money, self),
		"payout": Economy.match_payout(frames_used), "item_income": earned, "grown": grow_after_match()}
	credit(summary.interest, "interest")
	credit(summary.payout, "payout")
	summary.balance = money
	match_number += 1
	return summary

## Gross income, sales, spend, net and savings, for the run or one match.
func stats(for_match: int = 0) -> Dictionary:
	var out := {"gross_income": 0, "sales": 0, "spend": 0, "rerolls": 0, "purchases": 0}
	for row in ledger:
		if for_match > 0 and row.match != for_match:
			continue
		if row.kind in INCOME: out.gross_income += int(row.amount)
		if row.kind == "sale": out.sales += int(row.amount)
		if row.kind in SPEND: out.spend += int(row.amount)
		if row.kind == "reroll": out.rerolls += 1
		if row.kind == "purchase": out.purchases += 1
	out.net = out.gross_income + out.sales - out.spend
	out.savings = money
	return out

# --- Changes -----------------------------------------------------------------

## Puts a newly bought item at a target from placements(); the caller has already
## paid. A replaced item is sold for its sale value. Returns [] or errors (no change).
func place(item_id: String, paid: int, target: String) -> Array[String]:
	var errors: Array[String] = []
	var plan := {}
	for option in placements(item_id):
		if option.target == target:
			plan = option
	if plan.is_empty():
		errors.append("cannot place %s at %s" % [item_id, target])
		return errors
	if slot_kind(item(item_id).get("category", "")) == "mod":
		var host: Dictionary = entry_at(target)
		host.mod = item_id
		host.mod_paid = paid
		return errors
	if not plan.replaces.is_empty():
		credit(sale_value(plan.replaces), "sale", entry_at(plan.replaces).item_id)
	var parts := target.split(":")
	match parts[0]:
		"card":
			if parts[1] == "new":
				_add_card(item_id, paid)
			else:
				cards.erase(parts[1])
				_add_card(item_id, paid)
		"charm":
			if parts[1] == "new":
				charms.append(_entry(item_id, paid))
			else:
				charms[int(parts[1]) - 1] = _entry(item_id, paid)
		"rack":
			if not plan.moves_to.is_empty():
				reserves[int(plan.moves_to.split(":")[1]) - 1] = rack[int(parts[1])]
			rack[int(parts[1])] = _entry(item_id, paid)
		"reserve":
			reserves[int(parts[1]) - 1] = _entry(item_id, paid)
		"upgrade":
			upgrades.append(_entry(item_id, paid))
			if Upgrades.kind(item_id) == "reserve_slot":
				for _i in Upgrades.RESERVE_BONUS:
					reserves.append(null)
	return errors

func sell(ref: String) -> Array[String]:
	var errors: Array[String] = []
	if not can_sell(ref):
		errors.append("cannot sell " + ref)
		return errors
	var entry: Dictionary = entry_at(ref)
	credit(sale_value(ref), "sale", entry.item_id)
	_drop(ref)
	return errors

func _drop(ref: String) -> void:
	var parts := ref.split(":")
	match parts[0]:
		"card": cards.erase(parts[1])
		"charm": charms.remove_at(int(parts[1]) - 1)
		"reserve": reserves[int(parts[1]) - 1] = null

## The removal service takes a deck card out without paying for it.
func remove_card(uid: String) -> Array[String]:
	var errors: Array[String] = []
	if not cards.has(uid):
		errors.append("not a deck card: " + uid)
	else:
		cards.erase(uid)
	return errors

## Played tactical cards leave the run deck (design §15) and cannot be sold.
func drop_consumed(uids: Array) -> void:
	for uid in uids:
		cards.erase(uid)

## Rack editing between matches: swap two pin places (rack or reserve).
func swap_pins(a: String, b: String) -> Array[String]:
	var errors: Array[String] = []
	for ref in [a, b]:
		if not (ref.begins_with("rack:") or ref.begins_with("reserve:")):
			errors.append("not a pin place: " + ref)
	if not errors.is_empty():
		return errors
	var first = entry_at(a)
	var second = entry_at(b)
	if (a.begins_with("rack:") and second == null) or (b.begins_with("rack:") and first == null):
		errors.append("a rack position cannot be left empty")
		return errors
	_set_pin(a, second)
	_set_pin(b, first)
	return errors

## Charm order between matches (design §4): Charm `slot` (1-based) moves one place
## left. Order matters: additions before multipliers score more.
func move_charm_left(slot: int) -> Array[String]:
	var errors: Array[String] = []
	if slot < 2 or slot > charms.size():
		errors.append("no Charm to move at slot %d" % slot)
		return errors
	var moved = charms[slot - 1]
	charms[slot - 1] = charms[slot - 2]
	charms[slot - 2] = moved
	return errors

func _set_pin(ref: String, entry: Variant) -> void:
	if ref.begins_with("rack:"):
		rack[int(ref.split(":")[1])] = entry
	else:
		reserves[int(ref.split(":")[1]) - 1] = entry

# --- Play views ----------------------------------------------------------------

## FrameBuilder loadout: rack pins, their modifications and Charms in slot order.
func loadout() -> Dictionary:
	var pins := {}
	var pin_mods := {}
	for position in range(1, RACK_SIZE + 1):
		pins[position] = rack[position].item_id
		if not String(rack[position].mod).is_empty():
			pin_mods[position] = rack[position].mod
	var pin_growth := {}
	for position in range(1, RACK_SIZE + 1):
		pin_growth[position] = int(rack[position].get("growth", 0))
	return {"pins": pins, "charms": charms.map(func(e): return e.item_id), "pin_mods": pin_mods,
		"pin_growth": pin_growth, "charm_growth": charms.map(func(e): return int(e.get("growth", 0)))}

## The deck's cards as uid -> item id.
func deck_cards() -> Dictionary:
	var out := {}
	for uid in cards:
		out[uid] = cards[uid].item_id
	return out

func card_mod(uid: String) -> String:
	return cards[uid].mod if cards.has(uid) else ""

func to_dict() -> Dictionary:
	var rack_out := {}
	for position in rack:
		rack_out[str(position)] = rack[position].duplicate()
	var out := {"schema_version": SCHEMA_VERSION, "money": money, "match_number": match_number, "rack": rack_out,
		"reserves": reserves.duplicate(true), "charms": charms.duplicate(true), "cards": cards.duplicate(true),
		"next_card": next_card, "ledger": ledger.duplicate(true), "strike_streak": strike_streak}
	if effects_state > 0:
		out["effects_state"] = effects_state # additive (E18-C02); absent in older saves
	if not upgrades.is_empty():
		out["upgrades"] = upgrades.duplicate(true) # additive (E18-C07)
	return out

static func from_dict(data: Dictionary, catalogue: Dictionary) -> RefCounted:
	var inventory = load("res://src/rules/run_inventory.gd").new()
	inventory._index(catalogue)
	inventory.money = int(data.money)
	inventory.match_number = int(data.match_number)
	for key in data.rack:
		inventory.rack[int(key)] = _ints(data.rack[key])
	inventory.reserves = data.reserves.map(func(e): return null if e == null else _ints(e))
	inventory.charms = data.charms.map(func(e): return _ints(e))
	for uid in data.cards:
		inventory.cards[uid] = _ints(data.cards[uid])
	inventory.next_card = int(data.next_card)
	inventory.ledger = data.ledger.map(func(row): return {"match": int(row.match), "kind": row.kind, "amount": int(row.amount), "item_id": row.item_id})
	inventory.strike_streak = int(data.get("strike_streak", 0))
	inventory.effects_state = int(data.get("effects_state", 0))
	inventory.upgrades = data.get("upgrades", []).map(func(e): return _ints(e))
	return inventory

static func _ints(entry: Dictionary) -> Dictionary:
	return {"item_id": entry.item_id, "paid": int(entry.paid), "mod": entry.mod, "mod_paid": int(entry.mod_paid), "growth": int(entry.get("growth", 0))}
