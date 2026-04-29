extends Node

## GameManager - Singleton global para NK7
## Gestiona estado del juego, progreso, configuración y transiciones

# ══════════════════════════════════════════════════════════════════
# SEÑALES
# ══════════════════════════════════════════════════════════════════

signal level_completed(level_name: String)
signal checkpoint_reached(checkpoint_id: int)
signal player_died
signal game_paused
signal game_resumed

# ══════════════════════════════════════════════════════════════════
# PROGRESO DEL JUEGO
# ══════════════════════════════════════════════════════════════════

var current_level := 1
var current_checkpoint := 0
var levels_completed := []
var total_deaths := 0
var total_time := 0.0

# ══════════════════════════════════════════════════════════════════
# CONFIGURACIÓN GLOBAL
# ══════════════════════════════════════════════════════════════════

var screen_shake_enabled := true
var camera_smoothing_speed := 5.0
var master_volume := 1.0
var music_volume := 0.8
var sfx_volume := 1.0

# ══════════════════════════════════════════════════════════════════
# ESTADO DEL JUEGO
# ══════════════════════════════════════════════════════════════════

var is_paused := false
var player_reference: CharacterBody2D = null

# ══════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ══════════════════════════════════════════════════════════════════

func _ready() -> void:
	# Cargar configuración
	load_settings()
	
	# Configurar audio buses
	_setup_audio_buses()


func _setup_audio_buses() -> void:
	# Crear buses de audio si no existen
	if AudioServer.get_bus_index("Music") == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.get_bus_count() - 1, "Music")
	
	if AudioServer.get_bus_index("SFX") == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.get_bus_count() - 1, "SFX")


# ══════════════════════════════════════════════════════════════════
# GESTIÓN DE PROGRESO
# ══════════════════════════════════════════════════════════════════

func complete_level(level_name: String) -> void:
	if not level_name in levels_completed:
		levels_completed.append(level_name)
	level_completed.emit(level_name)
	save_game()


func reach_checkpoint(checkpoint_id: int) -> void:
	current_checkpoint = checkpoint_id
	checkpoint_reached.emit(checkpoint_id)
	save_game()


func player_death() -> void:
	total_deaths += 1
	player_died.emit()


func reset_progress() -> void:
	current_level = 1
	current_checkpoint = 0
	levels_completed.clear()
	total_deaths = 0
	total_time = 0.0


# ══════════════════════════════════════════════════════════════════
# GUARDADO Y CARGA
# ══════════════════════════════════════════════════════════════════

func save_game() -> void:
	var save_data = {
		"current_level": current_level,
		"current_checkpoint": current_checkpoint,
		"levels_completed": levels_completed,
		"total_deaths": total_deaths,
		"total_time": total_time,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	var file = FileAccess.open("user://save_game.dat", FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()


func load_game() -> bool:
	if not FileAccess.file_exists("user://save_game.dat"):
		return false
	
	var file = FileAccess.open("user://save_game.dat", FileAccess.READ)
	if not file:
		return false
	
	var save_data = file.get_var()
	file.close()
	
	if save_data:
		current_level = save_data.get("current_level", 1)
		current_checkpoint = save_data.get("current_checkpoint", 0)
		levels_completed = save_data.get("levels_completed", [])
		total_deaths = save_data.get("total_deaths", 0)
		total_time = save_data.get("total_time", 0.0)
		
		# Cargar nivel guardado
		_load_level(current_level)
		return true
	
	return false


func _load_level(level_number: int) -> void:
	var level_path = "res://scenes/levels/level_%02d.tscn" % level_number
	if ResourceLoader.exists(level_path):
		get_tree().change_scene_to_file(level_path)


# ══════════════════════════════════════════════════════════════════
# CONFIGURACIÓN
# ══════════════════════════════════════════════════════════════════

func load_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	
	if err == OK:
		# Audio
		master_volume = config.get_value("audio", "master_volume", 100) / 100.0
		music_volume = config.get_value("audio", "music_volume", 80) / 100.0
		sfx_volume = config.get_value("audio", "sfx_volume", 100) / 100.0
		
		# Accesibilidad
		screen_shake_enabled = config.get_value("accessibility", "screen_shake", true)
		camera_smoothing_speed = config.get_value("accessibility", "camera_smoothing", 5.0)
		
		# Aplicar configuración
		_apply_audio_settings()


func _apply_audio_settings() -> void:
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Master"),
		linear_to_db(master_volume)
	)
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Music"),
		linear_to_db(music_volume)
	)
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("SFX"),
		linear_to_db(sfx_volume)
	)


# ══════════════════════════════════════════════════════════════════
# PAUSA
# ══════════════════════════════════════════════════════════════════

func pause_game() -> void:
	if not is_paused:
		is_paused = true
		get_tree().paused = true
		game_paused.emit()


func resume_game() -> void:
	if is_paused:
		is_paused = false
		get_tree().paused = false
		game_resumed.emit()


func toggle_pause() -> void:
	if is_paused:
		resume_game()
	else:
		pause_game()


# ══════════════════════════════════════════════════════════════════
# UTILIDADES
# ══════════════════════════════════════════════════════════════════

func get_player() -> CharacterBody2D:
	if not player_reference or not is_instance_valid(player_reference):
		# Buscar jugador en la escena actual
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player_reference = players[0]
	return player_reference


func get_camera() -> Camera2D:
	var player = get_player()
	if player:
		for child in player.get_children():
			if child is Camera2D:
				return child
	return null


func shake_camera(intensity: float = 10.0, duration: float = 0.3) -> void:
	if not screen_shake_enabled:
		return
	
	var camera = get_camera()
	if camera and camera.has_method("shake"):
		camera.shake(intensity, duration)


# ══════════════════════════════════════════════════════════════════
# TRANSICIONES
# ══════════════════════════════════════════════════════════════════

func transition_to_level(level_number: int, fade_duration: float = 0.5) -> void:
	# Crear fade out
	var fade = ColorRect.new()
	fade.color = Color.BLACK
	fade.modulate.a = 0.0
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	get_tree().root.add_child(fade)
	
	# Fade out
	var tween = create_tween()
	tween.tween_property(fade, "modulate:a", 1.0, fade_duration)
	await tween.finished
	
	# Cambiar escena
	current_level = level_number
	_load_level(level_number)
	
	# Fade in
	await get_tree().process_frame
	tween = create_tween()
	tween.tween_property(fade, "modulate:a", 0.0, fade_duration)
	await tween.finished
	
	fade.queue_free()
