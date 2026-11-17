# M24 labor feasibility and frozen experiment design

Prepared before M24 longitudinal outcomes, from M23 `790327546b1c5637940afa11a18e91e4df512dbf`.
This is a capacity/authorization witness, not a prediction of aggregate recovery.

## Unchanged real economy

Use the exact fifteen M23 identities, four managing owners and eleven employee
relationships, four firms and their installed slots (farm3/mill3/bakery3/brewery2),
goods/recipes/targets, prices wheat2/flour5/bread6/ale4, finite visitor budget,
household utility, grain clearing and initial zero commodities. Household90 +
firms480 + visitors8622 = **9192 coins**. Wage remains **10** for every completed
one-hour shift. No new coin, equipment, good, worker or subsidy is endowed.
M23's independently checked full-production witness remains21 wheat,15 flour,
21 bread,12 ale with eleven shifts, conditional cash surpluses12/15/21/16.

The M24-only homogeneous-labor authority ignores occupational qualification gates
for ordinary nonowner residents; it does not change their historical `skills`
arrays or create experience/levels. Actual affiliation, active contract, one labor
unit/day, physical site/time, inputs, assets and payroll still bind. Owners remain
management-only. Old scenarios retain their exact qualification rules.

## Employer objective and ties

Reuse M23's inventory-target conditional continuation. Incremental projected cash
contribution is output at the firm's own posted price minus missing whole input
lots at genuinely inspected prices minus the actual wage. Require **strictly
positive** contribution, owned cash for planned inputs/payroll, actual capacity
and affiliated/available workers. Never schedule a shift just to share work.
The19-cap third farm shift still has five wheat×2−10=0 and is declined; the16-cap
last two wheat would lose6. Matching cannot manufacture profitable work there.

Rank available homogeneous candidates by financial cost first; equal wage10/time/
output candidates are financially identical. `legacy_sorted` breaks equal-cost
ties by ID; `neutral_rotate` rotates each sorted equal-cost group left by
`day % group_size`. Availability/cost preference precedes rotation. A pure fixture
tests strict preference irrespective of tie. This is employer indifference, not
altruism or a worker-specific productivity preference.

Post only a genuine unfilled installed position. At the physical meeting, the
owner knows own current cash/output/input stock, own existing/reserved headcount,
own actual sales/production, own installed slots and last inspected input terms.
For posting only, predict carry after the remaining selling day by subtracting
own previous-day unit sales (initially the fixed output target) from currently
owned output, floored at zero. Apply the **same** target/positive-contribution
whole-shift budget to that carry with virtual wage10 workers up to installed slots
and the full fixed farm cap. Current cash must fund the entire projected plan;
future customer receipts are not added to that budget. A missing position exists
only if projected profitable shifts exceed active staff plus reserved arrivals.
No future true grain, other firms' balances or private consumer data enter it.
The zero-brew-request control never advertises brewery work it will not procure.
Forecasts remain conditional and fallible; postings do not reserve stock/payroll.

Offer fixed terms: wage10, one due shift/day, cycle1, duration30 days from actual
start, no experience requirement. A notice posted on day d is available only at
that meeting and must start at d+1; unaccepted/offered work expires at the next
boundary. Cancellation or changed economic/funding/capacity conditions cancel
pending entry without terminating the old job. Filled/expired/withdrawn notices
are explicitly closed. Each owner evaluates applicants only for its own notices;
equal financial applicants use the same day rotation, without private income data.

## Worker knowledge and financial choice

Use only the worker's own native due/paid/missed receipts over the last **three
days including today**, own current affiliation, and public notices actually
inspected at the bakery. All shifts have ended by the meeting; an own due shift
without a wage receipt is observably missed, not a guaranteed future income.
Employed current paid-opportunity estimate is `(paid+1)/(due+2)` over that window;
unemployed status quo is0. Unfamiliar valid notices have conservative prior1/2.
Expected income is that probability×10; supported switching cash cost is0.
Compare exact integer ratios. Stay on exact ties; prefer strictly greater expected
paid income. Search after an observed own miss or when unemployed; choose the
highest-valued observed offer, then stable posting ID on equal alternatives.
No wage underbidding or imagined vacancy influences a decision. The prior is an
assumption, not an employer promise or information about tomorrow's true sales.

