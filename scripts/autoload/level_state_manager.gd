extends Node

## ════════════════════════════════════════════════════════════════
## LEVEL STATE MANAGER
## ════════════════════════════════════════════════════════════════
## Gestiona el estado persistente de los niveles
## Guarda: posición del jugador, enemigos derrotados, puertas abiertas,
## coleccionables recogidos, interruptores activados, etc.
## ════════════════════════════════════════════════════════════════

# ══════════════════════════════════════════════════════════════════
# ESTADO DEL NIVEL ACTUAL
# ══════════════════════════════════════════════════════════════════

var current_level_state := {
	"player_position": Vector2.ZERO,
	"player_health": 100,
	"player_energy": 100,
	"player_durability": 100,
	"player_cubes": 0,
	"player_coins": 0,
	"player_keycards": [],
	
	"enemies_defeated": [],  # IDs de enemigos derrotados
	"doors_opened": [],  # IDs de puertas abiertas
	"collectibles_taken": [],  # IDs de coleccionables recogidos
	"switches_activated": [],  # IDs de interruptores activados
	"checkpoints_reached": [],  # IDs de checkpoints alcanzados
}

# ══════════════════════════════════════════════════════════════════
# GUARDADO Y CARGA
# ══════════════════════════════════════════════════════════════════

func save_level_state() -> Dictionary:
	"""Guardar estado actual del nivel"""
	var player := GameManager.get_player()
	
	if player:
		current_level_state["player_position"] = player.global_position
		
		if player.has_method("get_health_percent"):
			current_level_state["player_health"] = player.health
		if player.has_method("get_energy_percent"):
			current_level_state["player_energy"] = player.energy
		if player.has_method("get_tool_durability_percent"):
			current_level_state["player_durability"] = player.stamina
		if player.has_method("get_cubes_count"):
			current_level_state["player_cubes"] = player.cubes_collected
		if player.has_method("get_coins_count"):
			current_level_state["player_coins"] = player.coins_collected
		
		# Keycards
		if "keycards" in player:
			current_level_state["player_keycards"] = player.keycards.duplicate()
	
	return current_level_state.duplicate()

func load_level_state(state: Dictionary) -> void:
	"""Cargar estado del nivel"""
	if state.is_empty():
		return
	
	current_level_state = state.duplicate()
	
	# Esperar a que el nivel esté listo
	await get_tree().process_frame
	await get_tree().process_frame
	
	_restore_player_state()
	_restore_level_objects()

func _restore_player_state() -> void:
	"""Restaurar estado del jugador"""
	var player := GameManager.get_player()
	if not player:
		return
	
	# Posición
	if current_level_state.has("player_position"):
		player.global_position = current_level_state["player_position"]
	
	# Recursos
	if current_level_state.has("player_health"):
		player.health = float(current_level_state["player_health"])
	if current_level_state.has("player_energy"):
		player.energy = float(current_level_state["player_energy"])
	if current_level_state.has("player_durability"):
		player.stamina = float(current_level_state["player_durability"])
	
	# Coleccionables
	if current_level_state.has("player_cubes"):
		player.cubes_collected = current_level_state["player_cubes"]
	if current_level_state.has("player_coins"):
		player.coins_collected = current_level_state["player_coins"]
	if current_level_state.has("player_keycards"):
		player.keycards = current_level_state["player_keycards"].duplicate()

func _restore_level_objects() -> void:
	"""Restaurar estado de objetos del nivel"""
	# Eliminar enemigos derrotados
	for enemy_id in current_level_state.get("enemies_defeated", []):
		var enemy := _find_object_by_id(enemy_id)
		if enemy:
			enemy.queue_free()
	
	# Abrir puertas
	for door_id in current_level_state.get("doors_opened", []):
		var door := _find_object_by_id(door_id)
		if door and door.has_method("activate"):
			door.activate()
	
	# Eliminar coleccionables recogidos
	for collectible_id in current_level_state.get("collectibles_taken", []):
		var collectible := _find_object_by_id(collectible_id)
		if collectible:
			collectible.queue_free()
	
	# Activar interruptores
	for switch_id in current_level_state.get("switches_activated", []):
		var switch := _find_object_by_id(switch_id)
		if switch and switch.has_method("activate"):
			switch.activate()

func _find_object_by_id(object_id: String) -> Node:
	"""Buscar objeto por ID único"""
	return get_tree().root.find_child(object_id, true, false)

# ══════════════════════════════════════════════════════════════════
# REGISTRO DE EVENTOS
# ══════════════════════════════════════════════════════════════════

func register_enemy_defeated(enemy_id: String) -> void:
	"""Registrar enemigo derrotado"""
	if not enemy_id in current_level_state["enemies_defeated"]:
		current_level_state["enemies_defeated"].append(enemy_id)
		_auto_save()

func register_door_opened(door_id: String) -> void:
	"""Registrar puerta abierta"""
	if not door_id in current_level_state["doors_opened"]:
		current_level_state["doors_opened"].append(door_id)
		_auto_save()

func register_collectible_taken(collectible_id: String) -> void:
	"""Registrar coleccionable recogido"""
	if not collectible_id in current_level_state["collectibles_taken"]:
		current_level_state["collectibles_taken"].append(collectible_id)
		_auto_save()

func register_switch_activated(switch_id: String) -> void:
	"""Registrar interruptor activado"""
	if not switch_id in current_level_state["switches_activated"]:
		current_level_state["switches_activated"].append(switch_id)
		_auto_save()

func register_checkpoint_reached(checkpoint_id: String) -> void:
	"""Registrar checkpoint alcanzado"""
	if not checkpoint_id in current_level_state["checkpoints_reached"]:
		current_level_state["checkpoints_reached"].append(checkpoint_id)
		_auto_save()

# ══════════════════════════════════════════════════════════════════
# AUTO-GUARDADO
# ══════════════════════════════════════════════════════════════════

func _auto_save() -> void:
	"""Guardar automáticamente el progreso"""
	if GameManager.is_playing:
		GameManager.save_game()

func reset_level_state() -> void:
	"""Resetear estado del nivel (para nuevo nivel)"""
	current_level_state = {
		"player_position": Vector2.ZERO,
		"player_health": 100,
		"player_energy": 100,
		"player_durability": 100,
		"player_cubes": 0,
		"player_coins": 0,
		"player_keycards": [],
		"enemies_defeated": [],
		"doors_opened": [],
		"collectibles_taken": [],
		"switches_activated": [],
		"checkpoints_reached": [],
	}

# ══════════════════════════════════════════════════════════════════
# UTILIDADES
# ══════════════════════════════════════════════════════════════════

func is_enemy_defeated(enemy_id: String) -> bool:
	"""Verificar si un enemigo fue derrotado"""
	return enemy_id in current_level_state.get("enemies_defeated", [])

func is_door_opened(door_id: String) -> bool:
	"""Verificar si una puerta fue abierta"""
	return door_id in current_level_state.get("doors_opened", [])

func is_collectible_taken(collectible_id: String) -> bool:
	"""Verificar si un coleccionable fue recogido"""
	return collectible_id in current_level_state.get("collectibles_taken", [])

func is_switch_activated(switch_id: String) -> bool:
	"""Verificar si un interruptor fue activado"""
	return switch_id in current_level_state.get("switches_activated", [])

func is_checkpoint_reached(checkpoint_id: String) -> bool:
	"""Verificar si un checkpoint fue alcanzado"""
	return checkpoint_id in current_level_state.get("checkpoints_reached", [])
