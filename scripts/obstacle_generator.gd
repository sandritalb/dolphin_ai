extends Node

# ============================================================================
# OBSTACLE GENERATOR - Object pooling system for sharks and boats
# Spawns obstacles ahead of the player and despawns when out of view
# ============================================================================

# ============================================================================
# CONSTANTS
# ============================================================================
const WATER_LEVEL: float = -100.0
const SHARK_CONTAINER_NAME: String = "SharkContainer"
const BOAT_CONTAINER_NAME: String = "BoatContainer"

# ============================================================================
# PRELOAD SCENES
# ============================================================================
var shark_scene = preload("res://scenes/Shark.tscn")
var boat_scene = preload("res://scenes/Boat.tscn")

# ============================================================================
# REFERENCES
# ============================================================================
var shark_container: Node = null
var boat_container: Node = null
var player: Node = null

# ============================================================================
# POOLS
# ============================================================================
var shark_pool: Array = []
var boat_pool: Array = []
var active_sharks: Array = []
var active_boats: Array = []

# ============================================================================
# SETTINGS
# ============================================================================
@export var pool_size: int = 20
@export var spawn_distance_ahead: float = 1400.0  # How far ahead to spawn
@export var despawn_distance_behind: float = 900.0  # How far behind to despawn
@export var spawn_width: float = 1000.0  # Width range for random spawning
@export var shark_spawn_chance: float = 0.3  # Chance to spawn shark per cycle
@export var boat_spawn_chance: float = 0.3  # Chance to spawn boat per cycle
@export var spawn_cycle_time: float = 2.0  # Seconds between spawn attempts
@export var shark_min_depth_offset: float = 50.0  # Minimum offset below water level
@export var shark_max_depth: float = 350.0  # Maximum depth (above this value)
@export var spawn_chance_increase_rate: float = 0.004  # How much to increase spawn chances per second
@export var max_spawn_chance: float = 0.8  # Maximum spawn chance cap

# ============================================================================
# INTERNAL STATE
# ============================================================================
var spawn_timer: float = 0.0
var elapsed_time: float = 0.0  # Track time to increase spawn chances
var current_shark_spawn_chance: float = 0.0
var current_boat_spawn_chance: float = 0.0


# ============================================================================
# LIFECYCLE
# ============================================================================

func _ready() -> void:
	# Get references
	player = get_tree().root.get_node("Main/DolphinPlayer")
	shark_container = get_node(SHARK_CONTAINER_NAME)
	boat_container = get_node(BOAT_CONTAINER_NAME)
	
	# Verify containers exist
	if not shark_container:
		print("⚠️ SharkContainer not found! Creating one...")
		shark_container = Node.new()
		shark_container.name = SHARK_CONTAINER_NAME
		get_parent().add_child(shark_container)
	
	if not boat_container:
		print("⚠️ BoatContainer not found! Creating one...")
		boat_container = Node.new()
		boat_container.name = BOAT_CONTAINER_NAME
		get_parent().add_child(boat_container)
	
	if not player:
		print("❌ ERROR: Dolphin player not found!")
		return
	
	# Initialize pools
	_initialize_pools()
	
	# Initialize spawn chances
	current_shark_spawn_chance = shark_spawn_chance
	current_boat_spawn_chance = boat_spawn_chance
	
	print("✅ Obstacle Generator initialized with pools of %d" % pool_size)


func _physics_process(delta: float) -> void:
	if not player:
		return
	
	# Track elapsed time and increase spawn chances
	elapsed_time += delta
	_update_spawn_chances()
	
	# Update spawn timer
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = spawn_cycle_time
		_try_spawn_obstacles()
	
	# Check and despawn out-of-view obstacles
	_despawn_out_of_view_obstacles()


# ============================================================================
# POOL INITIALIZATION
# ============================================================================

func _initialize_pools() -> void:
	# Create shark pool
	for i in range(pool_size):
		var shark = shark_scene.instantiate()
		shark_container.add_child(shark)
		shark.hide()
		shark.process_mode = Node.PROCESS_MODE_DISABLED  # Disable physics
		shark.set_meta("pooled", true)
		shark_pool.append(shark)
	
	# Create boat pool
	for i in range(pool_size):
		var boat = boat_scene.instantiate()
		boat_container.add_child(boat)
		boat.hide()
		boat.process_mode = Node.PROCESS_MODE_DISABLED  # Disable physics
		boat.set_meta("pooled", true)
		boat_pool.append(boat)


# ============================================================================
# SPAWNING LOGIC
# ============================================================================

func _try_spawn_obstacles() -> void:
	# Try to spawn a shark
	if randf() < current_shark_spawn_chance:
		_spawn_shark()
	
	# Try to spawn a boat
	if randf() < current_boat_spawn_chance:
		_spawn_boat()


func _spawn_shark() -> void:
	var shark = _get_pooled_shark()
	if shark:
		_position_shark_ahead(shark)
		shark.show()
		shark.process_mode = Node.PROCESS_MODE_INHERIT  # Enable physics
		shark.set_meta("pooled", false)
		active_sharks.append(shark)
		# Connect to dolphin_touched signal if not already connected
		if shark.has_signal("dolphin_touched"):
			if not shark.dolphin_touched.is_connected(Callable(self, "_on_shark_dolphin_touched")):
				shark.dolphin_touched.connect(Callable(self, "_on_shark_dolphin_touched"))
				print("🔗 Connected shark's dolphin_touched signal to obstacle generator")


