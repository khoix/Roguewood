extends Node
## PERF-1 (owner, 2026-11-21): the Graphics page and what it sets. On an iPhone the
## game sometimes froze for a moment after a release and Safari sometimes lost the
## WebGL context; both point at the phone's GPU. Three settings, saved on the device
## (they must survive the reload after a lost context), each at Normal by default:
## - Resolution: Low draws at no more than 2× the screen's density (the web canvas);
##   Normal is the screen's own density (as before); High adds 2× anti-aliasing to the
##   3D lane.
## - Texture detail: Low draws large art (over 512 px) from a copy at most 512 px on
##   its long side; Normal draws the art as shipped (as before); High draws large art
##   with smoothed mipmaps, so it stays clean when shown small.
## - Performance log: records every frame that takes longer than 150 ms (where the
##   game was, GPU memory) and a lost WebGL context, with a corner readout; the log can
##   be copied from the page to send.
## At the defaults nothing here runs: no sweep, no readout, nothing changed.
const UiTheme = preload("res://src/presentation/house_ui_theme.gd")
const LEVELS := ["low", "normal", "high"]
const DEFAULTS := {"resolution": "normal", "textures": "normal", "perf_log": false}
const LOW_DENSITY := 2.0
const TEXTURE_CAP := 512
const LONG_FRAME_MS := 150.0
const LOG_SIZE := 60
const SWEEP_PER_FRAME := 40
const REVISIT_SECONDS := 3.0
const ORIGINAL := &"rw_graphics_original"

var settings: Dictionary = DEFAULTS.duplicate()
var save_dir := "user://saves"
var log_entries: Array = [] # {at, ms, where, vram}
var long_frames := 0
var swapped := 0 # textures drawn from a Low or High copy
var page: CanvasLayer
var readout: Label
var resolution_choice: OptionButton
var texture_choice: OptionButton
var log_toggle: CheckButton
var log_label: Label
var copy_button: Button
var back_button: Button
var _on_back: Callable
var _copies := {} # source texture id -> its copy at the current level
var _made := {} # ids of copies made here, never processed again
var _queue: Array = [] # weak references to nodes still to check
var _held: Array = [] # weak references to every node that can hold art
var _fresh: Array = [] # nodes added since the last frame
var _sampler_names := {} # shader id -> its texture uniforms
var sweep_usec := 0 # the sweep's time this frame (tests hold it to a budget)
var sweep_worst_usec := 0
var _copied_this_frame := false
var _retry := false
var _sweep_at := 0.0
var _last_usec := 0
var _added := 0
var _log_dirty := false
var _log_saved_at := 0.0

func _ready() -> void:
	name = "Graphics"
	process_mode = Node.PROCESS_MODE_ALWAYS
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--save-dir="): save_dir = arg.trim_prefix("--save-dir=")
	_load()
	get_tree().node_added.connect(_node_added)
	_apply_resolution()
	_read_context_loss()

# --- Settings ---------------------------------------------------------------

func _path(file: String) -> String:
	return save_dir.path_join(file)

func _load() -> void:
	var text := FileAccess.get_file_as_string(_path("graphics.json"))
	var data = JSON.parse_string(text) if not text.is_empty() else null
	if data is Dictionary:
		for key in DEFAULTS:
			if data.has(key) and typeof(data[key]) == typeof(DEFAULTS[key]): settings[key] = data[key]
	for key in ["resolution", "textures"]:
		if settings[key] not in LEVELS: settings[key] = "normal"
	var log_text_saved := FileAccess.get_file_as_string(_path("perf_log.json"))
	var saved = JSON.parse_string(log_text_saved) if not log_text_saved.is_empty() else null
	if saved is Array: log_entries = saved

func _save() -> void:
	DirAccess.make_dir_recursive_absolute(save_dir)
	var file := FileAccess.open(_path("graphics.json"), FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(settings))

## Changes one setting, applies it and saves it.
func set_value(key: String, value) -> void:
	if not DEFAULTS.has(key) or typeof(value) != typeof(DEFAULTS[key]): return
	if key in ["resolution", "textures"] and value not in LEVELS: return
	settings[key] = value
	_save()
	match key:
		"resolution": _apply_resolution()
		"textures": _restart_sweep()
		"perf_log":
			_last_usec = 0
			if readout != null: readout.visible = value
	_refresh_page()

