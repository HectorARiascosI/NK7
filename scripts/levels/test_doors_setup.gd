extends Node2D

## ════════════════════════════════════════════════════════════════
## CONFIGURACIÓN DEL NIVEL DE PRUEBA DE PUERTAS
## ════════════════════════════════════════════════════════════════
## Script para configurar las puertas del nivel de prueba con
## diferentes configuraciones y conectar señales para debugging.
## ════════════════════════════════════════════════════════════════

@onready var door1 : Node2D = $Doors/Door1_Tutorial
@onready var door2 : Node2D = $Doors/Door2_Medium
@onready var door3 : Node2D = $Doors/Door3_Heavy
@onready var door4 : Node2D = $Doors/Door4_Electrified

func _ready() -> void:
	_configure_doors()
	_connect_signals()
	_print_instructions()

func _configure_doors() -> void:
	"""Configurar cada puerta con parámetros específicos"""
	
	# PUERTA 1: Tutorial - Fácil
	if door1:
		door1.damage_level = 1  # LIGHT - 1 paso
		door1.initial_state = 0  # LOCKED_DAMAGED
		door1.starts_electrified = false
		door1.repair_time_per_step = 1.5  # Más rápido para tutorial
		door1.hack_time = 2.0
		door1.tool_durability_cost = 5  # Menos coste
	
	# PUERTA 2: Media - Normal
	if door2:
		door2.damage_level = 2  # MEDIUM - 2 pasos
		door2.initial_state = 0  # LOCKED_DAMAGED
		door2.starts_electrified = false
		door2.repair_time_per_step = 2.0
		door2.hack_time = 3.0
		door2.tool_durability_cost = 10
	
	# PUERTA 3: Pesada - Difícil
	if door3:
		door3.damage_level = 3  # HEAVY - 3 pasos
		door3.initial_state = 0  # LOCKED_DAMAGED
		door3.starts_electrified = false
		door3.repair_time_per_step = 2.5
		door3.hack_time = 4.0
		door3.tool_durability_cost = 15
		door3.door_weight = 150.0  # Más pesada, abre más lento
	
	# PUERTA 4: Electrificada - Peligrosa
	if door4:
		door4.damage_level = 2  # MEDIUM - 2 pasos
		door4.initial_state = 7  # ELECTRIFIED
		door4.starts_electrified = true
		door4.repair_time_per_step = 2.0
		door4.hack_time = 3.0
		door4.tool_durability_cost = 10
		door4.electrified_damage = 25

func _connect_signals() -> void:
	"""Conectar señales para debugging y feedback"""
	
	if door1:
		door1.door_state_changed.connect(_on_door1_state_changed)
		door1.repair_progress_updated.connect(_on_door1_repair_progress)
		door1.door_opened.connect(_on_door1_opened)
	
	if door2:
		door2.door_state_changed.connect(_on_door2_state_changed)
		door2.repair_progress_updated.connect(_on_door2_repair_progress)
		door2.door_opened.connect(_on_door2_opened)
	
	if door3:
		door3.door_state_changed.connect(_on_door3_state_changed)
		door3.repair_progress_updated.connect(_on_door3_repair_progress)
		door3.door_opened.connect(_on_door3_opened)
	
	if door4:
		door4.door_state_changed.connect(_on_door4_state_changed)
		door4.player_damaged.connect(_on_door4_player_damaged)
		door4.door_opened.connect(_on_door4_opened)

# ══════════════════════════════════════════════════════════════════
# CALLBACKS DE SEÑALES
# ══════════════════════════════════════════════════════════════════

func _on_door1_state_changed(new_state) -> void:
	print("[DOOR 1] Estado cambiado a: ", _get_state_name(new_state))

func _on_door1_repair_progress(current: int, total: int) -> void:
	print("[DOOR 1] Progreso de reparación: %d/%d" % [current, total])

func _on_door1_opened() -> void:
	print("[DOOR 1] ✓ Puerta abierta - Tutorial completado")

func _on_door2_state_changed(new_state) -> void:
	print("[DOOR 2] Estado cambiado a: ", _get_state_name(new_state))

