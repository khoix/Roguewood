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
	# The rings are drawn on the face, so they turn with a fanned card and stay
	# within reach of the card's own edge (owner's play notes, 2026-11-14).
	card.set_fan(8.0, 4.0)
	_expect(card._ring.get_parent() == card._face and card._ring.get_index() == card._face.get_child_count() - 1 and is_equal_approx(card._face.rotation, deg_to_rad(8.0))
		and card._ring.size.is_equal_approx(card._face.size) and card.get_theme_stylebox("focus") is StyleBoxEmpty, "the selection and focus rings ride on the fanned face", failures)
	# An item whose art is still to come shows its category mark, dimmed and labelled.
	card.size = Vector2(210, 300)
	card.set_item("charm.laser_level" if ItemAssets.slot("charm.laser_level", "card") == null else "none.such")
	_expect(card.art_pending and card._parts.pending.visible and card.art.texture == load("res://assets/ui/cards/charm.svg") and card.art.modulate.a < 0.5, "a card without art shows its category mark and ART TO COME", failures)
	card.set_item("charm.trophy_case")
	_expect(not card.art_pending and not card._parts.pending.visible and card.art.modulate.a == 1.0, "a card with art shows it at full strength", failures)
	card.free()
	failures.append_array(_font_covers_text())
	return failures

## Every character the game can show has a glyph in the bundled font. A desktop
## borrows a missing one from a system font; a browser cannot, and a phone draws a
## box (owner's play notes, 2026-11-14). New symbols: docs/art/ui/patch_symbols.py.
static func _font_covers_text() -> Array[String]:
	var failures: Array[String] = []
	var font: FontFile = load("res://assets/ui/fonts/PixelifySans.ttf")
	var missing := {}
	var pending: Array = ["res://src", "res://content"]
	while not pending.is_empty():
		var dir: String = pending.pop_back()
		for sub in DirAccess.get_directories_at(dir):
			pending.append(dir.path_join(sub))
		for file in DirAccess.get_files_at(dir):
			if file.get_extension() not in ["gd", "json", "tscn"]: continue
			var text := FileAccess.get_file_as_string(dir.path_join(file))
			for i in text.length():
				var code := text.unicode_at(i)
				if code > 126 and not font.has_char(code):
					missing[String.chr(code)] = dir.path_join(file)
	for symbol in missing:
		failures.append("the font has no glyph for '%s' (U+%04X), used in %s" % [symbol, symbol.unicode_at(0), missing[symbol]])
	return failures

static func _expect(condition: bool, label: String, failures: Array[String]) -> void:
	if not condition: failures.append(label)
