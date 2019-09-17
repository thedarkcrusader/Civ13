////////AXIS: MOVEMENT LOOP/////////

/obj/structure/vehicleparts/axis/ex_act(severity)
	switch(severity)
		if (1.0)
			Destroy()
			return
		if (2.0)
			if (prob(10))
				Destroy()
				return
		if (3.0)
			return

/obj/structure/vehicleparts/axis/Destroy()
	for(var/obj/structure/vehicleparts/frame/F in components)
		F.axis -= src
	wheel = null
	visible_message("<span class='danger'>The [name] axis gets wrecked!</span>")
	qdel(src)

/obj/structure/vehicleparts/axis/proc/startmovementloop()
	if (isemptylist(corners))
		check_corners()
	if (isemptylist(matrix))
		check_matrix()
	moving = TRUE
	movementloop()
	movementsound()

/obj/structure/vehicleparts/axis/proc/movementsound()
	if (!moving)
		return
	playsound(loc, 'sound/machines/tank_moving.ogg',100, TRUE)
	spawn(30)
		movementsound()

/obj/structure/vehicleparts/axis/proc/movementloop()
	if (moving == TRUE)
		get_weight()
		if (do_vehicle_check() && currentspeed > 0)
			for (var/obj/structure/vehicleparts/movement/W in wheels)
				W.icon_state = "[W.movement_icon][color_code]"
				W.update_icon()
			do_move()
		else
			for (var/obj/structure/vehicleparts/movement/W in wheels)
				W.icon_state = "[W.base_icon][color_code]"
				W.update_icon()
			currentspeed = 0
			moving = FALSE
			stopmovementloop()
		spawn(vehicle_m_delay+1)
			movementloop()
			return
	else
		return

/obj/structure/vehicleparts/axis/proc/stopmovementloop()
	moving = FALSE
	for (var/obj/structure/vehicleparts/movement/W in wheels)
		W.icon_state = W.base_icon
		W.update_icon()
	return

/obj/structure/vehicleparts/axis/proc/get_weight()
	current_weight = 5
	for(var/obj/structure/vehicleparts/frame/FR in components)
		current_weight += FR.total_weight()
	return current_weight

/obj/structure/vehicleparts/axis/proc/do_vehicle_check()
	if (check_engine())
		if (wheels.len < 4)
			moving = FALSE
			stopmovementloop()
			return FALSE
		for(var/obj/structure/vehicleparts/movement/MV in wheels)
			if (MV.broken)
				visible_message("<span class = 'warning'>\The [name] can't move, a [MV.ntype] is broken!</span>")
				moving = FALSE
				stopmovementloop()
				return FALSE
		for(var/obj/structure/vehicleparts/frame/FR in components)
			var/turf/T = get_turf(get_step(FR.loc,dir))
			if (!T)
				moving = FALSE
				stopmovementloop()
				return FALSE
			var/turf/TT = get_turf(get_step(T, dir))
			for(var/mob/living/L in TT)
				var/protec = FALSE
				for (var/obj/structure/vehicleparts/frame/FRR in L.loc)
					if (FRR.axis == FR.axis)
						protec = TRUE
				if (!protec)
					if (current_weight >= 45)
						visible_message("<span class='warning'>\the [src] runs over \the [L]!</span>","<span class='warning'>You run over \the [L]!</span>")
						L.crush()
						if (L)
							qdel(L)
					else
						if (ishuman(L))
							var/mob/living/carbon/human/HH = L
							HH.adjustBruteLoss(rand(7,16)*abs(currentspeed))
							HH.Weaken(rand(2,5))
							visible_message("<span class='warning'>\the [src] hits \the [L]!</span>","<span class='warning'>You hit \the [L]!</span>")
							L.forceMove(get_turf(get_step(TT,dir)))
						else if (istype(L,/mob/living/simple_animal))
							var/mob/living/simple_animal/SA = L
							SA.adjustBruteLoss(rand(7,16)*abs(currentspeed))
							if (SA.mob_size >= 30)
								visible_message("<span class='warning'>\the [src] hits \the [SA]!</span>","<span class='warning'>You hit \the [SA]!</span>")
								L.forceMove(get_turf(get_step(TT,dir)))
							else
								visible_message("<span class='warning'>\the [src] runs over \the [SA]!</span>","<span class='warning'>You run over \the [SA]!</span>")
								SA.crush()
			for(var/obj/structure/O in T)
				if (O.density == TRUE && !(O in transporting))
					if (current_weight >= 55)
						visible_message("<span class='warning'>\the [src] crushes \the [O]!</span>","<span class='warning'>You crush \the [O]!</span>")
						qdel(O)
					else
						visible_message("<span class='warning'>\the [src] hits \the [O]!</span>","<span class='warning'>You hit \the [O]!</span>")
						return FALSE
				else if (O.density == FALSE && !(O in transporting))
					if (!istype(O, /obj/structure/sign/traffic/zebracrossing) && !istype(O, /obj/structure/sign/traffic/central) && !istype(O, /obj/structure/rails))
						visible_message("<span class='warning'>\the [src] crushes \the [O]!</span>","<span class='warning'>You crush \the [O]!</span>")
						qdel(O)
			if (T.density == TRUE)
				visible_message("<span class='warning'>\the [src] hits \the [T]!</span>","<span class='warning'>You hit \the [T]!</span>")
				return FALSE
			for(var/obj/covers/CV in T && !(CV in transporting))
				if (CV.density == TRUE)
					visible_message("<span class='warning'>\the [src] hits \the [CV]!</span>","<span class='warning'>You hit \the [CV]!</span>")
					return FALSE
			for(var/obj/item/I in T && !(I in transporting))
				qdel(I)
			var/canpass = FALSE
			for(var/obj/covers/CVV in T)
				if (CVV.density == FALSE)
					canpass = TRUE
			if ((!istype(T, /turf/floor/beach/water/deep) ||  istype(T, /turf/floor/beach/water/deep) && canpass == TRUE) && T.density == FALSE  || istype(T, /turf/floor/trench/flooded))
				canpass = TRUE
			else
				moving = FALSE
				stopmovementloop()
				return FALSE
		return TRUE
	else
		moving = FALSE
		stopmovementloop()
		return FALSE
