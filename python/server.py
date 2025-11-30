import asyncio
import websockets
import json

clients = set()

async def handler(websocket):
    print("Godot conectado!")
    clients.add(websocket)

    try:
        async for message in websocket:
            data = json.loads(message)

            # Recibimos OBSERVACIÓN desde Godot
            observation = data["obs"]

            # Aquí decides la acción (0,1,2…) o envías lo que quieras
            action = 0  # por ahora fijo, luego pondremos la IA

            # Enviar acción de vuelta a Godot
            await websocket.send(json.dumps({"action": action}))
    except:
        print("Godot desconectado")
    finally:
        clients.remove(websocket)

async def main():
    print("Servidor WebSocket escuchando en ws://localhost:8765")
    async with websockets.serve(handler, "localhost", 8765):
        await asyncio.Future()  # para mantenerlo vivo

asyncio.run(main())
