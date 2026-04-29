// Shader de borde neón para paneles y botones
shader_type canvas_item;

uniform vec4 border_color : source_color = vec4(0.0, 0.8, 1.0, 1.0);
uniform float border_width : hint_range(1.0, 10.0) = 2.0;
uniform float glow_intensity : hint_range(0.0, 3.0) = 1.5;
uniform float pulse_speed : hint_range(0.0, 5.0) = 1.5;
uniform vec4 bg_color : source_color = vec4(0.05, 0.08, 0.15, 0.92);

void fragment() {
	vec2 uv = UV;
	vec2 size = 1.0 / TEXTURE_PIXEL_SIZE;
	
	// Pulso de brillo
	float pulse = sin(TIME * pulse_speed) * 0.3 + 0.7;
	
	// Borde
	float bw = border_width / min(size.x, size.y);
	bool is_border = (uv.x < bw || uv.x > 1.0 - bw || uv.y < bw || uv.y > 1.0 - bw);
	
	vec4 color = bg_color;
	
	if (is_border) {
		color = border_color * pulse * glow_intensity;
		color.a = 1.0;
	}
	
	COLOR = color;
}
