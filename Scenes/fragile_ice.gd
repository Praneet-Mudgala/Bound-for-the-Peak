extends StaticBody2D

@export var break_delay: float = 2.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var detector: Area2D = $TouchDetector

var is_breaking: bool = false


func _ready() -> void:
	anim.play("Normal")
	detector.body_entered.connect(_on_climber_touched)

func _on_climber_touched(body: Node2D) -> void:
	if is_breaking:
		return
	if body.is_in_group("climbers"):
		start_shattering()

func start_shattering() -> void:
	is_breaking = true
	anim.play("Broken")
	
	var timer := 0.0
	var start_x := anim.position.x
	
	while timer < break_delay:
		anim.position.x = start_x + randf_range(-3.0, 3.0)
		await get_tree().process_frame
		timer += get_process_delta_time()
	
	for body in detector.get_overlapping_bodies():
		if body.has_method("set_anchored") and body.get("is_anchored"):
			body.set_anchored(false)
	
	collision.set_deferred("disabled", true)
	queue_free()
