extends Node2D
class_name LevelDoor

## ════════════════════════════════════════════════════════════════
## LEVEL DOOR — Puerta de transición entre niveles NK-7
## Detección por distancia (no depende de collision layers)
## Al presionar [E] cerca: animación + transición al nivel destino
## ════════════════════════════════════════════════════════════════

signal door_entered

@export var next_level       : int     = 2
@export var spawn_position   : Vector2 = Vector2.ZERO
@export var label_text       : String  = "[E] Entrar"
@export var required_keycard : String  = ""
@export var interact_radius  : float   = 80.0

# ── Nodos ─────────────────────────────────────────────────────────
@onready var _sprite : Sprite2D         = $DoorSprite
@onready var _label  : Label            = $InteractLabel
@onready var _col    : CollisionShape2D = $StaticBody/CollisionShape2D

# ── Texturas ──────────────────────────────────────────────────────
const BASE_PATH := "res://assets/objects/door_frames/"
var _tex_closed  : Texture2D
var _tex_opening : Texture2D
var _tex_open    : Texture2D

# ── Estado ────────────────────────────────────────────────────────
var _player_near : bool = false
var _used        : bool = false
var _player      : Node = null

# ══════════════════════════════════════════════════════════════════

func _ready() -> void:
	_load_textures()
	if _sprite:
		_sprite.texture = _tex_closed
	_label.text    = label_text
	_label.visible = false
	# Buscar jugador
	await get_tree().process_frame
	_find_player()

func _load_textures() -> void:
	_tex_closed  = load(BASE_PATH + "door_closed.png")  as Texture2D
	_tex_opening = load(BASE_PATH + "door_opening.png") as Texture2D
	_tex_open    = load(BASE_PATH + "door_open.png")    as Texture2D

func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0]
	else:
		_player = _search_node(get_tree().root, "kai")

func _search_node(node: Node, target: String) -> Node:
	if node.name == target:
		return node
	for child in node.get_children():
		var r := _search_node(child, target)
		if r:
			return r
	return null

func _process(_delta: float) -> void:
	if _used:
		return

	# Re-buscar jugador si no lo tenemos
	if not _player or not is_instance_valid(_player):
		_find_player()
		return

	# Detección por distancia — no depende de collision layers
	var dist := global_position.distance_to(_player.global_position)
	var near := dist <= interact_radius

	if near != _player_near:
		_player_near = near
		_label.visible = near

	if near and Input.is_action_just_pressed("interact"):
		_enter()

# ── Entrada ───────────────────────────────────────────────────────

func _enter() -> void:
	# Verificar keycard
	if required_keycard != "":
		if _player and _player.has_method("has_keycard"):
			if not _player.has_keycard(required_keycard):
				_label.text = "⚠ Requiere tarjeta de acceso"
				_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
				await get_tree().create_timer(2.0).timeout
				_label.text = label_text
				_label.remove_theme_color_override("font_color")
				return

	_used          = true
	_label.visible = false

	# Freeze al jugador
	if _player and _player.has_method("set_physics_process"):
		_player.set_physics_process(false)

	# Animación de apertura
	if _sprite:
		var tw := create_tween().set_trans(Tween.TRANS_SINE)
		tw.tween_property(_sprite, "modulate", Color(1.5, 1.3, 0.8), 0.1)
		tw.tween_callback(func(): _sprite.texture = _tex_opening)
		tw.tween_property(_sprite, "modulate", Color.WHITE, 0.2)
		await tw.finished

	await get_tree().create_timer(0.25).timeout

	if _sprite:
		_sprite.texture = _tex_open
	if _col:
		_col.disabled = true

	# Mover jugador hacia la puerta
	if _player:
		var tw_walk := create_tween().set_trans(Tween.TRANS_SINE)
		tw_walk.tween_property(_player, "position:x", global_position.x, 0.3)
		await tw_walk.finished

	await get_tree().create_timer(0.2).timeout

	door_entered.emit()

	# Transición
	if has_node("/root/GameManager"):
		if spawn_position != Vector2.ZERO:
			GameManager.set_meta("next_spawn", spawn_position)
		GameManager.transition_to_level(next_level)
	else:
		get_tree().change_scene_to_file(
			"res://scenes/levels/level_%02d.tscn" % next_level)
