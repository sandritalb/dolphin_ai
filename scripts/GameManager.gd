extends Node2D
@onready var dolphin = $Dolphin

var wave_scene = preload("res://Wave.tscn")
var wave_spawn_timer = 0.0
var wave_spawn_interval = 1.5

func _ready():
	# Asegurar que el delfín siempre está encima
	dolphin.z_index = 100

func _process(delta):
	wave_spawn_timer += delta
	if wave_spawn_timer >= wave_spawn_interval:
		_spawn_wave()
		wave_spawn_timer = 0.0

func _spawn_wave():
	var w = wave_scene.instantiate()
	w.position = Vector2(800, 380)
	w.z_index = 0  # Las olas atrás
	add_child(w)

func _input(event):
	if event.is_action_pressed("toggle_ai"):
		dolphin.auto_play = !dolphin.auto_play
		print("Modo IA:", dolphin.auto_play)
