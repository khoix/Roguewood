extends RefCounted
## Boss rules a rival imposes (E09, ADR 006; Dead Straight E13, ADR 008). A closed
## vocabulary keyed by catalogue boss_rule id; unknown rules are refused, never
## ignored. Banking rules leave the frame's FrameRules result untouched (its
## calculation stays readable): they only change what the match banks, and say so
## as one extra log line. Launch rules constrain the committed launch before it is
## saved or simulated, and the aim UI shows the constraint.
## E18-C05 adds House Rules (only the House Ball may be thrown; tactical cards stay
## allowed) and House Pins (every racked pin scores as plain Wood: FrameRules sees
## a Wood rack, pin modifications kept), and lets a League champion carry several
## rules at once (DivisionRun.rules()). Lane conditions are not rules: LaneSpec reads
## the match's catalogue lane_condition id.
## E17-L02 adds the Neon rules, which change the roll itself (lane_rules, read by
## LaneWorld): Oil Slick halves the hook a charge produces (the committed spin, and
## so "curved", is unchanged), Narrow Lane moves each gutter edge two boards in (a
## ball crossing it before touching a pin is a gutter ball, and the start is kept
## inside it), and Strobe halves the ring's perfect and sweet bands.
## E18-C20 adds the Salvage rules. Frugal House pays no item income in the match
## (paid(): the payouts are taken out of what the run credits, and the log shows the
## amount the house kept; match pay and interest are not item income). Dull Pins
## halves every Value a pin adds (frame_context(): FrameRules' pin_value_scale).
## Rust switches every modification off: frame_loadout() drops the rack's pin
## modifications, and mods_off() tells the lab to play no ball modification, in the
## scoring or in the roll (Bumper Guard's rebound, a hook scale). The hosts work as
## normal, and nothing is removed from the run.
const Lane = preload("res://src/simulation/lane_spec.gd")
const CLEAN_SWEEP := "boss_rule.lab_clean_sweep"
## Rule id -> mechanic. The lab fixture and the production rule share Clean Sweep.
const KINDS := {"boss_rule.lab_clean_sweep": "clean_sweep", "boss_rule.clean_sweep": "clean_sweep", "boss_rule.dead_straight": "dead_straight",
	"boss_rule.house_rules": "house_only", "boss_rule.house_pins": "plain_rack",
	"boss_rule.oil_slick": "hook_scale", "boss_rule.narrow_lane": "lane_width", "boss_rule.strobe": "ring_scale",
	"boss_rule.frugal_house": "no_item_income", "boss_rule.dull_pins": "pin_value_scale", "boss_rule.rust": "no_mods"}
const KNOWN := ["boss_rule.lab_clean_sweep", "boss_rule.clean_sweep", "boss_rule.dead_straight", "boss_rule.house_rules", "boss_rule.house_pins",
	"boss_rule.oil_slick", "boss_rule.narrow_lane", "boss_rule.strobe", "boss_rule.frugal_house", "boss_rule.dull_pins", "boss_rule.rust"]
const PIN_VALUE_SCALE := 0.5
const HOOK_SCALE := 0.5
const NARROW_BOARDS := 2
const ZONE_SCALE := 0.5
const HOUSE_BALL := "ball.house"
const WOOD := "pin.wood"

static func unknown(rule_ids: Array) -> Array[String]:
	var errors: Array[String] = []
	for rule_id in rule_ids:
		if rule_id not in KNOWN:
			errors.append("unknown boss rule: " + str(rule_id))
	return errors

static func kind(rule_id: String) -> String:
	return KINDS.get(rule_id, "")

## True when a rule in force disables charged spin.
static func spin_disabled(rule_ids: Array) -> bool:
	return rule_ids.any(func(r): return kind(r) == "dead_straight")

## False when House Rules is in force and the ball is not the House Ball.
static func ball_allowed(rule_ids: Array, ball_id: String) -> bool:
	return ball_id == HOUSE_BALL or not rule_ids.any(func(r): return kind(r) == "house_only")

## What the rules in force change in the roll itself (LaneWorld.rules). Empty when
## none does, so the standard lane stays exactly as it was.
static func lane_rules(rule_ids: Array) -> Dictionary:
	var out := {}
	for rule_id in rule_ids:
		match kind(rule_id):
			"hook_scale": out["hook_scale"] = HOOK_SCALE
			"lane_width": out["gutter_edge"] = Lane.LANE_HALF_WIDTH - NARROW_BOARDS * Lane.BOARD_WIDTH
			"ring_scale": out["zone_scale"] = ZONE_SCALE
	return out

