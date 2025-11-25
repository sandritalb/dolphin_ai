extends Node2D


# Signals
signal item_entered(body: Node2D)

# spring physics variables
var velocity = 0
var force = 0
var height = 0 #position.y

var target_height = 0 #position.y + 80

# # Stiffness constant
# var k = 0.015
# # Damping constant
# var d = 0.03

var motion_factor = 0.006



func _ready() -> void:
	var area_2d = get_node("Area2D")
	area_2d.body_entered.connect(_on_body_entered)
	area_2d.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	print("Body entered: ", body.name)
	if body is RigidBody2D:
		var velocity_y = body.linear_velocity.y
		# Apply enter effect only when body is moving down (positive velocity_y)
		if velocity_y > 0:
			splash(velocity_y)
	elif body is CharacterBody2D:
		var velocity_y = body.velocity.y
		# Apply enter effect only when body is moving down (positive velocity_y)
		if velocity_y > 0:
			splash(velocity_y)
	item_entered.emit(body)

func _on_body_exited(body: Node2D) -> void:
	print("Body exited: ", body.name)
	if body is RigidBody2D:
		var velocity_y = body.linear_velocity.y
		# Apply exit effect only when body is moving up (negative velocity_y)
		if velocity_y < 0:
			splash(velocity_y)
	elif body is CharacterBody2D:
		var velocity_y = body.velocity.y
		# Apply exit effect only when body is moving up (negative velocity_y)
		if velocity_y < 0:
			splash(velocity_y)
	item_entered.emit(body)

func water_update(spring_constant: float, damping: float) -> void:
	height = position.y
	var x = height - target_height

	var loss = -damping * velocity

	# hook's law: F = -k * x
	force = -spring_constant * x + loss 

	velocity += force
	position.y += velocity

func initialize(x_pos: float, motion_factor_param: float = 0.006) -> void:
	target_height = position.y
	height = position.y
	position.x = x_pos
	velocity = 0
	force = 0
	motion_factor = motion_factor_param


func splash(intensity: float) -> void:
	velocity += intensity * motion_factor