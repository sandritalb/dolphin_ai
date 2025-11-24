# ============================================================================
# DOLPHIN PLAYER - Player input controller (composition)
# Handles human player input and control (keyboard + joystick)
# ============================================================================

extends Node

# Customizable input keys
@export var key_right: String = "ui_right"
@export var key_left: String = "ui_left"
@export var key_up: String = "ui_up"
@export var key_down: String = "ui_down"
@export var key_debug: String = "ui_accept"

# Joystick axis names (for analog stick support)
@export var joy_axis_x: String = ""  # e.g., "P1_joy_x" or "P2_joy_x"
@export var joy_axis_y: String = ""  # e.g., "P1_joy_y" or "P2_joy_y"
@export var joystick_deadzone: float = 0.2

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
		# Keyboard input
		if Input.is_action_pressed(key_right):
			input_direction.x = 1.0
		if Input.is_action_pressed(key_left):
			input_direction.x = 0.0
		if Input.is_action_pressed(key_up):
			input_direction.y = -1.0
		if Input.is_action_pressed(key_down):
			input_direction.y = 1.0
		
		# Joystick analog stick input (if configured)
		var joy_input = get_joystick_input()
		if joy_input.length() > joystick_deadzone:
			# Joystick overrides keyboard if active
			if abs(joy_input.x) > joystick_deadzone:
				input_direction.x = 1.0 if joy_input.x > 0 else 0.0
			if abs(joy_input.y) > joystick_deadzone:
				input_direction.y = joy_input.y
	
	# Debug input
	if Input.is_action_just_pressed(key_debug):
		if dolphin and dolphin.has_method("print_debug_info"):
			dolphin.print_debug_info()
	
	return input_direction


func get_joystick_input() -> Vector2:
	"""Get joystick analog stick input as a Vector2"""
	var joy_vector = Vector2.ZERO
	
	# Use axis actions if configured
	if joy_axis_x != "" and InputMap.has_action(joy_axis_x + "_pos"):
		joy_vector.x = Input.get_action_strength(joy_axis_x + "_pos") - Input.get_action_strength(joy_axis_x + "_neg")
	if joy_axis_y != "" and InputMap.has_action(joy_axis_y + "_pos"):
		joy_vector.y = Input.get_action_strength(joy_axis_y + "_pos") - Input.get_action_strength(joy_axis_y + "_neg")
	
	# Apply deadzone
	if joy_vector.length() < joystick_deadzone:
		return Vector2.ZERO
	
	return joy_vector


func on_exit_water() -> void:
	print("🐬 Dolphin jumps out of water!")


func on_enter_water() -> void:
	print("💧 Splash! Dolphin enters water")
