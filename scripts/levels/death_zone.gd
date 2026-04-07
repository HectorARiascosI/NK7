extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "kai":
		_kill_player(body)

func _kill_player(player: Node2D) -> void:
	# Reproducir animación de muerte
	if player.has_node("AnimatedSprite2D"):
		var sprite = player.get_node("AnimatedSprite2D")
		sprite.play("dead")
	
	# Desactivar controles del jugador
	player.set_physics_process(false)
	
	# Esperar 2 segundos y reiniciar nivel
	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()
