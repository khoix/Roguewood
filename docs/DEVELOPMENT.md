# Development

Use integration branch `codex/roguewood-build`; read AI-HANDOFF.md before changes.

## Prerequisites

Install Godot 4.5.2 **standard** (not .NET) and matching 4.5.2 export templates from https://godotengine.org/download/archive/4.5.2-stable/. Verify `godot --version` begins `4.5.2.stable.`. Python 3.10+ is required (no third-party Python packages). Set `GODOT_BIN` to the executable path if it is not named godot/godot4 on PATH.

From repository root:

```sh
python3 tools/qa.py doctor
python3 tools/qa.py import
python3 tools/qa.py unit
python3 tools/qa.py content
python3 tools/qa.py integration
python3 tools/qa.py smoke
python3 tools/qa.py export
```

`export` builds and starts Linux x86-64 debug output, requires matching templates, and is Linux-only. It does not validate iOS, Android, or Windows. Use the editor's template manager to install templates, or see the CI installation script for Linux. Outputs live in ignored build/. CI repeats doctor, unit, content, integration, smoke, and export on pushes and pull requests.

Open project.godot with the pinned editor; F6/F5 runs the title fixture. It is developer scaffolding, not release artwork or a playable game. Use `"$GODOT_BIN" --path .` with your shell's environment-variable syntax for CLI launch.

E02 supplies unit, content, and contract integration suites; see [Contracts](CONTRACTS.md). The E03 e2e command supports the bootstrap J01 journey described below. E03 must implement actual UI/input-driven E2E, deterministic fixtures and failure artifacts. Logs report engine script errors even if the engine returns zero.

## Mobile feasibility

See decisions/001-foundation.md for target matrix, renderer and module boundaries. iOS export needs macOS and Xcode; Android needs Android SDK/JDK; signing and device evidence remain outstanding. No credentials or export_credentials.cfg belong in Git. Linux smoke is the bootstrap acceptance check, not a substitute for device testing.

CI verifies both downloads against tools/godot-downloads.sha512, copied from the official 4.5.2 release SHA512-SUMS.txt and verified locally. Update version and checksums together when intentionally upgrading.

## E03 native journey

`python3 tools/qa.py e2e --journey J01` drives native UI actions through menu, fixed House League/House Kit entry, deterministic reset and return. Only that initial fixture is selectable; catalogue and Career eligibility come later. `shell` remains a quick alias for the underlying script. Use `xvfb-run -a python3 tools/qa.py e2e --journey J01 --rendered` on Linux to exercise real rendering and save menu/session/reset/returned PNGs. A real desktop display also works without Xvfb. These captures document developmental UI, not final art approval.

Artifacts live in ignored `artifacts/e03/headless` and `artifacts/e03/rendered`. Per-run screenshot cleanup prevents old captures from falsely satisfying validation. Logs include state checkpoints. `--inject-failure` must return nonzero and retain the failure log (plus failure.png when rendered). State waits are bounded at two seconds; outer process timeout is thirty seconds and preserves partial output. A hung renderer may prevent a final failure screenshot, so earlier checkpoints and timeout logs are retained. CI runs both modes and uploads diagnostics even on failure. J01 is the E03 bootstrap journey, not later device/whole-game acceptance. Other journeys are rejected until implemented.
