extends RefCounted

const WHY_I_CAME := "Dad disappeared on a job at 17 Briar Lane in 1998. They never found him. Tonight someone reported a television playing in the empty house, although its power should be disconnected. I asked dispatch for the job.\n\nHis last job slip has this address on it. I want to find out what he was doing here before I close tonight's call."
const OFFICE_POWER := "The office terminal came on with the kitchen supply. Dad's name is on its 1998 job file. I want to read it before I close this call."
const INSPECTION_KIT := "The case is stamped 2018. This address came off the service list in 1999. I don't know when the case was brought here, or who left it.\n\nThe UV head fits my work torch. It reveals ink I can't see in white light. The label says the office report sleeves use that ink.\n\nBoth lights use the same battery. UV runs it down faster. I have a hand-wound backup in the cap if I run out of spares. Equipment controls are listed in Settings."

const HALL_MICROPHONE := "A small microphone is bolted to the hall wall. Its cable runs back to the office recorder.\n\nThe recorder can pick up my footsteps as I cross the hall. I can play them back from the office. Dad used this equipment too, but his 1998 test reel is stored separately."

const TRANSPORT_LEADER := "HALL MICROPHONE / NO RECORDING YET\n\nPencil note: Walk past the microphone. Let it record your steps, then stand still."

const RUBBING_LINES := ["Kitchen radio: 104.6.","I rang home. Eli answered. He's safe.","I shut the lounge door. Now it's his room."]

const WITNESS_TITLE := "THE UNSIGNED CLEARANCE"
const WITNESS_CARBON := "17 BRIAR LANE / CLEARANCE CARBON / 1998\n\nMachine entry: EMPTY / 23:18.\nInspection completed: [blank]\nWitness signature: [blank]\n\nSimon's handwriting: I haven't finished checking the building. I haven't signed this. The machine marked the building empty anyway. Keep this copy with my report. My test notes are in the records store at the end of this passage.\n\nMy note: Nobody witnessed Dad leaving. The job was marked finished while Dad was still inside. Changing the register won't tell me where he went. But this unsigned copy shows that he never agreed the house was empty."

const INSPECTION_TITLE := "REPORT SLEEVE / INSPECTION"

const COMPARISON_TITLE := "ELI / TONIGHT'S COMPARISON"

const SITE := "Briar Lane clearance works / 1998\nSite office: No. 17\n\nNos. 13-19 are vacant. Keep No. 17 open until the final inspection. Front room: waiting area. Rear room: property files.\n\nLeave the service feed on until everyone has signed out. The door counter records people entering and leaving. Check its total against the sign-in book. If they disagree, search the building before marking it empty.\n\nRemove this address from the call-out list when the site closes.\n\nHandwritten below: Counter says two arrivals. Ward is the only name in the sign-in book."

const CALL := "PROPERTY SERVICES / WORK ORDER 017\n17 Briar Lane / Eli Ward\n\nReported fault: television playing in a vacant property. Supply listed as disconnected. Caller gave no name or contact number.\n\nDispatch note: Address removed from service list in 1999. Confirm address before attending. Check the building before closing the job. Note any mistakes in the register and keep a copy with the job sheet.\n\nMy note: Dispatch nearly cancelled it. Then they said Briar Lane. I've still got Dad's last job slip. Same house. I asked them to give me the call."
const ARCHIVE := "PROPERTY FILE / SIMON WARD\nElectrical contractor / 1998\n\n23:17 - Signed in.\n23:18 - Marked ABSENT by the door counter.\nDeparture time: blank. No door opening recorded.\n\nMissing-person report attached. Ward did not return from this call. His son, Eli, was seven.\n\nService-camera still: a second man at the stairs. No name or vehicle recorded.\n\nSimon's pencil note: He stands there whenever I try to leave. Keep my notebook. Don't file this as an empty property.\n\nA brass service key is clipped inside the folder."
const PROCEDURE := "SERVICE SHED / S. WARD / 1998\n\nIsolation order:\nCOOLING first, then SUPPLY, then COUNTER.\nPull the isolator only after all three lines are closed. Each wheel has a plate naming its line. The paint colours identify the wheels; they do not give the order.\n\nMy report is in the lower drawer of the service cabinet. Its catch is linked to the floor plate. Weight on the plate holds it open. The cabinet stays locked until the lines are isolated.\n\nThe office copy of my report has been changed. Use the original if I don't come back. Someone keeps walking above me. If I stop, he stops. I haven't seen another contractor all night.\n\nPlease check the house if I don't sign out.\n\nA small key is taped to the back."
const SOURCE_COPY := "MY RECORDING / TONIGHT\n\nI played my footsteps from the hall microphone, then played them again. The reels stopped. A moment later, I heard another step at the office doorway. I hadn't moved.\n\nIt wasn't on the tape. This happened tonight, while I was listening. Dad's 1998 reel is a different recording.\n\nI've kept my comparison with his report. Together, they're a reason for dispatch to investigate the house, not just correct his entry."
const FIELD_RETURN := "COUNTER STRIP / 1998\nS. WARD / IN 23:17\nABSENT 23:18\nEXIT / --\n\nNo departure was recorded.\n\nPencil note: Notebook in lower drawer. Floor release operates the catch.\n\nA fresh carbon underneath carries tonight's work-order number. Tonight's job number has appeared on Dad's old paperwork."
const ORIGINAL := "S. WARD / FIELD REPORT / 1998\n\nThe counter registered another arrival. I disconnected its feed. The motor stopped. The hall lights didn't.\n\nA man is standing by the stairs. No van, no tools. He won't answer me. When I go towards the front door, he moves in front of it.\n\nI came here about a television. I've just seen my own name crossed out in the office file. I'm still in the building.\n\nCheck every room before signing it off. Don't let the counter decide I'm gone.\n\n[The last page is missing. The report sleeve is marked: UV / inspect reverse.]"
const RECOUNT := "Dad was still inside when they marked him absent. Nobody checked.\n\nNow the register has both our names. His arrival in 1998. Mine tonight.\n\nI can correct his entry and close my call-out. Or I can attach his report and tonight's comparison, and leave the fault open for investigation. Either way, he stays missing. I need to take the receipt with me."

