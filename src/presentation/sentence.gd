extends RefCounted
## UI-28 (owner, 2026-11-19): in player-facing text, the first word after a colon
## starts with a capital. For text inserted after a colon at run time.
static func cap(text: String) -> String:
	return text if text.is_empty() else text[0].to_upper() + text.substr(1)
