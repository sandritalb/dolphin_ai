import asyncio
import websockets
import json

clients = set()

async def handler(websocket):
    print("Godot conectado!")
    clients.add(websocket)

    try:
        async for message in websocket:
            try:
                data = json.loads(message)
                print(f"📨 Recibido desde Godot: {data}")

                # Recibimos OBSERVACIÓN desde Godot (complete observation dict)
                observation = data

                # Aquí decides la acción (0,1,2…) o envías lo que quieras
                action = 0  # por ahora fijo, luego pondremos la IA

                # Enviar acción de vuelta a Godot
                response = json.dumps({"action": action})
                await websocket.send(response)
                print(f"✅ Acción enviada: {response}")
            except json.JSONDecodeError as e:
                print(f"❌ Error al parsear JSON: {e}")
                print(f"   Mensaje recibido: {message}")
            except Exception as e:
                print(f"❌ Error procesando mensaje: {e}")
                raise
    except Exception as e:
        print(f"❌ Godot desconectado: {e}")
    finally:
        clients.discard(websocket)
        print("Godot removido de clientes")

async def main():
    print("Servidor WebSocket escuchando en ws://localhost:8765")
    async with websockets.serve(handler, "localhost", 8765):
        await asyncio.Future()  # para mantenerlo vivo

asyncio.run(main())
