extends PanelContainer
## Between-match Pro Shop (E08): the match settlement, five offers, reroll, the
## card-removal service, selling, and a choice sheet for placements (including
## explicit replacements) with Cancel. A view only: the lab and the pure Shop and
## RunInventory own every rule and number. Touch, mouse and keyboard/gamepad focus
## all work. Developmental look; card art and foil are E12/E19.
const Sentence = preload("res://src/presentation/sentence.gd")
const ItemAssets = preload("res://src/presentation/item_assets.gd")
const CardView = preload("res://src/presentation/card_view.gd")
const UiTheme = preload("res://src/presentation/house_ui_theme.gd")
const ModArt = preload("res://src/presentation/modification_art.gd")
## UI-12 (owner's play notes, 2026-11-16): placing an item shows a map of the rack
## (each pin with its art and modification badge) and the other places as tiles; a
## tap selects one and shows what is there now and what will change, and Confirm
## applies it. Sell shows the owned items as tiles; a tap opens the item with a Sell
## confirmation. Keyboard and gamepad focus shows the same detail and accept applies,
## as before. The bowling triangle, back row first, as the player sees it down the lane.
const RACK_ROWS := [[7, 8, 9, 10], [4, 5, 6], [2, 3], [1]]
signal offer_pressed(index: int)
signal reroll_pressed
signal remove_pressed
signal sell_pressed(ref: String)
signal continue_pressed
signal choice_made(index: int)
signal choice_cancelled
signal charm_reordered(from_slot: int, to_slot: int) # UI-32: 1-based Charm slots

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
var owned_list: Container # UI-12: the Sell tiles (HFlowContainer "Owned")
var charm_box: VBoxContainer # UI-32: the Inventory's Charm section (heading, row, hint), first
var charm_row: HBoxContainer # the Charms in scoring order, reordered by drag and drop
var charm_hint: Label
var items_heading: Label
var ledger: PanelContainer # UI-32: the payout and rack, as a slip (summary and rack_label keep the text)
var _dragging_charm := false
var _refocus_charm := 0
var sell_detail: Label
var sell_confirm_sheet: PanelContainer
var sell_card: CardView
var sell_confirm_title: Label
var sell_confirm_text: Label
var sell_confirm: Button
var sell_back: Button
var _sell_pending := ""
var _sellables: Dictionary = {} # ref -> the view's sellable entry
var choice_map: VBoxContainer
var choice_others: HFlowContainer
var choice_detail: Label
var choice_confirm: Button
var _choice_labels: Array = []
var _choice_visuals: Array = []
var _choice_selected := -1
var _pointer := false # the last press came from a finger or the mouse, not focus and accept
var choice_touched := false # a finger or the mouse picked a place (not only focus) since the sheet opened
var _opening := false # the sheet's first focus is not a pick
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
		_show_details()
		if _details_open: _reveal_ledger()) # UI-32: the slip opens into view
	details_button.custom_minimum_size = Vector2(0, 56)
	details_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details_button.size_flags_stretch_ratio = 1.5
	_main.move_child(summary, -1) # actions, message, Inventory and Details, then the payout
	rack_label = _label(_main, "RackSummary", 20)
	rack_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# UI-32 (owner, 2026-11-20): the payout and the rack as a themed slip. The two
	# labels stay, hidden, with the full text (tools, tests and the art hooks read it).
	ledger = PanelContainer.new()
	ledger.name = "PayoutRack"
	ledger.add_theme_stylebox_override("panel", UiTheme.frame("slip", 18.0, 14.0))
	_main.add_child(ledger)
	_main.move_child(ledger, summary.get_index())
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
	var sell_column := VBoxContainer.new()
	sell_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sell_column.add_theme_constant_override("separation", 10)
	sell_scroll.add_child(sell_column)
	# UI-32 (owner, 2026-11-20): the Charms first, in a row in scoring order, reordered
	# by drag and drop (Shift+Left/Right with keyboard focus); the other items below.
	# A tap on any item opens it to review or sell, as before.
	charm_box = VBoxContainer.new()
	charm_box.name = "CharmSection"
	charm_box.add_theme_constant_override("separation", 6)
	sell_column.add_child(charm_box)
	var charm_heading := _label(charm_box, "CharmHeading", 20)
	charm_heading.text = "Charms · scored left to right"
	charm_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	charm_heading.add_theme_color_override("font_color", UiTheme.BRASS)
	charm_row = HBoxContainer.new()
	charm_row.name = "CharmRow"
	charm_row.alignment = BoxContainer.ALIGNMENT_CENTER
	charm_row.add_theme_constant_override("separation", 6)
	charm_box.add_child(charm_row)
	charm_hint = _label(charm_box, "CharmHint", 16)
	charm_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	charm_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	charm_hint.add_theme_color_override("font_color", Color("9aa8a6"))
	items_heading = _label(sell_column, "ItemsHeading", 20)
	items_heading.text = "Your Items"
	items_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	items_heading.add_theme_color_override("font_color", UiTheme.BRASS)
	var flow := HFlowContainer.new()
	flow.name = "Owned"
	flow.alignment = FlowContainer.ALIGNMENT_CENTER
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flow.add_theme_constant_override("h_separation", 8)
	flow.add_theme_constant_override("v_separation", 8)
	sell_column.add_child(flow)
	owned_list = flow
	sell_detail = _label(sell_box, "SellDetail", 18)
	sell_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sell_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sell_detail.add_theme_color_override("font_color", Color("9aa8a6"))
	sell_close = _button(sell_box, "SellClose", close_sell)
	sell_close.text = "Done"
	sell_close.custom_minimum_size = Vector2(0, 56)
	# UI-12: a tapped item opens large, with what it is, where it sits and its price.
	sell_confirm_sheet = _sheet("SellConfirm")
	var confirm_box := VBoxContainer.new()
	confirm_box.add_theme_constant_override("separation", 8)
	sell_confirm_sheet.add_child(confirm_box)
	sell_confirm_title = _label(confirm_box, "SellConfirmTitle", 28)
	sell_confirm_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sell_card = CardView.new()
	sell_card.name = "SellCard"
	sell_card.focus_mode = Control.FOCUS_NONE
	sell_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sell_card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	confirm_box.add_child(sell_card)
	sell_confirm_text = _label(confirm_box, "SellConfirmText", 22)
	sell_confirm_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sell_confirm_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var confirm_row := HBoxContainer.new()
	confirm_row.alignment = BoxContainer.ALIGNMENT_CENTER
	confirm_row.add_theme_constant_override("separation", 12)
	confirm_box.add_child(confirm_row)
	sell_back = _button(confirm_row, "SellBack", close_sell_confirm)
	sell_back.text = "Back"
	sell_back.custom_minimum_size = Vector2(150, 60)
	sell_confirm = _button(confirm_row, "SellConfirmButton", func():
		var ref := _sell_pending
		close_sell_confirm()
		if not ref.is_empty(): call_deferred("emit_signal", "sell_pressed", ref))
	sell_confirm.custom_minimum_size = Vector2(190, 60)
	# The offer sheet: the card large, its full text and price, Buy and Back.
	offer_sheet = _sheet("OfferSheet")
	var offer_box := VBoxContainer.new()
	offer_box.add_theme_constant_override("separation", 8)
	offer_sheet.add_child(offer_box)
	# UI-26 (owner, 2026-11-19): the price sits at the top right, beside the name.
	var offer_head := HBoxContainer.new()
	offer_head.name = "OfferHead"
	offer_box.add_child(offer_head)
	var balance := Control.new() # matches the price's side, so the name stays centred
	balance.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	balance.size_flags_stretch_ratio = 0.3
	offer_head.add_child(balance)
	offer_title = _label(offer_head, "OfferTitle", 28)
	offer_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	offer_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	offer_price = _label(offer_head, "OfferPrice", 28)
	offer_price.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	offer_price.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	offer_price.size_flags_stretch_ratio = 0.3
	offer_price.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
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
	choice_map = VBoxContainer.new()
	choice_map.name = "RackMap"
	choice_map.add_theme_constant_override("separation", 6)
	sheet.add_child(choice_map)
	choice_others = HFlowContainer.new()
	choice_others.name = "OtherPlaces"
	choice_others.alignment = FlowContainer.ALIGNMENT_CENTER
	choice_others.add_theme_constant_override("h_separation", 8)
	choice_others.add_theme_constant_override("v_separation", 8)
	sheet.add_child(choice_others)
	choice_detail = _label(sheet, "ChoiceDetail", 20)
	choice_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	choice_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	choice_detail.custom_minimum_size.y = 56
	var choice_row := HBoxContainer.new()
	choice_row.alignment = BoxContainer.ALIGNMENT_CENTER
	choice_row.add_theme_constant_override("separation", 12)
	sheet.add_child(choice_row)
	cancel_choice = _button(choice_row, "CancelChoice", func(): choice_cancelled.emit())
	cancel_choice.text = "Cancel"
	cancel_choice.custom_minimum_size = Vector2(150, 60)
	choice_confirm = _button(choice_row, "ConfirmChoice", func():
		if _choice_selected >= 0: call_deferred("emit_signal", "choice_made", _choice_selected))
	choice_confirm.text = "Confirm"
	choice_confirm.custom_minimum_size = Vector2(190, 60)

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
	offer_price.text = "$%d" % int(offer.get("price", 0))
	var reason := String(offer.get("reason", ""))
	offer_reason.text = "" if offer.state == "buy" else "Can't buy: %s." % Sentence.cap(reason if not reason.is_empty() else "not available")
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
	if choice_sheet.visible or owned_list.get_child_count() + charm_row.get_child_count() == 0: return
	close_offer()
	sell_sheet.show()
	_fit_sell()
	for child in charm_row.get_children() + owned_list.get_children():
		if child is Button:
			child.grab_focus()
			break

