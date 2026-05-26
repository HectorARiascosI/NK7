extends CharacterBody2D
class_name Ukibuki

## ════════════════════════════════════════════════════════════════
## ROBOT ENEMIGO UKIBUKI — IA con Line-of-Sight
## ════════════════════════════════════════════════════════════════
## - Patrulla suavemente entre dos puntos
## - Detecta al jugador por rango Y por visión directa (raycast)
## - NO dispara si hay una estructura entre él y el jugador
## - Persigue al jugador moviéndose hacia él en estado ALERT
## - Flotación visual solo en el sprite (sin glitch de física)
## ════════════════════════════════════════════════════════════════

signal player_detected
signal player_lost
signal attacked
signal damaged(amount: int)
signal destroyed

# ══════════════════════════════════════════════════════════════════
# CONFIGURACIÓN EXPORTABLE
# ══════════════════════════════════════════════════════════════════

@export_group("Estadísticas")
@export var max_health     : int   = 60    ## 2 golpes de Kai (30 dmg c/u) = muerto
@export var damage         : int   = 22    ## Daño del fallback (sin proyectil)
@export var speed          : float = 80.0

@export_group("Identificación")
@export var unique_id      : String = ""

@export_group("Comportamiento")
@export var patrol_distance : float = 200.0  ## Distancia a cada lado del origen
@export var detection_range : float = 320.0  ## Rango de detección por proximidad
@export var attack_range    : float = 260.0  ## Rango máximo para disparar
@export var attack_cooldown : float = 2.2    ## Segundos entre disparos
@export var chase_speed_mult: float = 1.4    ## Multiplicador de velocidad al perseguir

@export_group("Flotación visual")
@export var float_amplitude : float = 7.0    ## Píxeles de oscilación vertical
@export var float_speed     : float = 1.8    ## Ciclos por segundo

@export_group("Proyectil")
@export var projectile_speed : float = 210.0
@export var projectile_scene : PackedScene

# ══════════════════════════════════════════════════════════════════
# NODOS
# ══════════════════════════════════════════════════════════════════

@onready var sprite         : AnimatedSprite2D    = $Sprite
@onready var collision      : CollisionShape2D    = $Collision
@onready var detection_area : Area2D              = $DetectionArea
@onready var attack_timer   : Timer               = $AttackTimer
@onready var particles      : GPUParticles2D      = $DamageParticles
@onready var light          : PointLight2D        = $Light
@onready var audio_alert    : AudioStreamPlayer2D = $AlertSound
@onready var audio_shoot    : AudioStreamPlayer2D = $ShootSound
@onready var audio_damage   : AudioStreamPlayer2D = $DamageSound

# ══════════════════════════════════════════════════════════════════
# ESTADO INTERNO
# ══════════════════════════════════════════════════════════════════

enum State { IDLE, PATROL, ALERT, CHASE, ATTACK, DAMAGED, DESTROYED }

var current_state    : State = State.PATROL
var current_health   : int
var player_reference : CharacterBody2D = null
var patrol_origin    : Vector2
var patrol_direction : int   = 1
var can_attack       : bool  = true
var _time            : float = 0.0

## Pausa breve al girar en patrulla
var _patrol_pause_timer : float = 0.0
const PATROL_PAUSE_TIME : float = 0.35

## Tiempo sin ver al jugador antes de volver a patrullar
var _lost_sight_timer   : float = 0.0
const LOST_SIGHT_TIMEOUT: float = 2.5

## Última posición conocida del jugador (para perseguir aunque lo pierda de vista)
var _last_known_player_pos : Vector2 = Vector2.ZERO

## Capas de física que bloquean la visión (TileMap, StaticBody2D, etc.)
## Ajusta este valor según las collision layers de tu proyecto
const LOS_COLLISION_MASK : int = 1   ## Layer 1 = geometría del mundo

# ══════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ══════════════════════════════════════════════════════════════════

func _ready() -> void:
	current_health = max_health
	patrol_origin  = global_position
	_time          = randf() * TAU

	if unique_id.is_empty():
		unique_id = "ukibuki_%s_%d" % [name, get_instance_id()]

	if LevelStateManager.is_enemy_defeated(unique_id):
		queue_free()
		return

	# Pausable: se detiene con get_tree().paused = true
	process_mode = Node.PROCESS_MODE_PAUSABLE

	_setup_detection()
	_setup_timer()
	_setup_visuals()
	add_to_group("enemies")

func _setup_detection() -> void:
	if detection_area:
		detection_area.body_entered.connect(_on_detection_entered)
		detection_area.body_exited.connect(_on_detection_exited)

