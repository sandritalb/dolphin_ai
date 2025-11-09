extends Camera2D

@export var target_a: Node2D
@export var target_b: Node2D
@export var smooth_speed: float = 1.0
@export var lookahead_distance: float = 200.0  # How far ahead to look

func _process(delta: float) -> void:
	# If neither target exists, do nothing
	if not target_a and not target_b:
		return
	
	var target_x: float
	
	# If both exist, focus on midpoint
	if target_a and target_b:
		target_x = (target_a.global_position.x + target_b.global_position.x) / 2.0
	# If only target_a exists, follow it
	elif target_a:
		target_x = target_a.global_position.x
	# If only target_b exists, follow it
	else:
		target_x = target_b.global_position.x
	
	# Add lookahead to the right
	target_x += lookahead_distance
	
	# Smoothly move camera horizontally only (very smooth easing)
	var lerp_factor = clamp(delta * smooth_speed, 0.0, 0.1)
	global_position.x = lerp(global_position.x, target_x, lerp_factor)