func level(key: String) -> String:
	return String(settings.get(key, "normal"))

# --- Resolution -------------------------------------------------------------

## The web canvas follows the browser's device pixel ratio; the page's loader script
## (tools/author_loader.py) caps it, before the engine starts, from the saved level.
## High's anti-aliasing is the root viewport's, on every platform.
func _apply_resolution() -> void:
	var lane_aa := Viewport.MSAA_2X if level("resolution") == "high" else Viewport.MSAA_DISABLED
	if get_tree().root.msaa_3d != lane_aa: get_tree().root.msaa_3d = lane_aa
	if not OS.has_feature("web"): return
	var cap := LOW_DENSITY if level("resolution") == "low" else 0.0
	JavaScriptBridge.eval("""(function(){
		try { localStorage.setItem('rw.resolution', '%s'); } catch (e) {}
		if (!window.rwDensity) { // a page without the loader script (author_loader.py)
			var fixed = window.devicePixelRatio || 1;
			window.rwDensity = {real: function () { return fixed; }, cap: 0};
			Object.defineProperty(window, 'devicePixelRatio', {configurable: true, get: function () {
				var r = window.rwDensity.real(), c = window.rwDensity.cap; return c > 0 ? Math.min(r, c) : r; }});
		}
		window.rwDensity.cap = %s;
	})()""" % [level("resolution"), cap], true)

## The canvas's pixel density now (the web), for the page and tests.
func density() -> float:
	if not OS.has_feature("web"): return DisplayServer.screen_get_scale()
	var value = JavaScriptBridge.eval("window.devicePixelRatio || 1", true)
	return float(value) if value != null else 1.0

# --- Texture detail ---------------------------------------------------------

## Only nodes that can draw art are followed: those with a texture property, a
## canvas shader material or a 3D material override.
static func _can_hold_art(node: Node) -> bool:
	return not _texture_props(node).is_empty() or (node is CanvasItem and node.material is ShaderMaterial) \
		or (node is GeometryInstance3D and node.material_override != null)

func _node_added(node: Node) -> void:
	_added += 1
	if level("textures") != "normal" or swapped > 0:
		_fresh.append(node) # checked once it has settled (its art often arrives after it joins)

## On a level change: every node that can hold art, a few a frame.
func _restart_sweep() -> void:
	_copies.clear()
	_held.clear()
	for node in get_tree().root.find_children("*", "", true, false):
		if _can_hold_art(node): _held.append(weakref(node))
	_queue = _held.duplicate()
	_sweep_at = 0.0

## PERF-1b (owner, 2026-11-21: Low or High textures dropped a phone under 20 fps):
## the sweep is incremental and cheap. Art already drawn at the current level is
## skipped without loading anything; only nodes that can hold art are followed; the
## followed list is revisited every few seconds for art changed since.
func _sweep(delta: float) -> void:
	if level("textures") == "normal" and _queue.is_empty() and _fresh.is_empty() and swapped == 0: return
	var start := Time.get_ticks_usec()
	_sweep_at += delta
	if not _fresh.is_empty():
		for node in _fresh:
			if is_instance_valid(node) and _can_hold_art(node):
				_held.append(weakref(node))
				_queue.append(_held.back())
		_fresh.clear()
	if _queue.is_empty() and _sweep_at >= REVISIT_SECONDS:
		_sweep_at = 0.0
		_held = _held.filter(func(ref): return ref.get_ref() != null)
		_queue = _held.duplicate()
	_copied_this_frame = false
	var count := 0
	while not _queue.is_empty() and count < SWEEP_PER_FRAME:
		var ref: WeakRef = _queue.pop_back()
		var node = ref.get_ref()
		count += 1
		if node == null: continue
		_retry = false
		_treat_node(node)
		if _retry: _queue.push_front(ref) # waits for next frame's copy
	sweep_usec = Time.get_ticks_usec() - start
	sweep_worst_usec = maxi(sweep_worst_usec, sweep_usec)

