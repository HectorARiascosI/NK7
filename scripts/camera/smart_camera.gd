extends Camera2D
class_name SmartCamera

## ═══════════════════════════════════════════════════════════════
## SmartCamera NK7 — Cámara 2D profesional para platformer
## ═══════════════════════════════════════════════════════════════
##
## Técnica: Focus Zone (Tiny Thor / Celeste / Hollow Knight)
## La cámara NO mueve el mundo. Sigue al jugador suavemente
## dentro de una zona de enfoque, con lookahead horizontal
## y suavizado independiente en X e Y.
##
## Principios clave:
##  - El viewport es FIJO. Solo la posición global de la cámara cambia.
##  - X: suavizado rápido con lookahead según dirección del jugador.
##  - Y: solo sigue cuando el jugador toca el suelo (no en cada salto).
##       Líneas de pánico para caídas largas.
##  - Límites duros: nunca muestra fuera del nivel.
## ═══════════════════════════════════════════════════════════════

# ── Configuración exportable ─────────────────────────────────────

@export_group("Focus Zone")
## Ancho de la zona muerta horizontal (px). La cámara no se mueve
## mientras el jugador esté dentro de este rango.
@export var focus_half_width  : float = 60.0
## Alto de la zona muerta vertical.
@export var focus_half_height : float = 40.0

@export_group("Suavizado")
## Velocidad de seguimiento horizontal (lerp factor por segundo).
@export var smooth_x : float = 8.0
## Velocidad de seguimiento vertical cuando el jugador está en suelo.
@export var smooth_y : float = 5.0
## Velocidad de seguimiento vertical en líneas de pánico.
@export var smooth_y_panic : float = 12.0

@export_group("Lookahead")
## Píxeles de anticipación horizontal según dirección del jugador.
@export var lookahead_px    : float = 80.0
## Velocidad de transición del lookahead.
@export var lookahead_speed : float = 4.0

@export_group("Líneas de Pánico")
## Distancia desde el centro de la cámara que activa seguimiento
## vertical urgente (caída libre / salto muy alto).
@export var panic_top    : float = 120.0
@export var panic_bottom : float = 100.0

@export_group("Límites del Nivel")
## Activa el clamp a los límites definidos en Camera2D.
@export var use_limits : bool = true

# ── Estado interno ───────────────────────────────────────────────

var _target      : CharacterBody2D = null
var _cam_pos     : Vector2         = Vector2.ZERO   # posición suavizada
var _lookahead   : float           = 0.0            # offset horizontal actual
var _last_facing : float           = 1.0            # 1 = derecha, -1 = izquierda
var _on_floor_y  : float           = 0.0            # última Y cuando estaba en suelo

# ════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ════════════════════════════════════════════════════════════════

func _ready() -> void:
	# La cámara es hija del jugador → su padre ES el target
	if get_parent() is CharacterBody2D:
		_target = get_parent() as CharacterBody2D

	# Desactivar el suavizado nativo de Godot — lo hacemos nosotros
	position_smoothing_enabled = false

	# Posición inicial = jugador
	if _target:
		_cam_pos = _target.global_position
		_on_floor_y = _cam_pos.y
	global_position = _cam_pos


# ════════════════════════════════════════════════════════════════
# PROCESO — se ejecuta DESPUÉS de la física (_physics_process)
# ════════════════════════════════════════════════════════════════