func _fit_sell() -> void:
	var screen := get_viewport_rect().size
	var columns := maxi(1, int((minf(560.0, screen.x - 32.0) - 48.0 + 8.0) / (_sell_tile_size().x + 8.0)))
	var rows := ceili(owned_list.get_child_count() / float(columns))
	var charms := (_charm_tile_size().y + 90.0) if charm_box.visible else 0.0
	var items := ((_sell_tile_size().y + 8.0) * rows + 36.0) if owned_list.get_child_count() > 0 else 0.0
	_fit_sheet(sell_sheet, Vector2(560.0, charms + items + 190.0))

## Five Charms fit one row on a phone.
func _charm_tile_size() -> Vector2:
	var screen := get_viewport_rect().size
	var width := floorf(clampf((minf(560.0, screen.x - 32.0) - 60.0 - 6.0 * 4.0) / 5.0, 64.0, 100.0))
	return Vector2(width, floorf(width * 1.22))

func _sell_tile_size() -> Vector2:
	var screen := get_viewport_rect().size
	return Vector2(112, 128) if screen.y >= 820.0 else Vector2(96, 108)

## The tapped item, large, with its place, modification and price; Sell confirms.
func open_sell_confirm(ref: String) -> void:
	var owned: Dictionary = _sellables.get(ref, {})
	if owned.is_empty(): return
	_sell_pending = ref
	var screen := get_viewport_rect().size
	var width := floorf(clampf(minf(screen.x - 200.0, (screen.y - 420.0) / CardView.ASPECT), 120.0, 240.0))
	sell_card.custom_minimum_size = Vector2(width, floorf(width * CardView.ASPECT))
	var item_id := String(owned.get("item_id", ""))
	sell_card.visible = not item_id.is_empty()
	if sell_card.visible:
		sell_card.set_item(item_id, {}, String(owned.get("name", "")))
		sell_card.show_face(true)
		sell_card.set_state("", "", "", String(owned.get("text", "")))
	sell_confirm_title.text = String(owned.get("name", owned.label))
	sell_confirm_text.text = String(owned.get("detail", owned.label))
	sell_confirm.text = "Sell +$%d" % int(owned.get("value", 0))
	sell_confirm_sheet.show()
	sell_confirm.grab_focus()
	_fit_sheet(sell_confirm_sheet, Vector2(480.0, 10000.0))
	sell_confirm_sheet.modulate.a = 0.0
	for i in 2:
		await get_tree().process_frame
		if not is_inside_tree() or not sell_confirm_sheet.visible or _sell_pending != ref: return
		sell_confirm_sheet.size.y = 0.0
		_fit_sheet(sell_confirm_sheet, Vector2(480.0, sell_confirm_sheet.get_combined_minimum_size().y))
	sell_confirm_sheet.modulate.a = 1.0

