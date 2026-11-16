"""Independent M15 money/goods/assets/labor reconstruction for short exported traces."""
import copy
import hashlib
import json


def audit(data):
    r, history = data["report"], data["events"]
    state = copy.deepcopy(history[0]["details"]["state"])
    entities, books, assets = state["entities"], state["cash_results"], state["productive_assets"]
    affiliations, jobs = state["affiliations"], state["employment"]
    quotes = state.get("commodity_quotes")
    combined = sum(p["money"] for p in entities.values())
    receipts, claimed, worked = set(), set(), set()
    consumed = {}
    pay_before = {}
    for index, e in enumerate(history, 1):
        assert e["id"] == index
        action, actor, target, d = (e[k] for k in ("action", "actor", "target", "details"))
        if action == "day_started":
            worked.clear()
        if not e["success"]:
            continue
        if action == "quote_revised":
            q = d["quote"]
            previous = quotes.get(target, {}).get(q["item"], {})
            assert state["businesses"][target]["owner"] == actor and q["seller"] == target
            assert type(q["unit_price"]) is int and 1 <= q["unit_price"] <= 1_000_000_000
            assert previous.get("revised_day", -1) != e["day"] and q["revised_day"] == q["effective_day"] == e["day"]
            assert q["version"] == previous.get("version", 0) + 1
            quotes.setdefault(target, {})[q["item"]] = copy.deepcopy(q)
        elif action == "business_founded":
            assert target not in entities and d["entity"]["money"] == 0
            assert all(n == 0 for n in d["entity"]["inventory"].values())
            assert d["business"]["owner"] == actor and not d["business"]["employees"]
            assert all(n == 0 for n in d["book"].values())
            entities[target] = copy.deepcopy(d["entity"])
            state["businesses"][target] = copy.deepcopy(d["business"])
            books[target] = copy.deepcopy(d["book"])
        elif action == "purchase":
            item, qty, price = (d[k] for k in ("item", "quantity", "unit_price"))
            assert type(qty) is int and qty > 0
            if quotes is None:
                assert price == {"wheat": 2, "flour": 4, "bread": 4}[item]
            else:
                q = quotes[target][item]
                assert q["active"] and price == q["unit_price"] and qty <= q["limit"]
                assert all(d["quote"][k] == v for k, v in q.items())
                assert d["quote"]["available"] == min(q["limit"], entities[target]["inventory"][item])
            assert d["total_price"] == qty * price
            entities[actor]["money"] -= qty * price
            entities[target]["money"] += qty * price
            entities[actor]["inventory"][item] += qty
            entities[target]["inventory"][item] -= qty
            books[target]["sales"] += qty * price
            if actor in books:
                books[actor]["inputs"] += qty * price
        elif action == "transfer_money":
            amount, purpose = d["amount"], d["purpose"]
            assert type(amount) is int and amount > 0
            pay_before[index] = (entities[actor]["money"], copy.deepcopy(books.get(actor)))
            entities[actor]["money"] -= amount
            entities[target]["money"] += amount
            if purpose == "capital_contribution":
                assert state["businesses"][target]["owner"] == actor
                books[target]["capital_contributions"] += amount
            elif purpose == "asset_purchase":
                books[actor]["capital_purchases"] += amount
                if target in books:
                    books[target]["capital_asset_sales"] += amount
            elif purpose == "wage":
                books[actor]["payroll"] += amount
            else:
                assert purpose == "distribution"
                books[actor]["distributions"] += amount
            receipts.add(index)
        elif action in ("produce", "harvest"):
            if action == "harvest":
                inputs, outputs = {}, {"wheat": d["amount"]}
                assert d["amount"] == 4
            else:
                inputs, outputs = ({"wheat": 4}, {"flour": 4}) if d["recipe"] == "mill" else ({"flour": 4}, {"bread": 6})
                assert d["inputs"] == inputs and d["outputs"] == outputs and d["batches"] == 2
            for item, amount in inputs.items():
                entities[actor]["inventory"][item] -= amount
            for item, amount in outputs.items():
                entities[actor]["inventory"][item] += amount
            receipts.add(index)
        elif action in ("owner_work_shift", "work_shift"):
            own = action == "owner_work_shift"
            assert affiliations[actor] == dict(business=target, kind="self_employed" if own else "employee")
            assert actor not in worked and state["businesses"][target]["industry"] in entities[actor]["skills"]
            output = d["production_event_id"]
            assert output not in claimed and history[output-1]["actor"] == target and history[output-1]["action"] in ("produce", "harvest")
            claimed.add(output)
            if own:
                assert d["wage"] == 0 and state["businesses"][target]["owner"] == actor
            else:
                pay = d["payment_event_id"]
                assert pay not in claimed and jobs[actor]["active"] and jobs[actor]["business"] == target
                assert history[pay-1]["actor"] == target and history[pay-1]["target"] == actor
                assert history[pay-1]["details"] == dict(amount=d["wage"], purpose="wage") and jobs[actor]["wage"] == d["wage"]
                claimed.add(pay)
            worked.add(actor)
        elif action == "consume":
            entities[actor]["inventory"]["bread"] -= d["amount"]
            consumed[actor] = consumed.get(actor, 0) + d["amount"]
        elif action in ("capital_contribution", "asset_purchased", "profit_distribution"):
            pay = d.get("payment_event_id")
            if pay is not None:
                assert pay == index - 1 and pay not in claimed and history[pay-1]["success"]
                claimed.add(pay)
            if action == "capital_contribution":
                assert history[pay-1]["actor"] == actor and history[pay-1]["target"] == target
                assert history[pay-1]["details"] == dict(amount=d["amount"], purpose="capital_contribution")
            elif action == "asset_purchased":
                asset = assets[d["asset"]]
                assert asset["holder"] == d["seller"] and asset["for_sale"] and asset["price"] == d["price"]
                if d["price"]:
                    assert history[pay-1]["details"] == dict(amount=d["price"], purpose="asset_purchase")
                asset.update(holder=target, for_sale=False)
                assert asset == d["asset_state"]
            else:
                cash, book = pay_before[pay]
                retained = book["sales"] - book["inputs"] - book["payroll"] - book["distributions"]
                policy = d["policy"]
                portion = 0 if policy["mode"] == "retain" else max(0, retained) // (2 if policy["mode"] == "half" else 1)
                assert d["amount"] == min(portion, max(0, cash-policy["reserve"])) > 0
                assert d["cumulative_before"] == book and state["businesses"][target]["owner"] == actor
                assert history[pay-1]["details"] == dict(amount=d["amount"], purpose="distribution")
        elif action == "employment_ended":
            assert affiliations.pop(actor) == d["affiliation"]
            if d["affiliation"]["kind"] == "employee":
                jobs[actor] = copy.deepcopy(d["job"])
        elif action == "self_employment_started":
            assert actor not in affiliations
            affiliations[actor] = copy.deepcopy(d["affiliation"])
        elif action == "employment_started":
            assert actor not in affiliations
            affiliations[actor] = copy.deepcopy(d["affiliation"])
            jobs[actor] = copy.deepcopy(d["job"])
        assert sum(p["money"] for p in entities.values()) == combined
        assert all(type(p["money"]) is int and 0 <= p["money"] <= 1_000_000_000 for p in entities.values())
        assert all(type(n) is int and 0 <= n <= 1_000_000_000 for p in entities.values() for n in p["inventory"].values())
    assert receipts == claimed and entities == r["final"]["entities"] and books == r["final"]["cash_results"]
    assert assets == r["final"]["productive_assets"] and set(assets) == set(r["initial"]["productive_assets"])
    assert affiliations == r["final"]["affiliations"]
    if quotes is not None:
        assert quotes == r["final"]["commodity_quotes"]
    for actor, entity in entities.items():
        account = r["accounts"][actor]
        assert account["consumed"] == consumed.get(actor, 0)
        initial_money = r["initial"]["entities"].get(actor, {}).get("money", 0)
        assert entity["money"] == initial_money + account["earned"] - account["spent"]
    canonical = json.dumps(history, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode()
    assert hashlib.sha256(canonical).hexdigest() == r["profitable"]["ledger_sha256"]
