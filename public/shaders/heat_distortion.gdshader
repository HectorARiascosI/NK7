// Heat / radiation distortion — Godot 4
// Aplica sobre un ColorRect a pantalla completa ENCIMA del fondo
// Usa hint_screen_texture (Godot 4 copia el buffer automáticamente)
shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float strength    : hint_range(0.0, 0.02)  = 0.0045;
uniform float speed       : hint_range(0.1, 5.0)   = 1.15;
uniform float wave_scale  : hint_range(1.0, 20.0)  = 5.8;
// El calor es más intenso en la parte inferior (sube desde el suelo)
uniform float heat_rise   : hint_range(0.0, 3.0)   = 1.2;

void fragment() {
	float t = TIME * speed;

	// Dos capas de ondas para turbulencia orgánica
	float wx = sin(UV.y * wave_scale * 2.9 + t * 1.3)
			 + sin(UV.y * wave_scale * 1.5 + t * 0.85) * 0.45;
	float wy = cos(UV.x * wave_scale * 2.6 + t * 1.05)
			 + cos(UV.x * wave_scale * 1.2 + t * 0.65) * 0.45;

	// Máscara: más fuerte abajo, casi nulo arriba
	float heat_mask = pow(UV.y, heat_rise);

	vec2 distorted_uv = SCREEN_UV + vec2(wx, wy) * strength * heat_mask;

	COLOR = textureLod(screen_texture, distorted_uv, 0.0);
}
