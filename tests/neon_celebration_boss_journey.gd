extends "res://tests/neon_league_journey.gd"
## UI-A9-N (Claude, 2026-11-24): the live Neon set in the real eight-Division Neon
## League (J22L02's run, real input): each boss win plays one of that rival's own two
## endings with the Neon boss sting, before the Division Result; strikes play Neon's
## strike scenes, never the House set's.
const ENDINGS := {
	"rival.slick": ["boss_slick_slip", "boss_slick_squeegee"],
	"rival.laser_lena": ["boss_laser_lena_lights_out", "boss_laser_lena_tangle"],
	"rival.dj_flicker": ["boss_dj_flicker_power_down", "boss_dj_flicker_scratch"],
	"rival.dj_flicker_champion": ["boss_dj_flicker_champion_headline", "boss_dj_flicker_champion_encore"],
}

func _play_match(division: int, m: Dictionary) -> void:
	var alley = lab.alley_screen
	_check(alley.variants_override.is_empty(), "UI-A9-N: the live Neon manifest, no overrides")
	_check(lab.league_theme.manifest.get("league_id", "") == "league.neon", "UI-A9-N: the Neon theme is in force")
	var bosses := func(): return alley.played.filter(func(p): return p.event == "boss_defeated").size()
	var before: int = bosses.call()
	await super._play_match(division, m)
	# AV-UI1: a button pressed in a Neon match (the match's own Begin, Next, keep)
	# makes a Neon click.
	var ui: Node = scene.ui_sounds
	_check(ui.league() == "league.neon" and ui.played > 0 and ui.last_stream == ui.sound_for(ui.last_kind, "league.neon")
		and String(ui.last_stream.resource_path).ends_with(".neon.wav"), "AV-UI1: D%d's buttons make Neon's sounds (%s)" % [division, ui.last_stream.resource_path if ui.last_stream else "none"])
	var strikes: Array = alley.played.filter(func(p): return p.event == "strike")
	_check(not strikes.is_empty() and strikes.all(func(p): return String(p.path).begins_with("res://assets/ui/alley_screen/neon/strike_")),
		"UI-A9-N: D%d strikes play Neon's strike scenes" % division)
	if m.kind != "boss":
		_check(bosses.call() == before, "UI-A9-N: an ordinary match has no boss celebration")
		return
	await _wait_for(func(): return alley.playing() and alley.current_event == "boss_defeated", "the boss celebration's turn", 600)
	var own: Array = ENDINGS[m.rival].map(func(key): return "res://assets/ui/alley_screen/neon/%s.tscn" % key)
	_check(bosses.call() == before + 1, "UI-A9-N: one celebration per boss win")
	_check(alley.current_path in own and alley.current_context.rival_id == m.rival, "UI-A9-N: %s plays one of its own endings (%s)" % [m.rival, alley.current_path])
	var stream: AudioStream = lab.league_theme.celebration_sound("boss_defeated")
	_check(stream != null and String(stream.resource_path).begins_with("res://assets/ui/alley_screen/neon/")
		and lab.motion.sound.voices.any(func(v): return v.playing and v.stream == stream), "UI-A9-N: the Neon boss sting plays")
	_check(not lab.next_rack.visible, "UI-A9-N: the Division Result waits for the celebration")
	await _capture("neon_boss_d%02d" % division)
	if division % 2 == 1:
		alley.skip()
	else:
		await _wait_for(func(): return not alley.playing(), "the boss ending finishes", 300)
	_check(lab.next_rack.visible, "UI-A9-N: the Division Result follows the celebration")