func close_sell_confirm() -> void:
	if not sell_confirm_sheet.visible: return
	var ref := _sell_pending
	_sell_pending = ""
	sell_confirm_sheet.hide()
	sell_confirm_sheet.modulate.a = 1.0
	_dim.visible = sell_sheet.visible or offer_sheet.visible
	var tile := sell_button(ref)
	if tile != null and tile.is_visible_in_tree(): tile.grab_focus()

## A square tile: the item's art, its modification's badge, a short caption. A press
## from a finger or the mouse is told apart from focus and accept (_pointer).
func _tile(parent: Control, node_name: String, item_id: String, mod: String, caption: String, tile_size: Vector2) -> Button:
	var tile := Button.new()
	tile.name = node_name
	tile.text = caption
	tile.custom_minimum_size = tile_size
	tile.set_meta("art_tile", true) # ModificationArt badges it but keeps its art
	tile.icon = ItemAssets.slot(item_id, "icon") as Texture2D if not item_id.is_empty() else null
	tile.set_meta("own_icon", tile.icon)
	tile.expand_icon = true
	tile.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tile.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	tile.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tile.clip_text = true
	tile.add_theme_font_size_override("font_size", 15)
	tile.add_theme_constant_override("icon_max_width", int(tile_size.x * 0.62))
	tile.gui_input.connect(func(event): _pointer = event is InputEventMouseButton or event is InputEventScreenTouch)
	parent.add_child(tile)
	if not mod.is_empty(): ModArt._badge(tile, mod, int(tile_size.x * 0.24))
	var ring := Panel.new()
	ring.name = "Selected"
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.draw_center = false
	style.border_color = UiTheme.BRASS
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	ring.add_theme_stylebox_override("panel", style)
	ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ring.hide()
	tile.add_child(ring)
	return tile

