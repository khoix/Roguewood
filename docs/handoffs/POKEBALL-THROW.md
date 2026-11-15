# Agent task handoff — POKEBALL-THROW

## Assignment

- Objective: archive the requested Pokémon GO throwing-physics reconstruction.
- Owner: Codex; no separate agent reviewer assigned.
- State: DONE (documentation, packaging and scoped verification).
- Branch: `docs/pokeball-throw-reconstruction`, based on main
  `4aefda6464fa9746ee8b5fa0a8f7c7043bbfc8b0`.
- Scope: `docs/pokeball-throw/` and this handoff. This is the owner's separate
  research-documentation request, not an execution-plan milestone or wave claim.
  The current request explicitly directs a new branch from main and a PR to main.
- Out of scope: changing Roguewood gameplay, integration branches or central
  milestone state; merging the PR.

## Changes and decisions

Preserved the 23 curated reconstruction files from the source archive, whose
SHA-256 is `1eb91fdc1cc1190fd2c8e89798319c4496f354da7c0e6b11c42ef5b4a724df99`.
Added repository-relative run/reproduction instructions, optional analysis
dependencies and local artifact ignores. `.gdignore` excludes the standalone
Unity example and research evidence from Godot resource import. The figures
are generated trajectory plots, not gameplay screenshots or rendered captures.
No game source, content flags, shared contracts or project settings changed.

## Validation evidence

Performed on the packaged files with Python 3.12 on Linux:

| Procedure | Outcome | Evidence |
|---|---|---|
| `python3 -m unittest -v test_physics.py` | PASS, 7 tests | `../pokeball-throw/evidence/validation.json` |
| `tools/verify_native_math.py` with original matching ARM64 library and method map | PASS, 12 comparisons; maximum absolute error 2.6417559e-6 | `../pokeball-throw/evidence/native-math-validation.json` |
| Parse all packaged Python files and JSON evidence | PASS | Packaging validation record |

Native verification uses mocked gravity/libm and covers only target-speed
arithmetic. Complete gesture-to-flight gameplay matching, held-ball positioning,
collisions, live configuration and the Unity engine port remain unvalidated.
No Roguewood E2E run is claimed: this change adds isolated reference files.

## Persistence and next step

The containing Git commit identifies this package; branch publication and PR
links are reported after remote verification. Integration status: unmerged.
No packaging work remains. A later implementation task can use the README and
reproduction guide; game integration and device validation need separate scope.
