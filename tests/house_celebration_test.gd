extends RefCounted

static func run() -> Array[String]:
	var failures: Array[String] = []
	var cases: Array = []
	for file in DirAccess.get_files_at("res://assets/ui/alley_screen/house"):
		if file.ends_with(".tscn"):
			cases.append([file.trim_suffix(".tscn"),3.0 if file.begins_with("boss_") else (1.8 if file.begins_with("strike_") else 1.6)])
	for spec in cases:
		var scene = load("res://assets/ui/alley_screen/house/" + spec[0] + ".tscn").instantiate()
		if not is_equal_approx(scene.duration(),spec[1]): failures.append("House celebration duration: " + spec[0])
		var count := [0]
		scene.finished.connect(func(): count[0] += 1)
		scene.play({"reduced_motion":true})
		scene.skip()
		scene.skip()
		if count[0] != 1: failures.append("House celebration completion must be once: " + spec[0])
		scene.play({"reduced_motion":false})
		scene._process(spec[1]+0.01)
		scene.skip()
		if count[0] != 2: failures.append("House celebration replay completion: " + spec[0])
		if scene.mouse_filter != Control.MOUSE_FILTER_IGNORE: failures.append("House scene must not own input")
		scene.free()
	for event in ["strike", "spare", "boss_defeated"]:
		var sound = load("res://assets/ui/alley_screen/house/" + event + ".wav")
		if not sound is AudioStreamWAV or sound.get_length() < 0.2 or sound.get_length() > 1.5:
			failures.append("House sting must load and remain short: " + event)
	return failures
