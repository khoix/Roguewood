# E05 device trials — straight and curve feel

Status: **NOT RUN.** No phone, iOS toolchain or Android SDK was available in the E05 Linux session, and no mobile build exists yet (exports are E26 work). This page is the protocol to run once a device build exists. Until then, the real-phone gate stays open.

## What this checks (design §5 feel tests)

1. A first-time player releases an intentional **straight** ball within **3 tries**.
2. They can produce clockwise and counter-clockwise curves on purpose, and tell them apart, within **10 tries**.
3. They can explain their misses. If they blame unexplained randomness, fix input or feedback before adding content.

## Setup

- A build from the branch under test on a primary-target phone (iPhone 13 Pro class, iOS 16+) and on at least one secondary phone (Android 10+). Record the model, OS version and screen size.
- Start with fresh in-session settings: right-handed (or the player's hand), sensitivity ×1.00, reduced motion off, larger targets off, assist off.
- Every committed roll appends one JSON line to `user://throw_trials.jsonl`. On desktop that is `~/.local/share/godot/app_userdata/Roguewood/` (Linux) or `%APPDATA%\Godot\app_userdata\Roguewood\` (Windows). On phones, pull the app data with the platform's developer tools. Lines record the input source, the gesture metrics (speed, screen angle, turn, spin, power), the launch, the hook in meters, the outcome, the settings and the viewport.

## Procedure (per tester, portrait, then repeat 3–5 in landscape)

1. Explain only: "hold the ball, circle to spin, flick up; tap the lane to move the ring."
2. Ask for a straight ball at the head pin. Count tries until one is straight (`curved=false`) and reaches the rack.
3. Ask for a ball that curves right, then one that curves left. Count tries until each direction succeeds (`hook_m` sign matches) and the tester names the direction correctly before the ball breaks.
4. Ten free throws. After each miss, ask "why did that happen?" and note the answer verbatim.
5. Repeat steps 2–3 with assist controls on, then with sensitivity at ×0.75 and ×1.5.
6. Note any accidental cancels (status shows "No throw (…)") and any throw the tester didn't intend.

## Record

| Date | Tester | Device / OS / screen | Orientation | Straight tries | Curve-right tries | Curve-left tries | Accidental cancels | Unintended throws | Miss explanations | Log file hash |
|---|---|---|---|---|---|---|---|---|---|---|
| — | — | — | — | NOT RUN | NOT RUN | NOT RUN | — | — | — | — |

Pass: all testers meet tries ≤3 (straight) and ≤10 (each curve), there are no unintended throws, and nobody blames randomness. Attach the JSONL logs outside the repository (they are evidence, not source) and record their SHA-256 here. Tune gesture thresholds (ADR 003) only with this evidence.
