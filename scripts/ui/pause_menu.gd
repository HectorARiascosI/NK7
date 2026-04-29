extends Control

## Menú de pausa para NK7
## Se activa con ESC durante el juego

signal resume_pressed
signal restart_pressed
signal settings_pressed
signal main_menu_pressed

# ══════════════════════════════════════════════════════════════════
# NODOS
# ══════════════════════════════════════════════════════════════════

@onready var resume_button    := $Panel/Content/VBoxContainer/ResumeButton
@onready var restart_button   := $Panel/Content/VBoxContainer/RestartButton
@onready var settings_button  := $Panel/Content/VBoxContainer/SettingsButton
@onready var main_menu_button := $Panel/Content/VBoxContainer/MainMenuButton
@onready var panel            := $Panel

# ══════════════════════════════════════════════════════════════════
# VARIABLES
# ══════════════════════════════════════════════════════════════════

var is_paused := false

# ══════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ══════════════════════════════════════════════════════════════════

func _ready() -> void:
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS  # Funciona incluso cuando el juego está pausado
	# Aplicar tema NK7
	if has_node("/root/NK7Theme"):
		theme = get_node("/root/NK7Theme").get_nk7_theme()


# ══════════════════════════════════════════════════════════════════
# INPUT
# ══════════════════════════════════════════════════════════════════

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		if is_paused:
			_resume()
		else:
			_pause()


# ══════════════════════════════════════════════════════════════════
# PAUSA / RESUME
# ══════════════════════════════════════════════════════════════════

func _pause() -> void:
	is_paused = true
	get_tree().paused = true
	show()
	_play_open_animation()
	resume_button.grab_focus()


func _resume() -> void:
	is_paused = false
	get_tree().paused = false
	_play_close_animation()
	await get_tree().create_timer(0.2).timeout
	hide()


func _play_open_animation() -> void:
	# Animación de apertura
	modulate.a = 0.0
	panel.scale = Vector2(0.95, 0.95)
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.2)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _play_close_animation() -> void:
	# Animación de cierre
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_property(panel, "scale", Vector2(0.95, 0.95), 0.2)


# ══════════════════════════════════════════════════════════════════
# SEÑALES DE BOTONES
# ══════════════════════════════════════════════════════════════════

func _on_resume_pressed() -> void:
	_resume()
	resume_pressed.emit()


func _on_restart_pressed() -> void:
	get_tree().paused = false
	is_paused = false
	restart_pressed.emit()
	# Recargar nivel actual
	get_tree().reload_current_scene()


func _on_settings_pressed() -> void:
	settings_pressed.emit()
	# Abrir configuración desde pausa
	var settings_scene : PackedScene = load("res://scenes/ui/settings_menu.tscn")
	if settings_scene:
		var settings : Control = settings_scene.instantiate()
		add_child(settings)


func _on_main_menu_pressed() -> void:
	# Confirmar antes de salir
	var confirm_dialog = ConfirmationDialog.new()
	confirm_dialog.dialog_text = "¿Seguro que quieres volver al menú principal?\nSe perderá el progreso no guardado."
	confirm_dialog.confirmed.connect(_return_to_main_menu)
	add_child(confirm_dialog)
	confirm_dialog.popup_centered()


func _return_to_main_menu() -> void:
	get_tree().paused = false
	is_paused = false
	main_menu_pressed.emit()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
