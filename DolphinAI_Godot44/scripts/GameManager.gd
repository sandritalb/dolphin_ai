extends Node2D
@onready var dolphin = $Dolphin
@onready var timer = $Timer

func _ready():
    timer.start()

func _on_Timer_timeout():
    var wave_scene = preload("res://Wave.tscn")
    var w = wave_scene.instantiate()
    w.position = Vector2(800, 380)
    add_child(w)

func _input(event):
    if event.is_action_pressed("toggle_ai"):
        dolphin.auto_play = !dolphin.auto_play
        print("Modo IA:", dolphin.auto_play)
