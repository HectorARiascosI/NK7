extends Node2D
class_name ElectricDoor

## ════════════════════════════════════════════════════════════════
## PUERTA ELECTRIFICADA NK-7 - SISTEMA AVANZADO
## ════════════════════════════════════════════════════════════════
## Sistema completo de puertas con múltiples estados, reparación
## multi-paso, física dinámica y efectos visuales profesionales.
##
## ESTADOS:
##   - LOCKED_DAMAGED:  Cerrada, dañada, luz roja parpadeante
##   - REPAIRING:       Jugador reparando (animación herramienta)
##   - LOCKED_FIXED:    Reparada pero sin energía, luz amarilla
##   - UNLOCKING:       Desbloqueando con energía, chispas
##   - OPENING:         Animación de apertura
##   - OPEN:            Completamente abierta, luz verde
##   - CLOSING:         Cerrando (si auto_close)
##
## INTERACCIONES:
##   - use_tool:    Reparar daños (multi-paso)
##   - hack:        Restaurar energía / bypass
##   - interact:    Abrir puerta reparada
## ════════════════════════════════════════════════════════════════

signal door_state_changed(new_state: DoorState)
signal repair_progress_updated(current: int, total: int)
signal door_opened
signal door_closed
signal player_damaged
signal energy_restored

# ══════════════════════════════════════════════════════════════════
# ENUMS Y CONSTANTES
# ══════════════════════════════════════════════════════════════════

enum DoorState {
	LOCKED_DAMAGED,   ## Cerrada y dañada (luz roja)
	REPAIRING,        ## En proceso de reparación
	LOCKED_FIXED,     ## Reparada pero sin energía (luz amarilla)
	UNLOCKING,        ## Restaurando energía (chispas)
	OPENING,          ## Abriéndose
	OPEN,             ## Abierta (luz verde)
	CLOSING,          ## Cerrándose
	ELECTRIFIED       ## Electrificada (daña al jugador)
}

enum DamageLevel {
	NONE,      ## Sin daños
	LIGHT,     ## 1 paso de reparación
	MEDIUM,    ## 2 pasos de reparación
	HEAVY      ## 3 pasos de reparación
}

# ══════════════════════════════════════════════════════════════════
# CONFIGURACIÓN EXPORTADA
# ══════════════════════════════════════════════════════════════════

@export_group("Estado Inicial")
@export var initial_state : DoorState = DoorState.LOCKED_DAMAGED
@export var damage_level : DamageLevel = DamageLevel.MEDIUM
@export var starts_electrified : bool = false

@export_group("Comportamiento")
@export var auto_close : bool = false
@export var auto_close_delay : float = 4.0
@export var requires_energy : bool = true
@export var can_be_forced : bool = false  ## Puede forzarse con fuerza bruta

@export_group("Reparación")
@export var repair_time_per_step : float = 2.0  ## Tiempo por paso de reparación
@export var requires_tool : bool = true
@export var tool_durability_cost : int = 10  ## Coste de durabilidad por paso

@export_group("Energía")
@export var energy_required : int = 50
@export var hack_time : float = 3.0

@export_group("Física")
@export var door_weight : float = 100.0  ## Afecta velocidad de apertura
@export var opening_speed : float = 1.0
@export var electrified_damage : int = 25

@export_group("Audio")
@export var play_sounds : bool = true
@export var sound_volume : float = 0.8

# ══════════════════════════════════════════════════════════════════
# NODOS
# ══════════════════════════════════════════════════════════════════

@onready var sprite : AnimatedSprite2D = $Sprite
@onready var collision_body : StaticBody2D = $DoorBody
@onready var collision_shape : CollisionShape2D = $DoorBody/CollisionShape2D
@onready var interaction_area : Area2D = $InteractionArea
@onready var damage_area : Area2D = $DamageArea
@onready var light : PointLight2D = $StatusLight
@onready var particles : GPUParticles2D = $Particles
@onready var repair_particles : GPUParticles2D = $RepairParticles
@onready var hint_label : Label = $HintLabel
@onready var progress_bar : ProgressBar = $ProgressBar
@onready var audio_player : AudioStreamPlayer2D = $AudioPlayer

# ══════════════════════════════════════════════════════════════════
# VARIABLES DE ESTADO
# ══════════════════════════════════════════════════════════════════

var current_state : DoorState = DoorState.LOCKED_DAMAGED
var repair_steps_completed : int = 0
var repair_steps_required : int = 0
var is_electrified : bool = false
var has_energy : bool = false
var is_animating : bool = false

# Variables de interacción
var player_nearby : Node2D = null
var is_repairing : bool = false
var is_hacking : bool = false
var repair_timer : float = 0.0
var hack_timer : float = 0.0

