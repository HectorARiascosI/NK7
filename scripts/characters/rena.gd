extends CharacterBody2D

## ════════════════════════════════════════════════════════════════
## RENA — Técnica de Control NK-7
## ════════════════════════════════════════════════════════════════
## Jugador 2 cooperativo opcional.
## Traje negro con detalles naranja.
## Comparte física con Kai pero tiene habilidades propias:
##   - Hackeo más rápido (50% menos tiempo)
##   - Escudo temporal (bloquea 1 proyectil)
##   - Puede activar paneles de control remotamente
## ════════════════════════════════════════════════════════════════

@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D

# ── Velocidades ───────────────────────────────────────────────────
const SPEED           := 115.0
const RUN_SPEED       := 220.0
const CROUCH_SPEED    := 55.0
const CLIMB_SPEED     := 85.0
const CLIMB_RUN_SPEED := 170.0

# ── Física de salto ───────────────────────────────────────────────
const JUMP_FORCE         := -295.0
const JUMP_FORCE_RUNNING := -335.0
const WALK_JUMP_BOOST    := 1.10
const AIR_CONTROL        := 0.85
const GRAVITY            := 980.0
const FALL_GRAVITY_MULT  := 1.2

# ── Recursos ──────────────────────────────────────────────────────
const MAX_HEALTH := 100
const MAX_ENERGY := 100
const MAX_TOOL_DURABILITY := 100

var health           : int = MAX_HEALTH
var energy           : int = MAX_ENERGY
var tool_durability  : int = MAX_TOOL_DURABILITY
var has_repair_tool  : bool = true
var has_hacking_device : bool = true

# ── Coleccionables ────────────────────────────────────────────────
var cubes_collected : int = 0
var coins_collected : int = 0
var keycards : Array[String] = []

# ── Habilidades especiales de RENA ────────────────────────────────
var shield_active    : bool = false
var shield_charges   : int = 0
const MAX_SHIELD_CHARGES := 1

# ── Estado de movimiento ──────────────────────────────────────────
var is_running       := false
var is_crouching     := false
var is_climbing      := false
var is_climbing_fast := false
var is_doing_action  := false
var facing_right     := true
var can_climb        := false
var current_ladder   : Area2D = null
var _just_jumped_from_ladder := false

var _jump_horizontal_speed  := 0.0
var _climb_horizontal_speed := 0.0

# ── Input (Jugador 2 — gamepad o teclado alternativo) ─────────────
# Por defecto usa el mismo mapa de input que Kai pero con prefijo "p2_"
# Si no existe el mapa p2_, cae en el mismo que Kai (modo single-player)
var _use_p2_input : bool = false

# ══════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ══════════════════════════════════════════════════════════════════

func _ready() -> void:
	add_to_group("player")
	add_to_group("rena")
	_check_p2_input()
	_setup_shield()

func _check_p2_input() -> void:
	_use_p2_input = InputMap.has_action("p2_move_left")

func _setup_shield() -> void:
	shield_charges = MAX_SHIELD_CHARGES

# ══════════════════════════════════════════════════════════════════
# PROCESO
# ══════════════════════════════════════════════════════════════════

func _physics_process(delta: float) -> void:
	_handle_climbing()
	
	if not is_climbing and not is_on_floor():
		var gravity_mult : float = FALL_GRAVITY_MULT if velocity.y > 0 else 1.0
		velocity.y += GRAVITY * gravity_mult * delta
	
	is_doing_action = false
	_handle_special_actions()
	
	if not is_doing_action and not is_climbing:
		_handle_movement()
		_handle_jump()
	elif is_climbing:
		_handle_climb_movement()
	
	_update_animation()
	move_and_slide()

# ══════════════════════════════════════════════════════════════════
# INPUT
# ══════════════════════════════════════════════════════════════════

func _action(action: String) -> bool:
	var full : String = ("p2_" + action) if _use_p2_input else action
	if InputMap.has_action(full):
		return Input.is_action_pressed(full)
	return Input.is_action_pressed(action)

func _action_just(action: String) -> bool:
	var full : String = ("p2_" + action) if _use_p2_input else action
	if InputMap.has_action(full):
		return Input.is_action_just_pressed(full)
	return Input.is_action_just_pressed(action)

func _axis(neg: String, pos: String) -> float:
	if _use_p2_input:
		var n := "p2_" + neg
		var p := "p2_" + pos
		if InputMap.has_action(n) and InputMap.has_action(p):
			return Input.get_axis(n, p)
	return Input.get_axis(neg, pos)

# ══════════════════════════════════════════════════════════════════
# MOVIMIENTO (idéntico a Kai)
# ══════════════════════════════════════════════════════════════════

func _on_ladder_entered(body: Node2D, ladder: Area2D) -> void:
	if body == self:
		can_climb = true
		current_ladder = ladder

func _on_ladder_exited(body: Node2D, ladder: Area2D) -> void:
	if body == self:
		can_climb = false
		if current_ladder == ladder:
			current_ladder = null
			is_climbing = false

func _handle_climbing() -> void:
	if _just_jumped_from_ladder:
		if not _action("climb_up") and not _action("climb_down"):
			_just_jumped_from_ladder = false
		return
	
	if can_climb and not is_climbing:
		if _action("climb_up") or _action("climb_down"):
			is_climbing = true
			velocity.x = 0
			velocity.y = 0
	
	if is_climbing:
		if _action_just("jump"):
			is_climbing = false
			_just_jumped_from_ladder = true
			var h := _axis("move_left", "move_right")
			var running_now := _action("run")
			velocity.y = JUMP_FORCE_RUNNING if running_now else JUMP_FORCE
			velocity.x = h * CLIMB_SPEED * 0.5 if h != 0 else 0.0
			is_climbing_fast = false
			return
		elif not can_climb:
			is_climbing = false
			is_climbing_fast = false

