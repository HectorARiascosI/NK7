extends Node

## ════════════════════════════════════════════════════════════════
## LEVEL 02 — Sector 7-F Security (Láseres Activos)
## ════════════════════════════════════════════════════════════════
## Acto II: KAI alcanza la zona de seguridad principal.
## Los láseres de detección fueron reconfigurados en modo letal.
## El jugador aprende que observar antes de actuar es fundamental.
##
## Mecánicas introducidas:
##   - Láseres horizontales y verticales con patrones
##   - Primera exposición al sistema de daño
##   - Puertas bloqueadas que requieren hackeo [Q]
##   - Zona "Restricted Area" con mayor densidad de peligros
## ════════════════════════════════════════════════════════════════


func _ready() -> void:
	# Mostrar recordatorio de controles al iniciar (no tutorial completo)
	await get_tree().process_frame
	_show_level_intro()


func _show_level_intro() -> void:
	## Buscar el sistema de tutorial para mostrar recordatorio de controles
	var tutorial := _search_node(get_tree().root, "TutorialSystem")
	if tutorial and tutorial.has_method("show_controls_reminder"):
		await get_tree().create_timer(1.5).timeout
		tutorial.show_controls_reminder()


func _search_node(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node
	for child in node.get_children():
		var result := _search_node(child, target_name)
		if result:
			return result
	return null
