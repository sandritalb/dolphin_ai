extends CharacterBody2D

@export var gravity: float = 900.0
@export var jump_force: float = -450.0
@export var auto_play: bool = false

var velocity_y = 0.0
var memory = []

func _physics_process(delta):
    if not auto_play:
        _player_input()
    else:
        _ai_behavior()
    _apply_physics(delta)

func _player_input():
    if Input.is_action_just_pressed("ui_accept") and is_on_floor():
        _jump()

func _ai_behavior():
    for sample in memory:
        var pos_y = sample[0]
        var vel_y = sample[1]
        var dist = sample[2]
        if abs(pos_y - global_position.y) < 40 and dist < 200:
            if is_on_floor():
                _jump()
                break

func _apply_physics(delta):
    if not is_on_floor():
        velocity_y += gravity * delta
    else:
        if velocity_y > 0:
            velocity_y = 0
    velocity = Vector2(0, velocity_y)
    move_and_slide()

func _jump():
    velocity_y = jump_force
    if not auto_play:
        var dist = _get_wave_distance()
        memory.append([global_position.y, velocity_y, dist])
        if memory.size() > 50:
            memory.remove_at(0)

func _get_wave_distance() -> float:
    var nearest = INF
    for node in get_parent().get_children():
        if node is Area2D and node.name.begins_with("Wave"):
            var d = node.global_position.x - global_position.x
            if d > 0 and d < nearest:
                nearest = d
    return nearest
