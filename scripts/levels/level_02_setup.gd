extends Node

## ════════════════════════════════════════════════════════════════
## LEVEL 02 — Sector 7-F Security
## ════════════════════════════════════════════════════════════════
## Kai llega al sector de seguridad principal.
## Los sistemas de control están más activos que en el Sector B.
##
## Mecánicas introducidas en este nivel:
##   - Láser V con timing (blink) — esperar el momento correcto
##   - Láser H con patrol — más peligroso, necesita switch previo
##   - Puerta bloqueada [Q] — requiere energía para hackear
##   - Keycard — coleccionable necesario para la salida
##   - Ukibuki más agresivo en piso 3 (mayor rango y velocidad)
##
## Flujo esperado del jugador:
##   1. Entrar por la izquierda del piso 1
##   2. Esperar timing del láser V o encontrar el switch
##   3. Subir al piso 2, recargar energía en EnergyTube
##   4. Apagar el switch del láser H (piso 2 izquierda)
##   5. Hackear la puerta bloqueada [Q] (piso 2 derecha)
##   6. Subir al piso 3, derrotar/esquivar Ukibuki3
##   7. Recoger la keycard
##   8. Usar la puerta de salida
## ════════════════════════════════════════════════════════════════

func _ready() -> void:
	await get_tree().process_frame
	_check_persistent_state()
	await get_tree().create_timer(1.2).timeout
	_show_level_hint()


func _check_persistent_state() -> void:
	## Restaurar estado de objetos que ya fueron interactuados
	## (LevelStateManager lo maneja automáticamente para puertas)
	## Aquí podemos hacer ajustes adicionales si es necesario
	pass


func _show_level_hint() -> void:
	## Mostrar un recordatorio breve de los controles clave para este nivel
	var tutorial := _search_node(get_tree().root, "TutorialSystem")
	if tutorial and tutorial.has_method("show_hint"):
		tutorial.show_hint("Sector 7-F — Sistema de seguridad activo\n[Q] Hackear · [E] Interactuar · Busca la tarjeta de acceso")
	elif tutorial and tutorial.has_method("show_controls_reminder"):
		tutorial.show_controls_reminder()


func _search_node(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node
	for child in node.get_children():
		var result := _search_node(child, target_name)
		if result:
			return result
	return null
