extends Control

## Menú de configuración de NK7
## Gestiona audio, video, controles y accesibilidad

signal back_pressed

# ══════════════════════════════════════════════════════════════════
# NODOS - AUDIO
# ══════════════════════════════════════════════════════════════════

@onready var master_volume_slider := $Window/Content/TabContainer/Audio/VBoxContainer/MasterVolume/Slider
@onready var music_volume_slider  := $Window/Content/TabContainer/Audio/VBoxContainer/MusicVolume/Slider
@onready var sfx_volume_slider    := $Window/Content/TabContainer/Audio/VBoxContainer/SFXVolume/Slider

@onready var master_value_label := $Window/Content/TabContainer/Audio/VBoxContainer/MasterVolume/LabelRow/ValueLabel
@onready var music_value_label  := $Window/Content/TabContainer/Audio/VBoxContainer/MusicVolume/LabelRow/ValueLabel
@onready var sfx_value_label    := $Window/Content/TabContainer/Audio/VBoxContainer/SFXVolume/LabelRow/ValueLabel

# ══════════════════════════════════════════════════════════════════
# NODOS - VIDEO
# ══════════════════════════════════════════════════════════════════

@onready var fullscreen_check  := $Window/Content/TabContainer/Video/VBoxContainer/Fullscreen/CheckButton
@onready var vsync_check       := $Window/Content/TabContainer/Video/VBoxContainer/VSync/CheckButton
@onready var resolution_option := $Window/Content/TabContainer/Video/VBoxContainer/Resolution/OptionButton

# ══════════════════════════════════════════════════════════════════
# NODOS - ACCESIBILIDAD
# ══════════════════════════════════════════════════════════════════

@onready var screen_shake_check      := $Window/Content/TabContainer/Accesibilidad/VBoxContainer/ScreenShake/CheckButton
@onready var camera_smoothing_slider := $Window/Content/TabContainer/Accesibilidad/VBoxContainer/CameraSmoothing/Slider
@onready var smoothing_value_label   := $Window/Content/TabContainer/Accesibilidad/VBoxContainer/CameraSmoothing/LabelRow/ValueLabel

# ══════════════════════════════════════════════════════════════════
# CONSTANTES
# ══════════════════════════════════════════════════════════════════

const RESOLUTIONS := {
	"1920x1080": Vector2i(1920, 1080),
	"1600x900":  Vector2i(1600, 900),
	"1366x768":  Vector2i(1366, 768),
	"1280x720":  Vector2i(1280, 720),
}

# ══════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ══════════════════════════════════════════════════════════════════

func _ready() -> void:
	# Aplicar tema NK7
	if has_node("/root/NK7Theme"):
		theme = get_node("/root/NK7Theme").get_nk7_theme()
	
	_load_settings()
	_setup_resolution_options()
	_connect_signals()
	
	# Animación de entrada
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)


func _setup_resolution_options() -> void:
	resolution_option.clear()
	for res_name in RESOLUTIONS.keys():
		resolution_option.add_item(res_name)


func _connect_signals() -> void:
	master_volume_slider.value_changed.connect(_on_master_volume_changed)
	music_volume_slider.value_changed.connect(_on_music_volume_changed)
	sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	vsync_check.toggled.connect(_on_vsync_toggled)
	resolution_option.item_selected.connect(_on_resolution_selected)
	screen_shake_check.toggled.connect(_on_screen_shake_toggled)
	camera_smoothing_slider.value_changed.connect(_on_camera_smoothing_changed)


# ══════════════════════════════════════════════════════════════════
# CARGAR/GUARDAR CONFIGURACIÓN
# ══════════════════════════════════════════════════════════════════

