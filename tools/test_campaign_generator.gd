extends SceneTree
func _initialize() -> void:
	var failures = preload("res://tests/campaign_generator_test.gd").run()
	for failure in failures: printerr("FAIL: " + failure)
	if failures.is_empty(): print("ROGUEWOOD_CAMPAIGN_GENERATOR_OK (200 schedules)")
	quit(0 if failures.is_empty() else 1)
