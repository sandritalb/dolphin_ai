from stable_baselines3 import PPO
from dolphin_env import DolphinEnv

env = DolphinEnv()

model = PPO(
    "MlpPolicy",
    env,
    verbose=1,
    learning_rate=2.5e-4,
    n_steps=2048
)

model.learn(total_timesteps=300_000)
model.save("dolphin_model")
