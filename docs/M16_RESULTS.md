# M16 — Dynamic pricing and rational market competition

## Choices fixed before experiments

Four `settlement_pricing` stages use M15 A's exact twelve residents, firms, skills, assets, money (432 village + 8760 external), original contracts, nine daily six-coin shifts, recipes, initial stocks and full realized-earnings distributions above 120. Stage A is fixed 2/4/4; B activates bakery pricing; C mill/bakery; D all three. No new production/staffing/investment policy. Run 1/3-day preflights and 30 days at seed 42, twice. Recheck the historical 365-day M15 control; do not export annual event histories.

Daily ordering: close old obligations; advance/reset day and declare original minimum duties; farm/mill/bakery owners price in chain order using only completed prior-day sales and current public quotes; perform the original three industry shifts each with its prescribed four-new-input procurement; households buy their outstanding one-loaf food need; six individual visitor requests; local and external consumption; distributions; contract closure. Due-event declaration before pricing creates no work or payment. All input purchases still precede the relevant paid shift and actual constraints can fail it. Existing input stock is retained even if a preceding shift failed; prescribed procurement is not secretly optimized after failures.

A quote is per business/commodity, integer price 1..the existing 1e9 numeric bound, active status, explicit offered limit, version and effective/revised day. Public availability is the lesser of current real stock and that limit; posting cannot reserve/duplicate goods. Initial output quotes use 2/4/4 and a full-stock limit. Other existing commodities may also be posted by a real owner. One revision per business/item/day, including activation/quantity changes. Purchases bind current version/terms; stock may change independently and is checked at execution. Buyer-supplied prices never set execution price.

Buyers choose cheapest active affordable stocked quotes, rotating the sorted equal-price group by `(sum of Unicode code points in buyer ID + day) modulo group size`. They retry other offers/refresh changed versions after real failures; no seller receives assigned customers. Residents buy at most one outstanding daily bread including owned food. Visitors have finite funds, six daily desired loaves and a private six-coin bread ceiling. Neither their ceiling nor other buyers' finances enter seller observations. Business input requests may split across suppliers without exceeding their prescribed quantity or cash.

The pure rational policy evaluates current−1/current/current+1 within numeric limits. Sensitivity is one unit/coin. Day-one subjective demand prior is the firm's own planned output (12 wheat/12 flour/18 bread), not a census of actual customers. Later reference demand is own prior-day fulfilled quantities plus quantities of actual stockout requests reaching that seller. Fulfilled sales are a lower bound; there is no omniscient estimate of buyers who never submitted a request. Reference price is the previous posted price. Forecast demand is clamped to own stock plus prescribed planned output. Operating cash estimate is candidate price × forecast sales minus the same public-quote planned input bill and contractual/additional payroll for every candidate. This is a conditional one-period cash approximation, not a production/solvency optimizer or long-run optimal price. Ties prefer current, then lower. Fixed mode proposes no revision; personality mode is reserved and rejected.

No parameter or policy will be adjusted after inspecting outcomes. Independent tests may supply explicit belief tables solely to test objective selection (3/4/5 revenues 54/72/60 and cases with a different optimum). Controlled competition uses declared finite seller stock/customer cash; it does not add another operating firm to the longitudinal reference. Its separately selectable `pricing_competition_fixture` starts with Ada (buyer X) holding four coins, Bram (Y) six, Cora’s bakery holding 120 coins/one bread and Finn’s rival bakery zero coins/one bread. All other original holdings stay unchanged; the unused visitor account has zero. Combined fixture money is 430. No productive assets are added and no production/payroll/full-village meals are exercised. Native edge fixtures may explicitly vary stock/cash to test ties, stock races and funded input competition.

## Actual results and verification

### Stages A–D: actual 30-day outcomes, seed 42

All twelve preflight/30-day cases replay byte-identically across independent processes. All cases conserve **9192 combined coins** after every event, with nonnegative holdings and reconciled goods, assets, payroll, capital and distributions. No economic parameters or policies were changed after inspecting outcomes.

| Stage | Adaptive sellers | Resident meals / missed | Visitor loaves / unfilled requests | Wheat / flour / bread produced | Paid shifts | Minimum-contract breaches | Village / external coins |
|---|---|---:|---:|---:|---:|---:|---:|
| A | none | 360 / 0 | 180 / 0 | 360 / 360 / 540 | 270 | 0 | 1152 / 8040 |
| B | bakery | 257 / 103 | 12 / 168 | 360 / 360 / 528 | 268 | 2 | 498 / 8694 |
| C | mill, bakery | 210 / 150 | 12 / 168 | 360 / 328 / 222 | 209 | 41 | 498 / 8694 |
| D | farm, mill, bakery | 102 / 258 | 24 / 156 | 224 / 84 / 126 | 98 | 116 | 570 / 8622 |

