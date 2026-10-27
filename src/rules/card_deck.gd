extends RefCounted
## Proposed draw-and-cycle equipment (design §15), built for E07's experiment and
## NOT a settled decision (ADR 004). Pure and seeded: shuffles use only this deck's
## own RNG stream, and the whole state round-trips as JSON data for saves (E10).
## The House ball is never a card: playing nothing always throws House.
## Card identity is a stable uid per copy ("card-1"…); the item id says what it is,
## and its category prefix (ball./consumable.) says how it plays.
const MODEL := "deck"
const SCHEMA_VERSION := 1
const HAND_SIZE := 4

var cards: Dictionary = {} # uid -> item_id
var draw_pile: Array = [] # last entry is the top card
var hand: Array = []
var discard: Array = []
var exhausted: Array = []
var frame := 0
var cycled := false
var reshuffles := 0
var tactical_rolls: Array = []
var rng_seed := 0
var _rng := RandomNumberGenerator.new()

static func create(item_ids: Array, deck_seed: int) -> RefCounted:
	var deck = load("res://src/rules/card_deck.gd").new()
	for index in item_ids.size():
		deck.cards["card-%d" % (index + 1)] = item_ids[index]
	deck.rng_seed = deck_seed
	deck._rng.seed = deck_seed
	deck.start_match()
	return deck

static func kind(item_id: String) -> String:
	if item_id.begins_with("ball."):
		return "ball"
	return "tactical" if item_id.begins_with("consumable.") else "other"

## Recombines hand, draw and discard (never exhausted cards) and shuffles.
func start_match() -> void:
	var pool: Array = []
	for uid in cards:
		if uid not in exhausted:
			pool.append(uid)
	pool.sort_custom(_uid_order)
	draw_pile = pool
	_shuffle(draw_pile)
	hand = []
	discard = []
	frame = 0
	cycled = false
	tactical_rolls = []

## Frame start: keep at most one card from the previous hand, discard the rest,
## then draw up to the hand size. The first frame of a match just draws.
func start_frame(retain: String = "") -> Array[String]:
	var errors: Array[String] = []
	if frame > 0 and not retain.is_empty() and retain not in hand:
		errors.append("can only retain a card from the current hand")
		return errors
	if frame > 0:
		for uid in hand.duplicate():
			if uid != retain:
				hand.erase(uid)
				discard.append(uid)
	while hand.size() < HAND_SIZE and _draw_one():
		pass
	frame += 1
	cycled = false
	tactical_rolls = []
	return errors

func _draw_one() -> bool:
	if draw_pile.is_empty():
		if discard.is_empty():
			return false
		draw_pile = discard
		discard = []
		draw_pile.sort_custom(_uid_order)
		_shuffle(draw_pile)
		reshuffles += 1
	hand.append(draw_pile.pop_back())
	return true

func _shuffle(pile: Array) -> void:
	for i in range(pile.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var swap = pile[i]
		pile[i] = pile[j]
		pile[j] = swap

static func _uid_order(a: String, b: String) -> bool:
	return int(a.trim_prefix("card-")) < int(b.trim_prefix("card-"))

## Playable choices this roll, in hand order.
func options() -> Array:
	var out: Array = []
	for uid in hand:
		out.append({"uid": uid, "item_id": cards[uid], "kind": kind(cards[uid]), "uses": 1})
	return out

## A ball card commits to one roll and goes to the discard pile (no refund on a
## strike). A tactical card is exhausted for the rest of the run; one per roll.
func play(uid: String, roll_index: int) -> Array[String]:
	var errors: Array[String] = []
	if uid not in hand:
		errors.append("card is not in hand: " + uid)
		return errors
	match kind(cards[uid]):
		"ball":
			hand.erase(uid)
			discard.append(uid)
		"tactical":
			if roll_index in tactical_rolls:
				errors.append("only one tactical card per roll")
				return errors
			hand.erase(uid)
			exhausted.append(uid)
			tactical_rolls.append(roll_index)
		_:
			errors.append("card cannot be played: " + cards[uid])
	return errors

func can_cycle() -> bool:
	return not cycled and not hand.is_empty()

## Once per frame: discard one unplayed card and draw one.
func cycle(uid: String) -> Array[String]:
	var errors: Array[String] = []
	if cycled:
		errors.append("already cycled this frame")
	elif uid not in hand:
		errors.append("card is not in hand: " + uid)
	if not errors.is_empty():
		return errors
	hand.erase(uid)
	discard.append(uid)
	_draw_one()
	cycled = true
	return errors

func can_retain() -> bool:
	return true

func counts() -> Dictionary:
	return {"hand": hand.size(), "draw": draw_pile.size(), "discard": discard.size(), "exhausted": exhausted.size()}

## RNG state is a 64-bit integer; it is stored as a string so JSON cannot round it.
func to_dict() -> Dictionary:
	return {"schema_version": SCHEMA_VERSION, "model": MODEL, "cards": cards.duplicate(), "draw_pile": draw_pile.duplicate(),
		"hand": hand.duplicate(), "discard": discard.duplicate(), "exhausted": exhausted.duplicate(), "frame": frame,
		"cycled": cycled, "reshuffles": reshuffles, "tactical_rolls": tactical_rolls.duplicate(), "seed": str(rng_seed), "rng_state": str(_rng.state)}

static func from_dict(data: Dictionary) -> RefCounted:
	var deck = load("res://src/rules/card_deck.gd").new()
	deck.cards = data.cards.duplicate()
	for key in ["draw_pile", "hand", "discard", "exhausted"]:
		deck.set(key, data[key].duplicate())
	deck.frame = int(data.frame)
	deck.cycled = bool(data.cycled)
	deck.reshuffles = int(data.reshuffles)
	deck.tactical_rolls = data.tactical_rolls.map(func(r): return int(r))
	deck.rng_seed = int(data.seed)
	deck._rng.seed = deck.rng_seed
	deck._rng.state = int(data.rng_state)
	return deck