# Variables de física
var door_open_amount : float = 0.0  ## 0.0 = cerrada, 1.0 = abierta
var door_velocity : float = 0.0

# ══════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ══════════════════════════════════════════════════════════════════

func _ready() -> void:
	_setup_nodes()
	_setup_signals()
	_calculate_repair_steps()
	_initialize_state()
	_update_visuals()

func _setup_nodes() -> void:
	# Configurar hint label
	if hint_label:
		hint_label.visible = false
		hint_label.add_theme_font_size_override("font_size", 10)
		hint_label.add_theme_color_override("font_color", Color(0.91, 0.63, 0.0))
	
	# Configurar progress bar
	if progress_bar:
		progress_bar.visible = false
		progress_bar.max_value = 100
		progress_bar.value = 0
	
	# Configurar partículas
	if particles:
		particles.emitting = false
	if repair_particles:
		repair_particles.emitting = false

func _setup_signals() -> void:
	if interaction_area:
		interaction_area.body_entered.connect(_on_player_entered)
		interaction_area.body_exited.connect(_on_player_exited)
	
	if damage_area:
		damage_area.body_entered.connect(_on_damage_area_entered)

func _calculate_repair_steps() -> void:
	match damage_level:
		DamageLevel.NONE:
			repair_steps_required = 0
		DamageLevel.LIGHT:
			repair_steps_required = 1
		DamageLevel.MEDIUM:
			repair_steps_required = 2
		DamageLevel.HEAVY:
			repair_steps_required = 3

func _initialize_state() -> void:
	current_state = initial_state
	is_electrified = starts_electrified
	
	# Si no está dañada, ya tiene energía
	if damage_level == DamageLevel.NONE:
		has_energy = true
		current_state = DoorState.LOCKED_FIXED

# ══════════════════════════════════════════════════════════════════
# PROCESO PRINCIPAL
# ══════════════════════════════════════════════════════════════════

func _process(delta: float) -> void:
	_handle_player_input()
	_update_repair_progress(delta)
	_update_hack_progress(delta)
	_update_door_physics(delta)
	_update_visuals()

func _handle_player_input() -> void:
	if not player_nearby or is_animating:
		return
	
	match current_state:
		DoorState.LOCKED_DAMAGED:
			if Input.is_action_pressed("use_tool") and not is_repairing:
				_start_repair()
			elif Input.is_action_just_released("use_tool") and is_repairing:
				_cancel_repair()
		
		DoorState.LOCKED_FIXED:
			if Input.is_action_pressed("hack") and not is_hacking:
				_start_hack()
			elif Input.is_action_just_released("hack") and is_hacking:
				_cancel_hack()
		
		DoorState.OPEN:
			pass  # Puerta abierta, no hay acciones
		
		_:
			pass

func _update_repair_progress(delta: float) -> void:
	if not is_repairing:
		return
	
	repair_timer += delta
	var progress := (repair_timer / repair_time_per_step) * 100.0
	
	if progress_bar:
		progress_bar.value = progress
	
	# Completar paso de reparación
	if repair_timer >= repair_time_per_step:
		_complete_repair_step()

func _update_hack_progress(delta: float) -> void:
	if not is_hacking:
		return
	
	hack_timer += delta
	var progress := (hack_timer / hack_time) * 100.0
	
	if progress_bar:
		progress_bar.value = progress
	
	# Completar hack
	if hack_timer >= hack_time:
		_complete_hack()

func _update_door_physics(delta: float) -> void:
	# Física suave de apertura/cierre
	var target_amount : float = 1.0 if current_state == DoorState.OPEN else 0.0
	var speed : float = opening_speed / (door_weight * 0.01)
	
	door_open_amount = lerp(door_open_amount, target_amount, speed * delta)
	
	# Actualizar colisión
	if collision_shape:
		collision_shape.disabled = door_open_amount > 0.8

# ══════════════════════════════════════════════════════════════════
# SISTEMA DE REPARACIÓN
# ══════════════════════════════════════════════════════════════════

func _start_repair() -> void:
	if repair_steps_completed >= repair_steps_required:
		return
	
	is_repairing = true
	repair_timer = 0.0
	current_state = DoorState.REPAIRING
	
	if progress_bar:
		progress_bar.visible = true
		progress_bar.value = 0
	
	if repair_particles:
		repair_particles.emitting = true
	
	_play_sound("repair_start")
	_update_hint_text("Reparando... [Mantén ESPACIO]")
	
	door_state_changed.emit(current_state)