| Stage | Wage coins | Owner distributions | Successful / rejected atomic purchases | Gross cash circulation | Price revisions: farm / mill / bakery |
|---|---:|---:|---:|---:|---:|
| A | 1620 | 540 | 720 / 0 | 6480 | 0 / 0 / 0 |
| B | 1608 | 742 | 449 / 0 | 6860 | 0 / 0 / 24 |
| C | 1254 | 407 | 376 / 0 | 5149 | 0 / 10 / 8 |
| D | 588 | 492 | 176 / 0 | 3084 | 15 / 13 / 17 |

**Zero rejected atomic purchases does not mean zero unmet demand.** Fresh synchronous policies exclude unaffordable, unstocked or reservation-ineligible quotes before submitting purchases. The resulting unfilled requests and failed consumption attempts remain recorded separately. Stock/quote races and forged requests produce real authoritative rejections in focused tests. The reported stockout-request signal is only actual failed requests reaching that seller; it is zero in these longitudinal runs. Sellers do not learn how many unsubmitted buyers lacked money or refused a private ceiling.

A reproduces M15’s actual final economic state, per-account cash flows, production/consumption, minimum contracts and circulation at matched horizons; the added quote/decision annotations intentionally give it a different ledger fingerprint. Every resident finishes day 30 with **66 coins and thirty meals**; each firm retains 120, with no stock. The historical M15 365-day payload and ledger fingerprint remain unchanged: 4380 resident meals, 2190 visitor loaves, 3285 shifts, 9192 village/zero visitor coins. No new adaptive annual run was needed to observe the failures already present by day 30.

### Forecast decisions and consequences

The first bakery decision compares prices **3/4/5** with estimated demand **18/18/17**, revenue **54/72/85**. Stage B’s unchanged planned input/payroll cost is 66, so estimated operating cash is **−12/6/19** and price **5** is chosen. Actual sales are eighteen at five, not the seventeen predicted. On day two it chooses six; on day three it chooses seven, forecasting seventeen sales but actually selling only twelve. All visitors refuse seven despite their ample funds. Their private six-coin ceiling never enters the seller observation.

At day four reference demand is twelve at price seven. Predicted demand at **6/7/8** is **13/12/11**, revenue **78/84/88**; eight therefore maximizes this declared belief even though actual sales fall to ten. Price choices pass the objective audit while realized demand differs. The policy is locally optimal under its own small, fallible forecast, not a long-run or omniscient optimum.

B’s bread prices range **5–11**, end at **10**, and fluctuate near 9/10 rather than stabilize. Cora eats all thirty days and finishes with **112 coins**; eleven others miss meals (Ada/Bram ten each, Kira eleven, the other eight nine each). The bakery closes with **259 unsold bread and eight flour**, despite 103 missed meals. Two late-worker shifts fail payroll while upstream production continues. Increased cash circulation/distributions do not establish improved food access.

C’s flour price peaks at **9**, ends **6**; bread peaks at **9**, ends **6**. Higher actual input bills reduce the bakery’s available payroll; fixed input procurement can still buy partial flour even when a following whole productive shift cannot be funded. The bakery makes only **37 shifts**, finishing at **40 coins/48 flour**. The mill finishes at **30 coins/132 flour/eleven wheat**; the farm holds 120 coins/21 wheat. Six resident meals/day continue near the end, but food access is uneven: Bram eats thirty times, Cora only five, Iona six and Kira three. This is continuing reduced activity, not universal viability.

D first raises wheat **3→8**, flour **5→9**, bread **5→9**. After sales collapse it lowers all three toward the one-coin floor; wheat/flour reach one on day 17 and bread on day 20. Lower posted prices cannot recreate working capital or flour. Last mill/bakery production is day **11**, last farm output sale day **12**, last bread sale day **14**, and last farm production day **19**. There are no resident meals on days **15–30**. No successful goods or money transaction occurs after day 19; quote/failed-attempt records continue. The farm spends its remaining operating capital producing unsold wheat until payroll fails, while the mill has already exhausted cash. Final farm/mill money is **zero/zero**, with **125/15 wheat** respectively; bakery cash is 120 but flour/bread are zero. Ada holds **261** and Cora **84** of the residents’ combined **450** coins. Their wealth cannot feed anyone without restored production, which M16 does not force.

