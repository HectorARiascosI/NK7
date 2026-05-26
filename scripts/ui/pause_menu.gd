extends CanvasLayer

## PauseMenu — NK7
## Se instancia como hijo del nivel activo.
## Escucha la acción "pause" (Escape) para mostrarse/ocultarse.
## Emite señales para que el nivel reaccione sin acoplamiento directo.

# ══════════════════════════════════════════════════════════════════
# SEÑALES
# ══════════════════════════════════════════════════════════════════

signal resume_requested
signal settings_requested
signal main_menu_requested

# ══════════════════════════════════════════════════════════════════
# CONSTANTES DE ANIMACIÓN Y ESTILO
# ══════════════════════════════════════════════════════════════════

const SCALE_NORMAL := Vector2(1.00, 1.00)
const SCALE_HOVER  := Vector2(1.05, 1.05)
const SCALE_PRESS  := Vector2(0.96, 0.96)
const TWEEN_IN     := 0.10
const TWEEN_OUT    := 0.16

const COLOR_NORMAL   := Color(1.00, 0.48, 0.32, 1.00)
const COLOR_HOVER    := Color(1.20, 0.75, 0.55, 1.00)
const COLOR_PRESS    := Color(0.70, 0.30, 0.20, 1.00)

# IDs de los botones — añadir aquí para escalar sin tocar otra lógica
const BTN_IDS := ["continuar", "ajustes", "menu_principal"]

# ══════════════════════════════════════════════════════════════════
# ESTADO INTERNO
# ══════════════════════════════════════════════════════════════════

var _btns    : Array[Dictionary] = []
var _visible_state := false   # rastrea si el menú está abierto

# ══════════════════════════════════════════════════════════════════
# NODOS (se resuelven en _ready)
# ══════════════════════════════════════════════════════════════════

@onready var _root_control : Control      = $Root
@onready var _overlay      : ColorRect    = $Root/Overlay
@onready var _panel        : Control      = $Root/Panel
@onready var _btn_continuar     : TextureRect = $Root/Panel/Buttons/BtnContinuar
@onready var _btn_ajustes       : TextureRect = $Root/Panel/Buttons/BtnAjustes
@onready var _btn_menu_principal: TextureRect = $Root/Panel/Buttons/BtnMenuPrincipal

# ══════════════════════════════════════════════════════════════════
# CICLO DE VIDA
# ══════════════════════════════════════════════════════════════════

func _ready() -> void:
	# El CanvasLayer siempre procesa aunque el árbol esté pausado
	process_mode = Node.PROCESS_MODE_ALWAYS

	_collect_buttons()
	_hide_immediate()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		# Verificar si el tutorial está activo
		if _is_tutorial_active():
			return  # No hacer nada si el tutorial está activo
		
		get_viewport().set_input_as_handled()
		if _visible_state:
			_do_resume()
		else:
			_open()


func _is_tutorial_active() -> bool:
	"""Verifica si el tutorial está activo para no interferir"""
	var tutorial_system := _find_node("TutorialSystem")
	if tutorial_system and "is_active" in tutorial_system:
		return tutorial_system.is_active
	return false


func _find_node(node_name: String) -> Node:
	"""Busca un nodo en el árbol"""
	return _search_node(get_tree().root, node_name)


func _search_node(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node
	for child in node.get_children():
		var result := _search_node(child, target_name)
		if result:
			return result
	return null

# ══════════════════════════════════════════════════════════════════
# CONSTRUCCIÓN DE BOTONES
# ══════════════════════════════════════════════════════════════════

func _collect_buttons() -> void:
	var nodes : Array[TextureRect] = [
		_btn_continuar,
		_btn_ajustes,
		_btn_menu_principal,
	]

	for i in range(nodes.size()):
		var n : TextureRect = nodes[i]
		n.pivot_offset = n.size * 0.5

		# Área de input invisible encima del TextureRect
		var area := Control.new()
		area.set_anchors_preset(Control.PRESET_FULL_RECT)
		area.mouse_filter = Control.MOUSE_FILTER_STOP
		n.add_child(area)

		area.mouse_entered.connect(_on_hover.bind(i, true))
		area.mouse_exited.connect(_on_hover.bind(i, false))
		area.gui_input.connect(_on_input.bind(i))

		n.modulate = COLOR_NORMAL
		_btns.append({"id": BTN_IDS[i], "node": n})

# ══════════════════════════════════════════════════════════════════
# APERTURA / CIERRE
# ══════════════════════════════════════════════════════════════════

func _open() -> void:
	_visible_state = true
	_root_control.visible = true
	get_tree().paused = true

	# Estado inicial para animar entrada
	_overlay.modulate.a = 0.0
	_panel.modulate.a   = 0.0
	_panel.scale        = Vector2(0.92, 0.92)

	var tw := create_tween().set_parallel(true)
	tw.tween_property(_overlay, "modulate:a", 1.0, 0.18)
	tw.tween_property(_panel,   "modulate:a", 1.0, 0.20)
	tw.tween_property(_panel,   "scale", Vector2(1.0, 1.0), 0.22) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# Animar botones en cascada
	for i in range(_btns.size()):
		var n : TextureRect = _btns[i]["node"]
		n.modulate.a = 0.0
		n.position.y += 10.0
		var delay := 0.10 + i * 0.06
		tw.tween_property(n, "modulate:a",   1.0,              0.18).set_delay(delay)
		tw.tween_property(n, "position:y",   n.position.y - 10.0, 0.18) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE).set_delay(delay)


