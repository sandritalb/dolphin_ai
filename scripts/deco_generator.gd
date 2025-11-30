extends Node

# ============================================================================
# DECO GENERATOR - Object pooling system for background decorations
# Spawns decorations ahead of the player and despawns when out of view
# ============================================================================

# ============================================================================
# PRELOAD SCENES
# ============================================================================
var deco_scene = preload("res://scenes/BackgroundDeco.tscn")

# ============================================================================
# REFERENCES
# ============================================================================
var player: Node = null

# ============================================================================
# POOLS
# ============================================================================
var deco_pool: Array = []
var active_decos: Array = []

# ============================================================================
# SETTINGS
# ============================================================================
@export var pool_size: int = 30
@export var spawn_distance_ahead: float = 1400.0  # How far ahead to spawn
@export var despawn_distance_behind: float = 900.0  # How far behind to despawn
@export var spawn_y_min_offset: float = 200.0  # Minimum offset below water level for spawning
@export var spawn_cycle_time: float = 3.0  # Seconds between spawn attempts
@export var spawn_chance: float = 0.6  # Chance to spawn deco per cycle

# ============================================================================
# INTERNAL STATE
# ============================================================================
var spawn_timer: float = 0.0


# ============================================================================
# LIFECYCLE
# ============================================================================

func _ready() -> void:
	# Initialize pool (deferred)
	_initialize_pool.call_deferred()
	
	print("✅ Deco Generator initialized with pool of %d" % pool_size)


func _physics_process(delta: float) -> void:
	if not player:
		return
	
	# Update spawn timer
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = spawn_cycle_time
		_try_spawn_deco()
	
	# Check and despawn out-of-view decorations
	_despawn_out_of_view_decos()


# ============================================================================
# POOL INITIALIZATION
# ============================================================================

func _initialize_pool() -> void:
	"""Create pool of decorations"""
	for i in range(pool_size):
		var deco = deco_scene.instantiate()
		add_child(deco)
		deco.hide()
		deco.process_mode = Node.PROCESS_MODE_DISABLED
		deco.set_meta("pooled", true)
		deco_pool.append(deco)


# ============================================================================
# SPAWNING LOGIC
# ============================================================================

func _try_spawn_deco() -> void:
	"""Try to spawn a decoration"""
	if randf() < spawn_chance:
		_spawn_deco()


func _spawn_deco() -> void:
	"""Spawn a decoration from the pool"""
	# Get a deco from the pool
	if deco_pool.is_empty():
		return
	
	var deco = deco_pool.pop_front()
	
	# Set spawn x position ahead of the player
	var spawn_x = player.global_position.x + spawn_distance_ahead
	
	# Setup random sprite and frame, which returns the appropriate y position
	var spawn_y = Globals.SEA_BOTTOM  # Default near sea bottom
	if deco.has_method("_setup_random_deco"):
		spawn_y = deco._setup_random_deco(spawn_y_min_offset)
	
	deco.global_position = Vector2(spawn_x, spawn_y)
	
	# Show and enable the deco
	deco.show()
	deco.process_mode = Node.PROCESS_MODE_INHERIT
	
	# Add to active list
	active_decos.append(deco)


# ============================================================================
# DESPAWNING LOGIC
# ============================================================================

func _despawn_out_of_view_decos() -> void:
	"""Check and despawn decorations that are behind the player"""
	var decos_to_remove = []
	
	for deco in active_decos:
		# If deco is behind the despawn distance, return it to pool
		if deco.global_position.x < player.global_position.x - despawn_distance_behind:
			decos_to_remove.append(deco)
	
	# Return decos to pool
	for deco in decos_to_remove:
		_return_deco_to_pool(deco)


func _return_deco_to_pool(deco: Node) -> void:
	"""Return a decoration to the pool"""
	deco.hide()
	deco.process_mode = Node.PROCESS_MODE_DISABLED
	deco.set_meta("pooled", true)
	active_decos.erase(deco)
	deco_pool.append(deco)


# ============================================================================
# PUBLIC API - Called by GameManager to set player reference
# ============================================================================

func set_player(player_node: Node) -> void:
	"""Set the player reference for spawn/despawn calculations"""
	player = player_node
	print("✅ Deco Generator: Player reference set")
