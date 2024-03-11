/turf
	icon = 'icons/turf/floors.dmi'
	level = 1
	vis_flags = VIS_INHERIT_PLANE|VIS_INHERIT_ID	//when this be added to vis_contents of something it inherit something.plane and be associatet with something on clicking,
													//important for visualisation of turf in openspace and interraction with openspace that show you turf.

	var/intact = 1

	// baseturfs can be either a list or a single turf type.
	// In class definition like here it should always be a single type.
	// A list will be created in initialization that figures out the baseturf's baseturf etc.
	// In the case of a list it is sorted from bottom layer to top.
	// This shouldn't be modified directly, use the helper procs.
	var/list/baseturfs = /turf/open/indestructible/ground/outside/desert

	var/initial_temperature = T20C
	var/to_be_destroyed = 0 //Used for fire, if a melting temperature was reached, it will be destroyed
	var/max_fire_temperature_sustained = 0 //The max temperature of the fire which it was subjected to

	var/blocks_air = FALSE

	flags_1 = CAN_BE_DIRTY_1

	var/list/image/blueprint_data //for the station blueprints, images of objects eg: pipes

	var/explosion_level = 0	//for preventing explosion dodging
	var/explosion_id = 0

	/// Wether this turf is affected by sunlight, neighbor to turfs that are, or neither.
	var/sunlight_state = NO_SUNLIGHT
	/// If neighbor to affected turfs, which neighbors. Uses smoothing adjacencies values.
	var/border_neighbors = null

	var/requires_activation	//add to air processing after initialize?
	var/changing_turf = FALSE

	var/bullet_bounce_sound = 'sound/weapons/bulletremove.ogg' //sound played when a shell casing is ejected ontop of the turf.
	var/bullet_sizzle = FALSE //used by ammo_casing/bounce_away() to determine if the shell casing should make a sizzle sound when it's ejected over the turf
							//IE if the turf is supposed to be water, set TRUE.

	var/tiled_dirt = FALSE // use smooth tiled dirt decal

	///Lumcount added by sources other than lighting datum objects, such as the overlay lighting component.
	var/dynamic_lumcount = 0

	///Which directions does this turf block the vision of, taking into account both the turf's opacity and the movable opacity_sources.
	var/directional_opacity = NONE
	///The turf's opacity were there no opacity sources.
	var/base_opacity = FALSE
	///Lazylist of movable atoms providing opacity sources.
	var/list/atom/movable/opacity_sources


/turf/vv_edit_var(var_name, var_value)
	var/static/list/banned_edits = list("x", "y", "z")
	if(var_name in banned_edits)
		return FALSE
	switch(var_name)
		if(NAMEOF(src, base_opacity))
			set_base_opacity(var_value)
			return  TRUE
	return ..()


/turf/Initialize(mapload)
	SHOULD_CALL_PARENT(FALSE)
	if(flags_1 & INITIALIZED_1)
		stack_trace("Warning: [src]([type]) initialized multiple times!")
	flags_1 |= INITIALIZED_1

	// by default, vis_contents is inherited from the turf that was here before
	vis_contents.Cut()

	if(color)
		add_atom_colour(color, FIXED_COLOUR_PRIORITY)

	assemble_baseturfs()

	levelupdate()
	if(smooth)
		queue_smooth(src)
	visibilityChanged()

	if(initial(opacity)) // Could be changed by the initialization of movable atoms in the turf.
		base_opacity = initial(opacity)
		directional_opacity = ALL_CARDINALS

	for(var/atom/movable/AM in src)
		Entered(AM)

	var/area/A = loc
	if(!IS_DYNAMIC_LIGHTING(src) && IS_DYNAMIC_LIGHTING(A))
		add_overlay(/obj/effect/fullbright)
	else
		if(A.outdoors == TRUE)
			sunlight_state = SUNLIGHT_SOURCE
		switch(sunlight_state)
			if(SUNLIGHT_SOURCE)
				setup_sunlight_source()
			if(SUNLIGHT_BORDER)
				border_neighbors = null
				smooth_sunlight_border()

	if(requires_activation)
		CALCULATE_ADJACENT_TURFS(src)

	if (light_power && light_range)
		update_light()

	var/turf/T = SSmapping.get_turf_above(src)
	if(T)
		T.multiz_turf_new(src, DOWN)
		SEND_SIGNAL(T, COMSIG_TURF_MULTIZ_NEW, src, DOWN)
	T = SSmapping.get_turf_below(src)
	if(T)
		T.multiz_turf_new(src, UP)
		SEND_SIGNAL(T, COMSIG_TURF_MULTIZ_NEW, src, UP)

	// apply materials properly from the default custom_materials value
	set_custom_materials(custom_materials)

	ComponentInitialize()
	if(density)
		update_air_ref(-1)
	__auxtools_update_turf_temp_info(FALSE)

	return INITIALIZE_HINT_NORMAL

