extends RigidBody2D

@export var max_anchor_time: float = 5.0
@export var swing_force: float = 1200.0
@export var hop_impulse: float = 280.0
@export var max_rope_length: float = 150.0

@onready var wall_detector: Area2D = $WallDetector
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var anchor_timer: float = 0.0
var is_active: bool = false
var is_anchored: bool = false
var partner: RigidBody2D = null

func _ready() -> void:
	update_visuals()
	can_sleep = false
	

func _process(delta: float) -> void:
	if has_node("AnchorIndicator"):
		$AnchorIndicator.visible = is_active and not is_anchored and can_anchor()
	
	if is_anchored:
		anchor_timer += delta
		
		if anchor_timer > max_anchor_time - 1.2:
			sprite.modulate = Color.RED if int(anchor_timer * 12) % 2 == 0 else Color(0.6, 0.8, 1.0)
		if anchor_timer >= max_anchor_time:
			set_anchored(false)
	else:
		anchor_timer = 0.0

func set_anchored(anchored: bool) -> void:
	is_anchored = anchored
	freeze = anchored
	if anchored:
		linear_velocity = Vector2.ZERO
	update_visuals()
	update_animations()

func update_visuals() -> void:
	if is_anchored:
		sprite.modulate = Color(0.6, 0.8, 1.0)
	elif is_active:
		sprite.modulate = Color.WHITE
	else:
		sprite.modulate = Color(0.8, 0.8, 0.8)

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if is_anchored or partner == null:
		return
	
	var free_roaming: bool = not partner.is_anchored
	
	if is_active:
		var dir := Input.get_axis("Left", "Right")
		
		if free_roaming:
			if dir != 0:
				state.linear_velocity.x = dir * 240.0
				sprite.flip_h = dir < 0
			else:
				state.linear_velocity.x = move_toward(state.linear_velocity.x, 0.0, 20.0)
			
			if Input.is_action_just_pressed("ReelIn") and abs(state.linear_velocity.y) < 10.0 and state.get_contact_count() > 0:
				state.linear_velocity.y = -450.0
			
		else:
			if dir != 0:
				state.apply_central_force(Vector2(dir * swing_force, 0))
				sprite.flip_h = dir < 0
			
				if abs(state.linear_velocity.y) < 5.0 and state.get_contact_count() > 0:
					state.apply_central_impulse(Vector2(dir * 120.0, -180.0))
		
			if Input.is_action_just_pressed("ReelIn"):
				var boost_dir := Vector2(dir * 0.6, -1.0).normalized()
				state.apply_central_impulse(boost_dir * hop_impulse)
		
	elif free_roaming:
		var diff := partner.global_position - global_position
		if diff.length() > max_rope_length * 0.6:
			state.linear_velocity.x = sign(diff.x) * 250.0
			sprite.flip_h = diff.x < 0
			
			if diff.y < -30.0 and abs(state.linear_velocity.y) < 10.0 and state.get_contact_count() > 0:
				state.linear_velocity.y = -430.0
		else:
			state.linear_velocity.x = move_toward(state.linear_velocity.x, 0.0, 25.0)
	
	
	var to_partner := partner.global_position - global_position
	var dist := to_partner.length()
	if dist > max_rope_length:
		var pull_dir := to_partner.normalized()
		state.transform.origin += pull_dir * (dist - max_rope_length)
		var outward_speed := state.linear_velocity.dot(-pull_dir)
		if outward_speed > 0:
			state.linear_velocity += pull_dir * outward_speed
	
	update_animations()

func can_anchor() -> bool:
	for body in wall_detector.get_overlapping_bodies():
		if body is StaticBody2D or body is TileMapLayer:
			return true
	return false

func update_animations() -> void:
	if is_anchored:
		sprite.play("Anchored")
	elif abs(linear_velocity.y) > 25.0:
		sprite.play("Jump")
	elif abs(linear_velocity.x) > 15.0:
		sprite.play("Walk")
	else:
		sprite.play("Idle")

func is_on_ground() -> bool:
	return get_contact_count() > 0 and abs(linear_velocity.y) < 15.0
