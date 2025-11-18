# ============================================================================
# RESULT MENU - Displays game results when player loses
# Shows distance traveled and provides restart button
# ============================================================================

extends CanvasLayer

# References
@onready var distance_label: Label = $Panel/VBoxContainer/DistanceLabel
@onready var restart_button: Button = $Panel/VBoxContainer/RestartButton

# Signals
signal restart_game_requested
signal result_menu_shown
signal result_menu_hidden

var distance_nm: float = 0.0


func _ready() -> void:
	hide()
	print("ResultMenu - visible: %s" % visible)
	if restart_button:
		restart_button.pressed.connect(_on_restart_button_pressed)
	print("✅ ResultMenu initialized")


func show_result(distance: float) -> void:
	"""Display the result menu with the final distance and pause the game"""
	distance_nm = distance
	
	if distance_label:
		distance_label.text = "Distance Traveled: %.2f nm" % distance_nm
	
	# Pause the game tree
	get_tree().paused = true
	
	print("About to show result menu - visible before: %s" % visible)
	show()
	result_menu_shown.emit()
	print("After show() - visible: %s" % visible)
	print("📊 Result menu shown - Distance: %.2f nm" % distance_nm)


func _on_restart_button_pressed() -> void:
	print("🔄 Restart button pressed")
	# Unpause the game before restarting
	get_tree().paused = false
	result_menu_hidden.emit()
	restart_game_requested.emit()