/obj/structure/vehicleparts/axis/proc/check_engine()

	if (!engine || !engine.fueltank)
		engine.on = FALSE
		return FALSE
	else if (get_weight() > engine.maxpower)
		visible_message("<span class='warning'>\The [engine] struggles and stalls!</span>")
		return FALSE
	else
		if (engine.fueltank.reagents.total_volume <= 0)
			engine.fueltank.reagents.total_volume = 0
			engine.on = FALSE
			return FALSE
		else
			if (engine.on)
				return TRUE
			else
				return FALSE
		return FALSE

	return TRUE

/obj/structure/vehicleparts/axis/proc/do_move()
	add_transporting()
	var/m_dir = loc.dir
	if (reverse)
		m_dir = OPPOSITE_DIR(dir)
	for (var/atom/movable/M in transporting)
		if ((istype(M, /obj/structure) || istype(M, /obj/item)) && !istype(M, /obj/structure/vehicleparts/frame) && !istype(M, /obj/structure/wild))
			var/obj/MO = M
			MO.forceMove(get_step(MO.loc, m_dir))
			if (!istype(M, /obj/structure/cannon) && !istype(M, /obj/structure/bed/chair))
				MO.dir = dir
				MO.update_icon()
			if (istype(M, /obj/structure/bed/chair/drivers))
				MO.dir = dir
				MO.update_icon()
			if (istype(M, /obj/structure/vehicleparts/movement))
				var/obj/structure/vehicleparts/movement/MV = M
				if (MV.reversed)
					MV.dir = OPPOSITE_DIR(dir)
		if (istype(M, /mob/living))
			var/mob/living/ML = M
			ML.forceMove(get_step(ML.loc, m_dir))
	for (var/obj/structure/vehicleparts/frame/F in components)
		F.dir = dir
		F.forceMove(get_step(F.loc, m_dir))
		F.update_icon()

	return

/obj/structure/vehicleparts/axis/proc/add_transporting()
	transporting = list()
	for (var/obj/structure/vehicleparts/frame/F in components)
		if (!F || !(F in range(7,loc)))
			components -= F
		var/turf/T = get_turf(F)
		for (var/atom/movable/M in T)
			if ((istype(M, /mob/living) || istype(M, /obj/structure) || istype(M, /obj/item)) && !(M in transporting))
				transporting += M
	for (var/obj/structure/vehicleparts/movement/MV in wheels)
		transporting += MV
	return transporting.len

