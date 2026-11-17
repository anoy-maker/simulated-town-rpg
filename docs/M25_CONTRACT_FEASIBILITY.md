# M25 contract semantics and frozen experiments

Predeclared from M24 `9e9fb8d3e1af1480aacb6fdc541472842299a7ca`, before M25
longitudinal outcomes. Scenario: `settlement_binding_contracts`. No economic
viability, full employment, or universal food target is imposed.

## Initial conditions and binding term

Main runs retain all fifteen M23/M24 residents, four managing owners, eleven
employee relationships, equipment, zero commodities, household cash6, firm
cash120, and visitor cash8622: **9192 coins**. Prices remain wheat2/flour5/bread6/
ale4; targets21/15/21/12 and all recipes/caps/market/shopping rules are unchanged.
Ordinary employees supply homogeneous labor; historical skills remain intact.

Every initial term covers calendar days1–3: inclusive start1, exclusive end4.
Every newly accepted term lasts exactly three days at **10 coins per attended
due day**, cycle1, one eligible hour/day. Farm09–10, mill11–12, brewery13–14,
bakery14–15. Owners only manage. Exclusivity lasts for the whole term; no blind
resignation, unilateral wage/term change, second employer, or early offer start.

At each industry start, actual on-site idle employees enter one-hour production
or standby activities. Verified continuous on-site attendance satisfies duty
regardless of assignment, inputs, sales, or employer solvency. Native activities
block departure/overlap during the hour. At the exact ending clock event, before
productive completion, verify all employees together and create one unique
ten-coin obligation per attended worker/day/firm. An absent worker receives an
evidenced nonattendance breach and no earned guarantee. Standby creates no goods
and no productive-shift event. An employer's failure to assign is not a worker
breach. Each attendance/due/payment/production/closure has receipt provenance.

## Real payments, arrears and the native production adapter

At each firm's work-window end, tender outstanding earned wages using existing
native transfers, purpose `wage`. Order by due day, then worker ID, then unique
obligation ID. Partial payment is exactly the lesser of outstanding amount,
actual firm cash and recipient headroom. This deterministic alphabetical tie
priority is explicit; it is not an equity rule. Never hold the120 distribution
floor against an earned wage. Payment reduces that exact obligation once.

Example: an attended worker is owed10, firm cash6. Transfer6, leaving cash0 and
arrears4; the worker gains6, money stays9192, firm payable equals worker
receivable4. A later actual receipt can discharge4; expiration/default never
deletes it. Claims are retained independently of current employment. No interest,
loan, synthetic cash, punitive damages or general credit market is created.

All attendance claims are accrued before clearing at the window end. A productive
employee's guarantee is paid once, then the existing validated productive shift
references that payment rather than transferring another ten. Narrow default-
preserving labor hooks recognize an already paid guarantee for cash/headroom
validation and the payment receipt. All affiliation, site/hour, equipment,
input/output and one-labor-unit checks remain authoritative. If a full ten cannot
be tendered for that employee, no productive shift is synthesized: the attended
hour remains real, the unpaid guarantee persists, and a breach is recorded. This
is the native paid-production execution limit, not an unpaid production model.

At19:00, after actual household meal attempts, clear all older/current arrears
from real later receipts **before** owner distributions. No retroactive shopping
uses those late wages. Record a timely-payment breach whenever an earned claim
remains unpaid after the work-window tender, even if later cured. Distributions
are zero while any arrears remain. Report cash operating margin separately from
sales minus input spending minus **accrued** wages; inventory is not valued as
formal accounting profit. Cash payroll + remaining arrears = accrued wages.

## Current assignment versus new commitment

Current guarantees are committed costs. Reserve existing arrears and all today's
prospective guarantees once when calculating cash available for inputs. A current
worker is eligible for production only if the deterministic payroll ordering can
fully fund their ten from known cash; an underfunded firm may still use a fully
funded worker with owned inputs while others attend standby. No purchase may be
justified using invented future cash. Current assignment uses the unchanged
target-replenishment continuation with **incremental input costs only**; strictly
positive extra output receipts are required. Actual input/cash/stock/capacity
validation still binds. Wage10 is still paid, never changed to zero.

At cap19, after two harvests the third employee can add five wheat worth10 for
zero additional input cost, versus idling while still owed10. At cap16 the last
two wheat are worth4. Both may have positive within-term incremental value.
For a new employee, those same daily output increments must also cover ten per
day across a whole term. This distinction does not mandate a sale or output.

