//File isn't currently being used.
/datum/preferences
	var/biological_gender = MALE
	var/identifying_gender = MALE

TYPE_PROC_REF(/datum/preferences, set_biological_gender)(gender)
	biological_gender = gender
	identifying_gender = gender


/obj/item/clothing/var/hides_bulges = FALSE // OwO wats this?