The first reduced external demand is price-driven, not exhaustion of the external account. B/C leave **8694** visitor coins; D leaves **8622**. Later failures also depend on prescribed procurement, unadjusted employment/output commitments, production indivisibility and M15’s distribution rule. Its 120-coin floor constrains distributions, not ordinary productive spending; past losses can therefore exhaust business capital after earlier legitimate payouts. No owner recontribution or staffing repair policy is introduced. These staged comparisons identify interacting mechanisms for this fixed population/order/belief, not a general result that dynamic prices always worsen economies.

### Business accounting at day 30

| Stage / firm | Sales | Input spending | Payroll | Distributions | Final cash | Final commodity stock |
|---|---:|---:|---:|---:|---:|---|
| A farm | 720 | 0 | 540 | 180 | 120 | none |
| A mill | 1440 | 720 | 540 | 180 | 120 | none |
| A bakery | 2160 | 1440 | 540 | 180 | 120 | none |
| B farm | 720 | 0 | 540 | 180 | 120 | none |
| B mill | 1440 | 720 | 540 | 180 | 120 | none |
| B bakery | 2350 | 1440 | 528 | 382 | 120 | 259 bread, 8 flour |
| C farm | 678 | 0 | 540 | 138 | 120 | 21 wheat |
| C mill | 1319 | 678 | 492 | 239 | 30 | 11 wheat, 132 flour |
| C bakery | 1491 | 1319 | 222 | 30 | 40 | 48 flour |
| D farm | 570 | 0 | 336 | 354 | 0 | 125 wheat |
| D mill | 594 | 570 | 126 | 18 | 0 | 15 wheat |
| D bakery | 840 | 594 | 126 | 120 | 120 | none |

All final residents’ balances, meals, wages, ownership income and expenditure are in [M16_ACCOUNTS.csv](M16_ACCOUNTS.csv). [M16_BUSINESS_DAYS.csv](M16_BUSINESS_DAYS.csv) contains **360** daily business rows: exact posted prices, all evaluated candidate demand/revenue/cash estimates, actual sales and stockout signals, production, input quantities/costs, payroll, distributions, inventory, cash and breaches. [M16_DAYS.csv](M16_DAYS.csv) contains **120** village-day rows, including every resident’s cash and actual meal/visitor outcomes. [M16_RUNS.csv](M16_RUNS.csv) contains the **twelve** run summaries and complete ledger/compact-summary fingerprints. No verbose event history was saved for these experiments.

### Competitive purchasing fixture and failures

The separately selectable one-day fixture conserves **430** coins and all six original productive assets. Ada buys Cora’s one bread at three, finishing with one coin; Bram then buys Finn’s one bread at five, also finishing with one. Seller cash becomes **123/5**. Both bread are consumed through real operations. No production, wages, new equipment or automatic customers appear. Original guaranteed work not exercised by this partial fixture closes honestly as six breaches; only these two meals are exercised. This is not another equilibrium run.

In the reversed-order native test, Bram takes the three-coin bread and finishes at **three coins**; Ada retains **four** and cannot afford the remaining five-coin loaf, which stays in Finn’s inventory. Allocation is allowed to change with order. Equal-price tests keep both sellers stocked and show a buyer’s selection alternating by day. An interleaved real competing purchase exhausts a selected quote: the first attempt fails stock authority, then the buyer independently buys the remaining seller’s loaf. No seller gets a guaranteed share.

Focused tests also cover legitimate quote refresh, forged prices/old versions, arbitrary buyer-supplied prices, unauthorized revision, one revision/day, positive/integer/numeric bounds and total-price overflow, stock exaggeration, two funded millers competing for four wheat, excess daily food and visitor quantities, private visitor ceilings, hidden customer balances/unoffered inventory, public observation copies and corrupted policy/quote receipts. Explicit demand tables verify all three candidate optima, current-price and lower-price ties, the one-coin floor, fixed mode and the unimplemented personality interface. Failed commands leave complete snapshots unchanged.

### Verification

