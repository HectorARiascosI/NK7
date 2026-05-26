shader_type canvas_item;
// NK-7 Button perspective shader — trapezoidal distortion
// Simulates a button viewed from a slight angle

uniform float skew_amount : hint_range(-0.3, 0.3) = 0.08;
uniform float top_scale : hint_range(0.5, 1.0) = 0.82;

void vertex() {
	// Narrow the top edge to create perspective illusion
	float y_norm = UV.y;
	float scale = mix(top_scale, 1.0, y_norm);
	VERTEX.x *= scale;
	VERTEX.x += skew_amount * (1.0 - y_norm) * 100.0;
}

void fragment() {
	COLOR = texture(TEXTURE, UV);
}
