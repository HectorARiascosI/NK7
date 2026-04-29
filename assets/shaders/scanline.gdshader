// Shader de scanlines para efecto CRT/pixel art en UI
shader_type canvas_item;

uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.15;
uniform float scanline_count : hint_range(50.0, 500.0) = 200.0;
uniform float noise_intensity : hint_range(0.0, 0.1) = 0.02;
uniform float time_speed : hint_range(0.0, 5.0) = 1.0;
uniform vec4 tint_color : source_color = vec4(0.0, 0.8, 1.0, 0.05);

float rand(vec2 co) {
	return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	
	// Scanlines
	float scanline = sin(UV.y * scanline_count * 3.14159) * 0.5 + 0.5;
	scanline = pow(scanline, 0.5);
	color.rgb -= scanline_intensity * (1.0 - scanline);
	
	// Ruido sutil
	float noise = rand(UV + vec2(TIME * time_speed * 0.1, 0.0)) * noise_intensity;
	color.rgb += noise;
	
	// Tinte de color
	color.rgb = mix(color.rgb, tint_color.rgb, tint_color.a);
	
	COLOR = color;
}
