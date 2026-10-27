extends RefCounted
## Provisional match economy (design §10/§15, ADR 005). Pure functions over whole
## dollars; every number here is a simulation input, not a tuned value.
const STARTING_MONEY := 6
const MATCH_PAYOUT := 3
const UNUSED_FRAME_BONUS := 1
const INTEREST_STEP := 5 # $1 per $5 held…
const INTEREST_CAP := 3 # …up to $3
const REROLL_BASE := 2 # first reroll in a shop visit
const REROLL_STEP := 1 # each further reroll in the same visit
const REMOVAL_PRICE := 3
const FRAMES_PER_MATCH := 2

## Interest is paid on the balance held when the match ends, before its payout.
static func interest(balance: int) -> int:
	return mini(floori(maxi(balance, 0) / float(INTEREST_STEP)), INTEREST_CAP)

static func match_payout(frames_used: int) -> int:
	return MATCH_PAYOUT + UNUSED_FRAME_BONUS * clampi(FRAMES_PER_MATCH - frames_used, 0, FRAMES_PER_MATCH)

static func reroll_cost(rerolls_this_visit: int) -> int:
	return REROLL_BASE + REROLL_STEP * rerolls_this_visit

## Half the price actually paid, rounded down. Items that cost nothing (starting kit,
## rewards) sell for the catalogue's explicit base sale value instead. Because a sale
## never returns more than was paid, buying and selling can never make money.
static func sale_value(paid: int, catalogue_resale: int) -> int:
	if paid <= 0:
		return maxi(catalogue_resale, 0)
	return floori(paid / 2.0)
