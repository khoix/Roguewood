extends Node
## QA-8 (owner, 2026-11-20): a rendered journey draws a frame only when something
## waits for one (a capture awaiting RenderingServer.frame_post_draw), and every
## EVERY frames besides, so shaders, viewports and stray captures stay current.
## The game logic runs every frame as before; only the drawing is skipped. Inert
## unless qa.py passes --qa-render-on-demand to a rendered (not headless) run, which
## it does only for journeys at a fixed frame rate (their timing never depends on
## how long a frame takes to draw).
## A SubViewport left at UPDATE_WHEN_VISIBLE renders only if the last drawn frame
## showed it, which with frames skipped may be a different screen (the lane went
## black in captures). Here it renders at every drawn frame instead (UPDATE_ALWAYS);
## frames not drawn render nothing, and what a capture shows is unchanged.
const EVERY := 30
var drawn := 0
var skipped := 0
var _frame := 0
var _baseline := 0

func _ready() -> void:
	if not OS.get_cmdline_user_args().has("--qa-render-on-demand") or DisplayServer.get_name() == "headless":
		queue_free()
		return
	process_priority = 1 << 30 # after everything else, so this frame's waits are seen
	process_mode = Node.PROCESS_MODE_ALWAYS
	_baseline = RenderingServer.frame_post_draw.get_connections().size()
	get_tree().node_added.connect(_always)
	for node in get_tree().root.find_children("*", "SubViewport", true, false): _always(node)
	RenderingServer.render_loop_enabled = false
	tree_exiting.connect(func(): print("QA_RENDER drawn=%d skipped=%d" % [drawn, skipped]))

func _always(node: Node) -> void:
	if node is SubViewport and node.render_target_update_mode == SubViewport.UPDATE_WHEN_VISIBLE:
		node.render_target_update_mode = SubViewport.UPDATE_ALWAYS

func _process(_delta: float) -> void:
	_frame += 1
	var draw := _frame % EVERY == 0 or RenderingServer.frame_post_draw.get_connections().size() > _baseline
	RenderingServer.render_loop_enabled = draw
	if draw: drawn += 1
	else: skipped += 1
