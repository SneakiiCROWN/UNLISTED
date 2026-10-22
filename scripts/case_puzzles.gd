extends RefCounted
# Solutions are generated once, stored explicitly, and never redrawn on load.
const STATIONS := [914,936,962,994,1012,1034,1066]
const ROLES := ["SUPPLY","COOLING","COUNTER"]
static func generate(events: Dictionary,seed_: int=-1) -> void:
	var rng:=RandomNumberGenerator.new()
	if seed_<0:rng.randomize();seed_=rng.randi_range(1,2147483646)
	rng.seed=seed_
	var roles: Array=[0,1,2]
	for i in range(2,0,-1):
		var j:=rng.randi_range(0,i);var swap: int=roles[i];roles[i]=roles[j];roles[j]=swap
	events.puzzles={"version":1,"seed":seed_,"station":STATIONS[rng.randi_range(0,STATIONS.size()-1)],"roles":roles}
static func ensure(events: Dictionary) -> void:
	if not events.has("puzzles"):
		events.puzzles={"version":0,"station":1046,"roles":[0,1,2]}
static func station(events: Dictionary) -> float:
	return float(events.get("puzzles",{}).get("station",1046))/10.0
static func roles(events: Dictionary) -> Array[int]:
	var result: Array[int]=[]
	for value in events.get("puzzles",{}).get("roles",[0,1,2]):result.append(int(value))
	return result
static func sequence(events: Dictionary) -> Array[int]:
	var mapping:=roles(events);var result: Array[int]=[]
	for role in [1,0,2]:result.append(mapping.find(role))
	return result
static func plate(events: Dictionary,index: int) -> String:
	return ["R / RED","B / BLUE","W / WHITE"][index]+"\n"+ROLES[int(roles(events)[index])]
static func lines(events: Dictionary) -> Array[String]:
	return ["Kitchen radio: %.1f."%station(events),"I phoned home. Eli answered. He's safe.","I shut the lounge door. Now it's his room."]
