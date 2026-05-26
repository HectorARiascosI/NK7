extends Control

## ════════════════════════════════════════════════════════════════
## GAME OVER SCREEN — NK-7
## Al presionar cualquier tecla: fade out → reinicia el nivel
## con el jugador con vida completa.
## ════════════════════════════════════════════════════════════════

var _ready_to_skip : bool = false

func _ready() -> void:
	# Empezar invisible
	modulate.a = 0.0
	$Vignette.modulate.a = 0.0

	# 1. Fade in lento de la imagen
	var tw1 := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tw1.tween_property(self, "modulate:a", 1.0, 1.5)
	await tw1.finished

	# 2. Pulso de viñeta roja
	var tw2 := create_tween().set_trans(Tween.TRANS_SINE)
	tw2.tween_property($Vignette, "modulate:a", 0.55, 0.4)
	tw2.tween_property($Vignette, "modulate:a", 0.0,  0.4)
	await tw2.finished

	# 3. Shake de la pantalla
	var origin := position
	var tw3 := create_tween().set_trans(Tween.TRANS_SINE)
	for i in range(6):
		tw3.tween_property(self, "position:x", origin.x + (6 if i % 2 == 0 else -6), 0.04)
	tw3.tween_property(self, "position:x", origin.x, 0.04)
	await tw3.finished

	_ready_to_skip = true

func _input(event: InputEvent) -> void:
	if not _ready_to_skip:
		return
	if event is InputEventKey and event.pressed:
		_restart()
	elif event is InputEventMouseButton and event.pressed:
		_restart()
	elif event is InputEventJoypadButton and event.pressed:
		_restart()

func _restart() -> void:
	_ready_to_skip = false

	# Fade out con flash blanco antes de reiniciar
	var tw := create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tw.tween_property($Flash, "modulate:a", 1.0, 0.15)
	tw.tween_property(self,   "modulate:a", 0.0, 0.3)
	await tw.finished

	# Reiniciar nivel actual con vida completa
	if has_node("/root/GameManager"):
		GameManager.transition_to_level(GameManager.current_level)
	else:
		get_tree().reload_current_scene()
