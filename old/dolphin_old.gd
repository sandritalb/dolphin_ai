# ============================================================================
# DOLPHIN CONTROLLER - Base Class
# Handles physics, water detection, and shared logic
# ============================================================================

extends CharacterBody2D

# Movement
@export var move_speed = 300.0         # pixels/second
@export var gravity = 600.0            # pixels/second²

# Water interaction
@export var water_level = -100.0        # Y position of water surface
@export var water_detection_range = 20.0
@export var water_drag = 0.8           # Drag multiplier in water (0-1)
@export var air_drag = 0.1            # Drag multiplier in air (0-1)

# Internal state
var velocity_vec: Vector2 = Vector2.ZERO
var is_in_water: bool = true

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
	
	# Call subclass initialization
	on_controller_ready()


# Override this in subclasses
func on_controller_ready() -> void:
	pass


func _physics_process(delta: float) -> void:
	# Update medium detection
	update_medium_state()
	
	# Get input from subclass
	var input_direction = get_controller_input(delta)
	
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


# Override this in subclasses to provide input
func get_controller_input(delta: float) -> Vector2:
	return Vector2.ZERO


# ============================================================================
# MEDIUM STATE DETECTION
# ============================================================================

func update_medium_state() -> void:
	var was_in_water = is_in_water
	is_in_water = position.y > (water_level - water_detection_range)
	
	# Detect water transitions
	if was_in_water and not is_in_water:
		on_exit_water()
	elif not was_in_water and is_in_water:
		on_enter_water()


# Override these in subclasses for specific behavior
func on_exit_water() -> void:
	pass


func on_enter_water() -> void:
	pass


# ============================================================================
# DEBUG / VISUALIZATION
# ============================================================================

func print_debug_info() -> void:
	print("\n=== DOLPHIN DEBUG INFO ===")
	print("Position: (%.1f, %.1f)" % [position.x, position.y])
	print("Velocity: %.1f px/s" % velocity_vec.length())
	print("Velocity Vec: (%.1f, %.1f)" % [velocity_vec.x, velocity_vec.y])
	print("Rotation: %.2f rad (%.1f°)" % [rotation, rad_to_deg(rotation)])
	print("Medium: %s" % ("WATER" if is_in_water else "AIR"))
	print("========================\n")
