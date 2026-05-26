extends Area2D
class_name Collectible

## ════════════════════════════════════════════════════════════════
## SISTEMA DE COLECCIONABLES NK-7
## ════════════════════════════════════════════════════════════════
## Base para todos los coleccionables del juego
## Tipos: CUBE (holográfico), CARD (tarjeta), ENERGY (tubo), COIN (engranaje)
## ════════════════════════════════════════════════════════════════

signal collected(type: CollectibleType, value: int)

# ══════════════════════════════════════════════════════════════════
# TIPOS DE COLECCIONABLES
# ══════════════════════════════════════════════════════════════════

enum CollectibleType {
	CUBE,      # Cubos holográficos azules (coleccionable principal)
	CARD,      # Tarjetas doradas/chips (para puertas y puntuación)
	ENERGY,    # Tubos de energía cyan (restaura energía)
	COIN       # Monedas/engranajes dorados (puntuación)
}

# ══════════════════════════════════════════════════════════════════
# CONFIGURACIÓN
# ══════════════════════════════════════════════════════════════════

@export_group("Identificación")
@export var unique_id : String = ""  ## ID único para persistencia

@export_group("Tipo")
@export var collectible_type : CollectibleType = CollectibleType.CUBE

@export_group("Valores")
@export var value : int = 1  ## Valor del coleccionable
@export var energy_restore : int = 25  ## Energía restaurada (solo ENERGY)
@export var keycard_id : String = ""  ## ID de tarjeta (solo CARD)

@export_group("Comportamiento")
@export var auto_collect : bool = true  ## Recolectar automáticamente al tocar
@export var respawn : bool = false  ## Reaparecer después de un tiempo
@export var respawn_time : float = 30.0

@export_group("Efectos")
@export var float_amplitude : float = 8.0  ## Amplitud de flotación
@export var float_speed : float = 2.0  ## Velocidad de flotación
@export var rotation_speed : float = 90.0  ## Velocidad de rotación (grados/seg)

# ══════════════════════════════════════════════════════════════════
# NODOS
# ══════════════════════════════════════════════════════════════════

@onready var sprite : AnimatedSprite2D = $Sprite
@onready var collision : CollisionShape2D = $Collision
@onready var particles : GPUParticles2D = $CollectParticles
@onready var light : PointLight2D = $Light
@onready var audio : AudioStreamPlayer2D = $CollectSound

# ══════════════════════════════════════════════════════════════════
# ESTADO
# ══════════════════════════════════════════════════════════════════

var is_collected : bool = false
var _initial_position : Vector2
var _time : float = 0.0

# ══════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ══════════════════════════════════════════════════════════════════

func _ready() -> void:
	_initial_position = position
	_setup_visuals()
	_connect_signals()
	
	# Generar ID único si no tiene
	if unique_id.is_empty():
		unique_id = "collectible_%s_%d" % [name, get_instance_id()]
	
	# Verificar si ya fue recogido
	if LevelStateManager.is_collectible_taken(unique_id):
		queue_free()
		return
	
	# Offset aleatorio para variación
	_time = randf() * TAU

func _setup_visuals() -> void:
	if not sprite:
		return
	
	# Configurar animación según tipo
	match collectible_type:
		CollectibleType.CUBE:
			sprite.play("cube")
			if light:
				light.color = Color(0.3, 0.7, 1.0)  # Azul cyan
				light.energy = 1.2
		
		CollectibleType.CARD:
			sprite.play("card")
			if light:
				light.color = Color(1.0, 0.85, 0.3)  # Dorado
				light.energy = 1.5
		
		CollectibleType.ENERGY:
			sprite.play("energy")
			if light:
				light.color = Color(0.2, 1.0, 0.9)  # Cyan brillante
				light.energy = 1.8
		
		CollectibleType.COIN:
			sprite.play("coin")
			if light:
				light.color = Color(1.0, 0.75, 0.2)  # Dorado
				light.energy = 1.0

func _connect_signals() -> void:
	body_entered.connect(_on_body_entered)

# ══════════════════════════════════════════════════════════════════
# PROCESO
# ══════════════════════════════════════════════════════════════════

func _process(delta: float) -> void:
	if is_collected:
		return
	
	_time += delta
	
	# Flotación vertical
	var float_offset : float = sin(_time * float_speed) * float_amplitude
	position.y = _initial_position.y + float_offset
	
	# Rotación
	if sprite:
		sprite.rotation_degrees += rotation_speed * delta
	
	# Pulso de luz
	if light:
		var pulse := 1.0 + sin(_time * 3.0) * 0.3
		light.energy = light.energy * pulse

# ══════════════════════════════════════════════════════════════════
# RECOLECCIÓN
# ══════════════════════════════════════════════════════════════════

func _on_body_entered(body: Node2D) -> void:
	if is_collected:
		return
	
	if not (body.is_in_group("player") or body.name == "kai"):
		return
	
	if auto_collect:
		collect(body)

