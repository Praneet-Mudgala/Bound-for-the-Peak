extends Area2D

@export var lift_force: float = 1650.0
@export var gust_size: Vector2 = Vector2(72.0, 252.0)

var streaks: Array[ColorRect] = []
var streak_speeds: Array[float] = []

func _ready() -> void:
	for i in range(10):
		var line := ColorRect.new()
		line.size = Vector2(2.0, randf_range(0.35, 0.75))
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(line)
		line.position = Vector2(
			randf_range( -gust_size.x * 0.45, gust_size.x * 0.45 ),
			randf_range( -gust_size.y * 0.5, gust_size.y * 0.5 )
		)
		streaks.append(line)
		streak_speeds.append( randf_range(180.0, 320.0) )


func _process(delta: float) -> void:
	var top_y := -gust_size.y * 0.5
	var bottom_y := gust_size.y * 0.5
	
	for i in range(streaks.size()):
		streaks[i].position.y -= streak_speeds[i] * delta
		if streaks[i].position.y < top_y:
			streaks[i].position.y = bottom_y
			streaks[i].position.x = randf_range( -gust_size.x * 0.45, gust_size.x * 0.45 )

func _physics_process(_delta: float) -> void:
	for body in get_overlapping_bodies():
		if body is RigidBody2D and not body.get("is_anchored"):
			body.apply_central_force(Vector2(0, -lift_force))