## The control to press to finish what a tap began (journeys use it after a tap).
func pending_confirm(control) -> Button:
	if not is_instance_valid(control): return null
	if choice_sheet.visible and _choice_selected >= 0 and control == choice_button(_choice_selected): return choice_confirm
	if sell_confirm_sheet.visible and not _sell_pending.is_empty() and control == sell_button(_sell_pending): return sell_confirm
	return null

func close_sell() -> void:
	if not sell_sheet.visible: return
	close_sell_confirm()
	sell_sheet.hide()
	_dim.visible = offer_sheet.visible
	if sell_open.is_visible_in_tree(): sell_open.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and sell_confirm_sheet.visible:
		close_sell_confirm()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") and (offer_sheet.visible or sell_sheet.visible):
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
	summary.visible = false # UI-32: the slip shows them; the labels keep the text
	rack_label.visible = false
	ledger.visible = shown
	details_button.visible = not _landscape
	details_button.text = "Hide Details" if _details_open else "Payout & Rack"

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
## removal_price, can_remove, rack, sellables: [{ref, label, item_id, mod, name, value,
## detail}] (Charms by their `charm:N` refs, in the Inventory's Charm row), payout and
## holdings (UI-32's slip, see _build_ledger), message, columns}.
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
	remove_button.text = "Remove a Card $%d" % view.removal_price
	remove_button.disabled = not view.can_remove or choice_sheet.visible
	continue_button.disabled = choice_sheet.visible
	message.text = view.get("message", "")
	var refused: bool = message.text.begins_with("Can't")
	message.add_theme_color_override("font_color", Color(1.0, 0.55, 0.45) if refused else Color(0.6, 0.95, 0.7))
	rack_label.text = view.rack
	_build_ledger(view)
	var focused_ref := ""
	var focused := get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	for box in [owned_list, charm_row]:
		for child in box.get_children():
			if child == focused: focused_ref = String(child.get_meta("ref", ""))
			box.remove_child(child)
			child.queue_free()
	_sellables = {}
	var charms: Array = view.sellables.filter(func(o): return String(o.ref).begins_with("charm:"))
	charms.sort_custom(func(a, b): return int(String(a.ref).get_slice(":", 1)) < int(String(b.ref).get_slice(":", 1)))
	var others: Array = view.sellables.filter(func(o): return not String(o.ref).begins_with("charm:"))
	for owned in charms + others:
		var ref: String = owned.ref
		_sellables[ref] = owned
		var is_charm := ref.begins_with("charm:")
		var caption := "%s\n+$%d" % [String(owned.get("name", owned.label)), int(owned.get("value", 0))] if owned.has("value") else String(owned.label)
		var tile := _tile(charm_row if is_charm else owned_list, "Sell_" + ref.replace(":", "_").replace("-", "_"), String(owned.get("item_id", "")),
			String(owned.get("mod", "")), caption, _charm_tile_size() if is_charm else _sell_tile_size())
		tile.set_meta("ref", ref)
		tile.tooltip_text = owned.label
		tile.disabled = choice_sheet.visible
		# A tap opens the item to confirm; accept sells at once (deferred: selling
		# rebuilds these tiles, so the pressed one must not vanish mid-input).
		tile.pressed.connect(func():
			var by_pointer := _pointer
			_pointer = false
			if _dragging_charm: return # the release that ended a drag is not a tap
			if by_pointer: open_sell_confirm(ref)
			else: call_deferred("emit_signal", "sell_pressed", ref))
		tile.focus_entered.connect(func(): sell_detail.text = String(owned.get("detail", owned.label)))
		if is_charm:
			var slot := int(ref.get_slice(":", 1))
			tile.add_theme_font_size_override("font_size", 13)
			var number := Label.new() # the scoring position
			number.name = "Slot"
			number.text = str(slot)
			number.mouse_filter = Control.MOUSE_FILTER_IGNORE
			number.add_theme_font_size_override("font_size", 14)
			number.add_theme_color_override("font_color", UiTheme.BRASS)
			number.position = Vector2(6, 2)
			tile.add_child(number)
			tile.set_drag_forwarding(func(_at): return _charm_drag(slot, tile),
				func(_at, data): return _charm_droppable(data, slot),
				func(_at, data): _charm_drop(data, slot))
			# Keyboard and gamepad: Shift+Left/Right moves the focused Charm.
			tile.gui_input.connect(func(event):
				if event is InputEventKey and event.pressed and event.shift_pressed and event.keycode in [KEY_LEFT, KEY_RIGHT]:
					var to := slot + (-1 if event.keycode == KEY_LEFT else 1)
					tile.accept_event()
					if to >= 1 and to <= charms.size() and not choice_sheet.visible:
						_refocus_charm = to
						charm_reordered.emit.call_deferred(slot, to))
	charm_box.visible = not charms.is_empty()
	charm_hint.text = "Drag a Charm to change the order. Tap any item to review or sell it." if charms.size() > 1 else "Tap any item to review or sell it."
	items_heading.visible = not others.is_empty() and not charms.is_empty()
	sell_detail.text = "" if view.sellables.is_empty() else ("Tap an item to review or sell it." if charms.size() < 2 else "")
	if sell_confirm_sheet.visible and not _sellables.has(_sell_pending): close_sell_confirm()
	# One Inventory control for all of it; the sheet stays open across sales and moves.
	sell_open.text = "Inventory"
	sell_open.disabled = view.sellables.is_empty() or choice_sheet.visible
	sell_title.text = "Inventory"
	if sell_sheet.visible:
		if sell_open.disabled: close_sell()
		else:
			_fit_sell.call_deferred()
			var back: Button = charm_tile(_refocus_charm) if _refocus_charm > 0 else (sell_button(focused_ref) if not focused_ref.is_empty() else null)
			if back != null: back.grab_focus.call_deferred()
	_refocus_charm = 0

