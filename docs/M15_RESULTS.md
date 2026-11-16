# M15 — Open economy and business formation

## Fixed implementation and experimental choices

M15 contains an isolated longitudinal `settlement_external_trade_reference` (A) and two prescribed transaction fixtures (B/C). No autonomous entrepreneurial, hiring, pricing or investment policy is added. All M0–M14 behavior and recorded outputs remain controls.

A copies M14's twelve residents, firms, ownership, skills, four existing workplace slots, 2/4/4 prices, six-coin wages and recipes. All nine employees work daily; their two-of-three minimum contracts remain unchanged, and the third shift is additional paid work. An external visitor purse starts with 8760 coins. Six real one-loaf purchases/day move 24 coins into the village; purchased visitor bread is consumed by that external account, separately from twelve resident meals. Initial village/combined money is 432/9192. External money never refills. Existing firms distribute actual eligible earnings above 120 after trade/consumption. Run 1/3/30/365 days seed 42, twice each; a separate 20-coin, three-day visitor case tests exhaustion without rescue.

B/C are audited synthetic initial conditions, not an extraction from a canonical run. Finn starts with 500 personal coins, the other eleven residents with six, the original firms with 120. The original mill owns twelve flour for the finite prescribed transactions. Ada owns one spare workshop priced at 60; an external equipment seller with zero coins owns one spare oven priced at 180. An already present external customer has 100 coins. Combined fixture currency is **1026**, village currency **926**. Existing six productive assets plus the two spare assets have unique IDs and initial holders. No assets, inputs or customers appear when a business is founded.

Finn contributes 300 to a new bakery, buys the two assets, and keeps 200 personal/60 business coins. New firms use an explicit **24-coin cash reserve** and default to **retain all operating earnings**. Alternative prescribed `half`/`full` payout rules act only on positive realized operating earnings less prior distributions and liquid cash above the stated reserve. Capital contributions and equipment purchases are separate financing/capital flows, not sales/payroll/operating costs. No initial capital becomes profit.

Finn and Iona explicitly request resignation from Cora at day zero, effective at the next day boundary. Finn then starts a self-employment affiliation, buys four flour for 16, performs one unpaid owner shift, and sells six bread to the existing customer for 24: closing business cash **68**, operating surplus **8**. Owner labor is a real capacity-limited shift with no salary. In C Finn posts one casual six-coin, zero-minimum job (three-day contract period/duration); uncommitted baking-skilled Iona applies, Finn makes the offer, and Iona accepts. Finn ends self-employment at the next boundary, when Iona's paid employment starts. Another real four-flour/six-bread transaction yields **70** cash and **10** cumulative retained earnings. Owner return to productive work, other distribution choices, unsold output, prior obligation retention and guaranteed-contract failures are independent tests, not changes to the C result.

B/C do not run the entire settlement production/food reference. Unattempted old guaranteed work is recorded honestly when fixture days close, and no employee is invented to replace the two resignations. Their failures cannot be interpreted as an autonomous forecast or solely as a causal effect of the resignations. Assets, commodities, all accounts, affiliations and employment transitions remain in the audit.

Architecture: extend the existing profitable world and labor authority through small default-preserving account/production/contract/report hooks. Use existing validated money transfers, purchases, recipes and paid work. New authority covers finite asset ownership, zero-endowment firm creation, contributions, unpaid owner work and the local board/affiliation transitions. Immutable receipts and independent reconstruction verify actual money/goods/assets, not predicted balance assignments.

## Actual results

### A: finite external trade (seed 42)

All predicted values were reproduced through actual transactions, without account resets. Each closed day independently verifies production 12 wheat / 12 flour / 18 bread, twelve resident meals, six visitor loaves, nine paid shifts, 54 wage coins and 18 owner-distribution coins. Existing four-slot workplaces and their identified assets permit three shifts; no capacity increase was needed. Every resident closes day `d` with `6 + 2d`; each business closes at 120 with zero commodities. Village money is `432 + 24d`, external money `8760 - 24d`, combined money always **9192**, including between transactions.

