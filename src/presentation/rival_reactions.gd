extends RefCounted
## Chooses rival reactions from play events (E09, design §18): one reaction at a
## time, with precedence and a cooldown, so a scoring chain cannot spam the portrait.
## Pure and clock-driven (microseconds), so tests and the lab share the same rules.
## Reactions are presentation only: they never pause input or change a result.
const COOLDOWN_USEC := 3000000
const SHOW_USEC := 2500000
## event -> [reaction key, precedence]. Results outrank tension, which outranks play.
const EVENTS := {
	"entrance": ["entrance", 1],
	"strike": ["impressed", 1],
	"gutter": ["confident", 1],
	"open": ["confident", 1],
	"near_victory": ["threatened", 2],
	"victory": ["defeated", 3],
	"defeat": ["victorious", 3],
}

var current := "" # reaction key on show, or ""
var shown_at := -COOLDOWN_USEC
var precedence := 0
var history: Array = [] # {event, reaction, at, shown}

## Returns the reaction key to show for an event at time now, or "" if suppressed.
func react(event: String, now: int) -> String:
	if not EVENTS.has(event):
		return ""
	var reaction: String = EVENTS[event][0]
	var rank: int = EVENTS[event][1]
	var cooling: bool = now - shown_at < COOLDOWN_USEC
	var shown: bool = not cooling or rank > precedence
	history.append({"event": event, "reaction": reaction, "at": now, "shown": shown})
	if not shown:
		return ""
	current = reaction
	shown_at = now
	precedence = rank
	return reaction

## The reaction still on show at time now, or "".
func visible_at(now: int) -> String:
	return current if now - shown_at < SHOW_USEC else ""