## After a reflow the focused action scrolls into view against the old layout
## (follow_focus), which hid the title when a shop first opened in landscape.
## Once the new layout has settled the shop starts from its top.
func _scroll_home() -> void:
	await get_tree().process_frame
	if is_inside_tree(): _scroll.scroll_vertical = 0

## labels: one line per choice (also the tile's tooltip). visuals (UI-12), one per
## choice: {target, item_id, mod, caption, detail, verb}; rack: the ten pins as
## {item_id, mod}, for the map's pins that are not choices. Without visuals the
## choices are a list of rows, each applied at once.
func show_choices(prompt: String, labels: Array, visuals: Array = [], rack: Array = []) -> void:
	choice_prompt.text = prompt
	_choice_labels = labels
	_choice_visuals = visuals
	_choice_selected = -1
	choice_touched = false
	for box in [choice_list, choice_map, choice_others]:
		for child in box.get_children():
			box.remove_child(child)
			child.queue_free()
	var visual := visuals.size() == labels.size() and not labels.is_empty()
	choice_list.visible = not visual
	choice_map.visible = false
	choice_others.visible = visual
	choice_detail.visible = visual
	choice_confirm.visible = visual
	choice_confirm.disabled = true
	choice_detail.text = "Tap a place to see what is there." if visual else ""
	var viewport_size := get_viewport_rect().size
	var width := minf(600.0, viewport_size.x - 32.0)
	choice_sheet.get_child(0).custom_minimum_size.x = width - 40.0
	if not visual:
		for i in labels.size():
			var index := i
			var button := _button(choice_list, "Choice_%d" % i, func(): choice_made.emit(index), CONNECT_DEFERRED)
			button.text = labels[i]
			button.custom_minimum_size = Vector2(0, 56)
	else:
		var by_target := {}
		for i in visuals.size():
			by_target[String(visuals[i].get("target", ""))] = i
		var pin := floorf(clampf((width - 40.0 - 24.0) / 4.0, 64.0, 104.0))
		if viewport_size.y < viewport_size.x: pin = floorf(clampf((viewport_size.y - 380.0) / 4.4, 52.0, 88.0))
		var pin_size := Vector2(pin, floorf(pin * 1.08))
		var on_rack: bool = visuals.any(func(v): return String(v.get("target", "")).begins_with("rack:"))
		choice_map.visible = on_rack
		if on_rack:
			for row_positions in RACK_ROWS:
				var row := HBoxContainer.new()
				row.alignment = BoxContainer.ALIGNMENT_CENTER
				row.add_theme_constant_override("separation", 6)
				choice_map.add_child(row)
				for position in row_positions:
					var target := "rack:%d" % position
					if by_target.has(target):
						_choice_tile(row, by_target[target], pin_size)
					else:
						# A pin that is not a choice: shown for the map, not pressable.
						var here: Dictionary = rack[position - 1] if rack.size() >= position else {}
						var still := _tile(row, "Pin_%d" % position, String(here.get("item_id", "")), String(here.get("mod", "")), str(position), pin_size)
						still.disabled = true
						still.focus_mode = Control.FOCUS_NONE
						still.modulate.a = 0.55
		for i in visuals.size():
			if not String(visuals[i].get("target", "")).begins_with("rack:"):
				_choice_tile(choice_others, i, Vector2(floorf(pin * 1.15), floorf(pin * 1.2)))
		choice_others.visible = choice_others.get_child_count() > 0
	choice_sheet.show()
	choice_sheet.size = Vector2(width, minf(64.0 * (labels.size() + 2) + 60.0, viewport_size.y - 160.0))
	choice_sheet.position = ((viewport_size - choice_sheet.size) * 0.5).floor()
	if labels.is_empty():
		cancel_choice.grab_focus()
	else:
		# UI-13 (owner, 2026-11-17): the map opens with nothing picked, so a preview
		# appears only on the pin the player touches (or moves focus to).
		_opening = true
		choice_button(0).grab_focus()
		_opening = false
	if visual: _fit_choices.call_deferred()

