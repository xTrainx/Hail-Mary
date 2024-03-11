
/obj/item/reagent_containers/food/snacks/pie
	icon = 'icons/obj/food/piecake.dmi'
	bitesize = 3
	w_class = WEIGHT_CLASS_NORMAL
	volume = 80
	list_reagents = list(/datum/reagent/consumable/nutriment = 10, /datum/reagent/consumable/nutriment/vitamin = 2)
	tastes = list("pie" = 1)
	foodtype = GRAIN

/obj/item/reagent_containers/food/snacks/pie/plain
	name = "plain pie"
	desc = "A simple pie, still delicious."
	icon_state = "pie"
	custom_food_type = /obj/item/reagent_containers/food/snacks/customizable/pie
	bonus_reagents = list(/datum/reagent/consumable/nutriment = 8, /datum/reagent/consumable/nutriment/vitamin = 1)
	tastes = list("pie" = 1)
	foodtype = GRAIN

/obj/item/reagent_containers/food/snacks/pie/cream
	name = "banana cream pie"
	desc = "A delicious banana cream pie just like in the old funny pictures."
	icon_state = "pie"
	bonus_reagents = list(/datum/reagent/consumable/nutriment = 2, /datum/reagent/consumable/nutriment/vitamin = 2)
	list_reagents = list(/datum/reagent/consumable/nutriment = 6, /datum/reagent/consumable/banana = 5, /datum/reagent/consumable/nutriment/vitamin = 2)
	tastes = list("pie" = 1)
	foodtype = GRAIN | DAIRY | SUGAR
	var/stunning = TRUE

/obj/item/reagent_containers/food/snacks/pie/cream/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	. = ..()
	if(!.) //if we're not being caught
		splat(hit_atom)

TYPE_PROC_REF(/obj/item/reagent_containers/food/snacks/pie/cream, splat)(atom/movable/hit_atom)
	if(isliving(loc)) //someone caught us!
		return
	var/turf/T = get_turf(hit_atom)
	new/obj/effect/decal/cleanable/pie_smudge(T)
	if(reagents && reagents.total_volume)
		reagents.reaction(hit_atom, TOUCH)
	if(ishuman(hit_atom))
		var/mob/living/carbon/human/H = hit_atom
		var/mutable_appearance/creamoverlay = mutable_appearance('icons/effects/creampie.dmi')
		if((H.dna.species.mutant_bodyparts["mam_snouts"] && H.dna.features["mam_snouts"] != "None") || (H.dna.species.mutant_bodyparts["snout"] && H.dna.features["snout"] != "None"))
			creamoverlay.icon_state = "creampie_snout"
		else
			creamoverlay.icon_state = "creampie_human"
		if(stunning)
			H.DefaultCombatKnockdown(20)	//splat!
		H.adjust_blurriness(1)
		H.visible_message(span_warning("[H] is creamed by [src]!"), span_userdanger("You've been creamed by [src]!"))
		playsound(H, "desceration", 50, TRUE)
		if(!H.is_mouth_covered())
			reagents.trans_to(H, 15, log = TRUE)	//Cream pie combat
		if(!H.creamed)	// one layer at a time
			H.add_overlay(creamoverlay)
			H.creamed = TRUE
			SEND_SIGNAL(H, COMSIG_ADD_MOOD_EVENT, "creampie", /datum/mood_event/creampie)
	qdel(src)

/obj/item/reagent_containers/food/snacks/pie/cream/nostun
	list_reagents = list(/datum/reagent/consumable/laughter = 15)
	stunning = FALSE

/obj/item/reagent_containers/food/snacks/pie/cream/body

/obj/item/reagent_containers/food/snacks/pie/cream/body/Destroy()
	var/turf/T = get_turf(src)
	for(var/atom/movable/A in contents)
		A.forceMove(T)
		A.throw_at(T, 1, 1)
	. = ..()

