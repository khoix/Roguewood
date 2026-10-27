# ADR 007 — E10 attempt saves and recovery

Status: accepted for E10 on 2026-10-27, pending the owner's review. It follows design §12 ("commit a throw and save before animating it… save after shop transactions and frame resolution… save-version migration"), §15 (persist the deck order, piles and RNG; no reroll by reload) and §16 (Career stored apart from attempts; awards neither duplicated nor lost).

## Storage (`src/persistence/save_store.gd`)

- **Location:** one directory, `user://saves` by default. The shell takes `--save-dir=<path>`, and every journey gets a fresh directory from `tools/qa.py`. Platform locations and cloud saves are E26.
- **Files:** one per kind, `attempt.json` and `career.json`, each holding an envelope `{format: "roguewood", kind, schema_version, sequence, checksum, payload}`.
  - `payload` is the state as canonical JSON text (sorted keys, full float precision); `checksum` is its SHA-256.
  - A torn, truncated or edited file is therefore detected, never half-loaded.
- **Atomic write:**
  1. Write `<kind>.json.tmp`, flush it, then read it back and verify it.
  2. Copy the current good `<kind>.json` to `<kind>.json.bak`.
  3. Replace `<kind>.json` with the temporary file. If a platform refuses to rename over an existing file, the old file is removed and the rename retried; the backup covers that instant.
  - A crash at any step leaves the previous state or the new one, never a mixture.
  - A leftover `.tmp` is ignored and replaced by the next write.
- **Read and recovery:**
  - The store tries the main file, then the backup.
  - An unreadable main file is **quarantined** as `<kind>.json.corrupt` (kept for diagnosis, never silently deleted), and the shell shows why: "…could not be read (checksum mismatch); restored the previous checkpoint." When no copy is usable, the menu says so, offers only a new attempt, and leaves the Career untouched.
  - Parsing is quiet; a damaged file is an expected case, not an engine error.
- **Versions:**
  - Each kind has a schema version (both are 1).
  - A newer save is refused ("made by a newer version"), as is version 0.
  - Older versions run through a registry of one-step migrations. A gap in the chain is refused.
  - Golden v1 saves are frozen in `tests/fixtures/saves/v1` (made by `tools/make_save_fixture.gd`). `save_test` loads them and checks exact values, and every later schema version must keep doing so through its migrations.

## The attempt snapshot (`src/persistence/attempt_snapshot.gd`)

- **Contents:** one snapshot holds everything that decides what happens next:
  - the attempt number and seed;
  - content hashes of the catalogue and the Division spec;
  - the run inventory (wallet, ledger, rack, Charms, cards, modifications);
  - the shop (offers, rerolls this visit, unlocked pool, selection log, RNG state);
  - the equipment model (deck piles, cycle flag, RNG state; or the direct bag);
  - the Division run;
  - the lab's frame state (frame, roll, match, total, launch serial, the rack with full-precision pin positions, this frame's reports, played tactics and modifications, and the settlement);
  - a committed launch, a banked frame's log, or the attempt result, depending on the phase.
- **One write per committed step:** every save is the whole snapshot, so each step is a single transaction:

  | Step | Phase saved |
  |---|---|
  | New attempt, frame start (deck draw), roll two ready, match start | `aim` |
  | A cycle (the draw is spent) | `aim` |
  | A launch commits (cards spent): **before the roll animates** | `committed` |
  | A roll resolves | `roll_resolved` |
  | A frame is scored: total, item income and match result banked **before the explanation plays** | `frame_done` |
  | Shop opens (settlement paid); each purchase, sale, reroll or removal | `shop` |
  | The boss introduction | `intro` |
  | The attempt ends (after the Career award is saved) | `division_over` |
  | Backgrounding, focus loss or a close request | the current resting phase |

- **Not saved:**
  - Presentation: animation progress, the aim ring, cards armed but not thrown, an open choice sheet.
  - Settings (E25). On resume, the saved equipment model and practice mode override the session's settings, so a load never rebuilds the deck or resets the Division.

## Recovery rules (the lab's `_restore`)

- **`committed`:** the saved launch is committed again, unchanged, on the saved rack, with its cards already spent. The roll is **re-simulated, never rethrown**: no new launch id and no second card.
  - J07 checks that the resumed result equals a clean simulation of the same launch.
  - Re-simulation reproduces the original only on the same build and platform. **No cross-platform bit-identical physics is claimed** (ADR 002). After the roll resolves, its report is saved and never simulated again.
- **`roll_resolved`:** play continues to roll two on the saved standing pins (positions exact) or to scoring.
- **`frame_done`:** the banked frame's calculation is shown again (revealed at once), but nothing is re-banked. Total, money and the match result come only from the save.
- **`shop`:** the saved offers, prices, sold flags and reroll price are restored. Reloading neither repeats nor refunds a purchase or a reroll, and never regenerates offers.
- **`intro`** and **`division_over`:** shown again from the save.
- **Content checks:**
  - If the catalogue or Division spec changed since the save, the load reports it but continues, provided every item the save names still exists.
  - A save naming a removed item is refused with a notice; the file is kept.
  - Existing attempts keep their own shop pool (`unlocked` is saved with the shop). A new unlock appears from the next attempt, as §16 requires.

## Career (`src/persistence/career_profile.gd`)

- **Separate file:** `career.json`, schema 1: `first_clears` (rival → {attempt}), `unlocked` gates and `intros_seen`.
- **Awards:** `record_first_clear` is idempotent. The Career is written **before** the attempt snapshot records the victory, so:
  - a crash between the two leaves the award banked once;
  - a reload can neither repeat it nor lose it.
- **E15** extends this profile with the unlock graph, milestones and records.

## Shell

The Clubhouse menu offers **Continue Attempt n · match m** whenever a resumable (unfinished) attempt is saved, and focuses it.
- Enter League starts a new attempt and replaces the attempt save.
- Retry and New Attempt behave as in ADR 006.
- Notices explain fallbacks and unusable saves.

## Evidence and limits

- **`save_test` covers:**
  - atomic replace, backup, and leftover temporary files;
  - four corruption kinds (truncation, an edited payload, garbage, the wrong kind), quarantine and recovery, and both copies broken;
  - newer, zero and gapped versions, and a two-step migration;
  - snapshot round trips for both equipment models, with identical shop rerolls and deck draws after loading;
  - refusal of removed items and unknown phases;
  - changed-content warnings;
  - the golden v1 saves;
  - Career idempotence and separation.
- **J07** restarts the engine for real (ten processes sharing one save directory) before, during and after a throw, during score resolution, after a purchase, after a reroll, between rolls and after an unlock. It also covers backgrounding, a corrupt latest save with fallback, and no usable save.
- **Mutation checks** (checksum, backup, quarantine, newer-version refusal, Career idempotence) were each caught.
- **Not covered:**
  - Killing the process by OS signal mid-write. The temp-then-replace design covers it, but it is exercised only by simulated torn files.
  - Mobile backgrounding on real devices (E26).
  - Re-simulation across platforms (not claimed).
