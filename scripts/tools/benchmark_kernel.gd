extends SceneTree
const Math=preload("res://scripts/sim/native_math.gd")
func _init() -> void:
	var args=OS.get_cmdline_user_args()
	var folder: String=args[0]
	var prefix: String=args[1]
	var copies: int=int(args[2])
	var math=Math.new(args[3])
	if not math.error.is_empty():
		printerr(math.error)
		quit(2)
		return
	var passes: Array=[]
	for pass_index in 3:
		var raw=FileAccess.get_file_as_bytes(folder+"/"+prefix+"-pass%d.bin"%[pass_index+1])
		var op: int=raw.decode_u32(8)
		var jobs=_unpack(raw)
		var repeated: Array=[]
		for _j in copies: repeated.append_array(jobs)
		passes.append({"op":op,"jobs":repeated})
	# One full representative decision warm-up; never shorten a measured batch.
	for pass_index in 3:
		var first=passes[pass_index]
		math.batch(first.op,first.jobs.slice(0,first.jobs.size()/copies))
	math.measurements.clear()
	var outputs: Array=[]
	var start=Time.get_ticks_usec()
	for phase in passes: outputs.append(math.batch(phase.op,phase.jobs))
	var total=Time.get_ticks_usec()-start
	print(JSON.stringify({"case":prefix,"copies":copies,"backend":args[3],"total_usec":total,"batches":math.measurements,
		"digest":JSON.stringify(outputs,"",true).sha256_text()}))
	quit()
func _unpack(raw: PackedByteArray) -> Array:
	var op: int=raw.decode_u32(8)
	var n: int=raw.decode_u32(12)
	var jobs: Array=[]
	var stride: int=432 if op==1 else 2648
	for j in n:
		var offset: int=16+j*stride
		var job={"price":int(raw.decode_u32(offset))}
		var flat=raw.slice(offset+16,offset+stride).to_float64_array()
		if op==1:
			job["carry"]=int(raw.decode_u32(offset+4))
			job["b"]={"local":{"alpha":Array(flat.slice(0,13)),"weights":Array(flat.slice(13,26))},
				"visitor":{"alpha":Array(flat.slice(26,39)),"weights":Array(flat.slice(39,52))}}
		else:
			job["supply"]=int(raw.decode_u32(offset+4))
			job["state"]=Array(flat.slice(0,4))
			var forecast: Array=[]
			for t in 13: forecast.append(Array(flat.slice(4+t*25,4+(t+1)*25)))
			job["forecast"]=forecast
		jobs.append(job)
	return jobs
