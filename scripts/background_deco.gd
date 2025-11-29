extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Seleccionar sprite y frame al inicializar
	_setup_random_deco()


func _setup_random_deco() -> void:
	"""Setup random decoration - called each time the deco is reused"""
	# Obtener los tres elementos de la escena
	var elements = [
		$set1,
		$set2,
		$set3
	]
	
	# Seleccionar aleatoriamente uno de los tres
	var random_index = randi() % elements.size()
	var selected_sprite = elements[random_index]
	
	# Ocultar todos excepto el seleccionado
	for i in range(elements.size()):
		elements[i].visible = (i == random_index)
	
	# Seleccionar un frame aleatorio dentro del sprite seleccionado
	# Con hframes=3 y vframes=3, hay 9 frames en total (0-8)
	var total_frames = selected_sprite.hframes * selected_sprite.vframes
	var random_frame = randi() % total_frames
	selected_sprite.frame = random_frame
