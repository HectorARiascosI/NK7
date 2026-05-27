extends Node2D
class_name LevelDoor

## ════════════════════════════════════════════════════════════════
## LEVEL DOOR — Puerta de transición entre niveles  NK-7
## Usa los frames extraídos del spritesheet doors.png
## Al presionar [E] cerca: animación de apertura + transición
## ════════════════════════════════════════════════════════════════

signal door_entered

## Nivel destino (número de nivel Godot: 1=level_01, 2=level_02…)
@export var next_level      : int    = 2
## Posición de spawn del jugador en el nivel destino (Vector2.ZERO = default)
@export var spawn_position  : Vector2 = Vector2.ZERO
## Texto del label de interacción
@export var label_text      : String  = "[E] Entrar"

# ── Nodos ─────────────────────────────────────────────────────────
@onready var _detect : Area2D           = $DetectionArea
@onready var _sprite : Sprite2D         = $DoorSprite
@onready var _label  : Label            = $InteractLabel
@onready var _col    : CollisionShape2D = $StaticBody/CollisionShape2D
@onready var _glow   : PointLight2D     = $GlowLight

# ── Texturas ──────────────────────────────────────────────────────
const BASE_PATH := "res://assets/objects/door_frames/"
var _tex_closed  : Texture2D
var _tex_opening : Texture2D
var _tex_open    : Texture2D

# ── Estado ────────────────────────────────────────────────────────
var _player_near : bool = false
var _used        : bool = false

# ══════════════════════════════════════════════════════════════════

func _ready() -> void:
	_load_textures()
	_sprite.texture = _tex_closed
	_label.text     = label_text
	_label.visible  = false
	_glow.enabled   = false

	_detect.body_entered.connect(_on_body_entered)
	_detect.body_exited.connect(_on_body_exited)

func _load_textures() -> void:
	_tex_closed  = load(BASE_PATH + "door_closed.png")  as Texture2D
	_tex_opening = load(BASE_PATH + "door_opening.png") as Texture2D
	_tex_open    = load(BASE_PATH + "door_open.png")    as Texture2D

func _process(_delta: float) -> void:
	if _player_near and not _used:
		if Input.is_action_just_pressed("interact"):
			_enter()

# ── Detección ─────────────────────────────────────────────────────

func _on_body_entered(body: Node2D) -> void:
	if not (body.is_in_group("player") or body.name == "kai"):
		return
	_player_near = true
	if _used:
		return
	_label.visible = true
	_glow.enabled  = true
	# Pulso de brillo
	var tw := create_tween().set_trans(Tween.TRANS_SINE).set_loops(0)
	tw.tween_property(_glow, "energy", 1.8, 0.5)
	tw.tween_property(_glow, "energy", 0.8, 0.5)

func _on_body_exited(body: Node2D) -> void:
	if not (body.is_in_group("player") or body.name == "kai"):
		return
	_player_near   = false
	_label.visible = false
	_glow.enabled  = false

# ── Entrada ───────────────────────────────────────────────────────

func _enter() -> void:
	_used          = true
	_player_near   = false
	_label.visible = false
	_glow.enabled  = false

	# Freeze al jugador
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("set_physics_process"):
		player.set_physics_process(false)

	# Animación: closed → opening → open
	var tw_open := create_tween().set_trans(Tween.TRANS_SINE)
	tw_open.tween_property(_sprite, "modulate", Color(1.5, 1.3, 0.8), 0.1)
	tw_open.tween_callback(func(): _sprite.texture = _tex_opening)
	tw_open.tween_property(_sprite, "modulate", Color.WHITE, 0.2)
	await tw_open.finished

	await get_tree().create_timer(0.25).timeout
	_sprite.texture = _tex_open
	_col.disabled   = true

	# Mover jugador hacia la puerta
	if player:
		var tw_walk := create_tween().set_trans(Tween.TRANS_SINE)
		tw_walk.tween_property(player, "position:x", global_position.x, 0.3)
		await tw_walk.finished

	await get_tree().create_timer(0.2).timeout

	door_entered.emit()

	# Transición al siguiente nivel
	if has_node("/root/GameManager"):
		if spawn_position != Vector2.ZERO:
			GameManager.set_meta("next_spawn", spawn_position)
		GameManager.transition_to_level(next_level)
	else:
		get_tree().change_scene_to_file(
			"res://scenes/levels/level_%02d.tscn" % next_level)
