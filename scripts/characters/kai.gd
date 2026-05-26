extends CharacterBody2D

@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D

## ══════════════════════════════════════════════════════════════════
## KAI — Personaje principal NK-7
## ══════════════════════════════════════════════════════════════════
##
## TABLA DE CONSUMO DE RECURSOS:
##
## STAMINA (barra dorada):
##   Correr          → -18 pts/s
##   Escalar rápido  → -10 pts/s
##   Empujar         → -8 pts/s
##   Saltar corriendo→ -5 pts (instantáneo)
##   Regen parado    → +12 pts/s (delay 1.2s)
##   Regen agachado  → +28 pts/s (sin delay)
##
## ENERGÍA (barra azul):
##   Hackear         → -15 pts/s
##   Atacar (F)      → -8 pts (instantáneo)
##   Regen pasiva    → +3 pts/s (delay 3s)
##   Regen agachado  → +10 pts/s extra (sin delay)
##
## SALUD (barra rosa):
##   Daño enemigo    → variable
##   I-frames        → 1.5s tras cada golpe
## ══════════════════════════════════════════════════════════════════

# ── Ataque ────────────────────────────────────────────────────────
const ATTACK_RANGE    := 80.0
const ATTACK_DAMAGE   := 30
const ATTACK_ENERGY   := 8.0
const ATTACK_COOLDOWN := 0.6

var _attack_cooldown_timer : float = 0.0
var _is_attacking          : bool  = false

# ── Velocidades ───────────────────────────────────────────────────
const SPEED           := 120.0
const RUN_SPEED       := 230.0
const CROUCH_SPEED    := 60.0
const CLIMB_SPEED     := 80.0
const CLIMB_RUN_SPEED := 160.0

## Velocidad de empuje cuando la stamina está baja (< 30%)
const PUSH_SPEED_LOW_STAMINA := 0.5   ## multiplicador

# ── Física de salto ───────────────────────────────────────────────
const JUMP_FORCE         := -305.0
const JUMP_FORCE_RUNNING := -345.0
const WALK_JUMP_BOOST    := 1.12
const AIR_CONTROL        := 0.85
const GRAVITY            := 980.0
const FALL_GRAVITY_MULT  := 1.2

# ── Recursos máximos ──────────────────────────────────────────────
const MAX_HEALTH  := 100
const MAX_ENERGY  := 100
const MAX_STAMINA := 100

# ── Stamina ───────────────────────────────────────────────────────
const STAMINA_DRAIN_RUN     : float = 18.0  ## pts/s corriendo
const STAMINA_DRAIN_CLIMB   : float = 10.0  ## pts/s escalando rápido
const STAMINA_DRAIN_PUSH    : float = 8.0   ## pts/s empujando
const STAMINA_DRAIN_JUMP    : float = 5.0   ## pts instantáneo al saltar corriendo
const STAMINA_REGEN_IDLE    : float = 12.0  ## pts/s parado/caminando
const STAMINA_REGEN_CROUCH  : float = 28.0  ## pts/s agachado quieto
const STAMINA_REGEN_DELAY   : float = 1.2   ## s de espera antes de regen
const STAMINA_RUN_THRESHOLD : float = 20.0  ## mínimo para volver a correr

# ── Energía ───────────────────────────────────────────────────────
const ENERGY_HACK_RATE    : float = 15.0  ## pts/s hackeando
const ENERGY_REGEN_IDLE   : float = 3.0   ## pts/s regen pasiva
const ENERGY_REGEN_CROUCH : float = 10.0  ## pts/s extra agachado quieto
const ENERGY_REGEN_DELAY  : float = 3.0   ## s sin usar para empezar regen

# ── I-frames ──────────────────────────────────────────────────────
const INVINCIBILITY_DURATION := 1.5

# ── Estado de movimiento ──────────────────────────────────────────
var is_running       := false
var is_crouching     := false
var is_climbing      := false
var is_climbing_fast := false
var is_doing_action  := false
var is_pushing       := false
var facing_right     := true
var can_climb        := false
var current_ladder   : Area2D = null

var _invincible_timer        : float = 0.0
var _jump_horizontal_speed   : float = 0.0
var _climb_horizontal_speed  : float = 0.0
var _just_jumped_from_ladder : bool  = false
var _tutorial_system         : Node  = null

