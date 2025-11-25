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
var target_height = global_position.y
var bottom = target_height + depth

@onready var water_polygon = get_node("WaterPolygon")

@onready var water_border = get_node("WaterBorder")
@export var border_thickness = 4.0

@onready var water_particles = preload("res://water_demo/WaterParticlesDemo.tscn")
@export var splash_intensity = 5.0
@export var detection_area_radius = 50.0

var detection_areas = []
var items_in_water = {}
var particle_cooldown = {}
@export var particle_cooldown_time = 0.5  # Cooldown between particle spawns

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
	
	# Update cooldowns
	for spring_index in particle_cooldown.keys():
		particle_cooldown[spring_index] -= _delta
		if particle_cooldown[spring_index] <= 0:
			particle_cooldown.erase(spring_index)
	
	draw_water_body()
	draw_water_border()


func _update_springs_with_camera() -> void:
	if not camera:
		camera = get_viewport().get_camera_2d()
		if camera:
			last_camera_x = camera.global_position.x
		return
	
	var current_camera_x = camera.global_position.x
	var camera_delta = current_camera_x - last_camera_x
	
	# Only process if camera moved right significantly
	if camera_delta < distance_between_springs:
		return
	
	last_camera_x = current_camera_x
	
	# Take the first spring (leftmost) and move it to the end (rightmost)
	var first_spring = springs[0]
	var last_spring = springs[springs.size() - 1]
	
	# Move first spring to be after the last spring
	first_spring.position.x = last_spring.position.x + distance_between_springs
	first_spring.velocity = 0
	first_spring.height = first_spring.target_height
	first_spring.position.y = first_spring.target_height
	
	# Remove from front and add to back
	springs.pop_front()
	springs.push_back(first_spring)
	

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
		_play_water_particles(spring_index)


func _on_detection_area_exited(area: Area2D, spring_index: int) -> void:
	# Item exited water
	print("Area exited water:", area, "at spring index:", spring_index)
	if items_in_water.has(area):
		items_in_water.erase(area)
		splash(spring_index, splash_intensity)
		_play_water_particles(spring_index)


func _play_water_particles(spring_index: int) -> void:
	# Only play particles if cooldown has expired
	if not particle_cooldown.has(spring_index):
		if spring_index >= 0 and spring_index < springs.size():
			var particles = water_particles.instantiate()
			particles.global_position = springs[spring_index].global_position
			get_parent().add_child(particles)
			particle_cooldown[spring_index] = particle_cooldown_time


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
