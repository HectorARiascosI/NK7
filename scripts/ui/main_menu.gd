extends Control

## Menú principal NK7 — Assets reales del diseño oficial

# ── Paleta del diseño ─────────────────────────────────────────
const C_TEXT       := Color(0.816, 0.886, 0.922, 1.0)  # #D0D4DC
const C_TEXT_LIGHT := Color(1.0,   1.0,   1.0,   1.0)
const C_TEXT_DIM   := Color(0.290, 0.314, 0.376, 1.0)  # #4A5060
const C_RED_SOFT   := Color(0.800, 0.267, 0.133, 1.0)  # #CC4422
const C_RED        := Color(0.800, 0.133, 0.000, 1.0)  # #CC2200
const C_YELLOW     := Color(0.910, 0.627, 0.000, 1.0)  # #E8A000

# ── Nodos ─────────────────────────────────────────────────────
@onready var play_button   : Button = $RightPanel/ButtonsArea/PlayButton
@onready var cont_button   : Button = $RightPanel/ButtonsArea/ContinueButton
@onready var cfg_button    : Button = $RightPanel/ButtonsArea/SettingsButton
@onready var cred_button   : Button = $RightPanel/ButtonsArea/CreditsButton
@onready var quit_button   : Button = $RightPanel/ButtonsArea/QuitButton
@onready var status_label  : Label  = $RightPanel/StatusBar/StatusLabel

# ── Estado ────────────────────────────────────────────────────
var _all_buttons : Array[Button] = []
var _tw_timer    : float  = 0.0
var _tw_full     : String = ""
var _tw_done     : bool   = true
const TW_SPEED   : float  = 38.0

const BOOT_LINES : Array = [
	{"text": "SISTEMA NK7 v1.0 — Inicializando...", "delay": 0.6},
	{"text": "Módulo de Energía: OK",               "delay": 0.4},
	{"text": "Sector B — Cargado",                  "delay": 0.4},
	{"text": "Listo: Selecciona una opción.",        "delay": 0.0},
]

# ════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ════════════════════════════════════════════════════════════════

func _ready() -> void:
	_all_buttons = [play_button, cont_button, cfg_button, cred_button, quit_button]
	_check_save()
	_apply_button_styles()
	_connect_hover()

	# Ocultar para animación de entrada
	for i in range(_all_buttons.size()):
		_all_buttons[i].modulate.a = 0.0

	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.4)
	await tw.finished

	_animate_in()
	await get_tree().create_timer(0.2).timeout
	_run_boot()


func _check_save() -> void:
	cont_button.disabled = not FileAccess.file_exists("user://save_game.dat")


# ════════════════════════════════════════════════════════════════
# ESTILOS CON ASSETS REALES
# ════════════════════════════════════════════════════════════════

func _apply_button_styles() -> void:
	var tex_normal   : Texture2D = load("res://assets/ui/buttons/btn_normal.png")
	var tex_hover    : Texture2D = load("res://assets/ui/buttons/btn_hover.png")
	var tex_pressed  : Texture2D = load("res://assets/ui/buttons/btn_pressed.png")
	var tex_disabled : Texture2D = load("res://assets/ui/buttons/btn_disabled.png")

	for btn in _all_buttons:
		_apply_tex_style(btn, tex_normal, tex_hover, tex_pressed, tex_disabled)

	# SALIR: tinte rojo en normal
	quit_button.add_theme_color_override("font_color", C_RED_SOFT)
	quit_button.add_theme_color_override("font_hover_color", C_RED)
	quit_button.add_theme_color_override("font_pressed_color", C_RED)


func _apply_tex_style(btn: Button,
		tex_n: Texture2D, tex_h: Texture2D,
		tex_p: Texture2D, tex_d: Texture2D) -> void:

	# Normal
	var sn := StyleBoxTexture.new()
	sn.texture = tex_n
	sn.set_texture_margin_all(0)
	sn.set_content_margin(SIDE_LEFT, 20)
	sn.set_content_margin(SIDE_RIGHT, 20)
	sn.set_content_margin(SIDE_TOP, 0)
	sn.set_content_margin(SIDE_BOTTOM, 0)
	btn.add_theme_stylebox_override("normal", sn)

	# Hover
	var sh := StyleBoxTexture.new()
	sh.texture = tex_h
	sh.set_texture_margin_all(0)
	sh.set_content_margin(SIDE_LEFT, 20)
	sh.set_content_margin(SIDE_RIGHT, 20)
	sh.set_content_margin(SIDE_TOP, 0)
	sh.set_content_margin(SIDE_BOTTOM, 0)
	btn.add_theme_stylebox_override("hover", sh)
	btn.add_theme_stylebox_override("focus", sh)

	# Pressed
	var sp := StyleBoxTexture.new()
	sp.texture = tex_p
	sp.set_texture_margin_all(0)
	sp.set_content_margin(SIDE_LEFT, 20)
	sp.set_content_margin(SIDE_RIGHT, 20)
	sp.set_content_margin(SIDE_TOP, 0)
	sp.set_content_margin(SIDE_BOTTOM, 0)
	btn.add_theme_stylebox_override("pressed", sp)

	# Disabled
	var sd := StyleBoxTexture.new()
	sd.texture = tex_d
	sd.set_texture_margin_all(0)
	sd.set_content_margin(SIDE_LEFT, 20)
	sd.set_content_margin(SIDE_RIGHT, 20)
	sd.set_content_margin(SIDE_TOP, 0)
	sd.set_content_margin(SIDE_BOTTOM, 0)
	btn.add_theme_stylebox_override("disabled", sd)

	# Colores de texto
	btn.add_theme_color_override("font_color",          C_TEXT)
	btn.add_theme_color_override("font_hover_color",    C_TEXT_LIGHT)
	btn.add_theme_color_override("font_pressed_color",  C_TEXT_LIGHT)
	btn.add_theme_color_override("font_focus_color",    C_TEXT_LIGHT)
	btn.add_theme_color_override("font_disabled_color", C_TEXT_DIM)
	btn.add_theme_font_size_override("font_size", 16)


