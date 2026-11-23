extends Node2D

const BURST_PARTICLES = preload("res://Scenes/burst_particles.tscn")
const DEATH_SCREEN_PATH := "res://Scenes/death_screen.tscn"
const FLAG_SCENE = preload ("res://Scenes/flag.tscn")
const CHUNK_HEIGHT : float = 648.0

@export var mountain_chunks: Array[PackedScene] = []
@export var lifesaver_texture: Texture2D

@onready var climber_a: RigidBody2D = $ClimberA
@onready var climber_b: RigidBody2D = $ClimberB
@onready var rope_line: Line2D = $RopeLine
@onready var camera: Camera2D = $Camera2D

var shake_amount: float = 0.0
var next_spawn_y: float = 0.0
var spawned_chunks: Array[Node2D] = []
var highest_y: float = 324.0
var start_y: float = 190.0

func _ready() -> void:
	climber_a.partner = climber_b
	climber_b.partner = climber_a
	
	climber_a.set_anchored(false)
	climber_a.is_active = true
	
	climber_b.set_anchored(false)
	climber_b.is_active = false
	
	
	start_y = climber_a.global_position.y + 160.0
	highest_y = start_y
	
	var spawn_flag := FLAG_SCENE.instantiate()
	spawn_flag.global_position = Vector2(climber_a.global_position.x - 40.0, 550.0)
	spawn_flag.get_node("HeightLabel").text = "Base Camp: 0m"
	add_child(spawn_flag)
	
	if Global.best_y < start_y - 36.0:
		var record_flag := FLAG_SCENE.instantiate()
		record_flag.global_position = Vector2(576.0, Global.best_y)
		record_flag.set_as_record_flag(Global.best_altitude_meters)
		add_child(record_flag)
	
	
	for i in range(3):
		spawn_next_chunk()
	
	climber_a.update_visuals()
	climber_b.update_visuals()
	
	Global.life_lost.connect(func(): shake_amount = 12.0)


func _process(delta: float) -> void:
	rope_line.points = [climber_a.global_position, climber_b.global_position]
	var dist := climber_a.global_position.distance_to(climber_b.global_position)
	var tension := clampf(dist / 160.0, 0.0, 1.0)
	rope_line.default_color = Color("d7b067").lerp(Color("e8be6fff"), pow(tension, 3.0))
	rope_line.width = lerpf(5.0, 2.5, tension)
	
	var midpoint := (climber_a.global_position + climber_b.global_position) / 2.0
	camera.global_position = camera.global_position.lerp(midpoint, 6.0 * delta)
	
	Global.update_altitude(midpoint.y, start_y)
	
	if Input.is_action_just_pressed("Anchor"):
		toggle_anchor()
	
	if Input.is_action_just_pressed("Swap"):
		swap_active_climbers()
	
	if Input.is_action_just_pressed("Unanchor"):
		release_anchor_only()
	
	if Input.is_action_just_pressed("Toss"):
		toss_partner()
	
	var bounds_midpoint := (climber_a.global_position + climber_b.global_position) / 2.0
	if bounds_midpoint.y < highest_y:
		highest_y = bounds_midpoint.y
	if midpoint.y < highest_y:
		highest_y = midpoint.y
		Global.update_altitude(highest_y, start_y)
	camera.global_position = camera.global_position.lerp(Vector2(576.0, highest_y), 6.0 * delta)
	
	if climber_a.global_position.y > highest_y + 620.0 and climber_b.global_position.y > highest_y + 620.0:
		handle_fall()
	
	
	if highest_y < next_spawn_y + 1000.0:
		spawn_next_chunk()
		cleanup_old_chunks()
	
	camera.offset = Vector2( randf_range(-shake_amount, shake_amount), randf_range(-shake_amount, shake_amount) )
	shake_amount = move_toward(shake_amount, 0.0, 40.0 * delta)

func release_anchor_only() -> void:
	if climber_a.is_anchored:
		climber_a.set_anchored(false)
	if climber_b.is_anchored:
		climber_b.set_anchored(false)
	
	climber_a.update_visuals()
	climber_b.update_visuals()

