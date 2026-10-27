extends PanelContainer
## Between-match Pro Shop (E08): the match settlement, five offers, reroll, the
## card-removal service, selling, and a choice sheet for placements (including
## explicit replacements) with Cancel. A view only: the lab and the pure Shop and
## RunInventory own every rule and number. Touch, mouse and keyboard/gamepad focus
## all work. Developmental look; card art and foil are E12/E19.
signal offer_pressed(index: int)
signal reroll_pressed
signal remove_pressed
signal sell_pressed(ref: String)
signal continue_pressed
signal choice_made(index: int)
signal choice_cancelled

var title: Label
var summary: Label
var money: Label
var preview: Label
var message: Label
var offers_grid: GridContainer
var reroll_button: Button
var remove_button: Button
var continue_button: Button
var rack_label: Label
var owned_list: VBoxContainer
var choice_sheet: PanelContainer
var choice_prompt: Label
var choice_list: VBoxContainer
var cancel_choice: Button
var offer_buttons: Array = []
var _main: VBoxContainer

func _ready() -> void:
	name = "ShopPanel"
	add_theme_stylebox_override("panel", _style(Color(0.05, 0.04, 0.09, 0.97)))
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_main = VBoxContainer.new()
	_main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_main.add_theme_constant_override("separation", 10)
	scroll.add_child(_main)
	title = _label(_main, "ShopTitle", 30)
	summary = _label(_main, "Settlement", 22)
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview = _label(_main, "NextMatch", 22)
	preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0))
	money = _label(_main, "Money", 28)
	money.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	offers_grid = GridContainer.new()
	offers_grid.name = "Offers"
	offers_grid.columns = 3
	offers_grid.add_theme_constant_override("h_separation", 8)
	offers_grid.add_theme_constant_override("v_separation", 8)
	_main.add_child(offers_grid)
	for i in 5:
		var button := Button.new()
		button.name = "Offer_%d" % i
		button.custom_minimum_size = Vector2(216, 150)
		button.clip_text = true
		button.pressed.connect(func(): offer_pressed.emit(i))
		offers_grid.add_child(button)
		offer_buttons.append(button)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	_main.add_child(actions)
	reroll_button = _button(actions, "Reroll", func(): reroll_pressed.emit())
	remove_button = _button(actions, "RemoveCard", func(): remove_pressed.emit())
	continue_button = _button(actions, "ContinueShop", func(): continue_pressed.emit())
	continue_button.text = "Next Match"
	message = _label(_main, "ShopMessage", 22)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.add_theme_color_override("font_color", Color(1.0, 0.55, 0.45))
	rack_label = _label(_main, "RackSummary", 20)
	rack_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	owned_list = VBoxContainer.new()
	owned_list.name = "Owned"
	owned_list.add_theme_constant_override("separation", 6)
	_main.add_child(owned_list)
	# Choice sheet: sits over the shop until a choice or Cancel.
	choice_sheet = PanelContainer.new()
	choice_sheet.name = "ChoiceSheet"
	choice_sheet.add_theme_stylebox_override("panel", _style(Color(0.1, 0.08, 0.16, 0.99)))
	choice_sheet.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	choice_sheet.top_level = true
	choice_sheet.hide()
	add_child(choice_sheet)
	var sheet_scroll := ScrollContainer.new()
	sheet_scroll.custom_minimum_size = Vector2(560, 0)
	sheet_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	choice_sheet.add_child(sheet_scroll)
	var sheet := VBoxContainer.new()
	sheet.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sheet.add_theme_constant_override("separation", 8)
	sheet_scroll.add_child(sheet)
	choice_prompt = _label(sheet, "ChoicePrompt", 24)
	choice_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	choice_list = VBoxContainer.new()
	choice_list.name = "Choices"
	choice_list.add_theme_constant_override("separation", 6)
	sheet.add_child(choice_list)
	cancel_choice = _button(sheet, "CancelChoice", func(): choice_cancelled.emit())
	cancel_choice.text = "Cancel"

