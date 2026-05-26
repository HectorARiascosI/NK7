extends Area2D

## Safe Zone - Zona Segura
## Marca áreas donde es seguro respawnear
## Invisible en juego, solo visible en modo debug

@export var zone_id : int = 0
@export var show_visual_debug : bool = false  # Solo para debug

var _is_player_inside : bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Solo crear visual si está en modo debug
	if show_visual_debug and OS.is_debug_build():
		_create_debug_visual()


func _create_debug_visual() -> void:
	"""Crea un indicador visual SOLO para debug"""
	var collision_shape := get_node_or_null("CollisionShape2D")
	if not collision_shape:
		return
	
	if collision_shape.shape == null:
		return
	
	var shape : Shape2D = collision_shape.shape
	if not shape is RectangleShape2D:
		return
	
	var rect_shape := shape as RectangleShape2D
	var size := rect_shape.size
	
	# Crear ColorRect semi-transparente
	var visual := ColorRect.new()
	visual.size = size
	visual.position = -size / 2
	visual.color = Color(0.0, 0.8, 1.0, 0.15)  # Muy transparente
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(visual)
	
	# Borde sutil
	var border := ReferenceRect.new()
	border.border_color = Color(0.0, 0.8, 1.0, 0.3)
	border.border_width = 1.0
	border.size = size
	border.position = -size / 2
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(border)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_is_player_inside = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_is_player_inside = false


func is_player_inside() -> bool:
	return _is_player_inside
