# ============================================================================
# PAUSE MENU - Pause menu that appears on ESC key
# Handles menu interactions and game pause/resume
# ============================================================================

extends CanvasLayer

var game_started: bool = false
var menu_visible: bool = false

# ============================================================================
# LIFECYCLE
# ============================================================================

func _ready() -> void:
	print("🎮 PauseMenu: _ready() called")
	
	# Get button references
	var action_btn = $Panel/VBoxContainer/ActionButton
	var quit_btn = $Panel/VBoxContainer/QuitButton
	
	print("Action button: ", action_btn)
	print("Quit button: ", quit_btn)
	
	# Connect button signals
	if action_btn:
		action_btn.pressed.connect(_on_action_pressed)
		print("✅ Connected ActionButton")
	else:
		print("❌ Could not find ActionButton")
	
	if quit_btn:
		quit_btn.pressed.connect(_on_quit_pressed)
		print("✅ Connected QuitButton")
	else:
		print("❌ Could not find QuitButton")
	get_tree().paused = true

func _input(event: InputEvent) -> void:
	# Toggle menu with ESC key
	
	if event.is_action_pressed("ui_cancel"):
		if menu_visible:
			_on_action_pressed()  # Resume
		else:
			show_menu()


# ============================================================================
# MENU VISIBILITY
# ============================================================================

func show_menu() -> void:
	print("📋 Showing pause menu...")
	menu_visible = true
	visible = true
	get_tree().paused = true
	
	# Update button text based on game state
	var action_btn = $Panel/VBoxContainer/ActionButton
	if action_btn:
		if game_started:
			action_btn.text = "Resume Game"
		else:
			action_btn.text = "Start Game"


func hide_menu() -> void:
	print("📋 Hiding pause menu...")
	menu_visible = false
	visible = false


# ============================================================================
# SIGNAL HANDLERS
# ============================================================================

func _on_action_pressed() -> void:
	if game_started:
		print("▶️ Resuming game...")
		get_tree().paused = false
		hide_menu()
	else:
		print("🎮 Starting game...")
		game_started = true
		get_tree().paused = false
		hide_menu()


func _on_quit_pressed() -> void:
	print("👋 Quitting game...")
	get_tree().quit()
