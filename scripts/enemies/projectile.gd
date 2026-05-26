extends Area2D
class_name Projectile

## ════════════════════════════════════════════════════════════════
## PROYECTIL DE ENEMIGO UKIBUKI
## ════════════════════════════════════════════════════════════════
##
## MECÁNICAS:
##   • Daño base: 22 pts (Kai aguanta ~4 balas con 100 HP)
##   • Agacharse esquiva: si el jugador está agachado, la bala pasa
##   • Parry (F en momento preciso): desvía la bala de vuelta al robot
##     → hace 50% de la vida máxima del robot
##   • Bala desviada detecta impacto por DISTANCIA (no body_entered)
##     porque el robot puede estar en otra collision layer
## ════════════════════════════════════════════════════════════════

@export var damage       : int   = 22
@export var lifetime     : float = 4.0

@onready var sprite    : Sprite2D         = $Sprite
@onready var collision : CollisionShape2D = $Collision
@onready var trail     : GPUParticles2D   = $Trail

var velocity    : Vector2 = Vector2.ZERO
var has_hit     : bool    = false
var _owner_node : Node    = null
var _owner_id   : int     = -1

## Parry
var _parried     : bool  = false
var _parry_ready : bool  = false
var _parry_target : Node = null   ## Robot al que va dirigida la bala desviada

## Radio de impacto cuando la bala está desviada (px)
const PARRY_HIT_RADIUS : float = 40.0

# ══════════════════════════════════════════════════════════════════

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(lifetime).timeout.connect(_destroy)

func set_direction(direction: Vector2, speed: float) -> void:
	velocity = direction.normalized() * speed

func set_velocity(vel: Vector2) -> void:
	velocity = vel

func set_owner_id(id: int) -> void:
	_owner_id = id

func set_owner_node(node: Node) -> void:
	_owner_node = node

# ══════════════════════════════════════════════════════════════════
# PROCESO
# ══════════════════════════════════════════════════════════════════

func _process(delta: float) -> void:
	if has_hit:
		return

	global_position += velocity * delta

	if velocity.length_squared() > 0:
		rotation = velocity.angle()

	if _parried:
		# ── Bala desviada: detectar impacto por distancia ─────────
		# No dependemos de body_entered porque el robot puede estar
		# en una collision layer diferente al jugador
		_check_parry_hit()
	else:
		# ── Bala normal: detectar ventana de parry ────────────────
		_check_parry_window()


func _check_parry_window() -> void:
	"""Activa la ventana de parry cuando la bala se acerca al jugador."""
	var player := _find_player()
	if not player or not is_instance_valid(player):
		return

	var dist := global_position.distance_to(player.global_position)

	# Activar ventana cuando está a 65px
	if not _parry_ready and dist < 65.0:
		_parry_ready = true
		if player.has_method("set_parry_window"):
			player.set_parry_window(true)

	# Comprobar si el jugador presiona F dentro de la ventana
	if _parry_ready and dist < 85.0:
		if Input.is_action_just_pressed("use_tool"):
			if player.has_method("set_parry_window"):
				player.set_parry_window(false)
			_do_parry()


func _check_parry_hit() -> void:
	"""Detecta si la bala desviada alcanzó al robot objetivo."""
	if not _parry_target or not is_instance_valid(_parry_target):
		# Sin objetivo válido — destruir si lleva mucho tiempo
		return

	var dist := global_position.distance_to(_parry_target.global_position)
	if dist <= PARRY_HIT_RADIUS:
		_hit_enemy(_parry_target)


# ══════════════════════════════════════════════════════════════════
# PARRY
# ══════════════════════════════════════════════════════════════════

