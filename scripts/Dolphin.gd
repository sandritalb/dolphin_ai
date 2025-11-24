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
@export var air_friction = 300.0          # Low friction in air
@export var water_friction = 1500.0         # High friction in water
@export var gravity = 800.0                # Gravity force (pixels/second²)

# Speed burst on exit water
@export var speed_burst_multiplier = 2.6   # Multiplier for speed burst
@export var speed_burst_duration = 0.1     # Duration of speed burst in seconds

# Water interaction
@export var water_level = -100.0           # Y position of water surface
@export var water_detection_range = 10.0

# Stun/Impact mechanics
@export var stun_duration: float = 0.1     # Stun duration on boat collision (seconds)
@export var stun_knockback: float = 150.0  # Knockback speed when hit (pixels/second)

# Internal state
var is_in_water: bool = true

# Bubble Ring
var bubble_ring_scene = preload("res://scenes/BubbleRing.tscn")

# Speed burst state
var speed_burst_timer: float = 0.0
var is_speed_bursting: bool = false

# Stun state
var is_stunned: bool = false

# Controller references
var controller: Node = null
var sprite_in: AnimatedSprite2D
var sprite_out: AnimatedSprite2D


func _ready():
	velocity = Vector2.ZERO
	is_in_water = true
	
	# Get sprite references
	sprite_in = get_node_or_null("in")
	sprite_out = get_node_or_null("out")
	
	# Find controller node (either dolphin_player or dolphin_ai)
	if has_node("DolphinPlayer"):
		controller = get_node("DolphinPlayer")
		print("🎮 Player Dolphin initialized at position: ", position)
	elif has_node("DolphinPlayer2"):
		controller = get_node("DolphinPlayer2")
		print("🎮 Player Dolphin 2 initialized at position: ", position)
	elif has_node("DolphinAI"):
		controller = get_node("DolphinAI")
		print("🤖 AI Dolphin initialized at position: ", position)
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
		print("💨 Speed burst timer: ", speed_burst_timer)
		speed_burst_timer -= delta
		if speed_burst_timer <= 0.0:
			is_speed_bursting = false
	
	# Get input from controller
	var input_direction = Vector2.ZERO
	if controller and controller.has_method("get_input"):
		input_direction = controller.get_input(delta)
	
	# Check for boat collision
	_check_boat_collision()
	
	# ============================================================================
	# APPLY PHYSICS BASED ON MEDIUM
	# ============================================================================
	
	# Skip physics if stunned
	if is_stunned:
		move_and_slide()
		return
	
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
	
	# Cap velocity to maximum speed of 1000 or 600 in water
	if velocity.length() > 1000.0 and not is_in_water:
		velocity = velocity.normalized() * 1000.0
	elif velocity.length() > 600.0 and is_in_water:
		velocity = velocity.normalized() * 600
	
	move_and_slide()
	
	# Rotate dolphin toward movement direction
	if velocity.length() > 10.0:
		rotation = velocity.angle()
	
	# # Flip sprites based on horizontal velocity direction
	# if velocity.x > 0:
	# 	if sprite_in:
	# 		sprite_in.flip_v = false
	# 	if sprite_out:
	# 		sprite_out.flip_v = false
	# elif velocity.x < 0:
	# 	if sprite_in:
	# 		sprite_in.flip_v = true
	# 	if sprite_out:
	# 		sprite_out.flip_v = true


# ============================================================================
# ABILITIES
# ============================================================================

func spawn_bubble_ring() -> void:
	if not is_in_water:
		return
		
	if bubble_ring_scene:
		var ring = bubble_ring_scene.instantiate()
		# Add to the same parent as dolphin (usually the main scene)
		get_parent().add_child(ring)
		
		# Spawn in front of the dolphin
		# Use a slight offset so it doesn't spawn inside
		var spawn_offset = Vector2.RIGHT.rotated(rotation) * 40.0
		ring.position = position + spawn_offset
		ring.rotation = rotation
		
		print("OoO Bubble Ring spawned!")


# ============================================================================
# COLLISION DETECTION
# ============================================================================

func _check_boat_collision() -> void:
	# Check all slide collisions from move_and_slide
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var body = collision.get_collider()
		if body and body.name == "Boat":
			# Apply stun effect with knockback
			_apply_stun(body)
			break


func _apply_stun(boat: Node2D) -> void:
	if not is_stunned:
		is_stunned = true
		
		# Calculate knockback direction (opposite to boat)
		var knockback_direction = (position - boat.position).normalized()
		velocity = knockback_direction * stun_knockback
		
		print("💥 Boat hit! Stunned for %.1f seconds" % stun_duration)
		
		# Use timer to automatically end stun
		await get_tree().create_timer(stun_duration).timeout
		is_stunned = false
		print("✅ Stun ended")


# ============================================================================
# MEDIUM STATE DETECTION
# ============================================================================

func update_medium_state() -> void:
	var was_in_water = is_in_water
	is_in_water = position.y > (water_level - water_detection_range)
	#print("🌊 Dolphin Y: ", position.y, " Water Level: ", water_level, " In Water: ", is_in_water)
	# Detect water transitions and notify controller
	if was_in_water and not is_in_water:
		# Activate speed burst when exiting water
		print("💨 Exiting water - activating speed burst!", position.y, water_level-water_detection_range, was_in_water, is_in_water)
		is_speed_bursting = true
		speed_burst_timer = speed_burst_duration
		
		# Boost the forward momentum
		if velocity.length() > 0:
			velocity = velocity.normalized() * min(velocity.length() * speed_burst_multiplier, max_speed * speed_burst_multiplier)
		
		# Trigger exit water particles
		if controller and controller.has_method("on_exit_water"):
			controller.on_exit_water()
	elif not was_in_water and is_in_water:
		if controller and controller.has_method("on_enter_water"):
			controller.on_enter_water()
		spawn_bubble_ring()


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
