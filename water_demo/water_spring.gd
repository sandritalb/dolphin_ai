extends Node2D


# spring physics variables
var velocity = 0
var force = 0
var height = 0 #position.y

var target_height = 0 #position.y + 80

# # Stiffness constant
# var k = 0.015
# # Damping constant
# var d = 0.03


func water_update(spring_constant: float, damping: float) -> void:
    height = position.y
    var x = height - target_height

    var loss = -damping * velocity

    # hook's law: F = -k * x
    force = -spring_constant * x + loss 

    velocity += force
    position.y += velocity

func initialize(x_pos: float) -> void:
    target_height = position.y
    height = position.y
    position.x = x_pos
    velocity = 0
    force = 0