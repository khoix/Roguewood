extends Node
## E22-L01: binds a League's theme (E22-L01-ART, assets/leagues/<league>/manifest.json)
## to the live lab. Cosmetic only: no collision, physics, input or scoring.
## - The Division's environment scene sits at the lane world's origin, a child of the
##   lab viewport, replaced when the stage changes. Division 8's boss match, the
##   Championship, has its own stage (the manifest's `championship` entry).
## - The match's lane condition picks the lane surface material; the lane's physics
##   material and geometry are untouched.
## - The League's music loops on the Master bus, quietly, for the whole attempt.
const Soundtrack = preload("res://src/presentation/soundtrack.gd")
const MANIFESTS := {"league.house": "res://assets/leagues/house/manifest.json", "league.neon": "res://assets/leagues/neon/manifest.json"}
const MUSIC_DB := -18.0

var manifest: Dictionary = {}
var stage_id := "" # the environment id on show
var environment: Node3D
var music: AudioStreamPlayer
var _championship := false # the stage on show is the Championship (its own track)

## A theme for the League, or null when it has none.
static func for_league(league_id: String) -> Node:
	if not MANIFESTS.has(league_id) or not FileAccess.file_exists(MANIFESTS[league_id]):
		return null
	var theme = load("res://src/presentation/league_theme.gd").new()
	theme.name = "LeagueTheme"
	theme.manifest = JSON.parse_string(FileAccess.get_file_as_string(MANIFESTS[league_id]))
	return theme

func _asset(id: String) -> String:
	return manifest.get("assets", {}).get(id, "")

## UI-20: the celebration variants the manifest lists for an event (resource paths).
## `boss_defeated` maps each rival id to its two. Empty until Codex's UI-A9 lands.
func celebrations(event: String, rival_id: String = "") -> Array:
	return celebrations_in(manifest, event, rival_id)

static func celebrations_in(data: Dictionary, event: String, rival_id: String = "") -> Array:
	var entry = data.get("celebrations", {}).get(event, [])
	if event == "boss_defeated":
		entry = entry.get(rival_id, []) if entry is Dictionary else []
	return (entry as Array).filter(func(p): return p is String and not String(p).is_empty()) if entry is Array else []

## UI-20: the event's sting (a list gives one per variant; any one is picked).
func celebration_sound(event: String, rng: RandomNumberGenerator = null) -> AudioStream:
	var entry = manifest.get("celebration_sounds", {}).get(event, "")
	if entry is Array:
		if entry.is_empty(): return null
		entry = entry[rng.randi_range(0, entry.size() - 1) if rng != null else 0]
	return load(entry) if entry is String and not entry.is_empty() and ResourceLoader.exists(entry) else null

## UI-20: what a League's set lacks once its theme says it is complete
## (`celebrations_complete`): at least 5 strikes and 5 spares, exactly 2 per rival.
static func celebration_gaps(data: Dictionary, rival_ids: Array) -> Array[String]:
	var gaps: Array[String] = []
	if not bool(data.get("celebrations_complete", false)): return gaps
	for event in ["strike", "spare"]:
		var list := celebrations_in(data, event)
		if list.size() < 5: gaps.append("%s: %d of at least 5 %s celebrations" % [data.get("league_id", "?"), list.size(), event])
		for path in list:
			if not ResourceLoader.exists(path): gaps.append("missing celebration " + path)
	for rival in rival_ids:
		var list := celebrations_in(data, "boss_defeated", rival)
		if list.size() != 2: gaps.append("%s: %d of 2 boss celebrations for %s" % [data.get("league_id", "?"), list.size(), rival])
		for path in list:
			if not ResourceLoader.exists(path): gaps.append("missing celebration " + path)
	return gaps

## The stage for a Division; `championship` selects the Championship entry.
func stage(division: int, championship: bool) -> Dictionary:
	for s in manifest.get("stages", []):
		if int(s.division) == division and bool(s.championship) == championship:
			return s
	return {}

