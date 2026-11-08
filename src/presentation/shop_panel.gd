extends PanelContainer
## Between-match Pro Shop (E08): the match settlement, five offers, reroll, the
## card-removal service, selling, and a choice sheet for placements (including
## explicit replacements) with Cancel. A view only: the lab and the pure Shop and
## RunInventory own every rule and number. Touch, mouse and keyboard/gamepad focus
## all work. Developmental look; card art and foil are E12/E19.
const ItemAssets = preload("res://src/presentation/item_assets.gd")
const CardView = preload("res://src/presentation/card_view.gd")
const UiTheme = preload("res://src/presentation/house_ui_theme.gd")
signal offer_pressed(index: int)
signal reroll_pressed
signal remove_pressed
signal sell_pressed(ref: String)
signal continue_pressed
signal choice_made(index: int)
signal choice_cancelled
signal charm_moved(slot: int)

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
var _scroll: ScrollContainer
var details_button: Button
var _details_open := false
var _landscape := false
var _split: HBoxContainer
var _pin: HBoxContainer
var _actions: HBoxContainer
var _shelf: VBoxContainer

func _ready() -> void:
	name = "ShopPanel"
	add_theme_stylebox_override("panel", UiTheme.frame("shop", 20.0, 16.0))
	# UI-2: landscape puts the offers on a three-column shelf beside the scrolling
	# shop text and actions; portrait keeps one scrolling column.
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	add_child(root)
	_split = HBoxContainer.new()
	_split.add_theme_constant_override("separation", 18)
	_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_split)
	# UI-3: in portrait the actions are pinned below the scrolling shop, always in reach.
	_pin = HBoxContainer.new()
	_pin.name = "PinnedActions"
	root.add_child(_pin)
	_shelf = VBoxContainer.new()
	_shelf.name = "Shelf"
	_shelf.alignment = BoxContainer.ALIGNMENT_CENTER
	_shelf.hide()
	_split.add_child(_shelf)
	var scroll := ScrollContainer.new()
	_scroll = scroll
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true # keyboard and gamepad focus scrolls its button into view
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_split.add_child(scroll)
	_main = VBoxContainer.new()
	_main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_main.add_theme_constant_override("separation", 10)
	scroll.add_child(_main)
	# UI-3: the title and money share a line.
	var heading := HBoxContainer.new()
	_main.add_child(heading)
	title = _label(heading, "ShopTitle", 30)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary = _label(_main, "Settlement", 22)
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview = _label(_main, "NextMatch", 22)
	preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0))
	money = _label(heading, "Money", 30)
	money.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	offers_grid = GridContainer.new()
	offers_grid.name = "Offers"
	offers_grid.columns = 3
	offers_grid.add_theme_constant_override("h_separation", 8)
	offers_grid.add_theme_constant_override("v_separation", 8)
	_main.add_child(offers_grid)
	for i in 5:
		_add_offer_button()
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_main.add_child(actions)
	_actions = actions
	reroll_button = _button(actions, "Reroll", func(): reroll_pressed.emit())
	remove_button = _button(actions, "RemoveCard", func(): remove_pressed.emit())
	continue_button = _button(actions, "ContinueShop", func(): continue_pressed.emit())
	continue_button.text = "Next Match"
	message = _label(_main, "ShopMessage", 22)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.add_theme_color_override("font_color", Color(1.0, 0.55, 0.45))
	# UI-3: the payout breakdown and the rack list fold behind Details in portrait.
	details_button = _button(_main, "ShopDetails", func():
		_details_open = not _details_open
		_show_details())
	_main.move_child(summary, -1) # actions, message, Details, then the payout
	rack_label = _label(_main, "RackSummary", 20)
	rack_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	owned_list = VBoxContainer.new()
	owned_list.name = "Owned"
	owned_list.add_theme_constant_override("separation", 6)
	_main.add_child(owned_list)
	# Choice sheet: sits over the shop until a choice or Cancel.
	choice_sheet = PanelContainer.new()
	choice_sheet.name = "ChoiceSheet"
	choice_sheet.add_theme_stylebox_override("panel", UiTheme.frame("menu", 20.0, 16.0))
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

## Offer buttons grow with the offers (E18-C07: Extra Shelf and the License offer).
func _add_offer_button() -> void:
	var i := offer_buttons.size()
	# Offers are UI-1 playing cards; the price is a removable overlay, never on the face.
	var button := CardView.new()
	button.name = "Offer_%d" % i
	button.custom_minimum_size = Vector2(196, 280)
	button.pressed.connect(func(): if not button.consume_long_press(): offer_pressed.emit(i))
	offers_grid.add_child(button)
	offer_buttons.append(button)