/obj/item/reagent_containers/food/snacks/pie/cream/body/On_Consume(mob/living/carbon/M)
	if(!reagents.total_volume) //so that it happens on the last bite
		if(iscarbon(M) && contents.len)
			var/turf/T = get_turf(src)
			for(var/atom/movable/A in contents)
				A.forceMove(T)
				A.throw_at(T, 1, 1)
				M.visible_message("[src] bursts out of [M]!</span>")
			M.emote("scream")
			M.DefaultCombatKnockdown(40)
			M.adjustBruteLoss(60)
	return ..()

/obj/item/reagent_containers/food/snacks/pie/berryclafoutis
	name = "berry clafoutis"
	desc = "No black birds, this is a good sign."
	icon_state = "berryclafoutis"
	bonus_reagents = list(/datum/reagent/consumable/nutriment = 1, /datum/reagent/consumable/nutriment/vitamin = 2)
	list_reagents = list(/datum/reagent/consumable/nutriment = 10, /datum/reagent/consumable/berryjuice = 5, /datum/reagent/consumable/nutriment/vitamin = 2)
	tastes = list("pie" = 1, "blackberries" = 1)
	foodtype = GRAIN | FRUIT | SUGAR

/obj/item/reagent_containers/food/snacks/pie/bearypie
	name = "beary pie"
	desc = "Was the pun really worth killing a Yao Guai over?"
	icon_state = "bearypie"
	bonus_reagents = list(/datum/reagent/consumable/nutriment = 2, /datum/reagent/consumable/nutriment/vitamin = 3)
	list_reagents = list(/datum/reagent/consumable/nutriment = 2, /datum/reagent/consumable/nutriment/vitamin = 3)
	tastes = list("pie" = 1, "meat" = 1, "salmon" = 1)
	foodtype = GRAIN | SUGAR

/obj/item/reagent_containers/food/snacks/pie/meatpie
	name = "meat-pie"
	icon_state = "meatpie"
	desc = "An old barber recipe, very delicious!"
	bonus_reagents = list(/datum/reagent/consumable/nutriment = 1, /datum/reagent/consumable/nutriment/vitamin = 5)
	tastes = list("pie" = 1, "meat" = 1)
	foodtype = GRAIN | MEAT

/obj/item/reagent_containers/food/snacks/pie/burek
	name = "Burek"
	icon = 'icons/obj/food/piecake.dmi'
	icon_state = "burek"
	desc = "If you know, you know."
	slice_path = /obj/item/reagent_containers/food/snacks/pie/burekslice
	slices_num = 4
	bonus_reagents = list(/datum/reagent/consumable/nutriment = 4, /datum/reagent/consumable/nutriment/vitamin = 6)
	list_reagents = list(/datum/reagent/consumable/nutriment= 20, /datum/reagent/consumable/nutriment/vitamin = 6)
	bitesize = 12
	tastes = list("meat" = 1, "oil" = 1)
	foodtype = GRAIN | MEAT

/obj/item/reagent_containers/food/snacks/pie/burekslice
	name = "Burek Slice"
	icon = 'icons/obj/food/piecake.dmi'
	icon_state = "burekslice"
	desc = "A slice of Burek, watch out for oil stains!"
	tastes = list("meat" = 1, "oil" = 1)
	foodtype = GRAIN | MEAT


/obj/item/reagent_containers/food/snacks/pie/tofupie
	name = "tofu-pie"
	icon_state = "meatpie"
	desc = "A delicious tofu pie."
	bonus_reagents = list(/datum/reagent/consumable/nutriment = 1, /datum/reagent/consumable/nutriment/vitamin = 2)
	tastes = list("pie" = 1, "tofu" = 1)
	foodtype = GRAIN


/obj/item/reagent_containers/food/snacks/pie/amanita_pie
	name = "amanita pie"
	desc = "Sweet and tasty poison pie."
	icon_state = "amanita_pie"
	bitesize = 4
	bonus_reagents = list(/datum/reagent/consumable/nutriment = 1, /datum/reagent/consumable/nutriment/vitamin = 4)
	list_reagents = list(/datum/reagent/consumable/nutriment = 6, /datum/reagent/toxin/amatoxin = 3, /datum/reagent/drug/mushroomhallucinogen = 1, /datum/reagent/consumable/nutriment/vitamin = 4)
	tastes = list("pie" = 1, "mushroom" = 1)
	foodtype = GRAIN | VEGETABLES | TOXIC | GROSS


