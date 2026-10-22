extends RefCounted

const TRANSPORT_LEADER := "HALL MICROPHONE / NO RECORDING YET\n\nPencil note: Walk past the microphone. Let it record your steps, then stand still."

const RUBBING_LINES := ["Kitchen radio: 104.6.","I phoned home. Eli answered. He's safe.","I shut the lounge door. Now it's his room."]

const INSPECTION_TITLE := "REPORT SLEEVE / INSPECTION"

const COMPARISON_TITLE := "ELI / TONIGHT'S COMPARISON"

const SITE := "Briar Lane clearance works / 1998\nSite office: No. 17\n\nNos. 13-19 are vacant. Keep No. 17 open until the final inspection. Front room: waiting area. Rear room: property files.\n\nLeave the service feed on until everyone has signed out. Check the electrical counter against the paper register. If they disagree, check the building. Do not certify it empty from the counter alone.\n\nRemove this address from the call-out list when the site closes.\n\nHandwritten below: Counter says two arrivals. Ward is the only name in the sign-in book."

const CALL := "PROPERTY SERVICES / WORK ORDER 017\n17 Briar Lane / Eli Ward\n\nReported fault: television playing in a vacant property. Supply listed as disconnected. Caller gave no name or contact number.\n\nDispatch note: Address removed from service list in 1999. Confirm address before attending. Check the building before signing the return. Keep any corrected entries with the job sheet.\n\nMy note: Dispatch nearly cancelled it. Then they said Briar Lane. I've still got Dad's last job slip. Same house. I asked them to give me the call."
const ARCHIVE := "PROPERTY FILE / SIMON WARD\nElectrical contractor / 1998\n\n23:17 - Signed in.\n23:18 - Status changed to ABSENT.\nDeparture time: blank. No door opening recorded.\n\nMissing-person report attached. Ward did not return from this call. His son, Eli, was seven.\n\nService-camera still: a second man at the stairs. No name or vehicle recorded.\n\nSimon's pencil note: He stands there whenever I try to leave. Keep my notebook. Don't file this as an empty property.\n\nA brass service key is clipped inside the folder."
const PROCEDURE := "SERVICE SHED / S. WARD / 1998\n\nIsolation order:\nCOOLING first, then SUPPLY, then COUNTER.\nPull the isolator only after all three lines are closed. Trace the service names on the plates. The colours are only line identifiers.\n\nThe lower return drawer has a spring catch. Keep the floor release weighted while opening it. Disconnect the feed first.\n\nI've left my original report in that drawer. The office copy has been changed; use the original if I don't come back. Someone keeps walking above me. If I stop, he stops. I haven't seen another contractor all night.\n\nPlease check the house if I don't sign out.\n\nA small key is taped to the back."
const SOURCE_COPY := "MY RECORDING / TONIGHT\n\nA is the hall microphone. Those are my footsteps. B plays them back. When B finishes, another step comes from the office doorway. I wasn't moving.\n\nThis isn't an old recording of Dad. It's happening to me, here, tonight.\n\nI've kept the comparison with his report. If I submit both, dispatch will have more than a missing entry to investigate."
const FIELD_RETURN := "COUNTER STRIP / 1998\nS. WARD / IN 23:17\nABSENT 23:18\nEXIT / --\n\nNo departure was recorded.\n\nPencil note: Notebook in lower drawer. Floor release operates the catch.\n\nA fresh carbon underneath carries tonight's work-order number. Tonight's job is being filed against Dad's old record."
const ORIGINAL := "S. WARD / FIELD REPORT / 1998\n\nThe counter registered another arrival. I disconnected its feed. The motor stopped. The hall lights didn't.\n\nA man is standing by the stairs. No van, no tools. He won't answer me. When I go towards the front door, he moves in front of it.\n\nI came here about a television. I've just seen my own name crossed out in the office file. I'm still in the building.\n\nCheck every room before signing it off. Don't let the counter decide I'm gone.\n\n[The last page is missing. The report sleeve is marked: UV / inspect reverse.]"
const RECOUNT := "Dad was still inside when they marked him absent. Nobody checked.\n\nNow the register has both our names. His arrival in 1998. Mine tonight.\n\nI can correct his entry and close my call-out. Or I can attach his report and tonight's comparison, and leave the fault open for investigation. Either way, he stays missing. I need to take the receipt with me."

