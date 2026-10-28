extends Control
## Observes the real lab; never writes physics, equipment, frame reports or scores.
const ItemAssets = preload("res://src/presentation/item_assets.gd")
var lab: Control
var rival: TextureRect
var reaction: Label
var reaction_state := 0
var reaction_count := 0
var impact_count := 0
var score_highlights := 0
var _state := ""
var _seen_fallen := 0
var _seen_step := 0
var _trail: Array[Vector2] = []
var _impact := Vector2.ZERO
var _impact_age := 1.0
var _samples: Array[float] = []
var _physics_samples: Array[float] = []
var _draw_samples: Array[float] = []
var _reaction_time := 0.0

func _ready() -> void:
	name = "MotionDirector"
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter=MOUSE_FILTER_IGNORE
	rival=TextureRect.new()
	rival.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	rival.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rival.texture_filter=TEXTURE_FILTER_NEAREST
	rival.mouse_filter=MOUSE_FILTER_IGNORE
	add_child(rival)
	reaction=Label.new()
	reaction.add_theme_font_size_override("font_size",17)
	reaction.add_theme_color_override("font_outline_color",Color.BLACK)
	reaction.add_theme_constant_override("outline_size",5)
	reaction.mouse_filter=MOUSE_FILTER_IGNORE
	add_child(reaction)
	set_reaction(0,_line("entrance"))
	lab.frame_scored.connect(_scored)

## Only rivals with an original portrait appear here (E13): The Custodian's atlas.
## Other rivals (The Surveyor) wait for their E21 art and keep the HUD bubble only.
const PORTRAITS := ["rival.lab_custodian", "rival.custodian"]

## The Division's rival (previewed before the boss match; practice shows the first
## Division's), or {}.
func _rival() -> Dictionary:
	if lab.division == null:
		return {}
	return lab.division.rival_for(lab.division.boss())

func _line(key: String) -> String:
	var r := _rival()
	var fallback := {"entrance": "Show me a clean rack.", "impressed": "Clean sweep. Well played.", "confident": "A clever line."}
	return "%s\n%s" % [r.get("name", "The Custodian"), r.get("reactions", {}).get(key, fallback.get(key, ""))]

func set_reaction(index: int, text: String) -> void:
	reaction_state=index
	var atlas:=AtlasTexture.new()
	atlas.atlas=load("res://assets/motion/custodian.png")
	var width:=atlas.atlas.get_width()/3.0
	atlas.region=Rect2(index*width,0,width,atlas.atlas.get_height())
	rival.texture=atlas
	reaction.text=text
	_reaction_time=2.0

func _scored(scored: Dictionary) -> void:
	reaction_count+=1
	set_reaction(2 if scored.result.category=="strike" else 1,_line("impressed") if scored.result.category=="strike" else _line("confident"))

func _process(delta: float) -> void:
	if not lab.lane: return
	var ball_id: String = lab.lane.launch.get("ball_id", "ball.house") if lab.state in ["rolling", "result", "scoring", "frame_done"] else lab.armed_ball_id()
	ItemAssets.dress_ball(lab.lane.ball, ball_id)
	if is_instance_valid(lab.lane.aim_ball): ItemAssets.dress_ball(lab.lane.aim_ball, ball_id)
	rival.position=Vector2(16,270 if size.y>size.x else 88)
	rival.size=Vector2(76,108 if size.y>size.x else 72)
	reaction.position=rival.position+(Vector2(0,112) if size.y>size.x else Vector2(84,8))
	reaction.size=Vector2(220,44)
	rival.visible=lab.state in ["aim","holding","result","scoring","frame_done"] and not lab.settings_panel.visible and _rival().get("id","") in PORTRAITS
	reaction.visible=rival.visible
	if _state!=lab.state:
		_state=lab.state
		if _state=="aim":
			_trail.clear()
			_seen_fallen=0
			_seen_step=0
			set_reaction(0,_line("entrance"))
		elif _state=="rolling":
			_samples.clear()
			_physics_samples.clear()
			_draw_samples.clear()
	if lab.state in ["rolling","result","scoring"]:
		_samples.append(Performance.get_monitor(Performance.TIME_PROCESS)*1000)
		_physics_samples.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000)
		_draw_samples.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		if _samples.size()>3600:
			_samples.pop_front()
			_physics_samples.pop_front()
			_draw_samples.pop_front()
	if lab.state=="rolling":
		var point: Vector2=lab.screen_point(lab.lane.ball_position())
		if not lab.settings.reduced_motion and not lab.settings.reduced_flash:
			_trail.append(point)
			if _trail.size()>10: _trail.pop_front()
		else: _trail.clear()
		var fallen: int=lab.lane.tracker.sequence.size()
		if fallen>_seen_fallen:
			impact_count+=fallen-_seen_fallen
			_seen_fallen=fallen
			_impact=point
			_impact_age=0
			if reaction_state==0: set_reaction(1,"That got my attention.")
	else: _trail.clear()
	if lab.state=="scoring" and lab.score_panel.shown!=_seen_step:
		_seen_step=lab.score_panel.shown
		score_highlights+=1
	_impact_age+=delta
	_reaction_time=maxf(0,_reaction_time-delta)
	rival.modulate=Color.WHITE
	if not lab.settings.reduced_motion and _reaction_time>1.8:
		rival.modulate=Color(1,1,1,lerpf(0.5,1.0,(2.0-_reaction_time)/0.2))
	queue_redraw()

func _draw() -> void:
	if lab==null or lab.settings.reduced_motion or lab.settings.reduced_flash: return
	for i in range(1,_trail.size()):
		draw_line(_trail[i-1],_trail[i],Color(0.37,0.85,0.8,float(i)/_trail.size()*0.45),3,true)
	if _impact_age<0.22:
		var t:=_impact_age/0.22
		draw_arc(_impact,12+t*35,0,TAU,32,Color(0.95,0.78,0.45,(1-t)*0.65),3,true)

func metrics() -> Dictionary:
	return {"samples":_samples.size(),"process_ms":_summary(_samples),"physics_ms":_summary(_physics_samples),"draw_calls":_summary(_draw_samples),
		"scope":"Godot CPU monitors under this renderer; not GPU time or device certification", "renderer":RenderingServer.get_video_adapter_name(),
		"reduced_motion":lab.settings.reduced_motion,"impacts":impact_count,"score_highlights":score_highlights,"reactions":reaction_count}

func _summary(values: Array[float]) -> Dictionary:
	if values.is_empty(): return {}
	var ordered:=values.duplicate()
	ordered.sort()
	return {"p50":ordered[int((ordered.size()-1)*0.5)],"p95":ordered[int((ordered.size()-1)*0.95)],"max":ordered[-1]}
