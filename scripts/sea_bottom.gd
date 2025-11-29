extends Node2D

## Sea Bottom - 4 layered polygons with varied heights for a natural ocean floor

# Width and segment configuration
@export var total_width: float = 3000.0
@export var segment_count: int = 60

# Height settings for each layer (back to front)
@export var layer1_base_height: float = 55.0  # Backmost layer (lightest, tallest)
@export var layer2_base_height: float = 40.0
@export var layer3_base_height: float = 35.0
@export var layer4_base_height: float = 15.0  # Frontmost layer (darkest, shortest)

@export var height_variance: float = 25.0
@export var smoothness: float = 0.5

# Layer colors (back to front, light to dark)
var layer_colors: Array[Color] = [
	Color("b9aa72"),  # Lightest - backmost (tallest)
	Color("af9361"),
	Color("946d4d"),
	Color("54423e"),  # Darkest - frontmost (shortest)
]

# Internal
@onready var layer1: Polygon2D = $Layer1
@onready var layer2: Polygon2D = $Layer2
@onready var layer3: Polygon2D = $Layer3
@onready var layer4: Polygon2D = $Layer4

var segment_width: float = 0.0

# Heights for each layer
var layer1_heights: Array[float] = []
var layer2_heights: Array[float] = []
var layer3_heights: Array[float] = []
var layer4_heights: Array[float] = []

# Camera tracking
var camera: Camera2D = null
var last_camera_x: float = 0.0
var start_x: float = 0.0  # Track how much we've shifted


func _ready() -> void:
	segment_width = total_width / segment_count
	_generate_all_heights()
	_draw_all_layers()
	
	# Find camera
	await get_tree().process_frame
	camera = get_viewport().get_camera_2d()
	if camera:
		last_camera_x = camera.global_position.x
		start_x = global_position.x


func _physics_process(_delta: float) -> void:
	_update_with_camera()


func _generate_all_heights() -> void:
	layer1_heights = _generate_heights(layer1_base_height)
	layer2_heights = _generate_heights(layer2_base_height)
	layer3_heights = _generate_heights(layer3_base_height)
	layer4_heights = _generate_heights(layer4_base_height)


func _draw_all_layers() -> void:
	_draw_layer(layer1, layer1_heights, layer_colors[0])
	_draw_layer(layer2, layer2_heights, layer_colors[1])
	_draw_layer(layer3, layer3_heights, layer_colors[2])
	_draw_layer(layer4, layer4_heights, layer_colors[3])


func _draw_layer(polygon: Polygon2D, heights: Array[float], color: Color) -> void:
	if not polygon or heights.size() == 0:
		return
	
	var points: PackedVector2Array = PackedVector2Array()
	
	# Top edge (irregular surface)
	for i in range(heights.size()):
		var x = i * segment_width
		var y = -heights[i]
		points.append(Vector2(x, y))
	
	# Bottom edge (flat)
	var max_depth = layer1_base_height + height_variance + 100.0
	points.append(Vector2(total_width, max_depth))
	points.append(Vector2(0, max_depth))
	
	polygon.polygon = points
	polygon.color = color


func _generate_heights(base_height: float) -> Array[float]:
	var heights: Array[float] = []
	
	# Generate random heights
	for i in range(segment_count + 1):
		var height = base_height + randf_range(-height_variance, height_variance)
		heights.append(height)
	
	# Smooth passes
	for _pass in range(3):
		var smoothed: Array[float] = []
		for i in range(heights.size()):
			if i == 0 or i == heights.size() - 1:
				smoothed.append(heights[i])
			else:
				var avg = (heights[i - 1] * 0.25) + (heights[i] * 0.5) + (heights[i + 1] * 0.25)
				smoothed.append(lerp(heights[i], avg, smoothness))
		heights = smoothed
	
	return heights


func _update_with_camera() -> void:
	if not camera:
		camera = get_viewport().get_camera_2d()
		if camera:
			last_camera_x = camera.global_position.x
			start_x = global_position.x
		return
	
	var current_camera_x = camera.global_position.x
	var camera_delta = current_camera_x - last_camera_x
	
	# Only process if camera moved right by one segment
	if camera_delta < segment_width:
		return
	
	last_camera_x = current_camera_x
	
	# Move the whole node to the right by one segment (keeps visuals stable)
	global_position.x += segment_width
	
	# Cycle points from left to right for each layer
	_cycle_layer_heights(layer1_heights, layer1_base_height)
	_cycle_layer_heights(layer2_heights, layer2_base_height)
	_cycle_layer_heights(layer3_heights, layer3_base_height)
	_cycle_layer_heights(layer4_heights, layer4_base_height)
	
	_draw_all_layers()


func _cycle_layer_heights(heights: Array[float], base_height: float) -> void:
	# Remove first point and add new one at end
	heights.pop_front()
	var new_height = base_height + randf_range(-height_variance, height_variance)
	# Smooth with neighbor
	if heights.size() > 0:
		new_height = lerp(new_height, heights[heights.size() - 1], smoothness * 0.5)
	heights.append(new_height)


## Regenerate all layers with new random heights
func regenerate() -> void:
	_generate_all_heights()
	_draw_all_layers()
