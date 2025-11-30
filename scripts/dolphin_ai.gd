# ============================================================================
# DOLPHIN AI - AI input controller (composition)
# Handles AI-controlled dolphin behavior with smart decision making
# ============================================================================

extends Node

# AI parameters - Distances for decision making (tweak these!)
@export_group("Detection Distances")
@export var shark_danger_distance: float = 300.0    # Distance to start avoiding sharks
@export var boat_danger_distance: float = 300.0     # Distance to start reacting to boats (needs early reaction for jumps)
@export var fish_chase_distance: float = 250.0      # Distance to chase fish

@export_group("Vertical Thresholds")
@export var vertical_avoid_threshold: float = 50.0  # Min vertical distance to consider "above" or "below"
@export var shark_vertical_danger_threshold: float = 50.0  # Vertical threshold for shark danger
@export var boat_jump_clearance: float = 100.0      # Space needed above boat to attempt jump
@export var max_depth_for_jump: float = 80.0        # Max depth below water to attempt a jump (increased for earlier surfacing)

@export_group("Safety Margins")
@export var shark_safety_multiplier: float = 1.2    # Extra margin when checking for sharks before chasing fish

# AI state
var ai_direction: Vector2 = Vector2.RIGHT

# Parent dolphin reference
var dolphin: Node = null
var is_in_water: bool = true

# Event tracking for observations
var last_fish_eaten: bool = false
var last_boat_hit: bool = false
var last_shark_hit: bool = false


# func _physics_process(_delta: float) -> void:
# 	var _observations = get_observations()


func on_ready(parent_dolphin: Node) -> void:
	dolphin = parent_dolphin
	ai_direction = Vector2.RIGHT
	
	# Connect to dolphin signals for event tracking
	if dolphin:
		if dolphin.has_signal("fish_eaten_signal"):
			dolphin.fish_eaten_signal.connect(_on_fish_eaten)
		if dolphin.has_signal("boat_hit_signal"):
			dolphin.boat_hit_signal.connect(_on_boat_hit)
		if dolphin.has_signal("shark_hit_signal"):
			dolphin.shark_hit_signal.connect(_on_shark_hit)
	
	print("🤖 AI Controller initialized")


func get_input(_delta: float) -> Vector2:
	# Get parent dolphin's water state
	if dolphin and "is_in_water" in dolphin:
		is_in_water = dolphin.is_in_water
	
	# AI only controls movement in water
	if not is_in_water:
		return Vector2.ZERO
	
	# Make decision based on observations
	ai_direction = _make_decision()
	
	return ai_direction


func _make_decision() -> Vector2:
	"""
	Make AI decision based on current game state.
	Priority:
	1. Avoid sharks (highest priority - survival)
	2. Avoid/jump boats
	3. Chase fish (only if safe)
	4. Default: go right
	"""
	if not dolphin:
		return Vector2.RIGHT
	
	var my_pos = dolphin.position
	
	# Gather nearby entities
	var nearest_shark = _find_nearest_threat("sharks")
	var nearest_boat = _find_nearest_threat("boats")
	var nearest_fish = _find_nearest_entity("fish")
	
	# Priority 1: Avoid sharks
	if nearest_shark != null:
		var shark_dist_x = abs(my_pos.x - nearest_shark.position.x)
		var shark_dist_y = abs(my_pos.y - nearest_shark.position.y)
		if shark_dist_x < shark_danger_distance and shark_dist_y < shark_vertical_danger_threshold:
			# Shark is close and at dangerous height - AVOID IT!
			return _avoid_shark_smart(my_pos, nearest_shark.position)
	
	# Priority 2: Handle boats
	if nearest_boat != null:
		var boat_dist = my_pos.distance_to(nearest_boat.position)
		if boat_dist < boat_danger_distance:
			# Check if we can safely jump the boat
			if _can_jump_boat(nearest_boat.position):
				# Go up to jump over the boat
				return Vector2(1.0, -1.0).normalized()
			else:
				# Go down to avoid the boat
				return Vector2(1.0, 1.0).normalized()
	
	# Priority 3: Chase fish (only if no nearby sharks in vertical area)
	if nearest_fish != null:
		var fish_dist = my_pos.distance_to(nearest_fish.position)
		if fish_dist < fish_chase_distance and _is_safe_to_chase_fish_vertical(nearest_fish.position):
			return _chase_entity(nearest_fish.position)
	
	# Default: go right (do nothing special)
	return Vector2.RIGHT


