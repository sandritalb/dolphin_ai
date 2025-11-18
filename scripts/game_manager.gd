# ============================================================================
# GAME MANAGER - Central game control
# Handles signals from game elements (shark, etc.) and manages game state
# ============================================================================

extends Node

# ============================================================================
# REFERENCES
# ============================================================================
@onready var hud: CanvasLayer = $HUD
@onready var result_menu: CanvasLayer = $ResultMenu

# ============================================================================
# SIGNALS
# ============================================================================
# signal game_restart_requested

# ============================================================================
# LIFECYCLE
# ============================================================================

func _ready() -> void:
	# Note: Dynamically spawned sharks will connect their dolphin_touched signals
	# through the ObstacleGenerator when they spawn
	
	# Connect result menu signal
	if result_menu and result_menu.has_signal("restart_game_requested"):
		result_menu.restart_game_requested.connect(_on_restart_game_requested)
	
	print("✅ GameManager initialized")


# ============================================================================
# SIGNAL HANDLERS
# ============================================================================

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

