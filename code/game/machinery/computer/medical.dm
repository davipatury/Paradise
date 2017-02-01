#define MED_DATA_MAIN	1	// Main menu
#define MED_DATA_R_LIST	2	// Record list
#define MED_DATA_MAINT	3	// Records maintenance
#define MED_DATA_RECORD	4	// Record
#define MED_DATA_V_DATA	5	// Virus database
#define MED_DATA_MEDBOT	6	// Medbot monitor

/obj/machinery/computer/med_data//TODO:SANITY
	name = "medical records console"
	desc = "This can be used to check medical records."
	icon_keyboard = "med_key"
	icon_screen = "medcomp"
	req_one_access = list(access_medical, access_forensics_lockers)
	circuit = /obj/item/weapon/circuitboard/med_data
	var/obj/item/weapon/card/id/scan = null
	var/authenticated = null
	var/rank = null
	var/screen = null
	var/datum/data/record/active1 = null
	var/datum/data/record/active2 = null
	var/a_id = null
	var/temp = null
	var/printing = null

	light_color = LIGHT_COLOR_DARKBLUE

/obj/machinery/computer/med_data/attackby(obj/item/O, mob/user, params)
	if(istype(O, /obj/item/weapon/card/id) && !scan)
		usr.drop_item()
		O.forceMove(src)
		scan = O
		ui_interact(user)
	..()

/obj/machinery/computer/med_data/attack_hand(mob/user)
	if(..())
		return
	if(is_away_level(z))
		to_chat(user, "<span class='danger'>Unable to establish a connection</span>: You're too far away from the station!")
		return
	ui_interact(user)

/obj/machinery/computer/med_data/ui_interact(mob/user, ui_key = "main", var/datum/nanoui/ui = null, var/force_open = 1)
	ui = nanomanager.try_update_ui(user, src, ui_key, ui, force_open)
	if(!ui)
		ui = new(user, src, ui_key, "med_data.tmpl", "Medical Records", 800, 380)
		ui.open()

