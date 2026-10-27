extends "res://tests/deck_journey.gd"
## J08 drives native controls on the actual lab. No direct launch/score injection.
var metrics_report: Array = []
var reduced_only := false
var landscape_only := false

func _initialize() -> void:
	var landscape := "--landscape" in OS.get_cmdline_user_args()
	root.size = Vector2i(1280,720) if landscape else Vector2i(720,1280)
	root.content_scale_size = root.size
	call_deferred("_run")

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--artifact-dir="): artifact_dir=arg.trim_prefix("--artifact-dir=")
		if arg=="--reduced": reduced_only=true
		if arg=="--landscape": landscape_only=true
	root.size=Vector2i(1280,720) if landscape_only else Vector2i(720,1280)
	catalogue=Contracts.read_json(FrameBuilder.LAB_CATALOGUE)
	scene=load("res://src/bootstrap/bootstrap.tscn").instantiate()
	scene.throw_settings = {"practice": true}
	root.add_child(scene)
	await process_frame
	await _focus_accept(scene.enter)
	await _wait_for(func(): return scene.lab!=null and scene.lab.state=="aim","lab ready")
	lab=scene.lab
	lab.trial_log_path=""
	await _focus_accept(scene.options)
	await _focus_accept(lab.settings_panel.assist)
	if reduced_only:
		await _focus_accept(lab.settings_panel.reduced_motion)
		await _focus_accept(lab.settings_panel.reduced_flash)
	await _focus_accept(lab.settings_panel.close)
	await _capture("aim")
	var uid:=_find("ball")
	var before: Dictionary=lab.equipment.counts().duplicate(true)
	await _tap(lab.card_hand.inspect_button)
	await _click(_card(uid))
	await _wait_for(func(): return lab.inspector.visible,"inspection opens")
	await process_frame
	await process_frame
	_check(Rect2(Vector2.ZERO, lab.size).encloses(lab.inspector.panel.get_global_rect()), "inspection fits viewport: lab=%s panel=%s" % [lab.size, lab.inspector.panel.get_global_rect()])
	_check(lab.armed_ball.is_empty(),"inspection does not arm the card")
	_check(lab.equipment.counts()==before,"inspection does not consume a card")
	# A real pointer movement changes foil; reduced motion fixes its direction.
	await _focus_accept(lab.inspector.finish)
	await _action("ui_down",3)
	await _action("ui_accept")
	var pointer:=InputEventMouseMotion.new()
	pointer.position=_window(lab.inspector.art.get_global_rect().position+lab.inspector.art.size*Vector2(0.8,0.4))
	Input.parse_input_event(pointer)
	await process_frame
	var tilt: Vector2=lab.inspector.foil.get_shader_parameter("tilt")
	_check(tilt==Vector2.ZERO if reduced_only else tilt.length()>0.01,"foil follows pointer only in full motion")
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = _window(lab.inspector.art.get_global_rect().position + lab.inspector.art.size * Vector2(0.2, 0.6))
	Input.parse_input_event(drag)
	await process_frame
	var touch_tilt: Vector2 = lab.inspector.foil.get_shader_parameter("tilt")
	_check(touch_tilt == Vector2.ZERO if reduced_only else touch_tilt.x < 0, "touch drag controls foil without playing a card")
	_check(lab.state == "aim" and lab.armed_ball.is_empty(), "inspection drag cannot start a throw")
	await _capture("foil")
	await _focus_accept(lab.inspector.finish)
	await _action("ui_down")
	await _action("ui_accept")
	_check(lab.inspector.reveal_count==1,"legendary preview starts once")
	if not reduced_only:
		_check(lab.inspector.revealing,"reveal animates")
		await _focus_accept(lab.inspector.skip_button)
	_check(not lab.inspector.revealing and lab.inspector.art.scale==Vector2.ONE,"skip/reduced reveal settles immediately")
	await _capture("reveal")
	await _action("ui_cancel")
	_check(not lab.inspector.visible,"Escape closes inspection")
	_check(lab.equipment.counts()==before and lab.armed_ball.is_empty(),"finish previews never alter equipment")
	await _tap(_card(uid))
	_check(lab.armed_ball==uid,"card still playable after inspection")
	var camera_before: Vector3=lab._camera.position
	await _slide(lab.assist_panel.position_slider,0.1)
	await _slide(lab.assist_panel.power_slider,0.7)
	await _slide(lab.assist_panel.spin_slider,0.25)
	await _focus_accept(lab.assist_panel.throw_button)
	_check(lab.state=="rolling","real throw starts")
	_check(lab.card_hand.inspect_button.disabled,"inspection locked during roll")
	for i in 30: await process_frame
	await _capture("rolling")
	if reduced_only: _check(lab._camera.position==camera_before,"reduced-motion camera remains fixed")
	await _wait_for(func(): return lab.motion.impact_count>0 or lab.state=="result","impact",ROLL_FRAMES)
	await _capture("impact")
	await _wait_for(func(): return lab.state in ["aim","scoring","frame_done"],"roll resolves",ROLL_FRAMES)
	if lab.state=="aim": await _throw(CLEANUP)
	await _wait_for(func(): return lab.state=="scoring","scoring begins",ROLL_FRAMES)
	await _capture("scoring")
	# Let normal ordering play before checking the immutable rules result.
	await _wait_for(func(): return lab.state=="frame_done","score animation finishes",ROLL_FRAMES)
	var built: Dictionary=FrameBuilder.build(FrameBuilder.lab_loadout(),catalogue,lab.frame_reports,{})
	var expected: Dictionary=Rules.resolve(built.frame)
	_check(lab.total_score==expected.score,"presentation banks exactly the rules score")
	_check(lab.score_panel.shown==lab.score_panel.steps.size(),"every score step remains available")
	_check(lab.motion.reaction_count==1,"one rival reaction per completed frame")
	_check(lab.motion.impact_count>0,"real pinfall triggered impact presentation")
	if reduced_only: _check(lab.motion._trail.is_empty(),"reduced motion has no trail")
	await process_frame
	await process_frame
	_check(not lab.card_hand.get_global_rect().intersects(lab.score_panel.get_global_rect()), "retained hand does not cover score")
	_check(not lab.next_rack.get_global_rect().intersects(lab.score_panel.get_global_rect()), "Next Rack remains outside score panel")
	await _capture("reaction")
	metrics_report.append(lab.motion.metrics())
	await _focus_accept(lab.next_rack)
	await _wait_for(func(): return lab.state=="aim","return to decision")
	_check(not lab.inspector.visible and not lab.card_hand.inspect_button.disabled,"inspection usable after scoring")
	await _capture("returned")
	if not artifact_dir.is_empty():
		var file:=FileAccess.open(artifact_dir.path_join("metrics.json"),FileAccess.WRITE)
		file.store_string(JSON.stringify(metrics_report,"  "))
	if "--inject-failure" in OS.get_cmdline_user_args(): _check(false,"Injected diagnostic failure")
	if not failures.is_empty(): await _capture("failure")
	if failures.is_empty(): print("ROGUEWOOD_J08_OK")
	quit(0 if failures.is_empty() else 1)
