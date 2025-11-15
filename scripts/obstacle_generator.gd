extends Node

# ============================================================================
# OBSTACLE GENERATOR - Object pooling system for sharks and boats
# Spawns obstacles ahead of the player and despawns when out of view
# ============================================================================

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
@export var pool_size: int = 5
@export var spawn_distance_ahead: float = 800.0  # How far ahead to spawn
@export var despawn_distance_behind: float = 500.0  # How far behind to despawn
@export var spawn_width: float = 600.0  # Width range for random spawning
@export var shark_spawn_chance: float = 0.6  # Chance to spawn shark per cycle
@export var boat_spawn_chance: float = 0.4  # Chance to spawn boat per cycle
@export var spawn_cycle_time: float = 2.0  # Seconds between spawn attempts

# ============================================================================
# INTERNAL STATE
# ============================================================================
var spawn_timer: float = 0.0


# ============================================================================
# LIFECYCLE
# ============================================================================

func _ready() -> void:
	# Get references
	player = get_tree().root.get_node("Main/Dolphin")
	shark_container = get_parent().get_node("SharkContainer")
	boat_container = get_parent().get_node("BoatContainer")
	
	# Verify containers exist
	if not shark_container:
		print("⚠️ SharkContainer not found! Creating one...")
		shark_container = Node.new()
		shark_container.name = "SharkContainer"
		get_parent().add_child(shark_container)
	
	if not boat_container:
		print("⚠️ BoatContainer not found! Creating one...")
		boat_container = Node.new()
		boat_container.name = "BoatContainer"
		get_parent().add_child(boat_container)
	
	if not player:
		print("❌ ERROR: Dolphin player not found!")
		return
	
	# Initialize pools
	_initialize_pools()
	print("✅ Obstacle Generator initialized with pools of %d" % pool_size)


func _physics_process(delta: float) -> void:
	if not player:
		return
	
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
		shark.set_meta("pooled", true)
		shark_pool.append(shark)
	
	# Create boat pool
	for i in range(pool_size):
		var boat = boat_scene.instantiate()
		boat_container.add_child(boat)
		boat.hide()
		boat.set_meta("pooled", true)
		boat_pool.append(boat)


# ============================================================================
# SPAWNING LOGIC
# ============================================================================

func _try_spawn_obstacles() -> void:
	# Try to spawn a shark
	if randf() < shark_spawn_chance:
		_spawn_shark()
	
	# Try to spawn a boat
	if randf() < boat_spawn_chance:
		_spawn_boat()


func _spawn_shark() -> void:
	var shark = _get_pooled_shark()
	if shark:
		_position_obstacle_ahead(shark)
		shark.show()
		shark.set_meta("pooled", false)
		active_sharks.append(shark)


func _spawn_boat() -> void:
	var boat = _get_pooled_boat()
	if boat:
		_position_obstacle_ahead(boat)
		boat.show()
		boat.set_meta("pooled", false)
		active_boats.append(boat)


func _position_obstacle_ahead(obstacle: Node2D) -> void:
	# Position ahead of player
	var spawn_x = player.position.x + spawn_distance_ahead
	var spawn_y = player.position.y + randf_range(-spawn_width / 2.0, spawn_width / 2.0)
	obstacle.position = Vector2(spawn_x, spawn_y)


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
			shark.hide()
			shark.set_meta("pooled", true)
			active_sharks.remove_at(i)
			shark_pool.append(shark)
	
	# Despawn boats
	for i in range(active_boats.size() - 1, -1, -1):
		var boat = active_boats[i]
		if boat.position.x < player.position.x - despawn_distance_behind:
			boat.hide()
			boat.set_meta("pooled", true)
			active_boats.remove_at(i)
			boat_pool.append(boat)