func _handle_climb_movement() -> void:
	is_climbing_fast = _action("run")
	var climbing_input := 0.0
	if _action("climb_up"):   climbing_input = -1.0
	elif _action("climb_down"): climbing_input = 1.0
	
	var spd : float = CLIMB_RUN_SPEED if is_climbing_fast else CLIMB_SPEED
	velocity.y = climbing_input * spd if climbing_input != 0 else 0.0
	if climbing_input == 0:
		is_climbing = false
	
	var h := _axis("move_left", "move_right")
	if h != 0:
		velocity.x = h * spd * 0.5
		facing_right = h > 0
		sprite.flip_h = not facing_right
	else:
		velocity.x = 0

func _handle_special_actions() -> void:
	if _action("interact"):
		sprite.play("communicate")
		velocity.x = 0
		is_doing_action = true
		return
	if _action("hack"):
		sprite.play("hack")
		velocity.x = 0
		is_doing_action = true
		return
	if _action("use_tool"):
		sprite.play("use_tool")
		velocity.x = 0
		is_doing_action = true
		return

func _handle_movement() -> void:
	var direction : float = _axis("move_left", "move_right")
	is_running   = _action("run") and not is_crouching and is_on_floor()
	is_crouching = _action("crouch") and is_on_floor()
	
	var spd : float = CROUCH_SPEED if is_crouching else (RUN_SPEED if is_running else SPEED)
	
	if is_on_floor():
		if direction != 0:
			velocity.x = direction * spd
			facing_right = direction > 0
			sprite.flip_h = not facing_right
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
	else:
		if direction != 0:
			var current_speed : float = abs(velocity.x)
			velocity.x = lerp(velocity.x, signf(direction) * current_speed, AIR_CONTROL * 0.05)
			facing_right = direction > 0
			sprite.flip_h = not facing_right

func _handle_jump() -> void:
	if _action_just("jump") and is_on_floor() and not is_crouching:
		if is_running:
			velocity.y = JUMP_FORCE_RUNNING
			_jump_horizontal_speed = velocity.x
		else:
			velocity.y = JUMP_FORCE
			_jump_horizontal_speed = velocity.x * WALK_JUMP_BOOST
		velocity.x = _jump_horizontal_speed
		AudioManager.play_sfx("jump", randf_range(-0.05, 0.05))

func _update_animation() -> void:
	if is_doing_action:
		return
	if is_climbing:
		sprite.play("climb")
		sprite.speed_scale = 2.0 if is_climbing_fast else 1.0
	elif not is_on_floor():
		sprite.speed_scale = 1.0
		sprite.play("jump")
	elif _action("push"):
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
# HABILIDADES ESPECIALES DE RENA
# ══════════════════════════════════════════════════════════════════

func activate_shield() -> bool:
	"""Activar escudo temporal (bloquea 1 proyectil)"""
	if shield_charges <= 0:
		return false
	shield_active = true
	shield_charges -= 1
	# Efecto visual: flash naranja
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(1.5, 0.7, 0.2), 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.3)
	return true

func recharge_shield() -> void:
	"""Recargar escudo (al recoger energy tube)"""
	shield_charges = min(shield_charges + 1, MAX_SHIELD_CHARGES)

func hack_fast(target: Node) -> bool:
	"""Hackear objetivo 50% más rápido que Kai"""
	if not has_hacking_device:
		return false
	if not consume_energy(15):
		return false
	if target.has_method("hack"):
		target.hack()
	return true

# ══════════════════════════════════════════════════════════════════
# SISTEMA DE RECURSOS (idéntico a Kai)
# ══════════════════════════════════════════════════════════════════

func take_damage(amount: int) -> void:
	if shield_active:
		shield_active = false
		AudioManager.play_sfx("ui_confirm")
		return
	
	health -= amount
	health = max(0, health)
	AudioManager.play_sfx("hurt")
	
	if health <= 0:
		die()
	else:
		sprite.play("hurt")
		await sprite.animation_finished

func heal(amount: int) -> void:
	health = min(MAX_HEALTH, health + amount)

func consume_energy(amount: int) -> bool:
	if energy >= amount:
		energy -= amount
		return true
	return false

func restore_energy(amount: int) -> void:
	energy = min(MAX_ENERGY, energy + amount)
	recharge_shield()

func use_tool(durability_cost: int = 10) -> bool:
	if not has_repair_tool:
		return false
	if tool_durability >= durability_cost:
		tool_durability = max(0, tool_durability - durability_cost)
		return true
	return false

func repair_tool(amount: int) -> void:
	tool_durability = min(MAX_TOOL_DURABILITY, tool_durability + amount)

func die() -> void:
	sprite.play("dead")
	set_physics_process(false)
	await get_tree().create_timer(1.5).timeout
	get_tree().reload_current_scene()

func get_health_percent() -> float:
	return float(health) / float(MAX_HEALTH)

func get_energy_percent() -> float:
	return float(energy) / float(MAX_ENERGY)

func get_tool_durability_percent() -> float:
	return float(tool_durability) / float(MAX_TOOL_DURABILITY)

# ── Coleccionables ────────────────────────────────────────────────

func add_cube(amount: int = 1) -> void:
	cubes_collected += amount
	AchievementManager.increment_counter("cubes_collected", amount)

func add_keycard(keycard_id: String) -> void:
	if not keycard_id in keycards:
		keycards.append(keycard_id)

func has_keycard(keycard_id: String) -> bool:
	return keycard_id in keycards

func get_cubes_count() -> int:
	return cubes_collected

func get_coins_count() -> int:
	return coins_collected
