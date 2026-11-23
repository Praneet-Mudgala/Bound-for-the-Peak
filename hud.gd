extends CanvasLayer

@export var intact_life_texture: Texture2D
@export var broken_life_texture: Texture2D

@onready var life_icons: Array[TextureRect] = [
	$LivesContainer/Life1,
	$LivesContainer/Life2,
	$LivesContainer/Life3
]

func _ready() -> void:
	$PauseOverlay.visible = false
	$PauseOverlay/PauseBox.visible = true
	$PauseOverlay/ControlsBox.visible = false
	
	$PauseOverlay/PauseBox/ResumeButton.pressed.connect(toggle_pause)
	$PauseOverlay/PauseBox/RetryButton.pressed.connect(_on_retry_pressed)
	$PauseOverlay/PauseBox/ControlsButton.pressed.connect(_on_controls_pressed)
	$PauseOverlay/PauseBox/MenuButton.pressed.connect(_on_menu_pressed)
	$PauseOverlay/ControlsBox/BackButton.pressed.connect(_on_back_pressed)

func _process(_delta: float) -> void:
	for i in range(life_icons.size()):
		if i < Global.lives:
			life_icons[i].texture = intact_life_texture
		else:
			life_icons[i].texture = broken_life_texture
	
	$HudLabel.text = "Altitude: " + str(Global.current_meters) + "m (Best: " + str(Global.best_altitude_meters) + "m)  |  Time: " + Global.get_formatted_time()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause() -> void:
	var paused := not get_tree().paused
	get_tree().paused = paused
	Global.is_running = not paused
	$PauseOverlay.visible = paused
	$PauseOverlay/PauseBox.visible = true
	$PauseOverlay/ControlsBox.visible = false

func _on_retry_pressed() -> void:
	get_tree().paused = false
	Global.start_new_run()
	get_tree().reload_current_scene()

func _on_controls_pressed() -> void:
	$PauseOverlay/PauseBox.visible = false
	$PauseOverlay/ControlsBox.visible = true

func _on_back_pressed() -> void:
	$PauseOverlay/PauseBox.visible = true
	$PauseOverlay/ControlsBox.visible = false

func _on_menu_pressed() -> void:
	get_tree().paused = false
	Global.stop_run()
	get_tree().change_scene_to_file("res://Scenes/title_screen.tscn")