## The launch a rule permits: Dead Straight commits every throw with zero spin;
## House Rules commits it with the House Ball; Narrow Lane keeps the start inside
## its edges.
static func constrain_launch(rule_ids: Array, launch: Dictionary) -> Dictionary:
	var out := launch.duplicate(true)
	if spin_disabled(rule_ids):
		out.spin = 0.0
	if out.has("ball_id") and not ball_allowed(rule_ids, str(out.ball_id)):
		out.ball_id = HOUSE_BALL
	var edge := float(lane_rules(rule_ids).get("gutter_edge", Lane.LANE_HALF_WIDTH))
	if out.has("start_x") and edge < Lane.LANE_HALF_WIDTH:
		var reach := Lane.max_start_x(edge)
		out.start_x = clampf(float(out.start_x), -reach, reach)
	return out

static func _has(rule_ids: Array, mechanic: String) -> bool:
	return rule_ids.any(func(r): return kind(r) == mechanic)

## True when Rust is in force: no ball or pin modification plays.
static func mods_off(rule_ids: Array) -> bool:
	return _has(rule_ids, "no_mods")

## The loadout FrameBuilder scores: House Pins racks plain Wood in every position
## (the pins' own effects and growth are off; pin modifications stay attached);
## Rust takes the pin modifications off the scored rack.
static func frame_loadout(rule_ids: Array, loadout: Dictionary) -> Dictionary:
	if not _has(rule_ids, "plain_rack") and not mods_off(rule_ids):
		return loadout
	var out := loadout.duplicate(true)
	if _has(rule_ids, "plain_rack"):
		for position in out.pins:
			out.pins[position] = WOOD
		out["pin_growth"] = {}
	if mods_off(rule_ids):
		out["pin_mods"] = {}
	return out

## The frame context with what the rules change in the calculation: Dull Pins'
## pin_value_scale. Unchanged when no rule does.
static func frame_context(rule_ids: Array, context: Dictionary) -> Dictionary:
	if not _has(rule_ids, "pin_value_scale"):
		return context
	var out := context.duplicate(true)
	out["pin_value_scale"] = PIN_VALUE_SCALE
	return out

## What the run is paid for a resolved frame: Frugal House takes every payout out of
## the result's future effects ({result, kept}: kept is the amount the house kept).
## The result itself is unchanged, so its calculation stays readable.
static func paid(rule_ids: Array, result: Dictionary) -> Dictionary:
	if not _has(rule_ids, "no_item_income"):
		return {"result": result, "kept": 0}
	var out := result.duplicate(true)
	var kept := 0
	for event in result.get("future_effects", []):
		if event.op == "payout":
			kept += int(event.amount)
	out.future_effects = result.get("future_effects", []).filter(func(e): return e.op != "payout")
	return {"result": out, "kept": kept}

## What the match banks for a resolved frame: {score, notes}. Item income is money,
## not points, so payouts are unaffected.
static func bank(rule_ids: Array, result: Dictionary) -> Dictionary:
	var score := int(result.score)
	var notes: Array = []
	for rule_id in rule_ids:
		match kind(rule_id):
			"clean_sweep":
				if result.category == "open":
					notes.append("Clean Sweep: An open frame banks nothing (%d → 0)" % score)
					score = 0
			"plain_rack":
				notes.append("House Pins: Every pin was scored as plain Wood")
			"pin_value_scale":
				notes.append("Dull Pins: Every pin's Value was halved")
			"no_mods":
				notes.append("Rust: Every modification was switched off")
			"no_item_income":
				var kept := int(paid(rule_ids, result).kept)
				if kept > 0:
					notes.append("Frugal House: Item payouts paid nothing ($%d kept by the house)" % kept)
	return {"score": score, "notes": notes}

static func summary(rule_id: String) -> String:
	match kind(rule_id):
		"clean_sweep":
			return "Clean Sweep — only strikes and spares bank points; open frames bank 0."
		"dead_straight":
			return "Dead Straight — charged spin is disabled; every throw rolls straight."
		"house_only":
			return "House Rules — only the House Ball may be thrown; tactical cards are allowed."
		"plain_rack":
			return "House Pins — every pin scores as plain Wood; materials are off, modifications stay."
		"hook_scale":
			return "Oil Slick — every hook is halved: The same charge curves half as far."
		"lane_width":
			return "Narrow Lane — each gutter edge is two boards in; crossing it is a gutter ball."
		"ring_scale":
			return "Strobe — the ring's sweet and perfect zones are half their size."
		"no_item_income":
			return "Frugal House — items pay no money this match; match pay and interest still come."
		"pin_value_scale":
			return "Dull Pins — every pin's Value is halved (rounded down); Charms and Mult are untouched."
		"no_mods":
			return "Rust — every ball and pin modification is switched off this match."
	return rule_id

## All rules of a rival (a League champion can carry more than one), as one line.
static func summaries(rule_ids: Array) -> String:
	return " ".join(rule_ids.map(func(r): return summary(r)))
