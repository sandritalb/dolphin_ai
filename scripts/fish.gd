extends Node2D

# ============================================================================
# FISH - Swims at the bottom of the sea with bobbing motion
# ============================================================================

signal fish_eaten(fish: Node2D)

@export var wave_bob_amount: float = 8.0  # How far up/down the fish bobs
@export var wave_frequency: float = 0.6   # How fast the fish bobs (cycles per second)

var base_position: Vector2
var time_elapsed: float = 0.0

func _ready():
	base_position = position
	
	# Add to fish group for identification
	add_to_group("fish")
	
	# Connect Area2D signal to detect dolphin collision
	var area = get_node_or_null("Area2D")
	if area:
		area.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	# Check if the body is a dolphin
	if body.is_in_group("dolphins"):
		# Notify the dolphin that it ate a fish
		if body.has_method("eat_fish"):
			body.eat_fish()
		
		# Emit signal so pool manager can return this fish to pool
		fish_eaten.emit(self)
		print("🐟 Fish eaten!")

func _process(delta):
	# Create smooth bobbing motion using sine wave (like the boat)
	time_elapsed += delta
	var bob_offset = sin(time_elapsed * wave_frequency * PI * 2) * wave_bob_amount
	position = base_position + Vector2(0, bob_offset)
