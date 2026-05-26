extends StaticBody2D
class_name LockedDoor

## ════════════════════════════════════════════════════════════════
## PUERTA BLOQUEADA NK-7 (FILA INFERIOR)
## ════════════════════════════════════════════════════════════════
## Puerta bloqueada que requiere hackeo con [Q]
## 
## SECUENCIA DE FRAMES (Fila inferior del spritesheet):
##   Frame 0 (X=0, Y=312):    Panel apagado - LOCKED
##   Frame 1 (X=192, Y=312):  Hackeando, panel activo - HACKING
##   Frame 2 (X=384, Y=312):  Desbloqueada, efectos - UNLOCKED
##   Frame 3 (X=576, Y=312):  Abierta completamente - OPEN
##
## INTERACCIÓN: Mantener [Q] para hackear → Automáticamente abre
## ════════════════════════════════════════════════════════════════

signal hack_started
signal hack_progress(current: float, total: float)
signal hack_completed
signal door_opened
signal door_closed

# ══════════════════════════════════════════════════════════════════
# CONFIGURACIÓN
# ══════════════════════════════════════════════════════════════════

@export_group("Hackeo")
@export var hack_time : float = 3.0  ## Tiempo total de hackeo
@export var energy_cost : int = 20  ## Energía consumida
@export var hack_difficulty : int = 1  ## 1=Fácil, 2=Medio, 3=Difícil

@export_group("Identificación")
@export var unique_id : String = ""  ## ID único para persistencia

@export_group("Comportamiento")
@export var auto_close : bool = false
@export var auto_close_delay : float = 5.0
@export var opening_duration : float = 1.0

@export_group("Seguridad")
@export var requires_keycard : bool = false
@export var keycard_id : String = ""

# ══════════════════════════════════════════════════════════════════
# NODOS
# ══════════════════════════════════════════════════════════════════

@onready var sprite : AnimatedSprite2D = $Sprite
@onready var collision : CollisionShape2D = $Collision
@onready var interaction_area : Area2D = $InteractionArea
@onready var hint_label : Label = $HintLabel
@onready var progress_bar : ProgressBar = $ProgressBar
@onready var particles : GPUParticles2D = $HackParticles
@onready var status_light : PointLight2D = $StatusLight
@onready var panel_light : PointLight2D = $PanelLight

# ══════════════════════════════════════════════════════════════════
# ESTADO
# ══════════════════════════════════════════════════════════════════

enum State { LOCKED, HACKING, UNLOCKED, OPENING, OPEN, CLOSING }

var current_state : State = State.LOCKED
var is_hacking : bool = false
var hack_timer : float = 0.0
var player_nearby : CharacterBody2D = null
var has_been_hacked : bool = false

# ══════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ══════════════════════════════════════════════════════════════════

func _ready() -> void:
	_setup_nodes()
	_connect_signals()
	
	# Generar ID único si no tiene
	if unique_id.is_empty():
		unique_id = "locked_door_%s_%d" % [name, get_instance_id()]
	
	# Verificar si ya fue abierta
	if LevelStateManager.is_door_opened(unique_id):
		current_state = State.OPEN
		has_been_hacked = true
		collision.disabled = true
		if sprite:
			sprite.play("open")
	else:
		_update_visuals()

func _setup_nodes() -> void:
	if hint_label:
		hint_label.visible = false
	if progress_bar:
		progress_bar.visible = false
		progress_bar.max_value = 100
	if particles:
		particles.emitting = false
	if status_light:
		status_light.color = Color.RED
		status_light.energy = 0.8
	if panel_light:
		panel_light.color = Color(0.2, 0.2, 0.3)
		panel_light.energy = 0.3

func _connect_signals() -> void:
	if interaction_area:
		interaction_area.body_entered.connect(_on_player_entered)
		interaction_area.body_exited.connect(_on_player_exited)

# ══════════════════════════════════════════════════════════════════
# PROCESO
# ══════════════════════════════════════════════════════════════════

func _process(delta: float) -> void:
	_handle_input()
	_update_hack_progress(delta)