func _load_settings() -> void:
	var config := ConfigFile.new()
	var err := config.load("user://settings.cfg")
	
	if err != OK:
		_set_default_settings()
		return
	
	master_volume_slider.value = config.get_value("audio", "master_volume", 100)
	music_volume_slider.value  = config.get_value("audio", "music_volume", 80)
	sfx_volume_slider.value    = config.get_value("audio", "sfx_volume", 100)
	
	fullscreen_check.button_pressed = config.get_value("video", "fullscreen", false)
	vsync_check.button_pressed      = config.get_value("video", "vsync", true)
	
	screen_shake_check.button_pressed  = config.get_value("accessibility", "screen_shake", true)
	camera_smoothing_slider.value      = config.get_value("accessibility", "camera_smoothing", 5.0)
	
	_update_value_labels()


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume_slider.value)
	config.set_value("audio", "music_volume",  music_volume_slider.value)
	config.set_value("audio", "sfx_volume",    sfx_volume_slider.value)
	config.set_value("video", "fullscreen",    fullscreen_check.button_pressed)
	config.set_value("video", "vsync",         vsync_check.button_pressed)
	config.set_value("video", "resolution",    resolution_option.get_item_text(resolution_option.selected))
	config.set_value("accessibility", "screen_shake",      screen_shake_check.button_pressed)
	config.set_value("accessibility", "camera_smoothing",  camera_smoothing_slider.value)
	config.save("user://settings.cfg")


func _set_default_settings() -> void:
	master_volume_slider.value = 100
	music_volume_slider.value  = 80
	sfx_volume_slider.value    = 100
	fullscreen_check.button_pressed = false
	vsync_check.button_pressed      = true
	screen_shake_check.button_pressed  = true
	camera_smoothing_slider.value      = 5.0
	_update_value_labels()


func _update_value_labels() -> void:
	master_value_label.text  = "%d%%" % int(master_volume_slider.value)
	music_value_label.text   = "%d%%" % int(music_volume_slider.value)
	sfx_value_label.text     = "%d%%" % int(sfx_volume_slider.value)
	smoothing_value_label.text = "%d" % int(camera_smoothing_slider.value)


# ══════════════════════════════════════════════════════════════════
# CALLBACKS - AUDIO
# ══════════════════════════════════════════════════════════════════

func _on_master_volume_changed(value: float) -> void:
	master_value_label.text = "%d%%" % int(value)
	var db := linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)
	_save_settings()


func _on_music_volume_changed(value: float) -> void:
	music_value_label.text = "%d%%" % int(value)
	var db := linear_to_db(value / 100.0)
	if AudioServer.get_bus_index("Music") != -1:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), db)
	_save_settings()


func _on_sfx_volume_changed(value: float) -> void:
	sfx_value_label.text = "%d%%" % int(value)
	var db := linear_to_db(value / 100.0)
	if AudioServer.get_bus_index("SFX") != -1:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), db)
	_save_settings()


# ══════════════════════════════════════════════════════════════════
# CALLBACKS - VIDEO
# ══════════════════════════════════════════════════════════════════

func _on_fullscreen_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	_save_settings()


func _on_vsync_toggled(toggled_on: bool) -> void:
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if toggled_on else DisplayServer.VSYNC_DISABLED
	)
	_save_settings()


func _on_resolution_selected(index: int) -> void:
	var res_name   : String    = resolution_option.get_item_text(index)
	var resolution : Vector2i  = RESOLUTIONS[res_name]
	DisplayServer.window_set_size(resolution)
	_save_settings()


# ══════════════════════════════════════════════════════════════════
# CALLBACKS - ACCESIBILIDAD
# ══════════════════════════════════════════════════════════════════

func _on_screen_shake_toggled(toggled_on: bool) -> void:
	if has_node("/root/GameManager"):
		get_node("/root/GameManager").screen_shake_enabled = toggled_on
	_save_settings()


func _on_camera_smoothing_changed(value: float) -> void:
	smoothing_value_label.text = "%d" % int(value)
	if has_node("/root/GameManager"):
		get_node("/root/GameManager").camera_smoothing_speed = value
	_save_settings()


# ══════════════════════════════════════════════════════════════════
# BOTONES
# ══════════════════════════════════════════════════════════════════

func _on_back_button_pressed() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	await tween.finished
	back_pressed.emit()
	queue_free()


func _on_reset_button_pressed() -> void:
	_set_default_settings()
	_save_settings()


# ══════════════════════════════════════════════════════════════════
# INPUT
# ══════════════════════════════════════════════════════════════════

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_button_pressed()