/obj/item/reagent_containers/food/snacks/pie/plump_pie
	name = "plump pie"
	desc = "I bet you love stuff made out of plump helmets!"
	icon_state = "plump_pie"
	bonus_reagents = list(/datum/reagent/consumable/nutriment = 1, /datum/reagent/consumable/nutriment/vitamin = 4)
	tastes = list("pie" = 1, "mushroom" = 1)
	foodtype = GRAIN | VEGETABLES


/obj/item/reagent_containers/food/snacks/pie/plump_pie/Initialize()
	. = ..()
	var/fey = prob(10)
	if(fey)
		name = "exceptional plump pie"
		desc = "Microwave is taken by a fey mood! It has cooked an exceptional plump pie!"
		bonus_reagents = list(/datum/reagent/consumable/nutriment = 1, /datum/reagent/medicine/omnizine = 5, /datum/reagent/consumable/nutriment/vitamin = 4)
		foodtype += ANTITOXIC
	if(fey)
		reagents.add_reagent(/datum/reagent/medicine/omnizine, 5)
		foodtype += ANTITOXIC


/obj/item/reagent_containers/food/snacks/pie/xemeatpie
	name = "mutant-pie"
	icon_state = "xenomeatpie"
	desc = "Probably not very healthy."
	bonus_reagents = list(/datum/reagent/consumable/nutriment = 1, /datum/reagent/consumable/nutriment/vitamin = 5)
	tastes = list("pie" = 1, "meat" = 1, "acid" = 1)
	foodtype = GRAIN | MEAT


/obj/item/reagent_containers/food/snacks/pie/applepie
	name = "apple pie"
	desc = "A pie containing sweet sweet love...or apple."
	icon_state = "applepie"
	bonus_reagents = list(/datum/reagent/consumable/nutriment = 1, /datum/reagent/consumable/nutriment/vitamin = 3)
	tastes = list("pie" = 1, "apple" = 1)
	foodtype = GRAIN | FRUIT | SUGAR

/obj/item/reagent_containers/food/snacks/pie/cherrypie
	name = "cherry pie"
	desc = "Taste so good, make a grown man cry."
	icon_state = "cherrypie"
	bonus_reagents = list(/datum/reagent/consumable/nutriment = 1, /datum/reagent/consumable/nutriment/vitamin = 2)
	tastes = list("pie" = 7, "Nicole Paige Brooks" = 2)
	foodtype = GRAIN | FRUIT | SUGAR


/obj/item/reagent_containers/food/snacks/pie/pumpkinpie
	name = "pumpkin pie"
	desc = "A delicious treat for the autumn months."
	icon_state = "pumpkinpie"
	slice_path = /obj/item/reagent_containers/food/snacks/pumpkinpieslice
	slices_num = 5
	bonus_reagents = list(/datum/reagent/consumable/nutriment = 1, /datum/reagent/consumable/nutriment/vitamin = 5)
	tastes = list("pie" = 1, "pumpkin" = 1)
	foodtype = GRAIN | VEGETABLES

/obj/item/reagent_containers/food/snacks/pumpkinpieslice
	name = "pumpkin pie slice"
	desc = "A slice of pumpkin pie, with whipped cream on top. Perfection."
	icon = 'icons/obj/food/piecake.dmi'
	icon_state = "pumpkinpieslice"
	filling_color = "#FFA500"
	list_reagents = list(/datum/reagent/consumable/nutriment = 2)
	tastes = list("pie" = 1, "pumpkin" = 1)
	foodtype = GRAIN | VEGETABLES

