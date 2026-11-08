extends PanelContainer
## The equipment row: the current hand (deck model) or the always-visible bag
## (direct model), a Cycle button and pile counts. A view only: it shows what the
## lab tells it and reports presses; the lab and the rules models own every
## decision. Buttons work by touch, mouse and keyboard/gamepad focus.
## Cards are UI-1's CardView: the UI-A1 playing-card face with art, rules and states.
const ItemAssets = preload("res://src/presentation/item_assets.gd")
const CardView = preload("res://src/presentation/card_view.gd")
const UiTheme = preload("res://src/presentation/house_ui_theme.gd")
signal card_pressed(uid: String)
signal cycle_pressed
signal inspect_requested(card: Dictionary, origin: Control)

var cards_row: HFlowContainer
var cycle_button: Button
var info: Label
var inspect_button: Button
var inspecting := false
var card_data: Dictionary = {}
var buttons: Dictionary = {} # uid -> CardView (a Button)
var reduced_motion := false
## Tallest a hand card may be (the lab keeps the hand clear of the ball).
var max_card_height := 150.0
## "row" (one row, as before), "flank" (two columns, actions below) or "fan".
var mode := "row"
var _left_handed := false
var body: BoxContainer
var actions: BoxContainer
var header: HBoxContainer
const FAN_OVERLAP := 0.3 # of a card's width

func _ready() -> void:
	name = "CardHand"
	add_theme_stylebox_override("panel", UiTheme.frame("panel", 14.0, 10.0))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	add_child(box)
	info = Label.new()
	info.name = "EquipmentInfo"
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_font_size_override("font_size", 20)
	header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	box.add_child(header)
	header.add_child(info)
	# UI-2: cards and actions; "flank" stacks them (landscape), "fan" puts the
	# actions on a thumb rail beside a fanned hand (portrait, mirrored for left hands).
	body = BoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(body)
	cards_row = HFlowContainer.new()
	cards_row.name = "Cards"
	cards_row.add_theme_constant_override("h_separation", 8)
	cards_row.add_theme_constant_override("v_separation", 8)
	cards_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(cards_row)
	actions = BoxContainer.new()
	actions.vertical = true
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 8)
	body.add_child(actions)
	cycle_button = Button.new()
	cycle_button.name = "CycleCard"
	cycle_button.text = "Cycle"
	cycle_button.custom_minimum_size = Vector2(110, 48)
	cycle_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cycle_button.pressed.connect(func(): cycle_pressed.emit())
	actions.add_child(cycle_button)
	inspect_button = Button.new()
	inspect_button.name = "InspectCard"
	inspect_button.text = "Inspect"
	inspect_button.custom_minimum_size = Vector2(110,48)
	inspect_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inspect_button.pressed.connect(func():
		inspecting = not inspecting
		inspect_button.text = "Pick card" if inspecting else "Inspect")
	actions.add_child(inspect_button)

