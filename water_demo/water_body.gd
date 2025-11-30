extends Node2D


@export var k = 0.015
@export var d = 0.03
@export var spread = 0.0002

@export var spring_number = 20
@export var distance_between_springs = 32

@onready var water_pring = preload("res://water_demo/WaterSpring.tscn")

var springs = []
var passes = 8

@export var depth = 100.0
var target_height = 0.0
var bottom = 0.0

@onready var water_polygon = get_node("WaterPolygon")

@onready var water_border = get_node("WaterBorder")
@export var border_thickness = 4.0

# Water color
@export var water_color: Color = Color(0, 0.537, 0.839, 1)

@export var splash_intensity = 5.0
@export var detection_area_radius = 50.0

var detection_areas = []
var items_in_water = {}

# Wave generation
@export var wave_enabled = true
@export var wave_frequency = 0.5  # How often waves are generated
@export var wave_amplitude = 1.0  # Strength of the waves
var wave_timer = 0.0
var wave_spring_spacing = 2  # Apply waves every N springs

@export var water_motion_factor = 0.006

# Camera following - water moves with the camera
var camera: Camera2D = null
var last_camera_x: float = 0.0


func _ready() -> void:
	water_border.width = border_thickness
	_setup_water_gradient()
	
	# Initialize target_height and bottom based on actual global position
	target_height = global_position.y
	bottom = target_height + depth

	for i in range(spring_number):
		var w = water_pring.instantiate()
		var x_pos = i * distance_between_springs
		w.initialize(x_pos, water_motion_factor)
		add_child(w)
		springs.append(w)
	
	# Find the camera in the scene
	await get_tree().process_frame
	camera = get_viewport().get_camera_2d()
	if camera:
		last_camera_x = camera.global_position.x


func _physics_process(_delta: float) -> void:
	# Move water springs with the camera
	_update_springs_with_camera()
	
	# Generate waves constantly
	if wave_enabled:
		wave_timer -= _delta
		if wave_timer <= 0.0:
			wave_timer = wave_frequency
			_generate_waves()
	
	for spring in springs:
		spring.water_update(k, d)
	
	var left_deltas = []
	var right_deltas = []

	for i in range(springs.size()):
		left_deltas.append(0)
		right_deltas.append(0)

	for j in range(passes):
		for i in range(springs.size()):
			if i > 0:
				left_deltas[i] = spread * (springs[i].height - springs[i - 1].height)
				springs[i - 1].velocity += left_deltas[i]
			if i < springs.size() - 1:
				right_deltas[i] = spread * (springs[i].height - springs[i + 1].height)
				springs[i + 1].velocity += right_deltas[i]
	
	draw_water_body()
	draw_water_border()


func _update_springs_with_camera() -> void:
	if not camera:
		camera = get_viewport().get_camera_2d()
		if camera:
			last_camera_x = camera.global_position.x
		return
	
	var current_camera_x = camera.global_position.x
	
	# Get the global X position of the first spring
	var first_spring = springs[0]
	var first_spring_global_x = global_position.x + first_spring.position.x
	
	# Get viewport width to know when spring is off-screen
	var viewport_width = get_viewport().get_visible_rect().size.x
	var left_edge = current_camera_x - (viewport_width / 2) - (distance_between_springs * 5)
	
	# Only recycle when the first spring is off the left edge of the screen
	while first_spring_global_x < left_edge:
		var last_spring = springs[springs.size() - 1]
		
		# Move first spring to be after the last spring
		first_spring.position.x = last_spring.position.x + distance_between_springs
		first_spring.velocity = 0
		first_spring.height = first_spring.target_height
		first_spring.position.y = first_spring.target_height
		
		# Remove from front and add to back
		springs.pop_front()
		springs.push_back(first_spring)
		
		# Update for next iteration
		first_spring = springs[0]
		first_spring_global_x = global_position.x + first_spring.position.x
	

func splash(index: int, velocity: float) -> void:
	if index >= 0 and index < springs.size():
		springs[index].velocity += velocity



func _generate_waves() -> void:
	# Apply waves to random springs spaced out across the water
	for i in range(0, springs.size(), wave_spring_spacing):
		splash(i, randf_range(-wave_amplitude, wave_amplitude))


func _on_detection_area_entered(area: Area2D, spring_index: int) -> void:
	# Item entered water
	print("Area entered water:", area, "at spring index:", spring_index)
	if not items_in_water.has(area):
		items_in_water[area] = spring_index
		splash(spring_index, splash_intensity)


func _on_detection_area_exited(area: Area2D, spring_index: int) -> void:
	# Item exited water
	print("Area exited water:", area, "at spring index:", spring_index)
	if items_in_water.has(area):
		items_in_water.erase(area)
		splash(spring_index, splash_intensity)


func draw_water_body() -> void:
	# var surface_points = []
	# for i in range(springs.size()):
	#     surface_points.append(Vector2(springs[i].position))

	var curve = water_border.curve
	var points = Array(curve.get_baked_points())
	if points.size() == 0:
		return
	var water_polygon_points = points

	var first_index = 0
	var last_index = water_polygon_points.size() - 1
	water_polygon_points.append(Vector2(water_polygon_points[last_index].x, bottom))
	water_polygon_points.append(Vector2(water_polygon_points[first_index].x, bottom))
	water_polygon.polygon = PackedVector2Array(water_polygon_points)

func draw_water_border() -> void:
	var curve = Curve2D.new().duplicate()
	var border_points = []
	for i in range(springs.size()):
		border_points.append(Vector2(springs[i].position))
	for i in range(border_points.size()):
		curve.add_point(springs[i].position)
	water_border.curve = curve
	water_border.smooth(true)
	water_border.queue_redraw()


func _setup_water_gradient() -> void:
	var gradient = Gradient.new()
	gradient.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT  # Hard color changes
	
	# Clear default points
	gradient.remove_point(0)
	
	# Add colors from top to bottom (based on sea.png blues)
	gradient.add_point(0.0, Color("53aaa7"))
	gradient.add_point(0.08, Color("4a9f9f"))
	gradient.add_point(0.16, Color("409094"))
	gradient.add_point(0.24, Color("38848b"))
	gradient.add_point(0.32, Color("2f7380"))
	gradient.add_point(0.40, Color("266575"))
	gradient.add_point(0.48, Color("215a6d"))
	gradient.add_point(0.56, Color("205a6e"))
	gradient.add_point(0.64, Color("1f5a6d"))
	gradient.add_point(0.72, Color("1c5166"))
	gradient.add_point(0.84, Color("1a435d"))
	gradient.add_point(0.92, Color("173753"))
	
	var gradient_texture = GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.fill_from = Vector2(0, 0)
	gradient_texture.fill_to = Vector2(0, 1)  # Vertical gradient (top to bottom)
	gradient_texture.width = 1
	gradient_texture.height = depth
	
	water_polygon.texture = gradient_texture
	water_polygon.color = Color.WHITE  # White so texture shows properly