func _complete_repair_step() -> void:
	repair_steps_completed += 1
	repair_timer = 0.0
	is_repairing = false
	
	if repair_particles:
		repair_particles.emitting = false
	
	_play_sound("repair_complete")
	repair_progress_updated.emit(repair_steps_completed, repair_steps_required)
	
	# Verificar si la reparación está completa
	if repair_steps_completed >= repair_steps_required:
		_finish_repair()
	else:
		current_state = DoorState.LOCKED_DAMAGED
		_update_hint_text("[ESPACIO] Reparar (%d/%d)" % [repair_steps_completed, repair_steps_required])
	
	if progress_bar:
		progress_bar.visible = false

func _cancel_repair() -> void:
	is_repairing = false
	repair_timer = 0.0
	current_state = DoorState.LOCKED_DAMAGED
	
	if progress_bar:
		progress_bar.visible = false
	
	if repair_particles:
		repair_particles.emitting = false
	
	_update_hint_text("[ESPACIO] Reparar (%d/%d)" % [repair_steps_completed, repair_steps_required])

func _finish_repair() -> void:
	current_state = DoorState.LOCKED_FIXED
	is_electrified = false
	
	if progress_bar:
		progress_bar.visible = false
	
	_play_sound("repair_finished")
	_update_hint_text("[E] Hackear sistema eléctrico")
	
	door_state_changed.emit(current_state)

# ══════════════════════════════════════════════════════════════════
# SISTEMA DE HACKEO
# ══════════════════════════════════════════════════════════════════

func _start_hack() -> void:
	if has_energy:
		return
	
	is_hacking = true
	hack_timer = 0.0
	current_state = DoorState.UNLOCKING
	
	if progress_bar:
		progress_bar.visible = true
		progress_bar.value = 0
	
	if particles:
		particles.emitting = true
	
	_play_sound("hack_start")
	_update_hint_text("Hackeando... [Mantén E]")
	
	door_state_changed.emit(current_state)

func _complete_hack() -> void:
	is_hacking = false
	hack_timer = 0.0
	has_energy = true
	
	if progress_bar:
		progress_bar.visible = false
	
	if particles:
		particles.emitting = false
	
	_play_sound("hack_complete")
	energy_restored.emit()
	
	# Abrir puerta automáticamente
	await get_tree().create_timer(0.5).timeout
	open_door()

func _cancel_hack() -> void:
	is_hacking = false
	hack_timer = 0.0
	current_state = DoorState.LOCKED_FIXED
	
	if progress_bar:
		progress_bar.visible = false
	
	if particles:
		particles.emitting = false
	
	_update_hint_text("[E] Hackear sistema eléctrico")

# ══════════════════════════════════════════════════════════════════
# CONTROL DE PUERTA
# ══════════════════════════════════════════════════════════════════

func open_door() -> void:
	if current_state == DoorState.OPEN or is_animating:
		return
	
	if not has_energy and requires_energy:
		_show_error_message("Sin energía")
		return
	
	is_animating = true
	current_state = DoorState.OPENING
	
	_play_sound("door_opening")
	door_state_changed.emit(current_state)
	
	# Animación de apertura
	if sprite:
		sprite.play("opening")
		await sprite.animation_finished
	
	current_state = DoorState.OPEN
	is_animating = false
	door_opened.emit()
	
	_update_hint_text("")
	
	# Auto-cierre
	if auto_close:
		await get_tree().create_timer(auto_close_delay).timeout
		close_door()

func close_door() -> void:
	if current_state != DoorState.OPEN or is_animating:
		return
	
	is_animating = true
	current_state = DoorState.CLOSING
	
	_play_sound("door_closing")
	door_state_changed.emit(current_state)
	
	# Animación de cierre
	if sprite:
		sprite.play("closing")
		await sprite.animation_finished
	
	current_state = DoorState.LOCKED_FIXED
	is_animating = false
	door_closed.emit()
	
	if player_nearby:
		_update_hint_text("[E] Abrir puerta")

# ══════════════════════════════════════════════════════════════════
# VISUALES Y EFECTOS
# ══════════════════════════════════════════════════════════════════

func _update_visuals() -> void:
	if not sprite:
		return
	
	# Actualizar sprite según estado
	match current_state:
		DoorState.LOCKED_DAMAGED:
			sprite.play("locked_damaged")
			_set_light_color(Color.RED, true)  # Rojo parpadeante
		
		DoorState.REPAIRING:
			sprite.play("locked_damaged")
			_set_light_color(Color.ORANGE, false)
		
		DoorState.LOCKED_FIXED:
			sprite.play("locked_fixed")
			_set_light_color(Color.YELLOW, false)
		
		DoorState.UNLOCKING:
			sprite.play("unlocking")
			_set_light_color(Color.CYAN, true)  # Cyan parpadeante
		
		DoorState.OPENING, DoorState.OPEN:
			_set_light_color(Color.GREEN, false)
		
		DoorState.CLOSING:
			_set_light_color(Color.YELLOW, false)
		
		DoorState.ELECTRIFIED:
			sprite.play("electrified")
			_set_light_color(Color.RED, true)