## The visual sheet's height is known once its tiles are laid out.
func _fit_choices() -> void:
	await get_tree().process_frame
	if not is_inside_tree() or not choice_sheet.visible: return
	var viewport_size := get_viewport_rect().size
	var content: Control = choice_sheet.get_child(0).get_child(0)
	choice_sheet.size.y = minf(content.get_combined_minimum_size().y + 40.0, viewport_size.y - 48.0)
	choice_sheet.position = ((viewport_size - choice_sheet.size) * 0.5).floor()

func _choice_tile(parent: Control, index: int, tile_size: Vector2) -> Button:
	var v: Dictionary = _choice_visuals[index]
	var tile := _tile(parent, "Choice_%d" % index, String(v.get("item_id", "")), String(v.get("mod", "")), String(v.get("caption", str(index + 1))), tile_size)
	tile.tooltip_text = _choice_labels[index]
	tile.pressed.connect(func():
		var by_pointer := _pointer
		_pointer = false
		if by_pointer:
			choice_touched = true
			select_choice(index)
		else: call_deferred("emit_signal", "choice_made", index))
	tile.focus_entered.connect(func(): if not _opening: select_choice(index))
	return tile

## Shows what is at a place now and what the choice will do; Confirm applies it.
func select_choice(index: int) -> void:
	if index < 0 or index >= _choice_visuals.size(): return
	if _choice_selected >= 0 and _choice_selected != index: _preview(_choice_selected, false)
	_choice_selected = index
	_preview(index, true)
	for i in _choice_visuals.size():
		var tile := choice_button(i)
		if tile != null: tile.get_node("Selected").visible = i == index
	choice_detail.text = String(_choice_visuals[index].get("detail", _choice_labels[index]))
	choice_confirm.text = String(_choice_visuals[index].get("verb", "Confirm"))
	choice_confirm.disabled = false

## UI-13 (owner, 2026-11-17): the picked place shows what is about to go there: a
## modification's badge on the pin, or the new item's art in the place. A new pin
## keeps the place's modification badge when it takes the modification over
## (UI-30); otherwise the badge leaves with the old pin. Picking another place
## restores this one.
func _preview(index: int, on: bool) -> void:
	var v: Dictionary = _choice_visuals[index]
	var tile := choice_button(index)
	var placing := String(v.get("placing", ""))
	if tile == null or placing.is_empty(): return
	var extent := int(tile.custom_minimum_size.x * 0.24)
	if bool(v.get("placing_mod", false)):
		# Larger while previewed, so the new modification reads at a glance.
		ModArt._badge(tile, placing if on else String(v.get("mod", "")), int(tile.custom_minimum_size.x * 0.46) if on else extent)
	else:
		tile.icon = (ItemAssets.slot(placing, "icon") as Texture2D) if on else tile.get_meta("own_icon", null)
		ModArt._badge(tile, String(v.get("keeps_mod", "")) if on else String(v.get("mod", "")), extent)
	tile.set_meta("previewing", placing if on else "")
	if on and is_inside_tree():
		tile.pivot_offset = tile.size * 0.5
		tile.scale = Vector2(1.08, 1.08)
		create_tween().tween_property(tile, "scale", Vector2.ONE, 0.18)

func choice_count() -> int:
	return _choice_labels.size() if choice_sheet.visible else 0

