/*
 * Don't use the apostrophe in name or desc. Causes script errors.
 * TODO: combine atleast some of the functionality with /proc_holder/spell
 */

/obj/effect/proc_holder/changeling
	panel = "Changeling"
	name = "Prototype Sting"
	desc = "" // Fluff
	var/helptext = "" // Details
	var/chemical_cost = 0 // negative chemical cost is for passive abilities (chemical glands)
	var/dna_cost = -1 //cost of the sting in dna points. 0 = auto-purchase, -1 = cannot be purchased
	var/req_dna = 0  //amount of dna needed to use this ability. Changelings always have atleast 1
	var/req_human = 0 //if you need to be human to use this ability
	var/req_absorbs = 0 //similar to req_dna, but only gained from absorbing, not DNA sting
	var/req_stat = CONSCIOUS // CONSCIOUS, UNCONSCIOUS or DEAD
	var/always_keep = 0 // important for abilities like revive that screw you if you lose them.
	var/ignores_fakedeath = FALSE // usable with the FAKEDEATH flag
	var/loudness = 0 //Determines how much having this ability will affect changeling blood tests. At 4, the blood will react violently and turn to ash, creating a unique message in the process. At 10, the blood will explode when heated.


TYPE_PROC_REF(/obj/effect/proc_holder/changeling, on_purchase)(mob/user, is_respec)
	action.Grant(user)
	if(!is_respec)
		SSblackbox.record_feedback("tally", "changeling_power_purchase", 1, name)

TYPE_PROC_REF(/obj/effect/proc_holder/changeling, on_refund)(mob/user)
	action.Remove(user)
	return

/obj/effect/proc_holder/changeling/Trigger(mob/user)
	if(!user || !user.mind || !user.mind.has_antag_datum(/datum/antagonist/changeling))
		return
	try_to_sting(user)

TYPE_PROC_REF(/obj/effect/proc_holder/changeling, try_to_sting)(mob/user, mob/target)
	if(!can_sting(user, target))
		return
	var/datum/antagonist/changeling/c = user.mind.has_antag_datum(/datum/antagonist/changeling)
	if(sting_action(user, target))
		SSblackbox.record_feedback("nested tally", "changeling_powers", 1, list("[name]"))
		sting_feedback(user, target)
		c.chem_charges -= chemical_cost

TYPE_PROC_REF(/obj/effect/proc_holder/changeling, sting_action)(mob/user, mob/target)
	return 0

TYPE_PROC_REF(/obj/effect/proc_holder/changeling, sting_feedback)(mob/user, mob/target)
	return 0

//Fairly important to remember to return 1 on success >.<
TYPE_PROC_REF(/obj/effect/proc_holder/changeling, can_sting)(mob/living/user, mob/target)
	if(!ishuman(user) && !ismonkey(user)) //typecast everything from mob to carbon from this point onwards
		return 0
	if(req_human && !ishuman(user))
		to_chat(user, span_warning("We cannot do that in this form!"))
		return 0
	var/datum/antagonist/changeling/c = user.mind.has_antag_datum(/datum/antagonist/changeling)
	if(c.chem_charges < chemical_cost)
		to_chat(user, span_warning("We require at least [chemical_cost] unit\s of chemicals to do that!"))
		return 0
	if(c.absorbedcount < req_dna)
		to_chat(user, span_warning("We require at least [req_dna] sample\s of compatible DNA."))
		return 0
	if(c.trueabsorbs < req_absorbs)
		to_chat(user, span_warning("We require at least [req_absorbs] sample\s of DNA gained through our Absorb ability."))
	if(req_stat < user.stat)
		to_chat(user, span_warning("We are incapacitated."))
		return 0
	if((HAS_TRAIT(user, TRAIT_DEATHCOMA)) && (!ignores_fakedeath))
		to_chat(user, span_warning("We are incapacitated."))
		return 0
	return 1

//used in /mob/Stat()
TYPE_PROC_REF(/obj/effect/proc_holder/changeling, can_be_used_by)(mob/user)
	if(QDELETED(user))
		return FALSE
	if(!ishuman(user) && !ismonkey(user))
		return FALSE
	if(req_human && !ishuman(user))
		return FALSE
	return TRUE
