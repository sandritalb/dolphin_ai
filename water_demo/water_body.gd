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


func _ready() -> void:
	water_border.width = border_thickness

	for i in range(spring_number):
		var w = water_pring.instantiate()
		var x_pos = i * distance_between_springs
		w.initialize(x_pos)
		add_child(w)
		springs.append(w)
	splash(2, 5)
	

func _physics_process(_delta: float) -> void:
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
	

func splash(index: int, velocity: float) -> void:
	if index >= 0 and index < springs.size():
		springs[index].velocity += velocity

	# for i in range(springs.size()):
	#     if i > 0:
	#         springs[i - 1].height += left_deltas[i]
	#     if i < springs.size() - 1:
	#         springs[i + 1].height += right_deltas[i]


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
