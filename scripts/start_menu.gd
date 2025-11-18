# ============================================================================
# PAUSE MENU - Pause menu that appears on ESC key
# Handles menu interactions and game pause/resume
# ============================================================================

extends CanvasLayer

var game_started: bool = false
var menu_visible: bool = false
var result_menu_active: bool = false

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
	
	# Connect to result menu signals
	var result_menu = get_tree().root.get_node_or_null("Main/ResultMenu")
	if result_menu:
		if result_menu.has_signal("result_menu_shown"):
			result_menu.result_menu_shown.connect(_on_result_menu_shown)
		if result_menu.has_signal("result_menu_hidden"):
			result_menu.result_menu_hidden.connect(_on_result_menu_hidden)
	
	get_tree().paused = true

func _input(event: InputEvent) -> void:
	# Toggle menu with ESC key
	# Don't process input if result menu is active
	if result_menu_active:
		return
	
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


func _on_result_menu_shown() -> void:
	print("📊 Result menu shown - disabling pause menu input")
	result_menu_active = true


func _on_result_menu_hidden() -> void:
	print("📊 Result menu hidden - enabling pause menu input")
	result_menu_active = false