func toss_partner() -> void:
	if climber_a.is_anchored or climber_b.is_anchored:
		return
	if climber_a.global_position.distance_to(climber_b.global_position) > 55.0:
		return
	var thrower := climber_a if climber_a.is_active else climber_b
	var flyer := climber_b if climber_a.is_active else climber_a
	if not thrower.is_on_ground():
		return
	var aim_x := Input.get_axis("Left", "Right") * 220.0
	flyer.linear_velocity = Vector2(aim_x, -680.0)
	spawn_burst(thrower.global_position, Color.WHITE)
	swap_active_climbers()

func handle_fall() -> void:
	Global.lose_life()
	
	var current_chunk_index := floori(highest_y / CHUNK_HEIGHT)
	var chunk_bottom_y := (current_chunk_index + 1) * CHUNK_HEIGHT - 54.0
	var spawn_x := 160.0
	
	var rescue_ledge := StaticBody2D.new()
	var sprite := Sprite2D.new()
	sprite.texture = lifesaver_texture
	
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = lifesaver_texture.get_size()
	col.shape = rect
	
	rescue_ledge.add_child(sprite)
	rescue_ledge.add_child(col)
	rescue_ledge.global_position = Vector2(spawn_x, (chunk_bottom_y) - 150.0 )
	add_child(rescue_ledge)
	spawn_burst(rescue_ledge.global_position, Color("faabaeff"))
	
	climber_a.set_anchored(false)
	climber_a.is_active = true
	climber_a.global_position = Vector2(spawn_x - 24.0, chunk_bottom_y - 40.0)
	climber_a.update_visuals()
	climber_b.set_anchored(false)
	climber_b.is_active = false
	climber_b.global_position = Vector2(spawn_x + 24.0, chunk_bottom_y - 40.0)
	climber_b.update_visuals()
	
	despawn_lifesaver(rescue_ledge)

func despawn_lifesaver(ledge: StaticBody2D) -> void:
	if not is_inside_tree():
		return
	await get_tree().create_timer(3.5).timeout
	if not is_instance_valid(ledge):
		return
	for i in range(6):
		ledge.visible = not ledge.visible
		await get_tree().create_timer(0.25).timeout
		if not is_instance_valid(ledge):
			return
	spawn_burst(ledge.global_position, Color.WHITE)
	ledge.queue_free()

func spawn_next_chunk() -> void:
	if mountain_chunks.is_empty():
		return
	
	var chosen_chunk: PackedScene = mountain_chunks.pick_random()
	var chunk_instance: Node2D = chosen_chunk.instantiate()
	
	next_spawn_y -= CHUNK_HEIGHT
	chunk_instance.position = Vector2(0, next_spawn_y)
	add_child(chunk_instance)
	spawned_chunks.append(chunk_instance)

func cleanup_old_chunks() -> void:
	for i in range(spawned_chunks.size() -1, -1, -1):
		var chunk := spawned_chunks[i]
		if chunk.position.y > highest_y + (CHUNK_HEIGHT * 2.0):
			chunk.queue_free()
			spawned_chunks.remove_at(i)

func toggle_anchor() -> void:
	var active := climber_a if climber_a.is_active else climber_b
	var partner := climber_b if climber_a.is_active else climber_a
	
	if active.is_anchored:
		active.set_anchored(false)
	elif active.can_anchor():
		partner.set_anchored(false)
		active.set_anchored(true)
		spawn_burst(active.global_position, Color("b0dffcff"))
		active.is_active = false
		partner.is_active = true
	elif !active.can_anchor():
		partner.set_anchored(false)
		active.set_anchored(false)
		active.is_active = false
		partner.is_active = true
	
	climber_a.update_visuals()
	climber_b.update_visuals()

func swap_active_climbers() -> void:
	if climber_a.is_active and not climber_b.is_anchored:
		climber_a.is_active = false
		climber_b.is_active = true
	elif climber_b.is_active and not climber_a.is_anchored:
		climber_a.is_active = true
		climber_b.is_active = false
	climber_a.update_visuals()
	climber_b.update_visuals()

func spawn_burst(pos: Vector2, col: Color) -> void:
	var p := BURST_PARTICLES.instantiate()
	p.global_position = pos
	add_child(p)
	p.burst(col)
