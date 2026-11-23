extends Control

var flakes: Array[ColorRect] = []
var speeds: Array[Vector2] = []

func _ready() -> void:
	randomize()
	var screen_size := get_viewport_rect().size
	
	for i in range(30):
		var flake := ColorRect.new()
		var sz := randf_range(2.0, 5.0)
		flake.size = Vector2(sz, sz)
		flake.color = Color(1.0, 1.0, 1.0, randf_range(0.4, 0.85))
		flake.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(flake)
		flake.position = Vector2( randf_range(0.0, screen_size.x), randf_range(0.0, screen_size.y) )
		flakes.append(flake)
		speeds.append( Vector2( randf_range(15.0, 40.0), randf_range(45.0, 95.0) ) )

func _process(delta: float) -> void:
	var screen_size := get_viewport_rect().size
	
	for i in range(flakes.size()):
		flakes[i].position += speeds[i] * delta
		
		if flakes[i].position.y > screen_size.y:
			flakes[i].position.y = -5.0
			flakes[i].position.x = randf_range(0.0, screen_size.x)
		
		if flakes[i].position.x > screen_size.x + 5.0:
			flakes[i].position.x = -5.0
