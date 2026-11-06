extends RefCounted
## E05-R2: the tethered swing (src/input/held_ball.gd, ADR 011) from synthetic,
## timestamped finger samples: the finger stays inside the ball, orbit speed (not
## loop count) sets the charge, a single corner never curves, the orbit coasts and
## winds down, reversing slows it first, the flick sets the throw with a small orbit
## nudge, low frame rates read the same, and the safe cancels.
const Held = preload("res://src/input/held_ball.gd")
const Mapper = preload("res://src/input/launch_mapper.gd")
const Contracts = preload("res://src/contracts/contracts.gd")
const FRAME := 16667

class Driver:
	var held: RefCounted
	var at := Vector2(0.5, 0.85)
	var usec := 1000000
	var frame := 16667
	var max_offset := 0.0 # largest ball-to-finger distance seen
	func _init(model: RefCounted, frame_usec: int = 16667) -> void:
		held = model
		frame = frame_usec
		held.begin(at, usec)
	## Moves the finger by each step, one event per frame.
	func steps(list: Array) -> void:
		for step in list:
			at += step
			usec += frame
			held.move(at, usec)
			max_offset = maxf(max_offset, held.ball.distance_to(held.finger))
	## Holds the finger still for `seconds`, ticking every frame.
	func hold(seconds: float) -> void:
		var end := usec + int(seconds * 1000000.0)
		while usec < end:
			usec += frame
			held.tick(usec)
			max_offset = maxf(max_offset, held.ball.distance_to(held.finger))
	func release() -> Dictionary:
		return held.release(at, usec)

static func up(count: int, step: float = 0.05) -> Array:
	var out: Array = []
	for i in count: out.append(Vector2(0.0, -step))
	return out

static func side(count: int, step: float) -> Array:
	var out: Array = []
	for i in count: out.append(Vector2(step, 0.0))
	return out

## Steps of a small finger circle of `radius` swept `sweep_deg` (positive =
## clockwise on screen), `deg_per_step` degrees per sample.
static func circle(radius: float, sweep_deg: float, deg_per_step: float) -> Array:
	var out: Array = []
	var center := Vector2(0.0, -radius)
	var previous := Vector2.ZERO
	var count := int(absf(sweep_deg) / deg_per_step)
	for i in count:
		var angle := deg_to_rad(90.0 + signf(sweep_deg) * deg_per_step * (i + 1))
		var next := center + Vector2(cos(angle), sin(angle)) * radius
		out.append(next - previous)
		previous = next
	return out

## Charge after swirling `turns_per_second` for `seconds` (finger circle radius 0.02).
static func swirl_charge(turns_per_second: float, seconds: float, frame_usec: int = FRAME) -> float:
	var drive := Driver.new(Held.new(), frame_usec)
	var per_step := absf(360.0 * turns_per_second * frame_usec / 1000000.0)
	drive.steps(circle(0.02, 360.0 * turns_per_second * seconds, per_step))
	return drive.held.charge()