TYPE_PROC_REF(/turf, __auxtools_update_turf_temp_info)()

/turf/return_temperature()

TYPE_PROC_REF(/turf, set_temperature)()


TYPE_PROC_REF(/turf, Initialize_Atmos)(times_fired)
	CALCULATE_ADJACENT_TURFS(src)

/turf/Destroy(force)
	. = QDEL_HINT_IWILLGC
	if(!changing_turf)
		stack_trace("Incorrect turf deletion")
	changing_turf = FALSE
	var/turf/T = SSmapping.get_turf_above(src)
	if(T)
		T.multiz_turf_del(src, DOWN)
	T = SSmapping.get_turf_below(src)
	if(T)
		T.multiz_turf_del(src, UP)
	if(force)
		..()
		//this will completely wipe turf state
		var/turf/B = new world.turf(src)
		for(var/A in B.contents)
			qdel(A)
		for(var/I in B.vars)
			B.vars[I] = null
		return
	visibilityChanged()
	QDEL_LIST(blueprint_data)
	flags_1 &= ~INITIALIZED_1
	requires_activation = FALSE
	..()

/turf/on_attack_hand(mob/user, act_intent = user.a_intent, unarmed_attack_flags)
	user.Move_Pulled(src)

TYPE_PROC_REF(/turf, multiz_turf_del)(turf/T, dir)

TYPE_PROC_REF(/turf, multiz_turf_new)(turf/T, dir)

//zPassIn doesn't necessarily pass an atom!
//direction is direction of travel of air
TYPE_PROC_REF(/turf, zPassIn)(atom/movable/A, direction, turf/source)
	return FALSE

//direction is direction of travel of air
TYPE_PROC_REF(/turf, zPassOut)(atom/movable/A, direction, turf/destination)
	return FALSE

//direction is direction of travel of air
TYPE_PROC_REF(/turf, zAirIn)(direction, turf/source)
	return FALSE

//direction is direction of travel of air
TYPE_PROC_REF(/turf, zAirOut)(direction, turf/source)
	return FALSE

TYPE_PROC_REF(/turf, zImpact)(atom/movable/falling, levels = 1, turf/prev_turf)
	var/flags = NONE
	var/list/falling_movables = falling.get_z_move_affected()
	var/list/falling_mov_names
	for(var/atom/movable/falling_mov as anything in falling_movables)
		falling_mov_names += falling_mov.name
	for(var/i in contents)
		var/atom/thing = i
		flags |= thing.intercept_zImpact(falling_movables, levels)
		if(flags & FALL_STOP_INTERCEPTING)
			break
	if(prev_turf && !(flags & FALL_NO_MESSAGE))
		for(var/mov_name in falling_mov_names)
			prev_turf.visible_message(span_danger("[mov_name] falls through [prev_turf]!"))
	if(!(flags & FALL_INTERCEPTED) && zFall(falling, levels + 1))
		return FALSE
	for(var/atom/movable/falling_mov as anything in falling_movables)
		if(!(flags & FALL_RETAIN_PULL))
			falling_mov.stop_pulling()
		if(!(flags & FALL_INTERCEPTED))
			falling_mov.onZImpact(src, levels)
		if(falling_mov.pulledby && (falling_mov.z != falling_mov.pulledby.z || get_dist(falling_mov, falling_mov.pulledby) > 1))
			falling_mov.pulledby.stop_pulling()
	return TRUE

