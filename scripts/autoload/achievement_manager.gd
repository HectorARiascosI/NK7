extends Node

## ════════════════════════════════════════════════════════════════
## ACHIEVEMENT MANAGER — NK-7
## ════════════════════════════════════════════════════════════════
## Sistema de logros persistente.
## Los logros se guardan en user://achievements.dat
## ════════════════════════════════════════════════════════════════

signal achievement_unlocked(achievement_id: String)

const SAVE_PATH := "user://achievements.dat"

# ── Definición de logros ──────────────────────────────────────────
const ACHIEVEMENTS := {
	# Progreso
	"first_steps":    { "name": "Primeros Pasos",      "desc": "Completa el nivel demo.",                "icon": "🔧", "secret": false },
	"sector_clear":   { "name": "Sector Despejado",    "desc": "Completa el Sector 7-F.",                "icon": "🔒", "secret": false },
	"control_master": { "name": "Control Total",       "desc": "Completa el Centro de Control.",         "icon": "💻", "secret": false },
	"industrial":     { "name": "Núcleo Industrial",   "desc": "Completa el Núcleo Industrial.",         "icon": "⚙️", "secret": false },
	"reactor_core":   { "name": "Núcleo del Reactor",  "desc": "Completa el Reactor Core.",              "icon": "☢️", "secret": false },
	"escape":         { "name": "Protocolo de Escape", "desc": "Escapa de la instalación NK-7.",         "icon": "🚀", "secret": false },
	# Combate
	"first_kill":     { "name": "Primer Objetivo",     "desc": "Destruye tu primer Ukibuki.",            "icon": "💥", "secret": false },
	"ukibuki_hunter": { "name": "Cazador de Robots",   "desc": "Destruye 10 Ukibukis.",                  "icon": "🤖", "secret": false },
	"pacifist":       { "name": "Pacifista",           "desc": "Completa un nivel sin destruir robots.", "icon": "☮️", "secret": true  },
	# Coleccionables
	"coin_collector": { "name": "Coleccionista",       "desc": "Recoge 50 monedas.",                     "icon": "🪙", "secret": false },
	"cube_master":    { "name": "Maestro de Cubos",    "desc": "Recoge 20 cubos holográficos.",          "icon": "🔷", "secret": false },
	"all_keycards":   { "name": "Acceso Total",        "desc": "Recoge todas las tarjetas de un nivel.", "icon": "🗝️", "secret": false },
	# Habilidad
	"no_damage":      { "name": "Intocable",           "desc": "Completa un nivel sin recibir daño.",    "icon": "🛡️", "secret": true  },
	"speedrun":       { "name": "Velocista",           "desc": "Completa un nivel en menos de 3 min.",   "icon": "⚡", "secret": true  },
	"no_deaths":      { "name": "Sin Bajas",           "desc": "Completa el juego sin morir.",           "icon": "💀", "secret": true  },
	# Exploración
	"checkpoint_pro": { "name": "Punto Seguro",        "desc": "Activa 5 checkpoints.",                  "icon": "📍", "secret": false },
	"energy_saver":   { "name": "Ahorro Energético",   "desc": "Completa un nivel con energía al 100%.", "icon": "🔋", "secret": true  },
	# Especiales
	"rena_partner":   { "name": "Trabajo en Equipo",   "desc": "Juega con RENA en modo cooperativo.",    "icon": "👥", "secret": false },
	"red_protocol":   { "name": "Protocolo Rojo",      "desc": "Desbloquea el nivel extra.",             "icon": "🔴", "secret": true  },
}

# ── Estado ────────────────────────────────────────────────────────
var _unlocked : Dictionary = {}   # id → timestamp
var _counters : Dictionary = {}   # id → int (para logros con contador)

# ══════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ══════════════════════════════════════════════════════════════════

func _ready() -> void:
	_load()

# ══════════════════════════════════════════════════════════════════
# API PÚBLICA
# ══════════════════════════════════════════════════════════════════

func unlock(achievement_id: String) -> void:
	"""Desbloquear un logro. No hace nada si ya está desbloqueado."""
	if not ACHIEVEMENTS.has(achievement_id):
		push_warning("[AchievementManager] Logro desconocido: %s" % achievement_id)
		return
	
	if is_unlocked(achievement_id):
		return
	
	_unlocked[achievement_id] = Time.get_unix_time_from_system()
	_save()
	achievement_unlocked.emit(achievement_id)
	
	# Sonido
	if has_node("/root/AudioManager"):
		AudioManager.play_sfx("achievement")
	
	print("[Logros] Desbloqueado: %s — %s" % [
		ACHIEVEMENTS[achievement_id]["name"],
		ACHIEVEMENTS[achievement_id]["desc"]
	])

func is_unlocked(achievement_id: String) -> bool:
	return _unlocked.has(achievement_id)

func get_unlock_time(achievement_id: String) -> int:
	return _unlocked.get(achievement_id, 0)

func get_all_achievements() -> Array[Dictionary]:
	"""Devuelve lista de todos los logros con su estado"""
	var result : Array[Dictionary] = []
	for id in ACHIEVEMENTS:
		var a : Dictionary = ACHIEVEMENTS[id].duplicate()
		a["id"]       = id
		a["unlocked"] = is_unlocked(id)
		a["time"]     = get_unlock_time(id)
		result.append(a)
	return result

func get_unlocked_count() -> int:
	return _unlocked.size()

func get_total_count() -> int:
	return ACHIEVEMENTS.size()

func get_completion_percent() -> float:
	if ACHIEVEMENTS.is_empty():
		return 0.0
	return float(_unlocked.size()) / float(ACHIEVEMENTS.size()) * 100.0

# ── Contadores para logros progresivos ───────────────────────────

func increment_counter(counter_id: String, amount: int = 1) -> void:
	"""Incrementar un contador y verificar logros asociados"""
	_counters[counter_id] = _counters.get(counter_id, 0) + amount
	_check_counter_achievements(counter_id)

func get_counter(counter_id: String) -> int:
	return _counters.get(counter_id, 0)

func _check_counter_achievements(counter_id: String) -> void:
	var val : int = _counters.get(counter_id, 0)
	match counter_id:
		"enemies_killed":
			if val >= 1:  unlock("first_kill")
			if val >= 10: unlock("ukibuki_hunter")
		"coins_collected":
			if val >= 50: unlock("coin_collector")
		"cubes_collected":
			if val >= 20: unlock("cube_master")
		"checkpoints_reached":
			if val >= 5:  unlock("checkpoint_pro")

# ══════════════════════════════════════════════════════════════════
# PERSISTENCIA
# ══════════════════════════════════════════════════════════════════

func _save() -> void:
	var data := {
		"unlocked": _unlocked.duplicate(),
		"counters": _counters.duplicate(),
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(data)
		file.close()

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var data = file.get_var()
	file.close()
	if data is Dictionary:
		_unlocked = data.get("unlocked", {})
		_counters = data.get("counters", {})

func reset_all() -> void:
	"""Resetear todos los logros (para debug)"""
	_unlocked.clear()
	_counters.clear()
	_save()