# ── Recursos ──────────────────────────────────────────────────────
var health  : float = MAX_HEALTH
var energy  : float = MAX_ENERGY
var stamina : float = MAX_STAMINA

var _stamina_regen_timer : float = 0.0
var _stamina_depleted    : bool  = false
var _energy_regen_timer  : float = 0.0

# ── Coleccionables ────────────────────────────────────────────────
var cubes_collected : int = 0
var coins_collected : int = 0
var keycards        : Array[String] = []

# ── Compatibilidad ────────────────────────────────────────────────
var has_repair_tool    : bool = true
var has_hacking_device : bool = true

## Indicador visual de parry disponible (activado por el proyectil)
var _parry_window_active : bool  = false
var _parry_flash_timer   : float = 0.0


# ══════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ══════════════════════════════════════════════════════════════════

func _ready() -> void:
	# El jugador es PAUSABLE — se congela con el árbol (tutorial, pausa)
	process_mode = Node.PROCESS_MODE_PAUSABLE
	await get_tree().process_frame
	_tutorial_system = _search_node(get_tree().root, "TutorialSystem")
	add_to_group("player")


func _is_tutorial_active() -> bool:
	## Ya no necesario para lógica de movimiento — el árbol se pausa.
	## Se mantiene por compatibilidad con código que lo consulte.
	if _tutorial_system == null:
		_tutorial_system = _search_node(get_tree().root, "TutorialSystem")
	if _tutorial_system == null:
		return false
	var val = _tutorial_system.get("is_active")
	return val != null and bool(val)


