extends CanvasLayer

## Sistema de diálogo y burbujas de tutorial para NK7
## Bloquea el input del jugador mientras hay diálogo activo.

signal dialogue_finished
signal line_finished

## Variable estática accesible desde cualquier script.
## Kai la consulta antes de procesar input.
static var is_active : bool = false

# ── Nodos (se crean en _build_ui) ────────────────────────────────
var panel        : PanelContainer = null
var portrait     : TextureRect    = null
var name_label   : Label          = null
var text_label   : RichTextLabel  = null
var continue_hint: Label          = null

# ── Config ───────────────────────────────────────────────────────
@export var chars_per_second : float = 40.0
@export var auto_advance     : bool  = false
@export var auto_delay       : float = 2.5

# ── Estado ───────────────────────────────────────────────────────
var _lines       : Array[Dictionary] = []
var _current     : int    = 0
var _typing      : bool   = false
var _full_text   : String = ""
var _char_index  : float  = 0.0
var _can_advance : bool   = false
var _blink_t     : float  = 0.0

# ── Paleta ───────────────────────────────────────────────────────
const C_KAI    := Color(0.55, 0.80, 1.00, 1.0)
const C_RENA   := Color(0.80, 0.55, 1.00, 1.0)
const C_SYSTEM := Color(0.91, 0.63, 0.00, 1.0)
const C_HINT   := Color(0.60, 0.85, 0.60, 1.0)

# ════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ════════════════════════════════════════════════════════════════

func _ready() -> void:
	layer = 10
	hide()
	_build_ui()

func _build_ui() -> void:
	# Construir la UI del diálogo completamente en código
	# para no depender de escenas externas

	# Panel principal
	var p := PanelContainer.new()
	p.name = "Panel"
	p.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	p.offset_top    = -140.0
	p.offset_bottom = -8.0
	p.offset_left   = 12.0
	p.offset_right  = -12.0

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.08, 0.11, 0.96)
	sb.border_color = Color(0.29, 0.31, 0.38, 0.9)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(0)
	sb.set_content_margin_all(10)
	p.add_theme_stylebox_override("panel", sb)
	add_child(p)

	# HBox exterior (portrait + contenido)
	var hbox := HBoxContainer.new()
	hbox.name = "HBox"
	hbox.add_theme_constant_override("separation", 12)
	p.add_child(hbox)

	# Portrait
	var port := TextureRect.new()
	port.name = "Portrait"
	port.custom_minimum_size = Vector2(80, 80)
	port.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	port.visible = false
	hbox.add_child(port)

	# VBox de texto
	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 4)
	hbox.add_child(vbox)

	# Nombre del hablante
	var nl := Label.new()
	nl.name = "NameLabel"
	nl.add_theme_font_size_override("font_size", 14)
	nl.add_theme_color_override("font_color", C_KAI)
	nl.visible = false
	vbox.add_child(nl)

	# Texto del diálogo
	var tl := RichTextLabel.new()
	tl.name = "TextLabel"
	tl.bbcode_enabled = true
	tl.fit_content = true
	tl.scroll_active = false
	tl.add_theme_font_size_override("normal_font_size", 16)
	tl.add_theme_color_override("default_color", Color(0.88, 0.90, 0.94, 1.0))
	vbox.add_child(tl)

	# Hint de continuar
	var ch := Label.new()
	ch.name = "ContinueHint"
	ch.add_theme_font_size_override("font_size", 11)
	ch.add_theme_color_override("font_color", Color(0.40, 0.43, 0.50, 0.8))
	ch.text = "[ ESPACIO / ENTER ]  CONTINUAR"
	ch.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ch.visible = false
	vbox.add_child(ch)

	# Reasignar referencias
	panel        = p
	portrait     = port
	name_label   = nl
	text_label   = tl
	continue_hint = ch


# ════════════════════════════════════════════════════════════════
# API PÚBLICA
# ════════════════════════════════════════════════════════════════

