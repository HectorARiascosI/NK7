extends Node

## GameManager - Singleton global para NK7
## Gestiona estado del juego, progreso, configuración y transiciones

# ══════════════════════════════════════════════════════════════════
# SEÑALES
# ══════════════════════════════════════════════════════════════════

signal level_completed(level_name: String)
signal checkpoint_reached(checkpoint_id: int)
signal player_died

# ══════════════════════════════════════════════════════════════════
# PROGRESO DEL JUEGO
# ══════════════════════════════════════════════════════════════════

var current_level := 1
var current_checkpoint := 0
var levels_completed := []
var total_deaths := 0
var total_time := 0.0
var total_score := 0
var is_playing := false

## Tutorial — persiste entre muertes (no se muestra de nuevo al morir)
var tutorial_shown : bool = false

## ── Sistema de racha de muertes ──────────────────────────────────
## Muertes consecutivas sin checkpoint = penalización de score
var consecutive_deaths  : int = 0   ## Muertes seguidas sin progresar
var _last_checkpoint_id : int = -1  ## Para detectar si progresó

const DEATH_STREAK_THRESHOLD : int   = 5     ## Muertes para activar penalización
const DEATH_PENALTY_PERCENT  : float = 0.15  ## 15% del score se pierde por racha

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

var player_reference: CharacterBody2D = null

# ══════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ══════════════════════════════════════════════════════════════════

func _ready() -> void:
	# Cargar configuración
	load_settings()
	
	# Configurar audio buses
	_setup_audio_buses()


func _process(delta: float) -> void:
	# Actualizar tiempo de juego si está jugando
	if is_playing:
		total_time += delta


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
	
	# Logros de progreso
	if has_node("/root/AchievementManager"):
		match levels_completed.size():
			1: AchievementManager.unlock("first_steps")
			2: AchievementManager.unlock("sector_clear")
			3: AchievementManager.unlock("control_master")
			4: AchievementManager.unlock("industrial")
			5:
				AchievementManager.unlock("reactor_core")
				AchievementManager.unlock("escape")
		if total_deaths == 0:
			AchievementManager.unlock("no_deaths")
	
	# Sonido
	if has_node("/root/AudioManager"):
		AudioManager.play_sfx("level_clear")
	
	save_game()


func reach_checkpoint(checkpoint_id: int) -> void:
	## Llegar a un nuevo checkpoint resetea la racha de muertes
	if checkpoint_id != _last_checkpoint_id:
		consecutive_deaths  = 0
		_last_checkpoint_id = checkpoint_id
	current_checkpoint = checkpoint_id
	checkpoint_reached.emit(checkpoint_id)
	save_game()


func player_death() -> void:
	total_deaths       += 1
	consecutive_deaths += 1
	player_died.emit()

	## Penalización por racha de muertes consecutivas.
	## consecutive_deaths NO se resetea aquí — se acumula entre muertes.
	## Solo se resetea al llegar a un checkpoint nuevo.
	if consecutive_deaths >= DEATH_STREAK_THRESHOLD:
		var penalty : int = int(float(total_score) * DEATH_PENALTY_PERCENT)
		if penalty > 0:
			total_score = max(0, total_score - penalty)
		## Reiniciar contador para que la siguiente racha de 5 vuelva a penalizar
		consecutive_deaths = 0


func reset_progress() -> void:
	current_level = 1
	current_checkpoint = 0
	levels_completed.clear()
	total_deaths = 0
	total_time = 0.0
	total_score = 0
	is_playing = false


# ══════════════════════════════════════════════════════════════════
# SISTEMA DE PUNTUACIÓN
# ══════════════════════════════════════════════════════════════════

func add_score(points: int) -> void:
	"""Añadir puntos a la puntuación total"""
	total_score += points
	print("[GameManager] Puntuación: +%d = %d" % [points, total_score])

func get_score() -> int:
	"""Obtener puntuación total"""
	return total_score


# ══════════════════════════════════════════════════════════════════
# GUARDADO Y CARGA
# ══════════════════════════════════════════════════════════════════

