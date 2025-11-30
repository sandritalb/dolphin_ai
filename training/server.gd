extends WebSocketMultiplayerPeer

func start():
	create_server(8080)
	print("Servidor WebSocket listo en ws://localhost:8080")
================================================================================

extends Node

var ws := WebSocketPeer.new()
var connected := false
var action := 0

func _ready():
    print("Conectando a Python...")
    var err = ws.connect_to_url("ws://localhost:8765")
    if err != OK:
        print("Error al conectar:", err)

func _process(delta):
    if ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
        connected = true
        
        # 1. ENVIAR OBSERVACIÓN A PYTHON
        var obs = {
            "obs": [
                $"../Dolphin".position.y,
                $"../Dolphin".velocity.y,
                $"..".distance_to_next_obstacle,
                $"..".next_obstacle_y
            ]
        }
        ws.send_text(JSON.stringify(obs))

        # 2. RECIBIR ACCIÓN DE PYTHON
        while ws.get_available_packet_count() > 0:
            var msg = ws.get_packet().get_string_from_utf8()
            var data = JSON.parse_string(msg)
            if data:
                action = data["action"]
                $"../Dolphin".apply_action(action)

    ws.poll()
# ws.poll() debe llamarse en _process o _physics_process, sino no funciona.