func _do_parry() -> void:
	"""Desvía la bala de vuelta al robot que la disparó."""
	_parried = true

	# Flash en la bala
	if sprite:
		sprite.modulate = Color(3.0, 3.0, 0.5)
		var tw := create_tween()
		tw.tween_property(sprite, "modulate", Color(1.0, 0.9, 0.2), 0.12)

	if has_node("/root/GameManager"):
		GameManager.shake_camera(3.0, 0.12)

	# Determinar objetivo
	_parry_target = _owner_node
	if not _parry_target or not is_instance_valid(_parry_target):
		# Fallback: ukibuki más cercano
		var enemies := get_tree().get_nodes_in_group("enemies")
		var nearest_dist := 9999.0
		for e in enemies:
			if not is_instance_valid(e): continue
			var d := global_position.distance_to(e.global_position)
			if d < nearest_dist:
				nearest_dist = d
				_parry_target = e

	if _parry_target and is_instance_valid(_parry_target):
		var new_dir : Vector2 = (_parry_target.global_position - global_position).normalized()
		velocity = new_dir * (velocity.length() * 1.4)
	else:
		_hit()


# ══════════════════════════════════════════════════════════════════
# COLISIONES (body_entered — para bala normal y geometría)
# ══════════════════════════════════════════════════════════════════

func _on_body_entered(body: Node2D) -> void:
	if has_hit:
		return

	if _parried:
		# Bala desviada: ignorar al jugador, destruirse con geometría
		if body.is_in_group("player") or body.name == "kai":
			return
		if body is StaticBody2D or body is TileMapLayer or body is TileMap:
			_hit()
		# El impacto al robot se maneja por distancia en _check_parry_hit
		return

	# Bala normal
	if body.is_in_group("player") or body.name == "kai":
		if _player_is_crouching(body):
			return   # Esquivada agachándose
		if body.has_method("take_damage"):
			body.take_damage(damage)
		_hit()
		return

	if body is StaticBody2D or body is TileMapLayer or body is TileMap:
		_hit()


func _player_is_crouching(player: Node) -> bool:
	if not player.get("is_crouching"):
		return false
	return abs(velocity.y) < abs(velocity.x) * 1.5


# ══════════════════════════════════════════════════════════════════
# IMPACTO AL ROBOT
# ══════════════════════════════════════════════════════════════════

func _hit_enemy(enemy: Node) -> void:
	if not is_instance_valid(enemy):
		_hit()
		return

	# Daño = 50% de la vida máxima
	var parry_damage : int = 30
	if enemy is Ukibuki:
		parry_damage = int(float(enemy.max_health) * 0.5)
	elif "max_health" in enemy:
		parry_damage = int(float(enemy.max_health) * 0.5)

	if enemy.has_method("take_damage"):
		enemy.take_damage(parry_damage)

	# Flash naranja en el robot
	var espr = enemy.get("sprite") if enemy.get("sprite") != null else null
	if espr and espr is AnimatedSprite2D:
		espr.modulate = Color(2.5, 0.6, 0.0)
		var tw := create_tween()
		tw.tween_property(espr, "modulate", Color.WHITE, 0.3)

	if has_node("/root/GameManager"):
		GameManager.shake_camera(7.0, 0.25)
		GameManager.add_score(150)

	_hit()


# ══════════════════════════════════════════════════════════════════
# HIT / DESTROY
# ══════════════════════════════════════════════════════════════════

func _hit() -> void:
	if has_hit:
		return
	has_hit  = true
	velocity = Vector2.ZERO

	# Apagar flash de parry si estaba activo
	if _parry_ready and not _parried:
		var player := _find_player()
		if player and player.has_method("set_parry_window"):
			player.set_parry_window(false)

	if sprite:
		sprite.visible = false
	if trail:
		trail.emitting = false

	await get_tree().create_timer(0.15).timeout
	_destroy()

func _destroy() -> void:
	if is_inside_tree():
		queue_free()


# ══════════════════════════════════════════════════════════════════
# UTILIDADES
# ══════════════════════════════════════════════════════════════════

func _find_player() -> Node:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	return get_tree().root.find_child("kai", true, false)
