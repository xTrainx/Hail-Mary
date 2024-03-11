
/datum/antagonist/blood_contract
	name = "Blood Contract Target"
	show_in_roundend = FALSE
	show_in_antagpanel = FALSE

/datum/antagonist/blood_contract/on_gain()
	. = ..()
	give_objective()
	start_the_hunt()

TYPE_PROC_REF(/datum/antagonist/blood_contract, give_objective)()
	var/datum/objective/survive/survive = new
	survive.owner = owner
	objectives += survive

/datum/antagonist/blood_contract/greet()
	. = ..()
	to_chat(owner, span_userdanger("You've been marked for death! Don't let the demons get you! KILL THEM ALL!"))

TYPE_PROC_REF(/datum/antagonist/blood_contract, start_the_hunt)()
	var/mob/living/carbon/human/H = owner.current
	if(!istype(H))
		return
	H.add_atom_colour("#FF0000", ADMIN_COLOUR_PRIORITY)
	var/obj/effect/mine/pickup/bloodbath/B = new(H)
	INVOKE_ASYNC(B, TYPE_PROC_REF(/obj/effect/mine/pickup/bloodbath, mineEffect), H) //could use moving out from the mine

	for(var/mob/living/carbon/human/P in GLOB.player_list)
		if(P == H || HAS_TRAIT(P, TRAIT_NO_MIDROUND_ANTAG))
			continue
		to_chat(P, span_userdanger("You have an overwhelming desire to kill [H]. [H.p_theyve(TRUE)] been marked red! Whoever [H.p_they()] [H.p_were()], friend or foe, go kill [H.p_them()]!"))
		P.put_in_hands(new /obj/item/kitchen/knife/butcher(P), TRUE)
