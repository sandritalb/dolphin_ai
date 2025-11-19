extends Node2D

@export var speed: float = 200.0
@export var lifetime: float = 4.0
@export var growth_rate: float = 5.0

func _ready():
	# Destroy after lifetime
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _process(delta):
	# Move forward (along local X axis)
	position += transform.x * speed * delta
	
	# Optional: Make the ring grow slightly
	var particles = $Particles
	if particles:
		particles.emission_sphere_radius += growth_rate * delta
