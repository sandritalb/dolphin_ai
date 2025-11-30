import gym
import numpy as np
import websocket
import json
import time

class DolphinEnv(gym.Env):
    def __init__(self):
        super().__init__()

        # acciones: 0 nada, 1 arriba, 2 abajo
        self.action_space = gym.spaces.Discrete(3)

        # observaciones
        self.observation_space = gym.spaces.Box(
            low=np.array([0, -500, 0, -200], dtype=np.float32),
            high=np.array([600, 500, 500, 200], dtype=np.float32)
        )

        self.ws = websocket.WebSocket()
        self.ws.connect("ws://localhost:8080")

    def reset(self):
        return np.zeros(4, dtype=np.float32)

    def step(self, action):
        # enviar acción a Godot
        self.ws.send(str(action))

        # recibir observación
        data = json.loads(self.ws.recv())

        obs = np.array([
            data["dolphin_y"],
            data["vel_y"],
            data["dist"],
            data["ob_y"]
        ], dtype=np.float32)

        # recompensa: sobrevivir = +1
        reward = 1.0

        # si se acerca demasiado al obstáculo, penalizar
        if data["dist"] < 0:
            reward = -50
            done = True
        else:
            done = False

        return obs, reward, done, {}
