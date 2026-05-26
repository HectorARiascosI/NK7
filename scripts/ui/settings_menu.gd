extends CanvasLayer

## SettingsMenu — NK7
## Menú de ajustes simplificado y funcional

@onready var _master_slider : HSlider  = $Root/Panel/Content/MasterVolume/Slider
@onready var _master_value  : Label    = $Root/Panel/Content/MasterVolume/Value
@onready var _music_slider  : HSlider  = $Root/Panel/Content/MusicVolume/Slider
@onready var _music_value   : Label    = $Root/Panel/Content/MusicVolume/Value
@onready var _sfx_slider    : HSlider  = $Root/Panel/Content/SFXVolume/Slider
@onready var _sfx_value     : Label    = $Root/Panel/Content/SFXVolume/Value

@onready var _shake_check   : CheckBox = $Root/Panel/Content/ScreenShake/CheckBox
@onready var _smooth_slider : HSlider  = $Root/Panel/Content/CameraSmoothing/Slider
@onready var _smooth_value  : Label    = $Root/Panel/Content/CameraSmoothing/Value

@onready var _btn_volver    : Button   = $Root/Panel/Content/Buttons/BtnVolver
@onready var _btn_guardar   : Button   = $Root/Panel/Content/Buttons/BtnGuardar

@onready var _panel : Panel = $Root/Panel

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	_load_current_settings()
	_connect_signals()
	_animate_in()
	
	print("[Settings] Menú de ajustes cargado")


func _connect_signals() -> void:
	_master_slider.value_changed.connect(_on_master_changed)
	_music_slider.value_changed.connect(_on_music_changed)
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	_shake_check.toggled.connect(_on_shake_toggled)
	_smooth_slider.value_changed.connect(_on_smooth_changed)
	
	_btn_volver.pressed.connect(_on_volver)
	_btn_guardar.pressed.connect(_on_guardar)


func _load_current_settings() -> void:
	_master_slider.value = GameManager.master_volume * 100.0
	_music_slider.value  = GameManager.music_volume * 100.0
	_sfx_slider.value    = GameManager.sfx_volume * 100.0
	
	_shake_check.button_pressed = GameManager.screen_shake_enabled
	_smooth_slider.value = GameManager.camera_smoothing_speed
	
	_update_labels()


func _on_master_changed(value: float) -> void:
	GameManager.master_volume = value / 100.0
	_master_value.text = "%d%%" % int(value)
	_apply_audio()


func _on_music_changed(value: float) -> void:
	GameManager.music_volume = value / 100.0
	_music_value.text = "%d%%" % int(value)
	_apply_audio()


func _on_sfx_changed(value: float) -> void:
	GameManager.sfx_volume = value / 100.0
	_sfx_value.text = "%d%%" % int(value)
	_apply_audio()


func _on_shake_toggled(enabled: bool) -> void:
	GameManager.screen_shake_enabled = enabled
	_shake_check.text = "Activado" if enabled else "Desactivado"
	print("[Settings] Vibración al recibir daño: ", "Activado" if enabled else "Desactivado")


func _on_smooth_changed(value: float) -> void:
	GameManager.camera_smoothing_speed = value
	_smooth_value.text = "%.1f" % value


func _apply_audio() -> void:
	var master_idx := AudioServer.get_bus_index("Master")
	var music_idx  := AudioServer.get_bus_index("Music")
	var sfx_idx    := AudioServer.get_bus_index("SFX")

	if master_idx >= 0:
		AudioServer.set_bus_volume_db(master_idx, linear_to_db(GameManager.master_volume))
	if music_idx >= 0:
		AudioServer.set_bus_volume_db(music_idx, linear_to_db(GameManager.music_volume))
	if sfx_idx >= 0:
		AudioServer.set_bus_volume_db(sfx_idx, linear_to_db(GameManager.sfx_volume))


func _update_labels() -> void:
	_master_value.text = "%d%%" % int(_master_slider.value)
	_music_value.text  = "%d%%" % int(_music_slider.value)
	_sfx_value.text    = "%d%%" % int(_sfx_slider.value)
	_smooth_value.text = "%.1f" % _smooth_slider.value
	_shake_check.text  = "Activado" if _shake_check.button_pressed else "Desactivado"


func _on_volver() -> void:
	print("[Settings] Descartando cambios...")
	GameManager.load_settings()
	_animate_out()


func _on_guardar() -> void:
	print("[Settings] Guardando configuración...")
	_save_settings()
	print("[Settings] ✓ Configuración guardada")
	_animate_out()


func _save_settings() -> void:
	var config := ConfigFile.new()
	
	config.set_value("audio", "master_volume", int(GameManager.master_volume * 100))
	config.set_value("audio", "music_volume",  int(GameManager.music_volume * 100))
	config.set_value("audio", "sfx_volume",    int(GameManager.sfx_volume * 100))
	
	config.set_value("accessibility", "screen_shake", GameManager.screen_shake_enabled)
	config.set_value("accessibility", "camera_smoothing", GameManager.camera_smoothing_speed)
	
	var err := config.save("user://settings.cfg")
	if err != OK:
		push_error("[Settings] Error al guardar: ", err)


func _animate_in() -> void:
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.9, 0.9)
	
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.2)
	tw.tween_property(_panel, "scale", Vector2(1.0, 1.0), 0.25) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _animate_out() -> void:
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_panel, "modulate:a", 0.0, 0.15)
	tw.tween_property(_panel, "scale", Vector2(0.95, 0.95), 0.15) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	
	await tw.finished
	queue_free()