func _process(delta: float) -> void:
	if not _target:
		return

	var player_pos : Vector2 = _target.global_position
	var vel        : Vector2 = _target.velocity

	# ── 1. Lookahead horizontal ──────────────────────────────────
	# Detectar dirección del jugador
	if vel.x > 10.0:
		_last_facing = 1.0
	elif vel.x < -10.0:
		_last_facing = -1.0

	var target_lookahead : float = _last_facing * lookahead_px
	# Solo aplicar lookahead si el jugador se está moviendo
	if abs(vel.x) < 5.0:
		target_lookahead = 0.0

	_lookahead = lerp(_lookahead, target_lookahead, delta * lookahead_speed)

	# ── 2. Objetivo de la cámara ─────────────────────────────────
	var target_x : float = player_pos.x + _lookahead
	var target_y : float = _cam_pos.y   # por defecto no mover Y

	# ── 3. Movimiento horizontal (siempre suave) ─────────────────
	# Focus zone: solo mover si el jugador sale de la zona muerta
	var diff_x : float = player_pos.x - _cam_pos.x
	if abs(diff_x) > focus_half_width:
		# El jugador salió de la zona → seguir con lookahead
		_cam_pos.x = lerp(_cam_pos.x, target_x, delta * smooth_x)
	else:
		# Dentro de la zona → suavizar hacia el lookahead sin urgencia
		_cam_pos.x = lerp(_cam_pos.x, target_x, delta * (smooth_x * 0.3))

	# ── 4. Movimiento vertical ───────────────────────────────────
	var diff_y : float = player_pos.y - _cam_pos.y

	if _target.is_on_floor():
		# En suelo: actualizar referencia Y y seguir suavemente
		_on_floor_y = player_pos.y
		if abs(diff_y) > focus_half_height:
			target_y = player_pos.y
			_cam_pos.y = lerp(_cam_pos.y, target_y, delta * smooth_y)
	else:
		# En el aire: solo mover si cruza las líneas de pánico
		if diff_y < -panic_top:
			# Jugador muy arriba (salto alto)
			target_y = player_pos.y + panic_top
			_cam_pos.y = lerp(_cam_pos.y, target_y, delta * smooth_y_panic)
		elif diff_y > panic_bottom:
			# Jugador muy abajo (caída libre)
			target_y = player_pos.y - panic_bottom
			_cam_pos.y = lerp(_cam_pos.y, target_y, delta * smooth_y_panic)
		# Si está dentro de las líneas de pánico → no mover Y en el aire

	# ── 5. Aplicar límites del nivel ─────────────────────────────
	if use_limits:
		_cam_pos = _apply_limits(_cam_pos)

	# ── 6. Escribir posición global ──────────────────────────────
	# IMPORTANTE: asignamos global_position, NO position ni offset.
	# Esto mueve la cámara en el mundo, no el mundo en la pantalla.
	global_position = _cam_pos


# ════════════════════════════════════════════════════════════════
# LÍMITES
# ════════════════════════════════════════════════════════════════

func _apply_limits(pos: Vector2) -> Vector2:
	# Obtener el tamaño del viewport para calcular el margen
	var vp_size : Vector2 = get_viewport_rect().size / zoom
	var half    : Vector2 = vp_size * 0.5

	var clamped := pos
	if limit_left   != -10000000: clamped.x = max(clamped.x, float(limit_left)   + half.x)
	if limit_right  !=  10000000: clamped.x = min(clamped.x, float(limit_right)  - half.x)
	if limit_top    != -10000000: clamped.y = max(clamped.y, float(limit_top)    + half.y)
	if limit_bottom !=  10000000: clamped.y = min(clamped.y, float(limit_bottom) - half.y)
	return clamped


# ════════════════════════════════════════════════════════════════
# API PÚBLICA
# ════════════════════════════════════════════════════════════════

## Sacudir la cámara (impactos, explosiones).
## Modifica global_position temporalmente, no offset.
func shake(intensity: float = 8.0, duration: float = 0.25) -> void:
	var tween := create_tween()
	var base   := _cam_pos
	var steps  := int(duration * 60.0)
	for i in range(steps):
		var s := Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		) * (1.0 - float(i) / float(steps))
		tween.tween_property(self, "global_position", base + s, 1.0 / 60.0)
	tween.tween_property(self, "global_position", base, 0.05)


## Teletransportar la cámara sin suavizado (cambio de sala, respawn).
func teleport_to(pos: Vector2) -> void:
	_cam_pos = pos
	global_position = pos


## Actualizar límites del nivel dinámicamente.
func set_level_limits(left: int, right: int, top: int, bottom: int) -> void:
	limit_left   = left
	limit_right  = right
	limit_top    = top
	limit_bottom = bottom
