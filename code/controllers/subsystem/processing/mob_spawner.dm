// fuck it i'll just make it its own subsystem whatever
PROCESSING_SUBSYSTEM_DEF(spawners)
	name = "Spawners"
	flags = SS_BACKGROUND|SS_POST_FIRE_TIMING|SS_NO_INIT
	wait = 1 SECONDS
	priority = FIRE_PRIORITY_SPAWNERS

/// YEah so this used to be something, but then I messed up and all the mobs just
/// Went into their own spawners, and I liked that, so imma do that k
/// enjoy the commented out cood

// 	/// List of all the spawners in existance, by Z level
// 	/// format: list("1" = list(spawner, spawner, spawner))
// 	var/list/spawners = list()

// / When a spawner is made, add it to the list, by its Z level
// TYPE_PROC_REF(/datum/controller/subsystem/spawners, register_spawner)(atom/spwner)
// 	if(!spwner)
// 		return
// 	if(!islist(spawners["[spwner.z]"]))
// 		spawners["[spwner.z]"] = list()
// 	spawners["[spwner.z]"] |= spwner

// /// When a spawner is deleted, find it and remove it
// TYPE_PROC_REF(/datum/controller/subsystem/spawners, unregister_spawner)(atom/spwner)
// 	if(!spwner)
// 		return
// 	spawners["[spwner.z]"] -= spwner

// /// Finds the spawner closest to the mob
// TYPE_PROC_REF(/datum/controller/subsystem/spawners, nearest_spawner)(mob/living/simple_animal/hostile/unbirthme)
// 	if(!unbirthme)
// 		return
// 	var/list/nearest_spawners = list()
// 	for(var/atom/maybe_spawner in spawners["[unbirthme.z]"])
// 		if(get_dist(unbirthme, maybe_spawner) > 10)
// 			continue
// 		if(!SEND_SIGNAL(maybe_spawner, COMSIG_SPAWNER_EXISTS))
// 			continue
// 		nearest_spawners |= maybe_spawner
// 	var/atom/spawner
// 	if(!LAZYLEN(nearest_spawners)) // nothing near?
// 		spawner = new /obj/structure/nest(get_turf(unbirthme))
// 	else
// 		spawner = pick(nearest_spawners)
// 	if(istype(spawner))
// 		return spawner
