# ============================================================================
# GAME MANAGER - Central game control
# Handles signals from game elements (shark, etc.) and manages game state
# ============================================================================

extends Node

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
	print("✅ GameManager initialized")


# ============================================================================
# SIGNAL HANDLERS
# ============================================================================

func _on_shark_dolphin_touched() -> void:
	print("🎮 GameManager: Dolphin was touched by shark!")
	restart_game()


# ============================================================================
# GAME CONTROL
# ============================================================================

func restart_game() -> void:
	print("🔄 Restarting game...")
	get_tree().reload_current_scene()