| Days | Village / external money | Resident meals | Visitor bread | Paid shifts | Wages | Owner distributions | Misses / breaches |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 456 / 8736 | 12 | 6 | 9 | 54 | 18 | 0 / 0 |
| 3 | 504 / 8688 | 36 | 18 | 27 | 162 | 54 | 0 / 0 |
| 30 | 1152 / 8040 | 360 | 180 | 270 | 1620 | 540 | 0 / 0 |
| 365 | 9192 / 0 | 4380 | 2190 | 3285 | 19710 | 6570 | 0 / 0 |

Annual production is **4380 wheat, 4380 flour, 6570 bread**; bread consumption is 4380 local plus 2190 external. Each of nine employees completes 365 shifts and receives 2190 wage coins. The unchanged minimum contracts account for 2190 fulfilled obligations; **1095 additional shifts** pay another 6570 coins beyond the minimum's 13140. Owners perform no productive labor and each receives 2190 in genuine distributions. All twelve residents spend 1460 on food, eat 365 times, and finish with **736 personal coins**. Asset identities and inventories reconcile completely.

| Business, 365 days | Sales | Input costs | Payroll | Surplus distributed | Closing cash |
|---|---:|---:|---:|---:|---:|
| Farm | 8760 | 0 | 6570 | 2190 | 120 |
| Mill | 17520 | 8760 | 6570 | 2190 | 120 |
| Bakery | 26280 | 17520 | 6570 | 2190 | 120 |

A records **8760 successful purchases**, zero rejected purchases, gross monetary circulation **78840**, and 37596 events. Circulation includes repeated use of the same coins, not additional money supply. The visitor purse loses exactly 8760 and the village gains exactly 8760. The annual summary is 27833 bytes; the full ledger fingerprint is in [M15_RUNS.csv](M15_RUNS.csv). No annual event dump was generated.

The separate **20-coin visitor-purse/three-day test** conserves combined money **452**, buys only five loaves, and rejects the other thirteen daily attempts for insufficient funds. It produces the prescribed 54 bread but leaves **14 bread unsold at the bakery**. Only **35 resident meals** succeed: Cora cannot afford her day-three loaf. Bakery distributions total only **two coins**, rather than eighteen. The other firms continue their prescribed activity while funds permit; no replacement customer or replenishment repairs the lost demand. This shows the finite boundary has real consequences, not that A is sustainable after visitors run out of money. Day 366 was not part of the requested reference matrix.

### B: controlled startup and owner production

The initial ledger explicitly contains **926 village + 100 external = 1026 combined coins**, twelve flour at the mill and eight productive assets. Finn's 500 is a fixture endowment; it is not silently substituted into A. A's checked daily recurrence independently implies Finn has 500 at day 247.

| New-bakery checkpoint | Finn personal cash | Business cash | Contributions | Asset purchases | Sales | Operating inputs | Payroll | Retained operating earnings |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| After founding and asset purchases | 200 | 60 | 300 | 240 | 0 | 0 | 0 | 0 |
| B: after owner shift and actual sales | 200 | 68 | 300 | 240 | 24 | 16 | 0 | 8 |
| C: after employee shift and actual sales | 200 | 70 | 300 | 240 | 48 | 32 | 6 | 10 |

Founding creates no cash, stock, equipment, employees or customers. The real contribution moves 300; the real asset purchases pay 180 to the external equipment seller and 60 to Ada, who relinquish the two unique assets. The new bakery owns both; all eight initial asset identities remain present. A bare new enterprise is nonoperational until required assets are acquired. Its single productive slot is checked against owned asset capacity.

B buys four of the mill's twelve initial flour, consumes it in Finn's single real shift, and sells all six resulting bread to the initially funded customer. Finn receives **no wage**. Closing money is **770 village / 256 external / 1026 combined**: Ada 66, Finn 200, mill 136, new bakery 68, external vendor 180, customer 76; all other resident/business money remains at its fixture endowment. Eight initial flour remain at the mill; no bread remains after the customer's explicit consumption. No distributions occur.

