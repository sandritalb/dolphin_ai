extends StaticBody2D

# ============================================================================
# BOAT - Obstacle that stuns the dolphin on collision
# ============================================================================

@export var wave_bob_amount: float = 10.0  # How far up/down the boat bobs
@export var wave_frequency: float = 0.4   # How fast the boat bobs (cycles per second)

var base_position: Vector2
var time_elapsed: float = 0.0

func _ready():
	base_position = position

func _process(delta):
	# Create smooth bobbing motion using sine wave
	time_elapsed += delta
	var bob_offset = sin(time_elapsed * wave_frequency * PI * 2) * wave_bob_amount
	position = base_position + Vector2(0, bob_offset)