TYPE_PROC_REF(/turf, can_zFall)(atom/movable/A, levels = 1, turf/target)
	return zPassOut(A, DOWN, target) && target.zPassIn(A, DOWN, src)

TYPE_PROC_REF(/turf, zFall)(atom/movable/A, levels = 1, force = FALSE, falling_from_move = FALSE)
	var/turf/target = get_step_multiz(src, DOWN)
	if(!target || (!isobj(A) && !ismob(A)))
		return FALSE
	if(!force && (!can_zFall(A, levels, target) || !A.can_zFall(src, levels, target, DOWN)))
		return FALSE
	A.zfalling = TRUE
	A.zMove(DOWN, target, ZMOVE_CHECK_PULLEDBY)
	A.zfalling = FALSE
	target.zImpact(A, levels, src)
	return TRUE

TYPE_PROC_REF(/turf, handleRCL)(obj/item/rcl/C, mob/user)
	if(C.loaded)
		for(var/obj/structure/cable/LC in src)
			if(!LC.d1 || !LC.d2)
				LC.handlecable(C, user)
				return
		C.loaded.place_turf(src, user)
		if(C.wiring_gui_menu)
			C.wiringGuiUpdate(user)
		C.is_empty(user)

/turf/attackby(obj/item/C, mob/user, params)
	if(..())
		return TRUE
	if(can_lay_cable() && istype(C, /obj/item/stack/cable_coil))
		var/obj/item/stack/cable_coil/coil = C
		for(var/obj/structure/cable/LC in src)
			if(!LC.d1 || !LC.d2)
				LC.attackby(C,user)
				return
		coil.place_turf(src, user)
		return TRUE

	else if(istype(C, /obj/item/rcl))
		handleRCL(C, user)

	return FALSE

/turf/CanAllowThrough(atom/movable/mover)
	..()
	if(istype(mover)) // turf/Enter(...) will perform more advanced checks
		return !density

	stack_trace("Non movable passed to turf CanPass : [mover]")
	return FALSE

/turf/Enter(atom/movable/mover, atom/oldloc)
	// Do not call ..()
	// Byond's default turf/Enter() doesn't have the behaviour we want with Bump()
	// By default byond will call Bump() on the first dense object in contents
	// Here's hoping it doesn't stay like this for years before we finish conversion to step_
	var/atom/firstbump
	if(!CanPass(mover))
		firstbump = src
	else
		for(var/i in contents)
			if(i == mover || i == mover.loc) // Multi tile objects and moving out of other objects
				continue
			if(QDELETED(mover))
				break
			var/atom/movable/thing = i
			if(!thing.Cross(mover))
				if(CHECK_BITFIELD(mover.movement_type, UNSTOPPABLE))
					mover.Bump(thing)
					continue
				else
					if(!firstbump || ((thing.layer > firstbump.layer || thing.flags_1 & ON_BORDER_1) && !(firstbump.flags_1 & ON_BORDER_1)))
						firstbump = thing
	if(firstbump)
		if(!QDELETED(mover))
			mover.Bump(firstbump)
		return CHECK_BITFIELD(mover.movement_type, UNSTOPPABLE)
	return TRUE

/turf/Entered(atom/movable/AM)
	..()
	if(explosion_level && AM.ex_check(explosion_id))
		AM.ex_act(explosion_level)