## Shows the stage's environment in the viewport (once per stage change).
func show_stage(viewport: SubViewport, division: int, championship: bool) -> void:
	var s := stage(division, championship)
	if s.is_empty() or s.environment_id == stage_id:
		return
	if environment != null:
		environment.get_parent().remove_child(environment)
		environment.queue_free()
		environment = null
	var scene: PackedScene = load(_asset(s.environment_id))
	if scene == null:
		push_warning("League theme: missing environment " + s.environment_id)
		return
	_championship = championship
	_retune()
	environment = scene.instantiate()
	environment.name = "LeagueEnvironment"
	environment.set_meta("environment_id", s.environment_id)
	viewport.add_child(environment)
	stage_id = s.environment_id

## Applies the lane condition's surface material to the lane's cosmetic mesh.
func dress_lane(lane_world: Node3D, condition: String) -> String:
	_dress_pin_deck(lane_world)
	var visual := ""
	for l in manifest.get("lanes", []):
		if l.condition_id == condition:
			visual = l.visual_id
	if visual.is_empty():
		return ""
	var material: Material = load(_asset(visual))
	var body := lane_world.get_node_or_null("Lane")
	if material == null or body == null:
		return ""
	for child in body.get_children():
		if child is MeshInstance3D and child.mesh is BoxMesh and child.mesh.size.z > 0.2:
			child.material_override = material
			child.set_meta("lane_visual", visual)
	return visual

## UI-A6: each League manifest names its static pin-deck finish. Only the
## pre-existing visible meshes change; the bodies/shapes/materials stay intact.
func _dress_pin_deck(lane_world: Node3D) -> void:
	var path: String = manifest.get("pin_deck", "")
	if path.is_empty(): return
	var finish := load(path) as Material
	if finish == null: return
	for wall in lane_world.get_children():
		if not wall is StaticBody3D: continue
		if not (String(wall.name).begins_with("Kickback") or wall.name == "Cushion"): continue
		for child in wall.get_children():
			if child is MeshInstance3D:
				child.material_override = finish
				child.set_meta("pin_deck", path)
				# Preserve the existing Neon art journey contract.
				if manifest.get("league_id", "") == "league.neon": child.set_meta("neon_pin_deck", true)

## The League's own backdrop for the space beside the lane (E22-L02), or null when
## it keeps the House sky. The node has a `reduced` property, as the House one has.
func flank() -> Control:
	var id: String = manifest.get("flank", {}).get("normal", "")
	if id.is_empty():
		return null
	var scene: PackedScene = load(_asset(id))
	if scene == null:
		push_warning("League theme: missing flank backdrop " + id)
		return null
	var node: Control = scene.instantiate()
	node.set_meta("backdrop_id", id)
	return node

## Starts the League's music loop (once).
func play_music() -> void:
	if music != null:
		return
	var stream: AudioStream = _track()
	if stream == null:
		return
	music = AudioStreamPlayer.new()
	music.name = "LeagueMusic"
	music.stream = stream
	music.volume_db = MUSIC_DB
	add_child(music)
	music.play()

## The track for the stage on show: the owner's soundtrack first (the Championship
## has its own), else the theme's own loop.
func _track() -> AudioStream:
	if _championship and Soundtrack.has("championship"):
		return Soundtrack.stream("championship")
	var league := String(manifest.get("league_id", ""))
	if Soundtrack.has(league):
		return Soundtrack.stream(league)
	return load(_asset(manifest.get("music", {}).get("asset_id", "")))

## A stage change (into or out of the Championship) swaps the playing track.
func _retune() -> void:
	if music == null: return
	var want := _track()
	if want != null and want != music.stream:
		music.stream = want
		music.play()

## Stops the loop and lets go of its stream when the lab closes. A test that quits
## while the loop plays stops it first and waits a few frames, or the audio thread
## still holds the playback at exit (Codex's E22-L01-ART inspector does the same).
func _exit_tree() -> void:
	if music != null:
		music.stop()
		music.stream = null
