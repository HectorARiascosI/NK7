extends Control

## ════════════════════════════════════════════════════════════════
## PANTALLA DE PERFIL Y LOGROS — NK-7
## ════════════════════════════════════════════════════════════════
## Muestra estadísticas globales y lista de logros.
## Se abre desde el menú principal (botón "Perfil").
## ════════════════════════════════════════════════════════════════

signal closed

# ── Colores NK-7 ──────────────────────────────────────────────────
const C_BG        := Color(0.05, 0.07, 0.10, 0.96)
const C_PANEL     := Color(0.08, 0.12, 0.16, 1.00)
const C_BORDER    := Color(0.20, 0.60, 0.80, 1.00)
const C_TITLE     := Color(0.20, 1.00, 0.80, 1.00)
const C_GOLD      := Color(1.00, 0.80, 0.20, 1.00)
const C_ORANGE    := Color(1.00, 0.50, 0.20, 1.00)
const C_LOCKED    := Color(0.35, 0.35, 0.40, 1.00)
const C_UNLOCKED  := Color(0.90, 0.90, 1.00, 1.00)
const C_SECRET    := Color(0.50, 0.50, 0.60, 1.00)

var _root         : Control
var _scroll       : ScrollContainer
var _list_vbox    : VBoxContainer
var _stats_panel  : Control
var _close_btn    : Control

# ══════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ══════════════════════════════════════════════════════════════════

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	_populate()
	_animate_in()

func _build_ui() -> void:
	# Fondo oscuro semitransparente
	var bg := ColorRect.new()
	bg.color = C_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	
	# Panel central
	var panel := _make_panel(Vector2(900, 580), Vector2(190, 70))
	add_child(panel)
	
	# Título
	var title := Label.new()
	title.text = "[ PERFIL — NK-7 ]"
	title.position = Vector2(0, 14)
	title.size = Vector2(900, 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", C_TITLE)
	panel.add_child(title)
	
	# Separador
	var sep := ColorRect.new()
	sep.color = C_BORDER
	sep.position = Vector2(20, 50)
	sep.size = Vector2(860, 2)
	panel.add_child(sep)
	
	# Panel de estadísticas (izquierda)
	_stats_panel = Control.new()
	_stats_panel.position = Vector2(20, 60)
	_stats_panel.size = Vector2(260, 480)
	panel.add_child(_stats_panel)
	_build_stats_panel()
	
	# Separador vertical
	var vsep := ColorRect.new()
	vsep.color = C_BORDER
	vsep.position = Vector2(290, 60)
	vsep.size = Vector2(2, 480)
	panel.add_child(vsep)
	
	# Lista de logros (derecha)
	_scroll = ScrollContainer.new()
	_scroll.position = Vector2(300, 60)
	_scroll.size = Vector2(580, 480)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(_scroll)
	
	_list_vbox = VBoxContainer.new()
	_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_vbox.add_theme_constant_override("separation", 6)
	_scroll.add_child(_list_vbox)
	
	# Botón cerrar
	_close_btn = _make_close_button(panel)
	panel.add_child(_close_btn)

func _make_panel(size: Vector2, pos: Vector2) -> Control:
	var c := Control.new()
	c.position = pos
	c.size = size
	
	var bg := ColorRect.new()
	bg.color = C_PANEL
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.add_child(bg)
	
	# Borde
	for edge in [
		[Vector2(0, 0), Vector2(size.x, 2)],
		[Vector2(0, size.y - 2), Vector2(size.x, 2)],
		[Vector2(0, 0), Vector2(2, size.y)],
		[Vector2(size.x - 2, 0), Vector2(2, size.y)],
	]:
		var b := ColorRect.new()
		b.color = C_BORDER
		b.position = edge[0]
		b.size = edge[1]
		c.add_child(b)
	
	return c

func _make_close_button(parent: Control) -> Control:
	var btn := Control.new()
	btn.position = Vector2(parent.size.x - 44, 8)
	btn.size = Vector2(36, 36)
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var bg := ColorRect.new()
	bg.color = Color(0.6, 0.1, 0.1, 0.8)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.add_child(bg)
	
	var lbl := Label.new()
	lbl.text = "✕"
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(lbl)
	
	btn.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton:
			var mb := event as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
				_close()
	)
	btn.mouse_entered.connect(func(): bg.color = Color(0.9, 0.2, 0.2, 0.9))
	btn.mouse_exited.connect(func():  bg.color = Color(0.6, 0.1, 0.1, 0.8))
	
	return btn

