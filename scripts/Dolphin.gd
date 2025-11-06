extends CharacterBody2D

@export var gravity: float = 980.0
@export var jump_force: float = -400.0
@export var auto_play: bool = false
@export var animation_speed: float = 0.15

var velocity_y = 0.0
var memory = []
var is_jumping = false
var animation_timer: float = 0.0
var current_frame: int = 0
var ground_level: float = 380.0

func _physics_process(delta):
	# Update animation
	animation_timer += delta
	if animation_timer >= animation_speed:
		animation_timer = 0.0
		current_frame = (current_frame + 1) % 4  # 2x2 sprite
		$Sprite2D.frame = current_frame
	
	# Apply gravity
	velocity_y += gravity * delta
	
	# Check if on ground
	var on_ground = global_position.y >= ground_level
	
	if on_ground:
		global_position.y = ground_level
		velocity_y = 0
		is_jumping = false
	
	# Limit top of screen
	if global_position.y < 50:
		global_position.y = 50
		velocity_y = 0
	
	# AI behavior
	if auto_play and on_ground:
		_ai_behavior()
	
	velocity = Vector2(0, velocity_y)
	move_and_slide()

func _input(event):
	if not auto_play and event.is_action_pressed("ui_accept"):
		if global_position.y >= ground_level:
			_jump()

func _ai_behavior():
	# Check for incoming waves
	var wave_distance = _get_nearest_wave_distance()
	
	if wave_distance < 250 and wave_distance > 0:
		_jump()

func _jump():
	velocity_y = jump_force
	is_jumping = true
	
	# Store jump data for learning
	if not auto_play:
		var wave_dist = _get_nearest_wave_distance()
		memory.append([global_position.y, velocity_y, wave_dist])
		if memory.size() > 50:
			memory.remove_at(0)

func _get_nearest_wave_distance() -> float:
	var nearest = INF
	var waves = get_tree().get_nodes_in_group("waves")
	
	if waves.is_empty():
		# Fallback to searching by name
		for node in get_tree().current_scene.get_children():
			if node is Area2D and node.name.begins_with("Wave"):
				var dist = node.global_position.x - global_position.x
				if dist > 0 and dist < nearest:
					nearest = dist
	else:
		for wave in waves:
			var dist = wave.global_position.x - global_position.x
			if dist > 0 and dist < nearest:
				nearest = dist
	
	return nearest if nearest != INF else -1.0