/turf/open/Entered(atom/movable/AM)
	..()
	//melting
	if(isobj(AM) && air && air.return_temperature() > T0C)
		var/obj/O = AM
		if(O.obj_flags & FROZEN)
			O.make_unfrozen()

	// if(!AM.zfalling)
	// 	zFall(AM)

TYPE_PROC_REF(/turf, is_plasteel_floor)()
	return FALSE

// A proc in case it needs to be recreated or badmins want to change the baseturfs
TYPE_PROC_REF(/turf, assemble_baseturfs)(turf/fake_baseturf_type)
	var/static/list/created_baseturf_lists = list()
	var/turf/current_target
	if(fake_baseturf_type)
		if(length(fake_baseturf_type)) // We were given a list, just apply it and move on
			baseturfs = fake_baseturf_type
			return
		current_target = fake_baseturf_type
	else
		if(length(baseturfs))
			return // No replacement baseturf has been given and the current baseturfs value is already a list/assembled
		if(!baseturfs)
			current_target = initial(baseturfs) || type // This should never happen but just in case...
			stack_trace("baseturfs var was null for [type]. Failsafe activated and it has been given a new baseturfs value of [current_target].")
		else
			current_target = baseturfs

	// If we've made the output before we don't need to regenerate it
	if(created_baseturf_lists[current_target])
		var/list/premade_baseturfs = created_baseturf_lists[current_target]
		if(length(premade_baseturfs))
			baseturfs = premade_baseturfs.Copy()
		else
			baseturfs = premade_baseturfs
		return baseturfs

	var/turf/next_target = initial(current_target.baseturfs)
	//Most things only have 1 baseturf so this loop won't run in most cases
	if(current_target == next_target)
		baseturfs = current_target
		created_baseturf_lists[current_target] = current_target
		return current_target
	var/list/new_baseturfs = list(current_target)
	for(var/i=0;current_target != next_target;i++)
		if(i > 100)
			// A baseturfs list over 100 members long is silly
			// Because of how this is all structured it will only runtime/message once per type
			stack_trace("A turf <[type]> created a baseturfs list over 100 members long. This is most likely an infinite loop.")
			message_admins("A turf <[type]> created a baseturfs list over 100 members long. This is most likely an infinite loop.")
			break
		new_baseturfs.Insert(1, next_target)
		current_target = next_target
		next_target = initial(current_target.baseturfs)

	baseturfs = new_baseturfs
	created_baseturf_lists[new_baseturfs[new_baseturfs.len]] = new_baseturfs.Copy()
	return new_baseturfs

TYPE_PROC_REF(/turf, levelupdate)()
	for(var/obj/O in src)
		if(O.level == 1 && (O.flags_1 & INITIALIZED_1))
			O.hide(src.intact)

// override for space turfs, since they should never hide anything
/turf/open/space/levelupdate()
	for(var/obj/O in src)
		if(O.level == 1 && (O.flags_1 & INITIALIZED_1))
			O.hide(0)

// Removes all signs of lattice on the pos of the turf -Donkieyo
TYPE_PROC_REF(/turf, RemoveLattice)()
	var/obj/structure/lattice/L = locate(/obj/structure/lattice, src)
	if(L && (L.flags_1 & INITIALIZED_1))
		qdel(L)

TYPE_PROC_REF(/turf, phase_damage_creatures)(damage,mob/U = null)//>Ninja Code. Hurts and knocks out creatures on this turf //NINJACODE
	for(var/mob/living/M in src)
		if(M==U)
			continue//Will not harm U. Since null != M, can be excluded to kill everyone.
		M.adjustBruteLoss(damage)
		M.Unconscious(damage * 4)
	for(var/obj/mecha/M in src)
		M.take_damage(damage*2, BRUTE, "melee", 1)

TYPE_PROC_REF(/turf, Bless)()
	new /obj/effect/blessing(src)