The independent **unsold-output test** buys the same flour and performs the same owner shift without a sale: business cash **44**, inventory **six bread**, operating cash earnings **−16**. The equipment cost is not deducted again from operating earnings. This is deliberately simple realized cash accounting, not inventory-valued accrual profit; no depreciation or owner labor opportunity cost is booked.

### C: public hiring, delegation and employment boundaries

Finn posts `baker_job`: baker skill, wage **6**, guaranteed shifts **0**, period **3 days**, duration **3 days**, vacancy **1**. Public terms are identical for all local residents and contain no company financial statements, inventory, other households' balances or remote markets. Returned observations are copies.

Iona's availability is genuine: her explicit resignation from Cora became effective before applying. Iona applies; Finn makes an employer-authorized offer; Iona accepts. At the next boundary Finn's requested end of self-employment takes effect and Iona's real employment begins. The job is active on days 2–4, expires at boundary 5, and produces no minimum-shift obligations because it is casual. Acceptance alone does not produce wages or goods.

On day two the new bakery buys another four real flour for 16, pays Iona six through the existing payroll authority, produces six bread and receives 24 from the same finite customer. Incremental operating cash earnings are **two**, cumulative **ten**, closing cash **70**. Finn still owns the bakery, holds **200**, has no productive affiliation and receives no employee wage or distribution. Iona finishes with **12** personal coins. The mill holds **152** coins/four flour, customer **52**, vendor **180**. Village/external money is **794/232**, combined still **1026**.

B/C run prescribed transactions, not complete village production or food schedules. Their zero reported missed meals means **no household meal attempts were exercised**, not that residents were fed. Old minimum work not attempted by these fixtures closes as **five breaches in B, nine cumulatively in C**; no invisible replacements, wages or debt appear. These figures must not be attributed solely to Finn/Iona leaving. A separate test resigns Finn after an obligation is already due: the old breach remains, future old-job dues cease. New guaranteed contracts also record genuine missing-input breaches, unlike casual jobs.

Separate tests let Iona resign, let Finn return to legitimate unpaid production using the remaining four initial flour, and let nonworking owner Finn accept paid work elsewhere without a second affiliation. A distribution test pays **five** under `half`, then the remaining **five** under `full`, leaving **60** in business cash and Finn **210**. A repeated full payout pays nothing; a further real capital contribution does not recreate earnings. The explicit new-firm reserve is 24, not M14's 120. Canonical B/C retain all earnings; these alternatives do not change their results.

### Verification

- **Godot 4.6.3 full suite: 2867 checks, zero failures** — all 2803 historical checks plus 64 focused M15 checks. The final full run includes the added uncommitted/missing-skill case and corrected consumption projection.
- **Python full suite: 38 tests passed** — all 33 historical tests plus five M15 tests.
- **133 historical payload comparisons passed**, byte-identical to published M0–M14 outputs: 59 through M7, six M8, six M9, eighteen M10, four M11, three M12, sixteen M13 study payloads plus sixteen original summaries, and five M14 summaries. M14's five cached summaries also match byte-for-byte. Original M0 30-day seed-42 SHA-256 remains `6df5c8eaeb998a82b8fb1af5ab1410722f5d9b9c39712597fb4f09f1497de1a9`.
- All requested A horizons and both fixtures passed independent-process replay and native auditing; short traces also passed the independent Python auditor. Editor import completed without script errors. Published artifact hashes, readable seven-line CLI reports, rejected fixture horizon/seed arguments and `git diff --check` passed.
- **No final test failures or blocked verification.** The full matrix used seed 42 as requested; no claim of stochastic resilience beyond these controlled cases.

Focused failures cover unauthorized owners, unrelated applicants, existing affiliations, missing skills, future-start jobs, duplicate vacancies/asset purchases/work, insufficient personal/business funds, invalid/overflowing capital amounts, non-offered incumbent assets, missing workshop/equipment, physical asset capacity, unsold production, capital disguised as profit, duplicate distributions, casual/guaranteed terms and expired jobs. Failed commands are compared against complete pre-command snapshots. Corrupted owner-wage/contribution/asset receipts are independently rejected.

