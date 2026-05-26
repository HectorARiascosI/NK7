extends Area2D

## Sistema de Checkpoint
## Se activa automáticamente cuando el jugador entra en el área
## Guarda la posición de respawn

signal checkpoint_activated(checkpoint_position: Vector2)

@export var checkpoint_id : int = 0  # ID único del checkpoint
@export var show_feedback : bool = true  # Mostrar mensaje al activar

var _activated : bool = false
var _sprite : Sprite2D
var _particles : CPUParticles2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_create_visual_feedback()


func _create_visual_feedback() -> void:
	# Crear sprite visual del checkpoint
	_sprite = Sprite2D.new()
	_sprite.modulate = Color(0.0, 0.8, 1.0, 0.6)  # Azul translúcido
	add_child(_sprite)
	
	# Crear partículas para feedback visual
	_particles = CPUParticles2D.new()
	_particles.emitting = false
	_particles.one_shot = true
	_particles.amount = 20
	_particles.lifetime = 0.8
	_particles.explosiveness = 0.8
	_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	_particles.emission_sphere_radius = 20.0
	_particles.direction = Vector2(0, -1)
	_particles.spread = 45.0
	_particles.gravity = Vector2(0, 200)
	_particles.initial_velocity_min = 50.0
	_particles.initial_velocity_max = 100.0
	_particles.scale_amount_min = 2.0
	_particles.scale_amount_max = 4.0
	_particles.color = Color(0.0, 1.0, 0.8, 1.0)
	add_child(_particles)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not _activated:
		activate()


func activate() -> void:
	if _activated:
		return
	
	_activated = true
	
	# Emitir señal con la posición del checkpoint
	checkpoint_activated.emit(global_position)
	
	# Feedback visual
	if show_feedback:
		_show_activation_feedback()
	
	# Cambiar color del sprite
	if _sprite:
		_sprite.modulate = Color(0.0, 1.0, 0.5, 0.8)  # Verde brillante


func _show_activation_feedback() -> void:
	# Emitir partículas
	if _particles:
		_particles.emitting = true
	
	# Animación de escala
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.2)
	tween.tween_property(self, "modulate:a", 1.0, 0.2)
	tween.chain()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.3)
	tween.tween_property(self, "modulate:a", 0.7, 0.3)


func reset() -> void:
	"""Resetear el checkpoint (útil para testing)"""
	_activated = false
	if _sprite:
		_sprite.modulate = Color(0.0, 0.8, 1.0, 0.6)
