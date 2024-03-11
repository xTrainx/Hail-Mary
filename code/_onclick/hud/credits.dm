#define CREDIT_ROLL_SPEED 125
#define CREDIT_SPAWN_SPEED 10
#define CREDIT_ANIMATE_HEIGHT (14 * world.icon_size)
#define CREDIT_EASE_DURATION 22
#define CREDITS_PATH "[global.config.directory]/contributors.dmi"

TYPE_PROC_REF(/client, RollCredits)()
	set waitfor = FALSE
	if(!fexists(CREDITS_PATH))
		return
	var/icon/credits_icon = new(CREDITS_PATH)
	LAZYINITLIST(credits)
	var/list/_credits = credits
	add_verb(src, TYPE_PROC_REF(/client, ClearCredits))
	var/static/list/credit_order_for_this_round
	if(isnull(credit_order_for_this_round))
		credit_order_for_this_round = list("Thanks for playing!") + (shuffle(icon_states(credits_icon)) - "Thanks for playing!")
	for(var/I in credit_order_for_this_round)
		if(!credits)
			return
		_credits += new /obj/screen/credit(null, I, src, credits_icon)
		sleep(CREDIT_SPAWN_SPEED)
	sleep(CREDIT_ROLL_SPEED - CREDIT_SPAWN_SPEED)
	remove_verb(src, TYPE_PROC_REF(/client, ClearCredits))
	qdel(credits_icon)

TYPE_PROC_REF(/client, ClearCredits)()
	set name = "Hide Credits"
	set category = "OOC"
	remove_verb(src, TYPE_PROC_REF(/client, ClearCredits))
	QDEL_LIST(credits)
	credits = null

/obj/screen/credit
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	alpha = 0
	screen_loc = "12,1"
	layer = SPLASHSCREEN_LAYER
	var/client/parent
	var/matrix/target

/obj/screen/credit/Initialize(mapload, credited, client/P, icon/I)
	. = ..()
	icon = I
	parent = P
	icon_state = credited
	maptext = credited
	maptext_x = world.icon_size + 8
	maptext_y = (world.icon_size / 2) - 4
	maptext_width = world.icon_size * 3
	var/matrix/M = matrix(transform)
	M.Translate(0, CREDIT_ANIMATE_HEIGHT)
	animate(src, transform = M, time = CREDIT_ROLL_SPEED)
	target = M
	animate(src, alpha = 255, time = CREDIT_EASE_DURATION, flags = ANIMATION_PARALLEL)
	addtimer(CALLBACK(src, PROC_REF(FadeOut)), CREDIT_ROLL_SPEED - CREDIT_EASE_DURATION)
	QDEL_IN(src, CREDIT_ROLL_SPEED)
	P.screen += src

/obj/screen/credit/Destroy()
	var/client/P = parent
	P.screen -= src
	icon = null
	LAZYREMOVE(P.credits, src)
	parent = null
	return ..()

TYPE_PROC_REF(/obj/screen/credit, FadeOut)()
	animate(src, alpha = 0, transform = target, time = CREDIT_EASE_DURATION)
