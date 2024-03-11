/obj/effect/particle_effect/expl_particles
	name = "fire"
	icon_state = "explosion_particle"
	opacity = 1
	anchored = TRUE

/obj/effect/particle_effect/expl_particles/Initialize()
	. = ..()
	QDEL_IN(src, 15)

/datum/effect_system/expl_particles
	number = 10

/datum/effect_system/expl_particles/start()
	for(var/i in 1 to number)
		var/obj/effect/particle_effect/expl_particles/expl = new /obj/effect/particle_effect/expl_particles(location)
		var/direct = pick(GLOB.alldirs)
		var/steps_amt = pick(1;25,2;50,3,4;200)
		for(var/j in 1 to steps_amt)
			addtimer(CALLBACK(GLOBAL_PROC, PROC_REF(_step), expl, direct), j)

/obj/effect/explosion
	name = "fire"
	icon = 'icons/effects/96x96.dmi'
	icon_state = "explosion"
	opacity = 1
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	pixel_x = -32
	pixel_y = -32

/obj/effect/explosion/Initialize()
	. = ..()
	QDEL_IN(src, 10)

/datum/effect_system/explosion

/datum/effect_system/explosion/set_up(loca)
	if(isturf(loca))
		location = loca
	else
		location = get_turf(loca)

/datum/effect_system/explosion/start()
	new/obj/effect/explosion( location )
	var/datum/effect_system/expl_particles/P = new/datum/effect_system/expl_particles()
	P.set_up(10, 0, location)
	P.start()

/datum/effect_system/explosion/smoke

TYPE_PROC_REF(/datum/effect_system/explosion/smoke, create_smoke)()
	var/datum/effect_system/smoke_spread/S = new
	S.set_up(2, location)
	S.start()
/datum/effect_system/explosion/smoke/start()
	..()
	addtimer(CALLBACK(src, PROC_REF(create_smoke)), 5)
