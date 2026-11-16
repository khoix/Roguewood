# Agent task handoff — MUSIC-1 (the owner's soundtrack, 2026-11-16)

## Assignment
- **Owner:** Claude, at the owner's request.
- **The music:** the owner made it with Suno and uploaded it to the branch's top level, then said: "I've only created league music for the existing leagues. Will add more as those get added."
- **State:** DONE.
- **Paths:**
  - assets/audio/music/ (four OGG loops, with the MP3 originals in source/, ignored by Godot);
  - tools/author_soundtrack.py;
  - src/presentation/soundtrack.gd;
  - src/presentation/league_theme.gd (the track choice only);
  - src/bootstrap/bootstrap.gd (the Clubhouse music);
  - tests: league_house_test, J11, J22L01 and J22L02 (whose check the live-art journey inherits);
  - docs/art/ASSET-LEDGER.md.

## What changed
- **Seamless loops:**
  - Each Suno track faded out over its last 3 seconds. `tools/author_soundtrack.py` cuts 3.5 s before the end and crossfades the last 2 s into the first 2 s.
  - Measured at each seam, the levels before and after match within 1.5 dB, and the sample jump is at most 0.017.
  - The loudness is as delivered (about −16 LUFS), already matching the earlier loops.
- **Where each track plays:**
  - the Clubhouse track on the title and the board, stopping when an attempt begins;
  - the House or Neon track during that League's attempts;
  - the Championship track for Division 8's title match, swapping in when the Championship stage appears.
- **Precedence:** the soundtrack takes precedence over each theme's own loop. Codex's manifests and theme previews are unchanged.
- **Volume:** the Music slider and Mute (UI-11) set the League music in play. The Clubhouse music takes its level from them when the board opens.
- **The other Leagues** (Salvage, Royal, Spectral, Foundry) get theirs in `Soundtrack.TRACKS` when the owner makes them. Run `python3 tools/author_soundtrack.py <name>.mp3` and import with looping on.

## Validation
- **`qa.py unit`:** PASS. The House and Neon Leagues pick the owner's tracks, the Championship picks its own, and each track is a looping OGG over two minutes.
- **J11:** PASS. The Clubhouse music plays, and stops when an attempt begins.
- **J22L01:** PASS. The House track plays in every match, and the Championship track at the title match.
- **J22L02 and J22L02LIVEART:** PASS. The Neon track plays.
- **Also PASS:** J01 (headless and rendered), J03C18, J06, J07, J09, J10, `web`, J02 and JUIA1.
- **Fixed during this work:** a playing Clubhouse loop left two resources in use at exit (J01, J06, J10). The shell now waits one mixer pass after stopping it, as PresentationAudio does.

## Limitations
- **Not heard on a phone yet.**
- **Browsers:** a browser starts audio only after the first tap. On the web the Clubhouse music begins at the title's tap.

## Follow-up (the owner, 2026-11-16)
- **The Clubhouse music starts at the Clubhouse menu,** after the title's tap. Before, it began with the title, and on the web became audible at the title's tap.
- **The title's tap plays a sound** (`ui_title_start.wav`: a provisional ball-meets-pin built from two of Codex's sounds) at the sound-effects level. It is silent under Mute.
- **The prompt reads "Tap to Play"** ("Click or press any key to Play" on a desktop).
- **The title has a new signal, `tapped`,** for the moment of the tap. `started` still follows the 0.3 s fade.
- **Native app builds** could start music on the title without a tap, but browsers allow sound only after the first interaction. The owner chose the menu for both.
- **Checks:**
  - J01 (headless and rendered): "to Play", no music under the title, then the tap's sound and the music at the menu.
  - Also PASS: J11, `web`, JUIA1, JUIA2 and `unit`.

