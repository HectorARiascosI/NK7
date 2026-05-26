extends Node2D

## ════════════════════════════════════════════════════════════════
## EXIT DOOR — Puerta de salida al siguiente nivel
## Al entrar el jugador: animación + transición al nivel siguiente
## ════════════════════════════════════════════════════════════════

@export var next_level : int = 1   ## Nivel al que lleva (1 = level_01)
@export var label_text : String = "[E] Salir"

@onready var _area  : Area2D            = $DetectionArea
@onready var _sprite: AnimatedSprite2D  = $Sprite
@onready var _label : Label             = $Label
@onready var _col   : CollisionShape2D  = $StaticBody/CollisionShape2D

var _player_inside : bool = false
var _used          : bool = false

func _ready() -> void:
	_label.text    = label_text
	_label.visible = false
	_area.body_entered.connect(_on_body_entered)
	_area.body_exited.connect(_on_body_exited)
	_sprite.play("closed")

func _process(_delta: float) -> void:
	if _player_inside and not _used:
		if Input.is_action_just_pressed("interact"):
			_enter()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "kai":
		_player_inside = true
		if not _used:
			_label.visible = true
			# Pulso de brillo en la puerta
			var tw := create_tween().set_trans(Tween.TRANS_SINE)
			tw.tween_property(_sprite, "modulate", Color(1.4, 1.2, 0.6), 0.25)
			tw.tween_property(_sprite, "modulate", Color.WHITE, 0.25)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "kai":
		_player_inside = false
		_label.visible = false

func _enter() -> void:
	_used          = true
	_label.visible = false
	_player_inside = false

	# Abrir puerta con animación
	_sprite.play("opening")
	await _sprite.animation_finished
	_sprite.play("open")
	_col.disabled = true

	# Pequeña pausa dramática
	await get_tree().create_timer(0.4).timeout

	# Fade out y cambio de nivel
	if has_node("/root/GameManager"):
		GameManager.transition_to_level(next_level)
	else:
		get_tree().change_scene_to_file("res://scenes/levels/level_0%d.tscn" % next_level)
