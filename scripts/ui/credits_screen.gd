extends Control

## Credits Screen - NK7
## Pantalla de créditos del proyecto universitario
## Muestra el equipo de desarrollo y agradecimientos

signal back_to_menu_requested

@onready var _scroll_container : ScrollContainer = $ScrollContainer
@onready var _back_button : Button = $BackButton
@onready var _vbox : VBoxContainer = $ScrollContainer/VBoxContainer

var _auto_scroll : bool = true
var _scroll_speed : float = 30.0  # Píxeles por segundo
var _scroll_position : float = 0.0


func _ready() -> void:
	_back_button.pressed.connect(_on_back_pressed)
	_scroll_container.scroll_vertical = 0
	_scroll_position = 0.0
	
	# Fade in suave
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)


func _process(delta: float) -> void:
	if _auto_scroll:
		_scroll_position += _scroll_speed * delta
		_scroll_container.scroll_vertical = int(_scroll_position)
		
		# Si llegamos al final, volver al inicio
		var max_scroll := _vbox.size.y - _scroll_container.size.y
		if _scroll_position >= max_scroll:
			_scroll_position = 0.0


func _input(event: InputEvent) -> void:
	# Detener auto-scroll si el usuario interactúa
	if event is InputEventMouseButton or event is InputEventKey:
		if event.is_pressed():
			_auto_scroll = false
	
	# ESC para volver
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_on_back_pressed()


func _on_back_pressed() -> void:
	# Fade out
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished
	
	# Volver al menú principal
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func reset_scroll() -> void:
	"""Resetear el scroll al inicio"""
	_scroll_position = 0.0
	_scroll_container.scroll_vertical = 0
	_auto_scroll = true
