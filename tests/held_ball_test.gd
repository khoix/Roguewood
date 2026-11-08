extends RefCounted
## E05-R4: the ragdoll ball (src/input/held_ball.gd, ADR 011) from synthetic,
## timestamped finger samples. The ball hangs from the touch point under gravity,
## lags and swings past a moving finger, stays round the finger inside its own
## radius, sways under slow circles and is whipped round by brisk ones (its turning
## is the charge), spins on briefly when the finger stops, reverses when circled
## the other way; the flick sets the throw; low frame rates read the same; the safe
## cancels hold.
const Held = preload("res://src/input/held_ball.gd")
const Mapper = preload("res://src/input/launch_mapper.gd")
const Contracts = preload("res://src/contracts/contracts.gd")
const FRAME := 16667
const RADIUS := 0.05 # a typical finger circle, in shorter sides

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
			max_offset = maxf(max_offset, held.ball.distance_to(held.pivot))
	## Holds the finger still for `seconds`, ticking every frame.
	func hold(seconds: float) -> void:
		var end := usec + int(seconds * 1000000.0)
		while usec < end:
			usec += frame
			held.tick(usec)
			max_offset = maxf(max_offset, held.ball.distance_to(held.pivot))
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

## Steps of a finger circle of `radius` at `turns_per_second` (positive = clockwise
## on screen) for `seconds`, sampled every `frame_usec`, starting at the circle's bottom.
static func circle(radius: float, turns_per_second: float, seconds: float, frame_usec: int = FRAME) -> Array:
	var out: Array = []
	var center := Vector2(0.0, -radius)
	var previous := Vector2.ZERO
	var count := int(seconds * 1000000.0 / frame_usec)
	for i in count:
		var angle := PI * 0.5 + TAU * turns_per_second * (i + 1) * frame_usec / 1000000.0
		var next := center + Vector2(cos(angle), sin(angle)) * radius
		out.append(next - previous)
		previous = next
	return out

## Charge after circling at `turns_per_second` for `seconds`.
static func swirl_charge(turns_per_second: float, seconds: float = 1.5, frame_usec: int = FRAME) -> float:
	var drive := Driver.new(Held.new(), frame_usec)
	drive.steps(circle(RADIUS, turns_per_second, seconds, frame_usec))
	return drive.held.charge()

