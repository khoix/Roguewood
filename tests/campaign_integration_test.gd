extends RefCounted
const Content = preload("res://src/rules/content_set.gd")
const League = preload("res://src/rules/league_run.gd")
const Snapshot = preload("res://src/persistence/attempt_snapshot.gd")
const SaveTests = preload("res://tests/save_test.gd")
const Lane = preload("res://src/simulation/lane_spec.gd")
const Shop = preload("res://src/rules/shop.gd")
const Streams = preload("res://src/procedural/random_streams.gd")
static func run() -> Array[String]:
	var errors: Array[String] = []
	var content := Content.load_set("campaign", 42)
	if not content.errors.is_empty(): return [str(content.errors)]
	var lab_content := Content.load_set("lab")
	var parts: Dictionary = SaveTests._parts(lab_content.catalogue, lab_content.divisions[0], "deck")
	# Persistence semantics are independent of the kit: use the existing lab kit
	# with campaign progression and its catalogue of implemented rival rules.
	var league = League.create(content.divisions)
	league.campaign = content.campaign
	for i in range(12):
		league.record_frame(league.target())
		league.next_match()
	parts.division = league
	parts.seed = 42
	parts.phase = "shop"
	var payload: Dictionary = JSON.parse_string(JSON.stringify(Snapshot.build(parts, content.hashes, "campaign"), "", true, true))
	# Validate rule/schedule corruption separately from fixture inventory IDs.
	var catalogue: Dictionary = content.catalogue.duplicate(true)
	for item in lab_content.catalogue.items:
		if not catalogue.items.any(func(x): return x.id == item.id): catalogue.items.append(item)
	_check(Snapshot.validate(payload, catalogue, "campaign").is_empty(), "campaign snapshot accepted", errors)
	var restored := Snapshot.restore(payload, catalogue, content.divisions, content.hashes)
	_check(restored.division.division_number() == 5 and restored.division.results.size() == 12, "midcampaign resumes exact progress", errors)
	_check(restored.division.specs == payload.division.campaign.divisions, "saved schedule used", errors)
	var bad := payload.duplicate(true)
	bad.division.campaign.divisions[0].matches[0].target += 1
	_check(not Snapshot.validate(bad, catalogue, "campaign").is_empty(), "altered target refuses load", errors)
	var stream = Streams.create(42)
	var shop_a = Shop.create(catalogue, int(stream.states.shops))
	for i in range(100): stream.draw("effects", 7)
	var shop_b = Shop.create(catalogue, int(stream.states.shops))
	shop_a.open_visit(parts.run, 1)
	shop_b.open_visit(parts.run, 1)
	_check(shop_a.offers == shop_b.offers, "effect draws cannot perturb real shop offers", errors)
	_check(Lane.ball_friction(14.0, "lane.dry") > Lane.ball_friction(14.0), "dry backend changes friction", errors)
	_check(Lane.ball_friction(5.0, "lane.dry") == Lane.ball_friction(5.0) and Lane.ball_friction(18.0, "lane.dry") == Lane.ball_friction(18.0), "oil/deck zones unchanged", errors)
	return errors
static func _check(ok: bool, message: String, errors: Array[String]) -> void:
	if not ok: errors.append(message)
