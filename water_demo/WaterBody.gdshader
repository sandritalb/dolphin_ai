shader_type canvas_item;

uniform vec4 tint : hint_color;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec4 color = texture(SCREEN_TEXTURE, SCREEN_UV);
	color = mix(color, tint, 0.4);
	color = mix(vec(0.5),color, 1.4);
	COLOR = color;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