func _treat_node(node: Node) -> void:
	if node == page or (page != null and page.is_ancestor_of(node)): return
	for prop in _texture_props(node):
		var current = node.get(prop)
		if not (current is Texture2D): continue
		if _settled(current): continue
		var key: String = String(ORIGINAL) + String(prop)
		# A node remembers its own art (by path, so the full-size texture can be freed)
		# while it draws a copy; art set since (not a copy made here) is the source now.
		var source: Texture2D = _recall(node, key) if _made.has(_id(current)) else current
		if source == null: continue
		var wanted := _for_level(source)
		if wanted != current: node.set(prop, wanted)
		_remember(node, key, source if wanted != source else null)
		if node is CanvasItem:
			var smooth := level("textures") == "high" and wanted != source
			if smooth and not node.has_meta(&"rw_graphics_filter"):
				node.set_meta(&"rw_graphics_filter", node.texture_filter)
				node.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			elif not smooth and node.has_meta(&"rw_graphics_filter"):
				node.texture_filter = node.get_meta(&"rw_graphics_filter")
				node.remove_meta(&"rw_graphics_filter")
	var materials: Array = []
	if node is CanvasItem and node.material is ShaderMaterial: materials.append(node.material)
	if node is GeometryInstance3D and node.material_override != null: materials.append(node.material_override)
	for material in materials: _treat_material(material)

static func _texture_props(node: Node) -> Array:
	if node is TextureRect or node is Sprite2D or node is Sprite3D or node is NinePatchRect: return ["texture"]
	if node is TextureButton: return ["texture_normal"]
	if node is Button: return ["icon"]
	return []

func _treat_material(material: Material) -> void:
	var names: Array = []
	if material is ShaderMaterial and material.shader != null:
		var shader_id: int = material.shader.get_instance_id()
		if not _sampler_names.has(shader_id):
			# Read once per shader: only its texture uniforms.
			_sampler_names[shader_id] = material.shader.get_shader_uniform_list().filter(
				func(u): return u.hint_string == "Texture2D" or u.type == TYPE_OBJECT).map(func(u): return u.name)
		names = _sampler_names[shader_id]
	elif material is BaseMaterial3D:
		names.append("albedo_texture")
	for prop in names:
		var current = material.get_shader_parameter(prop) if material is ShaderMaterial else material.get(prop)
		if not (current is Texture2D) or _settled(current): continue
		var key: String = String(ORIGINAL) + String(prop)
		var source: Texture2D = _recall(material, key) if _made.has(_id(current)) else current
		if source == null: continue
		var wanted := _for_level(source)
		if wanted == current: continue
		if material is ShaderMaterial: material.set_shader_parameter(prop, wanted)
		else: material.set(prop, wanted)
		_remember(material, key, source if wanted != source else null)

## The source is kept by its path (a weak reference for art made at runtime), so the
## full-size texture is freed while only the copy is drawn.
static func _remember(holder: Object, key: String, source: Texture2D) -> void:
	if source == null:
		if holder.has_meta(key): holder.remove_meta(key)
	elif not source.resource_path.is_empty() and not source.resource_path.contains("::"):
		holder.set_meta(key, source.resource_path)
	else:
		holder.set_meta(key, weakref(source))

static func _recall(holder: Object, key: String) -> Texture2D:
	if not holder.has_meta(key): return null
	var kept = holder.get_meta(key)
	if kept is String: return load(kept) as Texture2D
	return kept.get_ref() as Texture2D if kept is WeakRef else null

## Art that needs nothing at this level: a copy made for it, or art the level leaves
## as it is (small art, or every texture at Normal). Nothing is loaded to decide.
func _settled(texture: Texture2D) -> bool:
	var made = _made.get(_id(texture))
	if made != null: return made == level("textures")
	if level("textures") == "normal": return true
	return maxi(texture.get_width(), texture.get_height()) <= TEXTURE_CAP and not (texture is AtlasTexture)

static func _id(texture) -> int:
	return texture.get_instance_id() if texture != null else 0

