extends RefCounted
## The owner's soundtrack (2026-11-16, made with Suno; assets/audio/music/): the
## Clubhouse, each League and the Championship. A track here takes precedence over a
## League theme's own loop (LeagueTheme falls back to its manifest's music). The
## files are trimmed before Suno's fade-out and crossfaded into their own start, so
## each loops seamlessly (tools/author_soundtrack.py). Salvage, Royal, Spectral and
## Foundry add theirs as the owner makes them.
const TRACKS := {
	"clubhouse": "res://assets/audio/music/clubhouse.ogg",
	"league.house": "res://assets/audio/music/house.ogg",
	"league.neon": "res://assets/audio/music/neon.ogg",
	"championship": "res://assets/audio/music/championship.ogg",
	# UI-22: the award ceremony after a run. The owner's Suno track goes here (run
	# tools/author_soundtrack.py awards.mp3); until then the ceremony plays without it.
	"awards": "res://assets/audio/music/awards.ogg",
}
## The music sits under the sound effects (as the League loops did).
const MUSIC_DB := -18.0

static func has(key: String) -> bool:
	return TRACKS.has(key) and ResourceLoader.exists(TRACKS[key])

static func stream(key: String) -> AudioStream:
	return load(TRACKS[key]) if has(key) else null

## The music's level for the session's settings: the Music slider (UI-11) and Mute.
static func level_db(settings: Dictionary) -> float:
	var level: float = 0.0 if bool(settings.get("sound_muted", false)) else float(settings.get("music_volume", 1.0))
	return MUSIC_DB + linear_to_db(maxf(level, 0.0001))
