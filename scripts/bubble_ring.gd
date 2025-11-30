extends Node2D

func _ready():
	# Get lifetime from the Particles node and destroy after it completes
	var particles = $Particles
	var lifetime = particles.lifetime if particles else 4.0
	await get_tree().create_timer(lifetime).timeout
	particles.emitting = false
	await get_tree().create_timer(lifetime).timeout
	queue_free()
