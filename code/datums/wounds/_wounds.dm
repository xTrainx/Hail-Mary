/*
	Wounds are specific medical complications that can arise and be applied to (currently) carbons, with a focus on humans. All of the code for and related to this is heavily WIP,
	and the documentation will be slanted towards explaining what each part/piece is leading up to, until such a time as I finish the core implementations. The original design doc
	can be found at https://hackmd.io/@Ryll/r1lb4SOwU

	Wounds are datums that operate like a mix of diseases, brain traumas, and components, and are applied to a /obj/item/bodypart (preferably attached to a carbon) when they take large spikes of damage
	or under other certain conditions (thrown hard against a wall, sustained exposure to plasma fire, etc). Wounds are categorized by the three following criteria:
		1. Severity: Either MODERATE, SEVERE, or CRITICAL. See the hackmd for more details
		2. Viable zones: What body parts the wound is applicable to. Generic wounds like broken bones and severe burns can apply to every zone, but you may want to add special wounds for certain limbs
			like a twisted ankle for legs only, or open air exposure of the organs for particularly gruesome chest wounds. Wounds should be able to function for every zone they are marked viable for.
		3. Damage type: Currently either BRUTE or BURN. Again, see the hackmd for a breakdown of my plans for each type.

	When a body part suffers enough damage to get a wound, the severity (determined by a roll or something, worse damage leading to worse wounds), affected limb, and damage type sustained are factored into
	deciding what specific wound will be applied. I'd like to have a few different types of wounds for at least some of the choices, but I'm just doing rough generals for now. Expect polishing
*/

