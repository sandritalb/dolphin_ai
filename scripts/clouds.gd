extends Sprite2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mostrar_frame_aleatorio()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func mostrar_frame_aleatorio() -> void:
	# Si tienes una textura con múltiples frames, especifica el número total de frames
	var total_frames = 3  # Cambia esto al número de frames que tengas
	frame = randi() % total_frames
