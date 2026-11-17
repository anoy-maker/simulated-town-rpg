extends "res://scripts/sim/learning_world.gd"
## Opt-in authority guard. Tokens are execution state, never canonical economic state.
var _planning_id: int=0
func hold_planning(id: int,previous: int=0) -> bool:
	if id<=previous or _planning_id!=previous or _day<1 or _space.minute!=745: return false
	_planning_id=id
	return true
func release_planning(id: int) -> bool:
	if id==0 or _planning_id!=id: return false
	_planning_id=0
	return true
func advance_time(target: Variant) -> bool:
	if _planning_id!=0 and target is int and target>_space.minute:
		return _reject("spatial_clock","world","",{"target":target},"planning_pending")
	return super(target)
func advance_day() -> void:
	if _planning_id!=0:
		_reject("spatial_day_advanced","world","",{},"planning_pending")
		return
	super()