# ════════════════════════════════════════════════════════════════
# HOVER — triángulo dorado aparece en el texto
# ════════════════════════════════════════════════════════════════

# Texto base fijo por nombre de nodo — nunca depende de btn.text
const _BTN_LABELS : Dictionary = {
	"PlayButton":     "NUEVA PARTIDA",
	"ContinueButton": "CONTINUAR",
	"SettingsButton": "CONFIGURACIÓN",
	"CreditsButton":  "CRÉDITOS",
	"QuitButton":     "SALIR",
}

func _connect_hover() -> void:
	# Inicializar texto correcto en cada botón
	for btn in _all_buttons:
		var base : String = _BTN_LABELS.get(btn.name, "")
		btn.text = base
		# Solo mouse_entered/exited — NO focus signals
		# El foco por teclado no debe cambiar el texto
		btn.mouse_entered.connect(_on_mouse_enter.bind(btn))
		btn.mouse_exited.connect(_on_mouse_exit.bind(btn))

func _on_mouse_enter(btn: Button) -> void:
	if btn.disabled:
		return
	btn.text = "▶  " + _BTN_LABELS.get(btn.name, "")

func _on_mouse_exit(btn: Button) -> void:
	btn.text = _BTN_LABELS.get(btn.name, "")

func _btn_base_text(btn: Button) -> String:
	return _BTN_LABELS.get(btn.name, "")


# ════════════════════════════════════════════════════════════════
# ANIMACIÓN DE ENTRADA
# ════════════════════════════════════════════════════════════════

func _animate_in() -> void:
	# Animar solo opacidad — los botones en VBoxContainer no tienen posición libre
	for i in range(_all_buttons.size()):
		var btn := _all_buttons[i]
		var tw := create_tween()
		tw.tween_interval(i * 0.08)
		tw.tween_property(btn, "modulate:a", 1.0, 0.18)


# ════════════════════════════════════════════════════════════════
# TYPEWRITER BOOT SEQUENCE
# ════════════════════════════════════════════════════════════════

func _run_boot() -> void:
	for line_data in BOOT_LINES:
		var text  : String = line_data["text"]
		var delay : float  = line_data["delay"]
		await _typewrite(text)
		if delay > 0.0:
			await get_tree().create_timer(delay).timeout
	play_button.grab_focus()

func _typewrite(text: String) -> void:
	_tw_full  = text
	_tw_timer = 0.0
	_tw_done  = false
	while not _tw_done:
		await get_tree().process_frame

func _process(delta: float) -> void:
	if _tw_done or _tw_full.is_empty():
		return
	_tw_timer += delta
	var shown := mini(int(_tw_timer * TW_SPEED), _tw_full.length())
	if is_instance_valid(status_label):
		status_label.text = "> " + _tw_full.substr(0, shown)
	if shown >= _tw_full.length():
		_tw_done = true
		_tw_full = ""


# ════════════════════════════════════════════════════════════════
# BOTONES
# ════════════════════════════════════════════════════════════════

func _on_play_pressed() -> void:
	_set_status("Cargando Sector B...")
	_fade_out(func():
		if has_node("/root/GameManager"):
			get_node("/root/GameManager").reset_progress()
		get_tree().change_scene_to_file("res://scenes/levels/level_01.tscn")
	)

func _on_continue_pressed() -> void:
	_set_status("Cargando partida guardada...")
	_fade_out(func():
		if has_node("/root/GameManager"):
			get_node("/root/GameManager").load_game()
		else:
			get_tree().change_scene_to_file("res://scenes/levels/level_01.tscn")
	)

func _on_settings_pressed() -> void:
	var scene : PackedScene = load("res://scenes/ui/settings_menu.tscn")
	if scene:
		var node : Control = scene.instantiate()
		add_child(node)
		node.back_pressed.connect(func(): cfg_button.grab_focus())

func _on_credits_pressed() -> void:
	_fade_out(func():
		get_tree().change_scene_to_file("res://scenes/ui/credits_screen.tscn")
	)

func _on_quit_pressed() -> void:
	_set_status("Cerrando sistema...")
	_fade_out(func(): get_tree().quit())

func _set_status(txt: String) -> void:
	_tw_done = true
	_tw_full = ""
	if is_instance_valid(status_label):
		status_label.text = "> " + txt

func _fade_out(cb: Callable) -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.3)
	await tw.finished
	cb.call()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_quit_pressed()
