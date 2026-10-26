"""Roguewood headless verification; unimplemented suites fail explicitly."""
import argparse
import os
from pathlib import Path
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
VERSION = (ROOT / ".godot-version").read_text().strip()


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
    parser.add_argument("command", choices=["doctor", "import", "smoke", "export", "unit", "integration", "content", "shell", "e2e"])
    parser.add_argument("--journey", choices=["J01"], default="J01")
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
    elif args.command == "e2e":
        flags = [] if args.rendered else ["--headless"]
        artifact_dir = ROOT / "artifacts/e03" / ("rendered" if args.rendered else "headless")
        artifact_dir.mkdir(parents=True, exist_ok=True)
        for old in artifact_dir.glob("*.png"):
            old.unlink()
        extra = ["--artifact-dir=" + str(artifact_dir)]
        if args.inject_failure:
            extra.append("--inject-failure")
        run([exe, *flags, "--path", str(ROOT), "--script", "res://tests/shell_smoke.gd", "--", *extra],
            "ROGUEWOOD_SHELL_OK", artifact_dir / "journey.log", timeout=30)
        if args.rendered and not all((artifact_dir / (name + ".png")).is_file() for name in ("menu", "session", "reset", "returned")):
            raise RuntimeError("Rendered J01 missing required screenshots")
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
