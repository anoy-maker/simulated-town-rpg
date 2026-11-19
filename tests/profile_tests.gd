extends RefCounted
const Profile=preload("res://scripts/sim/execution_profile.gd")

static func _child() -> void:
	var _scope=Profile.scope("child") if Profile.enabled else null
	if Profile.enabled: Profile.count("work",7)

static func _parent() -> void:
	var _scope=Profile.scope("parent") if Profile.enabled else null
	_child()

static func run(suite) -> void:
	Profile.reset(false)
	_parent()
	suite._check(Profile.snapshot().phases.is_empty(),"profiling disabled by default leaves no measurements")
	Profile.reset(true)
	_parent()
	var data=Profile.snapshot()
	suite._check(data.counts.work==7 and data.phases.parent.calls==1 and data.phases.child.calls==1,"scoped profiler closes early/normal function exits and counts work")
	suite._check(data.phases.parent.inclusive_usec>=data.phases.child.inclusive_usec,"parent inclusive timing includes nested child")
	suite._check(data.phases.parent.exclusive_usec+data.phases.child.inclusive_usec==data.phases.parent.inclusive_usec,"exclusive phase timing subtracts child time exactly")
	Profile.reset(false)
	suite._check(Profile.snapshot().counts.is_empty() and not Profile.enabled,"profiling reset has no cross-run timing/cache state")
