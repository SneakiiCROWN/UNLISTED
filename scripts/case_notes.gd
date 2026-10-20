extends RefCounted

const CALL := "Work Order 017 / 17 Briar Lane\nContractor: Eli Ward. Listed occupancy: vacant.\n\nComplaint: television operating after the mains supply was disconnected. Inspect the carrier before energising the circuit.\n\nClose-out requires electrical isolation and a completed attendance record.\n\nLast service: 1998. Signed S. W.\nA utility stock label has been stapled to the sheet: BS1362 / 13A."
const ARCHIVE := "1998 / Simon Ward / Electrical contractor\nEntered 23:17. Departure not recorded.\nAt 23:18 the register changed his status to ABSENT. The supply remained under load.\n\nThe attached family contact names Eli Ward, age seven. Your father never came home from this call.\n\nCLOSE-OUT DISPUTED / No witness to departure. Original field recording requested. None supplied.\n\nA later entry repeats tonight's work order, including your name. It is dated 1998.\nA brass service key is clipped to the file."
const PROCEDURE := "Relay 17 / Simon Ward / handwritten\nA small stairwell key is clipped to the margin.\n\nThe register reports no occupant. The meter disagrees. Do not cut a loaded occupancy feed.\n\nClose COOLANT first. Close SUPPLY second. Close OCCUPANCY last. The manifold plates identify each circuit. Then pull the manual isolator.\n\nThe front call sheet is a duplicate attendance record. In 1998 the call was closed by marking a worker ABSENT. There is no departure in the book. An absence is not an exit.\n\nI heard your footsteps above me tonight, Eli. You are seven. You are at home."
const SOURCE_COPY := "1998 / S. WARD / ORIGINAL FIELD RECORD RETAINED\nCLOSE-OUT DISPUTED / No departure witnessed.\n\nThe return channel contains an arrival absent from the field microphone.\n\nThe house can repeat a movement. It cannot understand a departure. Do not erase the missing person to make the count balance.\n\nThe duplicate has a blank witness line. You could attach this record to the attendance sheet and leave Simon's case open.\n\nBelow it, in new ink: E. WARD / THE SOURCE REMAINS."

static func clue(game: Node) -> String:
	if game.isolated:return "Electrical work complete. The porch call sheet is the attendance register. Simon has no recorded departure."
	if game.shed_read:return "Match the circuit names in Simon's note to the plates on the relay."
	if game.report_read:return "The brass key fits the service door beside the utility bench."
	if game.stage >= 3:return "Power reached the office archive. Its date matters."
	if game.fuse:return "The kitchen carrier and the spare part share the same rating."
	if game.stage >= 1:return "The utility stock board lists a spare electrical cartridge."
	return "The paper beside the entrance explains why you were sent here."