For renewal/hiring, enumerate future headcounts from retained next-day staff up
to installed capacity (at most3). Simulate three days using own current goods,
known prices/recipes/cap/targets and yesterday's own unit sales as daily demand
(target prior on day1). Do not count receipts from initial stock as incremental
benefit of hiring: compare each candidate against the retained-staff baseline.
Each day's projection reserves ten per employee, buys only missing whole lots,
produces toward target, then sells at most forecast demand and available stock.
Require nonnegative projected cash at every stage and strictly greater full-term
cash contribution after **all** new guaranteed wages and real input costs; fewer
new commitments win exact ties. Current arrears are deducted first.

At the15:55 board, an owner may project remaining own sales today using yesterday's
sales less today's already realized unit sales, bounded by currently owned stock
and the firm's remaining trading window. These are conditional forecast receipts,
not spendable cash. At midnight no future-today sales are added; revalidate using
actual balances. Future input supply/sales may disappoint. No other firm's cash,
customer budgets, tomorrow's actual grain or hidden future demand enters the view.
Retained staggered staff are conservatively budgeted for all three projected days;
their occupied slot is never advertised before actual expiry. No-brew-request
never justifies new brewery employment, but existing guarantees are still owed.

## Expiration, renewal, local knowledge and lawful release

The existing15:55 bakery meeting is the only notice/offer observation point.
Applications/offers/acceptance concern next-day terms and are allowed only for
unemployed workers or on the current term's final day. Current occupied slots
become advertised **post-expiry** positions only if the full-term forecast supports
them. Owners prefer their expiring incumbents on equal financial value, then the
M24 day rotation within equal groups; there are no individual productivity stats.

Workers use their own last three scheduled days and actual wage receipts. For
an observed offer from a personally known employer, expected daily cash is
`(own cash wages received for those days +10)/(observed due days +2)`; unfamiliar
offers use5. Compare exact ratios, then prefer current incumbent renewal on ties,
then stable notice ID. One application/offer acceptance per meeting. On expiry,
unemployment has expected income0; an unoffered former job is not guaranteed
income. Workers can explicitly refuse renewal; no policy forces acceptance.

Modes: `matching` permits all locally observed eligible positions;
`obligations_only` permits renewal only by that firm's currently expiring
incumbents, under the same profit/feasibility and worker acceptance rules. It
does not renew negative-surplus positions automatically or restart a firm after
all incumbents have left. This freezes matching, not employer financial judgment.

Initial terms expire after day3 closure at24:00, even when the run ends there.
The next boundary ends the old relationship before starting an accepted new one.
Run boundaries are processed once; day4 starts with real renewed/hired contracts,
correct morning routes and no second labor unit. Keep immutable term history,
record expiration/nonrenewal/renewal and retain every unpaid claim.

Narrow optional material-breach release authority is tested: a worker may choose
next-boundary exit using their own still-unpaid wage breach receipt, or an owner
may end that worker's term using verified nonattendance. No automatic release
policy is used in main runs. Breach release is independent of a new offer; an
early-released worker searches after becoming unemployed. Neither releases current
day obligations, creates money, or erases arrears. No intentional breach policy,
court, reputation, wage competition or enforcement engine is implemented.

## Frozen verification and experiments

1. Preserve169 historical pins,12 M23 controls, all24 M24 conditions/modes/horizons
   and their existing report/ledger pins. Fresh original12 C/D audits and M22 smoke.
2. M25 four conditions ×1/3/30 days ×matching/obligations_only ×seed42, **two fresh
   processes each**, full report/event equality and independent economic replay.
3. Focused legal/attendance/cash tests named in issue35, including stocked standby,
   wages exactly once, absent employee vs unassigned employee, partial/oldest
   arrears, late receipts/shopping, liability survival, protected reserve, invalid
   payout/terms/notice, exclusivity, premature entry, lawful releases, voluntary
   renewal/refusal and next-day actual work. Rehashed forgeries must fail replay.
4. Separately labeled technical fixtures (not main endowments): `cash_short` /
   `cash_zero` endow bakery21 bread, bakery6/0 coins, Finn0 coins; all removed
   initial coins move to visitors, retaining9192. Actual retail receipts can pay
   wages at19:00. `insolvent` uses bakery0/Finn0 with zero goods. `no_show` changes
   only Dain's test morning destination to bakery, with actual travel. `staggered`
   starts first terms expiring after1/2/3 days by sorted employee index; all new
   terms are three days. Additional pure one-grain/one-coin fixtures test marginal
   use versus new commitment without changing longitudinal policies.

Measure run/command/report/audit time, RSS, events and appointment/tick tails.
Publish compact contract/day/worker/arrears evidence in `docs/M25_RESULTS.md`.
No parameter tuning after outcomes. Stop after M25 for review; no M26.
