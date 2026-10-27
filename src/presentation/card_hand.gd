extends PanelContainer
## The equipment row: the current hand (deck model) or the always-visible bag
## (direct model), a Cycle button and pile counts. A view only: it shows what the
## lab tells it and reports presses; the lab and the rules models own every
## decision. Buttons work by touch, mouse and keyboard/gamepad focus.
## Developmental look; card art and foil are E12/E19.
signal card_pressed(uid: String)
signal cycle_pressed

var cards_row: HFlowContainer
var cycle_button: Button
var info: Label
var buttons: Dictionary = {} # uid -> Button

func _ready() -> void:
	name = "CardHand"
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.03, 0.08, 0.85)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(10)
	add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	add_child(box)
	info = Label.new()
	info.name = "EquipmentInfo"
	info.add_theme_font_size_override("font_size", 20)
	box.add_child(info)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)
	# Flows onto a second row when the lab narrows the panel (landscape).
	cards_row = HFlowContainer.new()
	cards_row.name = "Cards"
	cards_row.add_theme_constant_override("h_separation", 8)
	cards_row.add_theme_constant_override("v_separation", 8)
	cards_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(cards_row)
	cycle_button = Button.new()
	cycle_button.name = "CycleCard"
	cycle_button.text = "Cycle"
	cycle_button.custom_minimum_size = Vector2(110, 96)
	cycle_button.pressed.connect(func(): cycle_pressed.emit())
	row.add_child(cycle_button)

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
		var button: Button = buttons.get(card.uid)
		if button == null:
			button = Button.new()
			button.name = "Card_" + card.uid.replace("-", "_").replace(".", "_")
			button.custom_minimum_size = Vector2(124, 96)
			button.toggle_mode = false
			button.clip_text = true
			var uid: String = card.uid
			button.pressed.connect(func(): card_pressed.emit(uid))
			cards_row.add_child(button)
			buttons[card.uid] = button
		cards_row.move_child(button, wanted.find(card.uid))
		var mark: String = marks.get(card.uid, "")
		var tag: String = {"ball": "▶ ARMED", "tactical": "▶ TACTIC", "keep": "★ KEEP"}.get(mark, "")
		button.text = "%s\n%s%s" % [card.title, card.detail, ("\n" + tag) if not tag.is_empty() else ""]
		button.modulate = Color(1.0, 0.9, 0.45) if not mark.is_empty() else (Color(0.75, 0.9, 1.0) if card.kind == "tactical" else Color.WHITE)
		button.disabled = not enabled
	info.text = header
	cycle_button.visible = cycle_supported
	cycle_button.disabled = not (can_cycle and enabled)

func button_for(uid: String) -> Button:
	return buttons.get(uid)
