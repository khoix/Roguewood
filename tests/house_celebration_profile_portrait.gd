extends "res://tests/house_celebration_art_journey.gd"
## Bounded full-render benchmark. All scene/lifecycle/real-roll assertions remain.
## Omit PNG readbacks; the parent still compares the source frames for correctness.
func orientations() -> Array: return ["portrait"]
func _capture(_label: String) -> void: pass
