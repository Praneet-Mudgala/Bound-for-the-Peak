extends Node2D

@onready var sky: Sprite2D = $Sky
@onready var far_mountains: Sprite2D = $FarMountains
@onready var near_mountains: Sprite2D = $NearMountains
@onready var back_clouds: Sprite2D = $BackClouds
@onready var front_clouds: Sprite2D = $FrontClouds


func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	var cam_top_left := camera.global_position - Vector2(576.0, 324.0)
	
	sky.global_position = cam_top_left
	back_clouds.global_position = cam_top_left
	front_clouds.global_position = cam_top_left
	
	far_mountains.global_position = Vector2(cam_top_left.x, (cam_top_left.y * 0.85) + 140.0 )
	near_mountains.global_position = Vector2(cam_top_left.x, (cam_top_left.y * 0.70) + 160.0 )
	
