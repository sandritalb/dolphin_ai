extends Node2D

func _ready():
	# Get lifetime from the Particles node and destroy after it completes
	var particles = $Particles
	var lifetime = particles.lifetime if particles else 4.0
	await get_tree().create_timer(lifetime).timeout
	queue_free()

# func _process(delta):
# 	# Move forward (along local X axis)
# 	position += transform.x * speed * delta
	
# 	# Optional: Make the ring grow slightly
# 	var particles = $Particles
# 	if particles:
# 		particles.emission_sphere_radius += growth_rate * delta