# ══════════════════════════════════════════════════════════════════
# ESTADÍSTICAS
# ══════════════════════════════════════════════════════════════════

func _build_stats_panel() -> void:
	var y := 0.0
	
	# Título sección
	_add_stat_label("ESTADÍSTICAS", y, C_TITLE, 14, true)
	y += 30
	
	# Progreso de logros
	var unlocked := AchievementManager.get_unlocked_count()
	var total    := AchievementManager.get_total_count()
	var pct      := AchievementManager.get_completion_percent()
	
	_add_stat_label("Logros", y, C_BORDER, 11)
	y += 18
	_add_stat_value("%d / %d  (%.0f%%)" % [unlocked, total, pct], y, C_GOLD)
	y += 24
	
	# Barra de progreso de logros
	_add_progress_bar(y, pct / 100.0, C_GOLD)
	y += 20
	
	# Separador
	y += 10
	var sep := ColorRect.new()
	sep.color = Color(C_BORDER.r, C_BORDER.g, C_BORDER.b, 0.4)
	sep.position = Vector2(0, y)
	sep.size = Vector2(260, 1)
	_stats_panel.add_child(sep)
	y += 14
	
	# Estadísticas de partida
	_add_stat_label("PARTIDA ACTUAL", y, C_TITLE, 12, true)
	y += 24
	
	var stats := [
		["Nivel actual",   str(GameManager.current_level)],
		["Muertes",        str(GameManager.total_deaths)],
		["Tiempo total",   _format_time(GameManager.total_time)],
		["Puntuación",     "%06d" % GameManager.get_score()],
		["Niveles claros", str(GameManager.levels_completed.size())],
	]
	
	for stat in stats:
		_add_stat_label(stat[0], y, C_LOCKED, 11)
		y += 16
		_add_stat_value(stat[1], y, C_UNLOCKED)
		y += 22
	
	# Separador
	y += 6
	var sep2 := ColorRect.new()
	sep2.color = Color(C_BORDER.r, C_BORDER.g, C_BORDER.b, 0.4)
	sep2.position = Vector2(0, y)
	sep2.size = Vector2(260, 1)
	_stats_panel.add_child(sep2)
	y += 14
	
	# Contadores globales
	_add_stat_label("COLECCIONABLES", y, C_TITLE, 12, true)
	y += 24
	
	var counters := [
		["Enemigos destruidos", str(AchievementManager.get_counter("enemies_killed"))],
		["Monedas recogidas",   str(AchievementManager.get_counter("coins_collected"))],
		["Cubos recogidos",     str(AchievementManager.get_counter("cubes_collected"))],
		["Checkpoints",         str(AchievementManager.get_counter("checkpoints_reached"))],
	]
	
	for c in counters:
		_add_stat_label(c[0], y, C_LOCKED, 11)
		y += 16
		_add_stat_value(c[1], y, C_ORANGE)
		y += 22

func _add_stat_label(text: String, y: float, color: Color, size: int = 11, bold: bool = false) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.position = Vector2(0, y)
	lbl.size = Vector2(260, 20)
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stats_panel.add_child(lbl)

func _add_stat_value(text: String, y: float, color: Color) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.position = Vector2(10, y)
	lbl.size = Vector2(250, 20)
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", color)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stats_panel.add_child(lbl)

func _add_progress_bar(y: float, fill: float, color: Color) -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.15)
	bg.position = Vector2(0, y)
	bg.size = Vector2(260, 12)
	_stats_panel.add_child(bg)
	
	var bar := ColorRect.new()
	bar.color = color
	bar.position = Vector2(0, y)
	bar.size = Vector2(260.0 * fill, 12)
	_stats_panel.add_child(bar)

# ══════════════════════════════════════════════════════════════════
# LISTA DE LOGROS
# ══════════════════════════════════════════════════════════════════