func _setup_timer() -> void:
	if attack_timer:
		attack_timer.wait_time = attack_cooldown
		attack_timer.one_shot  = false
		attack_timer.timeout.connect(_on_attack_ready)
		attack_timer.start()

func _setup_visuals() -> void:
	if light:
		light.color  = Color(1.0, 0.3, 0.3)
		light.energy = 1.2

# ══════════════════════════════════════════════════════════════════
# PROCESO PRINCIPAL
# ══════════════════════════════════════════════════════════════════

func _physics_process(delta: float) -> void:
	if current_state == State.DESTROYED:
		return

	_time += delta

	# ── Flotación SOLO en el sprite visual ───────────────────────
	if sprite:
		sprite.position.y = sin(_time * float_speed) * float_amplitude

	# ── Pausa al girar ────────────────────────────────────────────
	if _patrol_pause_timer > 0.0:
		_patrol_pause_timer -= delta
		velocity.x = move_toward(velocity.x, 0.0, speed * 6.0 * delta)
		velocity.y = 0.0
		move_and_slide()
		_update_animation()
		return

	# ── Máquina de estados ────────────────────────────────────────
	match current_state:
		State.IDLE:    _state_idle(delta)
		State.PATROL:  _state_patrol(delta)
		State.ALERT:   _state_alert(delta)
		State.CHASE:   _state_chase(delta)
		State.ATTACK:  _state_attack(delta)
		State.DAMAGED: pass

	velocity.y = 0.0   # Sin gravedad — robot flotante
	move_and_slide()
	_update_animation()

# ══════════════════════════════════════════════════════════════════
# LINE-OF-SIGHT — ¿puede ver al jugador?
# ══════════════════════════════════════════════════════════════════

func _has_line_of_sight() -> bool:
	"""Lanza un raycast desde el robot hasta el jugador.
	   Retorna true solo si no hay geometría sólida en el camino."""
	if not player_reference or not is_instance_valid(player_reference):
		return false

	var space  := get_world_2d().direct_space_state
	var origin := global_position
	var target := player_reference.global_position

	var query := PhysicsRayQueryParameters2D.create(origin, target, LOS_COLLISION_MASK)
	query.exclude = [self]   # No colisionar consigo mismo

	var result := space.intersect_ray(query)

	# Si el raycast no golpeó nada, hay línea de visión directa
	if result.is_empty():
		return true

	# Si golpeó al propio jugador (CharacterBody2D), también hay visión
	if result.has("collider") and result["collider"] == player_reference:
		return true

	# Golpeó una estructura — sin visión
	return false

func _can_see_player() -> bool:
	"""Combina rango de detección + line-of-sight."""
	return _is_player_in_range(detection_range) and _has_line_of_sight()

func _can_attack_player() -> bool:
	"""Puede atacar: en rango de ataque Y con visión directa."""
	return _is_player_in_range(attack_range) and _has_line_of_sight()

# ══════════════════════════════════════════════════════════════════
# ESTADOS
# ══════════════════════════════════════════════════════════════════

func _state_idle(_delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, speed * 2.0)
	if _can_see_player():
		_change_state(State.ALERT)

func _state_patrol(delta: float) -> void:
	var target_vx : float = patrol_direction * speed
	velocity.x = move_toward(velocity.x, target_vx, speed * 3.0 * delta)

	var dist : float = global_position.x - patrol_origin.x
	if patrol_direction > 0 and dist >= patrol_distance:
		_flip_patrol()
	elif patrol_direction < 0 and dist <= -patrol_distance:
		_flip_patrol()

	if _can_see_player():
		_change_state(State.ALERT)

func _flip_patrol() -> void:
	patrol_direction    *= -1
	_patrol_pause_timer  = PATROL_PAUSE_TIME
	if sprite:
		sprite.flip_h = patrol_direction < 0

func _state_alert(delta: float) -> void:
	"""Detectó al jugador — se orienta y decide si perseguir o atacar."""
	velocity.x = move_toward(velocity.x, 0.0, speed * 3.0 * delta)

	if not player_reference or not is_instance_valid(player_reference):
		_change_state(State.PATROL)
		return

	# Guardar última posición conocida
	_last_known_player_pos = player_reference.global_position

	var can_see : bool = _can_see_player()

	if not can_see:
		# Perdió la visión — esperar un momento antes de rendirse
		_lost_sight_timer += delta
		if _lost_sight_timer >= LOST_SIGHT_TIMEOUT:
			_lost_sight_timer = 0.0
			_change_state(State.PATROL)
		return

	_lost_sight_timer = 0.0

	# Orientarse hacia el jugador
	_face_player()

	# Decidir acción
	if _can_attack_player():
		_change_state(State.ATTACK)
	elif _is_player_in_range(detection_range):
		_change_state(State.CHASE)

