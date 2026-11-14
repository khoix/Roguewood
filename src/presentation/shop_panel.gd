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
## UI-5b (owner, 2026-11-10): a tapped offer opens large to read and confirm; one
## Sell control opens a sheet in place of a button per owned item; the preview is
## one short line (`preview` keeps the full sentences for tools and tests).
var preview_short: Label
var offer_sheet: PanelContainer
var offer_card: CardView
var offer_title: Label
var offer_kind: Label
var offer_detail: Label
var offer_price: Label
var offer_reason: Label
var buy_button: Button
var offer_back: Button
var sell_open: Button
var sell_sheet: PanelContainer
var sell_title: Label
var sell_close: Button
var _dim: ColorRect
var _offers: Array = []
var _offer_index := -1
var _money := 0

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
	preview.hide()
	preview_short = _label(_main, "NextMatchShort", 20)
	preview_short.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_short.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0))
	money = _label(heading, "Money", 30)
	money.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	# Room for a card's status tab (SOLD), which stands above the card, so it never
	# covers the last line of the preview.
	var tab_room := Control.new()
	tab_room.name = "TabRoom"
	tab_room.custom_minimum_size = Vector2(0, 14)
	tab_room.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_main.add_child(tab_room)
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
	var tools := HBoxContainer.new()
	tools.name = "ShopTools"
	tools.add_theme_constant_override("separation", 8)
	_main.add_child(tools)
	sell_open = _button(tools, "SellOpen", _open_sell)
	sell_open.custom_minimum_size = Vector2(0, 56)
	sell_open.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details_button = _button(tools, "ShopDetails", func():
		_details_open = not _details_open
		_show_details())
	details_button.custom_minimum_size = Vector2(0, 56)
	details_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details_button.size_flags_stretch_ratio = 1.5
	_main.move_child(summary, -1) # actions, message, Sell and Details, then the payout
	rack_label = _label(_main, "RackSummary", 20)
	rack_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# A dimmed layer under the two sheets; a tap on it closes them.
	_dim = ColorRect.new()
	_dim.name = "SheetDim"
	_dim.color = Color(0.03, 0.05, 0.08, 0.6)
	_dim.top_level = true
	_dim.hide()
	_dim.gui_input.connect(func(event):
		if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
			close_offer()
			close_sell())
	add_child(_dim)
	# The Sell sheet: everything that can be sold (and the Charm order), in rows.
	sell_sheet = _sheet("SellSheet")
	var sell_box := VBoxContainer.new()
	sell_box.add_theme_constant_override("separation", 10)
	sell_sheet.add_child(sell_box)
	sell_title = _label(sell_box, "SellTitle", 26)
	sell_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var sell_scroll := ScrollContainer.new()
	sell_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sell_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sell_scroll.follow_focus = true
	sell_box.add_child(sell_scroll)
	owned_list = VBoxContainer.new()
	owned_list.name = "Owned"
	owned_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	owned_list.add_theme_constant_override("separation", 6)
	sell_scroll.add_child(owned_list)
	sell_close = _button(sell_box, "SellClose", close_sell)
	sell_close.text = "Done"
	sell_close.custom_minimum_size = Vector2(0, 56)
	# The offer sheet: the card large, its full text and price, Buy and Back.
	offer_sheet = _sheet("OfferSheet")
	var offer_box := VBoxContainer.new()
	offer_box.add_theme_constant_override("separation", 8)
	offer_sheet.add_child(offer_box)
	offer_title = _label(offer_box, "OfferTitle", 28)
	offer_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	offer_card = CardView.new()
	offer_card.name = "OfferCard"
	offer_card.focus_mode = Control.FOCUS_NONE
	offer_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	offer_card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	offer_box.add_child(offer_card)
	offer_kind = _label(offer_box, "OfferKind", 18)
	offer_kind.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	offer_kind.add_theme_color_override("font_color", UiTheme.BRASS)
	offer_detail = _label(offer_box, "OfferDetail", 22)
	offer_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	offer_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	offer_price = _label(offer_box, "OfferPrice", 22)
	offer_price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	offer_price.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	offer_reason = _label(offer_box, "OfferReason", 20)
	offer_reason.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	offer_reason.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	offer_reason.add_theme_color_override("font_color", Color(1.0, 0.55, 0.45))
	var offer_row := HBoxContainer.new()
	offer_row.alignment = BoxContainer.ALIGNMENT_CENTER
	offer_row.add_theme_constant_override("separation", 12)
	offer_box.add_child(offer_row)
	offer_back = _button(offer_row, "OfferBack", close_offer)
	offer_back.text = "Back"
	offer_back.custom_minimum_size = Vector2(150, 60)
	buy_button = _button(offer_row, "OfferBuy", func():
		var index := _offer_index
		close_offer()
		offer_pressed.emit(index))
	buy_button.custom_minimum_size = Vector2(190, 60)
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

