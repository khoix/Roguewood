"""Reproduce E11 stills with pinned Godot on a real display (xvfb-run on Linux)."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import struct
import subprocess

ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / "artifacts/e11"


def run(args, name):
    result = subprocess.run(args, cwd=ROOT, capture_output=True, text=True, timeout=120)
    output = result.stdout + result.stderr
    (OUTPUT / f"{name}.log").write_text(output)
    if result.returncode or "ERROR:" in output or "SCRIPT ERROR:" in output:
        raise RuntimeError(output)
    return output


def main():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    engine = os.environ.get("GODOT_BIN") or shutil.which("godot")
    if not engine:
        raise RuntimeError("Set GODOT_BIN to the pinned Godot executable")
    version = subprocess.check_output([engine, "--version"], text=True).strip()
    if not version.startswith((ROOT / ".godot-version").read_text().strip() + ".stable."):
        raise RuntimeError(f"Wrong engine: {version}")
    manifest = json.loads((ROOT / "docs/art/assets.json").read_text())
    for item in manifest:
        data = (ROOT / item["path"]).read_bytes()
        assert hashlib.sha256(data).hexdigest() == item["sha256"], item["path"]
        assert struct.unpack(">II", data[16:24]) == tuple(item["dimensions"])
    run([engine, "--headless", "--editor", "--import"], "import")
    report = {"engine": version, "captures": [], "scope": "Still fixture, not gameplay or device validation"}
    for mode, dimensions in [("portrait", (720, 1280)), ("landscape", (1280, 720))]:
        path = OUTPUT / f"{mode}.png"
        path.unlink(missing_ok=True)
        args = [engine, "--audio-driver", "Dummy", "--script", "assets/art_direction/still.gd",
                "--", f"--capture={path}"]
        if mode == "landscape":
            args.append("--landscape")
        log = run(args, mode)
        assert "ROGUEWOOD_E11_STILL_OK" in log, log
        data = path.read_bytes()
        assert data[:8] == b"\x89PNG\r\n\x1a\n"
        assert struct.unpack(">II", data[16:24]) == dimensions
        report["captures"].append({"file": path.name, "dimensions": dimensions,
                                   "sha256": hashlib.sha256(data).hexdigest()})
    (OUTPUT / "report.json").write_text(json.dumps(report, indent=2) + "\n")
    print("ROGUEWOOD_E11_CAPTURE_OK")


if __name__ == "__main__":
    main()
