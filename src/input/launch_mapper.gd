extends RefCounted
## Builds contract launch records. Gestures and the accessible controls share one
## record shape, so identical choices produce identical launches. Provisional
## gain/limits (ADR 003).
const Lane = preload("res://src/simulation/lane_spec.gd")
const ANGLE_GAIN := 0.1 # lane degrees per screen degree
const MAX_LAUNCH_ANGLE_DEG := 4.0

static func launch_angle(screen_angle_deg: float) -> float:
	return clampf(screen_angle_deg * ANGLE_GAIN, -MAX_LAUNCH_ANGLE_DEG, MAX_LAUNCH_ANGLE_DEG)

static func to_launch(flick: Dictionary, start_x: float, launch_id: String, roll_index: int,
		target_x: float = Lane.DEFAULT_TARGET_X, ring_radius: float = Lane.DEFAULT_RING_RADIUS, ball_id: String = "ball.house") -> Dictionary:
	return from_controls({"start_x": start_x, "angle_deg": launch_angle(flick.angle_deg), "power": flick.power,
		"spin": flick.get("spin", 0.0)}, launch_id, roll_index, target_x, ring_radius, ball_id)

## controls: start_x (normalized), angle_deg (lane degrees), power, spin.
static func from_controls(controls: Dictionary, launch_id: String, roll_index: int,
		target_x: float = Lane.DEFAULT_TARGET_X, ring_radius: float = Lane.DEFAULT_RING_RADIUS, ball_id: String = "ball.house") -> Dictionary:
	var angle := deg_to_rad(clampf(controls.angle_deg, -MAX_LAUNCH_ANGLE_DEG, MAX_LAUNCH_ANGLE_DEG))
	return {
		"schema_version": 1, "launch_id": launch_id, "ball_id": ball_id, "roll_index": roll_index,
		"start_x": clampf(controls.start_x, -Lane.MAX_START_X, Lane.MAX_START_X),
		"direction_x": sin(angle), "direction_forward": cos(angle), "power": clampf(controls.power, 0.0, 1.0),
		"spin": clampf(controls.spin, -1.0, 1.0), "target_x": target_x, "ring_radius": ring_radius,
	}
