extends Node2D
class_name Laser

## Láser de seguridad NK7
## Soporta: horizontal, vertical y rotatorio (diagonal)
## Se puede activar/desactivar mediante señales o interruptores

signal player_hit

# ── Configuración ─────────────────────────────────────────────
@export_group("Tipo")
@export_enum("Horizontal", "Vertical", "Rotating") var laser_type : int = 0
@export var laser_length  : float = 200.0
@export var laser_width   : float = 4.0

@export_group("Comportamiento")
@export var is_active     : bool  = true
@export var blink_enabled : bool  = false
@export var blink_on_time : float = 1.5
@export var blink_off_time: float = 0.8
@export var rotate_speed  : float = 45.0   # grados/segundo (solo tipo Rotating)

@export_group("Daño")
@export var kill_on_touch : bool  = true
@export var damage        : int   = 1

# ── Nodos ─────────────────────────────────────────────────────
@onready var beam_area    : Area2D       = $BeamArea
@onready var beam_shape   : CollisionShape2D = $BeamArea/BeamShape
@onready var emitter_sprite : AnimatedSprite2D = $EmitterSprite

# ── Estado ────────────────────────────────────────────────────
var _blink_timer : float = 0.0
var _blink_on    : bool  = true
var _rotation_deg: float = 0.0

# ── Colores ───────────────────────────────────────────────────
const C_BEAM_ACTIVE  := Color(1.0, 0.10, 0.05, 0.85)
const C_BEAM_GLOW    := Color(1.0, 0.30, 0.20, 0.25)
const C_BEAM_OFF     := Color(0.30, 0.05, 0.02, 0.3)

# ════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ════════════════════════════════════════════════════════════════

func _ready() -> void:
	_setup_collision()
	beam_area.body_entered.connect(_on_body_entered)
	_update_active_state()

func _setup_collision() -> void:
	var shape := RectangleShape2D.new()
	match laser_type:
		0:  # Horizontal
			shape.size = Vector2(laser_length, laser_width * 2.0)
			beam_shape.position = Vector2(laser_length * 0.5, 0)
		1:  # Vertical
			shape.size = Vector2(laser_width * 2.0, laser_length)
			beam_shape.position = Vector2(0, laser_length * 0.5)
		2:  # Rotating — empieza horizontal
			shape.size = Vector2(laser_length, laser_width * 2.0)
			beam_shape.position = Vector2(laser_length * 0.5, 0)
	beam_shape.shape = shape


# ════════════════════════════════════════════════════════════════
# PROCESO
# ════════════════════════════════════════════════════════════════

func _process(delta: float) -> void:
	# Parpadeo
	if blink_enabled and is_active:
		_blink_timer += delta
		var threshold := blink_on_time if _blink_on else blink_off_time
		if _blink_timer >= threshold:
			_blink_timer = 0.0
			_blink_on = not _blink_on
			beam_area.monitoring = _blink_on

	# Rotación
	if laser_type == 2 and is_active:
		_rotation_deg += rotate_speed * delta
		rotation_degrees = _rotation_deg

	queue_redraw()

func _draw() -> void:
	if not is_active:
		_draw_beam(C_BEAM_OFF, false)
		return

	var visible_beam := _blink_on if blink_enabled else true
	if visible_beam:
		_draw_beam(C_BEAM_ACTIVE, true)
	else:
		_draw_beam(C_BEAM_OFF, false)

func _draw_beam(color: Color, glowing: bool) -> void:
	var start := Vector2.ZERO
	var end   : Vector2

	match laser_type:
		0, 2:  # Horizontal / Rotating
			end = Vector2(laser_length, 0)
		1:     # Vertical
			end = Vector2(0, laser_length)

	# Halo exterior
	if glowing:
		draw_line(start, end, Color(color.r, color.g, color.b, 0.15), laser_width * 4.0)
		draw_line(start, end, Color(color.r, color.g, color.b, 0.30), laser_width * 2.5)

	# Núcleo del láser
	draw_line(start, end, color, laser_width)

	# Línea central brillante
	if glowing:
		draw_line(start, end, Color(1.0, 0.8, 0.8, 0.9), laser_width * 0.4)

	# Emisor (punto de origen)
	draw_circle(start, laser_width * 1.5, color)
	if glowing:
		draw_circle(start, laser_width * 0.6, Color(1, 1, 1, 0.9))


# ════════════════════════════════════════════════════════════════
# COLISIÓN
# ════════════════════════════════════════════════════════════════

func _on_body_entered(body: Node2D) -> void:
	if not is_active:
		return
	if blink_enabled and not _blink_on:
		return

	if body.is_in_group("player") or body.name == "kai":
		player_hit.emit()
		if kill_on_touch:
			_kill_player(body)

func _kill_player(player: Node2D) -> void:
	if player.has_node("AnimatedSprite2D"):
		player.get_node("AnimatedSprite2D").play("dead")
	player.set_physics_process(false)
	# Sacudir cámara
	if has_node("/root/GameManager"):
		get_node("/root/GameManager").shake_camera(12.0, 0.3)
	await get_tree().create_timer(1.5).timeout
	get_tree().reload_current_scene()


# ════════════════════════════════════════════════════════════════
# API PÚBLICA
# ════════════════════════════════════════════════════════════════

func activate() -> void:
	is_active = true
	beam_area.monitoring = true
	_update_active_state()

func deactivate() -> void:
	is_active = false
	beam_area.monitoring = false
	_update_active_state()

func toggle() -> void:
	if is_active:
		deactivate()
	else:
		activate()

func _update_active_state() -> void:
	if beam_area:
		beam_area.monitoring = is_active and (_blink_on if blink_enabled else true)
	queue_redraw()
