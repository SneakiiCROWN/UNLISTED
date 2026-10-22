extends Node3D

var opened := false
var locked := false
var pivot: Node3D
var game: Node
var tween: Tween
var door_id := ""
var open_angle := -1.55
var clear_half_width := 0.95
var arrival_busy := false
var lock_visual: Node3D

func open_away_from(point: Vector3) -> void:
	# Swing into the unoccupied side. A fixed outward swing trapped a player
	# approaching the lounge leaf while its animation was still in progress.
	open_angle = -1.75 if to_local(point).z < 0 else 1.75

func restore_arrival() -> void:
	arrival_busy = false
	if tween and tween.is_valid():tween.kill()
	opened = false
	pivot.rotation.y = float(game.events.get("front_ajar_angle",0.20))

func knock_once() -> void:
	open_away_from(game.player.global_position)
	game.events.front_checked = true
	game.events.front_ajar = true
	game.events.front_ajar_angle = signf(open_angle)*0.20
	game.sound("foley/drop_wood_1",global_position+Vector3(0,1.35,0),-23).pitch_scale=0.88
	arrival_busy = true
	if tween and tween.is_valid():tween.kill()
	tween = create_tween()
	tween.tween_interval(0.48)
	tween.tween_callback(func():game.sound("door",global_position,-34).pitch_scale=0.72)
	tween.tween_property(pivot,"rotation:y",float(game.events.front_ajar_angle),0.95).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func():arrival_busy=false)
	game.save_game(true)

func use() -> void:
	if arrival_busy:return
	if door_id=="front" and game.events.get("arrival_check",false) and not game.events.get("front_checked",false):
		knock_once()
		return
	if locked:
		game.message("A brass padlock holds the shed door." if door_id=="shed" else "Locked.")
		game.sound("latch", global_position, -20)
		return
	if not opened:open_away_from(game.player.global_position)
	set_open(not opened)
	if is_instance_valid(game.threat):game.threat.hear(global_position,6.0)

func set_open(value: bool, duration := 0.85, restoring := false) -> void:
	if not value and opened and duration>0.05:
		var local := to_local(game.player.global_position)
		if absf(local.y)<0.6 and absf(local.x)<clear_half_width and absf(local.z)<0.48:
			game.message("The gate is obstructed." if door_id=="front_gate" else "The doorway is obstructed.",1.5)
			return
	var changed := value!=opened and duration>0.05
	if door_id=="front":
		arrival_busy=false
	if door_id=="front" and not restoring:
		game.events.erase("front_ajar")
		if value and game.events.get("arrival_check",false):game.events.front_checked=true
	opened = value
	if tween and tween.is_valid(): tween.kill()
	tween = create_tween()
	if changed:
		game.sound("latch",global_position,-29).pitch_scale = 0.9
		tween.tween_interval(0.07)
		tween.tween_callback(func():game.sound("door",global_position,-28).pitch_scale = 0.82)
	tween.tween_property(pivot, "rotation:y", open_angle if opened else 0.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if changed and not value:tween.tween_callback(func():game.sound("latch",global_position,-28).pitch_scale = 0.8)

func _process(_delta: float) -> void:
	if is_instance_valid(lock_visual):lock_visual.visible=locked