const MISSING_PAGE := "23:18 / Simon\n\nI rang home. Eli answered. He asked when I'd be home.\n\nI opened the lounge door. His bed was in there. His books. The little chair from his room. His drawing was on the cupboard - the one he'd put in my toolbox this morning.\n\nI know what I saw. I also know he's at home. This isn't our house.\n\nThe office radio was on our kitchen station. 104.6. The clock still says 23:18.\n\nThere's someone moving in that room. It can't be Eli. But if there's a child in here, I can't just leave.\n\nEli, if you get this: I was trying to get home. I thought I could help whoever was in that room."

const UNDERFLOOR_TEST := "No. 17 / S. Ward / 1998\nUnderfloor inspection\n\nAccess beside the cellar ramp. The passage leads to the old records store. The shelving runs on floor rails. Keep the inspection sheet on the back wall clear.\n\nDisconnected the return at the terminal box. Motor stopped. Footsteps continued overhead. They sounded like mine.\n\nI knocked on a joist. Once, then twice. Something knocked back from the passage. I stopped. It didn't.\n\nI tried the same pattern at the office test box. Notes pinned below it. The power switch stops the motor; unplugging the cable breaks the connection.\n\nI heard someone arrive, but the door hadn't opened. A sound isn't enough. I need to see who's there.\n\nMy report is still in the service drawer. I haven't signed the empty-house certificate. The counter filed it anyway. I've kept the unsigned carbon inside the return inspection box halfway down this passage."

const CONTINUITY_TEST := "OFFICE LINE TEST / S. WARD\n\nPressing the test button sends three taps through the cable. With the power on and the cable plugged in, I should hear three taps back at this box. That's how I check it's working.\n\nI switched it off and unplugged the cable. Tapped again. Nothing should have answered.\n\nI heard it from the lounge after I disconnected both. I went to the closed door to check. Nobody was in there. When I came back, the counter had printed another arrival.\n\nI kept the test reel with the service records below. Listen past the motor stopping.\n\nDon't sign this place off because a machine says it's empty. Check the rooms."

const DEAD_LINE_RESULT := "17 BRIAR LANE / COUNTER STRIP\nWARD, ELI / IN 23:17 / 1998\nEXIT / --\n\nMy name. The year Dad disappeared. I was seven.\n\nI switched the test box off and unplugged its cable. After the tapping from the lounge, this was waiting underneath the box.\n\nI wasn't here in 1998. Whatever printed this has got it wrong."

const SPARE_CARD_NOTE := "The cover was moving. There was nobody underneath it.\n\nAn eighth-birthday card. Signed Dad. Dated 1999. He missed that birthday. He missed every one after it.\n\nI don't know where this came from. It isn't how it happened."

const SPARE_GLASS_NOTE := "The cot was empty when I pulled the cover back. But in the mirror, someone still seemed to be lying under it.\n\nI looked back at the cot. There was nothing there."

static func rubbing_note(events: Dictionary={}) -> String:
	var lines: Array[String]=preload("res://scripts/case_puzzles.gd").lines(events)
	var seen: Array=events.get("uv_rows",[true,true,true])
	var observed: Array[String]=[]
	for i in 3:
		if seen[i]:observed.append(lines[i])
	return "\n".join(observed)+"\n\nDad left these lines in UV ink on the back of the report sleeve."+(" He said my room was here. I was at home." if seen[2] else "")

static func missing_page(events: Dictionary) -> String:
	return MISSING_PAGE.replace("104.6","%.1f"%preload("res://scripts/case_puzzles.gd").station(events))