/obj/structure/vehicleparts/axis/MouseDrop(var/obj/structure/vehicleparts/frame/VP)
	if (istype(VP, /obj/structure/vehicleparts/frame) && !VP.axis)
		playsound(loc, 'sound/effects/lever.ogg',100, TRUE)
		usr << "You connect \the [src] to \the [VP]."
		VP.axis = src
		VP.anchored = TRUE
		components += VP
		VP.name = "central [VP.name]"
		VP.color_code = color_code
		loc = VP
		return

//basically, a matrix works like this:
//matrix_l gives the horizontal length, matrix_h gives the vertical height, assuming its facing NORTH.
//so if we have a 3x4 vehicle, the matrix will look like this:
//
//|	1,1	|	1,2	|	1,3	|	1,4	|
//|	2,1	|	2,2	|	2,3	|	2,4	|
//|	3,1	|	3,2	|	3,3	|	3,4	|
//|	4,1	|	4,2	|	4,3	|	4,4	|
//
//the matrix always has to be a square with the sides being the value of largest between the length and height.
//in this case, 1,1 is the FL, 1,3 is the FR, 4,1 is the BL, 4,3 is the BR.
//so if we turn LEFT: we will be facing EAST, and it will change to:

/obj/structure/vehicleparts/axis/proc/check_matrix()
	if (corners[1] == null || corners[2] == null || corners[3] == null || corners[4] == null)
		world.log << "ERROR BUILDING MATRIX! (Incomplete Corner List)"
		return FALSE
	if (dir == NORTH || dir == SOUTH)
		matrix_l = abs(corners[2].x-corners[1].x)+1
		matrix_h = abs(corners[4].y-corners[2].y)+1
	else if (dir == WEST || dir == EAST)
		matrix_l = abs(corners[2].y-corners[1].y)+1
		matrix_h = abs(corners[4].x-corners[2].x)+1
	var/mside = max(matrix_l, matrix_h)
	if (mside == 0)
		world.log << "ERROR BUILDING MATRIX! (No Size)"
		return FALSE
	else if (mside < 0)
		mside = abs(mside)
	var/msize = mside*mside
	var/locx = 1
	var/locy = 1
	for (locx in 1 to mside)
		for (locy in 1 to mside)
			matrix += list("[locx],[locy]" = list(null,0,0, "[locx],[locy]"))
			locy++
		locx++
	if (matrix.len != msize)
		world.log << "ERROR BUILDING MATRIX! (Wrong Size: msize [msize], matrix.len [matrix.len])"
		return FALSE
	var/obj/structure/vehicleparts/frame/FFL = corners[1]
	if (!istype(FFL, /obj/structure/vehicleparts/frame))
		world.log << "ERROR BUILDING MATRIX! (Front-Left is not a Frame)"
		return FALSE
	if (FFL.dir == SOUTH)
		for (var/obj/structure/vehicleparts/frame/FM in components)
			var/disx = abs(FM.y-FFL.y)
			var/disy = abs(FM.x-FFL.x)
			matrix["[disx+1],[disy+1]"] = list(FM, disx+1, disy+1,"[disx+1],[disy+1]")
	return TRUE
/obj/structure/vehicleparts/axis/proc/check_corners()
	corners = list(null, null, null, null) //Front-Right, Front-Left, Back-Right,Back-Left; FR, FL, BR, BL
	for (var/obj/structure/vehicleparts/frame/F in components)
		var/sides = ""
		var/turf/T1 = get_turf(get_step(F,NORTH))
		for (var/i in list(NORTH,SOUTH,EAST,WEST))
			T1 =  get_turf(get_step(F,i))
			for (var/obj/structure/vehicleparts/frame/FF in T1)
				if (FF.axis == F.axis)
					sides = "[sides][i]"
		if (length(sides) == 2)
			if (findtext(sides,"1") && findtext(sides,"4")) //SW corner
				if (dir == SOUTH) //FR
					corners[1] = F
				else if (dir == NORTH) //BL
					corners[4] = F
				else if  (dir == WEST) //FL
					corners[2] = F
				else if (dir == EAST) // BR
					corners[3] = F
			if (findtext(sides,"1") && findtext(sides,"8")) //SE corner
				if (dir == SOUTH) //FL
					corners[2] = F
				else if (dir == NORTH) //BR
					corners[3] = F
				else if  (dir == WEST) //BL
					corners[4] = F
				else if (dir == EAST) // FR
					corners[1] = F
			if (findtext(sides,"2") && findtext(sides,"4")) //NW corner
				if (dir == SOUTH) //BR
					corners[3] = F
				else if (dir == NORTH) //FL
					corners[2] = F
				else if  (dir == WEST) //FR
					corners[1] = F
				else if (dir == EAST) // BL
					corners[4] = F
			if (findtext(sides,"2") && findtext(sides,"8")) //NE corner
				if (dir == SOUTH) //BL
					corners[4] = F
				else if (dir == NORTH) //FR
					corners[1] = F
				else if  (dir == WEST) //BR
					corners[3] = F
				else if (dir == EAST) // FL
					corners[2] = F
	if (corners[1] != null && corners[2] != null && corners[3] != null && corners[4] != null)
		return TRUE
	else
		world.log << "ERROR BUILDING CORNER LIST!"
		return FALSE

