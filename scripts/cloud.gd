extends Sprite2D

# ============================================================================
# CLOUD - Handles individual cloud movement and appearance
# ============================================================================

# ============================================================================
# MOVEMENT SETTINGS
# ============================================================================
var speed_multiplier: float = 0.7  # Percentage of camera speed (0.3 to 0.7 based on depth)
var camera: Camera2D = null
var last_camera_x: float = 0.0

# ============================================================================
# LIFECYCLE
# ============================================================================

func _ready() -> void:
	mostrar_frame_aleatorio()
	# Get reference to camera
	camera = get_viewport().get_camera_2d()
	if camera:
		last_camera_x = camera.global_position.x


func _process(delta: float) -> void:
	if not camera:
		camera = get_viewport().get_camera_2d()
		if camera:
			last_camera_x = camera.global_position.x
		return
	
	# Calculate camera speed this frame
	var camera_speed = (camera.global_position.x - last_camera_x) / delta if delta > 0 else 0.0
	last_camera_x = camera.global_position.x
	
	# Move cloud to the right at a percentage of camera speed
	# This creates the parallax effect - clouds appear to move slower than the player
	if camera_speed > 0:
		global_position.x += camera_speed * speed_multiplier * delta


# ============================================================================
# PUBLIC API
# ============================================================================

func set_movement_speed(speed: float) -> void:
	"""Set the speed multiplier (percentage of camera speed)"""
	speed_multiplier = speed


func set_scale_based_on_depth(depth_factor: float) -> void:
	"""Set scale based on depth (0.0 = far/top, 1.0 = near/bottom)"""
	# Clouds near sea level (depth_factor close to 1) are smaller (closer to water, farther from camera)
	# Clouds high up (depth_factor close to 0) are larger (closer to camera)
	var min_scale = 0.4  # Smallest scale for clouds near sea level
	var max_scale = 1.0  # Largest scale for clouds high in the sky
	var cloud_scale = lerp(max_scale, min_scale, depth_factor)
	scale = Vector2(cloud_scale, cloud_scale)


func mostrar_frame_aleatorio() -> void:
	# Si tienes una textura con múltiples frames, especifica el número total de frames
	var total_frames = 9  # Cambia esto al número de frames que tengas
	frame = randi() % total_frames
