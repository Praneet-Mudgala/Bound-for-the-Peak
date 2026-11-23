extends Control


func _ready() -> void:
	$VBoxContainer/StatsLabel.text = "Altitude Reached: " + str(Global.current_meters) + "m\nPersonal Best: " + str(Global.best_altitude_meters) + "m\nClimbing Time: " + Global.get_formatted_time()
	
	$VBoxContainer/RetryButton.pressed.connect(_on_retry_pressed)
	$VBoxContainer/MenuButton.pressed.connect(_on_menu_pressed)

func _on_retry_pressed() -> void:
	Global.start_new_run()
	get_tree().change_scene_to_file("res://Scenes/main_climb.tscn")

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/title_screen.tscn")