- **Godot 4.6.3 full suite: 2932 checks, zero failures**, retaining all 2867 historical checks and adding 65 focused M16 checks. The focused 65 were rerun successfully after the final observation-cursor audit refinement.
- **Python full suite: 44 tests passed**, retaining all 38 historical tests plus six M16 tests; the six were also rerun after the final audit refinement.
- **139 pinned historical payload comparisons passed:** all 133 through M14 and all six M15 summary payloads, with their existing full-ledger fingerprints and cached bytes. This includes the original M0 30-day seed-42 hash and the successful 365-day M15 external-trade control. No historical result/configuration was rewritten.
- All **twelve A–D experiments** ran twice in independent processes, with byte-identical compact reports and complete ledger fingerprints. Each also passed independent Python financial reconstruction of an in-memory full trace and all native accounting/observation/objective checks. Stage A matched the M15 control’s real accounting at 1/3/30 days.
- All **360 business-day**, **120 village-day**, **64 final-account** and **twelve run** rows were verified against generated summaries. The separately selectable finite-stock competition fixture also passed independent reconstruction.
- Editor import, all compact artifact fingerprints/row counts, readable seven-line CLI reports, invalid stage/scenario/fixture rejection, final M0 hash and `git diff --check` passed. **No final test failures or blocked verification; no economic parameters were tuned after results.**

Every stage’s 3/30-day native test also verifies split-run full state, ledger and report equality. The shared enterprise auditor reconstructs every authoritative movement and final assets/employment/books, conditionally validating M16 quote versions and prices; historical fixed-price branches remain unchanged. The separate pricing auditor reconstructs private own-account/prior-sales observations and public offers, independently evaluates the candidate objective and buyer tie/quantity rule, and validates execution links. The independent Python receipt auditor reconstructs all twelve experiment traces in memory, including actual quoted money/goods flows and canonical ledger fingerprints. No policy reads reporting aggregates or unrestricted world history.

### Architecture, commands and limits

`pricing_world.gd` extends M15 authority with per-business/item offers, private buyer demand limits, quote validation, restricted observations and validated dispatch. `buyer_policy.gd` and `pricing_policy.gd` are pure functions. `pricing_runner.gd` reuses M15 initial conditions and prescribed daily labor/production/distributions; configuration selects A–D. `pricing_fixtures.gd` supplies the isolated finite-stock competition reference. `pricing_report.gd` is a read-only daily projection; `pricing_audit.gd` independently checks decisions. A protected five-line native purchase adapter in `labor_world.gd` avoids duplicating atomic purchase accounting. Small conditional extensions in existing native/Python enterprise auditors recognize quoted receipts, without changing historical audit output.

```sh
# Stage selector is independent of days/seed; A is the default M16 stage.
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_pricing --stage A 30 42
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_pricing --stage B 30 42
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_pricing --stage C 30 42
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario settlement_pricing --stage D 30 42
godot --headless --path . --script res://scripts/tools/run_simulation.gd -- --scenario pricing_competition_fixture 1 42
python3 -B scripts/tools/run_pricing.py --output work/m16
godot --headless --no-header --path . --script res://tests/run_tests.gd
python3 -B -m unittest discover -s tests -p 'test_*.py' -v
```

A final audit refinement binds buyer observations to their ledger cursor, so a legitimate stock change between observation and execution does not appear to be leaked or fabricated information. This changes only new M16 observation metadata/auditing, not decisions, resources, prices or outcomes. All economic results and daily rows remained unchanged after rerunning the experiments.

`--report-json` exports compact reports without events; `--json` is available for short independent inspection. The fixed-price historical default CLI stays M0. All local output offers and job listings remain separate public observations. Offered limits are live stock caps, not reservations; inventory is checked again at execution. Price revision changes terms/version only. The policy optimizes each firm’s normal output commodity; general quote authority permits other existing commodities without implementing another industry or treating every good as essential food.

Forecasts deliberately condition on prescribed production/payroll and can overestimate output when actual resources or liquidity prevent shifts. The world never performs unaffordable work. Demand estimates use own fulfilled sales/received stockouts and one fixed sensitivity; they do not model the visitors’ discontinuous private ceiling, customer wealth distribution, competitors’ private state or long-run feedback. Competitor public quotes are observable; this first linear own-history belief does not learn cross-price elasticities. Fulfilled sales are a lower bound, but unsubmitted demand remains unknown. There is no reputation, personality behavior, investment, employment change, corrective retained-earnings policy, general equilibrium solver or claim of enduring autonomous stability. **Stop after M16 for review; no M17.**
