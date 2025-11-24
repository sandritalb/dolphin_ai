# ============================================================================
# RESULT MENU - Displays game results when player loses
# Shows distance traveled and provides restart button
# ============================================================================

extends CanvasLayer

# References
@onready var distance_label: Label = $Panel/VBoxContainer/DistanceLabel
@onready var restart_button: Button = $Panel/VBoxContainer/RestartButton
@onready var winner_label: Label = $Panel/VBoxContainer/WinnerLabel

# Signals
signal restart_game_requested
signal result_menu_shown
signal result_menu_hidden

var distance_nm: float = 0.0
var winner_text: String = ""


func _ready() -> void:
	hide()
	print("ResultMenu - visible: %s" % visible)
	if restart_button:
		restart_button.pressed.connect(_on_restart_button_pressed)
	print("✅ ResultMenu initialized")


func show_result(distance: float, winner: String = "") -> void:
	"""Display the result menu with the final distance, winner, and pause the game"""
	distance_nm = distance
	winner_text = winner
	
	if distance_label:
		distance_label.text = "Distance Traveled: %.2f nm" % distance_nm
	
	if winner_label and winner_text != "":
		winner_label.text = winner_text
		winner_label.show()
	else:
		if winner_label:
			winner_label.hide()
	
	# Pause the game tree
	get_tree().paused = true
	
	print("About to show result menu - visible before: %s" % visible)
	show()
	result_menu_shown.emit()
	print("After show() - visible: %s" % visible)
	print("📊 Result menu shown - Distance: %.2f nm" % distance_nm)
	print("🏆 Winner: %s" % winner_text)


func _on_restart_button_pressed() -> void:
	print("🔄 Restart button pressed")
	# Unpause the game before restarting
	get_tree().paused = false
	result_menu_hidden.emit()
	restart_game_requested.emit()
