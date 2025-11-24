# ============================================================================
# START MENU - Start menu with game mode selection
# Handles game mode selection (1 player vs 2 players)
# ============================================================================

extends CanvasLayer

# ============================================================================
# SIGNALS
# ============================================================================
signal game_mode_selected(mode: int)  # 1 for single player, 2 for two players

# ============================================================================
# CONSTANTS
# ============================================================================
const MODE_1_PLAYER = 1
const MODE_2_PLAYERS = 2

# ============================================================================
# VARIABLES
# ============================================================================
var game_started: bool = false
var menu_visible: bool = false
var result_menu_active: bool = false

# ============================================================================
# LIFECYCLE
# ============================================================================

func _ready() -> void:
	print("🎮 StartMenu: _ready() called")
	
	# Get button references
	var single_player_btn = $Panel/VBoxContainer/SinglePlayerButton
	var two_player_btn = $Panel/VBoxContainer/TwoPlayersButton
	var quit_btn = $Panel/VBoxContainer/QuitButton
	
	# Connect mode selection buttons
	if single_player_btn:
		single_player_btn.pressed.connect(_on_single_player_pressed)
		print("✅ Connected SinglePlayerButton")
	else:
		print("❌ Could not find SinglePlayerButton")
	
	if two_player_btn:
		two_player_btn.pressed.connect(_on_two_players_pressed)
		print("✅ Connected TwoPlayersButton")
	else:
		print("❌ Could not find TwoPlayersButton")
	
	if quit_btn:
		quit_btn.pressed.connect(_on_quit_pressed)
		print("✅ Connected QuitButton")
	else:
		print("❌ Could not find QuitButton")
	
	print("✅ StartMenu initialized")

func _input(event: InputEvent) -> void:
	# Toggle menu with ESC key
	# Don't process input if result menu is active
	if result_menu_active:
		return
	
	if event.is_action_pressed("ui_cancel"):
		if menu_visible:
			_on_quit_pressed()  # Quit on menu
		else:
			show_menu()


# ============================================================================
# MENU VISIBILITY
# ============================================================================

func show_menu() -> void:
	print("📋 Showing start menu...")
	menu_visible = true
	visible = true


func hide_menu() -> void:
	print("📋 Hiding start menu...")
	menu_visible = false
	visible = false


# ============================================================================
# SIGNAL HANDLERS
# ============================================================================

func _on_single_player_pressed() -> void:
	print("🎮 Starting Single Player mode...")
	game_started = true
	game_mode_selected.emit(MODE_1_PLAYER)
	hide_menu()


func _on_two_players_pressed() -> void:
	print("🎮 Starting Two Players mode...")
	game_started = true
	game_mode_selected.emit(MODE_2_PLAYERS)
	hide_menu()


func _on_quit_pressed() -> void:
	print("👋 Quitting game...")
	get_tree().quit()


func _on_result_menu_shown() -> void:
	print("📊 Result menu shown - disabling start menu input")
	result_menu_active = true


func _on_result_menu_hidden() -> void:
	print("📊 Result menu hidden - enabling start menu input")
	result_menu_active = false
