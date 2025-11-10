extends CharacterBody2D

# ============================================================================
# DOLPHIN PHYSICS CONTROLLER - MULTI-INSTANCE SUPPORT
# Supports both player-controlled and AI-controlled dolphins
# ============================================================================

# Controller type
enum ControllerType { PLAYER, AI }

@export var controller_type: ControllerType = ControllerType.PLAYER

# Movement
@export var move_speed = 300.0         # pixels/second
@export var gravity = 600.0            # pixels/second²

# Water interaction
@export var water_level = -100.0        # Y position of water surface
@export var water_detection_range = 20.0
@export var water_drag = 0.8           # Drag multiplier in water (0-1)
@export var air_drag = 0.95            # Drag multiplier in air (0-1)

# AI parameters
@export var ai_wander_speed = 1.5      # How fast AI changes direction
@export var ai_max_wander_angle = PI / 4  # Max angle AI wanders
@export var ai_tint_color: Color = Color.LIGHT_BLUE  # Tint color for AI dolphins

# Internal state
var velocity_vec: Vector2 = Vector2.ZERO
var is_in_water: bool = true

# AI state
var ai_direction: Vector2 = Vector2.RIGHT
var ai_wander_timer: float = 0.0
var ai_wander_interval: float = 2.0  # Change direction every 2 seconds

# Sprite references
var sprite_in: AnimatedSprite2D
var sprite_out: AnimatedSprite2D


func _ready():
	# Initialize state
	position.y = water_level
	velocity_vec = Vector2.ZERO
	is_in_water = true
	
	# Get sprite references
	sprite_in = get_node_or_null("in")
	sprite_out = get_node_or_null("out")
	
	# Apply AI tint if this is an AI-controlled dolphin
	if controller_type == ControllerType.AI:
		apply_ai_tint()
	
	# AI initialization
	if controller_type == ControllerType.AI:
		ai_direction = Vector2.RIGHT
		randomize_ai_wander()


func apply_ai_tint() -> void:
	# Apply tint color to both sprites
	if sprite_in:
		sprite_in.self_modulate = ai_tint_color
	if sprite_out:
		sprite_out.self_modulate = ai_tint_color


func _physics_process(delta: float) -> void:
	# Update medium detection
	update_medium_state()
	
	# Get input based on controller type
	var input_direction = Vector2.ZERO
	if controller_type == ControllerType.PLAYER:
		input_direction = get_player_input(delta)
	else:
		input_direction = get_ai_input(delta)
	
	# Apply movement only in water
	if is_in_water and input_direction != Vector2.ZERO:
		input_direction = input_direction.normalized()
		velocity_vec = input_direction * move_speed
	
	# Apply gravity
	if not is_in_water:
		velocity_vec.y += gravity * delta
	
	# Apply drag
	var drag = water_drag if is_in_water else air_drag
	velocity_vec *= drag
	
	# Use CharacterBody2D's built-in collision detection
	velocity = velocity_vec
	move_and_slide()
	
	# Rotate dolphin toward movement direction
	if velocity_vec.length() > 10.0:
		rotation = velocity_vec.angle()


# ============================================================================
# MEDIUM STATE DETECTION
# ============================================================================

func update_medium_state() -> void:
	var was_in_water = is_in_water
	is_in_water = position.y > (water_level - water_detection_range)
	
	# Detect water transitions
	if was_in_water and not is_in_water:
		if controller_type == ControllerType.PLAYER:
			print("🐬 Dolphin jumps out of water!")
	elif not was_in_water and is_in_water:
		if controller_type == ControllerType.PLAYER:
			print("💧 Splash! Dolphin enters water")


# ============================================================================
# PLAYER INPUT
# ============================================================================

func get_player_input(delta: float) -> Vector2:
	var input_direction = Vector2.ZERO
	
	# Arrow key controls - only work in water!
	if is_in_water:
		if Input.is_action_pressed("ui_right"):
			input_direction.x = 1.0
		# No left movement allowed
		if Input.is_action_pressed("ui_up"):
			input_direction.y = -1.0
		if Input.is_action_pressed("ui_down"):
			input_direction.y = 1.0
	
	return input_direction


# ============================================================================
# AI INPUT
# ============================================================================

func get_ai_input(delta: float) -> Vector2:
	ai_wander_timer += delta
	
	# Change direction periodically
	if ai_wander_timer >= ai_wander_interval:
		randomize_ai_wander()
		ai_wander_timer = 0.0
	
	# AI only moves in water
	if is_in_water:
		return ai_direction
	
	return Vector2.ZERO


func randomize_ai_wander() -> void:
	# Random angle for wandering behavior
	var random_angle = randf_range(-ai_max_wander_angle, ai_max_wander_angle)
	
	# Prefer moving right, but allow some vertical movement
	ai_direction = Vector2(cos(random_angle), sin(random_angle)).normalized()


# ============================================================================
# DEBUG / VISUALIZATION (Console Output)
# ============================================================================

func _input(event: InputEvent) -> void:
	# Only player dolphin responds to debug input
	if controller_type == ControllerType.PLAYER:
		# Press 'P' to print debug info
		if event is InputEventKey and event.pressed and event.keycode == KEY_P:
			print_debug_info()


func print_debug_info() -> void:
	print("\n=== DOLPHIN DEBUG INFO ===")
	print("Position: (%.1f, %.1f)" % [position.x, position.y])
	print("Velocity: %.1f px/s" % velocity_vec.length())
	print("Velocity Vec: (%.1f, %.1f)" % [velocity_vec.x, velocity_vec.y])
	print("Rotation: %.2f rad (%.1f°)" % [rotation, rad_to_deg(rotation)])
	print("Medium: %s" % ("WATER" if is_in_water else "AIR"))
	print("Controller: %s" % ("PLAYER" if controller_type == ControllerType.PLAYER else "AI"))
	print("========================\n")
