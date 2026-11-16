extends RefCounted
const Math=preload("res://scripts/sim/native_math.gd")
const Beliefs=preload("res://scripts/sim/bakery_beliefs.gd")
const Policy=preload("res://scripts/sim/bakery_policy.gd")
const Batched=preload("res://scripts/sim/batched_bakery_policy.gd")
static func run(t: SceneTree) -> void:
	var o={"current_price":4,"posted":[4],"state":[72,12,0,0],"carry":3,"minimum":[1,0],"supply":12}
	var b=Beliefs.fresh()
	var saved=JSON.stringify([o,b])
	var original=Policy.decide(o,b,"D")
	var grouped=Batched.decide(o,b,"D",Math.new())
	t._check(original==grouped,"batched GDScript graph exactly matches original")
	t._check(JSON.stringify([o,b])==saved,"batch orchestration leaves permitted inputs immutable")
	t._check(not Math.new("unknown").error.is_empty(),"invalid backend fails closed")
	if not FileAccess.file_exists("res://native/m20/math.gdextension"):
		t._check(not Math.new("cpp").error.is_empty(),"explicit unavailable backend fails closed")
		return
	for backend in ["cpp","rust"]:
		var math=Math.new(backend)
		t._check(math.error.is_empty(),backend+" optional bridge loads")
		if not math.error.is_empty(): continue
		var native=Batched.decide(o,b,"D",math)
		t._check(native==original,backend+" complete candidate graph matches GDScript exactly")
		t._check(math.measurements.size()==3,backend+" exactly three decision batches")
		t._check(native==Batched.decide(o,b,"D",math),backend+" replay deterministic")
		var invalid=math._pack(1,[{"price":0,"carry":3,"b":b}])
		t._check(not math.bridge.compute(backend,invalid).ok,backend+" authoritative numerical boundary rejects invalid price")
		var pmf=Policy.forecasts(b,[6],3)[6]
		invalid=math._pack(2,[{"price":6,"supply":12,"state":[-1,0,0,0],"forecast":pmf}])
		t._check(not math.bridge.compute(backend,invalid).ok,backend+" negative cash rejected")