func _state_chase(delta: float) -> void:
	"""Persigue al jugador moviéndose hacia él."""
	if not player_reference or not is_instance_valid(player_reference):
		_change_state(State.PATROL)
		return

	var can_see : bool = _can_see_player()

	if can_see:
		_last_known_player_pos = player_reference.global_position
		_lost_sight_timer      = 0.0
	else:
		_lost_sight_timer += delta
		if _lost_sight_timer >= LOST_SIGHT_TIMEOUT:
			_lost_sight_timer = 0.0
			_change_state(State.PATROL)
			return

	# Moverse hacia la última posición conocida
	var dir_to_player : float = sign(_last_known_player_pos.x - global_position.x)
	var chase_spd     : float = speed * chase_speed_mult
	velocity.x = move_toward(velocity.x, dir_to_player * chase_spd, chase_spd * 3.0 * delta)

	if sprite:
		sprite.flip_h = dir_to_player < 0.0

	# Si llega a la última posición conocida sin ver al jugador → patrullar
	if not can_see and global_position.distance_to(_last_known_player_pos) < 20.0:
		_change_state(State.PATROL)
		return

	# Si puede atacar, atacar
	if _can_attack_player():
		_change_state(State.ATTACK)

func _state_attack(delta: float) -> void:
	"""Ataca al jugador si tiene línea de visión."""
	velocity.x = move_toward(velocity.x, 0.0, speed * 3.0 * delta)

	if not player_reference or not is_instance_valid(player_reference):
		_change_state(State.PATROL)
		return

	# ── VERIFICAR LÍNEA DE VISIÓN antes de disparar ───────────────
	if not _can_attack_player():
		# Perdió visión o el jugador se cubrió
		if _can_see_player():
			_change_state(State.ALERT)
		elif _is_player_in_range(detection_range):
			_change_state(State.CHASE)   # Perseguir aunque no vea
		else:
			_change_state(State.PATROL)
		return

	_face_player()

	if can_attack:
		_shoot()

func _face_player() -> void:
	if not player_reference:
		return
	var dir : float = sign(player_reference.global_position.x - global_position.x)
	if sprite and dir != 0.0:
		sprite.flip_h = dir < 0.0

# ══════════════════════════════════════════════════════════════════
# CAMBIO DE ESTADO
# ══════════════════════════════════════════════════════════════════

func _change_state(new_state: State) -> void:
	var old_state := current_state
	current_state  = new_state

	match new_state:
		State.ALERT:
			_lost_sight_timer = 0.0
			if old_state not in [State.ATTACK, State.CHASE, State.ALERT]:
				player_detected.emit()
				if audio_alert:
					audio_alert.play()
				elif has_node("/root/AudioManager"):
					AudioManager.play_sfx_at("ukibuki_alert", global_position)
			if light:
				light.color = Color(1.0, 0.5, 0.0)   # Naranja — alerta

		State.CHASE:
			if light:
				light.color = Color(1.0, 0.65, 0.0)  # Naranja intenso — persiguiendo

		State.ATTACK:
			attacked.emit()
			if light:
				light.color = Color(1.0, 0.2, 0.2)   # Rojo brillante — atacando

		State.PATROL:
			_lost_sight_timer = 0.0
			if old_state in [State.ALERT, State.ATTACK, State.CHASE]:
				player_lost.emit()
			if light:
				light.color = Color(1.0, 0.3, 0.3)   # Rojo — patrullando

# ══════════════════════════════════════════════════════════════════
# COMBATE
# ══════════════════════════════════════════════════════════════════

func _shoot() -> void:
	if not player_reference:
		return

	can_attack = false

	if audio_shoot:
		audio_shoot.play()
	elif has_node("/root/AudioManager"):
		AudioManager.play_sfx_at("ukibuki_shoot", global_position)

	if projectile_scene:
		var projectile : Node = projectile_scene.instantiate()
		get_parent().add_child(projectile)
		projectile.global_position = global_position

		# Pasar referencia del robot para el sistema de parry
		if projectile.has_method("set_owner_node"):
			projectile.set_owner_node(self)
		if projectile.has_method("set_owner_id"):
			projectile.set_owner_id(get_instance_id())

		var direction := (player_reference.global_position - global_position).normalized()
		if projectile.has_method("set_direction"):
			projectile.set_direction(direction, projectile_speed)
		elif projectile.has_method("set_velocity"):
			projectile.set_velocity(direction * projectile_speed)
	else:
		if player_reference.has_method("take_damage"):
			player_reference.take_damage(damage)

