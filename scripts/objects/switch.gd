extends Area2D
class_name Switch

## Interruptor / Palanca / Panel de control NK7
## Al interactuar (tecla E/F cerca), activa/desactiva objetos conectados

signal switched_on
signal switched_off
signal toggled(is_on: bool)

# ── Configuración ─────────────────────────────────────────────
@export_group("Tipo")
@export_enum("Switch", "Lever", "Panel") var switch_type : int = 0
@export var starts_on     : bool = false
@export var one_shot      : bool = false   # solo se puede usar una vez
@export var requires_hack : bool = false   # necesita acción de hackear

@export_group("Targets")
## Nodos a activar/desactivar. Deben tener métodos activate()/deactivate()
@export var targets : Array[NodePath] = []

# ── Nodos ─────────────────────────────────────────────────────
@onready var sprite : AnimatedSprite2D = $Sprite

# ── Estado ────────────────────────────────────────────────────
var _is_on       : bool = false
var _used        : bool = false
var _player_near : bool = false
var _hint_label  : Label = null

# ── Frames del spritesheet (interactables.png) ────────────────
# Fila 1 (y=0):   Interruptores — off, on_dim, on_bright, alarm
# Fila 2 (y=1):   Paneles — off, active, hacking, ok
# Fila 3 (y=2):   Palancas — left, moving, right

# ════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ════════════════════════════════════════════════════════════════

func _ready() -> void:
	_is_on = starts_on
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_create_hint()
	_update_visual()

func _create_hint() -> void:
	_hint_label = Label.new()
	_hint_label.text = "[E] INTERACTUAR"
	_hint_label.add_theme_font_size_override("font_size", 11)
	_hint_label.add_theme_color_override("font_color", Color(0.91, 0.63, 0.00, 1.0))
	_hint_label.position = Vector2(-50, -40)
	_hint_label.visible = false
	add_child(_hint_label)


# ════════════════════════════════════════════════════════════════
# PROCESO
# ════════════════════════════════════════════════════════════════

func _process(_delta: float) -> void:
	if not _player_near:
		return

	var action := "hack" if requires_hack else "communicate"
	if Input.is_action_just_pressed(action) or Input.is_action_just_pressed("use_tool"):
		_interact()


# ════════════════════════════════════════════════════════════════
# INTERACCIÓN
# ════════════════════════════════════════════════════════════════

func _interact() -> void:
	if one_shot and _used:
		return

	_is_on = not _is_on
	_used  = true

	_update_visual()
	_trigger_targets()

	if _is_on:
		switched_on.emit()
	else:
		switched_off.emit()
	toggled.emit(_is_on)

func _trigger_targets() -> void:
	for path in targets:
		var node := get_node_or_null(path)
		if node == null:
			continue
		if _is_on:
			if node.has_method("activate"):
				node.activate()
		else:
			if node.has_method("deactivate"):
				node.deactivate()

func _update_visual() -> void:
	if not is_instance_valid(sprite):
		return
	match switch_type:
		0:  # Interruptor
			sprite.play("on" if _is_on else "off")
		1:  # Palanca
			sprite.play("right" if _is_on else "left")
		2:  # Panel
			sprite.play("active" if _is_on else "off")


# ════════════════════════════════════════════════════════════════
# DETECCIÓN DE JUGADOR
# ════════════════════════════════════════════════════════════════

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "kai":
		_player_near = true
		if _hint_label:
			_hint_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "kai":
		_player_near = false
		if _hint_label:
			_hint_label.visible = false


# ════════════════════════════════════════════════════════════════
# API PÚBLICA
# ════════════════════════════════════════════════════════════════

func force_on() -> void:
	_is_on = true
	_update_visual()
	_trigger_targets()

func force_off() -> void:
	_is_on = false
	_update_visual()
	_trigger_targets()

func is_switched_on() -> bool:
	return _is_on
