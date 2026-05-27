extends CharacterBody2D
class_name Guardia

## ════════════════════════════════════════════════════════════════
## GUARDIA DE SEGURIDAD — Enemigo terrestre NK-7
## ════════════════════════════════════════════════════════════════
## Diferencias vs Ukibuki (robot flotante):
##   - Camina por el suelo (tiene gravedad)
##   - Más lento pero más resistente
##   - Dispara en ráfaga corta (2 disparos seguidos)
##   - No flota — animación de caminar normal
##   - Rango de detección menor (visión más limitada)
## ════════════════════════════════════════════════════════════════

signal player_detected
signal player_lost
signal attacked
signal damaged(amount: int)
signal destroyed

# ── Configuración ─────────────────────────────────────────────────
@export_group("Estadísticas")
@export var max_health      : int   = 80     ## Más resistente que Ukibuki (60)
@export var damage          : int   = 18
@export var speed           : float = 65.0   ## Más lento — es terrestre

@export_group("Identificación")
@export var unique_id       : String = ""

@export_group("Comportamiento")
@export var patrol_distance : float = 180.0
@export var detection_range : float = 260.0  ## Menor que Ukibuki — visión más corta
@export var attack_range    : float = 220.0
@export var attack_cooldown : float = 2.8    ## Más lento para disparar
@export var chase_speed_mult: float = 1.3

@export_group("Proyectil")
@export var projectile_speed : float = 180.0
@export var projectile_scene : PackedScene

# ── Física ────────────────────────────────────────────────────────
const GRAVITY       : float = 980.0
const FALL_MULT     : float = 1.2
const LOS_MASK      : int   = 1

# ── Nodos ─────────────────────────────────────────────────────────
@onready var sprite         : AnimatedSprite2D    = $Sprite
@onready var collision      : CollisionShape2D    = $Collision
@onready var detection_area : Area2D              = $DetectionArea
@onready var attack_timer   : Timer               = $AttackTimer
@onready var light          : PointLight2D        = $Light

# ── Estado ────────────────────────────────────────────────────────
enum State { IDLE, PATROL, ALERT, CHASE, ATTACK, DAMAGED, DESTROYED }

var current_state    : State = State.PATROL
var current_health   : int
var player_reference : CharacterBody2D = null
var patrol_origin    : Vector2
var patrol_direction : int   = 1
var can_attack       : bool  = true

var _patrol_pause    : float = 0.0
const PATROL_PAUSE   : float = 0.4
var _lost_sight      : float = 0.0
const LOST_TIMEOUT   : float = 2.0
var _last_known_pos  : Vector2 = Vector2.ZERO

# ══════════════════════════════════════════════════════════════════

func _ready() -> void:
	current_health = max_health
	patrol_origin  = global_position

	if unique_id.is_empty():
		unique_id = "guardia_%s_%d" % [name, get_instance_id()]

	if LevelStateManager.is_enemy_defeated(unique_id):
		queue_free()
		return

	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_to_group("enemies")

	if detection_area:
		detection_area.body_entered.connect(_on_detect_enter)
		detection_area.body_exited.connect(_on_detect_exit)

	if attack_timer:
		attack_timer.wait_time = attack_cooldown
		attack_timer.one_shot  = false
		attack_timer.timeout.connect(func(): can_attack = true)
		attack_timer.start()

	if light:
		light.color  = Color(1.0, 0.4, 0.1)  # Naranja — guardia terrestre
		light.energy = 0.9

func _physics_process(delta: float) -> void:
	if current_state == State.DESTROYED:
		return

	# Gravedad — el guardia camina por el suelo
	if not is_on_floor():
		var grav := GRAVITY * (FALL_MULT if velocity.y > 0 else 1.0)
		velocity.y += grav * delta
	else:
		velocity.y = 0.0

	if _patrol_pause > 0.0:
		_patrol_pause -= delta
		velocity.x = move_toward(velocity.x, 0.0, speed * 5.0 * delta)
		move_and_slide()
		_update_anim()
		return

	match current_state:
		State.IDLE:    _do_idle(delta)
		State.PATROL:  _do_patrol(delta)
		State.ALERT:   _do_alert(delta)
		State.CHASE:   _do_chase(delta)
		State.ATTACK:  _do_attack(delta)
		State.DAMAGED: pass

	move_and_slide()
	_update_anim()

# ── LOS ───────────────────────────────────────────────────────────

func _has_los() -> bool:
	if not player_reference or not is_instance_valid(player_reference):
		return false
	var space  := get_world_2d().direct_space_state
	var query  := PhysicsRayQueryParameters2D.create(
		global_position, player_reference.global_position, LOS_MASK)
	query.exclude = [self]
	var result := space.intersect_ray(query)
	if result.is_empty(): return true
	if result.get("collider") == player_reference: return true
	return false

func _in_range(r: float) -> bool:
	if not player_reference or not is_instance_valid(player_reference): return false
	return global_position.distance_to(player_reference.global_position) <= r

func _can_see() -> bool:  return _in_range(detection_range) and _has_los()
func _can_atk() -> bool:  return _in_range(attack_range)    and _has_los()

# ── Estados ───────────────────────────────────────────────────────

func _do_idle(_d: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, speed * 2.0)
	if _can_see(): _set_state(State.ALERT)

func _do_patrol(delta: float) -> void:
	velocity.x = move_toward(velocity.x, patrol_direction * speed, speed * 3.0 * delta)
	var dist := global_position.x - patrol_origin.x
	if patrol_direction > 0 and dist >= patrol_distance:   _flip()
	elif patrol_direction < 0 and dist <= -patrol_distance: _flip()
	if _can_see(): _set_state(State.ALERT)