/turf/storage_contents_dump_act(datum/component/storage/src_object, mob/user)
	. = ..()
	if(.)
		return
	if(length(src_object.contents()))
		to_chat(user, span_notice("You start dumping out the contents..."))
		if(!do_after(user,20,target=src_object.parent))
			return FALSE

	var/list/things = src_object.contents()
	var/datum/progressbar/progress = new(user, things.len, src)
	while (do_after(user, 10, TRUE, src, FALSE, CALLBACK(src_object, /datum/component/storage.proc/mass_remove_from_storage, src, things, progress)))
		stoplag(1)
	qdel(progress)

	return TRUE

//////////////////////////////
//Distance procs
//////////////////////////////

//Distance associates with all directions movement
TYPE_PROC_REF(/turf, Distance)(turf/T)
	return get_dist(src,T)

//  This Distance proc assumes that only cardinal movement is
//  possible. It results in more efficient (CPU-wise) pathing
//  for bots and anything else that only moves in cardinal dirs.
TYPE_PROC_REF(/turf, Distance_cardinal)(turf/T)
	if(!src || !T)
		return FALSE
	return abs(x - T.x) + abs(y - T.y)

////////////////////////////////////////////////////

/turf/singularity_act()
	if(intact)
		for(var/obj/O in contents) //this is for deleting things like wires contained in the turf
			if(O.level != 1)
				continue
			if(O.invisibility == INVISIBILITY_MAXIMUM)
				O.singularity_act()
	ScrapeAway(flags = CHANGETURF_INHERIT_AIR)
	return(2)

TYPE_PROC_REF(/turf, can_have_cabling)()
	return TRUE

TYPE_PROC_REF(/turf, can_lay_cable)()
	return can_have_cabling() & !intact

TYPE_PROC_REF(/turf, visibilityChanged)()
	GLOB.cameranet.updateVisibility(src)
	// The cameranet usually handles this for us, but if we've just been
	// recreated we should make sure we have the cameranet vis_contents.
	var/datum/camerachunk/C = GLOB.cameranet.chunkGenerated(x, y, z)
	if(C)
		if(C.obscuredTurfs[src])
			vis_contents += GLOB.cameranet.vis_contents_objects
		else
			vis_contents -= GLOB.cameranet.vis_contents_objects

TYPE_PROC_REF(/turf, burn_tile)()

TYPE_PROC_REF(/turf, is_shielded)()

/turf/contents_explosion(severity, target)
	var/affecting_level
	if(severity == 1)
		affecting_level = 1
	else if(is_shielded())
		affecting_level = 3
	else if(intact)
		affecting_level = 2
	else
		affecting_level = 1

	for(var/V in contents)
		var/atom/A = V
		if(!QDELETED(A) && A.level >= affecting_level)
			if(ismovable(A))
				var/atom/movable/AM = A
				if(!AM.ex_check(explosion_id))
					continue
			A.ex_act(severity, target)
			CHECK_TICK

/turf/narsie_act(force, ignore_mobs, probability = 20)
	. = (prob(probability) || force)
	for(var/I in src)
		var/atom/A = I
		if(ignore_mobs && ismob(A))
			continue
		if(ismob(A) || .)
			A.narsie_act()

/turf/ratvar_act(force, ignore_mobs, probability = 40)
	. = (prob(probability) || force)
	for(var/I in src)
		var/atom/A = I
		if(ignore_mobs && ismob(A))
			continue
		if(ismob(A) || .)
			A.ratvar_act()

//called on TYPE_PROC_REF(/datum/species, altdisarm)()
/turf/shove_act(mob/living/target, mob/living/user, pre_act = FALSE)
	var/list/possibilities
	for(var/obj/O in contents)
		if(CHECK_BITFIELD(O.obj_flags, SHOVABLE_ONTO))
			LAZYADD(possibilities, O)
		else if(!O.CanPass(target))
			return FALSE
	if(possibilities)
		var/obj/O = pick(possibilities)
		return O.shove_act(target, user)
	return FALSE