static func _style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(12)
	style.set_content_margin_all(14)
	return style

func _label(parent: Control, node_name: String, font_size: int) -> Label:
	var label := Label.new()
	label.name = node_name
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label

func _button(parent: Control, node_name: String, action: Callable, flags: int = 0) -> Button:
	var button := Button.new()
	button.name = node_name
	button.custom_minimum_size = Vector2(200, 64)
	button.pressed.connect(action, flags)
	parent.add_child(button)
	return button

## view: {title, summary, money, offers: [{text, state}], reroll_cost, can_reroll,
## removal_price, can_remove, rack, sellables: [{ref, label}], message, columns}.
## Offer states: "buy", "poor" (unaffordable), "blocked", "sold", "empty".
func show_view(view: Dictionary) -> void:
	title.text = view.title
	summary.text = view.summary
	preview.text = view.get("preview", "")
	money.text = "$%d" % view.money
	offers_grid.columns = view.get("columns", 3)
	for i in offer_buttons.size():
		var offer: Dictionary = view.offers[i]
		var button: Button = offer_buttons[i]
		button.text = offer.text
		button.disabled = offer.state != "buy" or choice_sheet.visible
		button.modulate = {"buy": Color.WHITE, "poor": Color(1.0, 0.75, 0.75), "blocked": Color(0.8, 0.8, 0.8), "sold": Color(0.6, 0.6, 0.6), "empty": Color(0.5, 0.5, 0.5)}[offer.state]
	reroll_button.text = "Reroll $%d" % view.reroll_cost
	reroll_button.disabled = not view.can_reroll or choice_sheet.visible
	remove_button.text = "Remove a card $%d" % view.removal_price
	remove_button.disabled = not view.can_remove or choice_sheet.visible
	continue_button.disabled = choice_sheet.visible
	message.text = view.get("message", "")
	var refused: bool = message.text.begins_with("Can't")
	message.add_theme_color_override("font_color", Color(1.0, 0.55, 0.45) if refused else Color(0.6, 0.95, 0.7))
	rack_label.text = view.rack
	for child in owned_list.get_children():
		owned_list.remove_child(child)
		child.queue_free()
	for owned in view.sellables:
		var ref: String = owned.ref
		# Deferred: selling rebuilds this list, so the button must not vanish mid-input.
		var button := _button(owned_list, "Sell_" + ref.replace(":", "_").replace("-", "_"), func(): sell_pressed.emit(ref), CONNECT_DEFERRED)
		button.text = owned.label
		button.custom_minimum_size = Vector2(0, 52)
		button.disabled = choice_sheet.visible

func show_choices(prompt: String, labels: Array) -> void:
	choice_prompt.text = prompt
	for child in choice_list.get_children():
		choice_list.remove_child(child)
		child.queue_free()
	for i in labels.size():
		var index := i
		var button := _button(choice_list, "Choice_%d" % i, func(): choice_made.emit(index), CONNECT_DEFERRED)
		button.text = labels[i]
		button.custom_minimum_size = Vector2(0, 56)
	choice_sheet.show()
	var viewport_size := get_viewport_rect().size
	choice_sheet.size = Vector2(minf(600.0, viewport_size.x - 32.0), minf(64.0 * (labels.size() + 2) + 60.0, viewport_size.y - 160.0))
	choice_sheet.position = (viewport_size - choice_sheet.size) * 0.5
	if labels.is_empty():
		cancel_choice.grab_focus()
	else:
		choice_list.get_child(0).grab_focus()

func hide_choices() -> void:
	choice_sheet.hide()

func button_for_offer(index: int) -> Button:
	return offer_buttons[index]

func choice_button(index: int) -> Button:
	return choice_list.get_child(index) if index < choice_list.get_child_count() else null

func sell_button(ref: String) -> Button:
	return owned_list.get_node_or_null("Sell_" + ref.replace(":", "_").replace("-", "_"))
