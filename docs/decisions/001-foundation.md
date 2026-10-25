# ADR 001 — E01 foundation

Status: accepted for bootstrap, 2026-10-25. Revisit only with a concrete incompatibility or visual/performance failure.

## Engine and targets

Pin Godot **4.5.2 stable**, standard GDScript build, and matching export templates. This is an explicit stable baseline, not a claim that it is latest. Avoid C# and plugins until justified. Python 3.10+ standard library drives tooling; CI uses Ubuntu 24.04's Python 3.12.

Primary player target: native iOS 16+ on iPhone 13 Pro class hardware, touch-first portrait and landscape. Secondary player targets: Android 10+ / GLES3-capable phone and Windows 11 x86-64. Linux x86-64 is the development/CI reference. These are engineering targets, not verified device coverage. Native macOS distribution and browser distribution are deferred, not assumed.

Bootstrap renderer: Compatibility (GLES3), including mobile. It supports the simple 3D/2D architecture and simulator path without Vulkan assumptions. E11/E12 must demonstrate premium art, custom foil shaders, lighting/reflection strategy, and motion on actual targets. If the visual target requires Mobile renderer, record measured reason and migrate presets before mass art. Pixelation alone cannot pass visual gates.

The root project.godot contains only a title/startup fixture. E03 owns real menu/navigation, E04 owns the bowling scene. No final art is implied.

## Boundaries

- Input: normalize timestamped pointer samples; emit launch intent (position, direction, speed, signed spin). No scoring mutations from input. E05 owns gesture mapping.
- Simulation: consumes launch intent; emits immutable unique-pin/collision outcomes. Fixed physics tick; begin with constrained 3D and benchmark repeatability at E04. No promise of bit-identical cross-device rigid-body outcomes.
- Rules: plain data and ordered effects, without scene-tree/UI dependencies. E02 defines versioned schema, IDs and event contract; do not preimplement that milestone here.
- Presentation: observes resolved events and plays animation/audio without changing score or consuming gameplay RNG. Keep UI crisp over pixel-art world.
- Persistence: separate versioned Career and attempt snapshots, independent RNG streams, committed throw before animation, atomic transaction boundaries. E10 implements recovery and migrations; never serialize live scene nodes as the canonical save.

Directories reserved by responsibility: src/input, src/simulation, src/rules, src/presentation, src/persistence; content for data; tests for fixtures and behavior. Create as needed rather than placeholder services.

## Deck decision

E07 implements the documented hand/cycle proposal and compares direct selection. Neither is finalized by this ADR. Record decision and effect on shop contracts before catalogue expansion.

## Test/export decision

E01 supplies editor import, scene startup and Linux debug export smoke. E02 adds rules tests; E03 adds real-input E2E harness. Headless startup is NOT E2E gameplay or visual validation. Future unimplemented qa commands fail explicitly.

Linux debug export is the first reproducible packaging proof. iOS requires macOS/Xcode, matching templates, signing configuration, and physical-device testing. Android requires SDK/JDK/signing configuration. None is available/validated by this E01 Linux bootstrap. Credentials are never committed. E26 owns native installation/release certification; do not infer success from Linux smoke.

Sources checked 2026-10-25:
- https://godotengine.org/download/archive/4.5.2-stable/
- https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_ios.html
- https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html
