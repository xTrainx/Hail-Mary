/obj/item/pai_cable
	desc = "A flexible coated cable with a universal jack on one end."
	name = "data cable"
	icon = 'icons/obj/power.dmi'
	icon_state = "wire1"
	item_flags = NOBLUDGEON
	var/obj/machinery/machine

TYPE_PROC_REF(/obj/item/pai_cable, plugin)(obj/machinery/M, mob/living/user)
	if(!user.transferItemToLoc(src, M))
		return
	user.visible_message("[user] inserts [src] into a data port on [M].", span_notice("You insert [src] into a data port on [M]."), span_italic("You hear the satisfying click of a wire jack fastening into place."))
	machine = M
