"""The owner's soundtrack (2026-11-16): turns Suno MP3s into seamless OGG loops in
assets/audio/music/. Each track is cut 3.5 s before its end (Suno fades out there)
and its last 2 s are crossfaded into its first 2 s, so the loop's end runs straight
into its start. Loudness is left as delivered (about -16 LUFS, like the earlier loops).
Run: python3 tools/author_soundtrack.py <name>.mp3 [...]   (ffmpeg required)"""
import subprocess, sys, pathlib

CUT_BEFORE_END = 3.5
CROSSFADE = 2.0

def loop(source: pathlib.Path) -> pathlib.Path:
    duration = float(subprocess.check_output(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", str(source)]))
    cut = duration - CUT_BEFORE_END
    n = CROSSFADE
    graph = (f"[0]atrim=start={n}:end={cut - n},asetpts=PTS-STARTPTS[a];"
             f"[0]atrim=start={cut - n}:end={cut},asetpts=PTS-STARTPTS,afade=t=out:st=0:d={n}[b];"
             f"[0]atrim=start=0:end={n},asetpts=PTS-STARTPTS,afade=t=in:st=0:d={n}[c];"
             "[b][c]amix=inputs=2:normalize=0[x];[a][x]concat=n=2:v=0:a=1,aresample=44100[o]")
    out = pathlib.Path("assets/audio/music") / (source.stem + ".ogg")
    out.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", str(source), "-filter_complex", graph,
                    "-map", "[o]", "-c:a", "libvorbis", "-q:a", "5", str(out)], check=True)
    return out

if __name__ == "__main__":
    for name in sys.argv[1:]:
        print(loop(pathlib.Path(name)))
