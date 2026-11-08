extends RefCounted
## UI-1: the card component's short rules (bound to catalogue rules, not samples)
## and its states, without a scene tree.
const CardView = preload("res://src/presentation/card_view.gd")
const ItemAssets = preload("res://src/presentation/item_assets.gd")

static func run() -> Array[String]:
	var failures: Array[String] = []
	ItemAssets._ensure()
	var names := {}
	for item in ItemAssets._items.values():
		names[item.id] = item.name
	var cases := {
		"pin.ruby": ["mult", "+2 Mult", "When down"],
		"charm.crown_jewel": ["mult", "×2 Mult", "Crown Pin fell last"],
		"charm.trophy_case": ["mult", "+1 Mult", "Per growth"],
		"charm.strike_fund": ["money", "+$1", "Strike"],
		"charm.wood_grain": ["value", "+3 Value", "Per Wood Pin down"],
		"ball.house": ["ball", "Reliable roll", "Standard weight"],
		"ball.hook": ["ball", "Hook ×1.6", "Spin response"],
		"consumable.nudge": ["consumable", "", "Before roll 2 · once"],
		"shop_upgrade.punch_card": ["shop_upgrade", "First reroll each visit is free · kept", "Kept for the run"],
	}
	for id in cases:
		var got := CardView.summary(ItemAssets._items[id], names)
		var want: Array = cases[id]
		var hint_ok: bool = want[1].is_empty() or got.hint == want[1]
		_expect(got.icon == want[0] and hint_ok and got.detail == want[2], "%s summarises as %s / %s / %s (got %s)" % [id, want[0], want[1], want[2], str(got)], failures)
	# Every catalogue item gets a non-empty face: a hint, and a known icon.
	for item in ItemAssets._items.values():
		var got := CardView.summary(item, names)
		_expect(not String(got.hint).is_empty() and ResourceLoader.exists("res://assets/ui/cards/%s.svg" % got.icon), "%s has a short rule and a known icon" % item.id, failures)
	# States: SOLD and LOCKED stamp the art; armed lifts with a tab; the text stays readable.
	var card := CardView.new()
	card.size = Vector2(210, 300)
	card.set_item("charm.trophy_case")
	card.set_state("sold", "", "", "Trophy Case  SOLD")
	_expect(card._parts.stamp.visible and card._parts.stamp.text == "SOLD" and card._parts.hatch.visible and card.text.contains("SOLD"), "sold stamps the art and keeps SOLD in the label", failures)
	card.set_state("armed", "ARMED")
	_expect(card._parts.tag.visible and card._parts.tag.text == "ARMED" and card._lift == 8.0 and not card._parts.stamp.visible, "armed lifts 8 px with an ARMED tab", failures)
	card.reduced_motion = true
	card.set_state("armed", "ARMED")
	_expect(card._lift == 0.0, "reduced motion: no lift", failures)
	card.set_state("", "", "$6")
	_expect(card._parts.price.visible and card._parts.price.text == "$6" and card.icon == ItemAssets.slot("charm.trophy_case", "icon"), "the price is an overlay; the production icon stays set", failures)
	card.size = Vector2(96, 137)
	card._layout()
	_expect(not card._parts.hint.visible and card._parts.name.visible and card._parts.rarity.visible, "a small card keeps name and rarity, and moves the rule to inspection", failures)
	card.free()
	return failures

static func _expect(condition: bool, label: String, failures: Array[String]) -> void:
	if not condition: failures.append(label)