func _flip() -> void:
	patrol_direction *= -1
	_patrol_pause     = PATROL_PAUSE
	if sprite: sprite.flip_h = patrol_direction < 0

func _do_alert(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, speed * 3.0 * delta)
	if not player_reference or not is_instance_valid(player_reference):
		_set_state(State.PATROL); return
	_last_known_pos = player_reference.global_position
	if not _can_see():
		_lost_sight += delta
		if _lost_sight >= LOST_TIMEOUT: _set_state(State.PATROL)
		return
	_lost_sight = 0.0
	_face_player()
	if _can_atk():   _set_state(State.ATTACK)
	elif _in_range(detection_range): _set_state(State.CHASE)

func _do_chase(delta: float) -> void:
	if not player_reference or not is_instance_valid(player_reference):
		_set_state(State.PATROL); return
	if _can_see():
		_last_known_pos = player_reference.global_position
		_lost_sight     = 0.0
	else:
		_lost_sight += delta
		if _lost_sight >= LOST_TIMEOUT: _set_state(State.PATROL); return
	var dir : float = sign(_last_known_pos.x - global_position.x)
	velocity.x = move_toward(velocity.x, dir * speed * chase_speed_mult, speed * 3.0 * delta)
	if sprite: sprite.flip_h = dir < 0
	if _can_atk(): _set_state(State.ATTACK)

func _do_attack(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, speed * 3.0 * delta)
	if not player_reference or not is_instance_valid(player_reference):
		_set_state(State.PATROL); return
	if not _can_atk():
		if _can_see(): _set_state(State.ALERT)
		elif _in_range(detection_range): _set_state(State.CHASE)
		else: _set_state(State.PATROL)
		return
	_face_player()
	if can_attack: _shoot()

func _face_player() -> void:
	if not player_reference: return
	var dir : float = sign(player_reference.global_position.x - global_position.x)
	if sprite and dir != 0: sprite.flip_h = dir < 0

# ── Cambio de estado ──────────────────────────────────────────────

func _set_state(s: State) -> void:
	var old := current_state
	current_state = s
	_lost_sight   = 0.0
	match s:
		State.ALERT:
			if old not in [State.ATTACK, State.CHASE, State.ALERT]:
				player_detected.emit()
			if light: light.color = Color(1.0, 0.6, 0.0)
		State.CHASE:
			if light: light.color = Color(1.0, 0.7, 0.0)
		State.ATTACK:
			attacked.emit()
			if light: light.color = Color(1.0, 0.2, 0.0)
		State.PATROL:
			if old in [State.ALERT, State.ATTACK, State.CHASE]: player_lost.emit()
			if light: light.color = Color(1.0, 0.4, 0.1)

# ── Combate ───────────────────────────────────────────────────────

func _shoot() -> void:
	if not player_reference: return
	can_attack = false
	if projectile_scene:
		var p := projectile_scene.instantiate()
		get_parent().add_child(p)
		p.global_position = global_position
		if p.has_method("set_owner_node"): p.set_owner_node(self)
		var dir := (player_reference.global_position - global_position).normalized()
		if p.has_method("set_direction"): p.set_direction(dir, projectile_speed)
	else:
		if player_reference.has_method("take_damage"):
			player_reference.take_damage(damage)

func take_damage(amount: int) -> void:
	if current_state == State.DESTROYED: return
	current_health -= amount
	damaged.emit(amount)
	if sprite:
		sprite.modulate = Color(1.6, 0.4, 0.4)
		create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.25)
	if current_health <= 0: _destroy()
	else:
		current_state = State.DAMAGED
		get_tree().create_timer(0.4).timeout.connect(func():
			if current_state == State.DAMAGED:
				_set_state(State.PATROL if not _can_see() else State.ALERT))

func _destroy() -> void:
	current_state = State.DESTROYED
	destroyed.emit()
	LevelStateManager.register_enemy_defeated(unique_id)
	if has_node("/root/AchievementManager"):
		AchievementManager.increment_counter("enemies_killed")
	if collision: collision.set_deferred("disabled", true)
	velocity = Vector2.ZERO
	if sprite:
		var tw := create_tween().set_parallel(true)
		tw.tween_property(sprite, "scale", Vector2(2.0, 2.0), 0.3)
		tw.tween_property(sprite, "modulate", Color(2.0, 0.8, 0.0, 0.0), 0.4)
	if light:
		var tw2 := create_tween()
		tw2.tween_property(light, "energy", 5.0, 0.1)
		tw2.tween_property(light, "energy", 0.0, 0.4)
	if has_node("/root/GameManager"):
		GameManager.add_score(400)
		GameManager.shake_camera(6.0, 0.25)
	await get_tree().create_timer(1.0).timeout
	queue_free()

# ── Detección ─────────────────────────────────────────────────────

func _on_detect_enter(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "kai":
		player_reference = body

func _on_detect_exit(body: Node2D) -> void:
	if body == player_reference: player_reference = null

# ── Animación ─────────────────────────────────────────────────────

func _update_anim() -> void:
	if not sprite: return
	match current_state:
		State.IDLE:      sprite.play("idle")
		State.PATROL:    sprite.play("walk")
		State.ALERT:     sprite.play("idle")
		State.CHASE:     sprite.play("walk")
		State.ATTACK:    sprite.play("idle")
		State.DAMAGED:   sprite.play("idle")
		State.DESTROYED: pass

# ── API pública ───────────────────────────────────────────────────

func is_alive() -> bool: return current_state != State.DESTROYED
func get_health_percent() -> float: return float(current_health) / float(max_health)
