extends Area2D

## Death Zone - Zona de muerte
## Cuando el jugador entra, muere y respawnea usando el sistema inteligente

var _smart_checkpoint_system : Node = null


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	await get_tree().process_frame
	_find_smart_checkpoint_system()


func _find_smart_checkpoint_system() -> void:
	var root := get_tree().root
	_smart_checkpoint_system = _search_node(root, "SmartCheckpointSystem")
	if not _smart_checkpoint_system:
		push_warning("DeathZone: No se encontró SmartCheckpointSystem")


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_kill_player(body)


func _kill_player(player: Node2D) -> void:
	# Registrar posición de muerte
	if _smart_checkpoint_system and _smart_checkpoint_system.has_method("register_death"):
		_smart_checkpoint_system.register_death(player.global_position)
	
	# Reproducir animación de muerte
	if player.has_node("AnimatedSprite2D"):
		var sprite = player.get_node("AnimatedSprite2D")
		sprite.play("dead")
	
	# Desactivar controles del jugador temporalmente
	player.set_physics_process(false)
	
	# Esperar 1 segundo y respawnear
	await get_tree().create_timer(1.0).timeout
	
	# Respawnear usando el sistema inteligente
	if _smart_checkpoint_system and _smart_checkpoint_system.has_method("respawn_player"):
		_smart_checkpoint_system.respawn_player()
		# Reactivar controles
		player.set_physics_process(true)
	else:
		# Fallback: recargar escena completa
		get_tree().reload_current_scene()


func _search_node(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node
	for child in node.get_children():
		var result := _search_node(child, target_name)
		if result:
			return result
	return null