func _search_node(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node
	for child in node.get_children():
		var result := _search_node(child, target_name)
		if result:
			return result
	return null


# ══════════════════════════════════════════════════════════════════
# PROCESO PRINCIPAL
# ══════════════════════════════════════════════════════════════════

func _physics_process(delta: float) -> void:
	if _attack_cooldown_timer > 0.0:
		_attack_cooldown_timer -= delta

	# I-frames — parpadeo visual
	if _invincible_timer > 0.0:
		_invincible_timer -= delta
		sprite.modulate.a = 0.5 if fmod(_invincible_timer, 0.15) < 0.075 else 1.0
	else:
		# Flash amarillo cuando hay ventana de parry disponible
		if _parry_window_active:
			_parry_flash_timer += delta * 12.0
			var t : float = 0.7 + 0.3 * sin(_parry_flash_timer)
			sprite.modulate = Color(1.0, t, 0.0)
		else:
			_parry_flash_timer = 0.0
			sprite.modulate    = Color.WHITE
			sprite.modulate.a  = 1.0

	_update_stamina(delta)
	_update_energy(delta)

	_handle_climbing()

	if not is_climbing and not is_on_floor():
		var grav_mult : float = FALL_GRAVITY_MULT if velocity.y > 0 else 1.0
		velocity.y += GRAVITY * grav_mult * delta

	is_doing_action = false
	is_pushing      = false
	_handle_special_actions(delta)

	if not is_doing_action and not is_climbing:
		_handle_movement(delta)
		_handle_jump()
	elif is_climbing:
		_handle_climb_movement(delta)

	_update_animation()
	move_and_slide()


# ══════════════════════════════════════════════════════════════════
# STAMINA
# ══════════════════════════════════════════════════════════════════

func _update_stamina(delta: float) -> void:
	# Solo consume stamina si realmente se está moviendo Y presiona run
	# abs(velocity.x) > 5 evita consumo al estar quieto con shift presionado
	var running_now : bool = Input.is_action_pressed("run") \
		and is_on_floor() \
		and not is_crouching \
		and abs(velocity.x) > 5.0   ## debe haber movimiento real

	if running_now:
		_drain_stamina(STAMINA_DRAIN_RUN * delta)
		return

	# Empujando gasta stamina solo si hay movimiento
	if is_pushing and is_on_floor() and abs(velocity.x) > 2.0:
		_drain_stamina(STAMINA_DRAIN_PUSH * delta)
		return

	# Agachado quieto = descanso activo (regen inmediata y más rápida)
	var crouching_still : bool = is_crouching and is_on_floor() \
		and abs(velocity.x) < 10.0

	if crouching_still:
		stamina += STAMINA_REGEN_CROUCH * delta
		stamina  = min(float(MAX_STAMINA), stamina)
		_stamina_regen_timer = STAMINA_REGEN_DELAY  # Saltar el delay
	else:
		if _stamina_regen_timer < STAMINA_REGEN_DELAY:
			_stamina_regen_timer += delta
		else:
			stamina += STAMINA_REGEN_IDLE * delta
			stamina  = min(float(MAX_STAMINA), stamina)

	if _stamina_depleted and stamina >= STAMINA_RUN_THRESHOLD:
		_stamina_depleted = false


func _drain_stamina(amount: float) -> void:
	stamina -= amount
	stamina  = max(0.0, stamina)
	_stamina_regen_timer = 0.0
	if stamina <= 0.0:
		_stamina_depleted = true


func _can_run() -> bool:
	return stamina > 0.0 and not _stamina_depleted


# ══════════════════════════════════════════════════════════════════
# ENERGÍA
# ══════════════════════════════════════════════════════════════════

func _update_energy(delta: float) -> void:
	var crouching_still : bool = is_crouching and is_on_floor() \
		and abs(velocity.x) < 10.0 and not is_doing_action

	if crouching_still:
		energy += (ENERGY_REGEN_IDLE + ENERGY_REGEN_CROUCH) * delta
		energy  = min(float(MAX_ENERGY), energy)
		return

	if _energy_regen_timer < ENERGY_REGEN_DELAY:
		_energy_regen_timer += delta
	else:
		energy += ENERGY_REGEN_IDLE * delta
		energy  = min(float(MAX_ENERGY), energy)


# ══════════════════════════════════════════════════════════════════
# ESCALERAS
# ══════════════════════════════════════════════════════════════════

func _on_ladder_entered(body: Node2D, ladder: Area2D) -> void:
	if body == self:
		can_climb      = true
		current_ladder = ladder

func _on_ladder_exited(body: Node2D, ladder: Area2D) -> void:
	if body == self:
		can_climb = false
		if current_ladder == ladder:
			current_ladder = null
			is_climbing    = false

func _handle_climbing() -> void:
	if _just_jumped_from_ladder:
		if not Input.is_action_pressed("climb_up") and not Input.is_action_pressed("climb_down"):
			_just_jumped_from_ladder = false
		return

	if can_climb and not is_climbing:
		if Input.is_action_pressed("climb_up") or Input.is_action_pressed("climb_down"):
			is_climbing = true
			velocity.x  = 0
			velocity.y  = 0

	if is_climbing:
		if Input.is_action_just_pressed("jump"):
			is_climbing              = false
			_just_jumped_from_ladder = true
			var h              := Input.get_axis("move_left", "move_right")
			var is_running_now := Input.is_action_pressed("run") and _can_run()
			velocity.y = JUMP_FORCE_RUNNING if is_running_now else JUMP_FORCE
			velocity.x = h * (CLIMB_RUN_SPEED if is_running_now else CLIMB_SPEED) * 0.5 if h != 0 else 0.0
			is_climbing_fast        = false
			_climb_horizontal_speed = 0.0
			return
		elif not can_climb:
			is_climbing      = false
			is_climbing_fast = false

func _handle_climb_movement(delta: float) -> void:
	var wants_fast : bool = Input.is_action_pressed("run") and _can_run()
	is_climbing_fast = wants_fast

	# Escalar rápido consume stamina
	if is_climbing_fast:
		_drain_stamina(STAMINA_DRAIN_CLIMB * delta)

	var climb_spd : float = CLIMB_RUN_SPEED if is_climbing_fast else CLIMB_SPEED

	var v := 0.0
	if Input.is_action_pressed("climb_up"):    v = -1.0
	elif Input.is_action_pressed("climb_down"): v = 1.0

	velocity.y = v * climb_spd if v != 0 else 0.0
	if v == 0:
		is_climbing = false

	var h := Input.get_axis("move_left", "move_right")
	if h != 0:
		velocity.x              = h * climb_spd * 0.5
		_climb_horizontal_speed = velocity.x
		facing_right            = h > 0
		sprite.flip_h           = not facing_right
	else:
		velocity.x              = 0
		_climb_horizontal_speed = 0.0


# ══════════════════════════════════════════════════════════════════
# ACCIONES ESPECIALES
# ══════════════════════════════════════════════════════════════════

func _handle_special_actions(delta: float) -> void:
	if Input.is_action_pressed("interact"):
		sprite.play("communicate")
		velocity.x      = 0
		is_doing_action = true
		return

	if Input.is_action_pressed("hack"):
		if energy > 0.0:
			energy -= ENERGY_HACK_RATE * delta
			energy  = max(0.0, energy)
			_energy_regen_timer = 0.0
			sprite.play("hack")
		else:
			# Sin energía: animación de fallo
			sprite.play("idle")
		velocity.x      = 0
		is_doing_action = true
		return

	if Input.is_action_pressed("use_tool"):
		if _attack_cooldown_timer <= 0.0 and _try_attack():
			velocity.x      = 0
			is_doing_action = true
			return
		sprite.play("use_tool")
		velocity.x      = 0
		is_doing_action = true
		return

	# Empujar — consume stamina, velocidad reducida si stamina baja
	if Input.is_action_pressed("push") and is_on_floor():
		is_pushing      = true
		is_doing_action = true
		# La velocidad de empuje se reduce si la stamina es baja
		# (se aplica en _handle_movement vía is_pushing)
		return


# ══════════════════════════════════════════════════════════════════
# ATAQUE
# ══════════════════════════════════════════════════════════════════

func _try_attack() -> bool:
	var nearest := _find_nearest_enemy()
	if nearest == null:
		return false
	if global_position.distance_to(nearest.global_position) > ATTACK_RANGE:
		return false
	if not consume_energy(ATTACK_ENERGY):
		return false
	_perform_attack(nearest)
	return true

func _perform_attack(target: Node) -> void:
	_is_attacking          = true
	_attack_cooldown_timer = ATTACK_COOLDOWN
	facing_right           = target.global_position.x > global_position.x
	sprite.flip_h          = not facing_right
	sprite.play("use_tool")

	if has_node("/root/AudioManager"):
		AudioManager.play_sfx("attack", randf_range(-0.1, 0.1))
	if target.has_method("take_damage"):
		target.take_damage(ATTACK_DAMAGE)

	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(1.5, 1.2, 0.5), 0.06)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)

	if has_node("/root/GameManager"):
		GameManager.shake_camera(4.0, 0.15)
	_is_attacking = false

