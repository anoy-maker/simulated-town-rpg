"""Conditional M27 marginal-cost arithmetic; no inferred sales or policy changes."""
def wedge(cap):
    assert cap in (16,19,21)
    units=min(7,cap-14)
    return dict(cap=cap,third_farm_wheat=units,farm_sales_if_sold=2*units,
                new_shift_wage=10,new_farm_margin=2*units-10,
                additional_committed_wage=0,current_assignment_margin_if_sold=2*units,
                label='relaxed_potential',condition='output sells at the unchanged quote')


def five_wheat_chain():
    farm=5*2-10;mill=5*5-5*2-10;bakery=7*6-5*5-10
    return dict(farm=farm,mill=mill,bakery=bakery,integrated=farm+mill+bakery,
                strictly_positive_integer_wheat_prices=[],
                proof='5p-10>0 requires integer p>=3; 15-5p>0 requires integer p<=2',
                incentive_compatible=False,condition='new wages, fixed flour5/bread6, all marginal output sold; not observed demand')
