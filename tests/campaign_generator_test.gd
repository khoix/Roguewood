extends RefCounted
const Generator = preload("res://src/procedural/campaign_generator.gd")
const Streams = preload("res://src/procedural/random_streams.gd")
const Division = preload("res://src/rules/division_run.gd")

static func run() -> Array[String]:
	var errors: Array[String] = []
	# Synthetic rules test constraints only; these are NOT playable catalogue items.
	var base: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://content/fixtures/lab_division.json"))
	var profile := {"id": "test", "championship_reuses_encountered_rule": true, "division_template": base, "bosses": [], "lanes": [{"id": "lane.a", "text": "A"}, {"id": "lane.b", "text": "B"}], "targets": []}
	var catalogue := {"items": []}
	for i in range(7):
		var boss: Dictionary = base.rivals[0].duplicate(true)
		boss.id = "rival.test%d" % i
		boss.rule = "boss_rule.test%d" % i
		boss["compatible_lanes"] = ["lane.a"] if i % 2 == 0 else ["lane.a", "lane.b"]
		profile.bosses.append(boss)
		catalogue.items.append({"id": boss.rule, "category": "boss_rule"})
	for i in range(8): profile.targets.append([100 + i * 400, 200 + i * 400, 300 + i * 400])
	_check(Generator.validate(profile, catalogue).is_empty(), "valid profile", errors)
	var first := Generator.generate(42, profile, catalogue)
	_check(first == Generator.generate(42, profile, catalogue), "same seed repeatability", errors)
	_check(first != Generator.generate(43, profile, catalogue), "different seed variation", errors)
	for seed_value in range(200):
		var schedule := Generator.generate(seed_value, profile, catalogue)
		_check(Generator.validate_schedule(schedule, profile, catalogue).is_empty(), "generated schedule recovers", errors)
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
	_check(Streams.restore({"version": 99}) == null, "unknown RNG version rejected", errors)
	var endless := Generator.extend_endless(first, profile, catalogue, [3200, 3300, 3400], true)
	_check(endless.get("divisions", []).size() == 9 and first.divisions.size() == 8, "endless append without mutation", errors)
	var saved: Dictionary = JSON.parse_string(JSON.stringify(first, "", true, true))
	_check(JSON.parse_string(JSON.stringify(endless, "", true, true)) == JSON.parse_string(JSON.stringify(Generator.extend_endless(saved, profile, catalogue, [3200, 3300, 3400], true), "", true, true)), "endless save reproducibility", errors)
	_check(not Generator.extend_endless(first, profile, catalogue, [3200, 3300, 3400], false).errors.is_empty(), "no endless before win", errors)
	var bad := profile.duplicate(true)
	bad.bosses.pop_back()
	_check(not Generator.generate(42, bad, catalogue).errors.is_empty(), "insufficient boss pool refused", errors)
	bad = profile.duplicate(true)
	bad.bosses[0].compatible_lanes = ["missing"]
	_check(not Generator.generate(42, bad, catalogue).errors.is_empty(), "incompatible pool refused", errors)
	bad = profile.duplicate(true)
	bad.targets[0] = [100, 90, 200]
	_check(not Generator.generate(42, bad, catalogue).errors.is_empty(), "bad target curve refused", errors)

	# Regression checks from the second review: authored exceptions, boundary
	# targets, pool-order independence, and hostile/corrupt saved records.
	var reordered := profile.duplicate(true)
	reordered.bosses.reverse()
	reordered.lanes.reverse()
	for boss in reordered.bosses: boss.compatible_lanes.reverse()
	_check(first == Generator.generate(42, reordered, catalogue), "pool ordering independent", errors)
	bad = profile.duplicate(true)
	bad.erase("championship_reuses_encountered_rule")
	_check(not Generator.generate(42, bad, catalogue).errors.is_empty(), "no implicit championship exception", errors)
	var eighth: Dictionary = bad.bosses[0].duplicate(true)
	eighth.id = "rival.eighth"
	bad.bosses.append(eighth)
	var unique := Generator.generate(42, bad, catalogue)
	_check(unique.errors.is_empty(), "distinct bosses may share a rule", errors)
	if unique.errors.is_empty():
		var ids := {}
		for spec in unique.divisions: ids[spec.rivals[0].id] = true
		_check(ids.size() == 8, "eight unique bosses by default", errors)
	bad = profile.duplicate(true)
	bad.targets[1] = [200, 400, 600]
	_check(not Generator.generate(42, bad, catalogue).errors.is_empty(), "boundary target drop refused", errors)
	_check(not Generator.extend_endless(first, profile, catalogue, [3000, 3100, 3200], true).errors.is_empty(), "endless cannot drop below previous boss", errors)
	for replacement in [null, {}, [], "bad", {"matches": [null, null, null]}]:
		var corrupt := first.duplicate(true)
		corrupt.divisions[0] = replacement
		_check(not Generator.validate_schedule(corrupt, profile, catalogue).is_empty(), "malformed saved Division refused", errors)
	for field in ["preview", "matches", "rivals"]:
		var corrupt := first.duplicate(true)
		corrupt.divisions[0].erase(field)
		_check(not Generator.validate_schedule(corrupt, profile, catalogue).is_empty(), "missing saved field " + field, errors)
	var corrupt := first.duplicate(true)
	corrupt.divisions[0].matches[0].target += 1
	_check(not Generator.validate_schedule(corrupt, profile, catalogue).is_empty(), "saved target tampering refused", errors)
	corrupt = first.duplicate(true)
	corrupt.rng.states.lanes += 1
	_check(not Generator.validate_schedule(corrupt, profile, catalogue).is_empty(), "saved schedule RNG tampering refused", errors)
	bad = profile.duplicate(true)
	bad.targets[7][2] += 1
	_check(not Generator.validate_schedule(first, bad, catalogue).is_empty(), "profile changes refused", errors)
	_check(Generator.validate_schedule(saved, profile, catalogue).is_empty(), "saved standard schedule accepted", errors)
	_check(Generator.validate_schedule(endless, profile, catalogue).is_empty(), "saved endless schedule accepted", errors)
	var twice := Generator.extend_endless(endless, profile, catalogue, [3500, 3600, 3700], true)
	_check(twice.errors.is_empty() and twice.divisions.size() == 10, "successive endless continuation", errors)
	var stream_state: Dictionary = rng.to_dict()
	_check(rng.draw("missing", 10) == -1 and rng.draw("shops", 0) == -1 and rng.to_dict() == stream_state, "invalid draws fail without mutation", errors)
	_check(Streams.create(42).to_dict() != Streams.create(42 + 2147483646).to_dict(), "seed upper bits retained", errors)
	for state in [0, -1, 1.5, 2147483647, INF, NAN, "bad"]:
		var corrupt_rng: Dictionary = rng.to_dict()
		corrupt_rng.states.shops = state
		_check(Streams.restore(corrupt_rng) == null, "invalid RNG values refused", errors)
	return errors

static func _check(ok: bool, label: String, errors: Array[String]) -> void:
	if not ok and label not in errors: errors.append(label)