/obj/machinery/computer/med_data/ui_data(mob/user, ui_key = "main", datum/topic_state/state = default_state)
	var/data[0]
	data["temp"] = temp
	if(!temp)
		data["scan"] = scan ? scan.name : null
		data["authenticated"] = authenticated
		data["screen"] = screen
		if(authenticated)
			switch(screen)
				if(MED_DATA_R_LIST)
					if(!isnull(data_core.general))
						data["records"] = list()
						for(var/datum/data/record/R in sortRecord(data_core.general))
							data["records"] += list(list("ref" = "\ref[R]", "id" = R.fields["id"], "name" = R.fields["name"]))
				if(MED_DATA_RECORD)
					var/general = list()
					if(istype(active1, /datum/data/record) && data_core.general.Find(active1))
						general["fields"] = list()
						general["fields"] += list(list("field" = "Name:", "value" = active1.fields["name"]))
						general["fields"] += list(list("field" = "ID:", "value" = active1.fields["id"]))
						general["fields"] += list(list("field" = "Sex:", "value" = active1.fields["sex"], "name" = "sex"))
						general["fields"] += list(list("field" = "Age:", "value" = active1.fields["age"], "name" = "age"))
						general["fields"] += list(list("field" = "Fingerprint:", "value" = active1.fields["fingerprint"], "name" = "fingerprint"))
						general["fields"] += list(list("field" = "Physical Status:", "value" = active1.fields["p_stat"], "name" = "p_stat"))
						general["fields"] += list(list("field" = "Mental Status:", "value" = active1.fields["m_stat"], "name" = "m_stat"))
						general["photos"] += list(list("photo" = active1.fields["photo-south"]))
						general["photos"] += list(list("photo" = active1.fields["photo-west"]))
						general["empty"] = 0
					else
						general["empty"] = 1
					data["general"] = general

					var/medical = list()
					if(istype(active2, /datum/data/record) && data_core.medical.Find(active2))
						medical["fields"] = list()
						medical["fields"] += list(list("field" = "Blood Type:", "value" = active2.fields["b_type"], "name" = "b_type", "line_break" = 0))
						medical["fields"] += list(list("field" = "DNA:", "value" = active2.fields["b_dna"], "name" = "b_dna", "line_break" = 1))
						medical["fields"] += list(list("field" = "Minor Disabilities:", "value" = active2.fields["mi_dis"], "name" = "mi_dis", "line_break" = 0))
						medical["fields"] += list(list("field" = "Details:", "value" = active2.fields["mi_dis_d"], "name" = "mi_dis_d", "line_break" = 1))
						medical["fields"] += list(list("field" = "Major Disabilities:", "value" = active2.fields["ma_dis"], "name" = "ma_dis", "line_break" = 0))
						medical["fields"] += list(list("field" = "Details:", "value" = active2.fields["ma_dis_d"], "name" = "ma_dis_d", "line_break" = 1))
						medical["fields"] += list(list("field" = "Allergies:", "value" = active2.fields["alg"], "name" = "alg", "line_break" = 0))
						medical["fields"] += list(list("field" = "Details:", "value" = active2.fields["alg_d"], "name" = "alg_d", "line_break" = 1))
						medical["fields"] += list(list("field" = "Current Diseases:", "value" = active2.fields["cdi"], "name" = "cdi", "line_break" = 0))
						medical["fields"] += list(list("field" = "Details:", "value" = active2.fields["cdi_d"], "name" = "cdi_d", "line_break" = 1))
						medical["fields"] += list(list("field" = "Important Notes:", "value" = active2.fields["notes"], "name" = "notes", "line_break" = 0))
						if(!active2.fields["comments"] || !islist(active2.fields["comments"]))
							active2.fields["comments"] = list()
						medical["comments"] = active2.fields["comments"]
						medical["empty"] = 0
					else
						medical["empty"] = 1
					data["medical"] = medical
				if(MED_DATA_V_DATA)
					data["virus"] = list()
					for(var/D in typesof(/datum/disease))
						var/datum/disease/DS = new D(0)
						if(istype(DS, /datum/disease/advance))
							continue
						if(!DS.desc)
							continue
						data["virus"] += list(list("name" = DS.name, "D" = D))
				if(MED_DATA_MEDBOT)
					data["medbots"] = list()
					for(var/mob/living/simple_animal/bot/medbot/M in world)
						if(M.z != z)
							continue
						var/turf/T = get_turf(M)
						if(T)
							var/medbot = list()
							medbot["name"] = M.name
							medbot["x"] = T.x
							medbot["y"] = T.y
							medbot["on"] = M.on
							if(!isnull(M.reagent_glass) && M.use_beaker)
								medbot["use_beaker"] = 1
								medbot["total_volume"] = M.reagent_glass.reagents.total_volume
								medbot["maximum_volume"] = M.reagent_glass.reagents.maximum_volume
							else
								medbot["use_beaker"] = 0
							data["medbots"] += list(medbot)
	return data

