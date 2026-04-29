extends Node

## NK7 Theme — Paleta industrial pixel art
## Basada en la estética real del juego:
##   Fondo: gris metálico muy oscuro (#1A1C22)
##   Acento primario: rojo advertencia (#CC2200)
##   Acento secundario: amarillo peligro (#E8A000)
##   Texto: blanco apagado (#D0D4DC)
##   Bordes: gris acero (#4A5060)
##   Hover: gris medio (#2E3240)

# ── Paleta ───────────────────────────────────────────────────────
const C_BG_DARK    := Color(0.08, 0.09, 0.11, 1.0)   # #141618
const C_BG_PANEL   := Color(0.11, 0.12, 0.15, 0.97)  # #1C1E26
const C_BG_BTN     := Color(0.14, 0.16, 0.20, 1.0)   # #242833
const C_BG_HOVER   := Color(0.20, 0.22, 0.27, 1.0)   # #333845
const C_BG_PRESSED := Color(0.09, 0.10, 0.13, 1.0)   # #171921

const C_RED        := Color(0.80, 0.13, 0.00, 1.0)   # #CC2200 — advertencia
const C_YELLOW     := Color(0.91, 0.63, 0.00, 1.0)   # #E8A000 — peligro
const C_STEEL      := Color(0.29, 0.31, 0.38, 1.0)   # #4A5060 — bordes
const C_STEEL_DIM  := Color(0.18, 0.20, 0.25, 1.0)   # #2E3340 — bordes apagados

const C_TEXT       := Color(0.82, 0.83, 0.86, 1.0)   # #D0D4DC
const C_TEXT_DIM   := Color(0.45, 0.48, 0.55, 1.0)   # #737A8C
const C_TEXT_RED   := Color(0.90, 0.30, 0.20, 1.0)   # #E64D33

var theme: Theme

func _ready() -> void:
	theme = _build()

func get_nk7_theme() -> Theme:
	if not theme:
		theme = _build()
	return theme

func _build() -> Theme:
	var t := Theme.new()

	# ── Button ──────────────────────────────────────────────────
	t.set_stylebox("normal",   "Button", _btn(C_BG_BTN,     C_STEEL_DIM))
	t.set_stylebox("hover",    "Button", _btn(C_BG_HOVER,   C_STEEL))
	t.set_stylebox("pressed",  "Button", _btn(C_BG_PRESSED, C_RED))
	t.set_stylebox("focus",    "Button", _btn(C_BG_HOVER,   C_YELLOW))
	t.set_stylebox("disabled", "Button", _btn(Color(C_BG_BTN, 0.4), Color(C_STEEL_DIM, 0.3)))

	t.set_color("font_color",          "Button", C_TEXT)
	t.set_color("font_hover_color",    "Button", Color(1, 1, 1, 1))
	t.set_color("font_pressed_color",  "Button", C_YELLOW)
	t.set_color("font_focus_color",    "Button", C_YELLOW)
	t.set_color("font_disabled_color", "Button", C_TEXT_DIM)

	# ── Panel ────────────────────────────────────────────────────
	t.set_stylebox("panel", "Panel", _panel())

	# ── Label ────────────────────────────────────────────────────
	t.set_color("font_color", "Label", C_TEXT)

	# ── HSlider ──────────────────────────────────────────────────
	t.set_stylebox("slider",       "HSlider", _slider_bg())
	t.set_stylebox("grabber_area", "HSlider", _slider_fill())
	t.set_icon("grabber",          "HSlider", _grabber_icon())

	# ── TabContainer ─────────────────────────────────────────────
	t.set_stylebox("panel",          "TabContainer", _tab_panel())
	t.set_stylebox("tab_selected",   "TabContainer", _tab_sel())
	t.set_stylebox("tab_unselected", "TabContainer", _tab_unsel())
	t.set_color("font_selected_color",   "TabContainer", C_YELLOW)
	t.set_color("font_unselected_color", "TabContainer", C_TEXT_DIM)

	# ── CheckButton ──────────────────────────────────────────────
	t.set_color("font_color",       "CheckButton", C_TEXT)
	t.set_color("font_hover_color", "CheckButton", C_YELLOW)

	# ── OptionButton ─────────────────────────────────────────────
	t.set_stylebox("normal", "OptionButton", _btn(C_BG_BTN,   C_STEEL_DIM))
	t.set_stylebox("hover",  "OptionButton", _btn(C_BG_HOVER, C_STEEL))
	t.set_color("font_color",       "OptionButton", C_TEXT)
	t.set_color("font_hover_color", "OptionButton", C_YELLOW)

	# ── PopupMenu ────────────────────────────────────────────────
	t.set_stylebox("panel", "PopupMenu", _panel())
	t.set_color("font_color",       "PopupMenu", C_TEXT)
	t.set_color("font_hover_color", "PopupMenu", C_YELLOW)

	# ── ScrollContainer ──────────────────────────────────────────
	t.set_stylebox("panel", "ScrollContainer", StyleBoxEmpty.new())

	# ── VScrollBar ───────────────────────────────────────────────
	t.set_stylebox("scroll",        "VScrollBar", _sbar_bg())
	t.set_stylebox("scroll_focus",  "VScrollBar", _sbar_bg())
	t.set_stylebox("grabber",       "VScrollBar", _sbar_grab())
	t.set_stylebox("grabber_hover", "VScrollBar", _sbar_grab_h())

	# ── HSeparator ───────────────────────────────────────────────
	var sep := StyleBoxLine.new()
	sep.color = Color(C_STEEL_DIM, 0.6)
	sep.thickness = 1
	t.set_stylebox("separator", "HSeparator", sep)

	return t

