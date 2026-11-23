extends Node2D

func _ready() -> void:
	$AnimatedSprite2D.play("Wave")

func set_as_record_flag(meters: int) -> void:
	$HeightLabel.text = "Personal Best: " + str(meters) + "m"