static func run() -> Array[String]:
	var failures: Array[String] = []
	var cap := float(Held.DEFAULTS.orbit_cap)
	var reach := cap * float(Held.DEFAULTS.tether_stretch)
	# A straight flick: committed, straight, no spin.
	var straight := Driver.new(Held.new())
	straight.steps(up(8))
	var s := straight.release()
	_expect(s.committed and s.spin == 0.0 and s.angle_deg == 0.0 and s.power > 0.3, "a straight flick commits straight with no spin (power %.2f)" % s.get("power", 0.0), failures)
	_expect(Contracts.validate("launch", Mapper.to_launch(s, 0.0, "held-1", 1)).is_empty(), "the result maps to a valid launch record", failures)
	var again := Driver.new(Held.new())
	again.steps(up(8))
	_expect(again.release() == s, "identical samples give identical results", failures)

	# Gravity: picked up, the ball drops onto its pin and hangs below the finger.
	var hang := Driver.new(Held.new())
	hang.hold(0.6)
	var below: Vector2 = hang.held.ball - hang.held.pivot
	_expect(below.y > 0.6 * cap and absf(below.x) < 0.1 * cap, "the ball hangs below the touch point under gravity (%.3f, %.3f)" % [below.x, below.y], failures)

	# Ragdoll: dragged, the ball trails the finger; stopped, it swings past.
	var drag := Driver.new(Held.new())
	drag.hold(0.4)
	var lag := 0.0
	for i in 15:
		drag.steps([Vector2(0.01, 0.0)])
		lag = maxf(lag, drag.held.finger.x - drag.held.ball.x)
	var past := 0.0
	for i in 30:
		drag.hold(1.0 / 60.0)
		past = maxf(past, drag.held.ball.x - drag.held.finger.x)
	_expect(lag > 0.3 * cap and past > 0.2 * cap, "a dragged ball trails the finger (%.3f) and swings past when it stops (%.3f)" % [lag, past], failures)

	# Whipped round: brisk circles spin the ball; its turning is the charge. With the
	# owner's phone tuning (50 rad/s, the longer pin, quick smoothing; 2026-11-08) a
	# small circle reaches full charge at about 4.5 turns a second.
	var brisk := swirl_charge(4.5)
	var lazy := swirl_charge(0.5)
	var c125 := swirl_charge(1.25)
	var c175 := swirl_charge(1.75)
	var c300 := swirl_charge(3.0)
	_expect(brisk >= 0.9, "a brisk circle (4.5 turns a second) reaches full charge (%.2f)" % brisk, failures)
	_expect(lazy == 0.0, "a slow circle (0.5 a second) only sways the ball and never charges (%.2f)" % lazy, failures)
	_expect(c125 <= c175 and c175 < c300 and c300 < brisk and c300 > 0.4 and c300 < 0.85,
		"faster circles charge more (1.25 t/s %.2f, 1.75 %.2f, 3 %.2f, 4.5 %.2f)" % [c125, c175, c300, brisk], failures)
	_expect(absf(swirl_charge(-4.5) + brisk) < 0.05, "counter-clockwise charges the mirror spin", failures)
	# Swirling slower lowers the bar (owner, 2026-11-06), without letting go.
	var slower := Driver.new(Held.new())
	slower.steps(circle(RADIUS, 4.5, 1.2))
	var fast_charge := float(slower.held.charge())
	slower.steps(circle(RADIUS, 1.5, 1.5))
	_expect(fast_charge > 0.9 and slower.held.charge() < 0.75, "slowing the circle lowers the charge (%.2f -> %.2f)" % [fast_charge, slower.held.charge()], failures)

	# The finger stays inside the ball, however hard it is whipped.
	var tether := Driver.new(Held.new())
	tether.steps(circle(0.08, 5.0, 1.5))
	tether.hold(0.5)
	tether.steps(up(8))
	_expect(tether.max_offset <= reach + 1e-4 and tether.max_offset > cap, "the pin stretches at speed but the finger stays inside the ball (largest %.3f, reach %.3f)" % [tether.max_offset, reach], failures)

	# A single corner, a part arc or sideways jiggling never curves.
	var corner := Driver.new(Held.new())
	corner.steps(side(5, 0.03))
	corner.steps(up(8))
	_expect(corner.release().spin == 0.0, "sideways placement then a flick is straight", failures)
	var arc := Driver.new(Held.new())
	arc.steps(circle(RADIUS, 1.5, 0.28))
	_expect(arc.held.charge() == 0.0, "a part arc charges nothing", failures)
	var zigzag := Driver.new(Held.new())
	zigzag.steps(side(4, 0.03) + side(4, -0.03) + side(4, 0.03) + side(4, -0.03))
	_expect(zigzag.held.charge() == 0.0, "sideways jiggling charges nothing", failures)

	# Momentum: with the finger stopped, the ball spins on briefly, then hangs again.
	var coast := Driver.new(Held.new())
	coast.steps(circle(RADIUS, 3.5, 1.2))
	var turned_before := float(coast.held.turn_deg)
	_expect(coast.held.curve_ready() and not Driver.new(Held.new()).held.curve_ready(), "the sparkle state follows the threshold", failures)
	coast.hold(0.4)
	var spun_on := absf(coast.held.turn_deg - turned_before)
	coast.hold(2.0)
	_expect(spun_on > 90.0 and coast.held.charge() == 0.0 and not coast.held.swirling, "a stopped finger: the ball spins on (%.0f degrees) and settles to hanging" % spun_on, failures)

	# Reversing brakes the ball first, then builds the other way.
	var reverse := Driver.new(Held.new())
	reverse.steps(circle(RADIUS, 4.5, 1.2))
	var forward := float(reverse.held.charge())
	var spinning := float(reverse.held.orbit_speed)
	reverse.steps(circle(RADIUS, -4.5, 0.15))
	var braked := float(reverse.held.orbit_speed)
	reverse.steps(circle(RADIUS, -4.5, 1.5))
	_expect(forward > 0.9 and braked < spinning and reverse.held.charge() < -0.8, "reversing brakes the ball (%.1f -> %.1f rad/s) before it builds the other way (%.2f)" % [spinning, braked, reverse.held.charge()], failures)

	# The release: the flick sets the throw; the ball's swing adds only a nudge.
	var throw := Driver.new(Held.new())
	throw.steps(circle(RADIUS, 3.5, 1.2))
	var held_charge := float(throw.held.charge())
	throw.steps(up(8))
	var t := throw.release()
	_expect(t.committed and t.spin > 0.8 and absf(t.spin - held_charge) < 0.2, "a swirl then a flick throws the held charge (%.2f of %.2f)" % [t.spin, held_charge], failures)
	_expect(absf(t.angle_deg) < 20.0, "the ball's swing nudges the throw only a little (%.1f degrees)" % t.angle_deg, failures)
	var no_nudge_model := Held.new()
	no_nudge_model.tuning.orbit_nudge = 0.0
	var plain := Driver.new(no_nudge_model)
	plain.steps(circle(RADIUS, 3.5, 1.2))
	plain.steps(up(8))
	_expect(plain.release().angle_deg == 0.0, "with no nudge the flick alone sets the direction", failures)
	var weak := Driver.new(Held.new())
	weak.steps(circle(RADIUS, 0.5, 2.0))
	weak.steps(up(8))
	var w := weak.release()
	_expect(w.committed and w.spin == 0.0, "a slow circle then a flick throws straight", failures)
	var turned := Driver.new(Held.new())
	turned.steps(circle(RADIUS, 0.5, 2.0))
	turned.steps([Vector2(0.03, -0.02), Vector2(0.01, -0.05)] + up(6))
	_expect(turned.release().spin == 0.0, "turning sharply into a fast flick never pumps a curve", failures)

	# Event timing: 15 fps reads like 60 fps; a late lift still throws.
	var fps15 := swirl_charge(4.5, 1.5, FRAME * 4)
	_expect(absf(fps15 - brisk) < 0.15, "a brisk circle sampled at 15 fps charges like 60 fps (%.2f vs %.2f)" % [fps15, brisk], failures)
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