## The texture to draw for `source` at the current level: itself at Normal and for
## small art; otherwise a copy (made once, kept while the level holds).
func _for_level(source: Texture2D) -> Texture2D:
	if source == null or _made.has(_id(source)) or level("textures") == "normal": return source
	if maxi(source.get_width(), source.get_height()) <= TEXTURE_CAP and not (source is AtlasTexture): return source
	var cache_key = source.resource_path if not source.resource_path.is_empty() else _id(source)
	if _copies.has(cache_key): return _copies[cache_key]
	var copy: Texture2D = null
	if source is AtlasTexture:
		if source.atlas != null and maxi(source.atlas.get_width(), source.atlas.get_height()) > TEXTURE_CAP:
			var sheet := _for_level(source.atlas)
			if sheet == source.atlas: return source # its sheet waits for a later frame
			copy = _atlas_from(source, sheet)
	else:
		# One new copy a frame (each is a resize); the node is retried next frame.
		if _copied_this_frame:
			_retry = true
			return source
		_copied_this_frame = true
		copy = _image_copy(source)
	if copy == null: copy = source
	_copies[cache_key] = copy
	if copy != source:
		_made[_id(copy)] = level("textures")
		swapped += 1
	return copy

func _image_copy(source: Texture2D) -> Texture2D:
	var image := source.get_image()
	if image == null or image.is_empty(): return null
	if image.is_compressed() and image.decompress() != OK: return null
	if level("textures") == "low":
		# Halving steps, then one last step: close to a box filter, and far quicker on
		# a phone than one Lanczos pass from the full size.
		var scale := float(TEXTURE_CAP) / maxf(image.get_width(), image.get_height())
		var target := Vector2i(maxi(1, roundi(image.get_width() * scale)), maxi(1, roundi(image.get_height() * scale)))
		while image.get_width() >= target.x * 2 and image.get_height() >= target.y * 2:
			image.resize(image.get_width() / 2, image.get_height() / 2, Image.INTERPOLATE_BILINEAR)
		image.resize(target.x, target.y, Image.INTERPOLATE_BILINEAR)
	else:
		image.generate_mipmaps()
	return ImageTexture.create_from_image(image)

## An atlas region keeps its place in a scaled sheet.
static func _atlas_from(source: AtlasTexture, sheet: Texture2D) -> Texture2D:
	var scale := float(sheet.get_width()) / source.atlas.get_width()
	var copy := AtlasTexture.new()
	copy.atlas = sheet
	copy.region = Rect2(source.region.position * scale, source.region.size * scale)
	copy.margin = Rect2(source.margin.position * scale, source.margin.size * scale)
	copy.filter_clip = source.filter_clip
	return copy

# --- Performance log ----------------------------------------------------------

func _process(delta: float) -> void:
	_sweep(delta)
	if not bool(settings.perf_log):
		_added = 0
		return
	var now := Time.get_ticks_usec()
	if _last_usec > 0:
		var ms := (now - _last_usec) / 1000.0
		if ms >= LONG_FRAME_MS: _record(ms)
	_last_usec = now
	_added = 0
	if readout != null and Engine.get_process_frames() % 15 == 0:
		readout.text = "%d fps · %d long · %.0f MB" % [Engine.get_frames_per_second(), long_frames, _vram()]
	if _log_dirty and Time.get_ticks_msec() / 1000.0 - _log_saved_at >= 2.0: _save_log()
	if OS.has_feature("web") and Engine.get_process_frames() % 60 == 0:
		JavaScriptBridge.eval("try{localStorage.setItem('rw.where', %s)}catch(e){}" % JSON.stringify(where()), true)

static func _vram() -> float:
	return Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0

## Where the game is: the screen, and in a match the lab's state and roll.
func where() -> String:
	var shell = get_tree().current_scene
	if shell == null or shell.get("screen") == null:
		shell = null
		for child in get_tree().root.get_children():
			if child.get("screen") != null and "lab" in child: shell = child
	if shell == null: return "start"
	var text := String(shell.screen)
	var lab = shell.get("lab")
	if lab != null and is_instance_valid(lab): text += " · %s · roll %d" % [lab.state, lab.history.size() + 1]
	return text

