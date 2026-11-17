extends RefCounted
## Fixed M21 pure job schema. Variant bytes preserve float64 and integer identity.
const PARAMS={"policy":"M18","horizon":14,"discount":0.99,"tie":1e-9,"backend":"rust"}
const OBS_KEYS=["day","current_price","posted","state","supply","input_price","carry","minimum"]
static func fingerprint(value: Variant) -> String:
	var hash=HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(var_to_bytes(value))
	return hash.finish().hex_encode()
static func _keys(value: Variant,keys: Array) -> bool:
	if not value is Dictionary or value.size()!=keys.size(): return false
	for key in keys:
		if not value.has(key): return false
	return true
static func _integer(value: Variant,low: int,high: int) -> bool:
	return value is int and value>=low and value<=high
static func _numbers(value: Variant,size: int,low: float,high: float) -> bool:
	if not value is Array or value.size()!=size: return false
	for x in value:
		if typeof(x) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(x) or x<low or x>high: return false
	return true
static func valid_inputs(o: Variant,b: Variant,stage: Variant) -> bool:
	if stage not in ["C","D"] or not _keys(o,OBS_KEYS) or not _keys(b,["local","visitor"]): return false
	if not _integer(o.day,1,10000) or not _integer(o.current_price,1,12) or not _integer(o.input_price,4,4): return false
	if not _integer(o.supply,0,12) or not _integer(o.carry,0,12): return false
	if not _numbers(o.state,4,-1e9,1e9) or not _numbers(o.minimum,2,0,12): return false
	for i in 3:
		if o.state[i]<0: return false
	for n in o.minimum:
		if not n is int: return false
	if not o.posted is Array or o.posted.size()>12: return false
	for p in o.posted:
		if not _integer(p,1,12): return false
	for cohort in ["local","visitor"]:
		if not _keys(b[cohort],["alpha","weights"]): return false
		if not _numbers(b[cohort].alpha,13,0.000000000001,1e9) or not _numbers(b[cohort].weights,13,0.0,1.0): return false
		var total=0.0
		for weight in b[cohort].weights: total+=weight
		if absf(total-1.0)>1e-9: return false
	return true
static func create(id: int,o: Dictionary,b: Dictionary,stage: String) -> PackedByteArray:
	if id<1 or not valid_inputs(o,b,stage): return PackedByteArray()
	return var_to_bytes({"version":1,"id":id,"owner":"cora","day":o.day,"minute":745,"stage":stage,
		"observation":o,"beliefs":b,"parameters":PARAMS,"observation_hash":fingerprint(o),
		"belief_hash":fingerprint(b),"input_hash":fingerprint([o,b,stage,PARAMS])})
static func decode(bytes: PackedByteArray) -> Dictionary:
	if bytes.size()<4 or bytes.size()>65536 or not bytes.has_encoded_var(0,false): return {}
	var job: Variant=bytes_to_var(bytes)
	if not _keys(job,["version","id","owner","day","minute","stage","observation","beliefs","parameters","observation_hash","belief_hash","input_hash"]): return {}
	if not _integer(job.version,1,1) or not _integer(job.id,1,1000000) or job.owner!="cora" or job.minute!=745 or job.parameters!=PARAMS: return {}
	if not valid_inputs(job.observation,job.beliefs,job.stage) or job.day!=job.observation.day: return {}
	if job.observation_hash!=fingerprint(job.observation) or job.belief_hash!=fingerprint(job.beliefs): return {}
	if job.input_hash!=fingerprint([job.observation,job.beliefs,job.stage,PARAMS]): return {}
	return job
static func compute(bytes: PackedByteArray,math: RefCounted,cache: Dictionary) -> PackedByteArray:
	var job=decode(bytes)
	if job.is_empty(): return var_to_bytes({"ok":false,"error":"invalid_job"})
	math.measurements.clear()
	var start=Time.get_ticks_usec()
	var proposal=preload("res://scripts/sim/batched_bakery_policy.gd").decide(job.observation,job.beliefs,job.stage,math,cache)
	return var_to_bytes({"ok":math.error.is_empty(),"id":job.id,"owner":job.owner,"day":job.day,"minute":job.minute,
		"input_hash":job.input_hash,"proposal":proposal,"compute_usec":Time.get_ticks_usec()-start,
		"thread_id":OS.get_thread_caller_id(),"batches":math.measurements})
