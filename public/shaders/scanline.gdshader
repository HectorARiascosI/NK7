shader_type canvas_item;
// NK-7 Scanline shader — CRT monitor effect for UI panels

uniform float line_density : hint_range(100.0, 800.0) = 300.0;
uniform float line_opacity : hint_range(0.0, 0.5) = 0.12;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.25;

void fragment() {
	vec4 base = texture(TEXTURE, UV);

	// Horizontal scanlines
	float line = mod(UV.y * line_density, 2.0);
	float scanline = step(1.0, line) * line_opacity;

	// Subtle vignette
	vec2 center = UV - 0.5;
	float vignette = 1.0 - dot(center, center) * vignette_strength * 2.0;

	COLOR = vec4(base.rgb * vignette - scanline, base.a);
}