func _record(ms: float, what: String = "") -> void:
	long_frames += 1
	var entry := {"at": Time.get_datetime_string_from_system(false, true), "ms": roundi(ms), "where": where(), "vram": snappedf(_vram(), 0.1), "added": _added}
	if not what.is_empty(): entry.what = what
	log_entries.append(entry)
	while log_entries.size() > LOG_SIZE: log_entries.pop_front()
	_log_dirty = true
	_refresh_page()

func _save_log() -> void:
	_log_dirty = false
	_log_saved_at = Time.get_ticks_msec() / 1000.0
	DirAccess.make_dir_recursive_absolute(save_dir)
	var file := FileAccess.open(_path("perf_log.json"), FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(log_entries))

## The loader script notes a lost WebGL context (and where the game last was) before
## it reloads; the log records it on the next start.
func _read_context_loss() -> void:
	if not OS.has_feature("web"): return
	var lost = JavaScriptBridge.eval("(function(){try{var t=localStorage.getItem('rw.contextLost');localStorage.removeItem('rw.contextLost');return t||'';}catch(e){return '';}})()", true)
	if typeof(lost) != TYPE_STRING or lost.is_empty(): return
	var at = JavaScriptBridge.eval("(function(){try{return localStorage.getItem('rw.where')||'';}catch(e){return '';}})()", true)
	log_entries.append({"at": lost, "ms": 0, "where": String(at) if at != null else "", "vram": 0.0, "added": 0, "what": "WebGL context lost; the page reloaded"})
	while log_entries.size() > LOG_SIZE: log_entries.pop_front()
	_save_log()

func log_text() -> String:
	var lines: Array = ["Roguewood performance log · %s · density %.1f · resolution %s · textures %s" % [OS.get_name(), density(), level("resolution"), level("textures")]]
	for e in log_entries:
		lines.append("%s  %s  %s  %.0f MB%s" % [e.at, ("%d ms" % e.ms) if int(e.ms) > 0 else "—", e.where, float(e.vram), ("  " + String(e.what)) if e.has("what") else ""])
	if log_entries.is_empty(): lines.append("No long frames recorded.")
	return "\n".join(lines)

func clear_log() -> void:
	log_entries.clear()
	long_frames = 0
	_save_log()
	_refresh_page()

# --- The page -------------------------------------------------------------------

func is_open() -> bool:
	return page != null and page.visible

## Opens the Graphics page over everything; `on_back` runs when Back closes it.
func open(on_back: Callable = Callable()) -> void:
	_on_back = on_back
	if page == null: _build_page()
	_refresh_page()
	page.show()
	resolution_choice.grab_focus()

func go_back() -> void:
	if not is_open(): return
	page.hide()
	if _on_back.is_valid(): _on_back.call()

func _input(event: InputEvent) -> void:
	if is_open() and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		go_back()

