extends CharacterBody2D

@export var gravity: float = 600.0
@export var jump_force: float = -350.0
@export var auto_play: bool = false
@export var animation_speed: float = 0.15

var velocity_y = 0.0
var memory = []
var is_jumping = false
var animation_timer: float = 0.0
var current_frame: int = 0

func _physics_process(delta):
    # Update animation
    animation_timer += delta
    if animation_timer >= animation_speed:
        animation_timer = 0.0
        current_frame = (current_frame + 1) % 6
        $Sprite2D.frame = current_frame
    
    # Aplicar gravedad
    velocity_y += gravity * delta
    
    # Limitar el delfín en el rango visible
    if global_position.y > 550:  # Límite inferior
        global_position.y = 550
        velocity_y = 0
        is_jumping = false
    
    if global_position.y < 50:  # Límite superior
        global_position.y = 50
        velocity_y = 0
    
    # Revisar si está en el suelo
    var on_floor = global_position.y >= 550
    
    if auto_play and on_floor:
        _ai_behavior()
    
    velocity = Vector2(0, velocity_y)
    move_and_slide()

func _input(event):
    if not auto_play and event.is_action_pressed("ui_accept"):
        if global_position.y >= 550:  # Solo saltar si está en el suelo
            _jump()
            get_tree().root.set_input_as_handled()

func _ai_behavior():
    for sample in memory:
        var pos_y = sample[0]
        var dist = sample[2]
        if abs(pos_y - global_position.y) < 40 and dist < 200:
            if global_position.y >= 550:
                _jump()
                break

func _jump():
    velocity_y = jump_force
    is_jumping = true
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
