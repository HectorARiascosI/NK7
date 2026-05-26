extends CanvasLayer

## ════════════════════════════════════════════════════════════════
## SELECTOR DE SLOTS DE GUARDADO NK-7
## ════════════════════════════════════════════════════════════════
## Permite al jugador elegir qué partida guardada cargar o eliminar
## ════════════════════════════════════════════════════════════════

signal slot_selected(slot: int)
signal cancelled

# ══════════════════════════════════════════════════════════════════
# NODOS
# ══════════════════════════════════════════════════════════════════

var _panel : PanelContainer
var _title : Label
var _slots_container : VBoxContainer
var _btn_cancel : Button
var _slot_buttons : Array[Dictionary] = []  # {btn: Button, delete_btn: Button, slot: int}

# ══════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ══════════════════════════════════════════════════════════════════

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_load_saves()
	_animate_in()

func _build_ui() -> void:
	# Fondo oscuro que cubre toda la pantalla
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.75)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	# Contenedor raíz para centrar correctamente
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# Panel principal centrado
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(700, 420)
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical   = Control.GROW_DIRECTION_BOTH

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.12, 0.97)
	style.border_color = Color(0.91, 0.63, 0.00, 1.0)
	style.set_border_width_all(2)
	style.set_content_margin_all(28)
	style.corner_radius_top_left     = 6
	style.corner_radius_top_right    = 6
	style.corner_radius_bottom_left  = 6
	style.corner_radius_bottom_right = 6
	_panel.add_theme_stylebox_override("panel", style)
	root.add_child(_panel)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	_panel.add_child(vbox)
	
	# Título
	_title = Label.new()
	_title.text = "SELECCIONAR PARTIDA GUARDADA"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 22)
	_title.add_theme_color_override("font_color", Color(0.91, 0.63, 0.00))
	vbox.add_child(_title)
	
	var sep1 := HSeparator.new()
	vbox.add_child(sep1)
	
	# Contenedor de slots
	_slots_container = VBoxContainer.new()
	_slots_container.add_theme_constant_override("separation", 12)
	vbox.add_child(_slots_container)
	
	var sep2 := HSeparator.new()
	vbox.add_child(sep2)
	
	# Botón cancelar
	_btn_cancel = Button.new()
	_btn_cancel.text = "Cancelar"
	_btn_cancel.custom_minimum_size = Vector2(200, 40)
	_btn_cancel.pressed.connect(_on_cancel)
	
	var cancel_container := HBoxContainer.new()
	cancel_container.alignment = BoxContainer.ALIGNMENT_CENTER
	cancel_container.add_child(_btn_cancel)
	vbox.add_child(cancel_container)

func _load_saves() -> void:
	"""Cargar información de todos los slots"""
	for i in range(GameManager.MAX_SAVE_SLOTS):
		var info := GameManager.get_save_info(i)
		_create_slot_button(i, info)

func _create_slot_button(slot: int, info: Dictionary) -> void:
	"""Crear botón para un slot de guardado con opción de eliminar"""
	var container := HBoxContainer.new()
	container.add_theme_constant_override("separation", 8)
	
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 80)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	if info.get("exists", false):
		# Slot con guardado
		var save_name: String = info.get("save_name", "PARTIDA %d" % (slot + 1))
		var level: int = info.get("level", 1)
		var deaths: int = info.get("deaths", 0)
		var time: float = info.get("time", 0.0)
		var score: int = info.get("score", 0)
		var date: String = info.get("date", "Desconocido")
		
		var time_str := _format_time(time)
		
		btn.text = """%s
Nivel %d | Muertes: %d | Tiempo: %s | Puntos: %d
Guardado: %s""" % [save_name, level, deaths, time_str, score, date]
		
		btn.pressed.connect(_on_slot_pressed.bind(slot))
		
		# Botón de eliminar
		var delete_btn := Button.new()
		delete_btn.text = "🗑️"
		delete_btn.custom_minimum_size = Vector2(60, 80)
		delete_btn.tooltip_text = "Eliminar partida"
		delete_btn.pressed.connect(_on_delete_pressed.bind(slot))
		
		# Estilo rojo para el botón de eliminar
		var delete_style := StyleBoxFlat.new()
		delete_style.bg_color = Color(0.6, 0.1, 0.1)
		delete_style.border_color = Color(1.0, 0.3, 0.3)
		delete_style.set_border_width_all(2)
		delete_btn.add_theme_stylebox_override("normal", delete_style)
		
		var delete_hover := StyleBoxFlat.new()
		delete_hover.bg_color = Color(0.8, 0.2, 0.2)
		delete_hover.border_color = Color(1.0, 0.4, 0.4)
		delete_hover.set_border_width_all(2)
		delete_btn.add_theme_stylebox_override("hover", delete_hover)
		
		container.add_child(btn)
		container.add_child(delete_btn)
		
		_slot_buttons.append({"btn": btn, "delete_btn": delete_btn, "slot": slot, "container": container})
	else:
		# Slot vacío
		btn.text = "SLOT %d - VACÍO" % (slot + 1)
		btn.disabled = true
		container.add_child(btn)
		
		_slot_buttons.append({"btn": btn, "delete_btn": null, "slot": slot, "container": container})
	
	_slots_container.add_child(container)