func _show_details() -> void:
	var pinned := not _landscape
	if pinned != (_actions.get_parent() == _pin):
		_actions.get_parent().remove_child(_actions)
		if pinned:
			_pin.add_child(_actions)
		else:
			_main.add_child(_actions)
			_main.move_child(_actions, message.get_index())
	_pin.visible = pinned
	for button in [reroll_button, remove_button, continue_button]:
		button.custom_minimum_size = Vector2(200, 64) if _landscape else Vector2(0, 60)
		button.size_flags_horizontal = Control.SIZE_FILL if _landscape else Control.SIZE_EXPAND_FILL
	var shown := _landscape or _details_open
	summary.visible = shown
	rack_label.visible = shown
	details_button.visible = not _landscape
	details_button.text = "Hide details" if _details_open else "Payout & rack details"

static func _style(_color: Color) -> StyleBox:
	return UiTheme.frame("panel", 14.0, 12.0)

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
## removal_price, can_remove, rack, sellables: [{ref, label}], charm_order, charm_moves:
## [{slot, label}], message, columns}.
## Offer states: "buy", "poor" (unaffordable), "blocked", "sold", "empty".
func show_view(view: Dictionary) -> void:
	title.text = view.title
	summary.text = view.summary
	preview.text = view.get("preview", "")
	money.text = "$%d" % view.money
	var landscape: bool = view.get("landscape", false)
	_landscape = landscape
	_show_details()
	# A reflow (portrait <-> landscape) brings the offers back into view.
	if _shelf.visible != landscape:
		_scroll.scroll_vertical = 0
		offers_grid.get_parent().remove_child(offers_grid)
		if landscape:
			_shelf.add_child(offers_grid)
		else:
			_main.add_child(offers_grid)
			_main.move_child(offers_grid, money.get_index() + 1)
		_shelf.visible = landscape
	offers_grid.columns = view.get("columns", 3)
	while offer_buttons.size() < view.offers.size():
		_add_offer_button()
	# Portrait keeps the cards compact so the actions and sales stay on screen;
	# landscape sizes the shelf's cards to fit every row on screen.
	var card_size := Vector2(105, 150)
	if not landscape:
		# UI-3: three columns as wide as the panel allows (up to 150 px), short
		# enough that every row of offers shows above the pinned actions.
		var rows := ceili(view.offers.size() / 3.0)
		var room := _scroll.size.y - 150.0 - 8.0 * (rows - 1)
		var height := clampf(room / maxf(rows, 1), 150.0, 214.0)
		var width := floorf(minf(minf(150.0, (size.x - 40.0 - 14.0 - 16.0) / 3.0), height / CardView.ASPECT))
		card_size = Vector2(width, floorf(width * CardView.ASPECT))
	if landscape:
		var rows := ceili(view.offers.size() / float(offers_grid.columns))
		var room := size.y - 40.0 - 8.0 * (rows - 1)
		var height := floorf(minf(280.0, room / maxf(rows, 1)))
		card_size = Vector2(floorf(height / CardView.ASPECT), height)
	for i in offer_buttons.size():
		offer_buttons[i].visible = i < view.offers.size()
		offer_buttons[i].custom_minimum_size = card_size
	for i in view.offers.size():
		var offer: Dictionary = view.offers[i]
		var button: CardView = offer_buttons[i]
		var item_id := str(offer.get("item_id", ""))
		if item_id.is_empty():
			button.item_id = ""
			button.show_face(false) # an empty slot shows the card back
		else:
			if button.item_id != item_id:
				button.set_item(item_id, {}, String(offer.get("name", "")))
				button.deal_in(0.035 * i)
			button.show_face(true)
		var state: String = {"buy": "", "poor": "unaffordable", "blocked": "unaffordable", "sold": "sold", "empty": ""}[offer.state]
		var price := "$%d" % int(offer.price) if offer.has("price") and offer.state != "sold" else ""
		button.set_state(state, String(offer.get("status", "")), price, offer.text)
		button.disabled = offer.state != "buy" or choice_sheet.visible
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
	# Charm order (E13), after the sales so existing controls keep their place: each
	# Charm after the first can move one slot left.
	if not String(view.get("charm_order", "")).is_empty():
		var order := _label(owned_list, "CharmOrder", 20)
		order.text = view.charm_order
		order.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for move in view.get("charm_moves", []):
		var slot: int = move.slot
		var button := _button(owned_list, "MoveCharm_%d" % slot, func(): charm_moved.emit(slot), CONNECT_DEFERRED)
		button.text = move.label
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

func move_button(slot: int) -> Button:
	return owned_list.get_node_or_null("MoveCharm_%d" % slot)

func sell_button(ref: String) -> Button:
	return owned_list.get_node_or_null("Sell_" + ref.replace(":", "_").replace("-", "_"))