## cards: [{uid, title, detail, kind}], marks: uid -> "ball"/"tactical"/"keep"/"cycle".
## cycle_supported hides the Cycle button for models without one.
func show_cards(cards: Array, marks: Dictionary, header: String, cycle_supported: bool, can_cycle: bool, enabled: bool) -> void:
	var wanted: Array = cards.map(func(card): return card.uid)
	for uid in buttons.keys():
		if uid not in wanted:
			# Detach now (the name may return this frame); free once any press settles.
			cards_row.remove_child(buttons[uid])
			buttons[uid].queue_free()
			buttons.erase(uid)
	for card in cards:
		card = card.duplicate()
		card["item_id"] = ItemAssets.identify(card)
		card_data[card.uid] = card
		var button: CardView = buttons.get(card.uid)
		var dealt := button == null
		if button == null:
			button = CardView.new()
			button.name = "Card_" + card.uid.replace("-", "_").replace(".", "_")
			var uid: String = card.uid
			button.pressed.connect(func():
				if button.consume_long_press(): return
				if inspecting:
					inspecting = false
					inspect_button.text = "Inspect"
					inspect_requested.emit(card_data[uid], buttons[uid])
				else: card_pressed.emit(uid), CONNECT_DEFERRED)
			# Long press opens inspection directly (UI-1).
			button.long_pressed.connect(func(): inspect_requested.emit(card_data[uid], buttons[uid]))
			cards_row.add_child(button)
			buttons[card.uid] = button
		button.reduced_motion = reduced_motion
		cards_row.move_child(button, wanted.find(card.uid))
		if button.item_id != card.item_id or button.item_id.is_empty():
			button.set_item(card.item_id, {}, card.title, preload("res://src/presentation/card_inspector.gd").illustration(int(card.get("art_index", 2))))
		var mark: String = marks.get(card.uid, "")
		var tag: String = {"ball": "ARMED", "tactical": "TACTIC", "keep": "KEEP"}.get(mark, "")
		var state: String = {"ball": "armed", "tactical": "tactic", "keep": "keep"}.get(mark, "")
		button.set_state(state, tag, "", "%s\n%s\n%s%s" % [card.title, card.detail, ItemAssets.rarity_mark(card.item_id), ("\n▶ " + tag) if not tag.is_empty() else ""])
		button.tooltip_text = "%s · %s\n%s" % [card.title, ItemAssets.rarity_mark(card.item_id), card.detail]
		if dealt:
			button.deal_in(0.035 * wanted.find(card.uid))
		button.disabled = not enabled
	inspect_button.disabled = not enabled
	if not enabled:
		inspecting = false
		inspect_button.text = "Inspect"
	info.text = header
	_size_cards()
	cycle_button.visible = cycle_supported
	cycle_button.disabled = not (can_cycle and enabled)

func button_for(uid: String) -> Button:
	return buttons.get(uid)

## Sizes the cards so the whole hand shows at once, at playing-card proportions.
## Cards get their size as they are created (show_cards), so a tap right after the
## hand changes lands where the card is drawn; this keeps it right after resizes.
func _process(_delta: float) -> void:
	_size_cards()

func _card_size() -> Vector2:
	var gap := 8.0
	var count := maxi(buttons.size(), 1)
	var width_available := cards_row.size.x if cards_row.size.x > 0.0 else 480.0
	var width: float
	match mode:
		"flank":
			width = (width_available - gap) / 2.0
		"fan":
			width = width_available / (1.0 + (1.0 - FAN_OVERLAP) * (count - 1))
		_:
			var per_row := count if size.x >= size.y * 1.4 or count <= 2 else ceili(count / 2.0)
			width = (width_available - gap * (per_row - 1)) / per_row
	width = minf(width, max_card_height / CardView.ASPECT)
	return Vector2(floorf(width), floorf(width * CardView.ASPECT))

## UI-2 layout modes; `left_handed` puts the fan's thumb rail on the left.
## "fan" (portrait, UI-3): Cycle and Inspect sit in the header beside the counts,
## mirrored for left hands, so the fan gets the panel's full width. "flank"
## (landscape): two columns with the actions below.
func set_mode(new_mode: String, left_handed: bool = false) -> void:
	if mode == new_mode and _left_handed == left_handed and actions.get_parent() != null and actions.get_parent() != body: return
	mode = new_mode
	_left_handed = left_handed
	body.vertical = mode == "flank"
	actions.vertical = false
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.get_parent().remove_child(actions)
	if mode == "fan":
		header.add_child(actions)
		header.move_child(actions, 0 if left_handed else -1)
	else:
		body.add_child(actions)
	info.add_theme_font_size_override("font_size", 16 if mode == "flank" else 18)
	for button in [cycle_button, inspect_button]:
		button.custom_minimum_size = Vector2(0 if mode == "flank" else 112, 44)
	_size_cards()

func _size_cards() -> void:
	if buttons.is_empty(): return
	var want := _card_size()
	var fan := mode == "fan"
	var separation := -int(roundf(want.x * FAN_OVERLAP)) if fan else 8
	if cards_row.get_theme_constant("h_separation") != separation:
		cards_row.add_theme_constant_override("h_separation", separation)
	var count := cards_row.get_child_count()
	for i in count:
		var button: CardView = cards_row.get_child(i)
		if button.custom_minimum_size != want:
			button.custom_minimum_size = want
		# A gentle arc: outer cards turn out and sit a little lower.
		var t := (i - (count - 1) * 0.5) / maxf((count - 1) * 0.5, 1.0) if fan and count > 1 else 0.0
		button.set_fan(6.0 * t, 10.0 * t * t)