# ══════════════════════════════════════════════════════════════════
# GUARDADO Y CARGA (Sistema mejorado con slots)
# ══════════════════════════════════════════════════════════════════

const MAX_SAVE_SLOTS := 3
var current_save_slot := 0
var current_save_name := ""

func save_game(slot: int = -1, save_name: String = "") -> bool:
	"""Guardar partida en el slot especificado (o el actual si es -1)"""
	if slot >= 0:
		current_save_slot = slot
	
	if save_name != "":
		current_save_name = save_name
	
	var save_data = {
		"version": "1.0",
		"slot": current_save_slot,
		"save_name": current_save_name,
		"current_level": current_level,
		"current_checkpoint": current_checkpoint,
		"levels_completed": levels_completed,
		"total_deaths": total_deaths,
		"consecutive_deaths": consecutive_deaths,
		"total_time": total_time,
		"total_score": total_score,
		"level_state": LevelStateManager.save_level_state(),
		"timestamp": Time.get_unix_time_from_system(),
		"date_string": Time.get_datetime_string_from_system()
	}
	
	var file_path := "user://save_slot_%d.dat" % current_save_slot
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()
		print("[GameManager] Partida guardada en slot %d" % current_save_slot)
		return true
	else:
		push_error("[GameManager] Error al guardar en slot %d" % current_save_slot)
		return false


func load_game(slot: int = -1) -> bool:
	"""Cargar partida del slot especificado (o el actual si es -1)"""
	if slot >= 0:
		current_save_slot = slot
	
	var file_path := "user://save_slot_%d.dat" % current_save_slot
	
	if not FileAccess.file_exists(file_path):
		print("[GameManager] No existe guardado en slot %d" % current_save_slot)
		return false
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("[GameManager] Error al leer slot %d" % current_save_slot)
		return false
	
	var save_data = file.get_var()
	file.close()
	
	if save_data:
		current_level      = save_data.get("current_level", 1)
		current_checkpoint = save_data.get("current_checkpoint", 0)
		levels_completed   = save_data.get("levels_completed", [])
		total_deaths       = save_data.get("total_deaths", 0)
		consecutive_deaths = save_data.get("consecutive_deaths", 0)
		total_time         = save_data.get("total_time", 0.0)
		total_score        = save_data.get("total_score", 0)
		current_save_name  = save_data.get("save_name", "Partida %d" % (current_save_slot + 1))
		is_playing         = true
		
		print("[GameManager] Partida cargada desde slot %d: %s" % [current_save_slot, current_save_name])
		print("  - Nivel: %d, Checkpoint: %d, Puntuación: %d" % [current_level, current_checkpoint, total_score])
		
		# Cargar nivel guardado
		_load_level(current_level)
		
		# Restaurar estado del nivel
		var level_state: Dictionary = save_data.get("level_state", {})
		if not level_state.is_empty():
			await get_tree().create_timer(0.5).timeout  # Esperar a que el nivel cargue
			LevelStateManager.load_level_state(level_state)
		
		return true
	
	return false


func get_save_info(slot: int) -> Dictionary:
	"""Obtener información de un slot de guardado sin cargarlo"""
	var file_path := "user://save_slot_%d.dat" % slot
	
	if not FileAccess.file_exists(file_path):
		return {"exists": false, "slot": slot}
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return {"exists": false, "slot": slot}
	
	var save_data = file.get_var()
	file.close()
	
	if save_data:
		return {
			"exists": true,
			"slot": slot,
			"save_name": save_data.get("save_name", "Partida %d" % (slot + 1)),
			"level": save_data.get("current_level", 1),
			"checkpoint": save_data.get("current_checkpoint", 0),
			"deaths": save_data.get("total_deaths", 0),
			"time": save_data.get("total_time", 0.0),
			"score": save_data.get("total_score", 0),
			"date": save_data.get("date_string", "Desconocido"),
			"timestamp": save_data.get("timestamp", 0)
		}
	
	return {"exists": false, "slot": slot}


