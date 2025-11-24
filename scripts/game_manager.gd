# ============================================================================
# GAME MANAGER - Central game control
# Handles signals from game elements (shark, etc.) and manages game state
# ============================================================================

extends Node

# ============================================================================
# CONSTANTS
# ============================================================================
const MODE_1_PLAYER = 1
const MODE_2_PLAYERS = 2

# Preload dolphin scenes
const DOLPHIN_PLAYER = preload("res://scenes/DolphinPlayer.tscn")
const DOLPHIN_AI = preload("res://scenes/DolphinAI.tscn")
const DOLPHIN_PLAYER2 = preload("res://scenes/DolphinPlayer2.tscn")

# ============================================================================
# REFERENCES
# ============================================================================
@onready var hud: CanvasLayer = $Canvas/HUD
@onready var result_menu: CanvasLayer = $Canvas/ResultMenu
@onready var start_menu: CanvasLayer = $Canvas/StartMenu
@onready var camera: Camera2D = $Camera2D
@onready var spawn1: Node2D = $Spawn1
@onready var spawn2: Node2D = $Spawn2

# ============================================================================
# VARIABLES
# ============================================================================
var game_mode: int = 0
var dolphin_player: Node = null
var dolphin_opponent: Node = null

# ============================================================================
# SIGNALS
# ============================================================================
# signal game_restart_requested

# ============================================================================
# LIFECYCLE
# ============================================================================

func _ready() -> void:
	# Connect start menu signal for game mode selection
	if start_menu and start_menu.has_signal("game_mode_selected"):
		start_menu.game_mode_selected.connect(_on_game_mode_selected)
		print("✅ Connected to StartMenu.game_mode_selected signal")
	else:
		print("❌ Could not find or connect to StartMenu.game_mode_selected signal")
	
	# Connect result menu signal
	if result_menu and result_menu.has_signal("restart_game_requested"):
		result_menu.restart_game_requested.connect(_on_restart_game_requested)
	
	# Pause game initially to show start menu
	get_tree().paused = true
	
	print("✅ GameManager initialized")


# ============================================================================
# SIGNAL HANDLERS
# ============================================================================

func _on_game_mode_selected(mode: int) -> void:
	"""Handle game mode selection from start menu"""
	print("🎮 GameManager: Game mode selected - ", mode)
	game_mode = mode
	
	if game_mode == MODE_1_PLAYER:
		_setup_dolphins_vs_ai()
	elif game_mode == MODE_2_PLAYERS:
		_setup_dolphins_vs_player()


func _setup_dolphins_vs_ai() -> void:
	"""Setup 1 Player mode: DolphinPlayer vs DolphinAI"""
	print("🐬 GameManager: Setting up 1 Player mode (vs AI)")
	
	# Clear existing dolphins
	if dolphin_player:
		dolphin_player.queue_free()
	if dolphin_opponent:
		dolphin_opponent.queue_free()
	
	# Instantiate DolphinPlayer at spawn1
	dolphin_player = DOLPHIN_PLAYER.instantiate()
	dolphin_player.position = spawn1.position
	add_child(dolphin_player)
	print("🐬 DolphinPlayer instantiated at position: ", dolphin_player.position)
	
	# Instantiate DolphinAI at spawn2
	dolphin_opponent = DOLPHIN_AI.instantiate()
	dolphin_opponent.position = spawn2.position
	add_child(dolphin_opponent)
	print("🦾 DolphinAI instantiated at position: ", dolphin_opponent.position)
	
	# Connect shark signals to player
	var obstacle_generator = get_node_or_null("Obstacles")
	if obstacle_generator:
		obstacle_generator.connect_shark_signals_to_target(dolphin_player)
		print("🔗 Connected obstacle generator to DolphinPlayer")
	
	# Update camera target
	if camera:
		camera.target_a = dolphin_player
		camera.target_b = dolphin_opponent
		print("📷 Camera setup: following DolphinPlayer and DolphinAI")
	
	# Update HUD target
	if hud and hud.has_method("set_target"):
		hud.set_target(dolphin_player)
		print("📊 HUD tracking DolphinPlayer")
	
	# Unpause game to start
	get_tree().paused = false
	print("▶️ Game unpaused - Starting 1 Player mode!")


func _setup_dolphins_vs_player() -> void:
	"""Setup 2 Players mode: DolphinPlayer vs DolphinPlayer2"""
	print("🐬 GameManager: Setting up 2 Players mode (vs Player)")
	print("📍 Spawn1 position: ", spawn1.position)
	print("📍 Spawn2 position: ", spawn2.position)
	
	# Clear existing dolphins
	if dolphin_player:
		dolphin_player.queue_free()
	if dolphin_opponent:
		dolphin_opponent.queue_free()
	
	# Instantiate DolphinPlayer at spawn1
	dolphin_player = DOLPHIN_PLAYER.instantiate()
	dolphin_player.position = spawn1.position
	add_child(dolphin_player)
	print("🐬 DolphinPlayer instantiated at position: ", dolphin_player.position)
	
	# Instantiate DolphinPlayer2 at spawn2
	dolphin_opponent = DOLPHIN_PLAYER2.instantiate()
	dolphin_opponent.position = spawn2.position
	add_child(dolphin_opponent)
	print("🐬 DolphinPlayer2 instantiated at position: ", dolphin_opponent.position)
	
	# Connect shark signals to first player
	var obstacle_generator = get_node_or_null("Obstacles")
	if obstacle_generator:
		obstacle_generator.connect_shark_signals_to_target(dolphin_player)
		print("🔗 Connected obstacle generator to DolphinPlayer")
	
	# Update camera to follow both players
	if camera:
		camera.target_a = dolphin_player
		camera.target_b = dolphin_opponent
		print("📷 Camera setup: following both DolphinPlayer and DolphinPlayer2")
	
	# Update HUD target to first player
	if hud and hud.has_method("set_target"):
		hud.set_target(dolphin_player)
		print("📊 HUD tracking DolphinPlayer")
	
	# Unpause game to start
	get_tree().paused = false
	print("▶️ Game unpaused - Starting 2 Player mode!")


func _on_shark_dolphin_touched() -> void:
	print("🎮 GameManager: Dolphin was touched by shark!")
	show_result_menu()


func _on_restart_game_requested() -> void:
	print("🔄 Restarting game...")
	get_tree().reload_current_scene()


# ============================================================================
# GAME CONTROL
# ============================================================================

func show_result_menu() -> void:
	"""Show the result menu with the current distance"""
	var current_distance = 0.0
	if hud and hud.has_method("get_current_distance"):
		current_distance = hud.get_current_distance()
	
	if result_menu and result_menu.has_method("show_result"):
		result_menu.show_result(current_distance)