func _populate() -> void:
	var achievements := AchievementManager.get_all_achievements()
	
	# Título
	var header := Label.new()
	header.text = "LOGROS  (%d/%d)" % [
		AchievementManager.get_unlocked_count(),
		AchievementManager.get_total_count()
	]
	header.add_theme_font_size_override("font_size", 14)
	header.add_theme_color_override("font_color", C_TITLE)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_list_vbox.add_child(header)
	
	# Separador
	var sep := ColorRect.new()
	sep.color = C_BORDER
	sep.custom_minimum_size = Vector2(0, 2)
	sep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_vbox.add_child(sep)
	
	# Primero los desbloqueados, luego los bloqueados
	var unlocked_list : Array = achievements.filter(func(a): return a["unlocked"])
	var locked_list   : Array = achievements.filter(func(a): return not a["unlocked"])
	
	for a in unlocked_list:
		_list_vbox.add_child(_make_achievement_row(a))
	
	if locked_list.size() > 0:
		var sep2 := ColorRect.new()
		sep2.color = Color(C_BORDER.r, C_BORDER.g, C_BORDER.b, 0.4)
		sep2.custom_minimum_size = Vector2(0, 1)
		sep2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_list_vbox.add_child(sep2)
	
	for a in locked_list:
		_list_vbox.add_child(_make_achievement_row(a))

func _make_achievement_row(a: Dictionary) -> Control:
	var row := Control.new()
	row.custom_minimum_size = Vector2(0, 52)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var is_unlocked : bool = a["unlocked"]
	var is_secret   : bool = a.get("secret", false)
	
	# Fondo de fila
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.12, 0.18, 0.22, 0.8) if is_unlocked else Color(0.06, 0.08, 0.10, 0.6)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(bg)
	
	# Borde izquierdo de color
	var accent := ColorRect.new()
	accent.position = Vector2(0, 4)
	accent.size = Vector2(3, 44)
	accent.color = C_GOLD if is_unlocked else C_LOCKED
	row.add_child(accent)
	
	# Icono
	var icon_lbl := Label.new()
	icon_lbl.text = a.get("icon", "?") if (is_unlocked or not is_secret) else "?"
	icon_lbl.position = Vector2(10, 10)
	icon_lbl.size = Vector2(32, 32)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_lbl.add_theme_font_size_override("font_size", 20)
	icon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon_lbl)
	
	# Nombre
	var name_lbl := Label.new()
	var display_name : String
	if is_secret and not is_unlocked:
		display_name = "???"
	else:
		display_name = a["name"]
	name_lbl.text = display_name
	name_lbl.position = Vector2(50, 8)
	name_lbl.size = Vector2(480, 20)
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.add_theme_color_override("font_color", C_UNLOCKED if is_unlocked else C_LOCKED)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(name_lbl)
	
	# Descripción
	var desc_lbl := Label.new()
	var display_desc : String
	if is_secret and not is_unlocked:
		display_desc = "Logro secreto"
	else:
		display_desc = a["desc"]
	desc_lbl.text = display_desc
	desc_lbl.position = Vector2(50, 28)
	desc_lbl.size = Vector2(480, 18)
	desc_lbl.add_theme_font_size_override("font_size", 10)
	desc_lbl.add_theme_color_override("font_color", C_SECRET if is_secret and not is_unlocked else Color(0.65, 0.65, 0.70))
	desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(desc_lbl)
	
	# Fecha de desbloqueo
	if is_unlocked:
		var time_lbl := Label.new()
		var ts : int = a.get("time", 0)
		var dt := Time.get_datetime_dict_from_unix_time(ts)
		time_lbl.text = "%02d/%02d/%04d" % [dt["day"], dt["month"], dt["year"]]
		time_lbl.position = Vector2(490, 18)
		time_lbl.size = Vector2(80, 16)
		time_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		time_lbl.add_theme_font_size_override("font_size", 9)
		time_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		time_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(time_lbl)
	
	return row

# ══════════════════════════════════════════════════════════════════
# ANIMACIONES
# ══════════════════════════════════════════════════════════════════

func _animate_in() -> void:
	modulate.a = 0.0
	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "modulate:a", 1.0, 0.25)

func _close() -> void:
	AudioManager.play_sfx("ui_cancel")
	var tw := create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "modulate:a", 0.0, 0.20)
	await tw.finished
	closed.emit()
	queue_free()

# ══════════════════════════════════════════════════════════════════
# INPUT
# ══════════════════════════════════════════════════════════════════

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_close()

# ══════════════════════════════════════════════════════════════════
# UTILIDADES
# ══════════════════════════════════════════════════════════════════

func _format_time(seconds: float) -> String:
	var h := int(seconds / 3600)
	var m := int(seconds / 60) % 60
	var s := int(seconds) % 60
	if h > 0:
		return "%dh %02dm %02ds" % [h, m, s]
	return "%02dm %02ds" % [m, s]