const MISSING_PAGE := "23:18 / Simon\n\nI rang home. Eli answered. He asked if I'd be back for tea.\n\nI opened the lounge door. His bed was in there. His books. The little chair from his room. His drawing was on the cupboard - the one he'd put in my toolbox this morning.\n\nI know what I saw. I also know he's at home. This isn't our house.\n\nThe office radio was on our kitchen station. 104.6. The clock still says 23:18.\n\nThere's someone moving in that room. It can't be Eli. But if there's a child in here, I can't just leave.\n\nEli, if you get this: I was trying to get home to you. I didn't choose to stay."

const UNDERFLOOR_TEST := "No. 17 / S. Ward / 1998\nUnderfloor inspection\n\nAccess beside the cellar ramp. Records store at the far end. The mobile rack is across the inspection bay; the rails are clear.\n\nDisconnected the return at the terminal box. Motor stopped. Footsteps continued overhead. They sounded like mine.\n\nI knocked on a joist. Once, then twice. Something knocked back from the passage. I stopped. It didn't.\n\nI tried the same pattern at the office test box. Notes pinned below it. Feed switch stops the motor; the return plug disconnects the line.\n\nThe sound of somebody coming back isn't enough. Check the door. See who it is.\n\nMy report is still in the service drawer. I haven't signed the empty-house certificate."

const CONTINUITY_TEST := "LINE TEST / S. WARD\n\n1. Leave feed and return connected. Tap the striker and listen to the reply.\n2. Switch feed OFF. Remove the return plug. Tap again. The box should stay silent.\n\nI used the rhythm marked on the joist below this office.\n\nWith both leads disconnected, I heard the reply from the lounge. The counter then printed another arrival. I checked the front door and register. Nobody had come in.\n\nKeep the strip. A printed name doesn't mean a person arrived."

const DEAD_LINE_RESULT := "17 BRIAR LANE / COUNTER STRIP\nWARD, ELI / IN 23:17 / 1998\nEXIT / --\n\nMy name. The year Dad disappeared. I was seven.\n\nI stopped the motor. I pulled the return lead. It still printed this.\n\nThat strip doesn't prove I was here. It proves the counter can lie."

const SPARE_CARD_NOTE := "The cover was moving. There was nobody underneath it.\n\nAn eighth-birthday card. Signed Dad. Dated 1999. He missed that birthday. He missed every one after it.\n\nI don't know where this came from. It isn't how it happened."

const SPARE_GLASS_NOTE := "The cot was empty when I pulled the cover back. In the mirror, something was still underneath it.\n\nFirst the strip. Now the card. This house keeps getting my life wrong."

static func rubbing_note(events: Dictionary={}) -> String:
	var lines: Array[String]=preload("res://scripts/case_puzzles.gd").lines(events)
	var seen: Array=events.get("uv_rows",[true,true,true])
	var observed: Array[String]=[]
	for i in 3:
		if seen[i]:observed.append(lines[i])
	return "\n".join(observed)+"\n\nDad wrote this on the report sleeve in inspection ink."+(" He said my room was here. I was at home." if seen[2] else "")

static func missing_page(events: Dictionary) -> String:
	return MISSING_PAGE.replace("104.6","%.1f"%preload("res://scripts/case_puzzles.gd").station(events))


