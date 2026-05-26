extends Node

## ════════════════════════════════════════════════════════════════
## LEVEL 03 — Sector 7 Control Center B (Circuitos y Puertas)
## ════════════════════════════════════════════════════════════════
## Acto III: KAI llega al centro de control secundario.
## Los circuitos de emergencia generaron un laberinto de puertas
## bloqueadas activadas por interruptores.
##
## Mecánicas introducidas:
##   - Mini-puzzles: botones que abren puertas específicas
##   - Interruptores que activan/desactivan láseres
##   - Puertas dañadas que requieren reparación [F]
##   - Panel de emergencia al final → señal de RENA
##   - "Access Control Systems — System Offline" como narrativa
## ════════════════════════════════════════════════════════════════


func _ready() -> void:
	await get_tree().process_frame
	_trigger_rena_signal_at_end()


func _trigger_rena_signal_at_end() -> void:
	## La señal de RENA se activa cuando el jugador llega al panel
	## de emergencia al final del nivel (conectado via Switch en la escena)
	pass


func _search_node(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node
	for child in node.get_children():
		var result := _search_node(child, target_name)
		if result:
			return result
	return null
