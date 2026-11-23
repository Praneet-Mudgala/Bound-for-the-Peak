extends Area2D

const BURST_PARTICLES = preload("res://Scenes/burst_particles.tscn")

@export var fall_speed: float = 480.0
@export var shake_delay: float = 0.35

@onready var sprite: Sprite2D = $Sprite2D
@onready var trigger_zone: Area2D = $TriggerZone

var triggered: bool = false
var is_falling: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_hit)
	trigger_zone.body_entered.connect(_on_trigger_entered)

func _on_body_hit(body: Node2D) -> void:
	if not is_falling:
		return
	
	if body.is_in_group("climbers") or body is RigidBody2D:
		if body.has_method("set_anchored"):
			body.set_anchored(false)
		if body is RigidBody2D:
			body.apply_central_impulse(Vector2(0, 300.0))
		Global.lose_life()
		spawn_burst(global_position, Color(0.529, 0.81, 0.988, 1.0))
		queue_free()
	else:
		spawn_burst(global_position, Color(0.529, 0.81, 0.988, 1.0))
		queue_free()

func _on_trigger_entered(body: Node2D) -> void:
	if triggered or not body.is_in_group("climbers"):
		return
	triggered = true
	
	var timer := 0.0
	var start_x := sprite.position.x
	var start_y := sprite.position.y
	while timer < shake_delay:
		sprite.position.x = start_x + randf_range(-2.5, 2.5)
		sprite.position.y = start_y + randf_range(-2.5, 2.5)
		await get_tree().process_frame
		timer += get_process_delta_time()
	sprite.position.x = start_x
	sprite.position.y = start_y
	is_falling = true

func _process(delta: float) -> void:
	if is_falling:
		position.y += fall_speed * delta

func spawn_burst(pos: Vector2, col: Color) -> void:
	var p := BURST_PARTICLES.instantiate()
	p.global_position = pos
	add_child(p)
	p.burst(col)
