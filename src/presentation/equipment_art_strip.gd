extends HBoxContainer
## Read-only visual inventory. Ordering comes from RunInventory; never handles input.
const Assets = preload("res://src/presentation/item_assets.gd")
var lab: Control
var _signature := ""

func _ready() -> void:
	name = "EquipmentArtStrip"
	mouse_filter = MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 8)

func _process(_delta: float) -> void:
	if lab.run == null: return
	visible = lab.state in ["aim", "holding", "rolling", "result", "frame_done"] and not lab.settings_panel.visible and not lab.score_panel.visible and not lab.hud.reaction.visible
	var ids: Array = lab.run.charms.map(func(entry): return String(entry.item_id))
	var signature := str(ids)
	if signature != _signature:
		_signature = signature
		for child in get_children():
			remove_child(child)
			child.queue_free()
		for id in ids:
			var texture := Assets.slot(id, "in_play") as Texture2D
			if texture == null: continue
			var panel := PanelContainer.new()
			panel.name = id.replace(".", "_")
			panel.mouse_filter = MOUSE_FILTER_IGNORE
			panel.add_theme_stylebox_override("panel", Assets.slot(id, "rarity_treatment"))
			var box := VBoxContainer.new()
			box.name = "Body"
			box.mouse_filter = MOUSE_FILTER_IGNORE
			panel.add_child(box)
			var art := TextureRect.new()
			art.name = "Identity"
			art.texture = texture
			art.texture_filter = TEXTURE_FILTER_NEAREST
			art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			art.custom_minimum_size = Vector2(48, 48)
			art.mouse_filter = MOUSE_FILTER_IGNORE
			box.add_child(art)
			var label := Label.new()
			label.text = String(lab.run.item(id).name).replace(" ", "\n")
			label.add_theme_font_size_override("font_size", 16)
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.mouse_filter = MOUSE_FILTER_IGNORE
			box.add_child(label)
			add_child(panel)
	position = Vector2(maxf(16, (lab.size.x - get_combined_minimum_size().x) * 0.5), lab.status.position.y + lab.status.size.y + 12)