/datum/wound
	/// What it's named
	var/name = "ouchie"
	/// The description shown on the scanners
	var/desc = ""
	/// The basic treatment suggested by health analyzers
	var/treat_text = ""
	/// What the limb looks like on a cursory examine
	var/examine_desc = "is badly hurt"

	/// needed for "your arm has a compound fracture" vs "your arm has some third degree burns"
	var/a_or_from = "a"
	/// The visible message when this happens
	var/occur_text = ""
	/// The visible message when this is renewed
	var/renew_text = ""
	/// This sound will be played upon the wound being applied
	var/sound_effect

	/// Either WOUND_SEVERITY_TRIVIAL (meme wounds like stubbed toe), WOUND_SEVERITY_MODERATE, WOUND_SEVERITY_SEVERE, or WOUND_SEVERITY_CRITICAL (or maybe WOUND_SEVERITY_LOSS)
	var/severity = WOUND_SEVERITY_MODERATE
	/// The list of wounds it belongs in, WOUND_LIST_BLUNT, WOUND_LIST_SLASH, or WOUND_LIST_BURN
	var/wound_type

	/// What body zones can we affect
	var/list/viable_zones = list(BODY_ZONE_HEAD, BODY_ZONE_CHEST, BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
	/// Who owns the body part that we're wounding
	var/mob/living/carbon/victim = null
	/// The bodypart we're parented to
	var/obj/item/bodypart/limb = null

	/// Specific items such as bandages or sutures that can try directly treating this wound
	var/list/treatable_by
	/// Specific items such as bandages or sutures that can try directly treating this wound only if the user has the victim in an aggressive grab or higher
	var/list/treatable_by_grabbed
	/// Tools with the specified tool flag will also be able to try directly treating this wound
	var/treatable_tool
	/// How long it will take to treat this wound with a standard effective tool, assuming it doesn't need surgery
	var/base_treat_time = 5 SECONDS

	/// Using this limb in a do_after interaction will multiply the length by this duration (arms)
	var/interaction_efficiency_penalty = 1
	/// Incoming damage on this limb will be multiplied by this, to simulate tenderness and vulnerability (mostly burns).
	var/damage_mulitplier_penalty = 1
	/// If set and this wound is applied to a leg, we take this many deciseconds extra per step on this leg
	var/limp_slowdown
	/// How much we're contributing to this limb's bleed_rate
	var/blood_flow

	/// The minimum we need to roll on [TYPE_PROC_REF(/obj/item/bodypart, check_wounding)()] to begin suffering this wound, see check_wounding_mods() for more
	var/threshold_minimum
	/// How much having this wound will add to all future check_wounding() rolls on this limb, to allow progression to worse injuries with repeated damage
	var/threshold_penalty
	/// If we need to process each life tick
	var/processes = FALSE

	/// If having this wound makes currently makes the parent bodypart unusable
	var/disabling

	/// What status effect we assign on application
	var/status_effect_type
	/// The status effect we're linked to
	var/datum/status_effect/linked_status_effect
	/// If we're operating on this wound and it gets healed, we'll nix the surgery too
	var/datum/surgery/attached_surgery
	/// if you're a lazy git and just throw them in cryo, the wound will go away after accumulating severity * 25 power
	var/cryo_progress

	/// What kind of scars this wound will create description wise once healed
	var/scar_keyword = "generic"
	/// If we've already tried scarring while removing (since remove_wound calls qdel, and qdel calls remove wound, .....) TODO: make this cleaner
	var/already_scarred = FALSE
	/// If we forced this wound through badmin smite, we won't count it towards the round totals
	var/from_smite

	/// What flags apply to this wound
	var/wound_flags = (FLESH_WOUND | BONE_WOUND | ACCEPTS_GAUZE)

/datum/wound/Destroy()
	if(attached_surgery)
		QDEL_NULL(attached_surgery)
	if(limb?.wounds && (src in limb.wounds)) // destroy can call remove_wound() and remove_wound() calls qdel, so we check to make sure there's anything to remove first
		remove_wound()
	limb = null
	victim = null
	return ..()

/**
 * apply_wound() is used once a wound type is instantiated to assign it to a bodypart, and actually come into play.
 *
 *
 * Arguments:
 * * L: The bodypart we're wounding, we don't care about the person, we can get them through the limb
 * * silent: Not actually necessary I don't think, was originally used for demoting wounds so they wouldn't make new messages, but I believe old_wound took over that, I may remove this shortly
 * * old_wound: If our new wound is a replacement for one of the same time (promotion or demotion), we can reference the old one just before it's removed to copy over necessary vars
 * * smited- If this is a smite, we don't care about this wound for stat tracking purposes (not yet implemented)
 */
TYPE_PROC_REF(/datum/wound, apply_wound)(obj/item/bodypart/L, silent = FALSE, datum/wound/old_wound = null, smited = FALSE)
	if(!istype(L) || !L.owner || !(L.body_zone in viable_zones) || isalien(L.owner) || !(L.is_organic_limb() || L.render_like_organic))
		qdel(src)
		return

	if(ishuman(L.owner))
		var/mob/living/carbon/human/H = L.owner
		if(((wound_flags & BONE_WOUND) && !(HAS_BONE in H.dna.species.species_traits)) || ((wound_flags & FLESH_WOUND) && !(HAS_FLESH in H.dna.species.species_traits)))
			qdel(src)
			return

	// we accept promotions and demotions, but no point in redundancy. This should have already been checked wherever the wound was rolled and applied for (see: bodypart damage code), but we do an extra check
	// in case we ever directly add wounds
	for(var/i in L.wounds)
		var/datum/wound/preexisting_wound = i
		if((preexisting_wound.type == type) && (preexisting_wound != old_wound))
			qdel(src)
			return

	victim = L.owner
	limb = L
	LAZYADD(victim.all_wounds, src)
	LAZYADD(limb.wounds, src)
	limb.update_wounds()
	if(status_effect_type)
		linked_status_effect = victim.apply_status_effect(status_effect_type, src)
	SEND_SIGNAL(victim, COMSIG_CARBON_GAIN_WOUND, src, limb)
	if(!victim.alerts["wound"]) // only one alert is shared between all of the wounds
		victim.throw_alert("wound", /obj/screen/alert/status_effect/wound)

	var/demoted
	if(old_wound)
		demoted = (severity <= old_wound.severity)

	//if(severity == WOUND_SEVERITY_TRIVIAL)
	//	return

	if(!(silent || demoted))
		var/msg = span_danger("[victim]'s [limb.name] [occur_text]!")
		var/vis_dist = COMBAT_MESSAGE_RANGE

		if(severity != WOUND_SEVERITY_MODERATE)
			msg = "<b>[msg]</b>"
			vis_dist = DEFAULT_MESSAGE_RANGE

		victim.visible_message(msg, span_userdanger("Your [limb.name] [occur_text]!"), vision_distance = vis_dist)
		if(sound_effect)
			playsound(L.owner, sound_effect, 70 + 20 * severity, TRUE)

	if(!demoted)
		wound_injury(old_wound)
		second_wind()

/// Remove the wound from whatever it's afflicting, and cleans up whateverstatus effects it had or modifiers it had on interaction times. ignore_limb is used for detachments where we only want to forget the victim
TYPE_PROC_REF(/datum/wound, remove_wound)(ignore_limb, replaced = FALSE)
	//TODO: have better way to tell if we're getting removed without replacement (full heal) scar stuff
	if(limb && !already_scarred && !replaced)
		already_scarred = TRUE
		var/datum/scar/new_scar = new
		new_scar.generate(limb, src)
	if(victim)
		LAZYREMOVE(victim.all_wounds, src)
		if(!victim.all_wounds)
			victim.clear_alert("wound")
		SEND_SIGNAL(victim, COMSIG_CARBON_LOSE_WOUND, src, limb)
	if(limb && !ignore_limb)
		LAZYREMOVE(limb.wounds, src)
		limb.update_wounds(replaced)

/**
 * replace_wound() is used when you want to replace the current wound with a new wound, presumably of the same category, just of a different severity (either up or down counts)
 *
 * This proc actually instantiates the new wound based off the specific type path passed, then returns the new instantiated wound datum.
 *
 * Arguments:
 * * new_type- The TYPE PATH of the wound you want to replace this, like /datum/wound/bleed/slash/severe
 * * smited- If this is a smite, we don't care about this wound for stat tracking purposes (not yet implemented)
 */
TYPE_PROC_REF(/datum/wound, replace_wound)(new_type, smited = FALSE)
	var/datum/wound/new_wound = new new_type
	already_scarred = TRUE
	remove_wound(replaced=TRUE)
	new_wound.apply_wound(limb, old_wound = src, smited = smited)
	qdel(src)
	return new_wound

/// The immediate negative effects faced as a result of the wound
TYPE_PROC_REF(/datum/wound, wound_injury)(datum/wound/old_wound = null)
	return

/// Additional beneficial effects when the wound is gained, in case you want to give a temporary boost to allow the victim to try an escape or last stand
TYPE_PROC_REF(/datum/wound, second_wind)()
	var/add_determ
	switch(severity)
		if(WOUND_SEVERITY_TRIVIAL)
			add_determ = WOUND_DETERMINATION_MODERATE
		if(WOUND_SEVERITY_MODERATE)
			add_determ = WOUND_DETERMINATION_MODERATE
		if(WOUND_SEVERITY_SEVERE)
			add_determ = WOUND_DETERMINATION_SEVERE
		if(WOUND_SEVERITY_CRITICAL)
			add_determ = WOUND_DETERMINATION_CRITICAL
		if(WOUND_SEVERITY_LOSS)
			add_determ = WOUND_DETERMINATION_LOSS
	if(victim.has_reagent(/datum/reagent/determination))
		add_determ *= 0.5 // already determined? kinda demoralizing to keep getting FUCKED
	victim.reagents.add_reagent(/datum/reagent/determination, add_determ)

/**
 * try_treating() is an intercept run from [TYPE_PROC_REF(/mob/living/carbon, attackby)] right after surgeries but before anything else. Return TRUE here if the item is something that is relevant to treatment to take over the interaction.
 *
 * This proc leads into [TYPE_PROC_REF(/datum/wound, treat)] and probably shouldn't be added onto in children types. You can specify what items or tools you want to be intercepted
 * with var/list/treatable_by and var/treatable_tool, then if an item fulfills one of those requirements and our wound claims it first, it goes over to treat() and treat_self().
 *
 * Arguments:
 * * I: The item we're trying to use
 * * user: The mob trying to use it on us
 */
TYPE_PROC_REF(/datum/wound, try_treating)(obj/item/I, mob/user)
	// first we weed out if we're not dealing with our wound's bodypart, or if it might be an attack
	if(!I || limb.body_zone != user.zone_selected || (I.force && user.a_intent != INTENT_HELP))
		return FALSE

	var/allowed = FALSE

	// check if we have a valid treatable tool (or, if cauteries are allowed, if we have something hot)
	if((I.tool_behaviour == treatable_tool) || (treatable_tool == TOOL_CAUTERY && I.get_temperature()))
		allowed = TRUE
	// failing that, see if we're aggro grabbing them and if we have an item that works for aggro grabs only
	else if(user.pulling == victim && user.grab_state >= GRAB_AGGRESSIVE && check_grab_treatments(I, user))
		allowed = TRUE
	// failing THAT, we check if we have a generally allowed item
	else
		for(var/allowed_type in treatable_by)
			if(istype(I, allowed_type))
				allowed = TRUE
				break

	// if none of those apply, we return false to avoid interrupting
	if(!allowed)
		return FALSE

	// now that we've determined we have a valid attempt at treating, we can stomp on their dreams if we're already interacting with the patient
	if(INTERACTING_WITH(user, victim))
		to_chat(user, span_warning("You're already interacting with [victim]!"))
		return TRUE

	// lastly, treat them
	treat(I, user)
	return TRUE

/// Generic bleed wound treatment from whatever'll allow it
/// No messages, damage healing, or thing usage, they'll be handled on the item doing the healing
/// Currently unused
TYPE_PROC_REF(/datum/wound, treat_bleed)(obj/item/stack/medical/I, mob/user, self_applied = 0, effectiveness)
	if(!I.is_suture)
		return
	var/blood_sutured = I.is_suture * (I.self_penalty_effectiveness * self_applied * effectiveness)
	blood_flow -= blood_sutured
	//limb.heal_damage(I.heal_brute, I.heal_burn)

	if(blood_flow <= 0)
		to_chat(user, span_green("You successfully stop the bleeding in [self_applied ? "your" : "[victim]'s"] [limb.name]."))
	else
		to_chat(user, span_notice("You reduce the bleeding in [self_applied ? "your" : "[victim]'s"] [limb.name]."))

/// Return TRUE if we have an item that can only be used while aggro grabbed (unhanded aggro grab treatments go in [TYPE_PROC_REF(/datum/wound, try_handling)]). Treatment is still is handled in [TYPE_PROC_REF(/datum/wound, treat)]
TYPE_PROC_REF(/datum/wound, check_grab_treatments)(obj/item/I, mob/user)
	return FALSE

/// Like try_treating() but for unhanded interactions from humans, used by joint dislocations for manual bodypart chiropractice for example.
TYPE_PROC_REF(/datum/wound, try_handling)(mob/living/carbon/human/user)
	return FALSE

/// Someone is using something that might be used for treating the wound on this limb
TYPE_PROC_REF(/datum/wound, treat)(obj/item/I, mob/user)
	return

/// If var/processing is TRUE, this is run on each life tick
TYPE_PROC_REF(/datum/wound, handle_process)()
	return

/// For use in do_after callback checks
TYPE_PROC_REF(/datum/wound, still_exists)()
	return (!QDELETED(src) && limb)

/// When our parent bodypart is hurt
TYPE_PROC_REF(/datum/wound, receive_damage)(wounding_type, wounding_dmg, wound_bonus)
	return

/// Called from cryoxadone and pyroxadone when they're proc'ing. Wounds will slowly be fixed separately from other methods when these are in effect. crappy name but eh
TYPE_PROC_REF(/datum/wound, on_xadone)(power)
	cryo_progress += power
	if(cryo_progress > 33 * severity)
		qdel(src)

/// When synthflesh is applied to the victim, we call this. No sense in setting up an entire chem reaction system for wounds when we only care for a few chems. Probably will change in the future
TYPE_PROC_REF(/datum/wound, on_synthflesh)(power)
	return

/// Called when the patient is undergoing stasis, so that having fully treated a wound doesn't make you sit there helplessly until you think to unbuckle them
TYPE_PROC_REF(/datum/wound, on_stasis)()
	return

/// Called when we're crushed in an airlock or firedoor, for one of the improvised joint dislocation fixes
TYPE_PROC_REF(/datum/wound, crush)()
	return

/// Called when we want to update our wounds, only matters on bleeds right now
TYPE_PROC_REF(/datum/wound, update_wound)()
	return

/// Used when we're being dragged while bleeding, the value we return is how much bloodloss this wound causes from being dragged. Since it's a proc, you can let bandages soak some of the blood
TYPE_PROC_REF(/datum/wound, drag_bleed_amount)()
	return

/// Returns how much the wound should be bleeding given an amount of blood, so we can scale bleeding for minor wounds
TYPE_PROC_REF(/datum/wound, get_blood_flow)(include_reductions = FALSE)
	return blood_flow

/**
 * get_examine_description() is used in carbon/examine and human/examine to show the status of this wound. Useful if you need to show some status like the wound being splinted or bandaged.
 *
 * Return the full string line you want to show, note that we're already dealing with the 'warning' span at this point, and that \n is already appended for you in the place this is called from
 *
 * Arguments:
 * * mob/user: The user examining the wound's owner, if that matters
 */
TYPE_PROC_REF(/datum/wound, get_examine_description)(mob/user)
	. = "[victim.p_their(TRUE)] [limb.name] [examine_desc]"
	. = severity <= WOUND_SEVERITY_MODERATE ? "[.]." : "<B>[.]!</B>"

TYPE_PROC_REF(/datum/wound, get_scanner_description)(mob/user)
	return "Type: [name]\nSeverity: [severity_text()]\nDescription: [desc]\nRecommended Treatment: [treat_text]"

TYPE_PROC_REF(/datum/wound, severity_text)()
	switch(severity)
		if(WOUND_SEVERITY_TRIVIAL)
			return "Trivial"
		if(WOUND_SEVERITY_MODERATE)
			return "Moderate"
		if(WOUND_SEVERITY_SEVERE)
			return "Severe"
		if(WOUND_SEVERITY_CRITICAL)
			return "Critical"
