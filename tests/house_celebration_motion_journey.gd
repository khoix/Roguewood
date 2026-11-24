extends "res://tests/house_celebration_art_journey.gd"
## Eight timed story beats, including anticipation, under the default CRT setting.
## Source-frame motion, lifecycle, skip and independent real-roll checks inherited.
func reduced_flash() -> bool: return false
func story_frames() -> Array: return [0.0, 0.1, 0.2, 0.3, 0.45, 0.6, 0.75, 0.9]
