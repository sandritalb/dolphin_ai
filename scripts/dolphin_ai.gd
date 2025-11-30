# ============================================================================
# DOLPHIN AI - AI input controller (composition)
# Handles AI-controlled dolphin behavior
# ============================================================================

extends Node

# AI parameters
@export var ai_wander_speed = 1.5      # How fast AI changes direction
@export var ai_max_wander_angle = PI / 4  # Max angle AI wanders
@export var ai_tint_color: Color = Color.LIGHT_BLUE  # Tint color for AI dolphins

var websocket: WebSocketPeer = null
var websocket_connected: bool = false

# AI state
var ai_direction: Vector2 = Vector2.RIGHT
var ai_wander_timer: float = 0.0
var ai_wander_interval: float = 2.0  # Change direction every 2 seconds

# Parent dolphin reference
var dolphin: Node = null
var is_in_water: bool = true

# Event tracking for observations
var last_fish_eaten: bool = false
var last_boat_hit: bool = false
var last_shark_hit: bool = false

# JSON observations
var observations_json: String = ""

func _physics_process(_delta: float) -> void:
	# Poll websocket to process incoming data
	if websocket:
		websocket.poll()
		
		# Track connection state
		var current_state = websocket.get_ready_state()
		
		# Only send if websocket is ready
		if current_state == WebSocketPeer.STATE_OPEN:
			if not websocket_connected:
				print("🤖 WebSocket NOW READY for first send")
				websocket_connected = true
			
			var observations = get_observations()
			observations_json = JSON.stringify(observations)
			websocket.send_text(observations_json)
			print_debug("🤖 AI Observations sent: ", observations_json)
		else:
			if websocket_connected:
				print("🤖 WARNING: WebSocket lost connection! State: ", current_state, " (", _get_state_name(current_state), ")")
				websocket_connected = false
			print_debug("🤖 AI WebSocket not ready, state: ", current_state)


func _get_state_name(state: int) -> String:
	match state:
		WebSocketPeer.STATE_CONNECTING:
			return "CONNECTING"
		WebSocketPeer.STATE_OPEN:
			return "OPEN"
		WebSocketPeer.STATE_CLOSING:
			return "CLOSING"
		WebSocketPeer.STATE_CLOSED:
			return "CLOSED"
		_:
			return "UNKNOWN"


func on_ready(parent_dolphin: Node) -> void:
	websocket = WebSocketPeer.new()
	var error = websocket.connect_to_url("ws://localhost:8765")
	if error != OK:
		print("Failed to connect to WebSocket", error)
	else:
		print("WebSocket connection initiated, waiting for STATE_OPEN...")
	dolphin = parent_dolphin
	ai_direction = Vector2.RIGHT
	randomize_ai_wander()
	apply_ai_tint()
	
	# Connect to dolphin signals for event tracking
	if dolphin:
		if dolphin.has_signal("fish_eaten_signal"):
			dolphin.fish_eaten_signal.connect(_on_fish_eaten)
		if dolphin.has_signal("boat_hit_signal"):
			dolphin.boat_hit_signal.connect(_on_boat_hit)
		if dolphin.has_signal("shark_hit_signal"):
			dolphin.shark_hit_signal.connect(_on_shark_hit)
	
	print("🤖 AI Controller initialized")


func apply_ai_tint() -> void:
	# Apply tint color to both sprites
	if dolphin:
		var sprite_in = dolphin.get_node_or_null("in")
		var sprite_out = dolphin.get_node_or_null("out")
		
		if sprite_in:
			sprite_in.self_modulate = ai_tint_color
		if sprite_out:
			sprite_out.self_modulate = ai_tint_color


func get_input(delta: float) -> Vector2:
	ai_wander_timer += delta
	
	# Get parent dolphin's water state
	if dolphin and "is_in_water" in dolphin:
		is_in_water = dolphin.is_in_water
	
	# Change direction periodically
	if ai_wander_timer >= ai_wander_interval:
		randomize_ai_wander()
		ai_wander_timer = 0.0
	
	# AI only moves in water
	if is_in_water:
		return ai_direction
	
	return Vector2.ZERO


func randomize_ai_wander() -> void:
	# Random angle for wandering behavior
	var random_angle = randf_range(-ai_max_wander_angle, ai_max_wander_angle)
	
	# Prefer moving right, but allow some vertical movement
	#ai_direction = Vector2(cos(random_angle), sin(random_angle)).normalized()
	ai_direction = Vector2(1.0, sin(random_angle)).normalized()


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