static func clue(game: Node) -> String:
	if is_instance_valid(game.last_call) and not game.events.get("call_complete",false) and (game.events.get("bedroom_left",false) or game.last_call.busy() or game.events.get("call_bay_found",false)):return game.last_call.hint()
	if (game.events.get("underfloor_read",false) or game.events.get("test_reel_heard",false) or game.events.get("line_calibrated",false) or game.events.get("line_test_armed",false)) and not game.events.get("line_strip_read",false) and not game.isolated and game.player.position.y>-.2 and ((game.player.position.x>1.6 and game.player.position.z< -3) or game.events.get("line_test_armed",false)):
		if game.events.get("line_response_complete",false):return "The sound came from the lounge after I disconnected the office test box. I should check what the counter did."
		if game.events.get("line_test_armed",false):return "The power is off and the cable is unplugged. Dad listened from the hall, with the lounge shut."
		return "Dad tapped the timber below the office, then tried the test box upstairs. His note is still pinned below its controls."
	if game.events.get("case_v3",false) and game.events.get("field_return_read",false) and not game.events.get("bedroom_left",false):
		if game.events.get("last_page_read",false):return "I have Dad's last page. I can leave the room."
		if game.events.get("receiver_found",false):return "I heard something beyond the lounge door. Dad wrote that the room changed after he shut it."
		if game.events.get("carbon_read",false):return "Dad wrote down %.1f. I can try it on the office radio."%game.PUZZLES.station(game.events)
		if not game.equipment.data.uv:return "Dad marked the sleeve for UV light. I saw an inspection kit on the shed bench."
		return "Dad marked the report sleeve for UV light. I can examine it on the office desk."
	if game.events.get("departure_pending","")!="":
		if is_instance_valid(game.final_account) and game.final_account.phase()=="receipt":return "My receipt is in the lower clip on the porch register."
		return "I've kept the receipt. My car is outside the front gate."
	if game.isolated and game.events.get("case_v2",false) and not game.events.get("field_return_read",false):return "The drawer shuts when I step off the floor plate. Something heavy could hold it open."
	if game.isolated:return "The original contradicts the office file. The porch register still carries the false entry."
	if game.shed_read:return "Match the circuit names in Simon's note to the plates on the relay."
	if game.report_read:return "The key in Dad's file opens the service door and the shed padlock."
	if game.stage >= 3:return "The office equipment has power now. There may be a record of Dad's call."
	if game.fuse:return "The spare fuse is rated 13A, the same as the empty kitchen holder."
	if game.stage >= 1:return "The utility stock board lists a spare 13A fuse."
	return "The call sheet is beside the front door."

# Replace wording only for records already collected. Never grant a clue or migrate
# progression flags while loading a legacy checkpoint.
static func refresh_collected(events: Dictionary) -> void:
	var notes: Dictionary=events.get("notes",{})
	var current: Dictionary={"WHY I CAME":WHY_I_CAME,"THE OFFICE SUPPLY":OFFICE_POWER,"INSPECTION KIT":INSPECTION_KIT,"HALL MICROPHONE":HALL_MICROPHONE,WITNESS_TITLE:WITNESS_CARBON,"BRIAR LANE / TEMPORARY OFFICE":SITE,"NIGHT CALL / 17 BRIAR LANE":CALL,"ARCHIVE / 23:17:08":ARCHIVE,"SIMON'S MANUAL OVERRIDE":PROCEDURE,COMPARISON_TITLE:SOURCE_COPY,"TRANSPORT / LEADER":TRANSPORT_LEADER,"THE UNFINISHED RETURN":unfinished_return(events),INSPECTION_TITLE:rubbing_note(events),"FIELD RETURN / 1998":FIELD_RETURN,"SIMON / ORIGINAL FIELD RETURN":ORIGINAL,"TWO ARRIVALS / NO EXIT":RECOUNT,"SIMON / THE MISSING PAGE":missing_page(events),"SIMON / UNDERFLOOR TEST":UNDERFLOOR_TEST,"SIMON / CONTINUITY TEST":CONTINUITY_TEST,"UNWITNESSED ARRIVAL":DEAD_LINE_RESULT,"THE SPARE PLACE":SPARE_CARD_NOTE,"THE UTILITY GLASS":SPARE_GLASS_NOTE}
	if notes.has("TORN PAGE / IMPRESSIONS"):
		notes[INSPECTION_TITLE]=rubbing_note(events);notes.erase("TORN PAGE / IMPRESSIONS")
	if notes.has("SIMON / RETURN CHANNEL"):
		notes[COMPARISON_TITLE]=SOURCE_COPY
		notes.erase("SIMON / RETURN CHANNEL")
	for title_ in current:
		if notes.has(title_):notes[title_]=current[title_]
	if notes.has("INSPECTION KIT") and events.get("equipment_date_compared",false):notes["INSPECTION KIT"]+="\n\nI compared its 2018 stock label with the 1998 job record. That doesn't tell me who left it here, or when they used it. I kept the label separate."

static func unfinished_return(events: Dictionary) -> String:
	if events.get("bedroom_left",false):return "I found Dad's last page. I kept it with his report."
	if events.get("last_page_read",false):return "I've got Dad's last page. I need to leave that room behind."
	if events.get("receiver_found",false):return "That sound came from the lounge. I'm checking it before I sign this."
	if events.get("carbon_read",false):return "Dad wrote down our kitchen radio station. I haven't tried it yet."
	return "The last page of Dad's report is missing. He marked the sleeve for UV light. There may be something on the back that explains where he went next."