# ── Helpers ──────────────────────────────────────────────────────

func _btn(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(0)
	s.set_content_margin(SIDE_LEFT, 18)
	s.set_content_margin(SIDE_RIGHT, 18)
	s.set_content_margin(SIDE_TOP, 10)
	s.set_content_margin(SIDE_BOTTOM, 10)
	return s

func _panel() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = C_BG_PANEL
	s.border_color = C_STEEL
	s.set_border_width_all(1)
	s.set_corner_radius_all(0)
	s.set_content_margin_all(12)
	return s

func _tab_panel() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = C_BG_PANEL
	s.border_color = C_STEEL_DIM
	s.set_border_width_all(1)
	s.set_border_width(SIDE_TOP, 0)
	s.set_content_margin_all(10)
	return s

func _tab_sel() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = C_BG_HOVER
	s.border_color = C_YELLOW
	s.set_border_width_all(1)
	s.set_border_width(SIDE_BOTTOM, 0)
	s.set_content_margin(SIDE_LEFT, 14)
	s.set_content_margin(SIDE_RIGHT, 14)
	s.set_content_margin(SIDE_TOP, 8)
	s.set_content_margin(SIDE_BOTTOM, 8)
	return s

func _tab_unsel() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = C_BG_BTN
	s.border_color = C_STEEL_DIM
	s.set_border_width_all(1)
	s.set_content_margin(SIDE_LEFT, 14)
	s.set_content_margin(SIDE_RIGHT, 14)
	s.set_content_margin(SIDE_TOP, 8)
	s.set_content_margin(SIDE_BOTTOM, 8)
	return s

func _slider_bg() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.10, 0.11, 0.14, 1.0)
	s.border_color = C_STEEL_DIM
	s.set_border_width_all(1)
	s.set_content_margin(SIDE_TOP, 5)
	s.set_content_margin(SIDE_BOTTOM, 5)
	return s

func _slider_fill() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(C_RED.r, C_RED.g, C_RED.b, 0.8)
	s.set_content_margin(SIDE_TOP, 5)
	s.set_content_margin(SIDE_BOTTOM, 5)
	return s

func _grabber_icon() -> ImageTexture:
	var img := Image.create(10, 18, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for x in range(10):
		for y in range(18):
			if x == 0 or x == 9 or y == 0 or y == 17:
				img.set_pixel(x, y, C_YELLOW)
			elif x >= 2 and x <= 7 and y >= 2 and y <= 15:
				img.set_pixel(x, y, Color(0.20, 0.22, 0.27, 1.0))
	return ImageTexture.create_from_image(img)

func _sbar_bg() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.10, 0.11, 0.14, 0.8)
	s.border_color = C_STEEL_DIM
	s.set_border_width_all(1)
	return s

func _sbar_grab() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(C_STEEL.r, C_STEEL.g, C_STEEL.b, 0.5)
	s.border_color = C_STEEL
	s.set_border_width_all(1)
	return s

func _sbar_grab_h() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(C_YELLOW.r, C_YELLOW.g, C_YELLOW.b, 0.6)
	s.border_color = C_YELLOW
	s.set_border_width_all(1)
	return s
