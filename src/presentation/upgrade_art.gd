extends Node
## Read-only shop decoration. Initial/restored ownership never replays purchase cues.
const Assets = preload("res://src/presentation/item_assets.gd")
const IDS = ["shop_upgrade.punch_card", "shop_upgrade.pin_caddy", "shop_upgrade.clearance_tag"]
var lab: Control
var seen: Array = []
var initialized := false
var row: HBoxContainer
var caddy: HBoxContainer
var glyph: Control
var history: Array = []
var case_icon: TextureRect
func _ready() -> void:
	row = HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lab.shop_panel._main.add_child(row)
	lab.shop_panel._main.move_child(row,lab.shop_panel.rack_label.get_index()+1)
	glyph = preload("res://src/presentation/ability_glyph.gd").new()
	row.add_child(glyph)
	case_icon = TextureRect.new()
	case_icon.texture = Assets.slot("shop_upgrade.pin_caddy","icon")
	case_icon.custom_minimum_size = Vector2(64,64)
	case_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	case_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	case_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	row.add_child(case_icon)
	caddy = HBoxContainer.new()
	row.add_child(caddy)
	for index in 3:
		var pocket := Label.new()
		pocket.custom_minimum_size = Vector2(110,56)
		pocket.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var style := StyleBoxFlat.new()
		style.bg_color = Color("17363c")
		style.border_color = Color("c49a56")
		style.set_border_width_all(2)
		style.set_corner_radius_all(8)
		pocket.add_theme_stylebox_override("normal", style)
		caddy.add_child(pocket)
func _process(_delta: float) -> void:
	if lab.run == null: return
	var owned: Array = lab.run.upgrades.map(func(e): return e.item_id)
	if initialized:
		for id in IDS:
			if id in owned and id not in seen:
				glyph.show_cue(Assets.slot(id,"activation"),lab.settings.reduced_motion or lab.settings.reduced_flash,Assets.slot(id,"icon"))
				var before: int = lab.motion.sound.played
				lab.motion.sound.cue(id,Assets.slot(id,"sound"),2)
				history.append({"id":id,"audio":lab.motion.sound.played>before})
	seen = owned.duplicate()
	initialized = true
	glyph.enabled = lab.motion.sound.enabled
	row.visible = lab.state == "shop" and ("shop_upgrade.pin_caddy" in owned or glyph.age < 1.2)
	caddy.visible = "shop_upgrade.pin_caddy" in owned
	case_icon.visible = "shop_upgrade.pin_caddy" in owned
	for index in 3:
		var pocket: Label = caddy.get_child(index)
		pocket.visible = index < lab.run.reserves.size()
		var entry = lab.run.reserves[index] if index < lab.run.reserves.size() else null
		pocket.text = "Pocket %d\n%s" % [index+1, "Empty" if entry == null else lab.run.item(entry.item_id).name]
		pocket.add_theme_color_override("font_color",Color("f2d6a0") if index == 2 else Color.WHITE)
	if lab.state != "shop" or lab.shop == null: return
	var reroll: Button = lab.shop_panel.reroll_button
	if "shop_upgrade.punch_card" in owned:
		reroll.icon = Assets.slot("shop_upgrade.punch_card","icon")
		reroll.expand_icon = true
		reroll.add_theme_constant_override("icon_max_width",28)
		reroll.text = "Reroll free" if lab.shop.reroll_cost(lab.run) == 0 else "Reroll $%d" % lab.shop.reroll_cost(lab.run)
	for i in lab.shop.offers.size():
		var button: Button = lab.shop_panel.button_for_offer(i)
		var tag := button.get_node_or_null("ClearancePrice") as RichTextLabel
		if tag == null:
			tag = RichTextLabel.new()
			tag.name = "ClearancePrice"
			tag.bbcode_enabled = true
			tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
			tag.scroll_active = false
			tag.add_theme_font_size_override("normal_font_size",16)
			var paper := StyleBoxFlat.new()
			paper.bg_color = Color("923c36")
			paper.corner_radius_top_right = 8
			paper.content_margin_left = 3
			tag.add_theme_stylebox_override("normal",paper)
			button.add_child(tag)
		var offer: Dictionary = lab.shop.offers[i]
		tag.visible = "shop_upgrade.clearance_tag" in owned and not offer.sold and not offer.item_id.is_empty()
		if tag.visible:
			var base: int = lab.run.item(offer.item_id).purchase_price
			tag.text = "[color=#fff0d5]↓ [s]$%d[/s][/color]" % base
			tag.position = Vector2(6,button.size.y-26)
			tag.size = Vector2(60,24)
			tag.set_meta("original_price",base)
			tag.set_meta("price",offer.price)