func _close(callback: Callable = Callable()) -> void:
	_visible_state = false

	var tw := create_tween().set_parallel(true)
	tw.tween_property(_overlay, "modulate:a", 0.0, 0.15)
	tw.tween_property(_panel,   "modulate:a", 0.0, 0.15)
	tw.tween_property(_panel,   "scale", Vector2(0.94, 0.94), 0.15) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)

	await tw.finished
	_hide_immediate()
	if callback.is_valid():
		callback.call()


func _hide_immediate() -> void:
	_root_control.visible = false
	_panel.scale          = Vector2(1.0, 1.0)
	_panel.modulate.a     = 1.0
	_overlay.modulate.a   = 1.0

# ══════════════════════════════════════════════════════════════════
# INTERACCIÓN DE BOTONES
# ══════════════════════════════════════════════════════════════════

func _on_hover(index: int, entering: bool) -> void:
	var n : TextureRect = _btns[index]["node"]
	n.pivot_offset = n.size * 0.5
	if entering:
		_tween_btn(n, SCALE_HOVER, COLOR_HOVER, TWEEN_IN,  Tween.TRANS_BACK)
	else:
		_tween_btn(n, SCALE_NORMAL, COLOR_NORMAL, TWEEN_OUT, Tween.TRANS_SINE)


func _on_input(event: InputEvent, index: int) -> void:
	var n : TextureRect = _btns[index]["node"]
	n.pivot_offset = n.size * 0.5
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_tween_btn(n, SCALE_PRESS, COLOR_PRESS, 0.06, Tween.TRANS_SINE)
			else:
				_tween_btn(n, SCALE_HOVER, COLOR_HOVER, 0.06, Tween.TRANS_SINE)
				_trigger(_btns[index]["id"])


func _tween_btn(n: TextureRect, sc: Vector2, col: Color, dur: float, trans: int) -> void:
	var tw := n.create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(trans).set_parallel(true)
	tw.tween_property(n, "scale",    sc,  dur)
	tw.tween_property(n, "modulate", col, dur)

# ══════════════════════════════════════════════════════════════════
# ACCIONES DE BOTONES
# ══════════════════════════════════════════════════════════════════

func _trigger(id: String) -> void:
	match id:
		"continuar":      _do_resume()
		"ajustes":        _do_settings()
		"menu_principal": _do_main_menu()


func _do_resume() -> void:
	_close(func():
		get_tree().paused = false
		resume_requested.emit())


func _do_settings() -> void:
	settings_requested.emit()
	# Instanciar el menú de ajustes
	var settings_path := "res://scenes/ui/settings_menu.tscn"
	if ResourceLoader.exists(settings_path):
		var settings_scene : PackedScene = load(settings_path)
		if settings_scene:
			var settings : Node = settings_scene.instantiate()
			get_tree().root.add_child(settings)
	else:
		# Fallback: crear desde script
		var settings_script : GDScript = load("res://scripts/ui/settings_menu.gd")
		if settings_script:
			var settings : Node = settings_script.new()
			get_tree().root.add_child(settings)


func _do_main_menu() -> void:
	_close(func():
		get_tree().paused = false
		main_menu_requested.emit())

# ══════════════════════════════════════════════════════════════════
# API PÚBLICA — para llamar desde el nivel si hace falta
# ══════════════════════════════════════════════════════════════════

## Abre el menú programáticamente (ej: desde cutscene o muerte)
func open() -> void:
	if not _visible_state:
		_open()

## Cierra el menú programáticamente sin emitir señales
func close_silent() -> void:
	if _visible_state:
		get_tree().paused = false
		_close()