## Mostrar una secuencia de líneas de diálogo.
## Cada línea es un Dictionary con:
##   "text"     : String  (requerido)
##   "speaker"  : String  (opcional, "" = sin nombre)
##   "type"     : String  (opcional: "kai", "rena", "system", "hint")
##   "portrait" : Texture2D (opcional)
func show_dialogue(lines: Array[Dictionary]) -> void:
	_lines   = lines
	_current = 0
	is_active = true   # ← bloquear input del jugador
	show()
	_show_line(_current)

func show_hint(text: String, speaker: String = "TUTORIAL") -> void:
	show_dialogue([{"text": text, "speaker": speaker, "type": "hint"}])

func show_system(text: String) -> void:
	show_dialogue([{"text": text, "speaker": "SISTEMA NK7", "type": "system"}])

func close() -> void:
	is_active = false  # ← desbloquear input del jugador
	hide()
	_typing = false
	_can_advance = false
	dialogue_finished.emit()


# ════════════════════════════════════════════════════════════════
# LÓGICA INTERNA
# ════════════════════════════════════════════════════════════════

func _show_line(index: int) -> void:
	if index >= _lines.size():
		close()
		return

	var line : Dictionary = _lines[index]
	var text    : String = line.get("text",    "")
	var speaker : String = line.get("speaker", "")
	var ltype   : String = line.get("type",    "kai")
	var tex     : Texture2D = line.get("portrait", null)

	# Color del nombre según tipo
	var name_color := C_KAI
	match ltype:
		"rena":   name_color = C_RENA
		"system": name_color = C_SYSTEM
		"hint":   name_color = C_HINT

	# Configurar nombre
	if speaker != "":
		name_label.text = speaker
		name_label.add_theme_color_override("font_color", name_color)
		name_label.visible = true
	else:
		name_label.visible = false

	# Configurar portrait
	if tex != null:
		portrait.texture = tex
		portrait.visible = true
	else:
		portrait.visible = false

	# Iniciar typewriter
	_full_text  = text
	_char_index = 0.0
	_typing     = true
	_can_advance = false
	continue_hint.visible = false
	text_label.text = ""

	# Borde del panel según tipo
	var border_c := Color(0.29, 0.31, 0.38, 0.9)
	match ltype:
		"kai":    border_c = Color(0.30, 0.55, 0.80, 0.9)
		"rena":   border_c = Color(0.55, 0.30, 0.80, 0.9)
		"system": border_c = Color(0.70, 0.48, 0.00, 0.9)
		"hint":   border_c = Color(0.20, 0.65, 0.30, 0.9)

	var sb := panel.get_theme_stylebox("panel") as StyleBoxFlat
	if sb:
		sb.border_color = border_c


func _process(delta: float) -> void:
	if not visible:
		return

	# Typewriter
	if _typing:
		_char_index += chars_per_second * delta
		var shown := mini(int(_char_index), _full_text.length())
		text_label.text = _full_text.substr(0, shown)

		if shown >= _full_text.length():
			_typing = false
			_can_advance = true
			continue_hint.visible = not auto_advance

			if auto_advance:
				await get_tree().create_timer(auto_delay).timeout
				_advance()

	# Parpadeo del hint
	if _can_advance and not auto_advance:
		_blink_t += delta
		if _blink_t >= 0.5:
			_blink_t = 0.0
			continue_hint.visible = not continue_hint.visible


func _advance() -> void:
	if _typing:
		# Mostrar texto completo inmediatamente
		text_label.text = _full_text
		_char_index = float(_full_text.length())
		_typing = false
		_can_advance = true
		continue_hint.visible = not auto_advance
		return

	_current += 1
	line_finished.emit()
	_show_line(_current)


# ════════════════════════════════════════════════════════════════
# INPUT
# ════════════════════════════════════════════════════════════════

func _input(event: InputEvent) -> void:
	if not visible:
		return
	# Avanzar con ESPACIO, ENTER o E — consumir el evento para que Kai no lo reciba
	var advance := (
		event.is_action_pressed("ui_accept") or
		event.is_action_pressed("jump") or
		event.is_action_pressed("communicate") or
		event.is_action_pressed("use_tool")
	)
	if advance:
		_advance()
		get_viewport().set_input_as_handled()