/obj/item/reagent_containers/food/snacks/pie/appletart
	name = "golden apple streusel tart"
	desc = "A tasty dessert that won't make it through a metal detector."
	icon_state = "gappletart"
	bonus_reagents = list(/datum/reagent/consumable/nutriment = 1, /datum/reagent/consumable/nutriment/vitamin = 4)
	list_reagents = list(/datum/reagent/consumable/nutriment = 8, /datum/reagent/gold = 5, /datum/reagent/consumable/nutriment/vitamin = 4)
	tastes = list("pie" = 1, "apple" = 1, "expensive metal" = 1)
	foodtype = GRAIN | FRUIT | SUGAR

/obj/item/reagent_containers/food/snacks/pie/grapetart
	name = "grape tart"
	desc = "A tasty dessert that reminds you of the wine you didn't make."
	icon_state = "grapetart"
	bonus_reagents = list(/datum/reagent/consumable/nutriment = 1, /datum/reagent/consumable/nutriment/vitamin = 4)
	list_reagents = list(/datum/reagent/consumable/nutriment = 4, /datum/reagent/consumable/nutriment/vitamin = 4)
	tastes = list("pie" = 1, "grape" = 1)
	foodtype = GRAIN | FRUIT | SUGAR

/obj/item/reagent_containers/food/snacks/pie/berrytart
	name = "berry tart"
	desc = "A tasty dessert of many different small barries on a thin pie crust."
	icon_state = "berrytart"
	bonus_reagents = list(/datum/reagent/consumable/nutriment = 1, /datum/reagent/consumable/nutriment/vitamin = 4)
	list_reagents = list(/datum/reagent/consumable/nutriment = 3, /datum/reagent/consumable/nutriment/vitamin = 5)
	tastes = list("pie" = 1, "berries" = 2)
	foodtype = GRAIN | FRUIT

/obj/item/reagent_containers/food/snacks/pie/cocolavatart
	name = "chocolate lava tart"
	desc = "A tasty dessert made of chocaloate, with a liquid core."
	icon_state = "cocolavatart"
	bonus_reagents = list(/datum/reagent/consumable/nutriment = 1, /datum/reagent/consumable/nutriment/vitamin = 4)
	list_reagents = list(/datum/reagent/consumable/nutriment = 4, /datum/reagent/consumable/nutriment/vitamin = 4)
	tastes = list("pie" = 1, "grape" = 1)
	foodtype = GRAIN | SUGAR

/obj/item/reagent_containers/food/snacks/pie/blumpkinpie
	name = "blumpkin pie"
	desc = "An odd blue pie made with toxic blumpkin."
	icon_state = "blumpkinpie"
	slice_path = /obj/item/reagent_containers/food/snacks/blumpkinpieslice
	slices_num = 5
	bonus_reagents = list(/datum/reagent/consumable/nutriment = 3, /datum/reagent/consumable/nutriment/vitamin = 6)
	tastes = list("pie" = 1, "a mouthful of pool water" = 1)
	foodtype = GRAIN | VEGETABLES

/obj/item/reagent_containers/food/snacks/blumpkinpieslice
	name = "blumpkin pie slice"
	desc = "A slice of blumpkin pie, with whipped cream on top. Is this edible?"
	icon = 'icons/obj/food/piecake.dmi'
	icon_state = "blumpkinpieslice"
	filling_color = "#1E90FF"
	list_reagents = list(/datum/reagent/consumable/nutriment = 2)
	tastes = list("pie" = 1, "a mouthful of pool water" = 1)
	foodtype = GRAIN | VEGETABLES

/obj/item/reagent_containers/food/snacks/pie/dulcedebatata
	name = "dulce de batata"
	desc = "A delicious jelly made with sweet potatoes."
	icon_state = "dulcedebatata"
	slice_path = /obj/item/reagent_containers/food/snacks/dulcedebatataslice
	slices_num = 5
	bonus_reagents = list(/datum/reagent/consumable/nutriment = 4, /datum/reagent/consumable/nutriment/vitamin = 8)
	tastes = list("jelly" = 1, "sweet potato" = 1)
	foodtype = GRAIN | VEGETABLES | SUGAR

