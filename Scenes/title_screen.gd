extends Control



func _on_play_pressed() -> void:
	Global.start_new_run()
	get_tree().change_scene_to_file("res://Scenes/main_climb.tscn")

func _on_controls_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/controls_screen.tscn")
