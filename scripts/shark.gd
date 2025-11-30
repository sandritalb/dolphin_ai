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
# SOUNDS
# ============================================================================
var bite_sound = preload("res://sounds/bite.mp3")
var shark_dead_sound = preload("res://sounds/shark_dead.mp3")

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
	# Add to sharks group for identification
	add_to_group("sharks")
	
	# Connect the body_entered signal to detect dolphin collision (CharacterBody2D)
	body_entered.connect(_on_body_entered)


func setup_patrol_points(base_position: Vector2, water_level: float, min_depth_offset: float, max_depth: float) -> void:
	# Store the starting position (Point A)
	start_position = base_position
	# Calculate Point B (offset in patrol direction)
	target_position = start_position + (patrol_direction.normalized() * patrol_distance)
	# Clamp only the target position Y to stay within depth bounds
	target_position.y = clamp(target_position.y, water_level + min_depth_offset, max_depth)
	# Initialize current target as Point B
	current_target = target_position

func _physics_process(delta: float) -> void:
	# Move toward current target
	var direction = (current_target - position).normalized()
	position += direction * patrol_speed * delta
	
	# Mirror shark sprite based on movement direction
	if direction.x > 0:
		scale.x = abs(scale.x)  # Face right
	elif direction.x < 0:
		scale.x = -abs(scale.x)  # Face left (mirrored)
	
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
	# Check if the entering body is a dolphin using group membership
	if body.is_in_group("dolphins"):
		print("💥 Shark touched dolphin!")
		# Play bite sound with random pitch variation
		SoundManager.play_sound(bite_sound, 0.9, 1.1, -3.0)
		# Play shark dead sound
		SoundManager.play_sound(shark_dead_sound, 0.9, 1.1, 0.0)
		# Notify the dolphin about the shark hit
		if body.has_signal("shark_hit_signal"):
			body.shark_hit_signal.emit(body)
		emit_signal("dolphin_touched")
