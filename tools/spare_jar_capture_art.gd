extends RefCounted
## Review-only baseline: restore the retained original atlas in memory, never on disk.
## Keep the returned resources alive so native UI loads use the same cached views.
static func prepare(before_art: bool = false) -> Array[Resource]:
	var views: Array[Resource] = []
	if not before_art and not OS.get_cmdline_user_args().has("--before-art"): return views
	for slot in ["card", "icon", "reduced_motion"]:
		var view := load("res://assets/items/d09/%s.charm.spare_jar.tres" % slot) as AtlasTexture
		view.atlas = load("res://assets/items/d09/source.AV-H3-B.png")
		view.region = Rect2(492, 160, 504, 736)
		views.append(view)
	print("AV-FIX1 BEFORE ART specimen: original atlas in current native UI; gameplay and Career unchanged")
	return views
