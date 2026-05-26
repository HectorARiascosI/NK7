extends Node

## Smart Checkpoint System
## Sistema inteligente que respawnea al jugador en la zona segura más cercana
## NO en checkpoints específicos, sino donde murió (si es seguro)

signal player_respawned(position: Vector2)

var _player : Node2D = null
var _safe_zones : Array[Dictionary] = []  # Zonas seguras del nivel
var _last_safe_position : Vector2 = Vector2.ZERO
var _death_position : Vector2 = Vector2.ZERO
var _initial_spawn : Vector2 = Vector2.ZERO


func _ready() -> void:
	await get_tree().process_frame
	_find_player()
	_find_safe_zones()
	
	if _player:
		_initial_spawn = _player.global_position
		_last_safe_position = _initial_spawn


func _find_player() -> void:
	_player = _search_node(get_tree().root, "kai")
	if not _player:
		push_error("SmartCheckpointSystem: No se encontró el jugador")


func _find_safe_zones() -> void:
	"""Encuentra todas las zonas seguras marcadas en el nivel"""
	_safe_zones.clear()
	
	# Buscar nodos en el grupo "safe_zones"
	var safe_zone_nodes := get_tree().get_nodes_in_group("safe_zones")
	
	for node in safe_zone_nodes:
		if node is Area2D:
			var zone_data := {
				"node": node,
				"position": node.global_position,
				"bounds": _get_area_bounds(node)
			}
			_safe_zones.append(zone_data)
			
			# Conectar señales para detectar cuando el jugador entra
			if not node.body_entered.is_connected(_on_player_entered_safe_zone):
				node.body_entered.connect(_on_player_entered_safe_zone.bind(node))
	
	print("SmartCheckpointSystem: Encontradas %d zonas seguras" % _safe_zones.size())


func _get_area_bounds(area: Area2D) -> Rect2:
	"""Obtiene los límites de un Area2D"""
	var shapes := area.get_children()
	for child in shapes:
		if child is CollisionShape2D:
			var collision_shape := child as CollisionShape2D
			if collision_shape.shape == null:
				continue
			var shape : Shape2D = collision_shape.shape
			if shape is RectangleShape2D:
				var rect_shape := shape as RectangleShape2D
				var size := rect_shape.size
				var pos : Vector2 = area.global_position + collision_shape.position
				return Rect2(pos - size / 2, size)
	return Rect2(area.global_position, Vector2(100, 100))


func _on_player_entered_safe_zone(body: Node2D, _zone: Area2D) -> void:
	"""Cuando el jugador entra en una zona segura, actualizar última posición segura"""
	if body.is_in_group("player"):
		_last_safe_position = body.global_position
		
		# Logro y sonido de checkpoint
		if has_node("/root/AchievementManager"):
			AchievementManager.increment_counter("checkpoints_reached")
		if has_node("/root/AudioManager"):
			AudioManager.play_sfx("checkpoint")
		
		print("SmartCheckpointSystem: Zona segura actualizada en ", _last_safe_position)


func register_death(death_pos: Vector2) -> void:
	"""Registra la posición donde murió el jugador"""
	_death_position = death_pos
	print("SmartCheckpointSystem: Muerte registrada en ", death_pos)


func respawn_player() -> void:
	"""Respawnea al jugador en la mejor posición"""
	if not _player:
		_find_player()
	
	if not _player:
		return
	
	# Determinar la mejor posición de respawn
	var respawn_pos := _calculate_best_respawn_position()
	
	# IMPORTANTE: Ajustar Y para que esté sobre el suelo
	# Hacer un raycast hacia abajo para encontrar el suelo
	respawn_pos = _find_ground_below(respawn_pos)
	
	# Respawnear
	_player.global_position = respawn_pos
	
	# Resetear velocidad si la propiedad existe
	if "velocity" in _player:
		_player.velocity = Vector2.ZERO
	
	player_respawned.emit(respawn_pos)
	print("SmartCheckpointSystem: Jugador respawneado en ", respawn_pos)


func _find_ground_below(pos: Vector2) -> Vector2:
	"""Encuentra el suelo sólido debajo de una posición usando raycast"""
	var space_state := _player.get_world_2d().direct_space_state
	
	# Raycast hacia abajo desde la posición
	var query := PhysicsRayQueryParameters2D.create(pos, pos + Vector2(0, 1000))
	query.collision_mask = 1  # Layer 1 (suelos)
	query.collide_with_areas = false  # NO detectar escaleras (que son Areas)
	query.collide_with_bodies = true  # SÍ detectar StaticBody2D (suelos)
	
	var result := space_state.intersect_ray(query)
	
	if result:
		# Verificar que NO sea una escalera
		var collider = result.collider
		if collider and not collider.is_in_group("ladders"):
			# Encontró suelo sólido, posicionar justo encima
			return result.position + Vector2(0, -35)  # 35 píxeles arriba del suelo
	
	# No encontró suelo válido, buscar la zona segura más cercana
	print("SmartCheckpointSystem: ADVERTENCIA - No se encontró suelo sólido debajo de ", pos)
	return get_nearest_safe_zone(pos)


func _calculate_best_respawn_position() -> Vector2:
	"""Calcula la mejor posición de respawn basándose en dónde murió"""
	
	# Si murió en una zona segura, respawnear ahí
	if _is_position_in_safe_zone(_death_position):
		return _death_position
	
	# Si no, respawnear en la última zona segura conocida
	if _last_safe_position != Vector2.ZERO:
		return _last_safe_position
	
	# Fallback: posición inicial
	return _initial_spawn


func _is_position_in_safe_zone(pos: Vector2) -> bool:
	"""Verifica si una posición está dentro de alguna zona segura"""
	for zone_data in _safe_zones:
		var bounds : Rect2 = zone_data["bounds"]
		if bounds.has_point(pos):
			return true
	return false


func get_nearest_safe_zone(pos: Vector2) -> Vector2:
	"""Encuentra la zona segura más cercana a una posición"""
	if _safe_zones.is_empty():
		return _initial_spawn
	
	var nearest_pos : Vector2 = _safe_zones[0]["position"]
	var nearest_dist := pos.distance_to(nearest_pos)
	
	for zone_data in _safe_zones:
		var zone_pos : Vector2 = zone_data["position"]
		var dist := pos.distance_to(zone_pos)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest_pos = zone_pos
	
	return nearest_pos


func reset_to_start() -> void:
	"""Resetear al inicio del nivel"""
	_last_safe_position = _initial_spawn
	respawn_player()


func _search_node(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node
	for child in node.get_children():
		var result := _search_node(child, target_name)
		if result:
			return result
	return null
