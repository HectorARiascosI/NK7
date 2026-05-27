extends Node

## ════════════════════════════════════════════════════════════════
## COMBAT MANAGER — NK-7
## ════════════════════════════════════════════════════════════════
## Autoload que centraliza toda la lógica de combate:
##   - Sistema de combo (multiplicador de score)
##   - Hit-stop (freeze frame al golpear)
##   - Notificaciones flotantes de daño
##   - Alertas entre enemigos
##   - Drop de items al morir enemigos
## ════════════════════════════════════════════════════════════════

signal combo_changed(count: int, multiplier: float)
signal combo_broken()
signal hit_landed(damage: int, position: Vector2, is_crit: bool)

# ── Combo ─────────────────────────────────────────────────────────
const COMBO_TIMEOUT     : float = 3.5   ## s sin golpear para romper combo
const COMBO_MULT_STEP   : float = 0.25  ## multiplicador extra por golpe
const COMBO_MAX_MULT    : float = 4.0   ## tope del multiplicador

var combo_count      : int   = 0
var combo_multiplier : float = 1.0
var _combo_timer     : float = 0.0

# ── Hit-stop ──────────────────────────────────────────────────────
const HIT_STOP_NORMAL : float = 0.06   ## s de freeze en golpe normal
const HIT_STOP_HEAVY  : float = 0.12   ## s de freeze en golpe fuerte
var _hit_stop_timer   : float = 0.0
var _in_hit_stop      : bool  = false

# ── Alertas entre enemigos ────────────────────────────────────────
const ALERT_RADIUS : float = 350.0   ## px — radio de alerta a aliados

# ── Drop de energía ───────────────────────────────────────────────
## Probabilidad de que un enemigo suelte un orbe de energía al morir
const ENERGY_DROP_CHANCE : float = 0.35

# ══════════════════════════════════════════════════════════════════

func _process(delta: float) -> void:
	# Hit-stop: congelar el árbol brevemente
	if _in_hit_stop:
		_hit_stop_timer -= delta
		if _hit_stop_timer <= 0.0:
			_in_hit_stop = false
			Engine.time_scale = 1.0
		return

	# Combo timeout
	if combo_count > 0:
		_combo_timer -= delta
		if _combo_timer <= 0.0:
			_break_combo()

# ══════════════════════════════════════════════════════════════════
# COMBO
# ══════════════════════════════════════════════════════════════════

func register_hit(damage: int, position: Vector2, is_heavy: bool = false) -> int:
	"""Registrar un golpe. Devuelve el daño real con multiplicador."""
	combo_count      += 1
	_combo_timer      = COMBO_TIMEOUT
	combo_multiplier  = min(1.0 + (combo_count - 1) * COMBO_MULT_STEP, COMBO_MAX_MULT)

	var real_damage := int(float(damage) * combo_multiplier)
	var is_crit     := combo_count > 0 and combo_count % 5 == 0

	combo_changed.emit(combo_count, combo_multiplier)
	hit_landed.emit(real_damage, position, is_crit)

	# Puntuación con multiplicador
	if has_node("/root/GameManager"):
		GameManager.add_score(int(10.0 * combo_multiplier))

	# Hit-stop
	_trigger_hit_stop(HIT_STOP_HEAVY if is_heavy else HIT_STOP_NORMAL)

	# Número flotante de daño
	_spawn_damage_number(real_damage, position, is_crit)

	return real_damage

func _break_combo() -> void:
	combo_count      = 0
	combo_multiplier = 1.0
	_combo_timer     = 0.0
	combo_broken.emit()

func reset_combo() -> void:
	_break_combo()

# ══════════════════════════════════════════════════════════════════
# HIT-STOP
# ══════════════════════════════════════════════════════════════════

func _trigger_hit_stop(duration: float) -> void:
	if not GameManager.screen_shake_enabled:
		return
	_in_hit_stop    = true
	_hit_stop_timer = duration
	Engine.time_scale = 0.05   ## casi congelado

# ══════════════════════════════════════════════════════════════════
# NÚMEROS FLOTANTES DE DAÑO
# ══════════════════════════════════════════════════════════════════

