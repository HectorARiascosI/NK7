extends CanvasLayer

## ════════════════════════════════════════════════════════════════
## PANTALLA DE NOMBRE DE PARTIDA NK-7
## ════════════════════════════════════════════════════════════════
## Solicita nombre de partida antes de iniciar el tutorial
## ════════════════════════════════════════════════════════════════

signal name_confirmed(save_name: String, slot: int)
signal cancelled

# ══════════════════════════════════════════════════════════════════
# CONFIGURACIÓN
# ══════════════════════════════════════════════════════════════════

const MAX_NAME_LENGTH := 20
const MIN_NAME_LENGTH := 3

# ══════════════════════════════════════════════════════════════════
# NODOS
# ══════════════════════════════════════════════════════════════════

var _panel : PanelContainer
var _title : Label
var _subtitle : Label
var _name_input : LineEdit
var _char_counter : Label
var _error_label : Label
var _btn_confirm : Button
var _btn_cancel : Button

var _selected_slot : int = -1

# ══════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ══════════════════════════════════════════════════════════════════

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_animate_in()
	
	# Enfocar el input automáticamente
	await get_tree().create_timer(0.4).timeout
	_name_input.grab_focus()

func _build_ui() -> void:
	# Fondo oscuro que cubre toda la pantalla
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.75)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	# Contenedor raíz que ocupa toda la pantalla para centrar correctamente
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# Panel principal centrado
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(500, 320)
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
	_title.text = "NUEVA PARTIDA"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 26)
	_title.add_theme_color_override("font_color", Color(0.91, 0.63, 0.00))
	vbox.add_child(_title)
	
	# Subtítulo
	_subtitle = Label.new()
	_subtitle.text = "Ingresa un nombre para tu partida"
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.add_theme_font_size_override("font_size", 14)
	_subtitle.add_theme_color_override("font_color", Color(0.7, 0.72, 0.75))
	vbox.add_child(_subtitle)
	
	var sep1 := HSeparator.new()
	vbox.add_child(sep1)
	
	# Espaciador
	var spacer1 := Control.new()
	spacer1.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer1)
	
	# Input de nombre
	_name_input = LineEdit.new()
	_name_input.placeholder_text = "Nombre de la partida..."
	_name_input.max_length = MAX_NAME_LENGTH
	_name_input.custom_minimum_size = Vector2(0, 45)
	_name_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_input.add_theme_font_size_override("font_size", 18)
	_name_input.text_changed.connect(_on_name_changed)
	_name_input.text_submitted.connect(_on_name_submitted)
	vbox.add_child(_name_input)
	
	# Contador de caracteres
	_char_counter = Label.new()
	_char_counter.text = "0 / %d caracteres" % MAX_NAME_LENGTH
	_char_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_char_counter.add_theme_font_size_override("font_size", 11)
	_char_counter.add_theme_color_override("font_color", Color(0.5, 0.52, 0.55))
	vbox.add_child(_char_counter)
	
	# Label de error
	_error_label = Label.new()
	_error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_error_label.add_theme_font_size_override("font_size", 12)
	_error_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	_error_label.visible = false
	vbox.add_child(_error_label)
	
	# Espaciador
	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer2)
	
	var sep2 := HSeparator.new()
	vbox.add_child(sep2)
	
	# Botones
	var btn_container := HBoxContainer.new()
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_container.add_theme_constant_override("separation", 16)
	vbox.add_child(btn_container)
	
	_btn_cancel = Button.new()
	_btn_cancel.text = "Cancelar"
	_btn_cancel.custom_minimum_size = Vector2(140, 40)
	_btn_cancel.pressed.connect(_on_cancel)
	btn_container.add_child(_btn_cancel)
	
	_btn_confirm = Button.new()
	_btn_confirm.text = "Confirmar"
	_btn_confirm.custom_minimum_size = Vector2(140, 40)
	_btn_confirm.disabled = true
	_btn_confirm.pressed.connect(_on_confirm)
	btn_container.add_child(_btn_confirm)
	
	# Hint
	var hint := Label.new()
	hint.text = "[ ENTER - Confirmar | ESC - Cancelar ]"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", Color(0.4, 0.42, 0.45))
	vbox.add_child(hint)

# ══════════════════════════════════════════════════════════════════
# VALIDACIÓN
# ══════════════════════════════════════════════════════════════════

func _on_name_changed(new_text: String) -> void:
	# Actualizar contador
	_char_counter.text = "%d / %d caracteres" % [new_text.length(), MAX_NAME_LENGTH]
	
	# Validar nombre
	var validation := _validate_name(new_text)
	
	if validation.valid:
		_error_label.visible = false
		_btn_confirm.disabled = false
		_char_counter.add_theme_color_override("font_color", Color(0.5, 0.52, 0.55))
	else:
		_error_label.text = validation.error
		_error_label.visible = true
		_btn_confirm.disabled = true
		_char_counter.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))

func _validate_name(name: String) -> Dictionary:
	"""Validar nombre de partida"""
	var trimmed := name.strip_edges()
	
	if trimmed.length() < MIN_NAME_LENGTH:
		return {"valid": false, "error": "⚠ Mínimo %d caracteres" % MIN_NAME_LENGTH}
	
	if trimmed.length() > MAX_NAME_LENGTH:
		return {"valid": false, "error": "⚠ Máximo %d caracteres" % MAX_NAME_LENGTH}
	
	# Verificar caracteres válidos (letras, números, espacios, guiones)
	var regex := RegEx.new()
	regex.compile("^[a-zA-Z0-9áéíóúÁÉÍÓÚñÑ _-]+$")
	if not regex.search(trimmed):
		return {"valid": false, "error": "⚠ Solo letras, números, espacios y guiones"}
	
	return {"valid": true, "error": ""}

# ══════════════════════════════════════════════════════════════════
# CALLBACKS
# ══════════════════════════════════════════════════════════════════

func _on_name_submitted(text: String) -> void:
	"""Callback cuando presiona ENTER"""
	if not _btn_confirm.disabled:
		_on_confirm()

func _on_confirm() -> void:
	var name := _name_input.text.strip_edges()
	var validation := _validate_name(name)
	
	if not validation.valid:
		return
	
	# Convertir a mayúsculas
	name = name.to_upper()
	
	# Buscar slot disponible
	var slot := _find_available_slot()
	if slot == -1:
		_error_label.text = "⚠ No hay slots disponibles"
		_error_label.visible = true
		return
	
	_animate_out()
	await get_tree().create_timer(0.3).timeout
	name_confirmed.emit(name, slot)
	queue_free()

func _on_cancel() -> void:
	_animate_out()
	await get_tree().create_timer(0.3).timeout
	cancelled.emit()
	queue_free()

func _find_available_slot() -> int:
	"""Encontrar el primer slot disponible"""
	for i in range(GameManager.MAX_SAVE_SLOTS):
		var info := GameManager.get_save_info(i)
		if not info.get("exists", false):
			return i
	return -1

# ══════════════════════════════════════════════════════════════════
# ANIMACIONES
# ══════════════════════════════════════════════════════════════════

func _animate_in() -> void:
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.85, 0.85)
	
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_panel, "modulate:a", 1.0, 0.35)
	tween.tween_property(_panel, "scale", Vector2(1.0, 1.0), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _animate_out() -> void:
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_panel, "modulate:a", 0.0, 0.25)
	tween.tween_property(_panel, "scale", Vector2(0.9, 0.9), 0.25)

# ══════════════════════════════════════════════════════════════════
# INPUT
# ══════════════════════════════════════════════════════════════════

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_cancel()
