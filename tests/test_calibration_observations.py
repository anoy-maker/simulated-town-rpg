"""Focused tests for the M8 observation-only ledger diagnostic."""
import copy
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts/tools"))
from run_calibration import food_sale_losses


def event(action, actor="baker", target="", success=True, **details):
    return dict(action=action, actor=actor, target=target, success=success, day=1, details=details)


def case(events, initial=1, other=0, final=0, other_final=1):
    for index, entry in enumerate(events, 1):
        entry["id"] = index
    def entities(a, b):
        return {"baker": {"inventory": {"bread": a}}, "laborer": {"inventory": {"bread": b}}}
    return dict(report=dict(experiment="combined_candidate", seed=42, days=1,
                            initial=dict(entities=entities(initial, other)), final=dict(entities=entities(final, other_final))),
                events=events)


def planning(command=None):
    return event("decision", phase="food", command_event_id=command)


def sale(success=True):
    return event("purchase", "laborer", "baker", success, item="bread", quantity=1)


def missed():
    return event("consume", success=False, reason="insufficient_stock", item="bread", amount=1)


class FoodSaleLossTests(unittest.TestCase):
    def test_links_real_sale_to_owned_food_and_missed_meal_without_mutation(self):
        data = case([planning(), sale(), missed()])
        original = copy.deepcopy(data)
        result = food_sale_losses(data)
        self.assertEqual(len(result), 1)
        self.assertEqual((result[0]["planning_event_id"], result[0]["sales_event_ids"], result[0]["consumption_event_id"]), (1, "[2]", 3))
        self.assertEqual(data, original)

    def test_sale_leaving_food_for_successful_meal_is_not_a_loss(self):
        self.assertEqual(food_sale_losses(case([planning(), sale(), event("consume", item="bread", amount=1)], initial=2)), [])

    def test_food_bought_by_its_own_proposal_was_not_owned_at_planning(self):
        purchase = event("purchase", "baker", "laborer", item="bread", quantity=1)
        self.assertEqual(food_sale_losses(case([purchase, planning(1), sale(), missed()], initial=0, other=1)), [])

    def test_failed_sale_and_non_sale_outflow_are_not_attributed_to_sales(self):
        transfer = event("transfer_item", "baker", "laborer", item="bread", amount=1)
        self.assertEqual(food_sale_losses(case([planning(), sale(False), transfer, missed()])), [])

    def test_other_outflows_make_a_mixed_cause_excluded(self):
        transfer = event("transfer_item", "baker", "laborer", item="bread", amount=2)
        self.assertEqual(food_sale_losses(case([planning(), sale(), transfer, missed()], initial=3, other_final=3)), [])

    def test_different_day_is_not_counted_as_a_same_day_planning_loss(self):
        events = [planning(), sale(), missed()]
        events[1]["day"] = events[2]["day"] = 2
        self.assertEqual(food_sale_losses(case(events)), [])


if __name__ == "__main__":
    unittest.main()
