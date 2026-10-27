# ADR 006 — E09 single Division loop and rival

Status: accepted for E09 on 2026-10-27, pending the owner's review. **Targets are provisional** test values, not balance; E14/E24 own progression and tuning. The Division and rival are lab fixtures (`content/fixtures/lab_division.json`, plus `boss_rule.lab_clean_sweep` in the lab catalogue). Final rival art, animation and lane treatment are E21.

## The Division (`src/rules/division_run.gd`)

- **Three matches:** opener 300, feature 500, and a boss of 800 against The Custodian. Each match is a fixed posted target within the two-frame budget (§4, §18). Targets never move during play: a unit test and J06 check this.
- **Victory and failure:**
  - A match is **won** as soon as its banked total reaches the target. The frame that crosses it resolves fully, then the match ends, and the unused frame pays its $1 bonus (§4, ADR 005).
  - A match is **lost** when the budget runs out first.
  - Losing any match ends the attempt. Winning the boss wins the Division.
- **Between matches:** a won opener or feature leads to the settlement and the Pro Shop, then the next match. The boss has no shop afterwards; the result screen follows.
- **Spec validation** (`validate_spec`):
  - opener, feature and boss, in that order, with rising targets;
  - a known rival whose rule is a catalogue `boss_rule`, on the boss match only;
  - a positive frame budget.
- **State** round-trips through JSON (match index, score, frames, results, outcome) for E10.

## Rival rule (`src/rules/rival_rules.gd`)

- **Clean Sweep** (`boss_rule.lab_clean_sweep`): only strikes and spares bank points; an open frame banks 0.
  - The rule acts on **what the match banks**. The FrameRules calculation stays as resolved and readable.
  - The score log gains one ✕ step that names the rule and the swept points, e.g. "Clean Sweep: an open frame banks nothing (70 → 0)".
  - Item income is money, not points, so payouts are unaffected.
- **Rule vocabulary:** closed and keyed by catalogue id; unknown rules are refused. Clean Sweep was chosen because it changes decisions (clear the rack rather than chase Value) without new physics, and its effect is exactly testable. The other §18 rivals (Slick, Iron Mae, The Surveyor) need physics or input rule hooks and are E17/E18 content.

## Previews (§18 step 1)

The boss, its rule, its posted target and its first-clear reward are visible **before any preparation**:
- In the match bar from the first frame: an inspectable "Boss: The Custodian ⓘ" badge.
- In every shop: "Boss later…", or for the boss itself "Next: Boss — target 800" with the rule and reward.

During the boss match the badge becomes "Rule: Clean Sweep ⓘ".

## Rival presentation

- **Introduction:** before the boss match, a modal introduction shows the portrait, name, rule, target, reward and an entrance line.
  - It is skippable at once (Begin) and advances on its own after 6 s.
  - Repeat encounters show a short version that advances after 2 s.
  - Reduced motion removes the fade.
- **Reactions** (`rival_reactions.gd`): event-driven, during the boss match only.
  - Events and responses: entrance; a strike gets "impressed"; a gutter or open frame gets "confident"; reaching 75% of the target gets "threatened"; a win or loss gets "defeated" or "victorious".
  - Precedence is result > tension > play, with a 3 s cooldown. A burst of events shows one reaction, and a higher-precedence event interrupts.
  - The bubble ignores all input. It sits below the status line, clear of the ball and the rack, and hides after 2.5 s. J06 throws while it is on screen.
- **Portrait:** developmental (a coloured disc with initials and a mood mouth). Final portraits and animation are E21.

## Results, retry and the Career record

- **Result screen:** the per-match scores against their targets.
  - On a loss: the unmet score and the rule in force.
  - On a win: the first-clear reward, banked immediately.
  - Buttons: Retry Division (after a loss) or New Attempt (after a win), and Clubhouse.
- **Attempts:** attempt *n* uses seed *n*. Restart Session always begins attempt 1, so J01's deterministic reset holds. Retry and New Attempt begin the next attempt.
- **Career record:** first clears, unlocked gates and rivals met. It lives in the shell, so it outlives retries, restarts and returning to the Clubhouse.
  - It is **in memory only**; E10/E15 make it durable.
  - The Custodian's first clear unlocks `gate.lab_rival`, which lets the E08 shop offer Lab Lead pins in later attempts. J06 checks that this survives a later loss.

## Practice

Options → "Practice (no targets)" plays target-free two-frame matches with shops, with no rival and no end. It applies to an attempt that has not thrown yet.

J02–J05 switch it on because they test throwing, scoring, the deck and the shop rather than targets. The default game is the Division, and J06 covers it.

## Open questions

- **Target curve:** 300/500/800 makes a House-ball strike enough for the opener and feature. Real targets depend on the catalogue and on E24's measured score distribution.
- **Payout after the boss:** E09 pays nothing after the boss because the attempt ends. E14's eight-Division run needs a Division-clear reward and a shop before the next Division.
- **Retry seed:** a retry uses the next seed, so its shops and deck differ. A "same seed" retry option may suit challenge modes (E23).
- **Intro auto-advance timing (6 s / 2 s):** this needs the E21 animation and a human check of reading time.
