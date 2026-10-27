"""E12 native J08 matrix and reproducible videos; run under xvfb-run on Linux."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
from qa import engine, run


def main():
    exe = engine()
    run([exe, "--headless", "--editor", "--import"])
    report = []
    for landscape, reduced in [(False, False), (True, False), (False, True), (True, True)]:
        mode = ("landscape" if landscape else "portrait") + ("-reduced" if reduced else "-full")
        output = ROOT / "artifacts/e12" / mode
        output.mkdir(parents=True, exist_ok=True)
        video = landscape == reduced  # portrait full, landscape reduced
        args = [exe, "--path", str(ROOT), "--audio-driver", "Dummy", "--fixed-fps", "60",
                "--resolution", "1280x720" if landscape else "720x1280"]
        avi = output / "sequence.avi"
        if video:
            args += ["--write-movie", str(avi)]
        args += ["--script", "res://tests/motion_journey.gd", "--", f"--artifact-dir={output}"]
        if landscape:
            args.append("--landscape")
        if reduced:
            args.append("--reduced")
        # MovieWriter initializes before SceneTree callbacks; project window
        # overrides win over --resolution. Supply only temporary window settings.
        override = ROOT / "override.cfg"
        if override.exists():
            raise RuntimeError("Existing override.cfg: refusing to replace local configuration")
        width, height = (1280, 720) if landscape else (720, 1280)
        override.write_text(f"[display]\nwindow/size/viewport_width={width}\nwindow/size/viewport_height={height}\n"
                            f"window/size/window_width_override={width}\nwindow/size/window_height_override={height}\n")
        try:
            run(args, "ROGUEWOOD_J08_OK", output / "journey.log", timeout=900)
        finally:
            override.unlink()
        for name in ["aim", "foil", "reveal", "rolling", "impact", "scoring", "reaction", "returned"]:
            if not (output / f"{name}.png").is_file():
                raise RuntimeError(f"Missing {mode}/{name}.png")
        if video:
            encoder = shutil.which("ffmpeg")
            if not encoder:
                raise RuntimeError("ffmpeg required for review video")
            subprocess.run([encoder, "-y", "-v", "error", "-i", str(avi), "-an", "-c:v", "libx264",
                            "-crf", "20", "-pix_fmt", "yuv420p", "-movflags", "+faststart",
                            str(output / "sequence.mp4")], check=True, timeout=180)
            probe = subprocess.check_output(["ffprobe", "-v", "error", "-select_streams", "v:0",
                                             "-show_entries", "stream=width,height", "-of", "json", str(output / "sequence.mp4")], text=True)
            dimensions = json.loads(probe)["streams"][0]
            expected = (1280, 720) if landscape else (720, 1280)
            if (dimensions["width"], dimensions["height"]) != expected:
                raise RuntimeError(f"Wrong movie dimensions: {dimensions}, expected {expected}")
            avi.unlink()
        report.append({"mode": mode, "video": video,
                       "metrics": json.loads((output / "metrics.json").read_text())})
    path = ROOT / "artifacts/e12/matrix.json"
    path.write_text(json.dumps(report, indent=2) + "\n")
    print("ROGUEWOOD_E12_MATRIX_OK")


if __name__ == "__main__":
    main()
