"""Roguewood headless verification; unimplemented suites fail explicitly."""
import argparse
import os
from pathlib import Path
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
VERSION = (ROOT / ".godot-version").read_text().strip()
# journey -> script, success marker, artifact directory, rendered captures, timeout, extra engine flags
JOURNEYS = {
    "J08": ("res://tests/motion_journey.gd", "ROGUEWOOD_J08_OK", "artifacts/e12",
            ("aim", "foil", "reveal", "rolling", "impact", "scoring", "reaction", "returned"), 900, ["--fixed-fps", "60"]),
    "J01": ("res://tests/shell_smoke.gd", "ROGUEWOOD_SHELL_OK", "artifacts/e03", ("menu", "session", "reset", "returned"), 30, []),
    "J02": ("res://tests/throw_journey.gd", "ROGUEWOOD_J02_OK", "artifacts/e04",
            ("aim", "cancelled", "rolling", "roll1", "roll2_aim", "frame", "gutter", "target", "curve_right_hold",
             "curve_right", "curve_left", "assist", "landscape"), 600, ["--fixed-fps", "60"]),
    "J03": ("res://tests/scoring_journey.gd", "ROGUEWOOD_J03_OK", "artifacts/e06",
            ("scoring", "strike", "spare", "open"), 600, ["--fixed-fps", "60"]),
    "J04": ("res://tests/deck_journey.gd", "ROGUEWOOD_J04_OK", "artifacts/e07",
            ("hand", "keep", "match_over", "exhausted", "direct"), 900, ["--fixed-fps", "60"]),
    "J05": ("res://tests/shop_journey.gd", "ROGUEWOOD_J05_OK", "artifacts/e08",
            ("shop", "bought", "funds", "place_pin", "full_slot", "removed", "landscape", "match2"), 900, ["--fixed-fps", "60"]),
    "J06": ("res://tests/division_journey.gd", "ROGUEWOOD_J06_OK", "artifacts/e09",
            ("preview", "shop_preview", "intro", "boss", "lost", "won", "lost_again"), 900, ["--fixed-fps", "60"]),
    "J07": ("res://tests/save_journey.gd", "ROGUEWOOD_J07_OK", "artifacts/e10",
            ("continue_menu", "resumed_hand", "resumed_roll", "resumed_frame", "resumed_shop", "resumed_reroll",
             "resumed_roll2", "career_kept", "fallback", "no_save"), 300, ["--fixed-fps", "60"]),
}
# Journeys that restart the game: each stage is a separate engine process sharing
# one save directory; stage k prints ROGUEWOOD_<journey>_STAGE<k>_OK.
STAGES = {"J07": 10}


def engine():
    executable = os.environ.get("GODOT_BIN") or shutil.which("godot") or shutil.which("godot4")
    if not executable:
        raise RuntimeError("Godot not found; install pinned version and set GODOT_BIN")
    version = subprocess.check_output([executable, "--version"], text=True).strip()
    if not version.startswith(VERSION + ".stable."):
        raise RuntimeError(f"Expected {VERSION}.stable, got {version}")
    return executable


