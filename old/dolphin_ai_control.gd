# ============================================================================
# DOLPHIN AI - AI input controller (composition)
# Handles AI-controlled dolphin behavior
# ============================================================================

extends Node

# AI parameters
@export var ai_wander_speed = 1.5      # How fast AI changes direction
@export var ai_max_wander_angle = PI / 4  # Max angle AI wanders
@export var ai_tint_color: Color = Color.LIGHT_BLUE  # Tint color for AI dolphins

# AI state
var ai_direction: Vector2 = Vector2.RIGHT
var ai_wander_timer: float = 0.0
var ai_wander_interval: float = 2.0  # Change direction every 2 seconds

# Parent dolphin reference
var dolphin: Node = null
var is_in_water: bool = true


func on_ready(parent_dolphin: Node) -> void:
	dolphin = parent_dolphin
	ai_direction = Vector2.RIGHT
	randomize_ai_wander()
	apply_ai_tint()
	print("🤖 AI Controller initialized")


func apply_ai_tint() -> void:
	# Apply tint color to both sprites
	if dolphin:
		var sprite_in = dolphin.get_node_or_null("in")
		var sprite_out = dolphin.get_node_or_null("out")
		
		if sprite_in:
			sprite_in.self_modulate = ai_tint_color
		if sprite_out:
			sprite_out.self_modulate = ai_tint_color


func get_input(delta: float) -> Vector2:
	ai_wander_timer += delta
	
	# Get parent dolphin's water state
	if dolphin and "is_in_water" in dolphin:
		is_in_water = dolphin.is_in_water
	
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


func on_exit_water() -> void:
	pass  # AI dolphins don't print debug messages


func on_enter_water() -> void:
	pass  # AI dolphins don't print debug messages
