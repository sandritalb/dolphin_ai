extends CharacterBody2D

@export var speed := 200.0
var gravity := 400.0

# Acciones: 0 = nada, 1 = subir, 2 = bajar
func apply_action(action):
	if action == 1:
		velocity.y = -speed
	elif action == 2:
		velocity.y = speed

func _physics_process(delta):
	# Aplicar gravedad suave
	velocity.y = lerp(velocity.y, 0.0, delta * 2)

	move_and_slide()