## A sheet over the shop, hidden until opened (the choice sheet's pattern).
func _sheet(node_name: String) -> PanelContainer:
	var sheet := PanelContainer.new()
	sheet.name = node_name
	sheet.add_theme_stylebox_override("panel", UiTheme.frame("menu", 20.0, 16.0))
	sheet.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	sheet.top_level = true
	sheet.hide()
	add_child(sheet)
	return sheet

## Centres a sheet on the screen at up to `wanted` size, over the dimmed layer.
func _fit_sheet(sheet: Control, wanted: Vector2) -> void:
	var screen := get_viewport_rect().size
	_dim.position = Vector2.ZERO
	_dim.size = screen
	_dim.show()
	sheet.size = Vector2(minf(wanted.x, screen.x - 32.0), minf(wanted.y, screen.y - 120.0))
	sheet.position = ((screen - sheet.size) * 0.5).floor()

## A tapped offer opens large, with its full text and price. Buying is the Buy
## button's job; an offer that cannot be bought still opens, and says why.
func open_offer(index: int) -> void:
	if index < 0 or index >= _offers.size() or choice_sheet.visible: return
	var offer: Dictionary = _offers[index]
	if String(offer.get("item_id", "")).is_empty() or offer.state in ["sold", "empty"]: return
	close_sell()
	_offer_index = index
	var screen := get_viewport_rect().size
	var width := floorf(clampf(minf(screen.x - 160.0, (screen.y - 420.0) / CardView.ASPECT), 150.0, 300.0))
	offer_card.custom_minimum_size = Vector2(width, floorf(width * CardView.ASPECT))
	offer_card.set_item(String(offer.item_id), {}, String(offer.get("name", "")))
	offer_card.show_face(true)
	offer_card.set_state("", "", "", String(offer.get("text", "")))
	offer_title.text = String(offer.get("name", ""))
	offer_kind.text = String(offer.get("kind", ""))
	offer_detail.text = String(offer.get("detail", ""))
	offer_price.text = "Costs $%d · you have $%d" % [int(offer.get("price", 0)), _money]
	var reason := String(offer.get("reason", ""))
	offer_reason.text = "" if offer.state == "buy" else "Can't buy: %s." % (reason if not reason.is_empty() else "not available")
	offer_reason.visible = not offer_reason.text.is_empty()
	buy_button.text = "Buy $%d" % int(offer.get("price", 0))
	buy_button.disabled = offer.state != "buy"
	offer_sheet.show()
	(offer_back if buy_button.disabled else buy_button).grab_focus()
	# Wrapped text has no height until it has a width: give the sheet its width,
	# then fit its height once the labels have wrapped.
	_fit_sheet(offer_sheet, Vector2(520.0, 10000.0))
	offer_sheet.modulate.a = 0.0
	for i in 2:
		await get_tree().process_frame
		if not is_inside_tree() or not offer_sheet.visible or _offer_index != index: return
		offer_sheet.size.y = 0.0
		_fit_sheet(offer_sheet, Vector2(520.0, offer_sheet.get_combined_minimum_size().y))
	offer_sheet.modulate.a = 1.0

func close_offer() -> void:
	if not offer_sheet.visible: return
	var index := _offer_index
	_offer_index = -1
	offer_sheet.hide()
	offer_sheet.modulate.a = 1.0
	_dim.visible = sell_sheet.visible
	if index >= 0 and index < offer_buttons.size() and offer_buttons[index].is_visible_in_tree() and not offer_buttons[index].disabled:
		offer_buttons[index].grab_focus()

func _open_sell() -> void:
	if choice_sheet.visible or owned_list.get_child_count() == 0: return
	close_offer()
	sell_sheet.show()
	_fit_sell()
	for child in owned_list.get_children():
		if child is Button:
			child.grab_focus()
			break

