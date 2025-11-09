extends CharacterBody2D

# ============================================================================
# DOLPHIN PHYSICS CONTROLLER - SIMPLIFIED
# Arrow keys control: RIGHT = right, LEFT = left, UP = up, DOWN = down
# ============================================================================

# Movement
@export var move_speed = 300.0         # pixels/second
@export var gravity = 600.0            # pixels/second²

# Water interaction
@export var water_level = -100.0        # Y position of water surface
@export var water_detection_range = 20.0
@export var water_drag = 0.8           # Drag multiplier in water (0-1)
@export var air_drag = 0.95            # Drag multiplier in air (0-1)

# Internal state
var velocity_vec: Vector2 = Vector2.ZERO
var is_in_water: bool = true


func _ready():
	# Initialize state
	position.y = water_level
	velocity_vec = Vector2.ZERO
	is_in_water = true


func _physics_process(delta: float) -> void:
	# Update medium detection
	update_medium_state()
	
	# Handle player input
	handle_input(delta)
	
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
		print("🐬 Dolphin jumps out of water!")
	elif not was_in_water and is_in_water:
		print("💧 Splash! Dolphin enters water")


# ============================================================================
# INPUT HANDLING
# ============================================================================

func handle_input(delta: float) -> void:
	var input_direction = Vector2.ZERO
	
	# Arrow key controls - only work in water!
	if is_in_water:
		if Input.is_action_pressed("ui_right"):
			input_direction.x = 1.0
		if Input.is_action_pressed("ui_left"):
			input_direction.x = -1.0
		if Input.is_action_pressed("ui_up"):
			input_direction.y = -1.0
		if Input.is_action_pressed("ui_down"):
			input_direction.y = 1.0
		
		# Apply movement (only in water, where thrust works)
		if input_direction != Vector2.ZERO:
			input_direction = input_direction.normalized()
			velocity_vec = input_direction * move_speed
	# In air: no thrust, only inertia (velocity continues naturally with gravity)




# ============================================================================
# DEBUG / VISUALIZATION (Console Output)
# ============================================================================

func _input(event: InputEvent) -> void:
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
	print("========================\n")
