# ============================================================================
# SHARK - Patrol behavior with collision detection
# Patrols between two points and signals when dolphin is touched
# ============================================================================

extends Area2D

# ============================================================================
# SIGNALS
# ============================================================================
signal dolphin_touched

# ============================================================================
# PATROL SETTINGS
# ============================================================================
@export var patrol_distance: float = 300.0  # Distance from starting position (point B offset)
@export var patrol_speed: float = 150.0     # Movement speed in pixels/second
@export var patrol_direction: Vector2 = Vector2.RIGHT  # Direction to patrol (-1, 0 or 1, 0 for horizontal; 0, -1 or 0, 1 for vertical)

# ============================================================================
# INTERNAL STATE
# ============================================================================
var start_position: Vector2  # Point A (starting position)
var target_position: Vector2  # Point B (patrol endpoint)
var current_target: Vector2  # Current target point
var is_moving_to_b: bool = true  # Direction flag

# ============================================================================
# LIFECYCLE
# ============================================================================

func _ready() -> void:
	# Store the starting position (Point A)
	start_position = position
	
	# Calculate Point B (offset in patrol direction)
	target_position = start_position + (patrol_direction.normalized() * patrol_distance)
	
	# Initialize current target as Point B
	current_target = target_position
	
	# Connect the body_entered signal to detect dolphin collision (CharacterBody2D)
	body_entered.connect(_on_body_entered)
	
	print("🦈 Shark initialized at position: ", start_position)
	print("🦈 Patrol Point A: ", start_position)
	print("🦈 Patrol Point B: ", target_position)


func _physics_process(delta: float) -> void:
	# Move toward current target
	var direction = (current_target - position).normalized()
	position += direction * patrol_speed * delta
	
	# Rotate shark to face movement direction
	if direction != Vector2.ZERO:
		rotation = direction.angle()
	
	# Check if reached target and switch direction
	if position.distance_to(current_target) < patrol_speed * delta:
		# Switch target
		if is_moving_to_b:
			current_target = start_position
			is_moving_to_b = false
		else:
			current_target = target_position
			is_moving_to_b = true


# ============================================================================
# COLLISION DETECTION
# ============================================================================

func _on_body_entered(body: Node2D) -> void:
	# Check if the entering body is a dolphin (CharacterBody2D)
	if body.name == "Dolphin":
		print("💥 Shark touched dolphin!")
		emit_signal("dolphin_touched")