func take_damage(amount: int) -> void:
	if current_state == State.DESTROYED:
		return

	current_health -= amount
	damaged.emit(amount)

	if particles:
		particles.emitting = true

	if audio_damage:
		audio_damage.play()
	elif has_node("/root/AudioManager"):
		AudioManager.play_sfx_at("ukibuki_damage", global_position)

	if sprite:
		sprite.modulate = Color(1.6, 0.4, 0.4)
		var tween := create_tween()
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.25)

	if current_health <= 0:
		_destroy()
	else:
		_change_state_damaged()

func _change_state_damaged() -> void:
	current_state = State.DAMAGED
	velocity.x    = 0.0
	get_tree().create_timer(0.5).timeout.connect(_exit_damaged_state)

func _exit_damaged_state() -> void:
	if current_state != State.DAMAGED:
		return
	if _can_see_player():
		_change_state(State.ALERT)
	elif player_reference and _is_player_in_range(detection_range):
		_change_state(State.CHASE)
	else:
		_change_state(State.PATROL)

func _destroy() -> void:
	current_state = State.DESTROYED
	destroyed.emit()

	LevelStateManager.register_enemy_defeated(unique_id)

	if has_node("/root/AchievementManager"):
		AchievementManager.increment_counter("enemies_killed")

	# Desactivar colisión inmediatamente
	if collision:
		collision.set_deferred("disabled", true)

	# Detener movimiento
	velocity = Vector2.ZERO

	# Animación de explosión
	if sprite:
		sprite.position = Vector2.ZERO   # Resetear offset de flotación
		sprite.modulate = Color.WHITE
		# Intentar animación "explosion", si no existe usar flash y escala
		if sprite.sprite_frames and sprite.sprite_frames.has_animation("explosion"):
			sprite.play("explosion")
		else:
			# Fallback: escalar y desvanecer
			var tw := create_tween()
			tw.set_parallel(true)
			tw.tween_property(sprite, "scale", Vector2(2.5, 2.5), 0.3)
			tw.tween_property(sprite, "modulate", Color(2.0, 1.0, 0.0, 0.0), 0.4)

	# Luz explota
	if light:
		var tween := create_tween()
		tween.tween_property(light, "energy", 6.0, 0.1)
		tween.tween_property(light, "energy", 0.0, 0.4)

	# Partículas
	if particles:
		particles.emitting = true

	if has_node("/root/AudioManager"):
		AudioManager.play_sfx_at("ukibuki_destroy", global_position)

	if has_node("/root/GameManager"):
		GameManager.add_score(500)
		GameManager.shake_camera(8.0, 0.35)

	# Esperar a que termine la animación antes de eliminar
	await get_tree().create_timer(1.2).timeout
	queue_free()

func _on_attack_ready() -> void:
	can_attack = true

# ══════════════════════════════════════════════════════════════════
# DETECCIÓN
# ══════════════════════════════════════════════════════════════════

func _on_detection_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "kai":
		player_reference = body

func _on_detection_exited(body: Node2D) -> void:
	if body == player_reference:
		player_reference = null

func _is_player_in_range(check_range: float) -> bool:
	if not player_reference or not is_instance_valid(player_reference):
		return false
	return global_position.distance_to(player_reference.global_position) <= check_range

# ══════════════════════════════════════════════════════════════════
# ANIMACIÓN
# ══════════════════════════════════════════════════════════════════

func _update_animation() -> void:
	if not sprite:
		return
	match current_state:
		State.IDLE:      sprite.play("idle")
		State.PATROL:    sprite.play("move")
		State.ALERT:     sprite.play("alert")
		State.CHASE:     sprite.play("move")
		State.ATTACK:    sprite.play("shoot")
		State.DAMAGED:   sprite.play("damage")
		State.DESTROYED: sprite.play("explosion")

# ══════════════════════════════════════════════════════════════════
# API PÚBLICA
# ══════════════════════════════════════════════════════════════════

func get_health_percent() -> float:
	return float(current_health) / float(max_health)

func is_alive() -> bool:
	return current_state != State.DESTROYED

func set_patrol_distance(distance: float) -> void:
	patrol_distance = distance

func set_aggro(enabled: bool) -> void:
	if enabled:
		if current_state == State.IDLE:
			_change_state(State.PATROL)
	else:
		if current_state in [State.ALERT, State.ATTACK, State.CHASE]:
			_change_state(State.IDLE)
