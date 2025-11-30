extends Node2D

# ============================================================================
# FRAME RULES FOR EACH SET:
# Set 1: All frames except frame 7 should be very near to the sea bottom
# Set 2: Frame 4 is banned, frames 7 and 0 can be anywhere, others near sea bottom
# Set 3: Frame 4 is banned, frame 7 can be anywhere, others near sea bottom
# ============================================================================

# Frames that can spawn anywhere (not restricted to sea bottom)
const SET1_FREE_FRAMES = [7]
const SET2_FREE_FRAMES = [0, 7]
const SET3_FREE_FRAMES = [7]

# Banned frames for each set
const SET1_BANNED_FRAMES = []
const SET2_BANNED_FRAMES = [4]
const SET3_BANNED_FRAMES = [4]


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Seleccionar sprite y frame al inicializar
	_setup_random_deco(200.0)


func _setup_random_deco(spawn_y_min_offset: float = 200.0) -> float:
	"""Setup random decoration - called each time the deco is reused
	   Returns the appropriate spawn Y position based on frame rules"""
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
	
	# Get allowed frames and free frames based on the selected set
	var banned_frames: Array
	var free_frames: Array
	
	match random_index:
		0:  # set1
			banned_frames = SET1_BANNED_FRAMES
			free_frames = SET1_FREE_FRAMES
		1:  # set2
			banned_frames = SET2_BANNED_FRAMES
			free_frames = SET2_FREE_FRAMES
		2:  # set3
			banned_frames = SET3_BANNED_FRAMES
			free_frames = SET3_FREE_FRAMES
	
	# Get all valid frames (excluding banned ones)
	var total_frames = selected_sprite.hframes * selected_sprite.vframes
	var valid_frames: Array = []
	for frame in range(total_frames):
		if frame not in banned_frames:
			valid_frames.append(frame)
	
	# Select a random valid frame
	var random_frame = valid_frames[randi() % valid_frames.size()]
	selected_sprite.frame = random_frame
	
	# Apply special scaling for set 2 frame 2 (scale x4)
	if random_index == 1 and random_frame == 2:
		selected_sprite.scale = Vector2(4.0, 4.0)
	else:
		selected_sprite.scale = Vector2(1.0, 1.0)
	
	# Determine spawn Y position based on whether this frame is "free" or near sea bottom
	var spawn_y: float
	if random_frame in free_frames:
		# Free frames can spawn anywhere in the water
		spawn_y = randf_range(Globals.SEA_BOTTOM - spawn_y_min_offset, Globals.SEA_BOTTOM-100)
	else:
		# Other frames should be very near to the sea bottom
		spawn_y = randf_range(Globals.SEA_BOTTOM - 100.0, Globals.SEA_BOTTOM-10)
	
	return spawn_y