func _spawn_boat() -> void:
	var boat = _get_pooled_boat()
	if boat:
		# Try to find a valid spawn position with minimum distance from other boats
		var spawn_position = _get_valid_boat_spawn_position()
		if spawn_position:
			boat.position = spawn_position
			boat.base_position = boat.position  # Reset bobbing base position
			boat.show()
			boat.process_mode = Node.PROCESS_MODE_INHERIT  # Enable physics
			boat.set_meta("pooled", false)
			active_boats.append(boat)
			print("⛵ Boat spawned at position: ", boat.position)
		else:
			# No valid position found, return boat to pool
			boat_pool.append(boat)
			print("⚠️ Could not find valid spawn position for boat; returning to pool.")


func _position_shark_ahead(shark: Node2D) -> void:
	# Position shark ahead of player, below water level
	var spawn_x = player.position.x + spawn_distance_ahead
	# Spawn between min_depth_offset and max_depth
	var spawn_y = randf_range(WATER_LEVEL + shark_min_depth_offset, shark_max_depth)
	var spawn_position = Vector2(spawn_x, spawn_y)
	
	# Set the shark's position first
	shark.position = spawn_position
	
	# Setup patrol points relative to shark position
	shark.setup_patrol_points(spawn_position, WATER_LEVEL, shark_min_depth_offset, shark_max_depth)
	print("🦈 Shark spawned at position: ", shark.position)

func _position_boat_ahead(boat: Node2D) -> void:
	# Position boat ahead of player at water level
	var spawn_x = player.position.x + spawn_distance_ahead + randf_range(-spawn_width / 2.0, spawn_width / 2.0)
	boat.position = Vector2(spawn_x, WATER_LEVEL)
	boat.base_position = boat.position  # Reset bobbing base position
	print("⛵ Boat spawned at position: ", boat.position)


func _get_valid_boat_spawn_position() -> Variant:
	# Try to find a spawn position that's at least 150 pixels away from other boats
	const MIN_DISTANCE: float = 150.0
	const MAX_ATTEMPTS: int = 5
	
	for attempt in range(MAX_ATTEMPTS):
		var spawn_x = player.position.x + spawn_distance_ahead + randf_range(-spawn_width / 2.0, spawn_width / 2.0)
		var spawn_position = Vector2(spawn_x, WATER_LEVEL)
		
		# Check distance from all active boats
		var is_valid = true
		for active_boat in active_boats:
			if spawn_position.distance_to(active_boat.position) < MIN_DISTANCE:
				is_valid = false
				break
		
		if is_valid:
			return spawn_position
	
	# No valid position found after max attempts
	return null


# ============================================================================
# POOL MANAGEMENT
# ============================================================================

func _get_pooled_shark() -> Area2D:
	if shark_pool.size() > 0:
		return shark_pool.pop_front()
	return null


func _get_pooled_boat() -> StaticBody2D:
	if boat_pool.size() > 0:
		return boat_pool.pop_front()
	return null


func _despawn_out_of_view_obstacles() -> void:
	# Despawn sharks
	for i in range(active_sharks.size() - 1, -1, -1):
		var shark = active_sharks[i]
		if shark.position.x < player.position.x - despawn_distance_behind:
			# Disconnect signal before returning to pool
			if shark.has_signal("dolphin_touched"):
				if shark.dolphin_touched.is_connected(Callable(self, "_on_shark_dolphin_touched")):
					shark.dolphin_touched.disconnect(Callable(self, "_on_shark_dolphin_touched"))
			
			shark.hide()
			shark.process_mode = Node.PROCESS_MODE_DISABLED  # Disable physics
			shark.set_meta("pooled", true)
			active_sharks.remove_at(i)
			shark_pool.append(shark)
	
	# Despawn boats
	for i in range(active_boats.size() - 1, -1, -1):
		var boat = active_boats[i]
		if boat.position.x < player.position.x - despawn_distance_behind:
			boat.hide()
			boat.process_mode = Node.PROCESS_MODE_DISABLED  # Disable physics
			boat.position = Vector2.ZERO  # Reset position when returning to pool
			boat.set_meta("pooled", true)
			active_boats.remove_at(i)
			boat_pool.append(boat)


# ============================================================================
# SPAWN CHANCE MANAGEMENT
# ============================================================================

func _update_spawn_chances() -> void:
	# Increase spawn chances based on elapsed time
	current_shark_spawn_chance = min(shark_spawn_chance + (elapsed_time * spawn_chance_increase_rate), max_spawn_chance)
	current_boat_spawn_chance = min(boat_spawn_chance + (elapsed_time * spawn_chance_increase_rate), max_spawn_chance)
	# print("🔺 Updated spawn chances - Shark: %.2f, Boat: %.2f" % [current_shark_spawn_chance, current_boat_spawn_chance])


# ============================================================================
# SIGNAL HANDLERS
# ============================================================================

func _on_shark_dolphin_touched() -> void:
	"""Handle when a shark touches the dolphin"""
	print("🦈 Obstacle Generator: Shark touched dolphin!")
	var game_manager = get_tree().root.get_node_or_null("Main")
	if game_manager:
		print("📍 Found GameManager, calling _on_shark_dolphin_touched()")
		game_manager._on_shark_dolphin_touched()
	else:
		print("❌ GameManager not found!")
