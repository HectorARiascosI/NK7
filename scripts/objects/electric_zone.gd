extends Area2D
class_name ElectricZone

## Zona electrificada NK7
## Suelo o barrera con descarga eléctrica animada
## Se puede desactivar con interruptores

signal player_hit

# ── Configuración ─────────────────────────────────────────────
@export var is_active      : bool  = true
@export var blink_enabled  : bool  = true
@export var blink_on_time  : float = 1.2
@export var blink_off_time : float = 0.4
@export var kill_on_touch  : bool  = true

# ── Nodos ─────────────────────────────────────────────────────
@onready var sprite : AnimatedSprite2D = $Sprite

# ── Estado ────────────────────────────────────────────────────
var _blink_timer : float = 0.0
var _blink_on    : bool  = true

# ════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ════════════════════════════════════════════════════════════════

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_update_visual()

func _update_visual() -> void:
	if not is_instance_valid(sprite):
		return
	if not is_active:
		sprite.play("off")
		monitoring = false
		return
	monitoring = _blink_on if blink_enabled else true
	sprite.play("active" if (_blink_on or not blink_enabled) else "idle")


# ════════════════════════════════════════════════════════════════
# PROCESO
# ════════════════════════════════════════════════════════════════

func _process(delta: float) -> void:
	if not is_active or not blink_enabled:
		return

	_blink_timer += delta
	var threshold := blink_on_time if _blink_on else blink_off_time
	if _blink_timer >= threshold:
		_blink_timer = 0.0
		_blink_on = not _blink_on
		_update_visual()


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
	if has_node("/root/GameManager"):
		get_node("/root/GameManager").shake_camera(14.0, 0.35)
	await get_tree().create_timer(1.5).timeout
	get_tree().reload_current_scene()


# ════════════════════════════════════════════════════════════════
# API PÚBLICA
# ════════════════════════════════════════════════════════════════

func activate() -> void:
	is_active = true
	_update_visual()

func deactivate() -> void:
	is_active = false
	_update_visual()

func toggle() -> void:
	if is_active:
		deactivate()
	else:
		activate()
