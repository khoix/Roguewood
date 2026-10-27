extends RefCounted
const Generator = preload("res://src/procedural/campaign_generator.gd")
const Streams = preload("res://src/procedural/random_streams.gd")
const Division = preload("res://src/rules/division_run.gd")

static func run() -> Array[String]:
	var errors: Array[String] = []
	# Synthetic rules test constraints only; these are NOT playable catalogue items.
	var base: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://content/fixtures/lab_division.json"))
	var profile := {"id": "test", "division_template": base, "bosses": [], "lanes": [{"id": "lane.a", "text": "A"}, {"id": "lane.b", "text": "B"}], "targets": []}
	var catalogue := {"items": []}
	for i in range(7):
		var boss: Dictionary = base.rivals[0].duplicate(true)
		boss.id = "rival.test%d" % i
		boss.rule = "boss_rule.test%d" % i
		boss["compatible_lanes"] = ["lane.a"] if i % 2 == 0 else ["lane.a", "lane.b"]
		profile.bosses.append(boss)
		catalogue.items.append({"id": boss.rule, "category": "boss_rule"})
	for i in range(8): profile.targets.append([100 + i * 100, 200 + i * 100, 300 + i * 100])
	_check(Generator.validate(profile, catalogue).is_empty(), "valid profile", errors)
	var first := Generator.generate(42, profile, catalogue)
	_check(first == Generator.generate(42, profile, catalogue), "same seed repeatability", errors)
	_check(first != Generator.generate(43, profile, catalogue), "different seed variation", errors)
	for seed_value in range(200):
		var schedule := Generator.generate(seed_value, profile, catalogue)
		var seen := {}
		for i in range(8):
			var spec: Dictionary = schedule.divisions[i]
			_check(Division.validate_spec(spec, catalogue).is_empty(), "DivisionRun contract", errors)
			var boss: Dictionary = spec.rivals[0]
			_check(not seen.has(boss.id) if i < 7 else seen.has(boss.id), "unique bosses / encountered championship", errors)
			seen[boss.id] = true
			for match_data in spec.matches:
				_check(match_data.lane_condition in boss.compatible_lanes, "legal pairing", errors)
			_check(spec.preview.matches == spec.matches, "preview exact fixed targets", errors)
			var run = Division.create(spec)
			for m in range(3):
				_check(run.record_frame(run.target()).won, "campaign target wins", errors)
				if m < 2: _check(run.next_match().is_empty(), "advance match", errors)
			_check(run.outcome == "won", "Division won", errors)
		var failed = Division.create(schedule.divisions[0])
		failed.record_frame(0)
		failed.record_frame(0)
		_check(failed.outcome == "lost" and not failed.next_match().is_empty(), "failure ends Division", errors)
	var rng = Streams.create(42)
	var other = Streams.create(42)
	for i in range(100): rng.draw("effects", 17)
	_check(rng.draw("shops", 1000) == other.draw("shops", 1000), "stream isolation", errors)
	var restored = Streams.restore(JSON.parse_string(JSON.stringify(rng.to_dict(), "", true, true)))
	for stream in Streams.NAMES:
		_check(rng.draw(stream, 73) == restored.draw(stream, 73), "JSON continuation " + stream, errors)
	_check(Streams.restore({"version": 2}) == null, "unknown RNG version rejected", errors)
	var endless := Generator.extend_endless(first, profile, catalogue, [1000, 1100, 1200], true)
	_check(endless.get("divisions", []).size() == 9 and first.divisions.size() == 8, "endless append without mutation", errors)
	var saved: Dictionary = JSON.parse_string(JSON.stringify(first, "", true, true))
	_check(JSON.parse_string(JSON.stringify(endless, "", true, true)) == JSON.parse_string(JSON.stringify(Generator.extend_endless(saved, profile, catalogue, [1000, 1100, 1200], true), "", true, true)), "endless save reproducibility", errors)
	_check(not Generator.extend_endless(first, profile, catalogue, [1000, 1100, 1200], false).errors.is_empty(), "no endless before win", errors)
	var bad := profile.duplicate(true)
	bad.bosses.pop_back()
	_check(not Generator.generate(42, bad, catalogue).errors.is_empty(), "insufficient boss pool refused", errors)
	bad = profile.duplicate(true)
	bad.bosses[0].compatible_lanes = ["missing"]
	_check(not Generator.generate(42, bad, catalogue).errors.is_empty(), "incompatible pool refused", errors)
	bad = profile.duplicate(true)
	bad.targets[0] = [100, 90, 200]
	_check(not Generator.generate(42, bad, catalogue).errors.is_empty(), "bad target curve refused", errors)
	return errors

static func _check(ok: bool, label: String, errors: Array[String]) -> void:
	if not ok and label not in errors: errors.append(label)
