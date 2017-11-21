/*
	Telekinesis

	This needs more thinking out, but I might as well.
*/
var/const/tk_maxrange = 15

/*
	Telekinetic attack:

	By default, emulate the user's unarmed attack
*/
/atom/proc/attack_tk(mob/user)
	if(user.stat)
		return
	user.UnarmedAttack(src,0) // attack_hand, attack_paw, etc
	return

/*
	This is similar to item attack_self, but applies to anything
	that you can grab with a telekinetic grab.

	It is used for manipulating things at range, for example, opening and closing closets.
	There are not a lot of defaults at this time, add more where appropriate.
*/
/atom/proc/attack_self_tk(mob/user)
	return

/obj/attack_tk(mob/user)
	if(user.stat)
		return
	if(anchored)
		..()
		return

	var/obj/item/tk_grab/O = new(src)
	O.form_grab(user, src)

/obj/item/attack_tk(mob/user)
	if(user.stat || !isturf(loc))
		return
	if((TK in user.mutations) && !user.get_active_hand()) // both should already be true to get here
		var/obj/item/tk_grab/O = new(src)
		O.form_grab(user, src)
	else
		warning("Strange attack_tk(): TK([TK in user.mutations]) empty hand([!user.get_active_hand()])")


/mob/attack_tk(mob/user)
	return // needs more thinking about

/*
	TK Grab Item (the workhorse of old TK)

	* If you have not grabbed something, do a normal tk attack
	* If you have something, throw it at the target.  If it is already adjacent, do a normal attackby(, params)
	* If you click what you are holding, or attack_self(), do an attack_self_tk() on it.
	* Deletes itself if it is ever not in your hand, or if you should have no access to TK.
*/
/obj/item/tk_grab
	name = "Agarr�o Telecinetico"
	desc = "Magica"
	icon = 'icons/obj/magic.dmi'//Needs sprites
	icon_state = "2"
	flags = NOBLUDGEON | ABSTRACT
	//item_state = null
	w_class = 10
	layer = 20
	plane = HUD_PLANE

	var/last_throw = 0
	var/atom/movable/focus = null
	var/mob/living/host = null

/obj/item/tk_grab/Destroy()
	if(focus)
		release_object()
	// Focus is null now
	host = null
	return ..()

/obj/item/tk_grab/dropped(mob/user)
	if(focus && user && loc != user && loc != user.loc) // drop_item() gets called when you tk-attack a table/closet with an item
		if(focus.Adjacent(loc))
			focus.loc = loc

	qdel(src)


	//stops TK grabs being equipped anywhere but into hands
/obj/item/tk_grab/equipped(mob/user, var/slot)
	if( (slot == slot_l_hand) || (slot== slot_r_hand) )
		return
	qdel(src)


/obj/item/tk_grab/attack_self(mob/user)
	if(focus)
		focus.attack_self_tk(user)

/obj/item/tk_grab/override_throw(mob/user, atom/target)
	afterattack(target, user)
	return TRUE

/obj/item/tk_grab/afterattack(atom/target , mob/living/user, proximity, params)//TODO: go over this
	if(!target || !user)
		return
	if(last_throw+3 > world.time)
		return
	if(!host || host != user)
		qdel(src)
		return
	if(!(TK in host.mutations))
		qdel(src)
		return
	if(isobj(target) && !isturf(target.loc))
		return

	var/d = get_dist(user, target)
	if(focus)
		d = max(d,get_dist(user,focus)) // whichever is further
	if(d > tk_maxrange)
		to_chat(user, "<span class='warning'>Sua mente n�o consegue ir t�o longe.</span>")
		return

	if(!focus)
		focus_object(target, user)
		return

	if(target == focus)
		target.attack_self_tk(user)
		return // todo: something like attack_self not laden with assumptions inherent to attack_self


	if(istype(focus,/obj/item) && target.Adjacent(focus) && !user.in_throw_mode)
		var/obj/item/I = focus
		var/resolved = target.attackby(I, user, params)
		if(!resolved && target && I)
			I.afterattack(target,user,1) // for splashing with beakers


	else
		apply_focus_overlay()
		focus.throw_at(target, 10, 1, user)
		last_throw = world.time

/obj/item/tk_grab/attack(mob/living/M, mob/living/user, def_zone)
	return

/obj/item/tk_grab/is_equivalent(obj/item/I)
	. = ..()
	if(!.)
		return I == focus

/obj/item/tk_grab/proc/focus_object(var/obj/target, var/mob/user)
	if(!istype(target,/obj))
		return//Cant throw non objects atm might let it do mobs later
	if(target.anchored || !isturf(target.loc))
		qdel(src)
		return
	focus = target
	update_icon()
	apply_focus_overlay()
	// Make it behave like other equipment
	if(istype(target, /obj/item))
		if(target in user.tkgrabbed_objects)
			// Release the old grab first
			user.unEquip(user.tkgrabbed_objects[target])
		user.tkgrabbed_objects[target] = src

/obj/item/tk_grab/proc/release_object()
	if(!focus)
		return
	if(istype(focus, /obj/item))
		// Delete the key/value pair of item to TK grab
		host.tkgrabbed_objects -= focus
	focus = null
	update_icon()

/obj/item/tk_grab/proc/apply_focus_overlay()
	if(!focus)
		return
	// Oh jeez ow
	var/obj/effect/overlay/O = new /obj/effect/overlay(locate(focus.x,focus.y,focus.z))
	O.name = "sparkles"
	O.anchored = 1
	O.density = 0
	O.layer = FLY_LAYER
	O.dir = pick(cardinal)
	O.icon = 'icons/effects/effects.dmi'
	O.icon_state = "nothing"
	flick("empdisable",O)
	spawn(5)
		qdel(O)

/obj/item/tk_grab/proc/form_grab(mob/user, obj/target)
	user.put_in_active_hand(src)
	host = user
	focus_object(target, user)


/obj/item/tk_grab/update_icon()
	overlays.Cut()
	if(focus && focus.icon && focus.icon_state)
		overlays += icon(focus.icon,focus.icon_state)

/*Not quite done likely needs to use something thats not get_step_to
	proc/check_path()
		var/turf/ref = get_turf(src.loc)
		var/turf/target = get_turf(focus.loc)
		if(!ref || !target)	return 0
		var/distance = get_dist(ref, target)
		if(distance >= 10)	return 0
		for(var/i = 1 to distance)
			ref = get_step_to(ref, target, 0)
		if(ref != target)	return 0
		return 1
*/

//equip_to_slot_or_del(obj/item/W, slot, del_on_fail = 1)
/*
		if(istype(user, /mob/living/carbon))
			if(user:mutations & TK && get_dist(source, user) <= 7)
				if(user:get_active_hand())	return 0
				var/X = source:x
				var/Y = source:y
				var/Z = source:z

*/
