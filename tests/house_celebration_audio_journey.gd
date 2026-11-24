extends "res://tests/scoring_journey.gd"
## Test-only sound entries exercise the shipping AlleyScreen -> theme -> mixer
## path without prematurely enabling the incomplete House manifest.
const SOUND_CASES := {"strike":"strike_pinwheel", "spare":"spare_last_chair", "boss_defeated":"boss_surveyor_tape"}

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--artifact-dir="): artifact_dir = arg.trim_prefix("--artifact-dir=")
	root.size = PORTRAIT
	scene = load("res://src/bootstrap/bootstrap.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await _wait_for(func(): return scene.enter.has_focus(), "menu focus")
	await _action("ui_accept")
	await _wait_for(func(): return scene.lab != null and scene.lab.state == "aim", "real lab ready")
	lab = scene.lab
	lab.trial_log_path = ""
	var sound = lab.motion.sound
	var alley = lab.alley_screen
	var theme = lab.league_theme
	_check(theme != null,"House theme available for sound path")
	if theme == null: quit(1); return
	var saved: Dictionary = theme.manifest.duplicate(true)
	var entries := {}
	for event in SOUND_CASES:
		entries[event] = "res://assets/ui/alley_screen/house/"+event+".wav"
		alley.variants_override[event] = ["res://assets/ui/alley_screen/house/"+SOUND_CASES[event]+".tscn"]
	theme.manifest["celebration_sounds"] = entries
	await _focus_accept(scene.sound_entry)
	await _slide(sound.volume_slider,0.5)
	await _focus_accept(sound.back_button)
	await _focus_accept(scene.resume)
	_check(is_equal_approx(sound.volume,0.5),"effects slider sets half level")
	for event in SOUND_CASES:
		var stream: AudioStream = theme.celebration_sound(event)
		var before: int = sound.played
		_check(alley.celebrate(event,{"rival_id":"rival.surveyor","rival_name":"The Surveyor"}),"plays " + event)
		_check(sound.played == before+1,"one sting through production mixer: " + event)
		var voices: Array = sound.voices.filter(func(v): return v.playing and v.stream == stream)
		_check(voices.size() == 1,"correct event stream: " + event)
		if not voices.is_empty():
			_check(is_equal_approx(voices[0].volume_db,linear_to_db(0.5*0.35)),"effects volume gain: " + event)
		await _capture("audio_"+event)
		alley.skip()
		for voice in sound.voices: voice.stop()
	await _focus_accept(scene.sound_entry)
	await _focus_accept(sound.mute_button)
	await _focus_accept(sound.back_button)
	await _focus_accept(scene.resume)
	_check(sound.muted and sound.voices.all(func(v): return not v.playing),"Mute stops active effect voices")
	for event in SOUND_CASES:
		var before: int = sound.played
		var suppressed: int = sound.suppressed
		alley.celebrate(event,{"rival_id":"rival.surveyor"})
		_check(sound.played == before and sound.suppressed == suppressed+1,"Mute suppresses sting: "+event)
		_check(alley.visible,"Mute preserves celebration picture")
		alley.skip()
	await _focus_accept(scene.sound_entry)
	await _focus_accept(sound.mute_button)
	await _slide(sound.volume_slider,0.0)
	await _focus_accept(sound.back_button)
	await _focus_accept(scene.resume)
	for event in SOUND_CASES:
		var before: int = sound.played
		alley.celebrate(event,{"rival_id":"rival.surveyor"})
		_check(sound.played == before,"zero effects volume suppresses " + event)
		alley.skip()
	_check(theme.music != null and theme.music.playing,"celebrations do not stop the music")
	await _check_low_portrait()
	theme.manifest = saved
	alley.variants_override = {}
	if failures.is_empty(): print("ROGUEWOOD_UIA9HA_OK")
	quit(0 if failures.is_empty() else 1)

func _check_low_portrait() -> void:
	var alley = lab.alley_screen
	alley.celebrate("boss_defeated",{"rival_id":"rival.surveyor","rival_name":"The Surveyor","reduced_motion":true})
	var art = alley.current
	art.set_process(false) # Hold this still while the user changes texture detail.
	var gfx = root.get_node("Graphics")
	_check(art.texture is AtlasTexture,"Normal draws the original portrait atlas")
	var original: WeakRef = weakref(art.texture)
	await _focus_accept(scene.graphics_entry)
	gfx.texture_choice.select(0)
	gfx.texture_choice.item_selected.emit(0)
	await _wait_for(func(): return art.texture is AtlasTexture and maxi(art.texture.atlas.get_width(),art.texture.atlas.get_height()) <= 512,"Low replaces the held portrait's sheet",300)
	_check(original.get_ref() == null,"held celebration releases its original atlas view at Low")
	gfx.texture_choice.select(1)
	gfx.texture_choice.item_selected.emit(1)
	await _wait_for(func(): return art.texture is AtlasTexture and maxi(art.texture.atlas.get_width(),art.texture.atlas.get_height()) > 512,"Normal restores the held portrait",300)
	alley.skip()
