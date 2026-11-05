extends RefCounted
## E05-R1a: the held-ball model (src/input/held_ball.gd, ADR 011) from synthetic,
## timestamped finger samples. Covers the follow spring, charging by swinging,
## pace, reversal, fading while held, the straight-below-threshold rule, the
## fling release (mid-circle included), event timing at low frame rates, and the
## launch contract.
const Held = preload("res://src/input/held_ball.gd")
const Mapper = preload("res://src/input/launch_mapper.gd")
const Contracts = preload("res://src/contracts/contracts.gd")
const FRAME := 16667

class Driver:
	var held: RefCounted
	var at := Vector2(0.5, 0.85)
	var usec := 1000000
	var frame := 16667
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
	## Holds the finger still for `seconds`, ticking every frame.
	func hold(seconds: float) -> void:
		var end := usec + int(seconds * 1000000.0)
		while usec < end:
			usec += frame
			held.tick(usec)
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

## Steps of a circle of `radius` swept `sweep_deg` (positive = clockwise on screen),
## `deg_per_step` degrees per sample, starting at the circle's bottom.
static func circle(radius: float, sweep_deg: float, deg_per_step: float = 10.0) -> Array:
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

## Loops of brisk circling (radius 0.06, 10 degrees per frame) until full charge.
static func loops_to_full(clockwise: bool) -> float:
	var drive := Driver.new(Held.new())
	var sign := 1.0 if clockwise else -1.0
	for i in 72 * 4:
		drive.steps(circle(0.06, sign * 10.0) if i == 0 else [_arc_step(0.06, sign, i)])
		if absf(drive.held.charge()) >= 0.999:
			return (i + 1) / 36.0
	return 99.0

static func _arc_step(radius: float, sign: float, i: int) -> Vector2:
	var a0 := deg_to_rad(90.0 + sign * 10.0 * i)
	var a1 := deg_to_rad(90.0 + sign * 10.0 * (i + 1))
	return (Vector2(cos(a1), sin(a1)) - Vector2(cos(a0), sin(a0))) * radius