def run(args, marker=None, log_path=None, timeout=120):
    try:
        result = subprocess.run(args, cwd=ROOT, capture_output=True, text=True, timeout=timeout)
    except subprocess.TimeoutExpired as error:
        def decode(value):
            return value.decode(errors="replace") if isinstance(value, bytes) else (value or "")
        output = decode(error.stdout) + decode(error.stderr) + "\nTIMEOUT\n"
        if log_path:
            log_path.parent.mkdir(parents=True, exist_ok=True)
            log_path.write_text(output)
        raise RuntimeError(f"Timed out after {timeout}s: {args}") from error
    output = result.stdout + result.stderr
    if log_path:
        log_path.parent.mkdir(parents=True, exist_ok=True)
        log_path.write_text(output)
    print(output, end="")
    if result.returncode or "SCRIPT ERROR:" in output or "ERROR:" in output:
        raise RuntimeError(f"Command failed: {args}")
    if marker and marker not in output:
        raise RuntimeError(f"Missing completion marker: {marker}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=["doctor", "import", "smoke", "export", "unit", "integration", "content", "physics", "shell", "e2e", "experiment"])
    parser.add_argument("--journey", choices=sorted(JOURNEYS), default="J01")
    parser.add_argument("--rendered", action="store_true", help="Use a real display; on Linux run via xvfb-run")
    parser.add_argument("--inject-failure", action="store_true", help="Exercise J01 failure artifacts")
    args = parser.parse_args()
    exe = engine()
    if args.command == "doctor":
        print(f"Godot {VERSION}; Python {sys.version.split()[0]}; project={ROOT}")
        return
    run([exe, "--headless", "--path", str(ROOT), "--editor", "--import"])
    if args.command in ("unit", "content", "integration"):
        run([exe, "--headless", "--path", str(ROOT), "--script", "res://tests/run_tests.gd", "--", args.command], "ROGUEWOOD_" + args.command.upper() + "_OK")
    elif args.command == "physics":
        artifact_dir = ROOT / "artifacts/e04"
        artifact_dir.mkdir(parents=True, exist_ok=True)
        report = artifact_dir / "physics-report.json"
        report.unlink(missing_ok=True)
        run([exe, "--headless", "--fixed-fps", "60", "--path", str(ROOT), "--script", "res://tests/run_tests.gd", "--", "physics",
             "--report=" + str(report)], "ROGUEWOOD_PHYSICS_OK", artifact_dir / "physics.log", timeout=600)
    elif args.command == "experiment":
        artifact_dir = ROOT / "artifacts/e07"
        artifact_dir.mkdir(parents=True, exist_ok=True)
        report = artifact_dir / "deck-experiment.json"
        report.unlink(missing_ok=True)
        run([exe, "--headless", "--path", str(ROOT), "--script", "res://tools/deck_experiment.gd", "--", "--runs=1000",
             "--out=" + str(report)], "ROGUEWOOD_EXPERIMENT_OK", artifact_dir / "experiment.log", timeout=600)
    elif args.command == "e2e":
        script, marker, artifacts, captures, timeout, engine_flags = JOURNEYS[args.journey]
        flags = ["--audio-driver", "Dummy", *engine_flags]
        if not args.rendered:
            flags.append("--headless")
        mode = "rendered" if args.rendered else "headless"
        if args.inject_failure:
            mode += "-failure"
        artifact_dir = ROOT / artifacts / mode
        artifact_dir.mkdir(parents=True, exist_ok=True)
        for old in artifact_dir.glob("*.png"):
            old.unlink()
        # Every journey saves into its own fresh directory, never the user's saves.
        save_dir = artifact_dir / "saves"
        shutil.rmtree(save_dir, ignore_errors=True)
        save_dir.mkdir(parents=True)
        extra = ["--artifact-dir=" + str(artifact_dir), "--save-dir=" + str(save_dir)]
        stages = STAGES.get(args.journey, 0)
        if not stages:
            if args.inject_failure:
                extra.append("--inject-failure")
            run([exe, *flags, "--path", str(ROOT), "--script", script, "--", *extra],
                marker, artifact_dir / "journey.log", timeout=timeout)
        else:
            logs = []
            for stage in range(1, stages + 1):
                stage_extra = extra + ["--stage=%d" % stage]
                if args.inject_failure and stage == stages:
                    stage_extra.append("--inject-failure")
                stage_marker = marker if stage == stages else marker.replace("_OK", "_STAGE%d_OK" % stage)
                log = artifact_dir / ("journey-stage%d.log" % stage)
                try:
                    run([exe, *flags, "--path", str(ROOT), "--script", script, "--", *stage_extra], stage_marker, log, timeout=timeout)
                finally:
                    if log.is_file():
                        logs.append(log.read_text())
                    (artifact_dir / "journey.log").write_text("".join(logs))
        if args.rendered and not all((artifact_dir / (name + ".png")).is_file() for name in captures):
            raise RuntimeError(f"Rendered {args.journey} missing required screenshots")
    elif args.command == "shell":
        run([exe, "--headless", "--path", str(ROOT), "--script", "res://tests/shell_smoke.gd"], "ROGUEWOOD_SHELL_OK", ROOT / "artifacts/e03/shell.log")
    elif args.command == "smoke":
        run([exe, "--headless", "--path", str(ROOT), "--", "--bootstrap-smoke"], "ROGUEWOOD_BOOT_OK")
    elif args.command == "export":
        target = ROOT / "build/linux/roguewood.x86_64"
        target.parent.mkdir(parents=True, exist_ok=True)
        run([exe, "--headless", "--path", str(ROOT), "--export-debug", "Linux", str(target)])
        run([str(target), "--headless", "--", "--bootstrap-smoke"], "ROGUEWOOD_BOOT_OK")


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, OSError, subprocess.SubprocessError) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        sys.exit(1)
