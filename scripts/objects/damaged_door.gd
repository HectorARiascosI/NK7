extends StaticBody2D
class_name DamagedDoor

## ════════════════════════════════════════════════════════════════
## PUERTA DAÑADA NK-7 (FILA SUPERIOR)
## ════════════════════════════════════════════════════════════════
## Puerta que requiere reparación progresiva con herramienta [F]
## 
## SECUENCIA DE FRAMES (Fila superior del spritesheet):
##   Frame 0 (X=0):    Cerrada, luz roja - LOCKED_DAMAGED
##   Frame 1 (X=192):  Reparando, luz amarilla - REPAIRING  
##   Frame 2 (X=384):  Desbloqueando, chispas - UNLOCKING
##   Frame 3 (X=576):  Abriendo - OPENING
##   Frame 4 (X=768):  Abierta, luz verde - OPEN
##
## INTERACCIÓN: Mantener [F] para reparar → Automáticamente abre
## ════════════════════════════════════════════════════════════════

signal repair_started
signal repair_progress(current: float, total: float)
signal repair_completed
signal door_opened
signal door_closed

# ══════════════════════════════════════════════════════════════════
# CONFIGURACIÓN
# ══════════════════════════════════════════════════════════════════

@export_group("Reparación")
@export var repair_steps : int = 2  ## Pasos de reparación (1-3)
@export var repair_time_per_step : float = 2.0  ## Segundos por paso
@export var tool_cost_per_step : int = 10  ## Durabilidad consumida

@export_group("Identificación")
@export var unique_id : String = ""  ## ID único para persistencia

@export_group("Comportamiento")
@export var auto_close : bool = false
@export var auto_close_delay : float = 4.0
@export var opening_duration : float = 0.8

# ══════════════════════════════════════════════════════════════════
# NODOS
# ══════════════════════════════════════════════════════════════════

@onready var sprite : AnimatedSprite2D = $Sprite
@onready var collision : CollisionShape2D = $Collision
@onready var interaction_area : Area2D = $InteractionArea
@onready var hint_label : Label = $HintLabel
@onready var progress_bar : ProgressBar = $ProgressBar
@onready var particles : GPUParticles2D = $RepairParticles
@onready var status_light : PointLight2D = $StatusLight

# ══════════════════════════════════════════════════════════════════
# ESTADO
# ══════════════════════════════════════════════════════════════════

enum State { LOCKED_DAMAGED, REPAIRING, UNLOCKING, OPENING, OPEN, CLOSING }

var current_state : State = State.LOCKED_DAMAGED
var repair_steps_completed : int = 0
var is_repairing : bool = false
var repair_timer : float = 0.0
var player_nearby : CharacterBody2D = null

# ══════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ══════════════════════════════════════════════════════════════════

func _ready() -> void:
	_setup_nodes()
	_connect_signals()
	
	# Generar ID único si no tiene
	if unique_id.is_empty():
		unique_id = "damaged_door_%s_%d" % [name, get_instance_id()]
	
	# Verificar si ya fue abierta
	if LevelStateManager.is_door_opened(unique_id):
		current_state = State.OPEN
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
		status_light.energy = 1.0

func _connect_signals() -> void:
	if interaction_area:
		interaction_area.body_entered.connect(_on_player_entered)
		interaction_area.body_exited.connect(_on_player_exited)

# ══════════════════════════════════════════════════════════════════
# PROCESO
# ══════════════════════════════════════════════════════════════════

func _process(delta: float) -> void:
	_handle_input()
	_update_repair_progress(delta)

func _handle_input() -> void:
	if not player_nearby or current_state != State.LOCKED_DAMAGED:
		return
	
	# Iniciar reparación con [F]
	if Input.is_action_pressed("use_tool") and not is_repairing:
		_start_repair()
	
	# Cancelar si suelta [F]
	elif Input.is_action_just_released("use_tool") and is_repairing:
		_cancel_repair()

func _update_repair_progress(delta: float) -> void:
	if not is_repairing:
		return
	
	repair_timer += delta
	var progress := (repair_timer / repair_time_per_step) * 100.0
	
	if progress_bar:
		progress_bar.value = progress
	
	repair_progress.emit(repair_timer, repair_time_per_step)
	
	# Completar paso
	if repair_timer >= repair_time_per_step:
		_complete_repair_step()

# ══════════════════════════════════════════════════════════════════
# SISTEMA DE REPARACIÓN
# ══════════════════════════════════════════════════════════════════