/obj/machinery/computer/med_data/Topic(href, href_list)
	if(..())
		return 1

	if(!data_core.general.Find(active1))
		active1 = null

	if(!data_core.medical.Find(active2))
		active2 = null

	if((usr.contents.Find(src) || (in_range(src, usr) && isturf(loc))) || (issilicon(usr)))
		usr.set_machine(src)

		if(href_list["temp"])
			temp = null

		if(href_list["temp_action"])
			if(href_list["temp_action"])
				var/prm = splittext(href_list["temp_action"], "=")
				switch(prm[1])
					if("del_all2")
						for(var/datum/data/record/R in data_core.medical)
							qdel(R)
						temp = list("text" = "All records deleted.", "buttons" = list())
					if("p_stat")
						if(active1)
							switch(prm[2])
								if("deceased")
									active1.fields["p_stat"] = "*Deceased*"
								if("ssd")
									active1.fields["p_stat"] = "*SSD*"
								if("active")
									active1.fields["p_stat"] = "Active"
								if("unfit")
									active1.fields["p_stat"] = "Physically Unfit"
								if("disabled")
									active1.fields["p_stat"] = "Disabled"
					if("m_stat")
						if(active1)
							switch(prm[2])
								if("insane")
									active1.fields["m_stat"] = "*Insane*"
								if("unstable")
									active1.fields["m_stat"] = "*Unstable*"
								if("watch")
									active1.fields["m_stat"] = "*Watch*"
								if("stable")
									active1.fields["m_stat"] = "Stable"
					if("b_type")
						if(active2)
							switch(prm[2])
								if("an")
									active2.fields["b_type"] = "A-"
								if("bn")
									active2.fields["b_type"] = "B-"
								if("abn")
									active2.fields["b_type"] = "AB-"
								if("on")
									active2.fields["b_type"] = "O-"
								if("ap")
									active2.fields["b_type"] = "A+"
								if("bp")
									active2.fields["b_type"] = "B+"
								if("abp")
									active2.fields["b_type"] = "AB+"
								if("op")
									active2.fields["b_type"] = "O+"
					if("del_r2")
						if(active2)
							qdel(active2)

		if(href_list["scan"])
			if(scan)
				scan.forceMove(loc)
				if(ishuman(usr))
					if(!usr.get_active_hand())
						usr.put_in_hands(scan)
				scan = null
			else
				var/obj/item/I = usr.get_active_hand()
				if(istype(I, /obj/item/weapon/card/id))
					usr.drop_item()
					I.forceMove(src)
					scan = I

		else if(href_list["logout"])
			authenticated = null
			screen = null
			active1 = null
			active2 = null

		else if(href_list["login"])

			if(isAI(usr))
				active1 = null
				active2 = null
				authenticated = usr.name
				rank = "AI"
				screen = MED_DATA_MAIN

			else if(isrobot(usr))
				active1 = null
				active2 = null
				authenticated = usr.name
				var/mob/living/silicon/robot/R = usr
				rank = "[R.modtype] [R.braintype]"
				screen = MED_DATA_MAIN

			else if(istype(scan, /obj/item/weapon/card/id))
				active1 = null
				active2 = null

				if(check_access(scan))
					authenticated = scan.registered_name
					rank = scan.assignment
					screen = MED_DATA_MAIN

		if(authenticated)

			if(href_list["screen"])
				screen = text2num(href_list["screen"])
				if(screen < 1)
					screen = MED_DATA_MAIN

				active1 = null
				active2 = null

			if(href_list["vir"])
				var/type = href_list["vir"]
				var/datum/disease/Dis = new type(0)
				var/AfS = ""
				for(var/mob/M in Dis.viable_mobtypes)
					AfS += "[initial(M.name)];"
				var/severity = Dis.severity
				switch(severity)
					if("Harmful", "Minor")
						severity = "<span class='good'>[severity]</span>"
					if("Medium")
						severity = "<span class='average'>[severity]</span>"
					if("Dangerous!")
						severity = "<span class='bad'>[severity]</span>"
					if("BIOHAZARD THREAT!")
						severity = "<h4><span class='bad'>[severity]</span></h4>"
				setTemp({"<b>Name:</b> [Dis.name]
						<BR><b>Number of stages:</b> [Dis.max_stages]
						<BR><b>Spread:</b> [Dis.spread_text] Transmission
						<BR><b>Possible Cure:</b> [(Dis.cure_text||"none")]
						<BR><b>Affected Lifeforms:</b>[AfS]<BR>
						<BR><b>Notes:</b> [Dis.desc]<BR>
						<BR><b>Severity:</b> [severity]"})
				qdel(Dis)

			if(href_list["del_all"])
				var/buttons = list()
				buttons += list(list("name" = "Yes", "icon" = "check", "val" = "del_all2=1"))
				buttons += list(list("name" = "No", "icon" = "times", "val" = null))
				setTemp("<h3>Are you sure you wish to delete all records?</h3>", buttons, 1)

			if(href_list["field"])
				var/a1 = active1
				var/a2 = active2
				switch(href_list["field"])
					if("fingerprint")
						if(istype(active1, /datum/data/record))
							var/t1 = copytext(trim(sanitize(input("Please input fingerprint hash:", "Med. records", active1.fields["fingerprint"], null) as text)), 1, MAX_MESSAGE_LEN)
							if(!t1 || !authenticated || usr.stat || usr.restrained() || (!in_range(src, usr) && !issilicon(usr)) || active1 != a1)
								return
							active1.fields["fingerprint"] = t1
					if("sex")
						if(istype(active1, /datum/data/record))
							if(active1.fields["sex"] == "Male")
								active1.fields["sex"] = "Female"
							else
								active1.fields["sex"] = "Male"
					if("age")
						if(istype(active1, /datum/data/record))
							var/t1 = input("Please input age:", "Med. records", active1.fields["age"], null) as num
							if(!t1 || !authenticated || usr.stat || usr.restrained() || (!in_range(src, usr) && !issilicon(usr)) || active1 != a1)
								return
							active1.fields["age"] = t1
					if("mi_dis")
						if(istype(active2, /datum/data/record))
							var/t1 = copytext(trim(sanitize(input("Please input minor disabilities list:", "Med. records", active2.fields["mi_dis"], null) as text)), 1, MAX_MESSAGE_LEN)
							if(!t1 || !authenticated || usr.stat || usr.restrained() || (!in_range(src, usr) && !issilicon(usr)) || active2 != a2)
								return
							active2.fields["mi_dis"] = t1
					if("mi_dis_d")
						if(istype(active2, /datum/data/record))
							var/t1 = copytext(trim(sanitize(input("Please summarize minor dis.:", "Med. records", active2.fields["mi_dis_d"], null) as message)), 1, MAX_MESSAGE_LEN)
							if(!t1 || !authenticated || usr.stat || usr.restrained() || (!in_range(src, usr) && !issilicon(usr)) || active2 != a2)
								return
							active2.fields["mi_dis_d"] = t1
					if("ma_dis")
						if(istype(active2, /datum/data/record))
							var/t1 = copytext(trim(sanitize(input("Please input major diabilities list:", "Med. records", active2.fields["ma_dis"], null) as text)), 1, MAX_MESSAGE_LEN)
							if(!t1 || !authenticated || usr.stat || usr.restrained() || (!in_range(src, usr) && !issilicon(usr)) || active2 != a2)
								return
							active2.fields["ma_dis"] = t1
					if("ma_dis_d")
						if(istype(active2, /datum/data/record))
							var/t1 = copytext(trim(sanitize(input("Please summarize major dis.:", "Med. records", active2.fields["ma_dis_d"], null) as message)), 1, MAX_MESSAGE_LEN)
							if(!t1 || !authenticated || usr.stat || usr.restrained() || (!in_range(src, usr) && !issilicon(usr)) || active2 != a2)
								return
							active2.fields["ma_dis_d"] = t1
					if("alg")
						if(istype(active2, /datum/data/record))
							var/t1 = copytext(trim(sanitize(input("Please state allergies:", "Med. records", active2.fields["alg"], null) as text)), 1, MAX_MESSAGE_LEN)
							if(!t1 || !authenticated || usr.stat || usr.restrained() || (!in_range(src, usr) && !issilicon(usr)) || active2 != a2)
								return
							active2.fields["alg"] = t1
					if("alg_d")
						if(istype(active2, /datum/data/record))
							var/t1 = copytext(trim(sanitize(input("Please summarize allergies:", "Med. records", active2.fields["alg_d"], null) as message)), 1, MAX_MESSAGE_LEN)
							if(!t1 || !authenticated || usr.stat || usr.restrained() || (!in_range(src, usr) && !issilicon(usr)) || active2 != a2)
								return
							active2.fields["alg_d"] = t1
					if("cdi")
						if(istype(active2, /datum/data/record))
							var/t1 = copytext(trim(sanitize(input("Please state diseases:", "Med. records", active2.fields["cdi"], null) as text)), 1, MAX_MESSAGE_LEN)
							if(!t1 || !authenticated || usr.stat || usr.restrained() || (!in_range(src, usr) && !issilicon(usr)) || active2 != a2)
								return
							active2.fields["cdi"] = t1
					if("cdi_d")
						if(istype(active2, /datum/data/record))
							var/t1 = copytext(trim(sanitize(input("Please summarize diseases:", "Med. records", active2.fields["cdi_d"], null) as message)), 1, MAX_MESSAGE_LEN)
							if(!t1 || !authenticated || usr.stat || usr.restrained() || (!in_range(src, usr) && !issilicon(usr)) || active2 != a2)
								return
							active2.fields["cdi_d"] = t1
					if("notes")
						if(istype(active2, /datum/data/record))
							var/t1 = copytext(html_encode(trim(input("Please summarize notes:", "Med. records", html_decode(active2.fields["notes"]), null) as message)), 1, MAX_MESSAGE_LEN)
							if(!t1 || !authenticated || usr.stat || usr.restrained() || (!in_range(src, usr) && !issilicon(usr)) || active2 != a2)
								return
							active2.fields["notes"] = t1
					if("p_stat")
						if(istype(active1, /datum/data/record))
							var/buttons = list()
							buttons += list(list("name" = "*Deceased*", "icon" = "stethoscope", "val" = "p_stat=deceased"))
							buttons += list(list("name" = "*SSD*", "icon" = "stethoscope", "val" = "p_stat=ssd"))
							buttons += list(list("name" = "Active", "icon" = "stethoscope", "val" = "p_stat=active"))
							buttons += list(list("name" = "Physically Unfit", "icon" = "stethoscope", "val" = "p_stat=unfit"))
							buttons += list(list("name" = "Disabled", "icon" = "stethoscope", "val" = "p_stat=disabled"))
							setTemp("<h3>Physical Condition</h3>", buttons)
					if("m_stat")
						if(istype(active1, /datum/data/record))
							var/buttons = list()
							buttons += list(list("name" = "*Insane*", "icon" = "stethoscope", "val" = "m_stat=insane"))
							buttons += list(list("name" = "*Unstable*", "icon" = "stethoscope", "val" = "m_stat=unstable"))
							buttons += list(list("name" = "*Watch*", "icon" = "stethoscope", "val" = "m_stat=watch"))
							buttons += list(list("name" = "Stable", "icon" = "stethoscope", "val" = "m_stat=stable"))
							setTemp("<h3>Mental Condition</h3>", buttons)
					if("b_type")
						if(istype(active2, /datum/data/record))
							var/buttons = list()
							buttons += list(list("name" = "A-", "icon" = "tint", "val" = "b_type=an"))
							buttons += list(list("name" = "A+", "icon" = "tint", "val" = "b_type=ap"))
							buttons += list(list("name" = "B-", "icon" = "tint", "val" = "b_type=bn"))
							buttons += list(list("name" = "B+", "icon" = "tint", "val" = "b_type=bp"))
							buttons += list(list("name" = "AB-", "icon" = "tint", "val" = "b_type=abn"))
							buttons += list(list("name" = "AB+", "icon" = "tint", "val" = "b_type=abp"))
							buttons += list(list("name" = "O-", "icon" = "tint", "val" = "b_type=on"))
							buttons += list(list("name" = "O+", "icon" = "tint", "val" = "b_type=op"))
							setTemp("<h3>Blood Type</h3>", buttons)
					if("b_dna")
						if(istype(active1, /datum/data/record))
							var/t1 = copytext(trim(sanitize(input("Please input DNA hash:", "Med. records", active1.fields["dna"], null) as text)), 1, MAX_MESSAGE_LEN)
							if(!t1 || !authenticated || usr.stat || usr.restrained() || (!in_range(src, usr) && !issilicon(usr)) || active1 != a1)
								return
							active1.fields["dna"] = t1
					if("vir_name")
						var/datum/data/record/v = locate(href_list["edit_vir"])
						if(v)
							var/t1 = copytext(trim(sanitize(input("Please input pathogen name:", "VirusDB", v.fields["name"], null)  as text)), 1, MAX_MESSAGE_LEN)
							if(!t1 || !authenticated || usr.stat || usr.restrained() || (!in_range(src, usr) && !issilicon(usr)) || active1 != a1)
								return
							v.fields["name"] = t1
					if("vir_desc")
						var/datum/data/record/v = locate(href_list["edit_vir"])
						if(v)
							var/t1 = copytext(trim(sanitize(input("Please input information about pathogen:", "VirusDB", v.fields["description"], null) as message)), 1, MAX_MESSAGE_LEN)
							if(!t1 || !authenticated || usr.stat || usr.restrained() || (!in_range(src, usr) && !issilicon(usr)) || active1 != a1)
								return
							v.fields["description"] = t1

			if(href_list["del_r"])
				if(active2)
					var/buttons = list()
					buttons += list(list("name" = "Yes", "icon" = "check", "val" = "del_r2=1"))
					buttons += list(list("name" = "No", "icon" = "times", "val" = null))
					setTemp("<h3>Are you sure you wish to delete the record (Medical Portion Only)?</h3>", buttons, 1)

			if(href_list["d_rec"])
				var/datum/data/record/R = locate(href_list["d_rec"])
				var/datum/data/record/M = locate(href_list["d_rec"])
				if(!data_core.general.Find(R))
					temp = list("text" = "Record Not Found!", "buttons" = list())
					nanomanager.update_uis(src)
					return
				for(var/datum/data/record/E in data_core.medical)
					if(E.fields["name"] == R.fields["name"] || E.fields["id"] == R.fields["id"])
						M = E
				active1 = R
				active2 = M
				screen = MED_DATA_RECORD

			if(href_list["new"])
				if(istype(active1, /datum/data/record) && !istype(active2, /datum/data/record))
					var/datum/data/record/R = new /datum/data/record()
					R.fields["name"] = active1.fields["name"]
					R.fields["id"] = active1.fields["id"]
					R.name = "Medical Record #[R.fields["id"]]"
					R.fields["b_type"] = "Unknown"
					R.fields["b_dna"] = "Unknown"
					R.fields["mi_dis"] = "None"
					R.fields["mi_dis_d"] = "No minor disabilities have been declared."
					R.fields["ma_dis"] = "None"
					R.fields["ma_dis_d"] = "No major disabilities have been diagnosed."
					R.fields["alg"] = "None"
					R.fields["alg_d"] = "No allergies have been detected in this patient."
					R.fields["cdi"] = "None"
					R.fields["cdi_d"] = "No diseases have been diagnosed at the moment."
					R.fields["notes"] = "No notes."
					data_core.medical += R
					active2 = R
					screen = MED_DATA_RECORD

			if(href_list["add_c"])
				if(!istype(active2, /datum/data/record))
					return
				var/a2 = active2
				var/t1 = copytext(trim(sanitize(input("Add Comment:", "Med. records", null, null) as message)), 1, MAX_MESSAGE_LEN)
				if(!t1 || !authenticated || usr.stat || usr.restrained() || (!in_range(src, usr) && !issilicon(usr)) || active2 != a2)
					return
				active2.fields["comments"] += "Made by [authenticated] ([rank]) on [current_date_string] [worldtime2text()]<BR>[t1]"

			if(href_list["del_c"])
				var/index = min(max(text2num(href_list["del_c"]) + 1, 1), length(active2.fields["comments"]))
				if(istype(active2, /datum/data/record) && active2.fields["comments"][index])
					active2.fields["comments"] -= active2.fields["comments"][index]

			if(href_list["search"])
				var/t1 = input("Search String: (Name, DNA, or ID)", "Med. records", null, null) as text
				if(!t1 || !authenticated || usr.stat || usr.restrained() || (!in_range(src, usr) && !issilicon(usr)))
					nanomanager.update_uis(src)
					return
				active1 = null
				active2 = null
				t1 = lowertext(t1)
				for(var/datum/data/record/R in data_core.medical)
					if(lowertext(R.fields["name"]) == t1 || t1 == lowertext(R.fields["id"]) || t1 == lowertext(R.fields["b_dna"]))
						active2 = R
				if(!active2)
					temp = list("text" = "Could not locate record [t1].", "buttons" = list())
				else
					for(var/datum/data/record/E in data_core.general)
						if(E.fields["name"] == active2.fields["name"] || E.fields["id"] == active2.fields["id"])
							active1 = E
					screen = MED_DATA_RECORD

			if(href_list["print_p"])
				if(!printing)
					printing = 1
					playsound(loc, "sound/goonstation/machines/printer_dotmatrix.ogg", 50, 1)
					sleep(50)
					var/obj/item/weapon/paper/P = new /obj/item/weapon/paper(loc)
					P.info = "<CENTER><B>Medical Record</B></CENTER><BR>"
					if(istype(active1, /datum/data/record) && data_core.general.Find(active1))
						P.info += {"Name: [active1.fields["name"]] ID: [active1.fields["id"]]
						<BR>\nSex: [active1.fields["sex"]]
						<BR>\nAge: [active1.fields["age"]]
						<BR>\nFingerprint: [active1.fields["fingerprint"]]
						<BR>\nPhysical Status: [active1.fields["p_stat"]]
						<BR>\nMental Status: [active1.fields["m_stat"]]<BR>"}
					else
						P.info += "<B>General Record Lost!</B><BR>"
					if(istype(active2, /datum/data/record) && data_core.medical.Find(active2))
						P.info += {"<BR>\n<CENTER><B>Medical Data</B></CENTER>
						<BR>\nBlood Type: [active2.fields["b_type"]]
						<BR>\nDNA: [active2.fields["b_dna"]]<BR>\n
						<BR>\nMinor Disabilities: [active2.fields["mi_dis"]]
						<BR>\nDetails: [active2.fields["mi_dis_d"]]<BR>\n
						<BR>\nMajor Disabilities: [active2.fields["ma_dis"]]
						<BR>\nDetails: [active2.fields["ma_dis_d"]]<BR>\n
						<BR>\nAllergies: [active2.fields["alg"]]
						<BR>\nDetails: [active2.fields["alg_d"]]<BR>\n
						<BR>\nCurrent Diseases: [active2.fields["cdi"]] (per disease info placed in log/comment section)
						<BR>\nDetails: [active2.fields["cdi_d"]]<BR>\n
						<BR>\nImportant Notes:
						<BR>\n\t[active2.fields["notes"]]<BR>\n
						<BR>\n
						<CENTER><B>Comments/Log</B></CENTER><BR>"}
						for(var/c in active2.fields["comments"])
							P.info += "[c]<BR>"
					else
						P.info += "<B>Medical Record Lost!</B><BR>"
					P.info += "</TT>"
					P.name = "paper- 'Medical Record'"
					printing = 0

	add_fingerprint(usr)
	nanomanager.update_uis(src)
	return

/obj/machinery/computer/med_data/proc/setTemp(text, list/buttons = list(), notice = 0)
	temp = list("text" = text, "buttons" = buttons, "has_buttons" = buttons.len > 0, "notice" = notice)

/obj/machinery/computer/med_data/emp_act(severity)
	if(stat & (BROKEN|NOPOWER))
		return ..(severity)

	for(var/datum/data/record/R in data_core.medical)
		if(prob(10/severity))
			switch(rand(1,6))
				if(1)
					R.fields["name"] = "[pick(pick(first_names_male), pick(first_names_female))] [pick(last_names)]"
				if(2)
					R.fields["sex"] = pick("Male", "Female")
				if(3)
					R.fields["age"] = rand(5, 85)
				if(4)
					R.fields["b_type"] = pick("A-", "B-", "AB-", "O-", "A+", "B+", "AB+", "O+")
				if(5)
					R.fields["p_stat"] = pick("*SSD*", "Active", "Physically Unfit", "Disabled")
				if(6)
					R.fields["m_stat"] = pick("*Insane*", "*Unstable*", "*Watch*", "Stable")
			continue

		else if(prob(1))
			qdel(R)
			continue

	..(severity)


/obj/machinery/computer/med_data/laptop
	name = "medical laptop"
	desc = "Cheap Nanotrasen laptop."
	icon_state = "laptop"
	icon_keyboard = "laptop_key"
	icon_screen = "medlaptop"
	density = 0

#undef MED_DATA_MAIN
#undef MED_DATA_R_LIST
#undef MED_DATA_MAINT
#undef MED_DATA_RECORD
#undef MED_DATA_V_DATA
#undef MED_DATA_MEDBOT