func _fit_sell() -> void:
	_fit_sheet(sell_sheet, Vector2(560.0, 62.0 * owned_list.get_child_count() + 150.0))

func close_sell() -> void:
	if not sell_sheet.visible: return
	sell_sheet.hide()
	_dim.visible = offer_sheet.visible
	if sell_open.is_visible_in_tree(): sell_open.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and (offer_sheet.visible or sell_sheet.visible):
		close_offer()
		close_sell()
		get_viewport().set_input_as_handled()

## Offer buttons grow with the offers (E18-C07: Extra Shelf and the License offer).
func _add_offer_button() -> void:
	var i := offer_buttons.size()
	# Offers are UI-1 playing cards; the price is a removable overlay, never on the face.
	var button := CardView.new()
	button.name = "Offer_%d" % i
	button.custom_minimum_size = Vector2(196, 280)
	button.pressed.connect(func(): if not button.consume_long_press(): open_offer(i))
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
		# A phone's three pinned actions fit the panel's width (at the default size
		# their words pushed the panel, and the money, past the screen's edge).
		if _landscape: button.remove_theme_font_size_override("font_size")
		else: button.add_theme_font_size_override("font_size", 19)
	offers_grid.size_flags_horizontal = Control.SIZE_FILL if _landscape else Control.SIZE_SHRINK_CENTER
	var shown := _landscape or _details_open
	summary.visible = shown
	rack_label.visible = shown
	details_button.visible = not _landscape
	details_button.text = "Hide details" if _details_open else "Payout & rack"

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
	preview_short.text = view.get("preview_short", preview.text.get_slice("\n", 0))
	money.text = "$%d" % view.money
	_offers = view.offers
	_money = int(view.money)
	if offer_sheet.visible and (choice_sheet.visible or _offer_index >= _offers.size()): close_offer()
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
			_main.move_child(offers_grid, _main.get_node("TabRoom").get_index() + 1)
		_shelf.visible = landscape
		_scroll_home.call_deferred()
	offers_grid.columns = view.get("columns", 3)
	while offer_buttons.size() < view.offers.size():
		_add_offer_button()
	# Portrait keeps the cards compact so the actions and sales stay on screen;
	# landscape sizes the shelf's cards to fit every row on screen.
	var card_size := Vector2(105, 150)
	if not landscape:
		# UI-3: three columns as wide as the panel allows (up to 150 px), short
		# enough that every row of offers shows above the pinned actions.
		# From the panel's anchored size, known before its first layout, so the cards
		# never resize under a tap a frame later.
		var area := get_parent_area_size() - Vector2(offset_left - offset_right, offset_top - offset_bottom)
		var rows := ceili(view.offers.size() / 3.0)
		var room := area.y - 32.0 - 68.0 - 150.0 - 8.0 * (rows - 1) # margins, pinned actions, heading
		var height := clampf(room / maxf(rows, 1), 150.0, 214.0)
		var width := floorf(minf(minf(150.0, (area.x - 40.0 - 14.0 - 16.0) / 3.0), height / CardView.ASPECT))
		card_size = Vector2(width, floorf(width * CardView.ASPECT))
	if landscape:
		var rows := ceili(view.offers.size() / float(offers_grid.columns))
		var room := (get_parent_area_size().y - offset_top + offset_bottom) - 40.0 - 8.0 * (rows - 1)
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
		# Any offer that is still for sale opens to be read; Buy says if it can be bought.
		button.disabled = offer.state in ["sold", "empty"] or item_id.is_empty() or choice_sheet.visible
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
	# One Sell control for all of it; the sheet stays open across sales until it is empty.
	var moves: int = view.get("charm_moves", []).size()
	sell_open.text = ("Sell · %d" % view.sellables.size()) if moves == 0 else "Sell · %d · order" % view.sellables.size()
	sell_open.disabled = (view.sellables.is_empty() and moves == 0) or choice_sheet.visible
	sell_title.text = "Sell" if moves == 0 else "Sell, or change the Charm order"
	if sell_sheet.visible:
		if sell_open.disabled: close_sell()
		else: _fit_sell.call_deferred()

## After a reflow the focused action scrolls into view against the old layout
## (follow_focus), which hid the title when a shop first opened in landscape.
## Once the new layout has settled the shop starts from its top.
func _scroll_home() -> void:
	await get_tree().process_frame
	if is_inside_tree(): _scroll.scroll_vertical = 0

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
