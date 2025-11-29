extends CanvasLayer

@export_range(0.0, 1.0) var bottom_anchor: float = 0.4  # Controla hasta dónde llega el degradado

func _ready():
	var gradient = Gradient.new()
	
	# Agregar los colores en el orden especificado
	var colors = [
		Color("163160"),
		Color("184b7b"),
		Color("1b5f8d"),
		Color("2077a4"),
		Color("3193bd"),
		Color("4ea5ca"),
		Color("8cc5e0")
	]
	
	# Configurar los puntos del degradado
	for i in range(colors.size()):
		var position = float(i) / (colors.size() - 1)
		gradient.add_point(position, colors[i])
	
	# Crear un ColorRect con el degradado (solo mitad superior)
	var color_rect = ColorRect.new()
	color_rect.anchor_left = 0
	color_rect.anchor_top = 0
	color_rect.anchor_right = 1
	color_rect.anchor_bottom = bottom_anchor  # Controlado por parámetro exportado
	color_rect.color = Color.WHITE
	
	# Crear un shader para el degradado suave
	var shader = Shader.new()
	shader.code = """
shader_type canvas_item;

void fragment() {
	// Degradado vertical suave de arriba hacia abajo
	float vertical_pos = UV.y;
	
	// Definir los colores
	vec3 color1 = vec3(0.086, 0.086, 0.376);  // 163160
	vec3 color2 = vec3(0.098, 0.294, 0.482);  // 184b7b
	vec3 color3 = vec3(0.106, 0.373, 0.553);  // 1b5f8d
	vec3 color4 = vec3(0.125, 0.467, 0.643);  // 2077a4
	vec3 color5 = vec3(0.196, 0.576, 0.741);  // 3193bd
	vec3 color6 = vec3(0.306, 0.647, 0.792);  // 4ea5ca
	vec3 color7 = vec3(0.549, 0.773, 0.878);  // 8cc5e0
	
	vec3 final_color;
	
	if (vertical_pos < 0.1667) {
		final_color = mix(color2, color2, vertical_pos / 0.1667); // i removed color1 to make a smoother gradient
	} else if (vertical_pos < 0.3334) {
		final_color = mix(color2, color3, (vertical_pos - 0.1667) / 0.1667);
	} else if (vertical_pos < 0.5) {
		final_color = mix(color3, color4, (vertical_pos - 0.3334) / 0.1666);
	} else if (vertical_pos < 0.6667) {
		final_color = mix(color4, color5, (vertical_pos - 0.5) / 0.1667);
	} else if (vertical_pos < 0.8334) {
		final_color = mix(color5, color6, (vertical_pos - 0.6667) / 0.1667);
	} else {
		final_color = mix(color6, color7, (vertical_pos - 0.8334) / 0.1666);
	}
	
	COLOR = vec4(final_color, 1.0);
}
"""
	
	var material = ShaderMaterial.new()
	material.shader = shader
	color_rect.material = material
	
	add_child(color_rect)
	move_child(color_rect, 0)