/obj/item/reagent_containers/food/snacks/dulcedebatataslice
	name = "dulce de batata slice"
	desc = "A slice of sweet dulce de batata jelly."
	icon = 'icons/obj/food/piecake.dmi'
	icon_state = "dulcedebatataslice"
	filling_color = "#8B4513"
	list_reagents = list(/datum/reagent/consumable/nutriment = 2)
	tastes = list("jelly" = 1, "sweet potato" = 1)
	foodtype = GRAIN | VEGETABLES | SUGAR

/obj/item/reagent_containers/food/snacks/pie/frostypie
	name = "frosty pie"
	desc = "Tastes like blue and cold."
	icon_state = "frostypie"
	bonus_reagents = list(/datum/reagent/consumable/nutriment = 4, /datum/reagent/consumable/nutriment/vitamin = 6)
	tastes = list("mint" = 1, "pie" = 1)
	foodtype = GRAIN | FRUIT | SUGAR

/obj/item/reagent_containers/food/snacks/pie/baklava
	name = "baklava"
	desc = "A delightful healthy snake made of nut layers with thin bread."
	icon_state = "baklava"
	slice_path = /obj/item/reagent_containers/food/snacks/baklavaslice
	slices_num = 6
	bonus_reagents = list(/datum/reagent/consumable/nutriment = 2, /datum/reagent/consumable/nutriment/vitamin = 6)
	tastes = list("nuts" = 1, "pie" = 1)
	foodtype = GRAIN

/obj/item/reagent_containers/food/snacks/baklavaslice
	name = "baklava dish"
	desc = "A portion delightful healthy snake made of nut layers with thin bread"
	icon = 'icons/obj/food/piecake.dmi'
	icon_state = "baklavaslice"
	filling_color = "#1E90FF"
	list_reagents = list(/datum/reagent/consumable/nutriment = 2, /datum/reagent/consumable/nutriment/vitamin = 4)
	tastes = list("nuts" = 1, "pie" = 1)
	foodtype = GRAIN

/obj/item/reagent_containers/food/snacks/pie/strawberrypie
	name = "strawberry pie"
	desc = "A strawberry pie."
	icon_state = "strawberrypie"
	bonus_reagents = list(/datum/reagent/consumable/nutriment = 6, /datum/reagent/consumable/nutriment/vitamin = 6)
	tastes = list("strawberry" = 1, "pie" = 1)
	foodtype = GRAIN | FRUIT | SUGAR

/obj/item/reagent_containers/food/snacks/pie/peachpie
	name = "peach pie"
	desc = "A pie with peach filling."
	icon_state = "strawberrypie"
	bonus_reagents = list(/datum/reagent/consumable/nutriment = 5, /datum/reagent/consumable/nutriment/vitamin = 6, /datum/reagent/consumable/peachjuice = 15)
	tastes = list("peach" = 1, "pie" = 1)
	foodtype = GRAIN | FRUIT

/obj/item/reagent_containers/food/snacks/pie/shepherds_pie
	name = "shepherds pie"
	desc = "A dish of minced meat and mixed vegetables baked under a layer of creamy mashed potatoes. Sliceable."
	icon_state = "shepherds_pie"
	slice_path = /obj/item/reagent_containers/food/snacks/pie/pieslice/shepherds_pie
	slices_num = 4
	list_reagents = list(/datum/reagent/consumable/nutriment = 40, /datum/reagent/consumable/nutriment/vitamin = 12)
	tastes = list("juicy meat" = 2, "mashed potatoes" = 2, "baked veggies" = 2)
	foodtype = MEAT | DAIRY | VEGETABLES

/obj/item/reagent_containers/food/snacks/pie/pieslice/shepherds_pie
	name = "shepherds pie slice"
	desc = "A messy slice of shepherds pie, made of minced meat and mixed vegetables baked under a layer of creamy mashed potatoes. Dangerously tasty."
	icon_state = "shepherds_pie_slice"
	list_reagents = list(/datum/reagent/consumable/nutriment = 10, /datum/reagent/consumable/nutriment/vitamin = 3)
	tastes = list("juicy meat" = 1, "mashed potatoes" = 1, "baked veggies" = 1)
	foodtype = MEAT | DAIRY | VEGETABLES
