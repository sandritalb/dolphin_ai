extends Node2D

@onready var dolphin = $Dolphin
@onready var ai = $DolphinAI

func _physics_process(delta):
	var obs = get_observation()

	var action = ai.choose_action([
		obs["dolphin_y"],
		obs["vel_y"],
		obs["dist"],
		obs["ob_y"]
	])

	dolphin.apply_action(action)
