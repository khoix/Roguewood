# ADR 009 — seeded campaign and optional continuation

E14, 2026-10-27. Implementation decision; target numbers are provisional.

The League selector offers the existing two-Division slice and an eight-Division
House Campaign. The attempt number is its seed, so Restart Session reproduces
seed 1 and New Attempt advances the seed. No player-performance input reaches the
generator. The result shows the seed. Custom seed entry and difficulty selection
remain later scope.

The profile in `content/campaign/profile.json` is an explicitly provisional
integration fixture. Seven distinct encounter IDs use the two implemented rules,
Dead Straight and Clean Sweep; the authored championship policy brings back one
encounter already met. New names do not count as new mechanics, final rival art,
or completed production catalogue entries. E17/E18/E21 retain that work. Targets
50–280 are deliberately permissive functional values; they do not establish a
balanced 30–45 minute run or distinct viable endgame builds. E24 replaces them
using measured build performance.

A boss explicitly lists compatible lanes; zero legal choices fails generation.
The current fixtures select House oil or Dry backend. Dry changes backend contact
friction from 0.2 to 0.3, preserving the oil and pin-deck zones. One condition is
applied per match. The HUD identifies it; before purchases, the shop shows the
next lane, boss rule, boss target and boss lane. Rival reactions are hidden in
shops/results so they cannot cover those decisions.

Generator schema 2 records the exact generated schedule, seed, profile digest and
RNG states. Named streams separate bosses, lanes, shops, rewards and effects.
Boss/lane streams construct schedules; their continuation is validated by replay.
The shop's existing engine PRNG is seeded from the named shop stream and its
advanced state remains in the existing atomic Shop save. Deck RNG remains its
own saved stream. Rewards and effects are deterministic in this content; their
reserved streams are saved but are not spuriously advanced. Physics/animation do
not consume any content RNG. This does not promise cross-platform rigid-body
replay.

LeagueRun carries the schedule alongside progression. Attempt schema 2 can hold
this additive field; old slice/lab snapshots remain byte-shape compatible.
Campaign restoration validates the profile, schedule, seed and position before
using the saved specs. A changed campaign profile refuses that attempt with a
visible save notice rather than changing targets under the player.

After Division 8, the result offers New Attempt, Clubhouse or Continue Endless.
The result itself can be resumed after restarting the process. Continue adds
exactly one Division, pays the preceding match once, opens a shop with the next
rules visible, and retains the current inventory, money and deck. New endless
targets are fixed increments of +10/+20/+30 from the last boss, independent of
performance. Losing ends the attempt. Generator v2 has an explicit 256-Division
recovery bound; at that bound the continuation button is absent. These are
progression foundations, not E23's complete difficulty/mastery/endless feature set.

Validation includes 200-seed constraint and corruption checks, real Shop stream
isolation, saved campaign restoration, and J09 in three actual engine processes:
12 matches and a shop save; resume and championship win; resume the choice,
continue to Division 9, then lose through actual gutter throws. All shots and
navigation use native input. The synthetic model probe remains supplementary.
