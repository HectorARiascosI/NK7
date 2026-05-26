extends CanvasLayer

## DialogueBox NK7 — Sistema de diálogo para el tutorial y narrativa
## Se activa desde level_01_tutorial.gd con show_dialogue(lines)
## Bloquea el input del jugador mientras está activo

signal dialogue_finished

# ── Estado ────────────────────────────────────────────────────
var is_active   : bool = false
var _lines      : Array = []
var _current    : int  = 0
var _typing     : bool = false
var _full_text  : String = ""
var _timer      : float = 0.0
const TYPE_SPD  : float = 42.0  # caracteres por segundo

# ── Nodos (construidos en _ready) ─────────────────────────────
var _panel      : PanelContainer
var _speaker    : Label
var _body       : RichTextLabel
var _hint       : Label

# ── Colores por tipo de hablante ──────────────────────────────
const COLORS := {
	"system": Color(0.91, 0.63, 0.00, 1.0),   # amarillo — sistema NK7
	"kai":    Color(0.82, 0.83, 0.86, 1.0),   # blanco apagado — Kai
	"rena":   Color(0.40, 0.85, 0.90, 1.0),   # cian — Rena por radio
	"default":Color(0.82, 0.83, 0.86, 1.0),
}

# ════════════════════════════════════════════════════════════════
func _ready() -> void:
	_build_ui()
	_hide_panel()


func _build_ui() -> void:
	# Panel principal en la parte inferior de la pantalla
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_top    = -148.0
	_panel.offset_bottom = -12.0
	_panel.offset_left   = 16.0
	_panel.offset_right  = -16.0

	var style := StyleBoxFlat.new()
	style.bg_color     = Color(0.06, 0.07, 0.09, 0.92)
	style.border_color = Color(0.29, 0.31, 0.38, 0.8)
	style.set_border_width_all(1)
	style.set_content_margin_all(12)
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	_panel.add_child(vbox)

	# Nombre del hablante
	_speaker = Label.new()
	_speaker.add_theme_font_size_override("font_size", 13)
	_speaker.add_theme_color_override("font_color", Color(0.91, 0.63, 0.00, 1.0))
	vbox.add_child(_speaker)

	# Separador
	var sep := HSeparator.new()
	vbox.add_child(sep)

	# Texto del diálogo
	_body = RichTextLabel.new()
	_body.bbcode_enabled = true
	_body.fit_content    = true
	_body.custom_minimum_size = Vector2(0, 72)
	_body.add_theme_font_size_override("normal_font_size", 14)
	_body.add_theme_color_override("default_color", Color(0.82, 0.83, 0.86, 1.0))
	vbox.add_child(_body)

	# Hint de continuar
	_hint = Label.new()
	_hint.text = "[ ESPACIO / ENTER — continuar ]"
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint.add_theme_font_size_override("font_size", 10)
	_hint.add_theme_color_override("font_color", Color(0.45, 0.48, 0.55, 0.8))
	vbox.add_child(_hint)


# ════════════════════════════════════════════════════════════════
# API PÚBLICA
# ════════════════════════════════════════════════════════════════

func show_dialogue(lines: Array) -> void:
	if lines.is_empty():
		return
	_lines   = lines
	_current = 0
	is_active = true
	_show_panel()
	_show_line(_lines[0])


func _show_line(line: Dictionary) -> void:
	var speaker : String = line.get("speaker", "")
	var text    : String = line.get("text",    "")
	var type    : String = line.get("type",    "default")

	_speaker.text = speaker
	_speaker.add_theme_color_override("font_color",
		COLORS.get(type, COLORS["default"]))

	_full_text = text
	_body.text = ""
	_timer     = 0.0
	_typing    = true
	_hint.modulate.a = 0.0


func _advance() -> void:
	if _typing:
		# Completar texto instantáneamente
		_body.text = _full_text
		_typing    = false
		_hint.modulate.a = 1.0
		return

	_current += 1
	if _current >= _lines.size():
		_finish()
	else:
		_show_line(_lines[_current])


func _finish() -> void:
	is_active = false
	_hide_panel()
	dialogue_finished.emit()


# ════════════════════════════════════════════════════════════════
# PROCESO — typewriter
# ════════════════════════════════════════════════════════════════

func _process(delta: float) -> void:
	if not is_active or not _typing:
		return

	_timer += delta
	var shown := mini(int(_timer * TYPE_SPD), _full_text.length())
	_body.text = _full_text.substr(0, shown)

	if shown >= _full_text.length():
		_typing = false
		# Parpadeo del hint
		var tw := create_tween().set_loops()
		tw.tween_property(_hint, "modulate:a", 1.0, 0.4)
		tw.tween_property(_hint, "modulate:a", 0.3, 0.4)


# ════════════════════════════════════════════════════════════════
# INPUT
# ════════════════════════════════════════════════════════════════

func _unhandled_input(event: InputEvent) -> void:
	if not is_active:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("communicate"):
		get_viewport().set_input_as_handled()
		_advance()


# ════════════════════════════════════════════════════════════════
# HELPERS
# ════════════════════════════════════════════════════════════════

func _show_panel() -> void:
	_panel.modulate.a = 0.0
	_panel.visible    = true
	var tw := create_tween()
	tw.tween_property(_panel, "modulate:a", 1.0, 0.18)


func _hide_panel() -> void:
	var tw := create_tween()
	tw.tween_property(_panel, "modulate:a", 0.0, 0.15)
	await tw.finished
	_panel.visible = false