func _format_time(seconds: float) -> String:
	"""Formatear tiempo en HH:MM:SS"""
	var hours: int = int(seconds / 3600)
	var minutes: int = int((seconds - hours * 3600) / 60)
	var secs: int = int(seconds) % 60
	
	if hours > 0:
		return "%02d:%02d:%02d" % [hours, minutes, secs]
	else:
		return "%02d:%02d" % [minutes, secs]

# ══════════════════════════════════════════════════════════════════
# CALLBACKS
# ══════════════════════════════════════════════════════════════════

func _on_slot_pressed(slot: int) -> void:
	_animate_out()
	await get_tree().create_timer(0.3).timeout
	slot_selected.emit(slot)
	queue_free()

func _on_delete_pressed(slot: int) -> void:
	"""Confirmar y eliminar slot"""
	# Crear diálogo de confirmación
	var confirm_dialog : Control = _create_confirmation_dialog(slot)
	add_child(confirm_dialog)

func _create_confirmation_dialog(slot: int) -> Control:
	"""Crear diálogo de confirmación para eliminar"""
	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Fondo oscuro
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(bg)
	
	# Panel de confirmación
	var confirm_panel := PanelContainer.new()
	confirm_panel.set_anchors_preset(Control.PRESET_CENTER)
	confirm_panel.custom_minimum_size = Vector2(400, 200)
	confirm_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	confirm_panel.grow_vertical   = Control.GROW_DIRECTION_BOTH
	
	var confirm_style := StyleBoxFlat.new()
	confirm_style.bg_color = Color(0.1, 0.1, 0.12)
	confirm_style.border_color = Color(1.0, 0.3, 0.3)
	confirm_style.set_border_width_all(3)
	confirm_style.set_content_margin_all(20)
	confirm_panel.add_theme_stylebox_override("panel", confirm_style)
	overlay.add_child(confirm_panel)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	confirm_panel.add_child(vbox)
	
	# Título
	var title := Label.new()
	title.text = "⚠ CONFIRMAR ELIMINACIÓN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	vbox.add_child(title)
	
	# Mensaje
	var info := GameManager.get_save_info(slot)
	var save_name: String = info.get("save_name", "PARTIDA %d" % (slot + 1))
	
	var message := Label.new()
	message.text = "¿Eliminar la partida\n\"%s\"?\n\nEsta acción no se puede deshacer." % save_name
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.add_theme_font_size_override("font_size", 14)
	vbox.add_child(message)
	
	# Botones
	var btn_container := HBoxContainer.new()
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_container.add_theme_constant_override("separation", 16)
	vbox.add_child(btn_container)
	
	var btn_no := Button.new()
	btn_no.text = "Cancelar"
	btn_no.custom_minimum_size = Vector2(120, 40)
	btn_no.pressed.connect(func(): overlay.queue_free())
	btn_container.add_child(btn_no)
	
	var btn_yes := Button.new()
	btn_yes.text = "Eliminar"
	btn_yes.custom_minimum_size = Vector2(120, 40)
	btn_yes.pressed.connect(func(): 
		_confirm_delete(slot)
		overlay.queue_free()
	)
	btn_container.add_child(btn_yes)
	
	# Animación de entrada
	confirm_panel.modulate.a = 0.0
	confirm_panel.scale = Vector2(0.8, 0.8)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(confirm_panel, "modulate:a", 1.0, 0.2)
	tween.tween_property(confirm_panel, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK)
	
	return overlay

func _confirm_delete(slot: int) -> void:
	"""Eliminar slot confirmado"""
	if GameManager.delete_save(slot):
		# Recargar lista de slots
		_reload_slots()

func _reload_slots() -> void:
	"""Recargar lista de slots después de eliminar"""
	# Limpiar slots actuales
	for slot_data in _slot_buttons:
		if slot_data.has("container"):
			slot_data["container"].queue_free()
	
	_slot_buttons.clear()
	
	# Recargar
	_load_saves()

func _on_cancel() -> void:
	_animate_out()
	await get_tree().create_timer(0.3).timeout
	cancelled.emit()
	queue_free()

# ══════════════════════════════════════════════════════════════════
# ANIMACIONES
# ══════════════════════════════════════════════════════════════════

func _animate_in() -> void:
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.9, 0.9)
	
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_panel, "modulate:a", 1.0, 0.3)
	tween.tween_property(_panel, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _animate_out() -> void:
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_panel, "modulate:a", 0.0, 0.2)
	tween.tween_property(_panel, "scale", Vector2(0.9, 0.9), 0.2)

# ══════════════════════════════════════════════════════════════════
# INPUT
# ══════════════════════════════════════════════════════════════════

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_cancel()
