extends Node

@export var parallax_factor: float = 0.5  # How much background moves relative to camera (0-1)
@export var wave_sway_amount: float = 20.0  # How far left/right the waves move
@export var wave_sway_frequency: float = 1.5  # How fast the waves sway (cycles per second)

@onready var sea_sprite = $sea
@onready var waves_sprite = $waves
@onready var camera = get_parent().get_node("Camera2D")

var sea_base_pos: Vector2
var waves_base_pos: Vector2
var background_width: float
var last_camera_x: float = 0.0
var time_elapsed: float = 0.0

func _ready():
	# Get base positions
	sea_base_pos = sea_sprite.position
	waves_base_pos = waves_sprite.position
	
	# Calculate texture width based on scale
	if sea_sprite.texture:
		background_width = sea_sprite.texture.get_width() * sea_sprite.scale.x

func _process(delta):
	# time_elapsed += delta
	
	# # Follow camera with parallax effect
	# var camera_offset = camera.global_position.x - last_camera_x
	
	# # Move background based on camera movement (parallax factor makes it slower)
	# sea_sprite.position.x += camera_offset * parallax_factor
	
	# # Calculate smooth sway motion for waves
	# var sway_offset = sin(time_elapsed * wave_sway_frequency * PI * 2) * wave_sway_amount
	# waves_sprite.position.x = waves_base_pos.x + sway_offset + (camera_offset * parallax_factor)
	
	# # Seamless looping - reset when too far
	# if sea_sprite.position.x < sea_base_pos.x - background_width * 2:
	# 	sea_sprite.position.x += background_width * 2
	# elif sea_sprite.position.x > sea_base_pos.x + background_width * 2:
	# 	sea_sprite.position.x -= background_width * 2
	
	# if waves_sprite.position.x < waves_base_pos.x - background_width * 2:
	# 	waves_sprite.position.x += background_width * 2
	# elif waves_sprite.position.x > waves_base_pos.x + background_width * 2:
	# 	waves_sprite.position.x -= background_width * 2
	
	last_camera_x = camera.global_position.x

