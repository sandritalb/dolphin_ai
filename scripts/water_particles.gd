extends GPUParticles2D

# ============================================================================
# WATER PARTICLES - Water splash effects when dolphin enters/exits water
# ============================================================================

func _ready():
	# Start with particles disabled
	emitting = false

func create_splash():
	"""Emit a burst of water particles"""
	emitting = true
	# Let it emit for a short duration
	await get_tree().create_timer(0.3).timeout
	emitting = false
