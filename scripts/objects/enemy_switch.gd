extends Area2D
class_name EnemySwitch

## ════════════════════════════════════════════════════════════════
## PALANCA / INTERRUPTOR DE CONTROL DE ENEMIGOS
## ════════════════════════════════════════════════════════════════
## Al interactuar (E), desactiva o reactiva todos los Ukibukis
## del grupo "enemies" que estén en el mismo nivel.
## ════════════════════════════════════════════════════════════════

signal switched(is_off: bool)

@export var switch_id   : String = ""   ## ID único para persistencia
@export var starts_on   : bool   = true ## true = enemigos activos al inicio
@export var affect_group: String = "enemies"  ## grupo a afectar

@onready var sprite     : AnimatedSprite2D = $Sprite
@onready var prompt     : Label            = $Prompt
@onready var collision  : CollisionShape2D = $CollisionShape2D

var _enemies_active : bool = true
var _player_nearby  : bool = false

# ══════════════════════════════════════════════════════════════════

func _ready() -> void:
	_enemies_active = starts_on
	_update_visuals()

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	if switch_id.is_empty():
		switch_id = "eswitch_%s_%d" % [name, get_instance_id()]

func _unhandled_input(event: InputEvent) -> void:
	if not _player_nearby:
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_toggle()

# ══════════════════════════════════════════════════════════════════

func _toggle() -> void:
	_enemies_active = not _enemies_active
	_apply_to_enemies()
	_update_visuals()
	switched.emit(not _enemies_active)

	if has_node("/root/AudioManager"):
		AudioManager.play_sfx("switch")

func _apply_to_enemies() -> void:
	var enemies := get_tree().get_nodes_in_group(affect_group)
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if _enemies_active:
			# Reactivar
			enemy.set_physics_process(true)
			enemy.set_process(true)
			if enemy.has_method("set_aggro"):
				enemy.set_aggro(true)
		else:
			# Desactivar — detener movimiento y IA
			enemy.set_physics_process(false)
			enemy.set_process(false)
			if "velocity" in enemy:
				enemy.velocity = Vector2.ZERO
			# Cambiar a animación idle
			if enemy.has_node("Sprite"):
				var spr = enemy.get_node("Sprite")
				if spr is AnimatedSprite2D:
					spr.play("idle")

func _update_visuals() -> void:
	if sprite:
		# Animación ON (palanca arriba) o OFF (palanca abajo)
		var anim := "on" if _enemies_active else "off"
		if sprite.sprite_frames and sprite.sprite_frames.has_animation(anim):
			sprite.play(anim)

	if prompt:
		prompt.text = "[E] Desactivar robots" if _enemies_active else "[E] Activar robots"

# ══════════════════════════════════════════════════════════════════

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "kai":
		_player_nearby = true
		if prompt:
			prompt.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "kai":
		_player_nearby = false
		if prompt:
			prompt.visible = false
