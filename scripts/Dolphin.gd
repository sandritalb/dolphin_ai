# ============================================================================
# DOLPHIN - Main controller using composition
# Uses Godot physics system for realistic movement
# ============================================================================

extends CharacterBody2D

# ============================================================================
# MOVEMENT PHYSICS
# ============================================================================
@export var max_speed = 300.0              # Maximum movement speed (pixels/second)
@export var acceleration = 1000.0          # Acceleration rate (pixels/second²)
@export var friction = 800.0               # Friction when no input (pixels/second²)

# Water vs Air physics
@export var water_acceleration = 1000.0    # Acceleration in water
@export var air_friction = 1500.0          # High friction in air
@export var water_friction = 300.0         # Low friction in water
@export var gravity = 800.0                # Gravity force (pixels/second²)

# Speed burst on exit water
@export var speed_burst_multiplier = 1.5   # Multiplier for speed burst
@export var speed_burst_duration = 0.3     # Duration of speed burst in seconds

# Water interaction
@export var water_level = -100.0           # Y position of water surface
@export var water_detection_range = 20.0

# Internal state
var is_in_water: bool = true

# Speed burst state
var speed_burst_timer: float = 0.0
var is_speed_bursting: bool = false

# Controller references
var controller: Node = null
var sprite_in: AnimatedSprite2D
var sprite_out: AnimatedSprite2D


func _ready():
	# Initialize state
	position.y = water_level
	velocity = Vector2.ZERO
	is_in_water = true
	
	# Get sprite references
	sprite_in = get_node_or_null("in")
	sprite_out = get_node_or_null("out")
	
	# Find controller node (either dolphin_player or dolphin_ai)
	if has_node("DolphinPlayer"):
		controller = get_node("DolphinPlayer")
		print("🎮 Player Dolphin initialized")
	elif has_node("DolphinAI"):
		controller = get_node("DolphinAI")
		print("🤖 AI Dolphin initialized")
	else:
		print("⚠️ WARNING: No controller node found (DolphinPlayer or DolphinAI)")
	
	# Notify controller that it's ready
	if controller and controller.has_method("on_ready"):
		controller.on_ready(self)


func _physics_process(delta: float) -> void:
	# Update medium detection
	update_medium_state()
	
	# Update speed burst timer
	if is_speed_bursting:
		speed_burst_timer -= delta
		if speed_burst_timer <= 0.0:
			is_speed_bursting = false
	
	# Get input from controller
	var input_direction = Vector2.ZERO
	if controller and controller.has_method("get_input"):
		input_direction = controller.get_input(delta)
	
	# ============================================================================
	# APPLY PHYSICS BASED ON MEDIUM
	# ============================================================================
	
	if is_in_water:
		# WATER PHYSICS - Apply acceleration and friction
		if input_direction != Vector2.ZERO:
			input_direction = input_direction.normalized()
			var current_accel = water_acceleration
			
			# Apply speed burst multiplier if active
			if is_speed_bursting:
				current_accel *= speed_burst_multiplier
				print("💨 Speed burst active!")
			
			# Accelerate toward max speed
			velocity = velocity.move_toward(input_direction * max_speed, current_accel * delta)
		else:
			# Apply water friction when no input
			velocity = velocity.move_toward(Vector2.ZERO, water_friction * delta)
	else:
		# AIR PHYSICS - Apply gravity and friction
		# Maintain horizontal momentum but add gravity
		
		# Apply gravity (stronger downward pull)
		velocity.y += gravity * delta
		
		# Only apply friction to horizontal movement (very slightly)
		# This preserves forward momentum from the jump
		velocity.x = move_toward(velocity.x, 0.0, air_friction * delta * 0.5)
	
	# Apply velocity and collision
	velocity = velocity  # This just assigns our calculated velocity
	move_and_slide()
	
	# Rotate dolphin toward movement direction
	if velocity.length() > 10.0:
		rotation = velocity.angle()


# ============================================================================
# MEDIUM STATE DETECTION
# ============================================================================

func update_medium_state() -> void:
	var was_in_water = is_in_water
	is_in_water = position.y > (water_level - water_detection_range)
	
	# Detect water transitions and notify controller
	if was_in_water and not is_in_water:
		# Activate speed burst when exiting water
		is_speed_bursting = true
		speed_burst_timer = speed_burst_duration
		
		# Boost the forward momentum
		if velocity.length() > 0:
			velocity = velocity.normalized() * min(velocity.length() * speed_burst_multiplier, max_speed * speed_burst_multiplier)
		
		if controller and controller.has_method("on_exit_water"):
			controller.on_exit_water()
	elif not was_in_water and is_in_water:
		if controller and controller.has_method("on_enter_water"):
			controller.on_enter_water()


# ============================================================================
# DEBUG / VISUALIZATION
# ============================================================================

func print_debug_info() -> void:
	var controller_type = "Unknown"
	if controller:
		if controller.name == "DolphinPlayer":
			controller_type = "PLAYER"
		elif controller.name == "DolphinAI":
			controller_type = "AI"
	
	print("\n=== DOLPHIN DEBUG INFO ===")
	print("Position: (%.1f, %.1f)" % [position.x, position.y])
	print("Velocity: %.1f px/s" % velocity.length())
	print("Velocity Vec: (%.1f, %.1f)" % [velocity.x, velocity.y])
	print("Rotation: %.2f rad (%.1f°)" % [rotation, rad_to_deg(rotation)])
	print("Medium: %s" % ("WATER" if is_in_water else "AIR"))
	print("Controller: %s" % controller_type)
	print("========================\n")