func _set_light_color(color: Color, blink: bool) -> void:
	if not light:
		return
	
	light.color = color
	
	if blink:
		var tween := create_tween().set_loops()
		tween.tween_property(light, "energy", 1.5, 0.3)
		tween.tween_property(light, "energy", 0.5, 0.3)
	else:
		light.energy = 1.0

func _update_hint_text(text: String) -> void:
	if hint_label:
		hint_label.text = text
		hint_label.visible = text != ""

func _show_error_message(message: String) -> void:
	if not hint_label:
		return
	
	hint_label.text = "⚠ " + message
	hint_label.add_theme_color_override("font_color", Color.RED)
	
	await get_tree().create_timer(2.0).timeout
	
	hint_label.add_theme_color_override("font_color", Color(0.91, 0.63, 0.0))
	_update_hint_based_on_state()

func _update_hint_based_on_state() -> void:
	if not player_nearby:
		_update_hint_text("")
		return
	
	match current_state:
		DoorState.LOCKED_DAMAGED:
			var text := "[ESPACIO] Reparar"
			if repair_steps_required > 0:
				text += " (%d/%d)" % [repair_steps_completed, repair_steps_required]
			_update_hint_text(text)
		
		DoorState.LOCKED_FIXED:
			_update_hint_text("[E] Hackear sistema eléctrico")
		
		DoorState.OPEN:
			_update_hint_text("")
		
		_:
			_update_hint_text("")

# ══════════════════════════════════════════════════════════════════
# DETECCIÓN DE JUGADOR
# ══════════════════════════════════════════════════════════════════

func _on_player_entered(body: Node2D) -> void:
	if not (body.is_in_group("player") or body.name == "kai"):
		return
	
	player_nearby = body
	_update_hint_based_on_state()

func _on_player_exited(body: Node2D) -> void:
	if not (body.is_in_group("player") or body.name == "kai"):
		return
	
	player_nearby = null
	_update_hint_text("")
	
	# Cancelar acciones en progreso
	if is_repairing:
		_cancel_repair()
	if is_hacking:
		_cancel_hack()

func _on_damage_area_entered(body: Node2D) -> void:
	if not is_electrified:
		return
	
	if body.is_in_group("player") or body.name == "kai":
		_damage_player(body)

func _damage_player(player: Node2D) -> void:
	player_damaged.emit()
	
	# Aplicar daño
	if player.has_method("take_damage"):
		player.take_damage(electrified_damage)
	
	# Efecto visual
	_play_sound("electric_shock")
	
	# Empujar al jugador
	if player is CharacterBody2D:
		var push_direction := (player.global_position - global_position).normalized()
		player.velocity = push_direction * 300.0

# ══════════════════════════════════════════════════════════════════
# AUDIO
# ══════════════════════════════════════════════════════════════════

func _play_sound(sound_name: String) -> void:
	if not play_sounds or not audio_player:
		return
	
	# Aquí cargarías los sonidos específicos
	# audio_player.stream = load("res://assets/sounds/" + sound_name + ".ogg")
	# audio_player.volume_db = linear_to_db(sound_volume)
	# audio_player.play()
	pass

# ══════════════════════════════════════════════════════════════════
# API PÚBLICA
# ══════════════════════════════════════════════════════════════════

func activate() -> void:
	"""Activar desde interruptor externo"""
	if has_energy:
		open_door()
	else:
		has_energy = true
		energy_restored.emit()
		open_door()

func deactivate() -> void:
	"""Desactivar desde interruptor externo"""
	close_door()

func force_open() -> void:
	"""Forzar apertura (bypass de seguridad)"""
	if not can_be_forced:
		return
	
	has_energy = true
	repair_steps_completed = repair_steps_required
	open_door()

func electrify() -> void:
	"""Electrificar la puerta"""
	is_electrified = true
	current_state = DoorState.ELECTRIFIED

func de_electrify() -> void:
	"""Quitar electrificación"""
	is_electrified = false
	if repair_steps_completed >= repair_steps_required:
		current_state = DoorState.LOCKED_FIXED
	else:
		current_state = DoorState.LOCKED_DAMAGED

func get_repair_progress() -> float:
	"""Obtener progreso de reparación (0.0 - 1.0)"""
	if repair_steps_required == 0:
		return 1.0
	return float(repair_steps_completed) / float(repair_steps_required)

func is_fully_functional() -> bool:
	"""Verificar si la puerta está completamente funcional"""
	return repair_steps_completed >= repair_steps_required and has_energy

func get_state() -> DoorState:
	"""Obtener estado actual"""
	return current_state
