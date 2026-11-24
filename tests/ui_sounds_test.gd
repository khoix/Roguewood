extends RefCounted
## AV-UI1 (2026-11-24): the final button sounds. Every kind has a House sound; Neon has
## its own three; any other League keeps the House's. Each is short and quiet enough
## to sit under the foley (UI-12's loudness).
const UiSounds = preload("res://src/presentation/ui_sounds.gd")

static func run() -> Array[String]:
	var failures: Array[String] = []
	for kind in ["tap", "select", "back"]:
		var house: AudioStream = UiSounds.sound_for(kind, "")
		var neon: AudioStream = UiSounds.sound_for(kind, "league.neon")
		if house == null or house != UiSounds.sound_for(kind, "league.house") or house != UiSounds.sound_for(kind, "league.salvage"):
			failures.append("AV-UI1: %s plays the House sound outside Neon" % kind)
		if neon == null or neon == house or not String(neon.resource_path).ends_with(".neon.wav"):
			failures.append("AV-UI1: %s has its own Neon sound" % kind)
		for stream in [house, neon]:
			if stream is AudioStreamWAV:
				var seconds: float = stream.get_length()
				if seconds < 0.03 or seconds > 0.08:
					failures.append("AV-UI1: %s lasts 30-80 ms (%.0f ms)" % [stream.resource_path, seconds * 1000.0])
				# The source file's samples (the imported data may be compressed).
				var data: PackedByteArray = FileAccess.get_file_as_bytes(stream.resource_path).slice(44)
				var peak := 0
				for i in range(0, data.size() - 1, 2):
					peak = maxi(peak, absi(data.decode_s16(i)))
				if peak == 0 or peak > 15600:
					failures.append("AV-UI1: %s peaks at or under -6.4 dBFS (%d)" % [stream.resource_path, peak])
	if UiSounds.sound_for("", "league.neon") != null:
		failures.append("AV-UI1: no sound for an opted-out button")
	return failures
