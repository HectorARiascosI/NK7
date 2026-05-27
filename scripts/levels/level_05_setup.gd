extends Node

## ════════════════════════════════════════════════════════════════
## LEVEL 05 — REACTOR CORE: GUERRA TOTAL
## ════════════════════════════════════════════════════════════════
## El reactor está en colapso. Todos los sistemas de seguridad
## se han vuelto locos y atacan a todo lo que se mueve.
## Kai tiene más resistencia aquí — el traje de emergencia activa
## sus escudos al máximo.
##
## Mecánicas:
##   - Kai empieza con HP aumentado (150)
##   - Explosiones aleatorias cada pocos segundos
##   - Todos los enemigos en estado ALERT desde el inicio
##   - Música de emergencia industrial
##   - Al matar a todos los enemigos → secuencia de escape
## ════════════════════════════════════════════════════════════════

var _explosion_timer : float = 0.0
var _explosion_interval : float = 3.5
var _enemies_killed : int = 0
var _total_enemies  : int = 0
var _war_started    : bool = false

func _ready() -> void:
	await get_tree().process_frame
	_boost_kai()
	_setup_hud()
	_count_enemies()
	await get_tree().create_timer(0.5).timeout
	_start_war()

func _process(delta: float) -> void:
	if not _war_started: return
	_explosion_timer += delta
	if _explosion_timer >= _explosion_interval:
		_explosion_timer = 0.0
		_explosion_interval = randf_range(2.0, 5.0)
		_spawn_random_explosion()

# ── Kai más resistente ────────────────────────────────────────────

func _boost_kai() -> void:
	var kai := _search_node(get_tree().root, "kai")
	if not kai: return
	# Aumentar HP al máximo extendido
	if "health" in kai:
		kai.health = 150.0
	# Reducir i-frames para que sea más justo pero aguante más
	if "MAX_HEALTH" in kai:
		pass  # La constante no se puede cambiar, pero el HP extra ya ayuda

# ── HUD ───────────────────────────────────────────────────────────

func _setup_hud() -> void:
	var hud := _search_node(get_tree().root, "PlayerHUD")
	if hud and hud.has_method("show_timer"):
		hud.show_timer()
	# Música de guerra
	if has_node("/root/AudioManager"):
		AudioManager.play_music("level_05")

# ── Contar enemigos ───────────────────────────────────────────────

func _count_enemies() -> void:
	await get_tree().process_frame
	var enemies := get_tree().get_nodes_in_group("enemies")
	_total_enemies = enemies.size()
	# Conectar señal destroyed de cada enemigo
	for enemy in enemies:
		if enemy.has_signal("destroyed"):
			enemy.destroyed.connect(_on_enemy_destroyed)

# ── Iniciar guerra — todos en ALERT ──────────────────────────────

func _start_war() -> void:
	_war_started = true
	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy): continue
		# Forzar estado ALERT en todos
		if enemy.has_method("_change_state") and "State" in enemy:
			enemy._change_state(enemy.State.ALERT)
		elif enemy.has_method("_set_state") and "State" in enemy:
			enemy._set_state(enemy.State.ALERT)
	# Mensaje de inicio
	_show_war_message("⚠ PROTOCOLO DE EMERGENCIA ACTIVADO", Color(1.0, 0.2, 0.2))

# ── Explosiones aleatorias ────────────────────────────────────────

func _spawn_random_explosion() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 10
	get_tree().root.add_child(canvas)

	# Posición aleatoria en pantalla
	var vp := get_viewport().get_visible_rect()
	var pos := Vector2(
		randf_range(vp.position.x + 50, vp.end.x - 50),
		randf_range(vp.position.y + 50, vp.end.y - 50)
	)

	# Flash de explosión
	var flash := ColorRect.new()
	flash.color = Color(1.0, 0.6, 0.1, 0.0)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(flash)

	# Círculo de explosión
	var label := Label.new()
	label.text = ["💥", "🔥", "⚡", "💣"][randi() % 4]
	label.add_theme_font_size_override("font_size", randi_range(24, 48))
	label.position = pos
	canvas.add_child(label)

	# Sacudir cámara
	if has_node("/root/GameManager"):
		GameManager.shake_camera(randf_range(3.0, 8.0), 0.2)

	# Sonido
	if has_node("/root/AudioManager"):
		AudioManager.play_sfx("ukibuki_destroy", randf_range(-0.3, 0.3))

	# Animación
	var tw := create_tween().set_parallel(true)
	tw.tween_property(flash, "color:a", 0.4, 0.05)
	tw.tween_property(label, "modulate:a", 1.0, 0.05)
	await tw.finished
	var tw2 := create_tween().set_parallel(true)
	tw2.tween_property(flash, "color:a", 0.0, 0.3)
	tw2.tween_property(label, "modulate:a", 0.0, 0.4)
	tw2.tween_property(label, "position:y", pos.y - 60, 0.4).set_ease(Tween.EASE_OUT)
	await tw2.finished
	canvas.queue_free()

# ── Enemigo muerto ────────────────────────────────────────────────

func _on_enemy_destroyed() -> void:
	_enemies_killed += 1
	_show_war_message(
		"%d / %d eliminados" % [_enemies_killed, _total_enemies],
		Color(0.3, 1.0, 0.5)
	)
	if _enemies_killed >= _total_enemies:
		_start_escape_sequence()

# ── Secuencia de escape ───────────────────────────────────────────

func _start_escape_sequence() -> void:
	_war_started = false
	_show_war_message("✓ REACTOR DESPEJADO — INICIANDO PROTOCOLO DE ESCAPE", Color(0.3, 1.0, 0.5))

	if has_node("/root/AudioManager"):
		AudioManager.stop_music()

	await get_tree().create_timer(2.0).timeout

	# Flash blanco de victoria
	var canvas := CanvasLayer.new()
	canvas.layer = 100
	get_tree().root.add_child(canvas)
	var white := ColorRect.new()
	white.color = Color.WHITE
	white.modulate.a = 0.0
	white.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(white)
	var tw := create_tween()
	tw.tween_property(white, "modulate:a", 1.0, 1.5)
	await tw.finished

	if has_node("/root/GameManager"):
		GameManager.complete_level("level_05")
		GameManager.transition_to_scene("res://scenes/ui/main_menu.tscn")

# ── Mensaje en pantalla ───────────────────────────────────────────

func _show_war_message(text: String, color: Color) -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 20
	get_tree().root.add_child(canvas)
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 16)
	label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position.y = 40
	label.modulate.a = 0.0
	canvas.add_child(label)
	var tw := create_tween()
	tw.tween_property(label, "modulate:a", 1.0, 0.2)
	tw.tween_interval(2.5)
	tw.tween_property(label, "modulate:a", 0.0, 0.5)
	await tw.finished
	canvas.queue_free()

func _search_node(node: Node, target_name: String) -> Node:
	if node.name == target_name: return node
	for child in node.get_children():
		var result := _search_node(child, target_name)
		if result: return result
	return null
