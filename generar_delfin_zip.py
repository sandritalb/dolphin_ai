import os, zipfile, textwrap, urllib.request

# --- Configuración ---
project_name = "DolphinAI_Godot44"
base_dir = os.path.join(os.getcwd(), project_name)
dirs = [
    f"{base_dir}/scripts",
    f"{base_dir}/assets"
]

# URLs de sprites pixel-art libres
sprites = {
    "dolphin.png": "https://png.pngtree.com/png-vector/20250922/ourmid/pngtree-cute-dolphin-pixel-art-jumping-over-retro-waves-png-image_17538722.webp",
    "wave.png": "https://img.favpng.com/3/5/24/pixel-art-wave-png-favpng-y7yedfwrUv3hV9Z4vgM9VDmpQ.jpg",
    "background.png": "https://i.ytimg.com/vi/Yd17qtZrG14/hq720.jpg"
}

# --- Crear estructura ---
for d in dirs:
    os.makedirs(d, exist_ok=True)

# --- Descargar sprites ---
for name, url in sprites.items():
    path = os.path.join(base_dir, "assets", name)
    try:
        urllib.request.urlretrieve(url, path)
        print(f"Descargado: {name}")
    except:
        with open(path, "wb") as f:
            f.write(b"")  # placeholder
        print(f"No se pudo descargar {name}, creado placeholder.")

# --- Crear scripts .gd ---
dolphin_gd = textwrap.dedent("""\
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
""")

wave_gd = textwrap.dedent("""\
    extends Area2D
    @export var speed: float = 250.0

    func _physics_process(delta):
        position.x -= speed * delta
        if position.x < -100:
            queue_free()
""")

game_manager_gd = textwrap.dedent("""\
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
""")

# Guardar scripts
with open(f"{base_dir}/scripts/Dolphin.gd", "w") as f: f.write(dolphin_gd)
with open(f"{base_dir}/scripts/Wave.gd", "w") as f: f.write(wave_gd)
with open(f"{base_dir}/scripts/GameManager.gd", "w") as f: f.write(game_manager_gd)

# --- Crear escenas básicas ---
main_tscn = textwrap.dedent("""\
    [gd_scene format=3]
    [node name="Main" type="Node2D"]
    [node name="GameManager" type="Node2D" parent="."]
    script = ExtResource("res://scripts/GameManager.gd")
    [node name="Dolphin" parent="." instance=ExtResource("res://Dolphin.tscn")]
    [node name="Timer" type="Timer" parent="."]
""")

dolphin_tscn = textwrap.dedent("""\
    [gd_scene format=3]
    [node name="Dolphin" type="CharacterBody2D"]
    script = ExtResource("res://scripts/Dolphin.gd")
    [node name="Sprite2D" type="Sprite2D" parent="."]
    texture = ExtResource("res://assets/dolphin.png")
""")

wave_tscn = textwrap.dedent("""\
    [gd_scene format=3]
    [node name="Wave" type="Area2D"]
    script = ExtResource("res://scripts/Wave.gd")
    [node name="Sprite2D" type="Sprite2D" parent="."]
    texture = ExtResource("res://assets/wave.png")
""")

with open(f"{base_dir}/main.tscn", "w") as f: f.write(main_tscn)
with open(f"{base_dir}/Dolphin.tscn", "w") as f: f.write(dolphin_tscn)
with open(f"{base_dir}/Wave.tscn", "w") as f: f.write(wave_tscn)

# --- Crear configuración mínima para HTML5 ---
project_godot = textwrap.dedent("""\
    [application]
    config/name="Dolphin AI"
    run/main_scene="res://main.tscn"
    config/icon="res://assets/dolphin.png"
    [rendering]
    renderer/rendering_method="forward_plus"
""")
with open(f"{base_dir}/project.godot", "w") as f: f.write(project_godot)

# --- Crear ZIP ---
zip_name = f"{project_name}.zip"
with zipfile.ZipFile(zip_name, 'w', zipfile.ZIP_DEFLATED) as zipf:
    for root, _, files in os.walk(base_dir):
        for file in files:
            full_path = os.path.join(root, file)
            zipf.write(full_path, os.path.relpath(full_path, os.getcwd()))

print(f"\n✅ Proyecto generado: {zip_name}")
print("Importa este ZIP en Godot 4.4 y exporta a Web (HTML5).")
