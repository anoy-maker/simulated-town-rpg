extends RefCounted
## M20 opt-in experimental batch adapter. Never receives authoritative world data.
const Policy=preload("res://scripts/sim/bakery_policy.gd")
const Finance=preload("res://scripts/sim/bakery_finance.gd")
var backend: String
var bridge: RefCounted
var error: String=""
var measurements: Array=[]
var record_packets: bool=false
var packets: Array=[]

func _init(selected: String="gdscript") -> void:
	backend=selected
	if backend=="gdscript": return
	if backend not in ["cpp","rust"]:
		error="Unknown numerical backend: "+backend
		return
	if not FileAccess.file_exists("res://native/m20/math.gdextension"):
		error="Native backend unavailable; run scripts/tools/build_native_math.py first"
		return
	var status=GDExtensionManager.load_extension("res://native/m20/math.gdextension")
	if status not in [GDExtensionManager.LOAD_STATUS_OK,GDExtensionManager.LOAD_STATUS_ALREADY_LOADED] or not ClassDB.class_exists("M20Math"):
		error="Native M20 extension could not be loaded"
		return
	bridge=ClassDB.instantiate("M20Math")

func _pack(op: int,jobs: Array) -> PackedByteArray:
	var bytes=PackedByteArray()
	bytes.resize(16)
	bytes.encode_u32(0,0x4b30324d)
	bytes.encode_u32(4,1)
	bytes.encode_u32(8,op)
	bytes.encode_u32(12,jobs.size())
	for job in jobs:
		var header=PackedByteArray()
		header.resize(16)
		header.encode_u32(0,job.price)
		header.encode_u32(4,job.carry if op==1 else job.supply)
		header.encode_u32(8,13)
		bytes.append_array(header)
		var values=PackedFloat64Array()
		if op==1:
			for c in ["local","visitor"]:
				values.append_array(PackedFloat64Array(job.b[c].alpha))
				values.append_array(PackedFloat64Array(job.b[c].weights))
		else:
			values.append_array(PackedFloat64Array(job.state))
			for row in job.forecast: values.append_array(PackedFloat64Array(row))
		bytes.append_array(values.to_byte_array())
	return bytes

func batch(op: int,jobs: Array) -> Array:
	assert(error.is_empty(),error)
	var start=Time.get_ticks_usec()
	var packet=_pack(op,jobs)
	var packed=Time.get_ticks_usec()
	var results: Array=[]
	var compute_usec: float
	var bridge_usec: float=0.0
	var response: Dictionary={}
	if backend=="gdscript":
		for job in jobs:
			results.append(Policy.forecasts(job.b,[job.price],job.carry)[job.price] if op==1 else Finance.continuation(job.state,job.price,job.forecast,job.supply))
		compute_usec=Time.get_ticks_usec()-packed
	else:
		response=bridge.compute(backend,packet)
		if not response.ok:
			error=response.error
			push_error(error)
			return []
		compute_usec=response.compute_usec
		bridge_usec=response.bridge_usec
	var called=Time.get_ticks_usec()
	if backend!="gdscript":
		var flat: PackedFloat64Array=response.output.slice(16).to_float64_array()
		if op==1:
			for j in jobs.size():
				var forecast: Array=[]
				for t in 13: forecast.append(Array(flat.slice(j*325+t*25,j*325+(t+1)*25)))
				results.append(forecast)
		else: results=Array(flat)
	var finished=Time.get_ticks_usec()
	measurements.append({"op":op,"jobs":jobs.size(),"pack_usec":packed-start,"call_usec":called-packed,
		"compute_usec":compute_usec,"bridge_usec":bridge_usec,"unpack_usec":finished-called,"total_usec":finished-start})
	if record_packets: packets.append({"input":packet,"results":results.duplicate(true)})
	return results
