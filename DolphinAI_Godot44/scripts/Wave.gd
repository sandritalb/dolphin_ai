extends Area2D
@export var speed: float = 250.0

func _physics_process(delta):
    position.x -= speed * delta
    if position.x < -100:
        queue_free()