func delete_save(slot: int) -> bool:
	"""Eliminar un slot de guardado"""
	var file_path := "user://save_slot_%d.dat" % slot
	
	if FileAccess.file_exists(file_path):
		DirAccess.remove_absolute(file_path)
		print("[GameManager] Slot %d eliminado" % slot)
		return true
	
	return false


func has_any_save() -> bool:
	"""Verificar si existe algún guardado"""
	for i in range(MAX_SAVE_SLOTS):
		if FileAccess.file_exists("user://save_slot_%d.dat" % i):
			return true
	return false


func _load_level(level_number: int) -> void:
	"""Cargar nivel por número. Niveles disponibles: 01–05"""
	var level_path := "res://scenes/levels/level_%02d.tscn" % level_number
	if ResourceLoader.exists(level_path):
		get_tree().change_scene_to_file(level_path)
	else:
		push_warning("[GameManager] Nivel %d no encontrado: %s" % [level_number, level_path])


func advance_to_next_level() -> void:
	"""Avanzar al siguiente nivel con transición de fade"""
	var next_level := current_level + 1
	# Niveles disponibles: 1 (demo/tutorial), 2, 3, 4, 5
	if next_level > 5:
		# Juego completado → menú principal
		transition_to_scene("res://scenes/ui/main_menu.tscn")
		return
	LevelStateManager.reset_level_state()
	transition_to_level(next_level)


func get_level_name(level_number: int) -> String:
	"""Obtener nombre narrativo del nivel"""
	match level_number:
		1: return "Nivel Demo — Sector B"
		2: return "Acto I — Sector 7-F Security"
		3: return "Acto II — Control Center B"
		4: return "Acto III — Industrial Core"
		5: return "Acto IV — Reactor Core"
		_: return "Nivel %d" % level_number


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
	var master_idx := AudioServer.get_bus_index("Master")
	var music_idx  := AudioServer.get_bus_index("Music")
	var sfx_idx    := AudioServer.get_bus_index("SFX")

	if master_idx >= 0:
		AudioServer.set_bus_volume_db(master_idx, linear_to_db(master_volume))
	if music_idx >= 0:
		AudioServer.set_bus_volume_db(music_idx, linear_to_db(music_volume))
	if sfx_idx >= 0:
		AudioServer.set_bus_volume_db(sfx_idx, linear_to_db(sfx_volume))


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

func transition_to_level(level_number: int, fade_duration: float = 0.4) -> void:
	current_level = level_number
	is_playing = true  # Activar contador de tiempo
	
	# Música por nivel
	if has_node("/root/AudioManager"):
		var track := "level_%02d" % level_number
		AudioManager.play_music(track)
	
	await _fade_transition(fade_duration, func(): _load_level(level_number))


func transition_to_scene(scene_path: String, fade_duration: float = 0.4) -> void:
	# Pausar contador si va al menú
	if "menu" in scene_path.to_lower():
		is_playing = false
		# Música de menú
		if has_node("/root/AudioManager"):
			AudioManager.play_music("menu")
	await _fade_transition(fade_duration, func(): get_tree().change_scene_to_file(scene_path))


func _fade_transition(duration: float, change_cb: Callable) -> void:
	# Crear CanvasLayer para que sobreviva el cambio de escena
	var canvas := CanvasLayer.new()
	canvas.layer = 128  # encima de todo
	get_tree().root.add_child(canvas)

	var fade := ColorRect.new()
	fade.color = Color.BLACK
	fade.modulate.a = 0.0
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(fade)

	# Fade out
	var tw := create_tween()
	tw.tween_property(fade, "modulate:a", 1.0, duration)
	await tw.finished

	# Cambiar escena
	change_cb.call()

	# Esperar a que la nueva escena esté lista
	await get_tree().process_frame
	await get_tree().process_frame

	# Fade in
	tw = create_tween()
	tw.tween_property(fade, "modulate:a", 0.0, duration)
	await tw.finished

	canvas.queue_free()