static func run() -> Array[String]:
	var failures: Array[String] = []
	var cap := float(Held.DEFAULTS.orbit_cap)
	# A straight flick: committed, straight, no spin.
	var straight := Driver.new(Held.new())
	straight.steps(up(8))
	var s := straight.release()
	_expect(s.committed and s.spin == 0.0 and s.angle_deg == 0.0 and s.power > 0.3, "a straight flick commits straight with no spin (power %.2f)" % s.get("power", 0.0), failures)
	_expect(Contracts.validate("launch", Mapper.to_launch(s, 0.0, "held-1", 1)).is_empty(), "the result maps to a valid launch record", failures)
	var again := Driver.new(Held.new())
	again.steps(up(8))
	_expect(again.release() == s, "identical samples give identical results", failures)

	# Orbit speed, not loop count, sets the charge.
	var brisk := swirl_charge(2.0, 0.75)
	var medium := swirl_charge(1.0, 1.5)
	var lazy := swirl_charge(0.5, 3.0)
	_expect(brisk >= 0.9, "a brisk swirl (2 turns a second) reaches full charge (%.2f)" % brisk, failures)
	_expect(absf(medium - 0.5) < 0.12 and absf(lazy - 0.25) < 0.08, "half the speed gives about half the charge (1 t/s %.2f, 0.5 t/s %.2f)" % [medium, lazy], failures)
	_expect(lazy < brisk * 0.5, "one and a half lazy loops charge less than one and a half brisk ones", failures)
	_expect(absf(swirl_charge(-2.0, 0.75) + brisk) < 0.01, "counter-clockwise charges the mirror spin", failures)

	# The finger stays inside the ball: the orbit never exceeds its cap.
	var tether := Driver.new(Held.new())
	tether.steps(circle(0.03, 1080.0, 12.0))
	tether.hold(0.5)
	tether.steps(up(8))
	_expect(tether.max_offset <= cap + 1e-4 and tether.max_offset > cap * 0.6, "the ball orbits within its cap of the finger (largest %.3f, cap %.3f)" % [tether.max_offset, cap], failures)

	# A single corner, a part arc or sideways jiggling never starts a swirl.
	var corner := Driver.new(Held.new())
	corner.steps(side(5, 0.03))
	corner.steps(up(8))
	_expect(not corner.held.swirling and corner.release().spin == 0.0, "sideways placement then a flick is straight", failures)
	var arc := Driver.new(Held.new())
	arc.steps(circle(0.02, 150.0, 12.0))
	_expect(not arc.held.swirling and arc.held.charge() == 0.0, "a part arc (150 degrees) charges nothing", failures)
	var zigzag := Driver.new(Held.new())
	zigzag.steps(side(4, 0.03) + side(4, -0.03) + side(4, 0.03))
	_expect(not zigzag.held.swirling, "sideways reversals charge nothing", failures)

	# Momentum: with the finger still, the ball keeps orbiting and winds down.
	var coast := Driver.new(Held.new())
	coast.steps(circle(0.02, 540.0, 12.0))
	var before := float(coast.held.charge())
	var angle := float(coast.held.orbit_angle)
	coast.hold(1.2)
	_expect(absf(coast.held.charge() - before * 0.5) < 0.06 and absf(coast.held.orbit_angle - angle) > TAU, "a still finger: the ball keeps orbiting and the charge halves in 1.2 s (%.2f -> %.2f)" % [before, coast.held.charge()], failures)
	_expect(coast.held.curve_ready() and not Driver.new(Held.new()).held.curve_ready(), "the sparkle state follows the threshold", failures)
	coast.hold(6.0)
	_expect(not coast.held.swirling and coast.held.charge() == 0.0, "a long pause lets the orbit stop", failures)

	# Reversing slows the orbit first, then builds the other way.
	var reverse := Driver.new(Held.new())
	reverse.steps(circle(0.02, 540.0, 12.0))
	var forward := float(reverse.held.charge())
	reverse.steps(circle(0.02, -120.0, 12.0))
	var slowed := float(reverse.held.charge())
	reverse.steps(circle(0.02, -900.0, 12.0))
	_expect(forward > 0.9 and slowed < forward and reverse.held.charge() < -0.8, "reversing slows the orbit (%.2f -> %.2f) before it builds the other way (%.2f)" % [forward, slowed, reverse.held.charge()], failures)

	# The release: the flick sets the throw; the orbit adds only a nudge; the charge holds.
	var throw := Driver.new(Held.new())
	throw.steps(circle(0.02, 720.0, 12.0))
	var held_charge := float(throw.held.charge())
	throw.steps(up(8))
	var t := throw.release()
	_expect(t.committed and t.spin > 0.85 and absf(t.spin - held_charge) < 0.15, "a swirl then a flick throws the held charge (%.2f of %.2f)" % [t.spin, held_charge], failures)
	_expect(absf(t.angle_deg) < 20.0, "the orbit nudges the throw only a little (%.1f degrees)" % t.angle_deg, failures)
	var no_nudge_model := Held.new()
	no_nudge_model.tuning.orbit_nudge = 0.0
	var plain := Driver.new(no_nudge_model)
	plain.steps(circle(0.02, 720.0, 12.0))
	plain.steps(up(8))
	_expect(plain.release().angle_deg == 0.0, "with no nudge the flick alone sets the direction", failures)
	var weak := Driver.new(Held.new())
	weak.steps(circle(0.02, 360.0, 2.4)) # 0.4 turns a second
	var w_charge := float(weak.held.charge())
	weak.steps(up(8))
	var w := weak.release()
	_expect(w_charge > 0.0 and w_charge < 0.25 and w.committed and w.spin == 0.0, "a slow swirl below the threshold throws straight (charge %.2f)" % w_charge, failures)

	var turned := Driver.new(Held.new())
	turned.steps(circle(0.02, 360.0, 2.4))
	turned.steps([Vector2(0.03, -0.02), Vector2(0.01, -0.05)] + up(6))
	_expect(turned.release().spin == 0.0, "turning sharply into a fast flick never pumps a weak swirl into a curve", failures)

	# Event timing: 15 fps reads like 60 fps; a late lift still throws.
	var fps15 := swirl_charge(2.0, 0.8, FRAME * 4)
	_expect(absf(fps15 - brisk) < 0.15, "a brisk swirl sampled at 15 fps charges like 60 fps (%.2f vs %.2f)" % [fps15, brisk], failures)
	var late := Driver.new(Held.new(), FRAME * 4)
	late.steps(up(3, 0.16))
	late.hold(FRAME * 4 / 1000000.0)
	_expect(late.release().committed, "a lift one 15 fps frame after the last move still throws", failures)

	# Safe cancels and limits.
	var stopped := Driver.new(Held.new())
	stopped.steps(up(6))
	stopped.hold(0.25)
	_expect(stopped.release().reason in ["short", "slow"], "stopping before letting go cancels safely", failures)
	_expect(Driver.new(Held.new()).release().reason == "no_motion", "a tap without motion cancels", failures)
	var down := Driver.new(Held.new())
	down.steps(up(6, -0.05))
	_expect(down.release().reason == "short", "a downward drag cancels", failures)
	var sideways := Driver.new(Held.new())
	sideways.steps(side(8, 0.06))
	_expect(sideways.release().reason in ["short", "not_forward"], "a sideways swipe cancels", failures)
	var violent := Driver.new(Held.new())
	violent.steps(up(6, 0.2))
	_expect(violent.release().power == 1.0, "a violent flick is capped at full power", failures)
	var gentle := Driver.new(Held.new())
	gentle.steps(up(20, 0.012))
	var boosted_model := Held.new()
	boosted_model.tuning.sensitivity = 2.0
	var boosted := Driver.new(boosted_model)
	boosted.steps(up(20, 0.012))
	_expect(gentle.release().reason == "slow" and boosted.release().committed, "sensitivity scales flick speed", failures)
	var cancelled := Driver.new(Held.new())
	cancelled.held.cancel()
	_expect(cancelled.held.release(Vector2(0.5, 0.2), 2000000).reason == "inactive", "a cancelled hold cannot throw", failures)
	return failures

static func _expect(condition: bool, label: String, failures: Array[String]) -> void:
	if not condition: failures.append(label)