All six cases run twice in independent Godot processes with byte-identical compact summaries and canonical ledger fingerprints. A additionally passes split-run state/event/report equality at every requested horizon; B/C repeat deterministically. Native reconstruction checks every event's combined currency, bounds, goods, asset identities, unique payroll/production claims, capital categories, affiliations, board lifecycle and actual due/outcome records against the full final state. A's daily expected recurrence is checked separately. Independent Python reconstruction checks short A/B/C traces, account-flow/consumption projections and receipt fingerprints. Annual reconstruction stays in memory.

The results driver writes **six run rows**, **100 account rows** (including every external account), and **16 fixture asset rows**. See [M15_RUNS.csv](M15_RUNS.csv), [M15_ACCOUNTS.csv](M15_ACCOUNTS.csv) and [M15_ASSETS.csv](M15_ASSETS.csv). Detailed checkpoints remain in the compact B/C report JSON and can be regenerated with the commands below.

During preflight, two audit dispatch omissions for `day_started` were corrected; a batch check initially treated the scalar audited-day count as a flag dictionary and was corrected. Review also corrected the inherited one-meal-per-command projection for multi-loaf visitor consumption and the displayed worker schedule. None required changing economic parameters, transaction outcomes or historical behavior. All final checks passed.

```sh
godot --headless --no-header --path . --script res://tests/run_tests.gd
python3 -B -m unittest discover -s tests -p 'test_*.py' -v
python3 -B scripts/tools/run_enterprise.py --output work/m15
# Optional short fixture ledger for independent receipt inspection:
godot --headless --no-header --path . --script res://scripts/tools/run_simulation.gd -- --scenario enterprise_delegation_fixture 2 42 --json
```

### Architecture and limits

New implementation: `enterprise_config.gd`, `enterprise_world.gd`, `external_trade_runner.gd`, `enterprise_fixtures.gd`, `enterprise_audit.gd`; Python audit/batch tools and focused native/Python tests. Small default-preserving hooks in `world_state.gd`, `labor_world.gd`, `profitable_world.gd` and their report runners reuse the historical validated authority for every monetary/commodity movement. The CLI adds only the three explicit selectors. README/architecture/roadmap and M15 artifacts document the boundary. No historical configuration, policy, result document or data table is replaced; no substantial kernel rewrite was necessary.

Employment records retain historical receipts when the current job changes. Boundary transition events occur after the old day's closure and carry an explicit next `effective_day`. New positive-minimum contracts use deterministic first-minimum-days phases and require whole-cycle durations; original M14 phases remain unchanged. This is a controlled employment lifecycle, not autonomous scheduling, severance or enforcement. Unaccepted offers have no cancellation/timeout/reopening policy yet; a reserved vacancy can remain pending. Original employee rosters retain past names, but active employment/affiliation authority controls eligibility and future dues.

Asset sale consent is the explicit initial `for_sale` offer; this milestone does not add an asset resale/listing market or construction. Existing firms' capacity receives explicit finite asset identities only in M15; historical scenarios retain their old representation. `operational` reports asset setup, not assured inputs, payroll, labor or demand. `half` pays half of currently remaining earnings per explicit settlement call; it is not a lifetime payout-ratio contract. All account/holding limits remain the kernel's existing one-billion ceiling. Snapshot reload/persistence, accrual valuation, depreciation and broader labor/investment frameworks remain outside scope.

A demonstrates prescribed trade/accounting feasibility with finite externally funded demand, not permanent money creation or endogenous growth. B/C demonstrate resource-funded formation and voluntary hiring under declared fixtures, not a claim of guaranteed customers or continued settlement equilibrium after job changes. No autonomous entrepreneurial, hiring or investment policies were introduced. **Stop after M15 for review; no M16.**