func collect(collector: Node2D) -> void:
	"""Recolectar el objeto"""
	if is_collected:
		return
	
	is_collected = true
	
	# Registrar en el sistema de persistencia
	LevelStateManager.register_collectible_taken(unique_id)
	
	# Aplicar efectos según tipo
	match collectible_type:
		CollectibleType.CUBE:
			_collect_cube(collector)
		
		CollectibleType.CARD:
			_collect_card(collector)
		
		CollectibleType.ENERGY:
			_collect_energy(collector)
		
		CollectibleType.COIN:
			_collect_coin(collector)
	
	# Efectos visuales y sonoros
	_play_collect_effects()
	
	# Emitir señal
	collected.emit(collectible_type, value)
	
	# Ocultar
	_hide_collectible()
	
	# Respawn o eliminar
	if respawn:
		await get_tree().create_timer(respawn_time).timeout
		_respawn()
	else:
		await get_tree().create_timer(1.0).timeout
		queue_free()

func _collect_cube(collector: Node2D) -> void:
	"""Recolectar cubo holográfico"""
	# Añadir al inventario de cubos
	if collector.has_method("add_cube"):
		collector.add_cube(value)
	
	# Añadir puntos
	if GameManager.has_method("add_score"):
		GameManager.add_score(100 * value)

func _collect_card(collector: Node2D) -> void:
	"""Recolectar tarjeta de acceso"""
	# Añadir tarjeta al inventario
	if collector.has_method("add_keycard"):
		collector.add_keycard(keycard_id)
	
	# Añadir puntos
	if GameManager.has_method("add_score"):
		GameManager.add_score(250 * value)

func _collect_energy(collector: Node2D) -> void:
	"""Recolectar tubo de energía"""
	# Restaurar energía
	if collector.has_method("restore_energy"):
		collector.restore_energy(energy_restore)
	
	# Añadir puntos
	if GameManager.has_method("add_score"):
		GameManager.add_score(50 * value)

func _collect_coin(collector: Node2D) -> void:
	"""Recolectar moneda/engranaje"""
	if GameManager.has_method("add_score"):
		GameManager.add_score(25 * value)
	if has_node("/root/AchievementManager"):
		AchievementManager.increment_counter("coins_collected", value)
	# Usar el método oficial para que el HUD lo refleje
	if collector.has_method("add_coin"):
		collector.add_coin(value)
	elif "coins_collected" in collector:
		collector.coins_collected += value

# ══════════════════════════════════════════════════════════════════
# EFECTOS
# ══════════════════════════════════════════════════════════════════

func _play_collect_effects() -> void:
	"""Reproducir efectos de recolección"""
	# Partículas
	if particles:
		particles.emitting = true
	
	# Sonido procedural según tipo
	if has_node("/root/AudioManager"):
		match collectible_type:
			CollectibleType.CUBE:   AudioManager.play_sfx("cube")
			CollectibleType.CARD:   AudioManager.play_sfx("keycard")
			CollectibleType.ENERGY: AudioManager.play_sfx("energy")
			CollectibleType.COIN:   AudioManager.play_sfx("coin")
	elif audio:
		audio.play()
	
	# Animación sutil: sube y desaparece, sin zoom
	if sprite:
		var tween := create_tween().set_parallel(true)
		tween.tween_property(sprite, "modulate:a", 0.0, 0.25)
		tween.tween_property(self, "position:y", position.y - 20, 0.25).set_ease(Tween.EASE_OUT)
	
	# Luz se apaga suavemente
	if light:
		var tween := create_tween()
		tween.tween_property(light, "energy", 0.0, 0.25)

func _hide_collectible() -> void:
	"""Ocultar coleccionable"""
	if collision:
		collision.set_deferred("disabled", true)
	
	# Mantener visible para animación
	visible = true

func _respawn() -> void:
	"""Reaparecer coleccionable"""
	is_collected = false
	position = _initial_position
	
	if collision:
		collision.disabled = false
	
	if sprite:
		sprite.scale = Vector2.ONE
		sprite.modulate.a = 1.0
	
	if light:
		_setup_visuals()
	
	# Animación de reaparición
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)

# ══════════════════════════════════════════════════════════════════
# API PÚBLICA
# ══════════════════════════════════════════════════════════════════

func get_collectible_name() -> String:
	"""Obtener nombre del coleccionable"""
	match collectible_type:
		CollectibleType.CUBE:
			return "Cubo Holográfico"
		CollectibleType.CARD:
			return "Tarjeta de Acceso"
		CollectibleType.ENERGY:
			return "Tubo de Energía"
		CollectibleType.COIN:
			return "Engranaje"
	return "Coleccionable"

func get_description() -> String:
	"""Obtener descripción del coleccionable"""
	match collectible_type:
		CollectibleType.CUBE:
			return "Cubo de datos holográfico. Coleccionable principal."
		CollectibleType.CARD:
			return "Tarjeta de acceso. Abre puertas bloqueadas."
		CollectibleType.ENERGY:
			return "Tubo de energía. Restaura %d de energía." % energy_restore
		CollectibleType.COIN:
			return "Engranaje. Aumenta tu puntuación."
	return ""
