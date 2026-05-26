extends Control

## ════════════════════════════════════════════════════════════════
## SPLASH SCREEN — NK-7
## Muestra la pantalla de inicio. Cualquier tecla/click → menú.
## ════════════════════════════════════════════════════════════════

var _ready_to_skip : bool = false

func _ready() -> void:
	modulate.a = 0.0
	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "modulate:a", 1.0, 1.2)
	await tw.finished
	_ready_to_skip = true

func _input(event: InputEvent) -> void:
	if not _ready_to_skip:
		return
	if event is InputEventKey and event.pressed:
		_go_to_menu()
	elif event is InputEventMouseButton and event.pressed:
		_go_to_menu()
	elif event is InputEventJoypadButton and event.pressed:
		_go_to_menu()

func _go_to_menu() -> void:
	_ready_to_skip = false
	var tw := create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "modulate:a", 0.0, 0.4)
	await tw.finished
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
