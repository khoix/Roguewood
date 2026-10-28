# ADR 010 — Career persistence and the unlock graph

E15, 2026-10-27. Implementation decision. Mastery thresholds, reward texts and
the counter tags are provisional; item assignments to the championship and
mastery gates belong to E17.

## Context

Design §16 asks for a Career kept apart from attempts, three unlock paths (first
boss victories, League championships, mastery objectives), immediate banking,
pool snapshots, a validated prerequisite graph and a practice policy. It also
forbids permanent universal score or cash boosts. E10 already stored a schema 1
Career (`first_clears`, `unlocked`, `intros_seen`) beside the attempt, and the
shop already filtered locked items with an attempt-local copy of `unlocked`.

## Decision

**Registry.** `content/career/unlocks.json` (schema 1) declares every gate with a
stable ID, a kind (boss, championship or mastery) and a name. It also lists the
Leagues, each with its content set, access prerequisites and championship award,
the mastery objectives, and the counter tags for each boss rule.
- Boss gates are awarded by the League specs' rivals (`first_clear.unlocks`).
- Catalogue items name the gates they wait for (`unlock.prerequisites`).
- The lab fixtures have their own registry (`content/fixtures/lab_unlocks.json`).

**Graph validation** (`src/career/unlock_graph.gd`, built by
`ContentSet.career_graph` and run by `qa.py content` and the shell):
- IDs are unique and prefixed. Every gate is declared once, is awarded by at
  least one source of its own kind, and is the kind of gate its items expect.
- Any loop in the requirement graph is refused. That covers a League that needs
  its own title, an objective that needs its own gate, and longer chains.
- A fixpoint from a fresh Career must reach every League, objective and locked
  item. A pin-materials objective counts only pins that are reachable without
  its own reward, so no item is ever needed to unlock itself.
- Each initially open League must offer a counter to every boss rule from the
  start (by tag, in the pool or the kit), never only behind that rival.
- An availability report counts initial and locked definitions per category,
  for the §16 targets (12/24 balls, 16/32 pins, 60/100 Charms initially).

**Career schema 2** (`src/persistence/career_profile.gd`; v1 migrates by adding
keys and attributing held gates to first clears):
- `awards`: where each gate came from.
- `attempts`: a uid counter, so every attempt has a unique Career uid. Attempt
  numbers repeat after Restart Session; uids do not.
- `championships`: wins per League, with the first and last attempt.
- `mastery`: completed objectives.
- `totals` and `tally`: Career and current-attempt counts.
- `records` per League: attempts, bests and wins, with practice kept apart.
- `items`: the collection history. Owned means Discovered; owned in a League win
  means Mastered. Collection states are Locked, Available, Discovered and
  Mastered.

**Banking.** Every award is written to `career.json` the moment it is earned and
before the attempt checkpoint that records the step. Every update is idempotent:
- a gate is held once;
- a frame counts once per uid (`tally.frame` marks the last frame counted);
- a title or an item's attempt counts once per uid.

So a crash between the two writes, or a reload, can neither repeat an award nor
lose one. Attempt snapshots record `career_attempt` additively. A snapshot from
before E15 gets a new uid when it resumes.

**Pool snapshot.** Each attempt copies the Career's gates into its shop when it
begins, and the copy is saved with the attempt. Unlocks therefore join the pool
from the next attempt, and the result screen says so: "Unlocked: Encore joins
the shop pool from your next attempt."

**Championships.** The first win of a League awards its championship gates.
Later wins add to the record (wins, Mastered items) without repeating an unlock.
Winning Endless Divisions later in the same attempt does not count the title
again.

**Mastery.** There are three provisional objectives:
- Spare Hand: 10 spares across the Career.
- True Curve: three curved strikes in one attempt.
- Mixed Rack: three pin materials knocked down in one attempt.

Cumulative and single-attempt goals are mixed, so a losing player still makes
progress. Up to three open goals and their progress are shown on the menu and on
the result screen. Their gates award trophies only for now; E17 may lock catalogue
items behind them, and the graph checks that those items stay reachable.

**Practice policy.** Practice attempts record discoveries and practice records
(`practice_best_frame`, `practice_attempts`), but never first clears, titles,
mastery progress or unlocks. The policy is stated on the Practice toggle and in
the match bar before the first throw. The campaign's seed equals its attempt
number and Restart Session repeats seed 1. Because every reward is one-time by
ID, a known seed cannot be farmed; custom seed entry does not exist yet (ADR 009),
and when it is added it should follow the practice policy.

**League access.** The menu checks `UnlockGraph.league_access` and disables a
League whose access gates are not held. Both current Leagues are open from the
start, so this changes nothing yet; E22's advanced Leagues will use it.

**No vertical progression.** The Career never feeds score, payout, interest or
starting money. A Career is only ever read for gates (the shop pool) and for
display.

## Consequences

- E16 builds the Clubhouse on `records`, `championships`, `items` with
  `collection_state`, and `goals`.
- E17 assigns items to the championship and mastery gates and authors further
  objectives; `qa.py content` refuses any graph that breaks the rules above.
- E22 adds the Royal, Spectral and Foundry Leagues with access gates on the
  opening Leagues' championships.
- E23 may add difficulty medals as further records.
- A gate that a newer catalogue drops stays in the Career and is reported on the
  menu, never silently deleted.

## Validation

- `career_test`: graph refusals (each rule above), the shipped graphs, awards
  and provenance, idempotence, mastery scopes, championships, practice, pool
  snapshots, the v1 → v2 migration and the golden v2 Career. Mutation checks
  removing the frame mark, title idempotence, the practice guards, the loop
  check, the self-unlock feasibility check and the counter check are each
  caught.
- J10: three real processes (see DEVELOPMENT.md).
- J09 now asserts that the campaign title is banked once across restarts and
  Endless.
