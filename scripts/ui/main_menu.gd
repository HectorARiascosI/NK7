extends Control

## NK7 — Menú Principal v6
## Botones TextureRect con shader de perspectiva trapezoidal
## Borde inferior más ancho (cercano), borde superior más estrecho (lejano)

const SCALE_NORMAL  := Vector2(1.00, 1.00)
const SCALE_HOVER   := Vector2(1.055, 1.055)
const SCALE_PRESS   := Vector2(0.965, 0.965)
const TWEEN_IN      := 0.10
const TWEEN_OUT     := 0.16

const COLOR_NORMAL   := Color(1.00, 0.48, 0.32, 1.00)
const COLOR_HOVER    := Color(1.20, 0.75, 0.55, 1.00)
const COLOR_PRESS    := Color(0.70, 0.30, 0.20, 1.00)
const COLOR_DISABLED := Color(0.35, 0.20, 0.15, 0.45)

const BTN_IDS := ["iniciar", "cargar", "ajustes", "creditos", "perfil", "salir"]

var _btns : Array[Dictionary] = []

func _ready() -> void:
	_collect_buttons()
	_check_save()

	modulate.a = 0.0
	await get_tree().process_frame
	await get_tree().process_frame

	for entry in _btns:
		var n : TextureRect = entry["node"]
		n.pivot_offset = n.size * 0.5
		n.scale        = Vector2(0.88, 0.88)
		n.modulate.a   = 0.0

	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.5)
	await tw.finished
	_animate_entrance()


func _collect_buttons() -> void:
	var nodes : Array = [
		$ButtonsContainer/Row0/BtnIniciar,
		$ButtonsContainer/Row0/BtnCargar,
		$ButtonsContainer/Row1/BtnAjustes,
		$ButtonsContainer/Row1/BtnCreditos,
		$ButtonsContainer/Row2/BtnPerfil,
		$ButtonsContainer/Row2/BtnSalir,
	]
	for i in range(nodes.size()):
		var n : TextureRect = nodes[i]
		var area := Control.new()
		area.set_anchors_preset(Control.PRESET_FULL_RECT)
		area.mouse_filter = Control.MOUSE_FILTER_STOP
		n.add_child(area)
		area.mouse_entered.connect(_on_hover.bind(i, true))
		area.mouse_exited.connect(_on_hover.bind(i, false))
		area.gui_input.connect(_on_input.bind(i))
		n.modulate = COLOR_NORMAL
		_btns.append({"id": BTN_IDS[i], "node": n, "disabled": false})


func _check_save() -> void:
	var idx := _find("cargar")
	if idx >= 0:
		_set_disabled(idx, not GameManager.has_any_save())


func _animate_entrance() -> void:
	for i in range(_btns.size()):
		var n     : TextureRect = _btns[i]["node"]
		var alpha : float = COLOR_DISABLED.a if _btns[i]["disabled"] else 1.0
		var delay : float = i * 0.065
		n.position.y += 14.0
		var tw_a := create_tween()
		tw_a.tween_interval(delay)
		tw_a.tween_property(n, "modulate:a", alpha, 0.20)
		var tw_s := create_tween()
		tw_s.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tw_s.tween_interval(delay)
		tw_s.set_parallel(true)
		tw_s.tween_property(n, "scale",      SCALE_NORMAL,       0.22).set_delay(delay)
		tw_s.tween_property(n, "position:y", n.position.y - 14.0, 0.22).set_delay(delay)


func _on_hover(index: int, entering: bool) -> void:
	var entry : Dictionary = _btns[index]
	if entry["disabled"]: return
	var n : TextureRect = entry["node"]
	n.pivot_offset = n.size * 0.5
	if entering:
		_tween_btn(n, SCALE_HOVER, COLOR_HOVER, TWEEN_IN,  Tween.TRANS_BACK)
	else:
		_tween_btn(n, SCALE_NORMAL, COLOR_NORMAL, TWEEN_OUT, Tween.TRANS_SINE)


func _on_input(event: InputEvent, index: int) -> void:
	var entry : Dictionary = _btns[index]
	if entry["disabled"]: return
	var n : TextureRect = entry["node"]
	n.pivot_offset = n.size * 0.5
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_tween_btn(n, SCALE_PRESS, COLOR_PRESS, 0.06, Tween.TRANS_SINE)
			else:
				_tween_btn(n, SCALE_HOVER, COLOR_HOVER, 0.06, Tween.TRANS_SINE)
				_trigger(entry["id"])


func _tween_btn(n: TextureRect, sc: Vector2, col: Color, dur: float, trans: int) -> void:
	var tw := n.create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(trans).set_parallel(true)
	tw.tween_property(n, "scale",    sc,  dur)
	tw.tween_property(n, "modulate", col, dur)


func _trigger(id: String) -> void:
	match id:
		"iniciar":  _on_play()
		"cargar":   _on_continue()
		"ajustes":  _on_settings()
		"creditos": _on_credits()
		"perfil":   _on_profile()
		"salir":    _on_quit()


func _find(id: String) -> int:
	for i in range(_btns.size()):
		if _btns[i]["id"] == id: return i
	return -1