func _handle_input() -> void:
	if not player_nearby or current_state != State.LOCKED:
		return
	
	# Iniciar hackeo con [Q]
	if Input.is_action_pressed("hack") and not is_hacking:
		_start_hack()
	
	# Cancelar si suelta [Q]
	elif Input.is_action_just_released("hack") and is_hacking:
		_cancel_hack()

func _update_hack_progress(delta: float) -> void:
	if not is_hacking:
		return
	
	hack_timer += delta
	var progress := (hack_timer / hack_time) * 100.0
	
	if progress_bar:
		progress_bar.value = progress
	
	hack_progress.emit(hack_timer, hack_time)
	
	# Completar hackeo
	if hack_timer >= hack_time:
		_complete_hack()

# ══════════════════════════════════════════════════════════════════
# SISTEMA DE HACKEO
# ══════════════════════════════════════════════════════════════════

func _start_hack() -> void:
	if not player_nearby:
		return
	
	# Verificar tarjeta de acceso si es necesaria
	if requires_keycard:
		if not _check_keycard():
			_show_message("⚠ Requiere tarjeta de acceso")
			return
	
	# Verificar energía
	if player_nearby.has_method("consume_energy"):
		if not player_nearby.consume_energy(energy_cost):
			_show_message("⚠ Energía insuficiente")
			return
	
	is_hacking = true
	hack_timer = 0.0
	current_state = State.HACKING
	
	# Activar efectos
	if particles:
		particles.emitting = true
	if progress_bar:
		progress_bar.visible = true
		progress_bar.value = 0
	if panel_light:
		panel_light.color = Color.CYAN
		panel_light.energy = 1.5
		_blink_panel_light()
	
	# Animación de hackeo
	if sprite:
		sprite.play("hacking")
	
	# Animación del jugador
	if player_nearby and player_nearby.has_node("AnimatedSprite2D"):
		player_nearby.get_node("AnimatedSprite2D").play("hack")
	
	hack_started.emit()
	_update_hint("[Q] Hackeando sistema...")

func _complete_hack() -> void:
	is_hacking = false
	hack_timer = 0.0
	has_been_hacked = true
	current_state = State.UNLOCKED
	
	if particles:
		particles.emitting = false
	if progress_bar:
		progress_bar.visible = false
	
	hack_completed.emit()
	
	# Efectos de éxito
	if sprite:
		sprite.play("unlocked")
	if status_light:
		status_light.color = Color.GREEN
		status_light.energy = 1.5
	if panel_light:
		panel_light.color = Color.GREEN
		panel_light.energy = 1.0
	
	_update_hint("✓ Sistema hackeado")
	
	# Esperar un momento antes de abrir
	await get_tree().create_timer(0.8).timeout
	
	# Abrir automáticamente
	_open_door()

func _cancel_hack() -> void:
	is_hacking = false
	hack_timer = 0.0
	current_state = State.LOCKED
	
	if particles:
		particles.emitting = false
	if progress_bar:
		progress_bar.visible = false
	if panel_light:
		panel_light.color = Color(0.2, 0.2, 0.3)
		panel_light.energy = 0.3
	
	_update_hint("[Q] Hackear sistema")
	_update_visuals()

func _check_keycard() -> bool:
	if not player_nearby:
		return false
	
	# Verificar si el jugador tiene la tarjeta
	if player_nearby.has_method("has_keycard"):
		return player_nearby.has_keycard(keycard_id)
	
	return false

# ══════════════════════════════════════════════════════════════════
# CONTROL DE PUERTA
# ══════════════════════════════════════════════════════════════════

func _open_door() -> void:
	current_state = State.OPENING
	
	# Registrar en el sistema de persistencia
	LevelStateManager.register_door_opened(unique_id)
	
	if sprite:
		sprite.play("opening")
	if status_light:
		status_light.color = Color.GREEN
		status_light.energy = 2.0
	
	_update_hint("Abriendo...")
	
	# Desactivar colisión gradualmente
	var tween := create_tween()
	tween.tween_property(collision, "disabled", true, opening_duration)
	
	await get_tree().create_timer(opening_duration).timeout
	
	current_state = State.OPEN
	door_opened.emit()
	_update_hint("")
	
	if sprite:
		sprite.play("open")
	
	# Auto-cierre
	if auto_close:
		await get_tree().create_timer(auto_close_delay).timeout
		_close_door()