func choice_label(index: int) -> String:
	return String(_choice_labels[index]) if index >= 0 and index < _choice_labels.size() else ""

func hide_choices() -> void:
	choice_sheet.hide()
	_choice_selected = -1

func button_for_offer(index: int) -> Button:
	return offer_buttons[index]

func choice_button(index: int) -> Button:
	return choice_sheet.find_child("Choice_%d" % index, true, false) as Button

## The Inventory tile for an owned item (a Charm's is in the Charm row).
func sell_button(ref: String) -> Button:
	var node_name := "Sell_" + ref.replace(":", "_").replace("-", "_")
	return (charm_row.get_node_or_null(node_name) if ref.begins_with("charm:") else owned_list.get_node_or_null(node_name)) as Button

## The Charm tile at a 1-based slot.
func charm_tile(slot: int) -> Button:
	return charm_row.get_node_or_null("Sell_charm_%d" % slot) as Button

# --- UI-32: the Charm row's drag and drop ------------------------------------

func _charm_drag(slot: int, tile: Button) -> Variant:
	if choice_sheet.visible or charm_row.get_child_count() < 2: return null
	_dragging_charm = true
	var ghost := TextureRect.new()
	ghost.texture = tile.icon
	ghost.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ghost.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ghost.size = tile.size * 0.9
	ghost.position = -ghost.size * 0.5
	ghost.modulate.a = 0.85
	var holder := Control.new() # centred on the finger
	holder.add_child(ghost)
	set_drag_preview(holder)
	tile.modulate.a = 0.4
	return {"charm_slot": slot}

func _charm_droppable(data: Variant, slot: int) -> bool:
	var ok: bool = data is Dictionary and data.has("charm_slot")
	for i in charm_row.get_child_count():
		var ring := charm_row.get_child(i).get_node_or_null("Selected")
		if ring != null: ring.visible = ok and i + 1 == slot and int(data.charm_slot) != slot
	return ok

func _charm_drop(data: Variant, slot: int) -> void:
	_end_charm_drag()
	var from := int(data.get("charm_slot", 0)) if data is Dictionary else 0
	if from > 0 and from != slot:
		_refocus_charm = slot
		charm_reordered.emit.call_deferred(from, slot) # the row is rebuilt by the result

func _end_charm_drag() -> void:
	for tile in charm_row.get_children():
		tile.modulate.a = 1.0
		var ring := tile.get_node_or_null("Selected")
		if ring != null: ring.hide()

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and _dragging_charm:
		_end_charm_drag()
		# A drag ends with the button's release; that release is not a tap.
		(func(): _dragging_charm = false).call_deferred()

# --- UI-32: the payout and rack slip -----------------------------------------

## Scrolls the shop so the opened slip starts at the top of the view.
func _reveal_ledger() -> void:
	for i in 2: await get_tree().process_frame
	if is_inside_tree() and ledger.visible:
		_scroll.scroll_vertical = int(maxf(0.0, ledger.position.y - 8.0))

const INK := Color("2a221c") # dark inks on the cream slip
const RUST := Color("8a4419")
const EARNED := Color("2f6b3a")

