extends Node3D

var opened := false
var locked := false
var pivot: Node3D
var game: Node
var tween: Tween
var door_id := ""
var open_angle := -1.55
var clear_half_width := 0.95
var lock_visual: Node3D

func open_away_from(point: Vector3) -> void:
	# Swing into the unoccupied side. A fixed outward swing trapped a player
	# approaching the lounge leaf while its animation was still in progress.
	open_angle = -1.75 if to_local(point).z < 0 else 1.75

func use() -> void:
	if locked:
		game.message("A brass padlock holds the shed door." if door_id=="shed" else "Locked.")
		game.sound("latch", global_position, -20)
		return
	if not opened:open_away_from(game.player.global_position)
	set_open(not opened)
	if is_instance_valid(game.threat):game.threat.hear(global_position,6.0)

func set_open(value: bool, duration := 0.85) -> void:
	if not value and opened and duration>0.05:
		var local := to_local(game.player.global_position)
		if absf(local.y)<0.6 and absf(local.x)<clear_half_width and absf(local.z)<0.48:
			game.message("The gate is obstructed." if door_id=="front_gate" else "The doorway is obstructed.",1.5)
			return
	var changed := value!=opened and duration>0.05
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
