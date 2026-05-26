extends Node

## ════════════════════════════════════════════════════════════════
## LEVEL 04 — Zone D Industrial Core (El Sector Inestable)
## ════════════════════════════════════════════════════════════════
## Acto IV: El núcleo central comienza a desestabilizarse.
## Plataformas de mantenimiento se mueven mal, láseres en ciclo
## y zonas electrificadas en el suelo. Checkpoints más escasos.
##
## Mecánicas combinadas:
##   - Plataformas móviles (ciclos de 12 segundos)
##   - Láseres en ciclo + zonas electrificadas simultáneas
##   - Mayor densidad de Ukibukis patrullando
##   - Puertas eléctricas (requieren reparar Y hackear)
##   - Ambiente: calor naranja/rojo, maquinaria industrial pesada
##   - "Zone D — Industrial Core" con ventiladores y tuberías
## ════════════════════════════════════════════════════════════════


func _ready() -> void:
	await get_tree().process_frame
	_setup_ambient_effects()


func _setup_ambient_effects() -> void:
	## El ambiente naranja/rojo del núcleo industrial se refleja
	## en la iluminación del nivel. Los Ukibukis tienen mayor
	## agresividad en este sector.
	pass


func _search_node(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node
	for child in node.get_children():
		var result := _search_node(child, target_name)
		if result:
			return result
	return null
