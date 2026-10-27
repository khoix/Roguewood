# E13 vertical-slice play session

Status: **BLOCKED — NOT RUN.** No phone, iOS toolchain, Android SDK or mobile build exists in the E13 Linux session (platform exports are E26). Nobody played the slice by hand on any device. What exists instead is the native J06 journey (real input, deterministic assist throws) and the seeded strategy simulation (ADR 008). Neither measures feel, comprehension, fun or duration. This page is the protocol and the defect list to carry into the session.

## What the session decides

1. **§13 stage-3 gate:** "at least three distinct viable builds; completed 10–15 minute slice." The simulation shows the builds exist at a modelled accuracy; humans must show they find and play them, and how long a slice takes.
2. **ADR 004 equipment model:** keep the draw/retain/cycle deck, or switch to direct selection (Options → Equipment). Ask which one gave useful decisions and which felt like fishing.
3. **Rival rules:** do players read Dead Straight and Clean Sweep before shopping, and adapt?
4. **Score comprehension:** can players explain a frame's score from the log (conditions, per-count lines, Echo retriggers, Charm order)?

## Setup

- A device build of the branch under test (primary iPhone 13 Pro class, iOS 16+; secondary Android 10+), portrait first. Default content (`slice`); fresh save directory and Career.
- Default settings; tell the tester only "hold the ball, circle to spin, flick up; tap the lane to move the ring", and that the shop is between matches.
- Keep `user://throw_trials.jsonl` and the save directory (`attempt.json`, `career.json`) from each tester.

## Procedure (per tester)

1. Play one full attempt without help. Time it from Enter League to the result screen.
2. After each match, ask what they bought and why; after each boss, what the rule did to them.
3. Ask them to explain one scored frame from its log.
4. Second attempt: ask them to aim for a different build (strikes, Echo/Ruby, Gold/Grower, Anchor/Lone Survivor). Note whether they can.
5. Repeat one attempt with Options → Equipment: direct. Ask which model they prefer and why.
6. Quit mid-match (backgrounding), relaunch, continue. Note anything that changed.

## Record

| Date | Tester | Device / OS | Attempt | Duration | Result (match reached) | Build attempted | Explained a frame? | Read the boss rule before shopping? | Model preference | Notes |
|---|---|---|---|---|---|---|---|---|---|---|
| — | — | — | — | NOT RUN | NOT RUN | — | — | — | — | — |

## Outstanding defects and gaps (known at E13)

| # | Area | Description | Owner |
|---|---|---|---|
| 1 | Shop | The Tactical and Workshop slots are always empty in the slice ("Nothing available"): the slice has no consumables or modifications. | E17/E18 content |
| 2 | Shop | No control swaps pins between existing rack positions; a pin is placed when bought. `RunInventory.swap_pins` exists. | E16/E25 UX |
| 3 | Shop | Charm reordering is one-slot-left buttons; there is no drag reorder or live score preview of the order. | E25 UX |
| 4 | Art | Batch E13-S01 has no card art, icons, VFX or audio; pins differ only by a developmental finish and colour, not shape markings. | E19/E20 |
| 5 | Rival | The Surveyor has no original portrait or animation; the Custodian atlas is the only rival art. | E21 |
| 6 | Balance | Division 2 targets (1100/1600/2400), prices and item numbers come from a synthetic simulation, not human play. Rival unlocks dilute the Charm pool and slightly lower win rates. | E24 |
| 7 | Feel | Item physics (Hook ×1.6 spin response, Hammer ×1.35 mass, Anchor ×1.6 mass, Rubber bounce 0.45) are untested by hand. | E05/E26 device trials |
| 8 | Duration | The 10–15 minute target is unmeasured. | this session |
| 9 | Layout | Long condition texts wrap inside shop offers; long HUD lines ("The Surveyor · D1/2 · Boss 3/3 · …") are tight at narrow portrait widths. Check readability on a phone. | E25/E26 |
