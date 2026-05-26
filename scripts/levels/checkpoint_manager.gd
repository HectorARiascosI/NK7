extends Node

## Checkpoint Manager
## Gestiona todos los checkpoints del nivel y el respawn del jugador

var _current_checkpoint_position : Vector2 = Vector2.ZERO
var _initial_spawn_position : Vector2 = Vector2.ZERO
var _player : Node2D = null
var _checkpoints : Array[Area2D] = []


func _ready() -> void:
	await get_tree().process_frame
	_find_player()
	_find_checkpoints()
	
	# Guardar posición inicial del jugador
	if _player:
		_initial_spawn_position = _player.global_position
		_current_checkpoint_position = _initial_spawn_position


func _find_player() -> void:
	var root := get_tree().root
	_player = _search_node(root, "kai")
	if not _player:
		push_error("CheckpointManager: No se encontró el jugador 'kai'")


func _find_checkpoints() -> void:
	# Buscar todos los nodos en el grupo "checkpoints"
	_checkpoints = []
	var checkpoint_nodes := get_tree().get_nodes_in_group("checkpoints")
	
	for node in checkpoint_nodes:
		if node is Area2D:
			_checkpoints.append(node)
			# Conectar señal de activación
			if node.has_signal("checkpoint_activated"):
				node.checkpoint_activated.connect(_on_checkpoint_activated)
	
	print("CheckpointManager: Encontrados %d checkpoints" % _checkpoints.size())


func _on_checkpoint_activated(checkpoint_position: Vector2) -> void:
	_current_checkpoint_position = checkpoint_position
	print("CheckpointManager: Checkpoint activado en ", checkpoint_position)
	
	# Opcional: Mostrar mensaje al jugador
	_show_checkpoint_message()


func respawn_player() -> void:
	"""Respawnear al jugador en el último checkpoint"""
	if not _player:
		_find_player()
	
	if _player:
		_player.global_position = _current_checkpoint_position
		
		# Resetear velocidad del jugador
		if _player.has("velocity"):
			_player.velocity = Vector2.ZERO
		
		print("CheckpointManager: Jugador respawneado en ", _current_checkpoint_position)


func reset_to_start() -> void:
	"""Resetear al inicio del nivel"""
	_current_checkpoint_position = _initial_spawn_position
	respawn_player()


func _show_checkpoint_message() -> void:
	# Aquí puedes añadir un mensaje visual si lo deseas
	# Por ejemplo, un label temporal que diga "Checkpoint guardado"
	pass


func _search_node(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node
	for child in node.get_children():
		var result := _search_node(child, target_name)
		if result:
			return result
	return null
