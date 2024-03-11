/obj/item/organ/body_egg
	name = "body egg"
	desc = "All slimy and yuck."
	icon_state = "innards"
	zone = BODY_ZONE_CHEST
	slot = "parasite_egg"

/obj/item/organ/body_egg/on_find(mob/living/finder)
	..()
	to_chat(finder, span_warning("You found an unknown alien organism in [owner]'s [zone]!"))

/obj/item/organ/body_egg/New(loc)
	if(iscarbon(loc))
		src.Insert(loc)
	return ..()

/obj/item/organ/body_egg/Insert(mob/living/carbon/M, special = 0, drop_if_replaced = TRUE)
	..()
	ADD_TRAIT(owner, TRAIT_XENO_HOST, TRAIT_GENERIC)
	owner.med_hud_set_status()
	INVOKE_ASYNC(src, PROC_REF(AddInfectionImages), owner)

/obj/item/organ/body_egg/Remove(special = FALSE)
	if(!QDELETED(owner))
		REMOVE_TRAIT(owner, TRAIT_XENO_HOST, TRAIT_GENERIC)
		owner.med_hud_set_status()
		INVOKE_ASYNC(src, PROC_REF(RemoveInfectionImages), owner)
	return ..()

/obj/item/organ/body_egg/on_death()
	. = ..()
	if(!owner)
		return
	egg_process()

/obj/item/organ/body_egg/on_life()
	. = ..()
	egg_process()


TYPE_PROC_REF(/obj/item/organ/body_egg, egg_process)()
	return

TYPE_PROC_REF(/obj/item/organ/body_egg, RefreshInfectionImage)()
	RemoveInfectionImages()
	AddInfectionImages()

TYPE_PROC_REF(/obj/item/organ/body_egg, AddInfectionImages)(mob/living/carbon/C)
	return

TYPE_PROC_REF(/obj/item/organ/body_egg, RemoveInfectionImages)(mob/living/carbon/C)
	return