An incumbent may apply without resigning. Only acceptance of an observed valid
offer authorizes a contingent next-day resignation/entry. Conflicting offers,
other applicants, same-job transfers, absent actors and changed terms reject.
The old affiliation remains active today; today's wages/dues/breaches remain in
history. At the boundary, prevalidate the entire transition, end the old relation
before starting the new, and route next morning from actual authorized employment.
Invalid/expired/canceled offers leave the old relation intact; never a partial
switch, duplicate affiliation or second same-day labor unit. Native wage/goods
commands remain the only economic mutations.

## Physical meeting and boundary witness

Matching alone adds **15:55–16:00** board activity on bakery[8,3]. Existing workers/
owners departing workplaces15:30 arrive by15:50 (farm four tiles, other sites
zero/two). An unemployed person may leave home15:00, reaching the bakery by15:45
even from the farthest existing home; no teleport or missing morning shift is
required. Public notices, applications, owner offers and personal acceptance are
witnessed there within one five-minute board appointment. Missing/busy actors
cannot inspect or transact. The global historical board is not a source of new
M24 knowledge. Stored observations are copies with native provenance IDs.

Board activity ends16:00 before bread, then original16:15 ale,18:30 home meals
and19:00 contract closure/realized distributions remain unchanged. Midnight entry
occurs only after24:00 and closure. Boundary records use the just-closed day's
24:00 instant and explicit effective-next-day terms, followed by the new day
00:00; no backward clock stamps. Oren's existing home[2,4]→farm[6,1] takes35min
from08:00, reaching before09:00. Gale's home[1,3]→brewery[8,5] takes45min,
before13:00. A different job does not reset prior daily labor or erase a breach.

## Deliberate vacancy witness and frozen comparisons

The separate vacancy fixture changes **only Gale's initial contract to inactive,
ended at day1 before work**; retain the former record, person, funds, zero goods,
all real assets and slots. Start with ten active affiliates rather than eleven,
same9192 coins. Farm has two active workers and one installed vacant position.
At cap21 the missing seven-grain shift has positive conditional margin4 and can
be funded with actual farm money. Fewer real farm workers can constrain grain
and leave a brewery incumbent without paid work. That incumbent can rationally
prefer a real observed vacancy under the declared1/2 prior. Two applicants may
compete; employer tie rotation, not a named-worker rescue, decides. The fixture
tests cross-industry acceptance, no immediate move, preserved old closure, one
next-day affiliation, actual commute and a genuine completed ten-coin shift.
The matched no-vacancy control restores Gale's original active contract with
identical money/commodities/assets. No vacancy means no extra hire, even if an
actor demands one. Results are not forced after defining these conditions.

Freeze before main outcomes:

1. M23 legacy reference/tight/scarce/no_brew_request ×1/3/30, seed42, against all
   twelve existing exact M23 report/ledger pins; independent fresh audits.
2. M24 `shift_selection`, `neutral_rotate`, same four conditions ×1/3/30, seed42,
   **two fresh processes each**. A small `legacy_sorted` comparison checks that
   removing rotation retains M23's economic movements; no resource retuning.
3. M24 `matching`, same neutral rule/conditions/horizons/seed, **two processes
   each**. With initially full staffing there may be no legitimate vacancies or
   turnover; report that outcome rather than fabricating applications/jobs.
4. Vacancy and no-vacancy three-day fixtures, two independent processes each;
   targeted competing/affiliated applicants, cancellation/expiry, unaccepted or
   forged/unobserved offers, absent/busy actors, owner authorization, conflicting
   offers, zero marginal vacancy, different own histories and duplicate labor.

Independent event reconstruction must check9192 after each transfer, exact recipes/
cargo/travel/quotes/consumer budgets, fixed10 pay, staffing/affiliation/contract
boundaries, receipt provenance and actual decisions. Deliberate rehashed forgeries
must fail. Preserve the169 M0–M22 pins, all M23 controls, original C/D audits and
M22 smoke. Measure isolated run/command/RSS/event/tick/appointment costs; use small
checks while editing and complete final acceptance once. No dynamic wages,
skill progression, welfare guarantee, new sector or M25 work.
