extends Node

## Tutorial del Nivel 01 — Demo de Mecánicas
## Este nivel es una demostración de las capacidades del juego
## Muestra controles, física, y mecánicas básicas

# ── Referencias ───────────────────────────────────────────────
var _tutorial_system : Node = null
var _player          : Node = null

# ════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ════════════════════════════════════════════════════════════════

func _ready() -> void:
	await get_tree().process_frame
	_tutorial_system = _find_node("TutorialSystem")
	_player = _find_node("kai")
	
	# Conectar señal de fin de tutorial para iniciar el timer
	if _tutorial_system:
		if not _tutorial_system.tutorial_finished.is_connected(_on_tutorial_finished):
			_tutorial_system.tutorial_finished.connect(_on_tutorial_finished)
		if not _tutorial_system.tutorial_skipped.is_connected(_on_tutorial_finished):
			_tutorial_system.tutorial_skipped.connect(_on_tutorial_finished)
	
	# Mostrar tutorial después de 1 segundo
	await get_tree().create_timer(1.0).timeout
	if _tutorial_system and _tutorial_system.has_method("show_tutorial"):
		_tutorial_system.show_tutorial()


func _on_tutorial_finished() -> void:
	"""Iniciar el timer cuando el jugador termina o salta el tutorial"""
	var hud := _find_node("PlayerHUD")
	if hud and hud.has_method("show_timer"):
		hud.show_timer()


func _find_node(node_name: String) -> Node:
	var root := get_tree().root
	return _search(root, node_name)


func _search(node: Node, target: String) -> Node:
	if node.name == target:
		return node
	for child in node.get_children():
		var result := _search(child, target)
		if result:
			return result
	return null


# ════════════════════════════════════════════════════════════════
# INPUT - Acceso rápido al tutorial
# ════════════════════════════════════════════════════════════════

func _unhandled_input(event: InputEvent) -> void:
	# TAB para ver controles en cualquier momento
	if event.is_action_pressed("ui_focus_next"):  # TAB
		if _tutorial_system and _tutorial_system.has_method("show_controls_reminder"):
			get_viewport().set_input_as_handled()
			_tutorial_system.show_controls_reminder()
