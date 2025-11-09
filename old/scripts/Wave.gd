# extends Area2D

# @export var speed: float = 200.0
# @export var wave_height: float = 100.0

# var collision_shape: CollisionShape2D
# var visual_wave: Polygon2D

# func _ready():
# 	# Add to waves group for detection
# 	add_to_group("waves")
	
# 	collision_shape = $CollisionShape2D
# 	visual_wave = $VisualWave
	
# 	# Update collision shape based on height
# 	var shape = RectangleShape2D.new()
# 	shape.size = Vector2(80, wave_height)
# 	collision_shape.shape = shape
	
# 	# Create wave visual (triangle/wave shape)
# 	_create_wave_visual()
	
# 	# Connect collision
# 	body_entered.connect(_on_body_entered)

# func _create_wave_visual():
# 	var width = 80.0
# 	var height = wave_height
	
# 	# Create a wave-like polygon
# 	var points = PackedVector2Array([
# 		Vector2(-width/2, height/2),      # Bottom left
# 		Vector2(-width/3, -height/2),     # Top left peak
# 		Vector2(0, height/4),              # Middle dip
# 		Vector2(width/3, -height/2),      # Top right peak
# 		Vector2(width/2, height/2)        # Bottom right
# 	])
	
# 	visual_wave.polygon = points
	
# 	# Add a bit of white foam on top
# 	visual_wave.color = Color(0.2, 0.5, 0.8, 0.9)

# func _physics_process(delta):
# 	position.x -= speed * delta
	
# 	# Remove when off screen
# 	if position.x < -100:
# 		queue_free()

# func _on_body_entered(body):
# 	if body.name == "Dolphin":
# 		print("Dolphin hit wave!")
# 		# Game over logic here
# 		get_tree().reload_current_scene()