TYPE_PROC_REF(/turf, get_smooth_underlay_icon)(mutable_appearance/underlay_appearance, turf/asking_turf, adjacency_dir)
	underlay_appearance.icon = icon
	underlay_appearance.icon_state = icon_state
	underlay_appearance.dir = adjacency_dir
	return TRUE

TYPE_PROC_REF(/turf, add_blueprints)(atom/movable/AM)
	var/image/I = new
	I.appearance = AM.appearance
	I.appearance_flags = RESET_COLOR|RESET_ALPHA|RESET_TRANSFORM
	I.loc = src
	I.setDir(AM.dir)
	I.alpha = 128

	LAZYADD(blueprint_data, I)


TYPE_PROC_REF(/turf, add_blueprints_preround)(atom/movable/AM)
	if(!SSticker.HasRoundStarted())
		add_blueprints(AM)

TYPE_PROC_REF(/turf, is_transition_turf)()
	return

/turf/acid_act(acidpwr, acid_volume)
	. = 1
	var/acid_type = /obj/effect/acid
	if(acidpwr >= 200) //alien acid power
		acid_type = /obj/effect/acid/alien
	var/has_acid_effect = FALSE
	for(var/obj/O in src)
		if(intact && O.level == 1) //hidden under the floor
			continue
		if(istype(O, acid_type))
			var/obj/effect/acid/A = O
			A.acid_level = min(A.level + acid_volume * acidpwr, 12000)//capping acid level to limit power of the acid
			has_acid_effect = 1
			continue
		O.acid_act(acidpwr, acid_volume)
	if(!has_acid_effect)
		new acid_type(src, acidpwr, acid_volume)

TYPE_PROC_REF(/turf, acid_melt)()
	return

/turf/handle_fall(mob/faller, forced)
	faller.lying = pick(90, 270)
	if(!forced)
		return
	if(has_gravity(src))
		playsound(src, "bodyfall", 50, 1)
	faller.drop_all_held_items()

TYPE_PROC_REF(/turf, photograph)(limit=20)
	var/image/I = new()
	I.add_overlay(src)
	for(var/V in contents)
		var/atom/A = V
		if(A.invisibility)
			continue
		I.add_overlay(A)
		if(limit)
			limit--
		else
			return I
	return I

/turf/AllowDrop()
	return TRUE

TYPE_PROC_REF(/turf, add_vomit_floor)(mob/living/M, toxvomit = NONE)

	var/obj/effect/decal/cleanable/vomit/V = new /obj/effect/decal/cleanable/vomit(src, M.get_static_viruses())
	//if the vomit combined, apply toxicity and reagents to the old vomit
	if (QDELETED(V))
		V = locate() in src
	if(!V) //the decal was spawned on a wall or groundless turf and promptly qdeleted.
		return
	// Make toxins and blazaam vomit look different
	if(toxvomit == VOMIT_PURPLE)
		V.icon_state = "vomitpurp_[pick(1,4)]"
	else if (toxvomit == VOMIT_TOXIC)
		V.icon_state = "vomittox_[pick(1,4)]"
	if (iscarbon(M))
		var/mob/living/carbon/C = M
		if(C.reagents)
			clear_reagents_to_vomit_pool(C,V)

/proc/clear_reagents_to_vomit_pool(mob/living/carbon/M, obj/effect/decal/cleanable/vomit/V)
	for(var/datum/reagent/consumable/R in M.reagents.reagent_list)                //clears the stomach of anything that might be digested as food
		if(R.nutriment_factor > 0)
			M.reagents.del_reagent(R.type)
	M.reagents.trans_to(V, M.reagents.total_volume / 10)

//Whatever happens after high temperature fire dies out or thermite reaction works.
//Should return new turf
TYPE_PROC_REF(/turf, Melt)()
	return ScrapeAway(flags = CHANGETURF_INHERIT_AIR)

/turf/bullet_act(obj/item/projectile/P)
	. = ..()
	if(. != BULLET_ACT_FORCE_PIERCE)
		. =  BULLET_ACT_TURF
