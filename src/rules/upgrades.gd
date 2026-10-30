extends RefCounted
## E18-C07 shop upgrades ("Pro Shop licences", design §3 and §15): bought from the
## shop's License offer, kept for the rest of the attempt, never sold, one of each.
## A closed vocabulary keyed by catalogue id, like rival rules and tactics; unknown
## upgrades do nothing. Every number here is provisional (E24).
##   free_reroll  (Punch Card):     the first reroll in each shop visit is free.
##   reserve_slot (Pin Caddy):      one more reserve slot for pins.
##   discount     (Clearance Tag):  every offer costs $1 less (never under $1).
##   interest_cap (Savings Book):   the interest cap rises by $2.
##   extra_offer  (Extra Shelf):    the shop shows one more offer, of any category.
##   rarity_shift (Spotlight Sign): uncommon and rare offers come up more often.
const Economy = preload("res://src/rules/economy.gd")
const KINDS := {"shop_upgrade.punch_card": "free_reroll", "shop_upgrade.pin_caddy": "reserve_slot", "shop_upgrade.clearance_tag": "discount",
	"shop_upgrade.savings_book": "interest_cap", "shop_upgrade.extra_shelf": "extra_offer", "shop_upgrade.spotlight_sign": "rarity_shift"}
const DISCOUNT := 1
const MIN_PRICE := 1
const INTEREST_BONUS := 2
const RESERVE_BONUS := 1
const SPOTLIGHT_WEIGHTS := {"common": 40, "uncommon": 38, "rare": 18, "epic": 4, "legendary": 0}

static func kind(item_id: String) -> String:
	return KINDS.get(item_id, "")

## What the upgrade does, for cards and shop offers ("" for other items).
static func describe(item_id: String) -> String:
	match kind(item_id):
		"free_reroll": return "First reroll each visit is free · kept"
		"reserve_slot": return "+%d reserve slot · kept" % RESERVE_BONUS
		"discount": return "Offers cost $%d less (min $%d) · kept" % [DISCOUNT, MIN_PRICE]
		"interest_cap": return "Interest cap $%d → $%d · kept" % [Economy.INTEREST_CAP, Economy.INTEREST_CAP + INTEREST_BONUS]
		"extra_offer": return "+1 shop offer, any category · kept"
		"rarity_shift": return "Rarer offers: uncommon %d%%, rare %d%% · kept" % [SPOTLIGHT_WEIGHTS.uncommon, SPOTLIGHT_WEIGHTS.rare]
	return ""

## True when the run owns an upgrade of this kind. inventory: a RunInventory (or null).
static func owned(inventory, upgrade_kind: String) -> bool:
	return inventory != null and inventory.upgrades.any(func(e): return kind(e.item_id) == upgrade_kind)

static func price(base: int, inventory) -> int:
	return maxi(MIN_PRICE, base - DISCOUNT) if owned(inventory, "discount") and base > 0 else base

## Reroll cost after `rerolls` paid this visit: with Punch Card the first is free and
## the usual sequence follows it.
static func reroll_cost(rerolls: int, inventory) -> int:
	if not owned(inventory, "free_reroll"):
		return Economy.reroll_cost(rerolls)
	return 0 if rerolls == 0 else Economy.reroll_cost(rerolls - 1)

static func interest(balance: int, inventory) -> int:
	var cap: int = Economy.INTEREST_CAP + (INTEREST_BONUS if owned(inventory, "interest_cap") else 0)
	return mini(floori(maxi(balance, 0) / float(Economy.INTEREST_STEP)), cap)

static func rarity_weights(base: Dictionary, inventory) -> Dictionary:
	return SPOTLIGHT_WEIGHTS if owned(inventory, "rarity_shift") else base

## One line per owned upgrade for the shop's summary.
static func summary(inventory, names: Dictionary) -> String:
	return ", ".join(inventory.upgrades.map(func(e): return names.get(e.item_id, e.item_id)))
