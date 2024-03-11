/obj/effect/manifest
	name = "manifest"
	icon = 'icons/mob/screen_gen.dmi'
	icon_state = "x"

/obj/effect/manifest/Initialize()
	. = ..()
	invisibility = INVISIBILITY_ABSTRACT

TYPE_PROC_REF(/obj/effect/manifest, manifest)()
	var/dat = "<B>Wasteland Census</B>:<BR>"
	for(var/mob/living/carbon/human/M in GLOB.carbon_list)
		dat += text("    <B>[]</B> -  []<BR>", M.name, M.get_assignment())
	var/obj/item/paper/P = new /obj/item/paper( src.loc )
	P.info = dat
	P.name = "paper- 'Wasteland Census'"
	//SN src = null
	qdel(src)
