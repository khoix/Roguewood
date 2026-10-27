extends RefCounted
## Boss rules a rival imposes (E09, ADR 006; Dead Straight E13, ADR 008). A closed
## vocabulary keyed by catalogue boss_rule id; unknown rules are refused, never
## ignored. Banking rules leave the frame's FrameRules result untouched (its
## calculation stays readable): they only change what the match banks, and say so
## as one extra log line. Launch rules constrain the committed launch before it is
## saved or simulated, and the aim UI shows the constraint.
const CLEAN_SWEEP := "boss_rule.lab_clean_sweep"
## Rule id -> mechanic. The lab fixture and the production rule share Clean Sweep.
const KINDS := {"boss_rule.lab_clean_sweep": "clean_sweep", "boss_rule.clean_sweep": "clean_sweep", "boss_rule.dead_straight": "dead_straight"}
const KNOWN := ["boss_rule.lab_clean_sweep", "boss_rule.clean_sweep", "boss_rule.dead_straight"]

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

## The launch a rule permits: Dead Straight commits every throw with zero spin.
static func constrain_launch(rule_ids: Array, launch: Dictionary) -> Dictionary:
	var out := launch.duplicate(true)
	if spin_disabled(rule_ids):
		out.spin = 0.0
	return out

## What the match banks for a resolved frame: {score, notes}. Item income is money,
## not points, so payouts are unaffected.
static func bank(rule_ids: Array, result: Dictionary) -> Dictionary:
	var score := int(result.score)
	var notes: Array = []
	for rule_id in rule_ids:
		match kind(rule_id):
			"clean_sweep":
				if result.category == "open":
					notes.append("Clean Sweep: an open frame banks nothing (%d → 0)" % score)
					score = 0
	return {"score": score, "notes": notes}

static func summary(rule_id: String) -> String:
	match kind(rule_id):
		"clean_sweep":
			return "Clean Sweep — only strikes and spares bank points; open frames bank 0."
		"dead_straight":
			return "Dead Straight — charged spin is disabled; every throw rolls straight."
	return rule_id
