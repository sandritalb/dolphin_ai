extends Node2D

@onready var dolphin = $Dolphin
@onready var websocket := $WebSocketClient

var next_obstacle_distance := 0
var next_obstacle_y := 0

func _ready():
	websocket.connect("data_received", Callable(self, "_on_data_received"))

func _physics_process(delta):
	# enviar observación a Python
	var obs = get_observation()
	websocket.send(JSON.stringify(obs))

func get_observation():
	# obtener próximo obstáculo
	var obstacle = get_next_obstacle()

	if obstacle:
		next_obstacle_distance = obstacle.position.x - dolphin.position.x
		next_obstacle_y = obstacle.position.y
	else:
		next_obstacle_distance = 300
		next_obstacle_y = 0

	return {
		"dolphin_y": dolphin.position.y,
		"vel_y": dolphin.velocity.y,
		"dist": next_obstacle_distance,
		"ob_y": next_obstacle_y
	}

func get_next_obstacle():
	for child in get_children():
		if "Obstacle" in child.name:
			return child
	return null

func _on_data_received(data):
	var action = int(data)
	dolphin.apply_action(action)
