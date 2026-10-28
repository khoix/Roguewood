extends SceneTree
## Writes the golden save fixtures (tests/fixtures/saves/v<N>/) used by save_test:
## a mid-attempt snapshot (feature match, roll 2 committed but unresolved, after a
## purchase, a reroll and a cycle) and a Career profile with one first clear.
## Version 1 files are frozen: every later schema version must keep loading them
## through its migrations. Regenerate only to add a new version's fixtures.
## Usage: godot --headless --script res://tools/make_save_fixture.gd -- --out=<dir>
## E15 adds the frozen schema 2 Career (tests/fixtures/saves/v2/career.json):
##   ... -- --out=<dir> --career-v2
const Store = preload("res://src/persistence/save_store.gd")
const Snapshot = preload("res://src/persistence/attempt_snapshot.gd")
const Career = preload("res://src/persistence/career_profile.gd")
const Inventory = preload("res://src/rules/run_inventory.gd")
const Shop = preload("res://src/rules/shop.gd")
const Deck = preload("res://src/rules/card_deck.gd")
const Division = preload("res://src/rules/division_run.gd")
const Contracts = preload("res://src/contracts/contracts.gd")
const Builder = preload("res://src/rules/frame_builder.gd")
const Lane = preload("res://src/simulation/lane_spec.gd")
const ScoringTest = preload("res://tests/scoring_test.gd")
const DIVISION := "res://content/fixtures/lab_division.json"
const DECK := ["ball.lab_value", "ball.lab_value", "ball.lab_mult", "ball.lab_mult", "ball.lab_coin", "ball.lab_coin", "consumable.lab_focus"]

func _init() -> void:
	var out := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
	if "--career-v2" in OS.get_cmdline_user_args():
		_career_v2(out)
		return
	var parts := golden_parts()
	var store = Store.create(out)
	store.clear("attempt")
	store.clear("career")
	var errors: Array[String] = store.write("attempt", Snapshot.build(parts, Snapshot.content_hashes(Builder.LAB_CATALOGUE, DIVISION)))
	var career := Career.fresh()
	var spec: Dictionary = Contracts.read_json(DIVISION)
	Career.record_first_clear(career, spec.rivals[0], 2)
	career.intros_seen[spec.rivals[0].id] = true
	errors.append_array(store.write("career", career))
	for suffix in [".bak", ".tmp"]:
		for kind in ["attempt", "career"]:
			DirAccess.remove_absolute(store.path(kind, suffix))
	print("errors=%s" % str(errors))
	print("ROGUEWOOD_FIXTURE_OK" if errors.is_empty() else "ROGUEWOOD_FIXTURE_FAILED")
	quit(0 if errors.is_empty() else 1)

## The fixed state behind the golden attempt; save_test rebuilds it to compare.
static func golden_parts() -> Dictionary:
	var catalogue: Dictionary = Contracts.read_json(Builder.LAB_CATALOGUE)
	var spec: Dictionary = Contracts.read_json(DIVISION)
	var wood: Array = []
	wood.resize(10)
	wood.fill("pin.wood")
	var run = Inventory.create(catalogue, wood, DECK)
	run.credit(1, "item_income", "ball.lab_coin")
	var settlement: Dictionary = run.settle_match(1)
	var shop = Shop.create(catalogue, hash([1, "shop"]))
	shop.open_visit(run, 1)
	shop.buy(3, "card:new", run) # the tactical slot's card into the deck
	shop.reroll(run)
	var division = Division.create(spec)
	division.record_frame(560)
	division.next_match()
	division.record_frame(240)
	var deck = Deck.create_with(run.deck_cards(), 1)
	deck.start_frame()
	deck.cycle(deck.hand[0])
	deck.play(deck.hand[0], 1)
	var all := range(1, 11)
	var first: Dictionary = ScoringTest.report(1, [2, 4, 5, 7, 8, 9, 10], all)
	var rack := {"schema_version": 1, "standing": []}
	for position in [1, 3, 6]:
		var at := Lane.spot(position)
		rack.standing.append({"position": position, "x": at.x + 0.0123456789, "f": at.y})
	first["rack_after"] = rack
	var second: Dictionary = ScoringTest.report(2, [1, 3, 6], [1, 3, 6])
	var lab := {"frame_number": 3, "roll_index": 2, "match_number": 2, "match_frame": 1, "total_score": 560, "launch_serial": 3,
		"rack": rack, "frame_reports": [first], "frame_tactics": {1: ["consumable.lab_focus"]}, "frame_mods": {},
		"kept_last_frame": "", "equipment_model": "deck", "settlement": settlement, "last_scored": null,
		"pending": {"launch": second.launch, "input": {"source": "assist"}}, "result": null}
	return {"attempt": 1, "seed": 1, "phase": "committed", "lab": lab, "run": run, "shop": shop, "division": division, "equipment": deck}

## Career v2 (E15, ADR 010): two lab attempts, the rival's first clear, one spare
## counted, a lab title won with Wood pins owned.
func _career_v2(out: String) -> void:
	var store = Store.create(out)
	store.clear("career")
	var career := Career.fresh()
	var spec: Dictionary = Contracts.read_json(DIVISION)
	Career.begin_attempt(career)
	var uid := Career.begin_attempt(career)
	Career.record_items(career, ["pin.wood", "ball.lab_value"], uid)
	Career.bank_frame(career, uid, 1, {"spares": 1, "strikes": 0, "curved_strikes": 0, "materials": ["pin.wood"]},
		{"league": "league.lab", "practice": false, "division": 1, "total": 240, "frame_score": 240}, [])
	Career.record_first_clear(career, spec.rivals[0], 2, uid)
	career.intros_seen[spec.rivals[0].id] = true
	Career.record_championship(career, {"id": "league.lab", "championship": {"gates": []}}, uid, ["pin.wood"])
	var errors: Array[String] = store.write("career", career)
	for suffix in [".bak", ".tmp"]:
		DirAccess.remove_absolute(store.path("career", suffix))
	print("errors=%s" % str(errors))
	print("ROGUEWOOD_FIXTURE_OK" if errors.is_empty() else "ROGUEWOOD_FIXTURE_FAILED")
	quit(0 if errors.is_empty() else 1)
