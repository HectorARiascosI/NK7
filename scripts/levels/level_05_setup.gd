extends Node

## ════════════════════════════════════════════════════════════════
## LEVEL 05 — Reactor Core NK-7-CORE-01 (El Núcleo Roto)
## ════════════════════════════════════════════════════════════════
## Acto V: La zona central, última barrera antes de la salida.
## Todos los sistemas de seguridad activos simultáneamente.
## El contador de tiempo se vuelve visible. Clímax narrativo.
##
## Mecánicas combinadas (todo lo aprendido):
##   - Láseres + plataformas móviles + zonas electrificadas
##   - Botones y puertas en secuencia
##   - Contador de tiempo visible en el HUD
##   - Dos paneles de activación simultánea (KAI + RENA)
##   - Al activar ambos paneles: luces se apagan → salida verde
##   - Ambiente: rojo profundo, reactor central dominante
##   - "Reactor Core — Authorized Personnel Only"
## ════════════════════════════════════════════════════════════════

signal both_panels_activated
signal level_escape_sequence_started

var _panel_north_activated : bool = false
var _panel_west_activated  : bool = false


func _ready() -> void:
	await get_tree().process_frame
	_setup_hud_timer()
	_connect_final_panels()


func _setup_hud_timer() -> void:
	## Mostrar el temporizador en el HUD al iniciar este nivel
	var hud := _search_node(get_tree().root, "PlayerHUD")
	if hud and hud.has_method("show_timer"):
		hud.show_timer()


func _connect_final_panels() -> void:
	## Los paneles norte y oeste se conectan via señales de Switch
	## en la escena. Cuando ambos se activan, inicia la secuencia de escape.
	pass


func activate_panel_north() -> void:
	"""Llamado por el Switch del panel norte cuando KAI lo activa"""
	_panel_north_activated = true
	_check_both_panels()


func activate_panel_west() -> void:
	"""Llamado por el Switch del panel oeste cuando RENA lo activa"""
	_panel_west_activated = true
	_check_both_panels()


func _check_both_panels() -> void:
	if _panel_north_activated and _panel_west_activated:
		both_panels_activated.emit()
		_start_escape_sequence()


func _start_escape_sequence() -> void:
	"""Secuencia de escape: luces se apagan, salida verde se activa"""
	level_escape_sequence_started.emit()

	# Apagar luces de emergencia (efecto visual)
	var tween := get_tree().create_tween()
	tween.tween_interval(0.5)

	# Transición al siguiente nivel o pantalla de victoria
	await get_tree().create_timer(3.0).timeout
	GameManager.transition_to_scene("res://scenes/ui/main_menu.tscn")


func _search_node(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node
	for child in node.get_children():
		var result := _search_node(child, target_name)
		if result:
			return result
	return null
