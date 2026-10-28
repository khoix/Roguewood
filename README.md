# Roguewood

A mobile-first, single-player bowling roguelike. You spin and flick a ball down a surreal pixel-art lane and knock over a rack you have customised. Then ball effects, pin effects and collectible Charms turn a small bowling result into an enormous score.

The core promise: **build a scoring engine that changes how you want to bowl.** Sometimes a strike is best; sometimes leaving one valuable pin standing is better.

> **Status: in development.** The game is not released or feature-complete, and nothing has been tested on a physical phone yet. Per-milestone status, evidence and open gates are in [docs/AI-HANDOFF.md](docs/AI-HANDOFF.md).

## What is playable today

- **The throw:** hold the ball, drag to line up, circle to add spin, and flick to throw. The lane uses deterministic Jolt physics with curved rolls, a target ring and accuracy grades. Mouse, keyboard and an assist mode also work.
- **Scoring:** each frame scores as Value × Mult and plays back as a step-by-step calculation, so every effect explains itself.
- **A run:** the House League has two Divisions of opener, feature and boss matches against named rivals (The Surveyor and The Custodian). Between matches you visit a seeded Pro Shop for Charms, balls, pins and modifications, and draw equipment from a deck. A provisional eight-Division **House Campaign** with an endless mode is also available.
- **Saves:** the game saves at every committed step. You can resume mid-throw or mid-shop, and it recovers from corrupt saves.
- **Career and Clubhouse:** unlocks, first clears, titles, mastery goals, records and the collection binder carry over between attempts. Practice attempts grant no unlocks.
- **Content so far:** the first production batches of balls, pins, Charms, boss rules and a starting kit are playable, with final pixel art and effects arriving in batches. The full release targets 270 definitions (§15 of the [design plan](Roguewood-Game-Plan.md)), and the checkpoint keeps the current counts.

## Tech stack

- [Godot 4.5.2](https://godotengine.org/download/archive/4.5.2-stable/) (standard, not .NET), GDScript, Compatibility renderer, Jolt physics.
- Python 3.10+ for the QA tooling (standard library only).
- Targets: iOS 16+ (primary), Android 10+, Windows 11. Linux x86-64 is used for development and CI. See [ADR 001](docs/decisions/001-foundation.md).

## Getting started

1. Install the Godot **4.5.2 standard** editor and its matching export templates. `godot --version` should begin `4.5.2.stable.`
2. If the executable is not on `PATH` as `godot` or `godot4`, set `GODOT_BIN` to its path.
3. From the repository root:

```sh
python3 tools/qa.py doctor   # checks the engine, Python and project
python3 tools/qa.py import   # imports assets
```

4. Open `project.godot` in the editor and press **F5**, or run `"$GODOT_BIN" --path .` from the command line.

The menu is the Clubhouse. Choose a League and press **Enter**. **Options** holds handedness, sensitivity, reduced motion, larger targets, the assist controls and Practice mode.

Useful launch flags (after `--`): `--content=lab` loads the test fixtures, and `--content=campaign` starts the eight-Division campaign.

## Testing

Every check goes through one entry point, `tools/qa.py`:

| Command | What it checks |
|---|---|
| `unit` | Rules, scoring, economy, saves, Career, catalogue and batch validation |
| `content` | Catalogue, unlock graph and authored batches against their contracts |
| `integration` | Contract-level rule integration |
| `physics` | Fixture throws through real Jolt worlds; prints a repeatability digest |
| `smoke` / `export` | Boots the project; builds and starts a Linux debug export |
| `slice` | Seeded build-strategy simulation of the vertical slice |
| `e2e --journey <ID>` | Native journeys that drive the real game with touch, mouse and keyboard |

Add `--rendered` to an `e2e` run to save screenshots; on Linux, run it under `xvfb-run -a`. Logs and captures go to the git-ignored `artifacts/` folder and are never committed. CI (`.github/workflows/bootstrap.yml`) runs the full set on every push and pull request and uploads the captures as an artifact.

[docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) describes each journey, its fixtures and its captures.

## Repository layout

```
src/
  rules/          pure frame scoring, inventory, shop, Divisions and Leagues
  simulation/     lane, ball and pin physics
  input/          gesture capture and launch mapping
  persistence/    attempt saves and the Career profile
  career/         unlock graph
  clubhouse/      Clubhouse screens and model
  procedural/     seeded campaign generation
  content/        authored-batch validation
  contracts/      JSON schema and contract checks
  presentation/   throw lab, HUD, score panel, art and effects
  bootstrap/      application shell
content/          catalogue, Leagues, kits, unlock registry, schemas, fixtures
assets/           pixel art, effects and audio
tests/            unit suites and native E2E journeys
tools/            qa.py, capture and authoring scripts
docs/             plans, decisions, hand-offs, art briefs and playtests
```

## Documentation

- [Roguewood-Game-Plan.md](Roguewood-Game-Plan.md): the game design and build plan.
- [docs/EXECUTION-PLAN.md](docs/EXECUTION-PLAN.md): milestones E01–E29.
- [docs/AI-HANDOFF.md](docs/AI-HANDOFF.md): the current checkpoint, which is the source of truth for status.
- [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md): setup, commands and journeys.
- [docs/CONTRACTS.md](docs/CONTRACTS.md): data and rule contracts.
- [docs/decisions/](docs/decisions/): architecture decision records (ADR 001–010).
- [docs/art/](docs/art/): the art bible, briefs and asset ledger.
- [docs/handoffs/](docs/handoffs/): per-task implementation and verification records.
- [docs/playtests/](docs/playtests/): device-trial and playtest protocols.

## How development works

Two AI agents build Roguewood under the repository owner's direction:

- **Claude** handles content, rules, UI and release.
- **Codex** handles all art, effects and audio, plus League themes and platform packaging.

[AGENTS.md](AGENTS.md) holds the operating rules. Work ships in **waves**: each wave's commits are integrated on `claude/roguewood-build` and merged to `main` by pull request after CI passes. Codex delivers on `codex/roguewood-build`, and the coordinator integrates it. The owner's merge is the approval.

## License

No license has been published. All rights are reserved by the repository owner until one is added.