func _start_repair() -> void:
	if not player_nearby:
		return
	
	# Verificar durabilidad de herramienta
	if player_nearby.has_method("use_tool"):
		if not player_nearby.use_tool(tool_cost_per_step):
			_show_message("⚠ Herramienta sin durabilidad")
			return
	
	is_repairing = true
	repair_timer = 0.0
	current_state = State.REPAIRING
	
	# Activar efectos
	if particles:
		particles.emitting = true
	if progress_bar:
		progress_bar.visible = true
		progress_bar.value = 0
	if status_light:
		status_light.color = Color.ORANGE
	
	# Animación de reparación
	if sprite:
		sprite.play("repairing")
	
	# Animación del jugador
	if player_nearby and player_nearby.has_node("AnimatedSprite2D"):
		player_nearby.get_node("AnimatedSprite2D").play("use_tool")
	
	repair_started.emit()
	_update_hint("[F] Reparando... (%d/%d)" % [repair_steps_completed + 1, repair_steps])

func _complete_repair_step() -> void:
	repair_steps_completed += 1
	repair_timer = 0.0
	is_repairing = false
	
	if particles:
		particles.emitting = false
	if progress_bar:
		progress_bar.visible = false
	
	# Verificar si completó todos los pasos
	if repair_steps_completed >= repair_steps:
		_finish_repair()
	else:
		# Volver a estado dañado para siguiente paso
		current_state = State.LOCKED_DAMAGED
		_update_hint("[F] Reparar (%d/%d)" % [repair_steps_completed, repair_steps])
		_update_visuals()

func _cancel_repair() -> void:
	is_repairing = false
	repair_timer = 0.0
	current_state = State.LOCKED_DAMAGED
	
	if particles:
		particles.emitting = false
	if progress_bar:
		progress_bar.visible = false
	
	_update_hint("[F] Reparar (%d/%d)" % [repair_steps_completed, repair_steps])
	_update_visuals()

func _finish_repair() -> void:
	current_state = State.UNLOCKING
	repair_completed.emit()
	
	if sprite:
		sprite.play("unlocking")
	if status_light:
		status_light.color = Color.CYAN
		_blink_light()
	
	_update_hint("Desbloqueando...")
	
	# Esperar animación de desbloqueo
	await get_tree().create_timer(1.0).timeout
	
	# Abrir automáticamente
	_open_door()

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
		status_light.energy = 1.5
	
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
	
	current_state = State.LOCKED_DAMAGED
	repair_steps_completed = 0
	door_closed.emit()
	
	if player_nearby:
		_update_hint("[F] Reparar (0/%d)" % repair_steps)
	
	_update_visuals()

# ══════════════════════════════════════════════════════════════════
# VISUALES
# ══════════════════════════════════════════════════════════════════

func _update_visuals() -> void:
	if not sprite:
		return
	
	match current_state:
		State.LOCKED_DAMAGED:
			sprite.play("locked_damaged")
			if status_light:
				status_light.color = Color.RED
				_blink_light()
		
		State.REPAIRING:
			sprite.play("repairing")
		
		State.UNLOCKING:
			sprite.play("unlocking")
		
		State.OPENING, State.OPEN:
			pass  # Ya manejado en _open_door()
		
		State.CLOSING:
			pass  # Ya manejado en _close_door()

func _blink_light() -> void:
	if not status_light:
		return
	
	var tween := create_tween().set_loops()
	tween.tween_property(status_light, "energy", 1.5, 0.4)
	tween.tween_property(status_light, "energy", 0.5, 0.4)

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
		_update_hint("[F] Reparar (%d/%d)" % [repair_steps_completed, repair_steps])
	else:
		hint_label.visible = false

# ══════════════════════════════════════════════════════════════════
# DETECCIÓN DE JUGADOR
# ══════════════════════════════════════════════════════════════════

func _on_player_entered(body: Node2D) -> void:
	if not (body.is_in_group("player") or body.name == "kai"):
		return
	
	player_nearby = body
	
	if current_state == State.LOCKED_DAMAGED:
		_update_hint("[F] Reparar (%d/%d)" % [repair_steps_completed, repair_steps])

func _on_player_exited(body: Node2D) -> void:
	if not (body.is_in_group("player") or body.name == "kai"):
		return
	
	player_nearby = null
	_update_hint("")
	
	if is_repairing:
		_cancel_repair()

# ══════════════════════════════════════════════════════════════════
# API PÚBLICA
# ══════════════════════════════════════════════════════════════════

func activate() -> void:
	"""Activar desde interruptor externo"""
	if current_state == State.LOCKED_DAMAGED:
		repair_steps_completed = repair_steps
		_finish_repair()

func get_repair_progress() -> float:
	if repair_steps == 0:
		return 1.0
	return float(repair_steps_completed) / float(repair_steps)

func is_open() -> bool:
	return current_state == State.OPEN
