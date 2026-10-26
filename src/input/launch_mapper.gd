extends RefCounted
## Maps a committed flick to a contract launch record. E04 throws are straight:
## spin is always 0. Provisional gain/limits; E05 owns sensitivity and handedness.
const Lane = preload("res://src/simulation/lane_spec.gd")
const ANGLE_GAIN := 0.1 # lane degrees per screen degree
const MAX_LAUNCH_ANGLE_DEG := 4.0

static func launch_angle(screen_angle_deg: float) -> float:
	return clampf(screen_angle_deg * ANGLE_GAIN, -MAX_LAUNCH_ANGLE_DEG, MAX_LAUNCH_ANGLE_DEG)

static func to_launch(flick: Dictionary, start_x: float, launch_id: String, roll_index: int) -> Dictionary:
	var angle := deg_to_rad(launch_angle(flick.angle_deg))
	return {
		"schema_version": 1, "launch_id": launch_id, "ball_id": "ball.house", "roll_index": roll_index,
		"start_x": clampf(start_x, -Lane.MAX_START_X, Lane.MAX_START_X),
		"direction_x": sin(angle), "direction_forward": cos(angle), "power": flick.power, "spin": 0.0,
		"target_x": Lane.DEFAULT_TARGET_X, "ring_radius": Lane.DEFAULT_RING_RADIUS,
	}