func _on_door2_repair_progress(current: int, total: int) -> void:
	print("[DOOR 2] Progreso de reparación: %d/%d" % [current, total])

func _on_door2_opened() -> void:
	print("[DOOR 2] ✓ Puerta abierta - Nivel medio completado")

func _on_door3_state_changed(new_state) -> void:
	print("[DOOR 3] Estado cambiado a: ", _get_state_name(new_state))

func _on_door3_repair_progress(current: int, total: int) -> void:
	print("[DOOR 3] Progreso de reparación: %d/%d" % [current, total])

func _on_door3_opened() -> void:
	print("[DOOR 3] ✓ Puerta abierta - Nivel difícil completado")

func _on_door4_state_changed(new_state) -> void:
	print("[DOOR 4] Estado cambiado a: ", _get_state_name(new_state))

func _on_door4_player_damaged() -> void:
	print("[DOOR 4] ⚠ ¡Jugador electrocutado!")

func _on_door4_opened() -> void:
	print("[DOOR 4] ✓ Puerta abierta - Desafío eléctrico completado")
	print("\n═══════════════════════════════════════")
	print("  ¡TODAS LAS PUERTAS COMPLETADAS!")
	print("═══════════════════════════════════════\n")

# ══════════════════════════════════════════════════════════════════
# UTILIDADES
# ══════════════════════════════════════════════════════════════════

func _get_state_name(state: int) -> String:
	"""Convertir número de estado a nombre legible"""
	match state:
		0: return "LOCKED_DAMAGED"
		1: return "REPAIRING"
		2: return "LOCKED_FIXED"
		3: return "UNLOCKING"
		4: return "OPENING"
		5: return "OPEN"
		6: return "CLOSING"
		7: return "ELECTRIFIED"
		_: return "UNKNOWN"

func _print_instructions() -> void:
	"""Imprimir instrucciones en consola"""
	print("\n════════════════════════════════════════════════════════════")
	print("  NIVEL DE PRUEBA - SISTEMA DE PUERTAS ELECTRIFICADAS NK-7")
	print("════════════════════════════════════════════════════════════")
	print("\nCONFIGURACIÓN DE PUERTAS:")
	print("  • Puerta 1: Tutorial (1 paso, fácil)")
	print("  • Puerta 2: Media (2 pasos, normal)")
	print("  • Puerta 3: Pesada (3 pasos, difícil)")
	print("  • Puerta 4: Electrificada (2 pasos, peligrosa)")
	print("\nCONTROLES:")
	print("  [ESPACIO] - Reparar puerta (mantener)")
	print("  [E] - Hackear sistema eléctrico (mantener)")
	print("  [FLECHAS] - Movimiento")
	print("  [SHIFT] - Correr")
	print("\nRECURSOS INICIALES:")
	print("  • Salud: 100")
	print("  • Energía: 100")
	print("  • Durabilidad herramienta: 100")
	print("\n════════════════════════════════════════════════════════════\n")

# ══════════════════════════════════════════════════════════════════
# DEBUG - Atajos de teclado
# ══════════════════════════════════════════════════════════════════

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return
	
	match event.keycode:
		KEY_1:
			if door1:
				door1.force_open()
				print("[DEBUG] Puerta 1 forzada a abrir")
		
		KEY_2:
			if door2:
				door2.force_open()
				print("[DEBUG] Puerta 2 forzada a abrir")
		
		KEY_3:
			if door3:
				door3.force_open()
				print("[DEBUG] Puerta 3 forzada a abrir")
		
		KEY_4:
			if door4:
				door4.de_electrify()
				print("[DEBUG] Puerta 4 des-electrificada")
		
		KEY_R:
			get_tree().reload_current_scene()
			print("[DEBUG] Nivel reiniciado")
		
		KEY_H:
			var player = get_tree().get_first_node_in_group("player")
			if player and player.has_method("heal"):
				player.heal(100)
				player.restore_energy(100)
				player.repair_tool(100)
				print("[DEBUG] Recursos del jugador restaurados")
