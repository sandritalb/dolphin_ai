extends Node2D

@export var stop_emit_before_remove: bool = false  # Whether to stop emitting and wait before removing

func _ready():
	# Get lifetime from the Particles node and destroy after it completes
	var particles = $Particles
	var lifetime = particles.lifetime if particles else 4.0
	await get_tree().create_timer(lifetime).timeout
	if stop_emit_before_remove:
		particles.emitting = false
		await get_tree().create_timer(lifetime).timeout
	queue_free()
