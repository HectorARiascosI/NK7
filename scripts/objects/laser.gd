extends Node2D
class_name Laser

## ════════════════════════════════════════════════════════════════
## LÁSER DE SEGURIDAD NK-7
## ════════════════════════════════════════════════════════════════
## Modos:
##   0 = always_on  → siempre activo, sin parpadeo
##   1 = blink      → parpadea ON/OFF con tiempos configurables
##   2 = patrol     → ON largo → advertencia rápida → OFF → ON...
## ════════════════════════════════════════════════════════════════

signal player_hit
signal activated
signal deactivated

@export_group("Comportamiento")
@export_enum("always_on","blink","patrol") var mode : int = 0
@export var blink_on_time  : float = 2.0
@export var blink_off_time : float = 0.8

@export_group("Daño")
@export var kill_on_touch : bool = true

# ── Nodos ─────────────────────────────────────────────────────────
@onready var sprite      : Node2D            = $Sprite       ## Sprite2D o AnimatedSprite2D
@onready var beam_area   : Area2D            = $BeamArea
@onready var beam_shape  : CollisionShape2D  = $BeamArea/BeamShape
## BeamSprite solo existe en laser_h
var beam_sprite : Sprite2D = null

# ── Estado ────────────────────────────────────────────────────────
var is_active    : bool  = true
var _beam_on     : bool  = true
var _blink_timer : float = 0.0
var _warn_phase  : bool  = false
var _warn_timer  : float = 0.0
const WARN_TIME  : float = 0.3   ## s de advertencia (parpadeo rápido)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE

	# Buscar BeamSprite si existe (solo laser_h)
	if has_node("BeamSprite"):
		beam_sprite = $BeamSprite

	if beam_area:
		beam_area.body_entered.connect(_on_body_entered)

	# Offset aleatorio para que no todos parpadeen al mismo tiempo
	_blink_timer = randf_range(0.0, blink_on_time * 0.5)
	_apply_state()

func _process(delta: float) -> void:
	match mode:
		0: pass   # always_on — nada que hacer
		1: _process_blink(delta)
		2: _process_patrol(delta)

# ── Blink: ON ↔ OFF ───────────────────────────────────────────────
func _process_blink(delta: float) -> void:
	if not is_active: return
	_blink_timer += delta
	var threshold := blink_on_time if _beam_on else blink_off_time
	if _blink_timer >= threshold:
		_blink_timer = 0.0
		_beam_on = not _beam_on
		_apply_state()

# ── Patrol: ON largo → parpadeo rápido de advertencia → OFF → ON ──
func _process_patrol(delta: float) -> void:
	if not is_active: return
	_blink_timer += delta

	if _beam_on:
		if _blink_timer >= blink_on_time:
			_blink_timer = 0.0
			_beam_on     = false
			_warn_phase  = false
			_apply_state()
	else:
		# Fase advertencia: parpadeo muy rápido antes de encender
		if not _warn_phase and _blink_timer >= blink_off_time * 0.5:
			_warn_phase = true
			_warn_timer = 0.0

		if _warn_phase:
			_warn_timer += delta
			# Parpadeo rápido visual durante la advertencia
			var fast_blink : bool = fmod(_warn_timer, 0.12) < 0.06
			_set_beam_visible(fast_blink)
			if beam_area:
				beam_area.monitoring = false  # No mata durante advertencia

			if _warn_timer >= WARN_TIME:
				_beam_on     = true
				_warn_phase  = false
				_blink_timer = 0.0
				_apply_state()

# ── Aplicar estado visual y de colisión ───────────────────────────
func _apply_state() -> void:
	var on : bool = is_active and _beam_on
	_set_beam_visible(on)
	if beam_area:
		beam_area.monitoring = on
		# Deshabilitar la colisión física también, no solo el monitoring
		if beam_shape:
			beam_shape.set_deferred("disabled", not on)

func _set_beam_visible(on: bool) -> void:
	if sprite:
		sprite.visible = on
	if beam_sprite:
		beam_sprite.visible = on

# ── Colisión ──────────────────────────────────────────────────────
func _on_body_entered(body: Node2D) -> void:
	if not is_active or not _beam_on: return
	if beam_shape and beam_shape.disabled: return
	if body.is_in_group("player") or body.name == "kai":
		player_hit.emit()
		if kill_on_touch and body.has_method("take_damage"):
			body.take_damage(9999)

# ── API pública ───────────────────────────────────────────────────
func activate() -> void:
	is_active = true
	_beam_on  = true
	_apply_state()
	activated.emit()

func deactivate() -> void:
	is_active = false
	_beam_on  = false
	_apply_state()
	deactivated.emit()
func toggle() -> void:
	if is_active: deactivate()
	else: activate()
