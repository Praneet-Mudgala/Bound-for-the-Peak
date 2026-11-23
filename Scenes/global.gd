extends Node

signal life_lost

var lives: int = 3
var current_meters: int = 0
var run_time: float = 0.0
var is_running: bool = false

var best_y: float = 999999.0
var best_altitude_meters: int = 0

func update_record(current_y: float, start_y: float) -> void:
	if current_y < best_y:
		best_y = current_y
		best_altitude_meters = max(best_altitude_meters, int((start_y - current_y) / 36.0))
		


func start_new_run() -> void:
	lives = 3
	current_meters = 0
	run_time = 0.0
	is_running = true

func stop_run() -> void:
	is_running = false

func _process(delta: float) -> void:
	if is_running:
		run_time += delta

func update_altitude(current_y: float, start_y: float) -> void:
	var new_meters: int = maxi(0, int((start_y - current_y) / 36.0))
	current_meters = new_meters
	if current_y < best_y:
		best_y = current_y
		best_altitude_meters = max(best_altitude_meters, current_meters)

func get_formatted_time() -> String:
	@warning_ignore("integer_division")
	var mins := int(run_time) / 60
	var secs := int(run_time) % 60
	var ms := int( (run_time - int(run_time)) * 100 )
	return "%02d:%02d.%02d" % [mins, secs, ms]

func lose_life() -> void:
	lives -= 1
	life_lost.emit()
	if lives <= 0:
		stop_run()
		get_tree().change_scene_to_file("res://Scenes/death_screen.tscn")