func _build_page() -> void:
	page = CanvasLayer.new()
	page.name = "GraphicsPage"
	page.layer = 90
	page.hide()
	add_child(page)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = UiTheme.build()
	page.add_child(root)
	var dim := ColorRect.new()
	dim.name = "GraphicsDim"
	dim.color = UiTheme.SCRIM # UI-35: one scrim behind every overlay
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(event):
		if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed: go_back.call_deferred())
	root.add_child(dim)
	var panel := PanelContainer.new()
	panel.name = "GraphicsPanel"
	panel.add_theme_stylebox_override("panel", UiTheme.frame("menu", 20.0, 18.0))
	root.add_child(panel)
	var place := func():
		var view: Vector2 = root.size
		var width := minf(view.x - 24.0, 640.0)
		panel.position = Vector2((view.x - width) * 0.5, 88.0)
		panel.size = Vector2(width, view.y - 100.0)
	root.resized.connect(place)
	place.call_deferred()
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	panel.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 12)
	scroll.add_child(box)
	var title := Label.new()
	title.text = "Graphics"
	title.add_theme_font_size_override("font_size", 30)
	box.add_child(title)
	resolution_choice = _choice(box, "Resolution", "GraphicsResolution", "resolution", {
		"low": "Low: at most 2× the screen's pixel density. Lighter on a phone's GPU.",
		"normal": "Normal: the screen's own pixel density.",
		"high": "High: the screen's density, with smoothed edges on the lane (2× anti-aliasing). Heaviest."})
	texture_choice = _choice(box, "Texture Detail", "GraphicsTextures", "textures", {
		"low": "Low: large art drawn from a smaller copy (512 px). Uses much less GPU memory.",
		"normal": "Normal: the art as made.",
		"high": "High: large art smoothed when shown small (mipmaps). Uses more GPU memory."})
	log_toggle = CheckButton.new()
	log_toggle.name = "GraphicsPerfLog"
	log_toggle.text = "Performance Log"
	log_toggle.custom_minimum_size = Vector2(0, 56)
	log_toggle.toggled.connect(func(on): set_value("perf_log", on))
	box.add_child(log_toggle)
	var hint := Label.new()
	hint.text = "Records every frame over %d ms and any lost WebGL context, with where the game was. Copy the log to send it." % int(LONG_FRAME_MS)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", Color("c9d3cf"))
	box.add_child(hint)
	log_label = Label.new()
	log_label.name = "GraphicsLogText"
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_label.add_theme_font_size_override("font_size", 16)
	box.add_child(log_label)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(row)
	copy_button = Button.new()
	copy_button.name = "GraphicsCopyLog"
	copy_button.text = "Copy Log"
	copy_button.custom_minimum_size = Vector2(180, 56)
	copy_button.pressed.connect(func():
		DisplayServer.clipboard_set(log_text())
		copy_button.text = "Copied")
	row.add_child(copy_button)
	var clear := Button.new()
	clear.name = "GraphicsClearLog"
	clear.text = "Clear"
	clear.custom_minimum_size = Vector2(140, 56)
	clear.pressed.connect(clear_log)
	row.add_child(clear)
	back_button = Button.new()
	back_button.name = "GraphicsBack"
	back_button.text = "Back"
	back_button.custom_minimum_size = Vector2(220, 64)
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_button.pressed.connect(go_back)
	box.add_child(back_button)
	# The corner readout while the log is on (frame rate, long frames, GPU memory).
	var layer := CanvasLayer.new()
	layer.name = "GraphicsReadout"
	layer.layer = 95
	add_child(layer)
	readout = Label.new()
	readout.position = Vector2(8, 4)
	readout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	readout.add_theme_font_size_override("font_size", 14)
	readout.add_theme_color_override("font_outline_color", Color.BLACK)
	readout.add_theme_constant_override("outline_size", 4)
	readout.visible = bool(settings.perf_log)
	layer.add_child(readout)

func _choice(box: VBoxContainer, heading: String, node_name: String, key: String, notes: Dictionary) -> OptionButton:
	var label := Label.new()
	label.text = heading
	label.add_theme_font_size_override("font_size", 22)
	box.add_child(label)
	var choice := OptionButton.new()
	choice.name = node_name
	choice.custom_minimum_size = Vector2(0, 56)
	for item in ["Low", "Normal", "High"]: choice.add_item(item)
	box.add_child(choice)
	var note := Label.new()
	note.name = node_name + "Note"
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_font_size_override("font_size", 18)
	note.add_theme_color_override("font_color", Color("c9d3cf"))
	box.add_child(note)
	choice.set_meta("notes", notes)
	choice.set_meta("note", note)
	choice.item_selected.connect(func(index): set_value(key, LEVELS[index]))
	return choice

func _refresh_page() -> void:
	if page == null: return
	for pair in [[resolution_choice, "resolution"], [texture_choice, "textures"]]:
		var choice: OptionButton = pair[0]
		choice.select(LEVELS.find(level(pair[1])))
		choice.get_meta("note").text = choice.get_meta("notes")[level(pair[1])]
	log_toggle.set_pressed_no_signal(bool(settings.perf_log))
	copy_button.text = "Copy Log"
	var shown: Array = log_entries.slice(maxi(0, log_entries.size() - 12))
	var lines: Array = []
	for e in shown:
		lines.append("%s  %s  %s" % [String(e.at).substr(11, 8), ("%d ms" % e.ms) if int(e.ms) > 0 else String(e.get("what", "")), e.where])
	log_label.text = ("Last %d of %d:\n" % [shown.size(), log_entries.size()] + "\n".join(lines)) if not lines.is_empty() else "No long frames recorded."
