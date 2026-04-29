extends Node2D
class_name Door

## Puerta industrial NK7
## Estados: cerrada (roja), abriendo, abierta (verde), bloqueada, electrificada

signal door_opened
signal door_closed
signal player_blocked   # jugador intentó pasar puerta bloqueada

# ── Configuración ─────────────────────────────────────────────
@export_group("Estado")
@export var starts_open   : bool  = false
@export var locked        : bool  = false   # requiere interruptor
@export var electrified   : bool  = false   # mata al tocar
@export var auto_close    : bool  = false
@export var auto_close_delay : float = 3.0

@export_group("Animación")
@export var open_duration : float = 0.6

# ── Nodos ─────────────────────────────────────────────────────
@onready var sprite    : AnimatedSprite2D  = $Sprite
@onready var collision : CollisionShape2D  = $StaticBody/CollisionShape2D
@onready var body      : StaticBody2D      = $StaticBody
@onready var area      : Area2D            = $DetectionArea

# ── Estado ────────────────────────────────────────────────────
var _is_open     : bool = false
var _is_animating: bool = false

# ════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ════════════════════════════════════════════════════════════════

func _ready() -> void:
	_is_open = starts_open
	area.body_entered.connect(_on_body_entered)
	_update_state(false)  # sin animación al inicio

func _update_state(animate: bool) -> void:
	if _is_open:
		collision.disabled = true
		if animate:
			sprite.play("opening")
			await sprite.animation_finished
		sprite.play("open")
	else:
		collision.disabled = false
		if animate:
			sprite.play("closing")
			await sprite.animation_finished
		if electrified:
			sprite.play("electrified")
		elif locked:
			sprite.play("locked")
		else:
			sprite.play("closed")


# ════════════════════════════════════════════════════════════════
# COLISIÓN
# ════════════════════════════════════════════════════════════════

func _on_body_entered(body_node: Node2D) -> void:
	if not (body_node.is_in_group("player") or body_node.name == "kai"):
		return

	if electrified and not _is_open:
		_electrocute_player(body_node)
	elif locked and not _is_open:
		player_blocked.emit()
		# Mostrar hint de que está bloqueada
		_flash_locked()

func _electrocute_player(player: Node2D) -> void:
	if player.has_node("AnimatedSprite2D"):
		player.get_node("AnimatedSprite2D").play("dead")
	player.set_physics_process(false)
	if has_node("/root/GameManager"):
		get_node("/root/GameManager").shake_camera(15.0, 0.4)
	await get_tree().create_timer(1.5).timeout
	get_tree().reload_current_scene()

func _flash_locked() -> void:
	# Parpadeo rápido para indicar que está bloqueada
	var tween := create_tween()
	for i in range(3):
		tween.tween_property(sprite, "modulate", Color(1.5, 0.3, 0.3, 1), 0.08)
		tween.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.08)


# ════════════════════════════════════════════════════════════════
# API PÚBLICA
# ════════════════════════════════════════════════════════════════

func activate() -> void:
	open()

func deactivate() -> void:
	close()

func open() -> void:
	if _is_open or _is_animating:
		return
	_is_open = true
	_is_animating = true
	door_opened.emit()
	await _update_state(true)
	_is_animating = false

	if auto_close:
		await get_tree().create_timer(auto_close_delay).timeout
		close()

func close() -> void:
	if not _is_open or _is_animating:
		return
	_is_open = false
	_is_animating = true
	door_closed.emit()
	await _update_state(true)
	_is_animating = false

func unlock() -> void:
	locked = false
	if not _is_open:
		sprite.play("closed")

func is_open() -> bool:
	return _is_open
