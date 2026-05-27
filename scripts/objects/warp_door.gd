extends Node2D
class_name WarpDoor

## ════════════════════════════════════════════════════════════════
## WARP DOOR — Puerta de teletransporte dentro del mismo nivel
## Al presionar [E] cerca: fade rápido + teletransporte al destino
## ════════════════════════════════════════════════════════════════

signal warped

@export var warp_target      : Vector2 = Vector2.ZERO  ## Posición destino GLOBAL (en coordenadas del mundo)
@export var warp_marker      : NodePath = NodePath("")  ## Alternativa: NodePath a un Marker2D destino
@export var label_text       : String  = "[E] Subir"
@export var interact_radius  : float   = 80.0

@onready var _label : Label = $InteractLabel if has_node("InteractLabel") else null

var _player_near : bool = false
var _used        : bool = false
var _player      : Node = null

# ══════════════════════════════════════════════════════════════════

func _ready() -> void:
	# Crear label si no existe en la escena
	if not _label:
		_label = Label.new()
		_label.add_theme_font_size_override("font_size", 13)
		_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.3))
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.position = Vector2(-50, -55)
		add_child(_label)

	_label.text    = label_text
	_label.visible = false

	await get_tree().process_frame
	_find_player()

func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0]
	else:
		_player = _search_node(get_tree().root, "kai")

func _search_node(node: Node, target: String) -> Node:
	if node.name == target: return node
	for child in node.get_children():
		var r := _search_node(child, target)
		if r: return r
	return null

func _process(_delta: float) -> void:
	if _used: return
	if not _player or not is_instance_valid(_player):
		_find_player()
		return

	var dist := global_position.distance_to(_player.global_position)
	var near := dist <= interact_radius

	if near != _player_near:
		_player_near = near
		_label.visible = near

	if near and Input.is_action_just_pressed("interact"):
		_warp()

func _warp() -> void:
	# Resolver destino — marker tiene prioridad sobre warp_target
	var dest : Vector2 = Vector2.ZERO
	if warp_marker != NodePath(""):
		var marker := get_node_or_null(warp_marker)
		if marker: dest = marker.global_position
	if dest == Vector2.ZERO:
		dest = warp_target
	if dest == Vector2.ZERO:
		push_warning("WarpDoor: warp_target no configurado")
		return

	_used          = true
	_label.visible = false

	# Fade rápido a negro
	var canvas := CanvasLayer.new()
	canvas.layer = 50
	get_tree().root.add_child(canvas)

	var fade := ColorRect.new()
	fade.color = Color.BLACK
	fade.modulate.a = 0.0
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(fade)

	var tw := create_tween()
	tw.tween_property(fade, "modulate:a", 1.0, 0.2)
	await tw.finished

	# Teletransportar al jugador
	_player.global_position = dest
	if "velocity" in _player:
		_player.velocity = Vector2.ZERO

	warped.emit()

	# Fade de vuelta
	await get_tree().process_frame
	var tw2 := create_tween()
	tw2.tween_property(fade, "modulate:a", 0.0, 0.25)
	await tw2.finished

	canvas.queue_free()
	_used = false  # Permitir usar la puerta de nuevo (para bajar también)