func _spawn_damage_number(damage: int, world_pos: Vector2, is_crit: bool) -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 25
	get_tree().root.add_child(canvas)

	var label := Label.new()
	label.text = ("CRIT! %d" % damage) if is_crit else str(damage)

	var color := Color(1.0, 0.9, 0.1) if is_crit else Color(1.0, 0.4, 0.4)
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 20 if is_crit else 14)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Convertir posición mundo → pantalla
	var viewport := get_tree().root.get_viewport()
	var screen_pos := viewport.get_camera_2d().get_screen_center_position() \
		if viewport.get_camera_2d() else world_pos
	# Usar la cámara del jugador para proyectar
	var cam := GameManager.get_camera()
	if cam:
		var vp_size := cam.get_viewport_rect().size
		var cam_pos := cam.global_position
		var zoom    := cam.zoom
		screen_pos = (world_pos - cam_pos) * zoom + vp_size * 0.5
	else:
		screen_pos = world_pos

	label.position = screen_pos + Vector2(randf_range(-20, 20), -20)
	canvas.add_child(label)

	# Animación: sube y desaparece
	var tw := create_tween().set_parallel(true)
	tw.tween_property(label, "position:y", label.position.y - 50, 0.8).set_ease(Tween.EASE_OUT)
	tw.tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.3)
	await tw.finished
	canvas.queue_free()

# ══════════════════════════════════════════════════════════════════
# ALERTAS ENTRE ENEMIGOS
# ══════════════════════════════════════════════════════════════════

func alert_nearby_enemies(source_pos: Vector2, exclude: Node = null) -> void:
	"""Alertar a todos los enemigos en radio ALERT_RADIUS."""
	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy): continue
		if enemy == exclude: continue
		if source_pos.distance_to(enemy.global_position) > ALERT_RADIUS: continue
		# Ukibuki
		if enemy.has_method("_change_state") and "State" in enemy:
			var alert_state = enemy.State.get("ALERT", -1)
			if alert_state != -1 and enemy.current_state == enemy.State.PATROL:
				enemy._change_state(enemy.State.ALERT)
		# Guardia
		elif enemy.has_method("_set_state") and "State" in enemy:
			if enemy.current_state == enemy.State.PATROL:
				enemy._set_state(enemy.State.ALERT)

# ══════════════════════════════════════════════════════════════════
# DROP DE ENERGÍA
# ══════════════════════════════════════════════════════════════════

func try_drop_energy(world_pos: Vector2) -> void:
	"""Intentar soltar un orbe de energía en la posición dada."""
	if randf() > ENERGY_DROP_CHANCE:
		return
	_spawn_energy_orb(world_pos)

func _spawn_energy_orb(world_pos: Vector2) -> void:
	"""Crear un orbe de energía temporal que el jugador puede recoger."""
	var orb := Area2D.new()
	orb.position = world_pos
	orb.collision_layer = 0
	orb.collision_mask  = 1

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 18.0
	shape.shape = circle
	orb.add_child(shape)

	# Visual: pequeño círculo cyan
	var sprite := ColorRect.new()
	sprite.size = Vector2(14, 14)
	sprite.position = Vector2(-7, -7)
	sprite.color = Color(0.2, 1.0, 0.9, 0.9)
	orb.add_child(sprite)

	# Luz
	var light := PointLight2D.new()
	light.color  = Color(0.2, 1.0, 0.9)
	light.energy = 1.5
	light.texture_scale = 0.3
	orb.add_child(light)

	get_tree().root.add_child(orb)

	# Flotación
	var tw := create_tween().set_loops()
	tw.tween_property(orb, "position:y", world_pos.y - 12, 0.6).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(orb, "position:y", world_pos.y,      0.6).set_ease(Tween.EASE_IN_OUT)

	# Recoger al tocar jugador
	orb.body_entered.connect(func(body: Node2D):
		if body.is_in_group("player") or body.name == "kai":
			if body.has_method("restore_energy"):
				body.restore_energy(30.0)
			if has_node("/root/AudioManager"):
				AudioManager.play_sfx("energy")
			tw.kill()
			orb.queue_free()
	)

	# Auto-destruir en 12 segundos
	get_tree().create_timer(12.0).timeout.connect(func():
		if is_instance_valid(orb):
			tw.kill()
			orb.queue_free()
	)