## view.payout: {match, payout, interest, held, item_income, notes}; view.holdings:
## {pins: [{item_id, mod, name}] by position, reserves: [{item_id, mod, name} or {}],
## charms: [n, max], deck: [n, max], rack_line, upgrades}.
func _build_ledger(view: Dictionary) -> void:
	for child in ledger.get_children():
		ledger.remove_child(child)
		child.queue_free()
	var pay: Dictionary = view.get("payout", {})
	var held: Dictionary = view.get("holdings", {})
	var column := VBoxContainer.new()
	column.name = "Slip"
	column.add_theme_constant_override("separation", 8)
	ledger.add_child(column)
	if not pay.is_empty():
		var head := HBoxContainer.new()
		head.name = "PayoutHead"
		column.add_child(head)
		var title_label := _ink(head, "PayoutTitle", "MATCH %d PAYOUT" % int(pay.get("match", 0)), 22, RUST)
		title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var total := int(pay.get("payout", 0)) + int(pay.get("interest", 0)) + int(pay.get("item_income", 0))
		_ink(head, "PayoutTotal", "+$%d" % total, 28, EARNED)
		var rows := GridContainer.new()
		rows.name = "PayoutRows"
		rows.columns = 2
		rows.add_theme_constant_override("h_separation", 12)
		rows.add_theme_constant_override("v_separation", 2)
		column.add_child(rows)
		var lines := [["Match payout", int(pay.get("payout", 0))], ["Interest · on $%d held" % int(pay.get("held", 0)), int(pay.get("interest", 0))],
			["Item income · during the match", int(pay.get("item_income", 0))]]
		for i in lines.size():
			var line: Array = lines[i]
			_ink(rows, "Line_%d" % i, line[0], 18, INK).size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var amount := _ink(rows, "Amount_%d" % i, "$%d" % line[1], 18, INK if line[1] == 0 else EARNED)
			amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		for note in pay.get("notes", []):
			_ink(column, "Note_%d" % column.get_child_count(), String(note), 16, RUST).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var rule := ColorRect.new()
		rule.name = "Rule"
		rule.color = Color(INK, 0.35)
		rule.custom_minimum_size = Vector2(0, 2)
		column.add_child(rule)
	if held.is_empty(): return
	_ink(column, "RackTitle", "YOUR RACK", 22, RUST)
	var body := HBoxContainer.new()
	body.name = "RackBody"
	body.add_theme_constant_override("separation", 14)
	column.add_child(body)
	# The rack as the player sees it down the lane: back row first.
	var triangle := VBoxContainer.new()
	triangle.name = "RackTriangle"
	triangle.add_theme_constant_override("separation", 2)
	body.add_child(triangle)
	var pins: Array = held.get("pins", [])
	for row in RACK_ROWS:
		var line := HBoxContainer.new()
		line.alignment = BoxContainer.ALIGNMENT_CENTER
		line.add_theme_constant_override("separation", 2)
		triangle.add_child(line)
		for position in row:
			var pin: Dictionary = pins[position - 1] if position - 1 < pins.size() else {}
			line.add_child(_pin_icon("Pin_%d" % position, pin, Vector2(30, 36)))
	var side := VBoxContainer.new()
	side.name = "RackSide"
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.add_theme_constant_override("separation", 6)
	body.add_child(side)
	_ink(side, "RackLine", String(held.get("rack_line", "")), 17, INK).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var reserve_row := HBoxContainer.new()
	reserve_row.name = "Reserves"
	reserve_row.add_theme_constant_override("separation", 4)
	side.add_child(reserve_row)
	_ink(reserve_row, "ReservesLabel", "Reserves", 16, INK)
	var reserves: Array = held.get("reserves", [])
	for i in reserves.size():
		var slot := PanelContainer.new()
		slot.name = "Reserve_%d" % (i + 1)
		var frame := StyleBoxFlat.new()
		frame.bg_color = Color(INK, 0.08)
		frame.border_color = Color(INK, 0.45)
		frame.set_border_width_all(2)
		frame.set_corner_radius_all(4)
		slot.add_theme_stylebox_override("panel", frame)
		slot.add_child(_pin_icon("Pin", reserves[i], Vector2(26, 30)))
		reserve_row.add_child(slot)
	var chips := HFlowContainer.new()
	chips.name = "Counts"
	chips.add_theme_constant_override("h_separation", 6)
	chips.add_theme_constant_override("v_separation", 6)
	side.add_child(chips)
	for chip in [["Charms", held.get("charms", [0, 0])], ["Deck", held.get("deck", [0, 0])]]:
		_chip(chips, "%s %d/%d" % [chip[0], int(chip[1][0]), int(chip[1][1])])
	if not String(held.get("upgrades", "")).is_empty():
		_ink(column, "Upgrades", "Upgrades, kept for the run: " + String(held.upgrades), 16, INK).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _ink(parent: Control, node_name: String, text: String, font_size: int, color: Color) -> Label:
	var label := _label(parent, node_name, font_size)
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

## A pin's art with its modification's badge, or a faint empty place.
func _pin_icon(node_name: String, pin: Dictionary, extent: Vector2) -> Control:
	var icon := TextureRect.new()
	icon.name = node_name
	icon.custom_minimum_size = extent
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_PASS
	var item_id := String(pin.get("item_id", ""))
	icon.texture = ItemAssets.slot(item_id, "icon") as Texture2D if not item_id.is_empty() else null
	icon.tooltip_text = String(pin.get("name", "Empty"))
	icon.set_meta("item_id", item_id)
	if item_id.is_empty(): icon.modulate.a = 0.35
	if not String(pin.get("mod", "")).is_empty(): ModArt._badge(icon, String(pin.mod), int(extent.x * 0.45))
	return icon

func _chip(parent: Control, text: String) -> void:
	var chip := PanelContainer.new()
	chip.name = "Chip"
	var style := StyleBoxFlat.new()
	style.bg_color = INK
	style.set_corner_radius_all(10)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	chip.add_theme_stylebox_override("panel", style)
	parent.add_child(chip)
	_ink(chip, "Text", text, 16, UiTheme.IVORY)

