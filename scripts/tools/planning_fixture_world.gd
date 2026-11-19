extends "res://scripts/sim/planning_jobs_world.gd"
## Isolated stale fixtures defer, rather than execute, the normal courier command.
## release_deposit invokes the unchanged validated real-cargo authority at 12:25.
var hold_deposit: bool=true
func deposit(owner: String,business: String) -> bool:
	if hold_deposit and owner=="cora" and business=="bakery": return false
	return super(owner,business)
func release_deposit() -> bool:
	hold_deposit=false
	return super.deposit("cora","bakery")
