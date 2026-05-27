extends Node2D

## LevelBase — NK7
## Script base que todos los niveles extienden.
## Gestiona el ciclo de vida del PauseMenu y AchievementToast de forma uniforme.

const PAUSE_MENU_SCENE      := preload("res://scenes/ui/pause_menu.tscn")
const ACHIEVEMENT_TOAST_SCENE := preload("res://scenes/ui/achievement_toast.tscn")

var _pause_menu       : CanvasLayer = null
var _achievement_toast : CanvasLayer = null

# ══════════════════════════════════════════════════════════════════
# CICLO DE VIDA
# ══════════════════════════════════════════════════════════════════

func _ready() -> void:
	_sync_current_level()
	_setup_pause_menu()
	_setup_achievement_toast()
	_on_level_ready()   # hook para subclases


func _sync_current_level() -> void:
	## Detectar el número de nivel desde el nombre del archivo de escena
	## y sincronizarlo con GameManager. Esto garantiza que current_level
	## sea correcto aunque el nivel se cargue directamente desde el editor.
	var scene_path : String = get_tree().current_scene.scene_file_path
	# Buscar patrón "level_XX" en la ruta
	var regex := RegEx.new()
	regex.compile("level_(\\d+)")
	var result := regex.search(scene_path)
	if result:
		var level_num : int = int(result.get_string(1))
		if level_num > 0:
			GameManager.current_level = level_num
			GameManager.is_playing    = true


## Sobrescribir en subclases para inicialización específica del nivel
func _on_level_ready() -> void:
	pass

# ══════════════════════════════════════════════════════════════════
# MENÚ DE PAUSA
# ══════════════════════════════════════════════════════════════════

func _setup_pause_menu() -> void:
	_pause_menu = PAUSE_MENU_SCENE.instantiate()
	add_child(_pause_menu)

	_pause_menu.resume_requested.connect(_on_pause_resume)
	_pause_menu.settings_requested.connect(_on_pause_settings)
	_pause_menu.main_menu_requested.connect(_on_pause_main_menu)

func _setup_achievement_toast() -> void:
	_achievement_toast = ACHIEVEMENT_TOAST_SCENE.instantiate()
	add_child(_achievement_toast)


func _on_pause_resume() -> void:
	pass  # El menú ya despausa el árbol; aquí se puede añadir lógica extra


func _on_pause_settings() -> void:
	# Abre ajustes encima del menú de pausa
	var path := "res://scenes/ui/settings_menu.tscn"
	if ResourceLoader.exists(path):
		var s : PackedScene = load(path)
		if s:
			_pause_menu.add_child(s.instantiate())
	else:
		push_warning("LevelBase: settings_menu.tscn no encontrado")


func _on_pause_main_menu() -> void:
	GameManager.transition_to_scene("res://scenes/ui/main_menu.tscn")
