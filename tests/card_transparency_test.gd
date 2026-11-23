extends RefCounted
## AV-FIX1 (owner, 2026-11-17): every catalogue item's card art, icon and reduced
## view sits on a transparent background, so the card's own window shows around it.
## Checked at the image's four edges: a background plate makes every edge opaque,
## while a subject may touch one edge (Standing Order's clipboard reaches the
## bottom). An image fails when at least PLATE_EDGES of its edges are more than
## EDGE_OPAQUE opaque.
## KNOWN_OPAQUE names the cards still waiting on Codex (AV-FIX1); the check fails
## once one of them is fixed, so the exception is then removed rather than kept.
const EDGE_OPAQUE := 0.5
const PLATE_EDGES := 3
const KNOWN_OPAQUE: Array[String] = [] # AV-FIX1: all remaining plates corrected.

## The share of opaque pixels along each edge: [top, bottom, left, right].
static func edge_opaque(texture: Texture2D) -> Array:
	var image := texture.get_image()
	if image == null or image.is_empty(): return [0.0, 0.0, 0.0, 0.0]
	if image.is_compressed(): image.decompress()
	var w := image.get_width()
	var h := image.get_height()
	var out := []
	for edge in 4:
		var count := 0
		var opaque := 0
		var length := w if edge < 2 else h
		for i in range(0, length, 2):
			var p := Vector2i(i, 0 if edge == 0 else h - 1) if edge < 2 else Vector2i(0 if edge == 2 else w - 1, i)
			count += 1
			if image.get_pixelv(p).a > 0.9: opaque += 1
		out.append(float(opaque) / maxf(count, 1))
	return out

static func has_plate(texture: Texture2D) -> bool:
	return edge_opaque(texture).filter(func(share): return share > EDGE_OPAQUE).size() >= PLATE_EDGES

static func run() -> Array[String]:
	var failures: Array[String] = []
	var catalogue: Dictionary = preload("res://src/rules/content_set.gd").load_set("house").catalogue
	for item in catalogue.items:
		for view in ["card", "icon", "reduced_motion"]:
			var path: String = item.get("assets", {}).get(view, "")
			if path.is_empty() or not ResourceLoader.exists(path): continue
			var texture = load(path)
			if not texture is Texture2D: continue
			var plate := has_plate(texture)
			if item.id in KNOWN_OPAQUE:
				if not plate:
					failures.append("%s %s is transparent now: remove it from KNOWN_OPAQUE" % [item.id, view])
			elif plate:
				failures.append("%s %s has an opaque background (edges %s)" % [item.id, view, str(edge_opaque(texture).map(func(e): return snappedf(e, 0.01)))])
	return failures
