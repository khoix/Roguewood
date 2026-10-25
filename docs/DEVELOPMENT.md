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

E02 supplies unit, content, and contract integration suites; see [Contracts](CONTRACTS.md). The e2e command deliberately fails until E03 supplies it. E03 must implement actual UI/input-driven E2E, deterministic fixtures and failure artifacts. Logs report engine script errors even if the engine returns zero.

## Mobile feasibility

See decisions/001-foundation.md for target matrix, renderer and module boundaries. iOS export needs macOS and Xcode; Android needs Android SDK/JDK; signing and device evidence remain outstanding. No credentials or export_credentials.cfg belong in Git. Linux smoke is the bootstrap acceptance check, not a substitute for device testing.

CI verifies both downloads against tools/godot-downloads.sha512, copied from the official 4.5.2 release SHA512-SUMS.txt and verified locally. Update version and checksums together when intentionally upgrading.
