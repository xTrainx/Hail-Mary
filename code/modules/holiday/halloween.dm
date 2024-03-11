///////////////////////////////////////
///////////HALLOWEEN CONTENT///////////
///////////////////////////////////////


//spooky recipes

/datum/recipe/sugarcookie/spookyskull
	reagents = list(/datum/reagent/consumable/flour = 5, /datum/reagent/consumable/sugar = 5, /datum/reagent/consumable/milk = 5)
	items = list(
		/obj/item/reagent_containers/food/snacks/egg,
	)
	result = /obj/item/reagent_containers/food/snacks/sugarcookie/spookyskull

/datum/recipe/sugarcookie/spookycoffin
	reagents = list(/datum/reagent/consumable/flour = 5, /datum/reagent/consumable/sugar = 5, /datum/reagent/consumable/coffee = 5)
	items = list(
		/obj/item/reagent_containers/food/snacks/egg,
	)
	result = /obj/item/reagent_containers/food/snacks/sugarcookie/spookycoffin

//////////////////////////////
//Spookoween trapped closets//
//////////////////////////////

#define SPOOKY_SKELETON 1
#define ANGRY_FAITHLESS 2
#define SCARY_BATS 		3
#define HOWLING_GHOST	4

//Spookoween variables
/obj/structure/closet
	var/trapped = 0
	var/mob/trapped_mob

/obj/structure/closet/initialize()
	..()
	if(prob(30))
		set_spooky_trap()

/obj/structure/closet/dump_contents()
	..()
	trigger_spooky_trap()

TYPE_PROC_REF(/obj/structure/closet, set_spooky_trap)()
	if(prob(1))
		trapped = ANGRY_FAITHLESS
		return
	if(prob(15))
		trapped = SCARY_BATS
		return
	if(prob(20))
		trapped = HOWLING_GHOST
		return
	else
		var/mob/living/carbon/human/H = new(loc)
		H.makeSkeleton()
		H.health = 1e5
		insert(H)
		trapped_mob = H
		trapped = SPOOKY_SKELETON
		return

TYPE_PROC_REF(/obj/structure/closet, trigger_spooky_trap)()
	if(!trapped)
		return

	else if(trapped == SPOOKY_SKELETON)
		visible_message("<span class='userdanger'><font size='5'>BOO!</font></span>")
		playsound(loc, 'sound/spookoween/girlscream.ogg', 300, 1)
		trapped = 0
		QDEL_IN(trapped_mob, 90)

	else if(trapped == HOWLING_GHOST)
		visible_message("<span class='userdanger'><font size='5'>[pick("OooOOooooOOOoOoOOooooOOOOO", "BooOOooOooooOOOO", "BOO!", "WoOOoOoooOooo")]</font></span>")
		playsound(loc, 'sound/spookoween/ghosty_wind.ogg', 300, 1)
		new /mob/living/simple_animal/shade/howling_ghost(loc)
		trapped = 0

	else if(trapped == SCARY_BATS)
		visible_message("<span class='userdanger'><font size='5'>Protect your hair!</font></span>")
		playsound(loc, 'sound/spookoween/bats.ogg', 300, 1)
		var/number = rand(1,3)
		for(var/i=0,i < number,i++)
			new /mob/living/simple_animal/hostile/retaliate/bat(loc)
		trapped = 0

	else if(trapped == ANGRY_FAITHLESS)
		visible_message(span_userdanger("The closet bursts open!"))
		visible_message("<span class='userdanger'><font size='5'>THIS BEING RADIATES PURE EVIL! YOU BETTER RUN!!!</font></span>")
		playsound(loc, 'sound/hallucinations/wail.ogg', 300, 1)
		var/mob/living/simple_animal/hostile/faithless/F = new(loc)
		trapped = 0
		QDEL_IN(F, 120)

//don't spawn in crates
/obj/structure/closet/crate/trigger_spooky_trap()
	return

/obj/structure/closet/crate/set_spooky_trap()
	return


////////////////////
//Spookoween Ghost//
////////////////////

/mob/living/simple_animal/shade/howling_ghost
	name = "ghost"
	real_name = "ghost"
	icon = 'icons/mob/mob.dmi'
	maxHealth = 1e6
	health = 1e6
	speak_emote = list("howls")
	emote_hear = list("wails","screeches")
	density = FALSE
	anchored = TRUE
	incorporeal_move = 1
	layer = 4
	var/timer = 0

/mob/living/simple_animal/shade/howling_ghost/Initialize()
	. = ..()
	icon_state = pick("ghost","ghostian","ghostian2","ghostking","ghost1","ghost2")
	icon_living = icon_state
	status_flags |= GODMODE
	timer = rand(1,15)

/mob/living/simple_animal/shade/howling_ghost/Life()
	..()
	timer--
	if(prob(20))
		roam()
	if(timer == 0)
		spooky_ghosty()
		timer = rand(1,15)

TYPE_PROC_REF(/mob/living/simple_animal/shade/howling_ghost, EtherealMove)(direction)
	forceMove(get_step(src, direction))
	setDir(direction)

TYPE_PROC_REF(/mob/living/simple_animal/shade/howling_ghost, roam)()
	if(prob(80))
		var/direction = pick(NORTH,SOUTH,EAST,WEST,NORTHEAST,NORTHWEST,SOUTHEAST,SOUTHWEST)
		EtherealMove(direction)

TYPE_PROC_REF(/mob/living/simple_animal/shade/howling_ghost, spooky_ghosty)()
	if(prob(20)) //haunt
		playsound(loc, pick('sound/spookoween/ghosty_wind.ogg','sound/spookoween/ghost_whisper.ogg','sound/spookoween/chain_rattling.ogg'), 300, 1)
	if(prob(10)) //flickers
		var/obj/machinery/light/L = locate(/obj/machinery/light) in view(5, src)
		if(L)
			L.flicker()
	if(prob(5)) //poltergeist
		var/obj/item/I = locate(/obj/item) in view(3, src)
		if(I)
			var/direction = pick(NORTH,SOUTH,EAST,WEST,NORTHEAST,NORTHWEST,SOUTHEAST,SOUTHWEST)
			step(I,direction)
		return

/mob/living/simple_animal/shade/howling_ghost/adjustHealth()
	. = 0

/mob/living/simple_animal/shade/howling_ghost/CanAllowThrough(atom/movable/mover, border_dir)
	..()
	return 1

/////////////////////////
// Spooky Uplink Items //
/////////////////////////

/datum/uplink_item/dangerous/crossbow/candy
	name = "Candy Corn Crossbow"
	desc = "A standard miniature energy crossbow that uses a hard-light projector to transform bolts into candy corn. Happy Halloween!"
	category = "Holiday"
	item = /obj/item/gun/energy/kinetic_accelerator/crossbow/halloween
	surplus = 0

/datum/uplink_item/device_tools/emag/hack_o_lantern
	name = "Hack-o'-Lantern"
	desc = "An emag fitted to support the Halloween season. Candle not included."
	category = "Holiday"
	item = /obj/item/card/emag/halloween
	surplus = 0