//Basically the do_move() proc but allows a destination to be defined, i.e., it doesnt just force move in a dir like the other proc.
//Reverts to do_move() if no destination or origin is specified.

/obj/structure/vehicleparts/axis/proc/do_move_dest(var/turf/ORIG = null, var/turf/DEST = null)
	if(!DEST || !ORIG)
		do_move()
		return
	else
		for (var/atom/movable/M in ORIG)
			if ((istype(M, /obj/structure) || istype(M, /obj/item)) && !istype(M, /obj/structure/wild))
				var/obj/MO = M
				MO.forceMove(DEST)
				if (!istype(M, /obj/structure/cannon) && !istype(M, /obj/structure/bed/chair))
					MO.dir = dir
					MO.update_icon()
				if (istype(M, /obj/structure/bed/chair/drivers))
					MO.dir = dir
					MO.update_icon()
				if (istype(M, /obj/structure/vehicleparts/movement))
					var/obj/structure/vehicleparts/movement/MV = M
					if (MV.reversed)
						MV.dir = OPPOSITE_DIR(dir)
			if (istype(M, /mob/living))
				var/mob/living/ML = M
				ML.forceMove(DEST)
		return


/obj/structure/vehicleparts/axis/proc/do_matrix(var/olddir = 0, var/newdir = 0, var/tdir = "none")
	if (olddir == 0 || newdir == 0 || tdir == "none")
		return
	if (isemptylist(corners))
		check_corners()
	if (isemptylist(matrix))
		check_matrix()

	//first we need to generate the matrix of the new locations, based on our frame matrix.
	var/turf/baset = get_turf(matrix["1,1"][1])

	if (tdir == "right")
		switch (newdir)
			if (EAST)
				for (var/i=1, i<=matrix_l, i++)
					for (var/j=1, j<= matrix_h, j++)
						var/obj/structure/vehicleparts/frame/FM = matrix["[i],[j]"][1]
						if (FM)
							var/ox = text2num(matrix["[i],[j]"][2])
							var/oy = text2num(matrix["[i],[j]"][3])
							var/tx = matrix_h-oy-1
							var/ty = matrix_l-ox-1
							var/turf/oturf = get_turf(FM)
							var/turf/nturf = get_turf(locate(baset.x+tx, baset.y+ty, baset.z))
							world.log << "[nturf]: [nturf.x], [nturf.y], [nturf.z]"
							do_move_dest(oturf,nturf)
			if (NORTH)
				for (var/i=1, i<=matrix_l, i++)
					for (var/j=1, j<= matrix_h, j++)
						var/obj/structure/vehicleparts/frame/FM = matrix["[i],[j]"][1]
						if (FM)
							var/ox = text2num(matrix["[i],[j]"][2])
							var/oy = text2num(matrix["[i],[j]"][3])
							var/tx = matrix_l-ox-1
							var/ty = matrix_h-oy-1
							var/turf/oturf = get_turf(FM)
							var/turf/nturf = get_turf(locate(baset.x+tx, baset.y+ty, baset.z))
							world.log << "[nturf]: [nturf.x], [nturf.y], [nturf.z]"
							do_move_dest(oturf,nturf)
			if (WEST)
				for (var/i=1, i<=matrix_l, i++)
					for (var/j=1, j<= matrix_h, j++)
						var/obj/structure/vehicleparts/frame/FM = matrix["[i],[j]"][1]
						if (FM)
							var/ox = text2num(matrix["[i],[j]"][2])
							var/oy = text2num(matrix["[i],[j]"][3])
							var/tx = matrix_l-ox-1
							var/ty = matrix_h-oy-1
							var/turf/oturf = get_turf(FM)
							var/turf/nturf = get_turf(locate(baset.x+tx, baset.y+ty, baset.z))
							world.log << "[nturf]: [nturf.x], [nturf.y], [nturf.z]"
							do_move_dest(oturf,nturf)
			if (SOUTH)
				for (var/i=1, i<=matrix_l, i++)
					for (var/j=1, j<= matrix_h, j++)
						var/obj/structure/vehicleparts/frame/FM = matrix["[i],[j]"][1]
						if (FM)
							var/ox = text2num(matrix["[i],[j]"][2])
							var/oy = text2num(matrix["[i],[j]"][3])
							var/tx = matrix_h-oy-1
							var/ty = matrix_l-ox-1
							var/turf/oturf = get_turf(FM)
							var/turf/nturf = get_turf(locate(baset.x+tx, baset.y+ty, baset.z))
							world.log << "[nturf]: [nturf.x], [nturf.y], [nturf.z]"
							do_move_dest(oturf,nturf)
	else if (tdir == "left")
		switch (newdir)
			if (EAST)
				for (var/i=1, i<=matrix_l, i++)
					for (var/j=1, j<= matrix_h, j++)
						var/obj/structure/vehicleparts/frame/FM = matrix["[i],[j]"][1]
						if (FM)
							var/ox = text2num(matrix["[i],[j]"][2])
							var/oy = text2num(matrix["[i],[j]"][3])
							var/tx = matrix_h-oy-1
							var/ty = matrix_l-ox-1
							var/turf/oturf = get_turf(FM)
							var/turf/nturf = get_turf(locate(baset.x+tx, baset.y+ty, baset.z))
							world.log << "[nturf]: [nturf.x], [nturf.y], [nturf.z]"
							do_move_dest(oturf,nturf)
			if (NORTH)
				for (var/i=1, i<=matrix_l, i++)
					for (var/j=1, j<= matrix_h, j++)
						var/obj/structure/vehicleparts/frame/FM = matrix["[i],[j]"][1]
						if (FM)
							var/ox = text2num(matrix["[i],[j]"][2])
							var/oy = text2num(matrix["[i],[j]"][3])
							var/tx = matrix_h-oy-1
							var/ty = matrix_l-ox-1
							var/turf/oturf = get_turf(FM)
							var/turf/nturf = get_turf(locate(baset.x+tx, baset.y+ty, baset.z))
							world.log << "[nturf]: [nturf.x], [nturf.y], [nturf.z]"
							do_move_dest(oturf,nturf)
			if (WEST)
				for (var/i=1, i<=matrix_l, i++)
					for (var/j=1, j<= matrix_h, j++)
						var/obj/structure/vehicleparts/frame/FM = matrix["[i],[j]"][1]
						if (FM)
							var/ox = text2num(matrix["[i],[j]"][2])
							var/oy = text2num(matrix["[i],[j]"][3])
							var/tx = matrix_h-oy-1
							var/ty = matrix_l-ox-1
							var/turf/oturf = get_turf(FM)
							var/turf/nturf = get_turf(locate(baset.x+tx, baset.y+ty, baset.z))
							world.log << "[nturf]: [nturf.x], [nturf.y], [nturf.z]"
							do_move_dest(oturf,nturf)
			if (SOUTH)
				for (var/i=1, i<=matrix_l, i++)
					for (var/j=1, j<= matrix_h, j++)
						var/obj/structure/vehicleparts/frame/FM = matrix["[i],[j]"][1]
						if (FM)
							var/ox = text2num(matrix["[i],[j]"][2])
							var/oy = text2num(matrix["[i],[j]"][3])
							var/tx = matrix_h-oy-1
							var/ty = matrix_l-ox-1
							var/turf/oturf = get_turf(FM)
							var/turf/nturf = get_turf(locate(baset.x+tx, baset.y+ty, baset.z))
							world.log << "[nturf]: [nturf.x], [nturf.y], [nturf.z]"
							do_move_dest(oturf,nturf)