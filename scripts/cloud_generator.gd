extends Node

# ============================================================================
# CLOUD GENERATOR - Spawns random clouds in the sky
# ============================================================================

# ============================================================================
# PRELOAD SCENES
# ============================================================================
var cloud_scene = preload("res://scenes/Cloud.tscn")

# ============================================================================
# REFERENCES
# ============================================================================
var cloud_container: Node = null
var player: Node = null

# ============================================================================
# POOLS
# ============================================================================
var cloud_pool: Array = []
var active_clouds: Array = []

# ============================================================================
# SETTINGS
# ============================================================================
@export var pool_size: int = 15
@export var spawn_distance_ahead: float = 1600.0  # How far ahead to spawn
@export var despawn_distance_behind: float = 1200.0  # How far behind to despawn
@export var spawn_y_min: float = -300.0  # Minimum Y position (top of sky)
@export var spawn_y_max: float = -100.0  # Maximum Y position (water level)
@export var spawn_cycle_time: float = 2.0  # Seconds between spawn attempts
@export var spawn_chance: float = 0.7  # Chance to spawn cloud per cycle
@export var cloud_speed_min: float = 0.6  # Clouds move at 60% minimum
@export var cloud_speed_max: float = 0.8  # Clouds move at 80% maximum

# ============================================================================
# INTERNAL STATE
# ============================================================================
var spawn_timer: float = 0.0


# ============================================================================
# LIFECYCLE
# ============================================================================

func _ready() -> void:
	# Create cloud container if it doesn't exist (deferred to avoid setup conflicts)
	cloud_container = get_parent().find_child("CloudContainer")
	if not cloud_container:
		cloud_container = Node.new()
		cloud_container.name = "CloudContainer"
		get_parent().add_child.call_deferred(cloud_container)
	
	# Initialize pool (deferred)
	_initialize_pool.call_deferred()
	
	print("✅ Cloud Generator initialized with pool of %d" % pool_size)


func _process(delta: float) -> void:
	if not player:
		return
	
	# Update spawn timer
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = spawn_cycle_time
		_try_spawn_cloud()
	
	# Move clouds
	_move_clouds()
	
	# Check and despawn out-of-view clouds
	_despawn_out_of_view_clouds()


# ============================================================================
# POOL INITIALIZATION
# ============================================================================

func _initialize_pool() -> void:
	"""Create pool of clouds"""
	for i in range(pool_size):
		var cloud = cloud_scene.instantiate()
		cloud_container.add_child(cloud)
		cloud.hide()
		cloud.process_mode = Node.PROCESS_MODE_DISABLED
		cloud.set_meta("pooled", true)
		cloud_pool.append(cloud)


# ============================================================================
# SPAWNING LOGIC
# ============================================================================

func _try_spawn_cloud() -> void:
	"""Try to spawn a cloud"""
	if randf() < spawn_chance:
		_spawn_cloud()


func _spawn_cloud() -> void:
	"""Spawn a cloud from the pool"""
	# Get a cloud from the pool
	if cloud_pool.is_empty():
		return
	
	var cloud = cloud_pool.pop_front()
	
	# Assign random speed multiplier (between 60% and 80%)
	var random_speed = randf_range(cloud_speed_min, cloud_speed_max)
	cloud.set_meta("speed_multiplier", random_speed)
	
	# Clouds spawn farther ahead based on their speed
	# Faster clouds spawn closer, slower clouds spawn farther
	var adjusted_spawn_distance = spawn_distance_ahead / random_speed
	var spawn_x = player.global_position.x + adjusted_spawn_distance + randf_range(-200, 200)
	var spawn_y = randf_range(spawn_y_min, spawn_y_max)
	
	cloud.global_position = Vector2(spawn_x, spawn_y)
	
	# Show cloud and enable processing
	cloud.show()
	cloud.process_mode = Node.PROCESS_MODE_INHERIT
	
	# Store reference and show frame aleatorio if tiene el script
	if cloud.has_method("mostrar_frame_aleatorio"):
		cloud.mostrar_frame_aleatorio()
	
	active_clouds.append(cloud)
	print("☁️ Cloud spawned at: %s with speed: %.1f%%" % [cloud.global_position, random_speed * 100])

# ============================================================================
# MOVEMENT LOGIC
# ============================================================================

func _move_clouds() -> void:
	"""Move clouds - they stay in their global position, don't follow player"""
	# Clouds don't need to move, they stay where they spawn
	# The parallax effect comes from spawning at different distances
	pass


# ============================================================================
# DESPAWNING LOGIC
# ============================================================================

func _despawn_out_of_view_clouds() -> void:
	"""Check and despawn clouds that are out of view"""
	for i in range(active_clouds.size() - 1, -1, -1):
		var cloud = active_clouds[i]
		
		# If cloud is too far behind player, return to pool
		if cloud.global_position.x < player.global_position.x - despawn_distance_behind:
			_return_cloud_to_pool(cloud, i)


func _return_cloud_to_pool(cloud: Node, index: int) -> void:
	"""Return a cloud to the pool"""
	cloud.hide()
	cloud.process_mode = Node.PROCESS_MODE_DISABLED
	active_clouds.remove_at(index)
	cloud_pool.append(cloud)


# ============================================================================
# PUBLIC API - Called by GameManager to set player reference
# ============================================================================

func set_player(player_node: Node) -> void:
	"""Set the player reference for spawn/despawn calculations"""
	player = player_node
	print("✅ Cloud Generator: Player reference set")
