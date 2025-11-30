import torch
from stable_baselines3 import PPO

model = PPO.load("dolphin_model.zip")

dummy_input = torch.zeros((1, 4))  # 4 = número de observaciones

torch.onnx.export(
    model.policy.mlp_extractor.policy_net,
    dummy_input,
    "policy.onnx",
    input_names=["obs"],
    output_names=["action_logits"],
    opset_version=11
)

python export_to_onnx.py --> policy.onnx
pip install onnx onnx-tf
onnx-tf convert -i policy.onnx -o tf_model
tf_model/saved_model.pb


import tensorflow as tf

converter = tf.lite.TFLiteConverter.from_saved_model("tf_model")
converter.optimizations = [tf.lite.Optimize.DEFAULT]

tflite_model = converter.convert()

with open("dolphin_model.tflite", "wb") as f:
    f.write(tflite_model)

python convert_to_tflite.py --> dolphin_model.tflite


