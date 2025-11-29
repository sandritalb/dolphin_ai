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


func _ready() -> void:
	segment_width = total_width / segment_count
	_draw_all_layers()


func _draw_all_layers() -> void:
	_draw_layer(layer1, layer1_base_height, layer_colors[0])
	_draw_layer(layer2, layer2_base_height, layer_colors[1])
	_draw_layer(layer3, layer3_base_height, layer_colors[2])
	_draw_layer(layer4, layer4_base_height, layer_colors[3])


func _draw_layer(polygon: Polygon2D, base_height: float, color: Color) -> void:
	if not polygon:
		return
	
	var heights = _generate_heights(base_height)
	var points: PackedVector2Array = PackedVector2Array()
	
	# Top edge (irregular surface)
	for i in range(heights.size()):
		var x = i * segment_width
		var y = -heights[i]
		points.append(Vector2(x, y))
	
	# Bottom edge (flat)
	var max_depth = layer4_base_height + height_variance + 100.0
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


## Regenerate all layers with new random heights
func regenerate() -> void:
	_draw_all_layers()
