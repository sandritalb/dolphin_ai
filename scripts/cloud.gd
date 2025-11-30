extends Sprite2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mostrar_frame_aleatorio()

	

func mostrar_frame_aleatorio() -> void:
	# Si tienes una textura con múltiples frames, especifica el número total de frames
	var total_frames = 9  # Cambia esto al número de frames que tengas
	frame = randi() % total_frames
