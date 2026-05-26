shader_type canvas_item;
// NK-7 Neon border glow shader

uniform vec4 glow_color : source_color = vec4(0.0, 0.96, 1.0, 1.0);
uniform float glow_width : hint_range(0.0, 0.05) = 0.015;
uniform float glow_intensity : hint_range(0.0, 3.0) = 1.4;
uniform float pulse_speed : hint_range(0.0, 5.0) = 1.2;

void fragment() {
	vec4 base = texture(TEXTURE, UV);

	// Edge detection via UV proximity to border
	float edge_x = min(UV.x, 1.0 - UV.x);
	float edge_y = min(UV.y, 1.0 - UV.y);
	float edge = min(edge_x, edge_y);
	float border = smoothstep(0.0, glow_width, edge);

	// Pulse
	float pulse = 0.85 + 0.15 * sin(TIME * pulse_speed);
	float glow = (1.0 - border) * glow_intensity * pulse;

	COLOR = mix(base, vec4(glow_color.rgb, base.a), clamp(glow, 0.0, 1.0));
}
