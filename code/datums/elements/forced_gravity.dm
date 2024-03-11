/datum/element/forced_gravity
	element_flags = ELEMENT_BESPOKE
	id_arg_index = 2
	var/gravity
	var/ignore_space

/datum/element/forced_gravity/Attach(datum/target, gravity=1, ignore_space=FALSE)
	. = ..()
	if(!isatom(target))
		return ELEMENT_INCOMPATIBLE

	src.gravity = gravity
	src.ignore_space = ignore_space

	RegisterSignal(target, COMSIG_ATOM_HAS_GRAVITY, PROC_REF(gravity_check))
	if(isturf(target))
		RegisterSignal(target, COMSIG_TURF_HAS_GRAVITY, PROC_REF(turf_gravity_check))

/datum/element/forced_gravity/Detach(datum/source, force)
	. = ..()
	var/static/list/signals_b_gone = list(COMSIG_ATOM_HAS_GRAVITY, COMSIG_TURF_HAS_GRAVITY)
	UnregisterSignal(source, signals_b_gone)

TYPE_PROC_REF(/datum/element/forced_gravity, gravity_check)(datum/source, turf/location, list/gravs)
	if(!ignore_space && isspaceturf(location))
		return
	gravs += gravity

TYPE_PROC_REF(/datum/element/forced_gravity, turf_gravity_check)(datum/source, atom/checker, list/gravs)
	return gravity_check(null, source, gravs)
