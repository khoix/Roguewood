extends Node
## E22-L01: binds a League's theme (E22-L01-ART, assets/leagues/<league>/manifest.json)
## to the live lab. Cosmetic only: no collision, physics, input or scoring.
## - The Division's environment scene sits at the lane world's origin, a child of the
##   lab viewport, replaced when the stage changes. Division 8's boss match, the
##   Championship, has its own stage (the manifest's `championship` entry).
## - The match's lane condition picks the lane surface material; the lane's physics
##   material and geometry are untouched.
## - The League's music loops on the Master bus, quietly, for the whole attempt.
const MANIFESTS := {"league.house": "res://assets/leagues/house/manifest.json"}
const MUSIC_DB := -18.0

var manifest: Dictionary = {}
var stage_id := "" # the environment id on show
var environment: Node3D
var music: AudioStreamPlayer

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
	environment = scene.instantiate()
	environment.name = "LeagueEnvironment"
	environment.set_meta("environment_id", s.environment_id)
	viewport.add_child(environment)
	stage_id = s.environment_id

## Applies the lane condition's surface material to the lane's cosmetic mesh.
func dress_lane(lane_world: Node3D, condition: String) -> String:
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

## Starts the League's music loop (once).
func play_music() -> void:
	if music != null:
		return
	var stream: AudioStream = load(_asset(manifest.get("music", {}).get("asset_id", "")))
	if stream == null:
		return
	music = AudioStreamPlayer.new()
	music.name = "LeagueMusic"
	music.stream = stream
	music.volume_db = MUSIC_DB
	add_child(music)
	music.play()

## Stops the loop and lets go of its stream when the lab closes. A test that quits
## while the loop plays stops it first and waits a few frames, or the audio thread
## still holds the playback at exit (Codex's E22-L01-ART inspector does the same).
func _exit_tree() -> void:
	if music != null:
		music.stop()
		music.stream = null