func _find_nearest_threat(group_name: String) -> Node:
	"""Find the nearest entity in a group that is AHEAD of the dolphin."""
	if not dolphin:
		return null
	
	var my_pos = dolphin.position
	var nearest: Node = null
	var nearest_dist: float = INF
	
	var entities = get_tree().get_nodes_in_group(group_name)
	for entity in entities:
		if not entity.visible:
			continue
		# Only consider threats that are ahead of us (to the right)
		if entity.position.x > my_pos.x:
			var dist = my_pos.distance_to(entity.position)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest = entity
	
	return nearest


func _find_nearest_entity(group_name: String) -> Node:
	"""Find the nearest visible entity in a group."""
	if not dolphin:
		return null
	
	var my_pos = dolphin.position
	var nearest: Node = null
	var nearest_dist: float = INF
	
	var entities = get_tree().get_nodes_in_group(group_name)
	for entity in entities:
		if not entity.visible:
			continue
		# Prefer entities ahead of us, but consider all
		var dist = my_pos.distance_to(entity.position)
		# Bonus for entities ahead (reduce apparent distance)
		if entity.position.x > my_pos.x:
			dist *= 0.7
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = entity
	
	return nearest


func _avoid_entity(entity_pos: Vector2) -> Vector2:
	"""Calculate direction to avoid an entity."""
	var my_pos = dolphin.position
	var diff_y = entity_pos.y - my_pos.y
	
	# If entity is above us, go down. If below, go up.
	if diff_y < -vertical_avoid_threshold:
		# Entity is above - go down
		return Vector2(1.0, 1.0).normalized()
	elif diff_y > vertical_avoid_threshold:
		# Entity is below - go up
		return Vector2(1.0, -1.0).normalized()
	else:
		# Entity is at same level - go down (safer, stays in water)
		return Vector2(1.0, 1.0).normalized()


func _chase_entity(entity_pos: Vector2) -> Vector2:
	"""Calculate direction to chase an entity (fish)."""
	var my_pos = dolphin.position
	var diff_y = entity_pos.y - my_pos.y
	
	# Move towards the fish vertically while going right
	if diff_y < -vertical_avoid_threshold:
		# Fish is above - go up
		return Vector2(1.0, -0.5).normalized()
	elif diff_y > vertical_avoid_threshold:
		# Fish is below - go down
		return Vector2(1.0, 0.5).normalized()
	else:
		# Fish is at same level - just go right
		return Vector2.RIGHT


func _can_jump_boat(boat_pos: Vector2) -> bool:
	"""Check if there's enough space to jump over a boat."""
	var my_pos = dolphin.position
	
	# We need to be close to water surface to jump effectively
	if my_pos.y > Globals.WATER_LEVEL + max_depth_for_jump:
		# Too deep in water, better to go down
		return false
	
	# Check if there's enough clearance above the boat
	# and no sharks blocking the jump path
	var sharks = get_tree().get_nodes_in_group("sharks")
	for shark in sharks:
		if not shark.visible:
			continue
		# Check if shark is in the jump path (above boat area)
		if abs(shark.position.x - boat_pos.x) < boat_jump_clearance:
			if shark.position.y < boat_pos.y:
				# Shark is above the boat - don't jump!
				return false
	
	return true


func _is_safe_to_chase_fish() -> bool:
	"""Check if it's safe to pursue fish (no nearby sharks)."""
	if not dolphin:
		return false
	
	var my_pos = dolphin.position
	var sharks = get_tree().get_nodes_in_group("sharks")
	
	for shark in sharks:
		if not shark.visible:
			continue
		var dist = my_pos.distance_to(shark.position)
		# If a shark is within danger distance, don't chase fish
		if dist < shark_danger_distance * shark_safety_multiplier:
			return false
	
	return true


func _is_safe_to_chase_fish_vertical(nearest_fish_pos: Vector2) -> bool:
	"""Check for sharks in the same vertical area before chasing fish."""
	var sharks = get_tree().get_nodes_in_group("sharks")
	for shark in sharks:
		if not shark.visible:
			continue
		var shark_dist_x = shark.position.x - nearest_fish_pos.x
		var shark_dist_y = abs(shark.position.y - nearest_fish_pos.y)
		# Only consider sharks ahead and within ±shark_vertical_danger_threshold units vertically
		if shark_dist_x > 0 and shark_dist_x < shark_danger_distance and shark_dist_y < shark_vertical_danger_threshold:
			return false
	return true


