extends Node

# ============================================================================
# FISH GENERATOR - Spawns fish at the bottom of the sea
# Fish are spawned ahead of the player and despawned when out of view
# ============================================================================

# ============================================================================
# CONSTANTS
# ============================================================================
const WATER_LEVEL: float = -100.0

# ============================================================================
# PRELOAD SCENES
# ============================================================================
var fish_scene = preload("res://scenes/fish.tscn")

# ============================================================================
# REFERENCES
# ============================================================================
var player: Node = null

# ============================================================================
# POOLS
# ============================================================================
var fish_pool: Array = []
var active_fish: Array = []

# ============================================================================
# SETTINGS
# ============================================================================
@export_category("Pool Settings")
@export var pool_size: int = 20  # Number of fish to pre-instantiate

@export_category("Spawn Distance")
@export var spawn_distance_ahead: float = 1400.0  # How far ahead to spawn
@export var despawn_distance_behind: float = 900.0  # How far behind to despawn

@export_category("Spawn Chances")
@export_range(0.0, 1.0) var fish_spawn_chance: float = 0.4  # Base chance to spawn fish per cycle
@export var spawn_cycle_time: float = 1.5  # Seconds between spawn attempts
@export var spawn_chance_increase_rate: float = 0.0  # How much to increase spawn chance per unit distance
@export_range(0.0, 1.0) var max_spawn_chance: float = 0.7  # Maximum spawn chance cap

@export_category("Depth Settings")
@export var min_depth: float = 120.0  # Minimum depth (Y position) for fish spawning
@export var max_depth: float = 320.0  # Maximum depth (Y position) for fish spawning

@export_category("Horizontal Spread")
@export var spawn_width: float = 800.0  # Width range for random horizontal spawning

# ============================================================================
# INTERNAL STATE
# ============================================================================
var spawn_timer: float = 0.0
var start_position_x: float = 0.0  # Track starting position to calculate distance
var current_fish_spawn_chance: float = 0.0


# ============================================================================
# LIFECYCLE
# ============================================================================

func _ready() -> void:
	# Initialize pool
	_initialize_pool()
	
	# Initialize spawn chance
	current_fish_spawn_chance = fish_spawn_chance
	
	print("✅ Fish Generator initialized with pool of %d fish" % pool_size)


func _physics_process(delta: float) -> void:
	if not player:
		return
	
	# Update spawn chances based on distance traveled
	_update_spawn_chance()
	
	# Update spawn timer
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = spawn_cycle_time
		_try_spawn_fish()
	
	# Check and despawn out-of-view fish
	_despawn_out_of_view_fish()


# ============================================================================
# POOL INITIALIZATION
# ============================================================================

func _initialize_pool() -> void:
	# Create fish pool
	for i in range(pool_size):
		var fish = fish_scene.instantiate()
		add_child(fish)
		fish.hide()
		fish.process_mode = Node.PROCESS_MODE_DISABLED  # Disable processing
		fish.set_meta("pooled", true)
		fish_pool.append(fish)


# ============================================================================
# SPAWNING LOGIC
# ============================================================================

func _try_spawn_fish() -> void:
	# Try to spawn a fish based on current spawn chance
	if randf() < current_fish_spawn_chance:
		_spawn_fish()


func _spawn_fish() -> void:
	var fish = _get_pooled_fish()
	if fish:
		_position_fish_ahead(fish)
		fish.show()
		fish.process_mode = Node.PROCESS_MODE_INHERIT  # Enable processing
		fish.set_meta("pooled", false)
		active_fish.append(fish)
		print("🐟 Spawning fish. Active fish count: %d" % active_fish.size())
		# Connect fish_eaten signal if not already connected
		if fish.has_signal("fish_eaten"):
			if not fish.fish_eaten.is_connected(_on_fish_eaten):
				fish.fish_eaten.connect(_on_fish_eaten)


func _position_fish_ahead(fish: Node2D) -> void:
	# Position fish ahead of player, at the bottom of the sea
	var spawn_x = player.position.x + spawn_distance_ahead + randf_range(-spawn_width / 2.0, spawn_width / 2.0)
	# Spawn between min_depth and max_depth (bottom of the sea)
	var spawn_y = randf_range(min_depth, max_depth)
	var spawn_position = Vector2(spawn_x, spawn_y)
	
	# Set the fish's position
	fish.position = spawn_position
	
	# Reset the fish's base position for bobbing animation
	if fish.has_method("_ready"):
		fish.base_position = spawn_position
		fish.time_elapsed = randf() * 10.0  # Randomize starting phase for variety
	
	print("🐟 Fish spawned at position: ", fish.position)


# ============================================================================
# POOL MANAGEMENT
# ============================================================================

func _get_pooled_fish() -> Node2D:
	if fish_pool.size() > 0:
		return fish_pool.pop_front()
	return null


func _despawn_out_of_view_fish() -> void:
	# Despawn fish that are behind the player
	for i in range(active_fish.size() - 1, -1, -1):
		var fish = active_fish[i]
		if fish.position.x < player.position.x - despawn_distance_behind:
			_return_fish_to_pool(fish)
			active_fish.remove_at(i)


func _on_fish_eaten(fish: Node2D) -> void:
	"""Handle when a fish is eaten by a dolphin - return it to pool"""
	if fish in active_fish:
		active_fish.erase(fish)
		_return_fish_to_pool(fish)


func _return_fish_to_pool(fish: Node2D) -> void:
	"""Return a fish to the pool for reuse"""
	# Use call_deferred to avoid disabling collision objects during physics callbacks
	fish.call_deferred("hide")
	fish.call_deferred("set_process_mode", Node.PROCESS_MODE_DISABLED)
	fish.set_meta("pooled", true)
	fish_pool.append(fish)


# ============================================================================
# SPAWN CHANCE MANAGEMENT
# ============================================================================

func _update_spawn_chance() -> void:
	# Increase spawn chance based on distance traveled
	var distance_traveled = max(0.0, player.position.x - start_position_x)
	current_fish_spawn_chance = min(fish_spawn_chance + (distance_traveled * spawn_chance_increase_rate), max_spawn_chance)


# ============================================================================
# PUBLIC API
# ============================================================================

func set_player_target(target: Node) -> void:
	"""
	Set the player target for fish spawning.
	Called by GameManager when a game mode is selected.
	"""
	player = target
	start_position_x = target.position.x  # Record starting position for distance tracking
	print("🎯 Fish Generator: Setting player target to: %s" % target.name)


func reset() -> void:
	"""Reset the fish generator - return all active fish to pool"""
	for fish in active_fish:
		fish.hide()
		fish.process_mode = Node.PROCESS_MODE_DISABLED
		fish.set_meta("pooled", true)
		fish_pool.append(fish)
	active_fish.clear()
	
	spawn_timer = 0.0
	current_fish_spawn_chance = fish_spawn_chance
	print("🔄 Fish Generator reset")