func _close_door() -> void:
	if current_state != State.OPEN:
		return
	
	current_state = State.CLOSING
	
	if sprite:
		sprite.play("closing")
	if status_light:
		status_light.color = Color.YELLOW
	
	collision.disabled = false
	
	await get_tree().create_timer(opening_duration).timeout
	
	# Si ya fue hackeada, queda desbloqueada
	if has_been_hacked:
		current_state = State.UNLOCKED
		if player_nearby:
			_update_hint("[Q] Abrir puerta")
	else:
		current_state = State.LOCKED
		if player_nearby:
			_update_hint("[Q] Hackear sistema")
	
	door_closed.emit()
	_update_visuals()

# ══════════════════════════════════════════════════════════════════
# VISUALES
# ══════════════════════════════════════════════════════════════════

func _update_visuals() -> void:
	if not sprite:
		return
	
	match current_state:
		State.LOCKED:
			sprite.play("locked")
			if status_light:
				status_light.color = Color.RED
				status_light.energy = 0.8
			if panel_light:
				panel_light.color = Color(0.2, 0.2, 0.3)
				panel_light.energy = 0.3
		
		State.HACKING:
			sprite.play("hacking")
		
		State.UNLOCKED:
			sprite.play("unlocked")
		
		State.OPENING, State.OPEN:
			pass  # Ya manejado en _open_door()
		
		State.CLOSING:
			pass  # Ya manejado en _close_door()

func _blink_panel_light() -> void:
	if not panel_light:
		return
	
	var tween := create_tween().set_loops()
	tween.tween_property(panel_light, "energy", 2.0, 0.2)
	tween.tween_property(panel_light, "energy", 0.8, 0.2)

func _update_hint(text: String) -> void:
	if hint_label:
		hint_label.text = text
		hint_label.visible = text != ""

func _show_message(text: String) -> void:
	if not hint_label:
		return
	
	var original_color := hint_label.get_theme_color("font_color", "Label")
	hint_label.add_theme_color_override("font_color", Color.RED)
	hint_label.text = text
	hint_label.visible = true
	
	await get_tree().create_timer(2.0).timeout
	
	hint_label.add_theme_color_override("font_color", original_color)
	if player_nearby:
		_update_hint("[Q] Hackear sistema")
	else:
		hint_label.visible = false

# ══════════════════════════════════════════════════════════════════
# DETECCIÓN DE JUGADOR
# ══════════════════════════════════════════════════════════════════

func _on_player_entered(body: Node2D) -> void:
	if not (body.is_in_group("player") or body.name == "kai"):
		return
	
	player_nearby = body
	
	match current_state:
		State.LOCKED:
			_update_hint("[Q] Hackear sistema")
		State.UNLOCKED:
			_update_hint("[Q] Abrir puerta")

func _on_player_exited(body: Node2D) -> void:
	if not (body.is_in_group("player") or body.name == "kai"):
		return
	
	player_nearby = null
	_update_hint("")
	
	if is_hacking:
		_cancel_hack()

# ══════════════════════════════════════════════════════════════════
# API PÚBLICA
# ══════════════════════════════════════════════════════════════════

func activate() -> void:
	"""Activar desde interruptor externo"""
	if current_state == State.LOCKED:
		has_been_hacked = true
		current_state = State.UNLOCKED
		_open_door()

func unlock() -> void:
	"""Desbloquear sin abrir"""
	if current_state == State.LOCKED:
		has_been_hacked = true
		current_state = State.UNLOCKED
		_update_visuals()

func is_open() -> bool:
	return current_state == State.OPEN

func is_unlocked() -> bool:
	return has_been_hacked or current_state in [State.UNLOCKED, State.OPEN]
