"""Verify deliberate J01 failure evidence and runner timeout/error detection."""
import argparse
from pathlib import Path
import subprocess
import sys
import tempfile

import qa


def check_runner():
    with tempfile.TemporaryDirectory() as directory:
        log = Path(directory) / "timeout.log"
        try:
            qa.run([sys.executable, "-u", "-c", "import time; print('partial-output'); time.sleep(5)"], log_path=log, timeout=0.2)
        except RuntimeError:
            assert "partial-output" in log.read_text() and "TIMEOUT" in log.read_text()
        else:
            raise AssertionError("Timeout was accepted")
        try:
            qa.run([sys.executable, "-c", "print('ERROR: diagnostic probe')"])
        except RuntimeError:
            pass
        else:
            raise AssertionError("Zero-exit engine error was accepted")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--headless", action="store_true")
    args = parser.parse_args()
    check_runner()
    mode = "headless-failure" if args.headless else "rendered-failure"
    directory = qa.ROOT / "artifacts/e03" / mode
    # The QA invocation clears stale PNGs; clear the old log too so launch
    # failures cannot masquerade as the requested intentional assertion.
    (directory / "journey.log").unlink(missing_ok=True)
    command = [sys.executable, str(qa.ROOT / "tools/qa.py"), "e2e", "--journey", "J01", "--inject-failure"]
    if not args.headless:
        command.append("--rendered")
    result = subprocess.run(command, cwd=qa.ROOT, capture_output=True, text=True, timeout=60)
    (qa.ROOT / "artifacts/e03/diagnostic-probe.log").write_text(result.stdout + result.stderr)
    assert result.returncode == 1, f"Expected controlled failure exit1, got {result.returncode}"
    log = (directory / "journey.log").read_text()
    assert "Injected diagnostic failure" in log and "J01 failure" in log
    assert "SCRIPT ERROR:" not in log and "ERROR:" not in log, "Unexpected engine error"
    assert "ROGUEWOOD_SHELL_OK" not in log, "Failed journey emitted success"
    if not args.headless:
        for name in ("menu", "session", "reset", "returned", "failure"):
            data = (directory / (name + ".png")).read_bytes()
            assert data.startswith(b"\x89PNG\r\n\x1a\n") and len(data) > 100, name
    print("ROGUEWOOD_DIAGNOSTICS_OK")


if __name__ == "__main__":
    main()
