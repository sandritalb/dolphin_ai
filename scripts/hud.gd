# ============================================================================
# HUD - Heads-Up Display for game stats
# Shows distance traveled and speed in real-time
# ============================================================================

extends CanvasLayer

# References
@onready var distance_label: Label = $VBoxContainer/DistanceLabel
@onready var speed_label: Label = $VBoxContainer/SpeedLabel

# Target to track
@export var target: Node2D = null
var target_b: Node2D = null

# Constants
const PIXELS_TO_NAUTICAL_MILES: float = 1.0 / 1852.0  # 1 nautical mile = 1852 meters
const PIXELS_PER_SECOND_TO_KNOTS: float = 0.03  # Conversion factor

# Initial position tracking
var initial_position: Vector2 = Vector2.ZERO
var starting_x: float = 0.0
var starting_x_b: float = 0.0
var current_distance_nm: float = 0.0


func _ready() -> void:
	# Initialize labels
	if distance_label:
		distance_label.text = "Distance: 0 nm"
	if speed_label:
		speed_label.text = "Speed: 0 kts"
	
	print("✅ HUD initialized")


func set_target(player: Node2D) -> void:
	"""Set the target node to track (usually the player dolphin)"""
	target = player
	if target:
		starting_x = target.position.x
		print("📊 HUD tracking target: %s" % target.name)


func set_targets(player_a: Node2D, player_b: Node2D) -> void:
	"""Set both targets to track for max distance calculation"""
	target = player_a
	target_b = player_b
	if target:
		starting_x = target.position.x
		print("📊 HUD tracking target A: %s" % target.name)
	if target_b:
		starting_x_b = target_b.position.x
		print("📊 HUD tracking target B: %s" % target_b.name)


func get_current_distance() -> float:
	"""Returns the current distance traveled in nautical miles"""
	return current_distance_nm


func _process(_delta: float) -> void:
	if not target:
		return
	
	# Update distance (based on horizontal movement) - use max of both dolphins
	var distance_a_pixels = target.position.x - starting_x
	var distance_a_nm = distance_a_pixels * PIXELS_TO_NAUTICAL_MILES
	
	var distance_b_nm = 0.0
	if target_b:
		var distance_b_pixels = target_b.position.x - starting_x_b
		distance_b_nm = distance_b_pixels * PIXELS_TO_NAUTICAL_MILES
	
	# Use the maximum distance between both dolphins
	current_distance_nm = max(distance_a_nm, distance_b_nm)
	
	if distance_label:
		distance_label.text = "Distance: %.1f nm" % current_distance_nm
	
	# Update speed (convert velocity magnitude to knots)
	var speed_pixels_per_second = 0.0
	if target and "velocity" in target:
		speed_pixels_per_second = target.velocity.length()
	var speed_knots = speed_pixels_per_second * PIXELS_PER_SECOND_TO_KNOTS
	
	if speed_label:
		speed_label.text = "Speed: %.1f kts" % speed_knots
