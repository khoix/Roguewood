extends RefCounted
## Boss rules a rival imposes on banking (E09, ADR 006). A closed vocabulary keyed
## by catalogue boss_rule id; unknown rules are refused, never ignored. The frame's
## FrameRules result is left untouched (its calculation stays readable): a rule only
## changes what the match banks, and says so as one extra log line.
const CLEAN_SWEEP := "boss_rule.lab_clean_sweep"
const KNOWN := [CLEAN_SWEEP]

static func unknown(rule_ids: Array) -> Array[String]:
	var errors: Array[String] = []
	for rule_id in rule_ids:
		if rule_id not in KNOWN:
			errors.append("unknown boss rule: " + str(rule_id))
	return errors

## What the match banks for a resolved frame: {score, notes}. Item income is money,
## not points, so payouts are unaffected.
static func bank(rule_ids: Array, result: Dictionary) -> Dictionary:
	var score := int(result.score)
	var notes: Array = []
	for rule_id in rule_ids:
		match rule_id:
			CLEAN_SWEEP:
				if result.category == "open":
					notes.append("Clean Sweep: an open frame banks nothing (%d → 0)" % score)
					score = 0
	return {"score": score, "notes": notes}

static func summary(rule_id: String) -> String:
	match rule_id:
		CLEAN_SWEEP:
			return "Clean Sweep — only strikes and spares bank points; open frames bank 0."
	return rule_id