func _set_disabled(index: int, disabled: bool) -> void:
	if index < 0 or index >= _btns.size(): return
	_btns[index]["disabled"] = disabled
	var n : TextureRect = _btns[index]["node"]
	n.modulate = COLOR_DISABLED if disabled else COLOR_NORMAL
	if n.get_child_count() > 0:
		n.get_child(0).mouse_filter = \
			Control.MOUSE_FILTER_IGNORE if disabled else Control.MOUSE_FILTER_STOP


func _on_play() -> void:
	# Mostrar pantalla de nombre de partida
	_show_save_name_input()

func _on_continue() -> void:
	# Mostrar selector de slots si hay múltiples guardados
	var saves_count: int = 0
	var last_slot: int = 0
	for i in range(GameManager.MAX_SAVE_SLOTS):
		var info: Dictionary = GameManager.get_save_info(i)
		if info.get("exists", false):
			saves_count += 1
			last_slot = i
	
	if saves_count == 0:
		# No hay guardados, iniciar nueva partida
		_on_play()
	elif saves_count == 1:
		# Solo un guardado, cargarlo directamente
		_fade_out_and_load(last_slot)
	else:
		# Múltiples guardados, mostrar selector
		_show_save_selector()

func _fade_out_and_load(slot: int) -> void:
	"""Fade out y cargar partida"""
	await _fade_out_async()
	if not await GameManager.load_game(slot):
		GameManager.reset_progress()
		GameManager.transition_to_level(1)

func _on_settings() -> void:
	var path := "res://scenes/ui/settings_menu.tscn"
	if ResourceLoader.exists(path):
		var s : PackedScene = load(path)
		if s: add_child(s.instantiate())
	else:
		push_warning("settings_menu.tscn no encontrado — reimporta el proyecto en Godot")

func _on_credits() -> void:
	_fade_out(func():
		get_tree().change_scene_to_file("res://scenes/ui/credits_screen.tscn"))

func _on_profile() -> void:
	var profile_path := "res://scenes/ui/profile_screen.tscn"
	if ResourceLoader.exists(profile_path):
		var s : PackedScene = load(profile_path)
		if s:
			var screen : Node = s.instantiate()
			add_child(screen)
	else:
		# Fallback: instanciar directamente desde el script
		var script : GDScript = load("res://scripts/ui/profile_screen.gd")
		if script:
			var screen : Node = script.new()
			add_child(screen)

func _on_quit() -> void:
	var origin := position
	var tw := create_tween().set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "position:x", origin.x + 8,  0.04)
	tw.tween_property(self, "position:x", origin.x - 8,  0.04)
	tw.tween_property(self, "position:x", origin.x + 4,  0.04)
	tw.tween_property(self, "position:x", origin.x,      0.04)
	await tw.finished
	_fade_out(func(): get_tree().quit())

func _fade_out(cb: Callable) -> void:
	var tw := create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "modulate:a", 0.0, 0.28)
	await tw.finished
	cb.call()

func _fade_out_async() -> void:
	"""Versión asíncrona de fade out sin callback"""
	var tw := create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "modulate:a", 0.0, 0.28)
	await tw.finished

func _show_save_selector() -> void:
	"""Mostrar selector de slots de guardado"""
	var selector_path := "res://scenes/ui/save_selector.tscn"
	if ResourceLoader.exists(selector_path):
		var selector_scene: PackedScene = load(selector_path)
		if selector_scene:
			var selector: Node = selector_scene.instantiate()
			add_child(selector)
			selector.slot_selected.connect(_on_slot_selected)
			selector.cancelled.connect(_on_selector_cancelled)
	else:
		# Fallback: cargar el primer guardado disponible
		for i in range(GameManager.MAX_SAVE_SLOTS):
			var info := GameManager.get_save_info(i)
			if info.get("exists", false):
				_fade_out_and_load(i)
				return

func _on_selector_cancelled() -> void:
	"""Callback cuando se cancela el selector"""
	pass  # El selector se cierra solo

func _on_slot_selected(slot: int) -> void:
	"""Callback cuando se selecciona un slot"""
	_fade_out_and_load(slot)

func _show_save_name_input() -> void:
	"""Mostrar pantalla de nombre de partida"""
	var input_path := "res://scenes/ui/save_name_input.tscn"
	if ResourceLoader.exists(input_path):
		var input_scene: PackedScene = load(input_path)
		if input_scene:
			var input_node: Node = input_scene.instantiate()
			add_child(input_node)
			input_node.name_confirmed.connect(_on_save_name_confirmed)
			input_node.cancelled.connect(_on_save_name_cancelled)
	else:
		# Fallback: iniciar sin nombre
		_start_new_game("Nueva Partida", 0)

func _on_save_name_confirmed(save_name: String, slot: int) -> void:
	"""Callback cuando se confirma el nombre de partida"""
	_start_new_game(save_name, slot)

func _on_save_name_cancelled() -> void:
	"""Callback cuando se cancela el nombre de partida"""
	pass  # El input se cierra solo

func _start_new_game(save_name: String, slot: int) -> void:
	"""Iniciar nueva partida con nombre"""
	_fade_out(func():
		GameManager.reset_progress()
		GameManager.current_save_slot = slot
		GameManager.current_save_name = save_name
		GameManager.save_game(slot, save_name)  # Guardar inmediatamente con el nombre
		GameManager.transition_to_level(1))

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_quit()
