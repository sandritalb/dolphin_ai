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

# Dolphin tags for identification (used to determine winner)
const TAG_PLAYER_1 = "Player 1"
const TAG_PLAYER_2 = "Player 2"
const TAG_AI = "AI"

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
		_setup_game(DOLPHIN_PLAYER, TAG_PLAYER_1, DOLPHIN_AI, TAG_AI)
	elif game_mode == MODE_2_PLAYERS:
		_setup_game(DOLPHIN_PLAYER, TAG_PLAYER_1, DOLPHIN_PLAYER2, TAG_PLAYER_2)


# ============================================================================
# GAME SETUP
# ============================================================================

func _setup_game(player_scene: PackedScene, player_tag: String, opponent_scene: PackedScene, opponent_tag: String) -> void:
	"""Setup game with specified dolphin scenes and tags"""
	print("🐬 GameManager: Setting up game - %s vs %s" % [player_tag, opponent_tag])
	
	# Clear existing dolphins
	_clear_dolphins()
	
	# Instantiate dolphins
	dolphin_player = _create_dolphin(player_scene, spawn1.position, player_tag)
	dolphin_opponent = _create_dolphin(opponent_scene, spawn2.position, opponent_tag)
	
	# Connect signals and setup game systems
	_connect_dolphin_signals()
	_setup_obstacle_generator()
	_setup_camera()
	_setup_hud()
	
	# Start game
	get_tree().paused = false
	print("▶️ Game unpaused - Starting %s vs %s!" % [player_tag, opponent_tag])


func _clear_dolphins() -> void:
	"""Clear existing dolphin instances"""
	if dolphin_player:
		dolphin_player.queue_free()
		dolphin_player = null
	if dolphin_opponent:
		dolphin_opponent.queue_free()
		dolphin_opponent = null


func _create_dolphin(scene: PackedScene, spawn_position: Vector2, tag: String) -> Node:
	"""Create and configure a dolphin instance"""
	var dolphin = scene.instantiate()
	dolphin.position = spawn_position
	dolphin.set_meta("dolphin_tag", tag)
	add_child(dolphin)
	print("🐬 %s dolphin instantiated at position: %s" % [tag, dolphin.position])
	return dolphin


func _connect_dolphin_signals() -> void:
	"""Connect disappear signals from both dolphins"""
	if dolphin_player and dolphin_player.has_signal("dolphin_disappeared_from_screen"):
		dolphin_player.dolphin_disappeared_from_screen.connect(_on_dolphin_disappeared)
	if dolphin_opponent and dolphin_opponent.has_signal("dolphin_disappeared_from_screen"):
		dolphin_opponent.dolphin_disappeared_from_screen.connect(_on_dolphin_disappeared)


func _setup_obstacle_generator() -> void:
	"""Connect obstacle generator signals to player dolphin"""
	var obstacle_generator = get_node_or_null("Obstacles")
	if obstacle_generator:
		obstacle_generator.connect_shark_signals_to_target(dolphin_player)
		print("🔗 Connected obstacle generator to player dolphin")


func _setup_camera() -> void:
	"""Setup camera to follow both dolphins"""
	if camera:
		camera.target_a = dolphin_player
		camera.target_b = dolphin_opponent
		print("📷 Camera setup: following both dolphins")


func _setup_hud() -> void:
	"""Setup HUD to track player dolphin"""
	if hud and hud.has_method("set_target"):
		hud.set_target(dolphin_player)
		print("📊 HUD tracking player dolphin")


func _on_shark_dolphin_touched() -> void:
	print("🎮 GameManager: Dolphin was touched by shark!")
	show_result_menu()


func _on_dolphin_disappeared(disappeared_dolphin: Node, _disappeared_dolphin_name: String) -> void:
	"""Handle when a dolphin disappears from screen - the other dolphin wins"""
	print("🎮 GameManager: Dolphin disappeared - ", disappeared_dolphin.name)
	
	# The winner is the OTHER dolphin (the one that didn't disappear)
	var winner_tag = ""
	if disappeared_dolphin == dolphin_player:
		winner_tag = dolphin_opponent.get_meta("dolphin_tag", "Unknown")
	else:
		winner_tag = dolphin_player.get_meta("dolphin_tag", "Unknown")
	
	var winner_name = "🏆 %s Wins!" % winner_tag
	
	# Show result menu with winner
	var current_distance = 0.0
	if hud and hud.has_method("get_current_distance"):
		current_distance = hud.get_current_distance()
	
	if result_menu and result_menu.has_method("show_result"):
		result_menu.show_result(current_distance, winner_name)
	
	print("🏆 Game Over! " + winner_name)


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

