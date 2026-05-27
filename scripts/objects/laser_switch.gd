extends Area2D
class_name LaserSwitch

## ════════════════════════════════════════════════════════════════
## INTERRUPTOR DE LÁSER — NK-7
## El jugador presiona E cerca del switch para apagar/encender
## el láser conectado. Una vez apagado, queda apagado.
## ════════════════════════════════════════════════════════════════

signal switched_off
signal switched_on

## Ruta al nodo del láser que controla (relativa a la raíz de la escena)
@export var laser_node_path : NodePath = NodePath("")
## Si true, solo se puede usar una vez (apagar permanentemente)
@export var one_shot : bool = true

@onready var sprite         : Sprite2D = $Sprite if has_node("Sprite") else null
@onready var interact_label : Label    = $InteractLabel if has_node("InteractLabel") else null

var _activated  : bool = false   ## Ya fue usado
var _player_near: bool = false
var _laser      : Node = null

const C_ACTIVE   := Color(1.0, 0.2, 0.1)   ## Rojo — láser activo
const C_DISABLED := Color(0.1, 0.8, 0.2)   ## Verde — láser apagado

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# Buscar el láser por NodePath primero
	if laser_node_path != NodePath(""):
		_laser = get_node_or_null(laser_node_path)
	
	# Fallback: buscar por nombre desde la raíz
	if not _laser:
		_laser = get_tree().root.find_child("Laser_Vertical2", true, false)
	
	if _laser:
		print("Switch: laser encontrado → ", _laser.name)
	else:
		print("Switch: ERROR - no se encontró laser")

	_update_visuals()

	if interact_label:
		interact_label.visible = false

func _process(_delta: float) -> void:
	if not _player_near:
		return
	if Input.is_action_just_pressed("interact"):
		_use()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "kai":
		_player_near = true
		if interact_label:
			interact_label.visible = not _activated

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "kai":
		_player_near = false
		if interact_label:
			interact_label.visible = false

func _use() -> void:
	if one_shot and _activated:
		return   ## Ya fue usado, no hace nada más

	_activated = true

	if _laser and _laser.has_method("deactivate"):
		_laser.deactivate()
		switched_off.emit()

	_update_visuals()

	if interact_label:
		interact_label.visible = false

func _update_visuals() -> void:
	if sprite:
		sprite.modulate = C_DISABLED if _activated else C_ACTIVE