func _find_nearest_enemy() -> Node:
	var enemies      := get_tree().get_nodes_in_group("enemies")
	var nearest      : Node  = null
	var nearest_dist : float = ATTACK_RANGE + 1.0
	for enemy in enemies:
		if not is_instance_valid(enemy): continue
		if enemy.has_method("is_alive") and not enemy.is_alive(): continue
		var d := global_position.distance_to(enemy.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest      = enemy
	return nearest


# ══════════════════════════════════════════════════════════════════
# MOVIMIENTO
# ══════════════════════════════════════════════════════════════════

func _handle_movement(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	is_running   = Input.is_action_pressed("run") and _can_run() \
		and not is_crouching and is_on_floor()
	is_crouching = Input.is_action_pressed("crouch") and is_on_floor()

	# Velocidad de correr se degrada cuando la stamina es baja
	var stamina_factor : float = clamp(stamina / STAMINA_RUN_THRESHOLD, 0.0, 1.0) \
		if stamina < STAMINA_RUN_THRESHOLD else 1.0

	var spd : float
	if is_crouching:
		spd = CROUCH_SPEED
	elif is_pushing:
		# Empujar: velocidad reducida si stamina baja
		var push_factor : float = lerp(PUSH_SPEED_LOW_STAMINA, 1.0,
			clamp(stamina / float(MAX_STAMINA), 0.0, 1.0))
		spd = SPEED * push_factor
	elif is_running:
		spd = lerp(SPEED, RUN_SPEED, stamina_factor)
	else:
		spd = SPEED

	if is_on_floor():
		if direction != 0:
			velocity.x    = direction * spd
			facing_right  = direction > 0
			sprite.flip_h = not facing_right
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED * 4.0 * delta)
	else:
		if direction != 0:
			velocity.x = lerp(velocity.x, sign(direction) * abs(velocity.x), AIR_CONTROL * 0.05)
			facing_right  = direction > 0
			sprite.flip_h = not facing_right

func _handle_jump() -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_crouching:
		if is_running:
			velocity.y             = JUMP_FORCE_RUNNING
			_jump_horizontal_speed = velocity.x
			# Saltar corriendo consume stamina instantáneamente
			_drain_stamina(STAMINA_DRAIN_JUMP)
		else:
			velocity.y             = JUMP_FORCE
			_jump_horizontal_speed = velocity.x * WALK_JUMP_BOOST
		velocity.x = _jump_horizontal_speed
		if has_node("/root/AudioManager"):
			AudioManager.play_sfx("jump", randf_range(-0.05, 0.05))


# ══════════════════════════════════════════════════════════════════
# ANIMACIÓN
# ══════════════════════════════════════════════════════════════════

func _update_animation() -> void:
	if is_doing_action and not is_pushing:
		return
	if is_climbing:
		sprite.play("climb")
		sprite.speed_scale = 2.0 if is_climbing_fast else 1.0
	elif not is_on_floor():
		sprite.speed_scale = 1.0
		sprite.play("jump")
	elif is_pushing:
		sprite.speed_scale = 1.0
		sprite.play("push")
	elif is_crouching:
		sprite.speed_scale = 1.0
		sprite.play("crouch")
	elif abs(velocity.x) > 10.0:
		sprite.speed_scale = 1.0
		sprite.play("run" if is_running else "walk")
	else:
		sprite.speed_scale = 1.0
		sprite.play("idle")


# ══════════════════════════════════════════════════════════════════
# SISTEMA DE RECURSOS
# ══════════════════════════════════════════════════════════════════

func take_damage(amount: int) -> void:
	if _invincible_timer > 0.0:
		return
	health -= float(amount)
	health  = max(0.0, health)
	_invincible_timer = INVINCIBILITY_DURATION

	var hud := _search_node(get_tree().root, "PlayerHUD")
	if hud and hud.has_method("flash_damage"):
		hud.flash_damage()

	if has_node("/root/AudioManager"):
		AudioManager.play_sfx("hurt")

	if health <= 0.0:
		die()
	else:
		sprite.play("hurt")
		await sprite.animation_finished

func heal(amount: float) -> void:
	health = min(health + amount, float(MAX_HEALTH))

func consume_energy(amount: float) -> bool:
	if energy >= amount:
		energy -= amount
		energy  = max(0.0, energy)
		_energy_regen_timer = 0.0
		return true
	return false

func restore_energy(amount: float) -> void:
	energy = min(energy + amount, float(MAX_ENERGY))
	_energy_regen_timer = 0.0

func restore_stamina(amount: float) -> void:
	stamina = min(stamina + amount, float(MAX_STAMINA))

func use_tool(_durability_cost: int = 10) -> bool:
	return true

func repair_tool(amount: int) -> void:
	restore_stamina(float(amount))

func die() -> void:
	sprite.play("dead")
	set_physics_process(false)
	if has_node("/root/AudioManager"):
		AudioManager.play_sfx("die")
	if has_node("/root/GameManager"):
		GameManager.player_death()
	await get_tree().create_timer(1.5).timeout
	get_tree().reload_current_scene()

func get_health_percent() -> float:
	return health / float(MAX_HEALTH)

func get_health() -> int:
	return int(health)

func get_max_health() -> int:
	return MAX_HEALTH

func get_energy_percent() -> float:
	return energy / float(MAX_ENERGY)

func get_tool_durability_percent() -> float:
	return stamina / float(MAX_STAMINA)

## Llamado por el proyectil para activar/desactivar el indicador de parry
func set_parry_window(active: bool) -> void:
	_parry_window_active = active
	if not active:
		_parry_flash_timer = 0.0


# ══════════════════════════════════════════════════════════════════
# COLECCIONABLES
# ══════════════════════════════════════════════════════════════════

func add_cube(amount: int = 1) -> void:
	cubes_collected += amount
	if has_node("/root/AchievementManager"):
		AchievementManager.increment_counter("cubes_collected", amount)
	if has_node("/root/AudioManager"):
		AudioManager.play_sfx("cube")

func add_coin(amount: int = 1) -> void:
	coins_collected += amount
	if has_node("/root/AudioManager"):
		AudioManager.play_sfx("coin")

func add_keycard(keycard_id: String) -> void:
	if not keycard_id in keycards:
		keycards.append(keycard_id)
		if has_node("/root/AudioManager"):
			AudioManager.play_sfx("keycard")

func has_keycard(keycard_id: String) -> bool:
	return keycard_id in keycards

func get_cubes_count() -> int:
	return cubes_collected

func get_coins_count() -> int:
	return coins_collected
