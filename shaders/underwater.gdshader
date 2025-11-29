shader_type canvas_item;

// Ondulation parameters
uniform float wave_amplitude : hint_range(0.0, 20.0) = 3.0;
uniform float wave_frequency : hint_range(0.0, 10.0) = 2.0;
uniform float wave_speed : hint_range(0.0, 5.0) = 1.5;

// Color tint parameters
uniform vec4 water_tint : source_color = vec4(0.4, 0.7, 1.0, 1.0);
uniform float tint_strength : hint_range(0.0, 1.0) = 0.25;

// Color pulsing
uniform float color_pulse_speed : hint_range(0.0, 3.0) = 0.5;
uniform float color_pulse_amount : hint_range(0.0, 0.5) = 0.1;

void fragment() {
	// Calculate ondulation offset
	float wave_offset_x = sin(UV.y * wave_frequency * 10.0 + TIME * wave_speed) * wave_amplitude / 100.0;
	float wave_offset_y = cos(UV.x * wave_frequency * 8.0 + TIME * wave_speed * 0.8) * wave_amplitude * 0.5 / 100.0;
	
	// Apply distorted UV
	vec2 distorted_uv = UV + vec2(wave_offset_x, wave_offset_y);
	
	// Sample the texture with distorted coordinates
	vec4 tex_color = texture(TEXTURE, distorted_uv);
	
	// Calculate pulsing tint intensity
	float pulse = sin(TIME * color_pulse_speed) * color_pulse_amount;
	float current_tint = tint_strength + pulse;
	
	// Apply underwater color tint (mix original with water color)
	vec3 tinted_color = mix(tex_color.rgb, tex_color.rgb * water_tint.rgb, current_tint);
	
	// Slight brightness variation for underwater caustics effect
	float caustic = sin(UV.x * 20.0 + TIME) * cos(UV.y * 15.0 + TIME * 0.7) * 0.05;
	tinted_color += caustic;
	
	COLOR = vec4(tinted_color, tex_color.a);
}
