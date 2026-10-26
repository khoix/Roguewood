# Development

Read AI-HANDOFF.md before changes; it records the active branch (E04 work is on `claude/roguewood-build`, derived from the E03-accepted `codex/roguewood-build`).

## Prerequisites

Install Godot 4.5.2 **standard** (not .NET) and matching 4.5.2 export templates from https://godotengine.org/download/archive/4.5.2-stable/. Verify `godot --version` begins `4.5.2.stable.`. Python 3.10+ is required (no third-party Python packages). Set `GODOT_BIN` to the executable path if it is not named godot/godot4 on PATH.

From repository root:

```sh
python3 tools/qa.py doctor
python3 tools/qa.py import
python3 tools/qa.py unit
python3 tools/qa.py content
python3 tools/qa.py integration
python3 tools/qa.py physics
python3 tools/qa.py smoke
python3 tools/qa.py export
```

`export` builds and starts Linux x86-64 debug output, requires matching templates, and is Linux-only. It does not validate iOS, Android, or Windows. Use the editor's template manager to install templates, or see the CI installation script for Linux. Outputs live in ignored build/. CI repeats doctor, unit, content, integration, physics, smoke, and export on pushes and pull requests.

Open project.godot with the pinned editor; F5 runs the shell, and Enter League opens the E04 throw lab. Hold the ball, drag to line up, circle to spin, then flick up. Mouse works through touch emulation, and Options opens the throw settings (handedness, sensitivity, reduced motion, larger targets, assist controls). It is developer scaffolding, not release artwork or the game loop. Use `"$GODOT_BIN" --path .` with your shell's environment-variable syntax for CLI launch.

E02 supplies unit, content, and contract integration suites; see [Contracts](CONTRACTS.md). The E03 e2e command supports the bootstrap J01 journey described below. E03 must implement actual UI/input-driven E2E, deterministic fixtures and failure artifacts. Logs report engine script errors even if the engine returns zero.

## Mobile feasibility

See decisions/001-foundation.md for target matrix, renderer and module boundaries. iOS export needs macOS and Xcode; Android needs Android SDK/JDK; signing and device evidence remain outstanding. No credentials or export_credentials.cfg belong in Git. Linux smoke is the bootstrap acceptance check, not a substitute for device testing.

CI verifies both downloads against tools/godot-downloads.sha512, copied from the official 4.5.2 release SHA512-SUMS.txt and verified locally. Update version and checksums together when intentionally upgrading.

## E03 native journey

`python3 tools/qa.py e2e --journey J01` drives native UI actions through menu, fixed House League/House Kit entry, deterministic reset and return. Only that initial fixture is selectable; catalogue and Career eligibility come later. `shell` remains a quick alias for the underlying script. Use `xvfb-run -a python3 tools/qa.py e2e --journey J01 --rendered` on Linux to exercise real rendering and save menu/session/reset/returned PNGs. A real desktop display also works without Xvfb. These captures document developmental UI, not final art approval.

Artifacts live in ignored `artifacts/e03/headless` and `artifacts/e03/rendered`. Per-run screenshot cleanup prevents old captures from falsely satisfying validation. Logs include state checkpoints. `--inject-failure` must return nonzero and retain the failure log (plus failure.png when rendered). State waits are bounded at two seconds; outer process timeout is thirty seconds and preserves partial output. A hung renderer may prevent a final failure screenshot, so earlier checkpoints and timeout logs are retained. CI runs both modes and uploads diagnostics even on failure. J01 is the E03 bootstrap journey, not later device/whole-game acceptance. Other journeys are rejected until implemented.

Automated J01 explicitly uses Godot Dummy audio; normal gameplay audio is unchanged. Intentional failure artifacts use separate headless-failure/rendered-failure directories. CI also runs `xvfb-run -a python3 tools/verify_diagnostics.py`, checking the deliberate failure exit, PNG signatures, failure logs, timeout partial output and strict engine-error rejection. Locally `--headless` runs the same diagnostics without screenshot assertions.

## E04 throw lab, physics fixtures and J02

`python3 tools/qa.py physics` runs `content/fixtures/throws/lab_throws.json` through real Jolt worlds headless at `--fixed-fps 60`. It checks contracts and outcome classes and requires repeated launches, aim delays and a JSON rack round trip to produce identical results. It also reports start-x sensitivity. The output is `artifacts/e04/physics.log` and `physics-report.json`, whose `digest` summarizes every outcome and final pose, so you can compare digests across machines. A run takes about 20 s.

`python3 tools/qa.py e2e --journey J02` drives the shell and throw lab through `Input.parse_input_event` touch and drag events. It covers three cancel paths (sideways only, slow, and OS-cancelled) that must consume nothing, and a touch away from the ball. It then plays a straight two-roll frame in which survivors are respotted, no pin is credited twice and the E02 `FrameRules.validate` accepts the frame, followed by Next Rack and a gutter frame. Finally it checks that both live rolls replay identically from their committed records in fresh worlds. J02 passes `--fixed-fps 60`, so gesture timing is deterministic. `--rendered` (via `xvfb-run -a` on Linux) saves aim, cancelled, rolling, roll1, roll2_aim, frame and gutter PNGs to `artifacts/e04/rendered`, and `--inject-failure` must exit 1. Expect about 1 minute rendered on llvmpipe. These captures show developmental geometry, not art approval or device feel.

## E05 curves, settings and J02 extension

J02 also covers:
- A tap on the lane that moves the target ring, and a short flick that cancels.
- A clockwise and a counter-clockwise circle gesture. Each must charge matching spin without steering the flick, contract and freeze the ring, carry the moved target, and hook more than 5 cm the matching way.
- A mouse throw, through touch emulation.
- Settings toggled through focused controls: reduced motion and assist on, then off.
- An assist throw driven only by keyboard actions on the sliders and Throw. Its launch must equal `LaunchMapper.from_controls`.
- A throw after rotating to landscape.
- A trial-log check: one complete line per committed roll, with touch, mouse and assist sources present.

J02 pins a phone-portrait window (450×800, so a 720×1280 canvas) in both modes. The project now uses stretch aspect `expand`, so the canvas follows the window; without this profile, the 64×64 headless window would turn the same injected gesture into different motion. Rendered J02 adds the target, curve_right_hold, curve_right, curve_left, assist and landscape captures, and saves `trials.jsonl` beside the screenshots. It takes about 70 s rendered on llvmpipe.

`physics` now includes curved fixtures. They check pocket hooks for both hands, that hook grows with spin, an exact mirror for opposite spin, faster throws hooking less, and spin 0 staying straight. In play, every committed roll appends to `user://throw_trials.jsonl` for the device trials in `docs/playtests/E05-device-trials.md`. Screenshots and logs are never committed; CI uploads them as the `journeys` artifact.