func on_exit_water() -> void:
	pass  # AI dolphins don't print debug messages


func on_enter_water() -> void:
	pass  # AI dolphins don't print debug messages


# ============================================================================
# EVENT HANDLERS
# ============================================================================

func _on_fish_eaten(_dolphin: Node) -> void:
	last_fish_eaten = true


func _on_boat_hit(_dolphin: Node) -> void:
	last_boat_hit = true


func _on_shark_hit(_dolphin: Node) -> void:
	last_shark_hit = true


# ============================================================================
# OBSERVATIONS
# ============================================================================

func get_observations() -> Dictionary:
	"""
	Get observations for AI training/inference.
	Returns a dictionary with positions of all game entities and event flags.
	"""
	var observations = {
		"dolphin": {
			"position": {"x": 0.0, "y": 0.0},
			"velocity": {"x": 0.0, "y": 0.0},
			"is_in_water": is_in_water,
			"is_stunned": false,
			"is_fish_boosting": false,
			"fish_eaten_count": 0
		},
		"dolphins": [],
		"fish": [],
		"boats": [],
		"sharks": [],
		"events": {
			"fish_eaten": last_fish_eaten,
			"boat_hit": last_boat_hit,
			"shark_hit": last_shark_hit
		}
	}
	
	# Get own dolphin position and state
	if dolphin:
		observations["dolphin"]["position"] = {"x": dolphin.position.x, "y": dolphin.position.y}
		observations["dolphin"]["velocity"] = {"x": dolphin.velocity.x, "y": dolphin.velocity.y}
		observations["dolphin"]["is_in_water"] = dolphin.is_in_water if "is_in_water" in dolphin else is_in_water
		observations["dolphin"]["is_stunned"] = dolphin.is_stunned if "is_stunned" in dolphin else false
		observations["dolphin"]["is_fish_boosting"] = dolphin.is_fish_boosting if "is_fish_boosting" in dolphin else false
		observations["dolphin"]["fish_eaten_count"] = dolphin.fish_eaten_count if "fish_eaten_count" in dolphin else 0
	
	# Get all dolphins in the scene
	var all_dolphins = get_tree().get_nodes_in_group("dolphins")
	for d in all_dolphins:
		if d != dolphin:  # Exclude self
			observations["dolphins"].append({
				"position": {"x": d.position.x, "y": d.position.y},
				"velocity": {"x": d.velocity.x, "y": d.velocity.y}
			})
	
	# Get all fish in the scene
	var all_fish = get_tree().get_nodes_in_group("fish")
	for f in all_fish:
		if f.visible:  # Only include visible (active) fish
			observations["fish"].append({
				"position": {"x": f.position.x, "y": f.position.y}
			})
	
	# Get all boats in the scene
	var all_boats = get_tree().get_nodes_in_group("boats")
	for b in all_boats:
		if b.visible:  # Only include visible (active) boats
			observations["boats"].append({
				"position": {"x": b.position.x, "y": b.position.y}
			})
	
	# Get all sharks in the scene
	var all_sharks = get_tree().get_nodes_in_group("sharks")
	for s in all_sharks:
		if s.visible:  # Only include visible (active) sharks
			observations["sharks"].append({
				"position": {"x": s.position.x, "y": s.position.y}
			})
	
	# Reset event flags after reading (they're one-shot events)
	last_fish_eaten = false
	last_boat_hit = false
	last_shark_hit = false
	
	return observations


func _avoid_shark_smart(my_pos: Vector2, shark_pos: Vector2) -> Vector2:
	"""Avoid shark by choosing direction with more free space to water level or sea bottom."""
	var space_up = abs(my_pos.y - Globals.WATER_LEVEL)
	var space_down = abs(Globals.SEA_BOTTOM - my_pos.y)
	var diff_y = shark_pos.y - my_pos.y
	
	if space_up > space_down:
		# More space above, go up
		return Vector2(1.0, -1.0).normalized()
	else:
		# More space below, go down
		return Vector2(1.0, 1.0).normalized()