static func run() -> Array[String]:
	var failures: Array[String] = []
	# Straight drag: a fast forward flick commits straight, with no spin.
	var straight := Driver.new(Held.new())
	straight.steps(up(8))
	var s := straight.release()
	_expect(s.committed and s.spin == 0.0 and absf(s.angle_deg) < 1e-3, "a straight flick commits straight with no spin", failures)
	_expect(s.power > 0.3 and s.power <= 1.0, "flick speed maps to power (%.2f)" % s.power, failures)
	_expect(Contracts.validate("launch", Mapper.to_launch(s, 0.0, "held-1", 1)).is_empty(), "the result maps to a valid launch record", failures)
	var again := Driver.new(Held.new())
	again.steps(up(8))
	_expect(again.release() == s, "identical samples give identical results", failures)

	var near := Driver.new(Held.new())
	near.steps(up(8).map(func(v): return v + Vector2(0.0015, 0.0)))
	var n := near.release()
	_expect(n.committed and n.angle_deg == 0.0, "a flick within 2 degrees of straight up throws exactly straight", failures)

	# The ball follows the finger on a spring: it lags, then settles on the finger.
	var follow := Driver.new(Held.new())
	follow.steps(side(1, 0.08))
	follow.hold(FRAME / 1000000.0)
	var lagging: Vector2 = follow.held.placement()
	_expect(lagging.x > 0.5 and lagging.x < 0.58, "the ball lags behind a sudden finger move (x %.3f)" % lagging.x, failures)
	follow.hold(0.5)
	_expect(follow.held.placement().distance_to(follow.at) < 0.002, "then settles under the finger", failures)
	var overshoot := Driver.new(Held.new())
	overshoot.steps(side(6, 0.03))
	var peak := 0.0
	for i in 30:
		overshoot.hold(FRAME / 1000000.0)
		peak = maxf(peak, overshoot.held.placement().x)
	_expect(peak > overshoot.at.x, "a moving ball overshoots when the finger stops (%.3f past %.3f)" % [peak, overshoot.at.x], failures)

	# Swinging charges spin; brisk circles reach full in about 1.5 loops, both ways.
	var cw := loops_to_full(true)
	var ccw := loops_to_full(false)
	_expect(cw >= 1.0 and cw <= 2.0 and absf(cw - ccw) < 1e-6, "brisk circles reach full spin in 1-2 loops, symmetric (%.2f, %.2f)" % [cw, ccw], failures)
	var brisk := Driver.new(Held.new())
	brisk.steps(circle(0.06, 360.0))
	var lazy := Driver.new(Held.new())
	lazy.steps(circle(0.06, 360.0, 3.0))
	_expect(brisk.held.charge() > 0.5 and lazy.held.charge() < brisk.held.charge() * 0.6,
		"lazy circles charge more slowly than brisk ones (%.2f vs %.2f after one loop)" % [lazy.held.charge(), brisk.held.charge()], failures)
	var counter := Driver.new(Held.new())
	counter.steps(circle(0.06, -360.0))
	_expect(absf(counter.held.charge() + brisk.held.charge()) < 1e-6, "counter-clockwise charges the mirror spin", failures)
	_expect(brisk.held.curve_ready() and not Driver.new(Held.new()).held.curve_ready(), "the curve-ready (sparkle) state follows the threshold", failures)

	# Reversing bleeds spin off first, then builds the other way.
	var reverse := Driver.new(Held.new())
	reverse.steps(circle(0.06, 540.0))
	var before := float(reverse.held.charge())
	reverse.steps(circle(0.06, -180.0))
	var bled := float(reverse.held.charge())
	reverse.steps(circle(0.06, -900.0))
	_expect(before > 0.9 and bled < before and bled > 0.0 and reverse.held.charge() < -0.5,
		"reversing bleeds spin (%.2f -> %.2f) before building the other way (%.2f)" % [before, bled, reverse.held.charge()], failures)

	# Held spin persists and fades slowly; the throw keeps it.
	var keep := Driver.new(Held.new())
	keep.steps(circle(0.06, 720.0))
	var charged := float(keep.held.charge())
	keep.hold(2.5)
	_expect(absf(keep.held.charge() - charged * 0.5) < 0.02, "held spin halves in 2.5 s (%.2f -> %.2f)" % [charged, keep.held.charge()], failures)
	keep.steps(up(8))
	var kept := keep.release()
	_expect(kept.committed and kept.spin > 0.25 and absf(kept.angle_deg) < 5.0, "a pause then a straight flick throws the held spin (%.2f)" % kept.spin, failures)

	# Below the curve threshold a throw is exactly straight.
	var weak := Driver.new(Held.new())
	weak.steps(circle(0.06, 90.0))
	weak.hold(0.3)
	weak.steps(up(8))
	var w := weak.release()
	_expect(w.committed and w.spin == 0.0 and w.charge > 0.0 and w.charge < 0.25, "spin below the threshold throws straight (charge %.2f)" % w.charge, failures)
	var corner := Driver.new(Held.new())
	corner.steps(side(5, 0.03))
	corner.steps(up(8))
	var c := corner.release()
	_expect(c.committed and c.spin == 0.0, "sideways placement then a flick is straight", failures)
	var zigzag := Driver.new(Held.new())
	zigzag.steps(side(4, 0.03) + side(4, -0.03) + side(4, 0.03))
	_expect(absf(zigzag.held.charge()) < 1e-6, "sideways reversals charge nothing", failures)

	# The release is the held ball's motion: letting go mid-circle flings along it.
	var fling := Driver.new(Held.new())
	fling.steps(circle(0.1, 720.0 + 135.0, 15.0))
	var f := fling.release()
	_expect(f.has("angle_deg") and absf(f.angle_deg) > 20.0, "a mid-circle release flings along the circle (angle %.1f, %s)" % [f.get("angle_deg", 0.0), f.reason], failures)
	_expect(f.spin > 0.25, "and keeps its spin", failures)
	var lifted := Driver.new(Held.new())
	lifted.steps(up(6))
	lifted.hold(0.25)
	_expect(lifted.release().reason in ["short", "slow"], "stopping before letting go cancels safely", failures)
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

	# Event timing: the same gesture sampled at 15 fps reads like it does at 60 fps.
	var fast := Driver.new(Held.new(), FRAME)
	fast.steps(circle(0.06, 720.0, 10.0))
	fast.steps(up(12, 0.04))
	var slow := Driver.new(Held.new(), FRAME * 4)
	slow.steps(circle(0.06, 720.0, 40.0))
	slow.steps(up(3, 0.16))
	var a := fast.release()
	var b := slow.release()
	_expect(a.committed and b.committed and absf(a.spin - b.spin) < 0.25 and absf(a.power - b.power) < 0.25,
		"15 fps and 60 fps sampling give similar throws (spin %.2f/%.2f, power %.2f/%.2f)" % [a.spin, b.spin, a.power, b.power], failures)

	# E26-W01's finding: at 15 fps the finger's lift arrives a frame after its last
	# move. The ball is still travelling on the spring, so the flick still counts.
	var late := Driver.new(Held.new(), FRAME * 4)
	late.steps(up(3, 0.16))
	late.hold(FRAME * 4 / 1000000.0)
	var l := late.release()
	_expect(l.committed, "a lift one 15 fps frame after the last move still throws (%s)" % l.reason, failures)

	# Sensitivity scales the measured flick speed only.
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