static func clue(game: Node) -> String:
	if game.events.get("underfloor_read",false) and not game.events.get("line_strip_read",false) and not game.isolated and game.player.position.y>-.2 and ((game.player.position.x>1.6 and game.player.position.z< -3) or game.events.get("line_test_armed",false)):
		if game.events.get("line_response_complete",false):return "The sound came from the lounge after I disconnected the office test box. I should check what the counter did."
		if game.events.get("line_test_armed",false):return "Both leads are disconnected. Dad listened from the hall, with the lounge shut."
		return "Dad tested the timber below the office, then the continuity box upstairs. His annotation is still pinned there."
	if game.events.get("case_v3",false) and game.events.get("field_return_read",false) and not game.events.get("bedroom_left",false):
		if game.events.get("last_page_read",false):return "I have Dad's last page. I can leave the room."
		if game.events.get("receiver_found",false):return "I heard something beyond the lounge door. Dad wrote that the room changed after he shut it."
		if game.events.get("carbon_read",false):return "Dad wrote down %.1f. I can try it on the office radio."%game.PUZZLES.station(game.events)
		if not game.equipment.data.uv:return "Dad marked the sleeve for inspection light. The equipment case in the shed had an inspection-head label."
		return "Dad marked the report sleeve for inspection light. I can examine it on the office desk."
	if game.events.get("departure_pending","")!="":return "I have the receipt. I need to get it out to the lane."
	if game.isolated and game.events.get("case_v2",false) and not game.events.get("field_return_read",false):return "The spring catch closes when I step off the floor release. It needs more weight."
	if game.isolated:return "The original contradicts the office file. The porch register still carries the false entry."
	if game.shed_read:return "Match the circuit names in Simon's note to the plates on the relay."
	if game.report_read:return "The brass key fits the service door beside the utility bench."
	if game.stage >= 3:return "The office equipment has power now. There may be a record of Dad's call."
	if game.fuse:return "The kitchen carrier and the spare part share the same rating."
	if game.stage >= 1:return "The utility stock board lists a spare electrical cartridge."
	return "The call sheet is beside the front door."

# Replace wording only for records already collected. Never grant a clue or migrate
# progression flags while loading a legacy checkpoint.
static func refresh_collected(events: Dictionary) -> void:
	var notes: Dictionary=events.get("notes",{})
	var current: Dictionary={"BRIAR LANE / TEMPORARY OFFICE":SITE,"NIGHT CALL / 17 BRIAR LANE":CALL,"ARCHIVE / 23:17:08":ARCHIVE,"SIMON'S MANUAL OVERRIDE":PROCEDURE,COMPARISON_TITLE:SOURCE_COPY,"TRANSPORT / LEADER":TRANSPORT_LEADER,"THE UNFINISHED RETURN":unfinished_return(events),INSPECTION_TITLE:rubbing_note(events),"FIELD RETURN / 1998":FIELD_RETURN,"SIMON / ORIGINAL FIELD RETURN":ORIGINAL,"TWO ARRIVALS / NO EXIT":RECOUNT,"SIMON / THE MISSING PAGE":missing_page(events),"SIMON / UNDERFLOOR TEST":UNDERFLOOR_TEST,"SIMON / CONTINUITY TEST":CONTINUITY_TEST,"UNWITNESSED ARRIVAL":DEAD_LINE_RESULT,"THE SPARE PLACE":SPARE_CARD_NOTE,"THE UTILITY GLASS":SPARE_GLASS_NOTE}
	if notes.has("TORN PAGE / IMPRESSIONS"):
		notes[INSPECTION_TITLE]=rubbing_note(events);notes.erase("TORN PAGE / IMPRESSIONS")
	if notes.has("SIMON / RETURN CHANNEL"):
		notes[COMPARISON_TITLE]=SOURCE_COPY
		notes.erase("SIMON / RETURN CHANNEL")
	for title_ in current:
		if notes.has(title_):notes[title_]=current[title_]

static func unfinished_return(events: Dictionary) -> String:
	if events.get("bedroom_left",false):return "I found Dad's last page. I kept it with his report."
	if events.get("last_page_read",false):return "I've got Dad's last page. I need to leave that room behind."
	if events.get("receiver_found",false):return "That sound came from the lounge. I'm checking it before I sign this."
	if events.get("carbon_read",false):return "Dad wrote down our kitchen radio station. I haven't tried it yet."
	return "Dad's last page is missing. The report sleeve says to check its reverse under an inspection lamp. I want to know what he left before I sign anything."
