extends Node
class_name SeaTextureGenerator

## Generate a procedural sea texture with waves
## Parameters:
##  - width: texture width in pixels
##  - height: texture height in pixels
##  - seed: noise seed for reproducibility
##  - wave_amplitude: height of waves (0.0 to 1.0)
##  - wave_frequency: frequency of wave pattern
##  - gradient_top: color at top of texture
##  - gradient_bottom: color at bottom of texture
static func generate_sea_texture(
	width: int = 800,
	height: int = 200,
	seed: int = 0,
	wave_amplitude: float = 0.15,
	wave_frequency: float = 0.03,
	gradient_top: Color = Color(0.2, 0.5, 0.8),
	gradient_bottom: Color = Color(0.0, 0.3, 0.6)
) -> ImageTexture:
	
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = wave_frequency
	noise.seed = seed
	
	var image = Image.create(width, height, false, Image.FORMAT_RGB8)
	
	for y in range(height):
		for x in range(width):
			# Get noise value for wave pattern
			var noise_val = noise.get_noise_2d(x, y)
			
			# Create wave displacement
			var wave_height = sin(x * 0.02 + y * 0.01) * wave_amplitude
			wave_height += noise_val * wave_amplitude
			
			# Gradient from top to bottom
			var gradient_factor = float(y) / float(height)
			var base_color = gradient_top.lerp(gradient_bottom, gradient_factor)
			
			# Add wave variation to color
			var color_variation = wave_height * 0.3
			var final_color = base_color + Color(color_variation, color_variation * 0.5, 0)
			final_color.a = 1.0
			
			image.set_pixel(x, y, final_color)
	
	return ImageTexture.create_from_image(image)


## Generate multiple wave texture variations for animation
static func generate_wave_frames(
	frame_count: int = 4,
	width: int = 800,
	height: int = 200,
	wave_amplitude: float = 0.2,
	wave_frequency: float = 0.03
) -> Array[ImageTexture]:
	
	var frames: Array[ImageTexture] = []
	
	for frame in range(frame_count):
		var noise = FastNoiseLite.new()
		noise.noise_type = FastNoiseLite.TYPE_PERLIN
		noise.frequency = wave_frequency
		noise.seed = frame
		
		var image = Image.create(width, height, false, Image.FORMAT_RGB8)
		
		for y in range(height):
			for x in range(width):
				var noise_val = noise.get_noise_2d(x + frame * 50, y)
				
				var wave_height = sin((x + frame * 50) * 0.02 + y * 0.01) * wave_amplitude
				wave_height += noise_val * wave_amplitude
				
				var gradient_factor = float(y) / float(height)
				var base_color = Color(0.2, 0.5, 0.8).lerp(Color(0.0, 0.3, 0.6), gradient_factor)
				
				var color_variation = wave_height * 0.3
				var final_color = base_color + Color(color_variation, color_variation * 0.5, 0)
				final_color.a = 1.0
				
				image.set_pixel(x, y, final_color)
		
		frames.append(ImageTexture.create_from_image(image))
	
	return frames


## Create a ShaderMaterial for animated procedural sea
static func create_sea_shader_material() -> ShaderMaterial:
	var shader = Shader.new()
	shader.code = """
shader_type canvas_item;

uniform float wave_speed : hint_range(0.0, 5.0) = 1.5;
uniform float wave_amplitude : hint_range(0.0, 0.5) = 0.15;
uniform float wave_frequency : hint_range(0.01, 0.2) = 0.05;
uniform vec3 color_shallow = vec3(0.2, 0.6, 0.9);
uniform vec3 color_deep = vec3(0.0, 0.3, 0.6);

void fragment() {
	vec2 uv = UV;
	
	// Add horizontal wave animation
	float wave_offset = sin(uv.x * wave_frequency * 6.28 + TIME * wave_speed) * wave_amplitude;
	wave_offset += sin(uv.x * wave_frequency * 3.14 + TIME * wave_speed * 0.7) * wave_amplitude * 0.5;
	
	// Vertical displacement for wave effect
	float wave_height = wave_offset * (1.0 - uv.y);
	
	// Create gradient with wave variation
	vec3 gradient = mix(color_shallow, color_deep, uv.y);
	
	// Add wave highlights
	float wave_light = max(wave_height * 0.5, 0.0);
	gradient += vec3(wave_light * 0.3);
	
	// Add subtle foam effect at wave peaks
	float foam = max(wave_height * 2.0, 0.0);
	gradient = mix(gradient, vec3(1.0), foam * 0.2);
	
	COLOR = vec4(gradient, 1.0);
}
"""
	
	var material = ShaderMaterial.new()
	material.shader = shader
	return material
