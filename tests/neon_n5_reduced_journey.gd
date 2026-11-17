extends "res://tests/neon_n5_art_journey.gd"
func _process(delta: float) -> bool:
 if is_instance_valid(lab): lab.settings.reduced_motion = true
 return super._process(delta)
