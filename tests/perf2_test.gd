extends RefCounted
## PERF-2 (the owner's phone log, 2026-11-21: GPU memory rose from 136 to 385 MB at
## Low): copies and rival portraits are kept only while something draws them, plus a
## few recent copies within a byte budget.
const Graphics = preload("res://src/platform/graphics.gd")
const RivalArt = preload("res://src/presentation/rival_art.gd")

static func run() -> Array[String]:
	var failures: Array[String] = []
	var gfx: Node = Graphics.new()
	var size := 64
	gfx.recent_cap = 3 * size * size * 4
	var refs: Array = []
	for i in 5:
		var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
		var copy := ImageTexture.create_from_image(image)
		gfx._copies["copy%d" % i] = weakref(copy)
		gfx._made[copy.get_instance_id()] = "low"
		gfx._keep(copy)
		refs.append(weakref(copy))
	var held: Array = refs.map(func(r): return r.get_ref() != null)
	if gfx._recent.size() != 3 or gfx._recent_bytes != 3 * size * size * 4 or held != [false, false, true, true, true]:
		failures.append("PERF-2: only the 3 most recent copies are kept once nothing draws them (%s, %d bytes)" % [str(held), gfx._recent_bytes])
	var live: Dictionary = gfx.live_copies()
	if live.count != 3 or gfx._made.size() != 3:
		failures.append("PERF-2: freed copies are forgotten (%s, %d ids)" % [str(live), gfx._made.size()])
	gfx.set_recent_cap(0)
	if refs.any(func(r): return r.get_ref() != null) or not gfx._recent.is_empty():
		failures.append("PERF-2: with no budget, a copy lives only while drawn")
	gfx.free()
	var id: String = RivalArt._manifest.keys()[0] if not RivalArt._manifest.is_empty() else ""
	if id.is_empty():
		RivalArt.entry("")
		id = RivalArt._manifest.keys()[0]
	var shown: Array = _show_twice(id) # [the same texture twice, a weak reference to it]
	if not shown[0]:
		failures.append("PERF-2: a shown portrait is the same texture each time (%s)" % id)
	if shown[1].get_ref() != null:
		failures.append("PERF-2: a portrait nothing shows is freed with its sheet (%s)" % id)
	return failures

## Shows a portrait twice; once this returns, nothing holds it.
static func _show_twice(id: String) -> Array:
	var portrait: Texture2D = RivalArt.portrait(id, "entrance")
	var again: Texture2D = RivalArt.portrait(id, "entrance")
	return [portrait != null and again == portrait, weakref(portrait)]
