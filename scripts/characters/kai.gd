extends CharacterBody2D

# ── Referencia a nodos hijos ──────────────────────────────────────
@onready var sprite := $AnimatedSprite2D

# ── Constantes de movimiento ──────────────────────────────────────
const SPEED        := 120.0
const RUN_SPEED    := 220.0
const CROUCH_SPEED := 60.0
const CLIMB_SPEED  := 80.0
const JUMP_FORCE   := -300.0
const GRAVITY      := 980.0

# ── Variables de estado ───────────────────────────────────────────
var is_running      := false
var is_crouching    := false
var is_climbing     := false
var is_doing_action := false
var facing_right    := true
var can_climb       := false
var current_ladder  : Area2D = null

# ── Referencia al DialogueBox (cacheada) ─────────────────────────
var _dialogue_box : Node = null


func _ready() -> void:
	# Buscar el DialogueBox una sola vez al iniciar
	await get_tree().process_frame
	_dialogue_box = _search_node(get_tree().root, "DialogueBox")


func _is_dialogue_open() -> bool:
	if _dialogue_box == null:
		_dialogue_box = _search_node(get_tree().root, "DialogueBox")
	if _dialogue_box == null:
		return false
	# Leer la variable estática is_active del DialogueBox
	var val = _dialogue_box.get("is_active")
	return val != null and bool(val)


func _search_node(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node
	for child in node.get_children():
		var result := _search_node(child, target_name)
		if result:
			return result
	return null


func _physics_process(delta: float) -> void:
	# ── Bloquear todo si hay diálogo activo ───────────────────────
	if _is_dialogue_open():
		velocity.x = move_toward(velocity.x, 0, SPEED * 2.0)
		if not is_on_floor():
			velocity.y += GRAVITY * delta
		move_and_slide()
		sprite.play("idle")
		return

	# Manejar escaleras
	_handle_climbing()
	
	# Aplicar gravedad solo si NO está trepando
	if not is_climbing and not is_on_floor():
		velocity.y += GRAVITY * delta
	
	# Resetear estado de acción cada frame
	is_doing_action = false
	
	_handle_special_actions()
	
	# Solo manejar movimiento si no está haciendo acción bloqueante
	if not is_doing_action and not is_climbing:
		_handle_movement()
		_handle_jump()
	elif is_climbing:
		_handle_climb_movement()
	
	_update_animation()
	move_and_slide()


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
	# Entrar en modo escalera automáticamente si presiona W o S cerca de una escalera
	if can_climb and not is_climbing:
		if Input.is_action_pressed("climb_up") or Input.is_action_pressed("climb_down"):
			is_climbing = true
			velocity.x = 0
			velocity.y = 0
	
	# Salir de la escalera si se presiona salto
	if is_climbing:
		if Input.is_action_just_pressed("jump"):
			is_climbing = false
			velocity.y = JUMP_FORCE
		elif not can_climb:
			is_climbing = false


func _handle_climb_movement() -> void:
	# Movimiento vertical en la escalera con W/S
	var climbing_input := 0.0
	
	if Input.is_action_pressed("climb_up"):
		climbing_input = -1.0
	elif Input.is_action_pressed("climb_down"):
		climbing_input = 1.0
	
	if climbing_input != 0:
		velocity.y = climbing_input * CLIMB_SPEED
	else:
		velocity.y = 0
		is_climbing = false
	
	# Movimiento horizontal en escalera
	var horizontal_input := Input.get_axis("move_left", "move_right")
	if horizontal_input != 0:
		velocity.x = horizontal_input * CLIMB_SPEED * 0.5
		if horizontal_input > 0:
			facing_right = true
			sprite.flip_h = false
		else:
			facing_right = false
			sprite.flip_h = true
	else:
		velocity.x = 0


func _handle_special_actions() -> void:
	# Muerte (test) - bloquea todo
	if Input.is_action_pressed("dead_test"):
		sprite.play("dead")
		velocity.x = 0
		is_doing_action = true
		return
	
	# Acciones que bloquean movimiento completamente
	if Input.is_action_pressed("communicate"):
		sprite.play("communicate")
		velocity.x = 0
		is_doing_action = true
		return
	
	if Input.is_action_pressed("hack"):
		sprite.play("hack")
		velocity.x = 0
		is_doing_action = true
		return
	
	if Input.is_action_pressed("use_tool"):
		sprite.play("use_tool")
		velocity.x = 0
		is_doing_action = true
		return


func _handle_movement() -> void:
	var direction := Input.get_axis("move_left", "move_right")
	is_running = Input.is_action_pressed("run") and not is_crouching and is_on_floor()
	is_crouching = Input.is_action_pressed("crouch") and is_on_floor()
	
	# Determinar velocidad según estado
	var current_speed := SPEED
	if is_crouching:
		current_speed = CROUCH_SPEED
	elif is_running:
		current_speed = RUN_SPEED
	
	# Aplicar movimiento
	if direction != 0:
		velocity.x = direction * current_speed
		# Actualizar dirección del sprite
		if direction > 0:
			facing_right = true
			sprite.flip_h = false
		else:
			facing_right = false
			sprite.flip_h = true
	else:
		# Frenar suavemente
		velocity.x = move_toward(velocity.x, 0, SPEED)


func _handle_jump() -> void:
	# No se puede saltar agachado
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_crouching:
		velocity.y = JUMP_FORCE


func _update_animation() -> void:
	# Si está haciendo acción especial, no cambiar animación
	if is_doing_action:
		return
	
	# Prioridad 1: Trepando escalera
	if is_climbing:
		sprite.position.y = -1
		if abs(velocity.y) > 10 or abs(velocity.x) > 10:
			sprite.play("climb")
		else:
			sprite.play("climb")
		return
	
	# Prioridad 2: En el aire
	if not is_on_floor():
		sprite.position.y = -1
		sprite.play("jump")
		return
	
	# Prioridad 3: Empujar (permite movimiento)
	if Input.is_action_pressed("push"):
		sprite.position.y = -1
		sprite.play("push")
		return
	
	# Prioridad 4: Agachado
	if is_crouching:
		sprite.position.y = 8  # ajustar posición para que toque el suelo
		if abs(velocity.x) > 10:  # se está moviendo agachado
			sprite.play("crouch")
		else:
			sprite.play("crouch")
		return
	
	# Prioridad 5: Movimiento normal
	sprite.position.y = -1
	if abs(velocity.x) > 10:
		if is_running:
			sprite.play("run")
		else:
			sprite.play("walk")
		return
	
	# Prioridad 6: Idle
	sprite.play("idle")
