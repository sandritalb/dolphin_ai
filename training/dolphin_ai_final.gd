extends Node

var model : TFLiteModel
var interpreter : TFLiteInterpreter

func _ready():
    model = TFLiteModel.new()
    model.load_model("res://models/dolphin_model.tflite")

    interpreter = TFLiteInterpreter.new()
    interpreter.load_model(model)
    interpreter.allocate_tensors()

func choose_action(obs: Array) -> int:
    var input_tensor := interpreter.get_input_tensor(0)
    input_tensor.set_data(obs)

    interpreter.invoke()

    var output_tensor := interpreter.get_output_tensor(0)
    var output = output_tensor.get_data()

    # El modelo devuelve logits → elegir acción con mayor probabilidad
    var best = 0
    var best_val = -99999.0
    for i in range(output.size()):
        if output[i] > best_val:
            best = i
            best_val = output[i]

    return best
