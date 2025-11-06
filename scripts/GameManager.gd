extends Node2D

var wave_scene = preload("res://Wave.tscn")
var wave_spawn_timer = 0.0
var wave_spawn_interval = 2.0
var min_wave_interval = 1.5
var max_wave_interval = 3.0
var game_speed = 1.0
var score = 0

@onready var dolphin = get_parent().get_node("Dolphin")

func _ready():
	randomize()
	_schedule_next_wave()

func _process(delta):
	wave_spawn_timer -= delta
	
	if wave_spawn_timer <= 0:
		_spawn_wave()
		_schedule_next_wave()
	
	# Increase difficulty over time
	game_speed = min(2.0, 1.0 + score * 0.001)

func _schedule_next_wave():
	wave_spawn_interval = randf_range(min_wave_interval, max_wave_interval) / game_speed
	wave_spawn_timer = wave_spawn_interval

func _spawn_wave():
	var wave = wave_scene.instantiate()
	
	# Random wave height: small (50-100), medium (100-150), large (150-200)
	var wave_height = randf_range(60, 180)
	var base_y = 400  # Sea level
	
	wave.position = Vector2(1200, base_y - wave_height / 2)
	wave.wave_height = wave_height
	wave.speed = 200.0 * game_speed
	
	get_parent().add_child(wave)
	score += 1

func _input(event):
	if event.is_action_pressed("toggle_ai"):
		if dolphin:
			dolphin.auto_play = !dolphin.auto_play
			print("AI Mode: ", dolphin.auto_play)
