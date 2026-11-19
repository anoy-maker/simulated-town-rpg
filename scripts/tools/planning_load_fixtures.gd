extends RefCounted
const Job=preload("res://scripts/sim/planning_job.gd")
const ROOT="res://tests/fixtures/m22/"
const MIX=["D-30","D-15","C-15","D-3","C-30","C-1","D-1","C-3"]
static func load_all() -> Dictionary:
	var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"manifest.json"))
	assert(manifest.version==1 and manifest.cases.size()==8)
	var out: Dictionary={}
	for item in manifest.cases:
		var packet=FileAccess.get_file_as_bytes(ROOT+item.case+".request")
		var expected=FileAccess.get_file_as_bytes(ROOT+item.case+".proposal")
		assert(Job.fingerprint(packet)==item.request_hash and Job.fingerprint(bytes_to_var(expected))==item.proposal_hash)
		assert(Job.decode(packet).input_hash==item.input_hash)
		out[item.case]={"packet":packet,"expected":expected,"proposal_hash":item.proposal_hash,"input_hash":item.input_hash}
	return out
static func name_for(index: int,mixed: bool) -> String:
	return MIX[index%MIX.size()] if mixed else "D-15"
