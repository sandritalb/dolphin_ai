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
@export var cloud_speed_min: float = 0.3  # Clouds near sea level move at 30% of camera speed
@export var cloud_speed_max: float = 0.7  # Clouds high in sky move at 70% of camera speed

# ============================================================================
# INTERNAL STATE
# ============================================================================
var spawn_timer: float = 0.0


# ============================================================================
# LIFECYCLE
# ============================================================================

func _ready() -> void:
	# Use this node itself as the container
	_initialize_pool()
	
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
		add_child(cloud)  # Add directly to this node
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
	
	# Determine spawn Y position first
	var spawn_y = randf_range(spawn_y_min, spawn_y_max)
	
	# Calculate depth factor: 0.0 = top of sky (spawn_y_min), 1.0 = near sea level (spawn_y_max)
	var depth_factor = (spawn_y - spawn_y_min) / (spawn_y_max - spawn_y_min)
	
	# Speed multiplier based on depth: lower clouds (higher depth_factor) move slower
	# This creates parallax effect - clouds near water seem farther away
	var speed_multiplier = lerp(cloud_speed_max, cloud_speed_min, depth_factor)
	
	cloud.set_meta("speed_multiplier", speed_multiplier)
	
	# Set speed multiplier on cloud (percentage of camera speed)
	if cloud.has_method("set_movement_speed"):
		cloud.set_movement_speed(speed_multiplier)
	
	# Set scale based on depth (lower clouds are smaller)
	if cloud.has_method("set_scale_based_on_depth"):
		cloud.set_scale_based_on_depth(depth_factor)
	
	# Clouds spawn farther ahead based on their speed
	# Faster clouds spawn closer, slower clouds spawn farther
	var adjusted_spawn_distance = spawn_distance_ahead / speed_multiplier
	var spawn_x = player.global_position.x + adjusted_spawn_distance + randf_range(-200, 200)
	
	cloud.global_position = Vector2(spawn_x, spawn_y)
	
	# Show cloud and enable processing
	cloud.show()
	cloud.process_mode = Node.PROCESS_MODE_INHERIT
	
	# Store reference and show frame aleatorio if tiene el script
	if cloud.has_method("mostrar_frame_aleatorio"):
		cloud.mostrar_frame_aleatorio()
	
	active_clouds.append(cloud)
	print("☁️ Cloud spawned at Y: %.0f, depth: %.2f, speed: %.0f%%" % [spawn_y, depth_factor, speed_multiplier * 100])

# ============================================================================
# MOVEMENT LOGIC
# ============================================================================

func _move_clouds() -> void:
	"""Clouds now handle their own movement in cloud.gd"""
	# Movement is now handled by each cloud's _process() function
	# This allows for individual speed control based on depth
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
	
	# Spawn some initial clouds immediately
	_spawn_initial_clouds()


func _spawn_initial_clouds() -> void:
	"""Spawn initial clouds across the visible area"""
	if not player:
		return
	
	# Spawn 5-8 clouds at various distances ahead
	var initial_count = randi_range(5, 8)
	for i in range(initial_count):
		if cloud_pool.is_empty():
			break
		
		var cloud = cloud_pool.pop_front()
		
		# Spread clouds across the visible and near-visible area
		var spawn_y = randf_range(spawn_y_min, spawn_y_max)
		var depth_factor = (spawn_y - spawn_y_min) / (spawn_y_max - spawn_y_min)
		var speed_multiplier = lerp(cloud_speed_max, cloud_speed_min, depth_factor)
		
		cloud.set_meta("speed_multiplier", speed_multiplier)
		
		# Set speed multiplier (percentage of camera speed)
		if cloud.has_method("set_movement_speed"):
			cloud.set_movement_speed(speed_multiplier)
		
		if cloud.has_method("set_scale_based_on_depth"):
			cloud.set_scale_based_on_depth(depth_factor)
		
		# Spread initial clouds from behind player to ahead
		var spawn_x = player.global_position.x + randf_range(-200, spawn_distance_ahead)
		
		cloud.global_position = Vector2(spawn_x, spawn_y)
		cloud.show()
		cloud.process_mode = Node.PROCESS_MODE_INHERIT
		
		if cloud.has_method("mostrar_frame_aleatorio"):
			cloud.mostrar_frame_aleatorio()
		
		active_clouds.append(cloud)
	
	print("☁️ Spawned %d initial clouds" % initial_count)
