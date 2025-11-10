# ============================================================================
# DOLPHIN PLAYER - Player input controller (composition)
# Handles human player input and control
# ============================================================================

extends Node

# Customizable input keys
@export var key_right: String = "ui_right"
@export var key_left: String = "ui_left"
@export var key_up: String = "ui_up"
@export var key_down: String = "ui_down"
@export var key_debug: String = "ui_accept"

# Parent dolphin reference
var dolphin: Node = null
var is_in_water: bool = true


func on_ready(parent_dolphin: Node) -> void:
	dolphin = parent_dolphin
	print("🎮 Player Controller initialized")


func get_input(_delta: float) -> Vector2:
	var input_direction = Vector2.ZERO
	
	# Get parent dolphin's water state
	if dolphin and dolphin.has_meta("is_in_water"):
		is_in_water = dolphin.get_meta("is_in_water")
	elif dolphin and "is_in_water" in dolphin:
		is_in_water = dolphin.is_in_water
	
	# Directional controls - only work in water!
	if is_in_water:
		if Input.is_action_pressed(key_right):
			input_direction.x = 1.0
		# No left movement allowed
		if Input.is_action_pressed(key_up):
			input_direction.y = -1.0
		if Input.is_action_pressed(key_down):
			input_direction.y = 1.0
	
	# Debug input
	if Input.is_action_just_pressed(key_debug):
		if dolphin and dolphin.has_method("print_debug_info"):
			dolphin.print_debug_info()
	
	return input_direction


func on_exit_water() -> void:
	print("🐬 Dolphin jumps out of water!")


func on_enter_water() -> void:
	print("💧 Splash! Dolphin enters water")
