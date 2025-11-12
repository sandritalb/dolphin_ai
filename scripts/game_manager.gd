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
	# Connect to the shark's signal
	var shark = get_tree().root.get_node_or_null("Main/Shark")
	if shark:
		if shark.has_signal("dolphin_touched"):
			shark.dolphin_touched.connect(_on_shark_dolphin_touched)
			print("✅ GameManager connected to Shark's dolphin_touched signal")
		else:
			print("⚠️ WARNING: Shark doesn't have 'dolphin_touched' signal")
	else:
		print("⚠️ WARNING: Could not find Shark node in the scene")


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
