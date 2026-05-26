extends CanvasLayer
class_name PlayerHUD

## ════════════════════════════════════════════════════════════════
## HUD DEL JUGADOR — NK-7
## ════════════════════════════════════════════════════════════════

# ── Nodos ─────────────────────────────────────────────────────────
@onready var _heart_display : HeartDisplay = $Root/HeartDisplay
@onready var _stamina_clip  : Control      = $Root/RowStamina/BarClip_Stamina
@onready var _stamina_fill  : TextureRect  = $Root/RowStamina/BarClip_Stamina/BarFill_Stamina
@onready var _label_coins   : Label        = $Root/CollectablesPanel/LabelCoins
@onready var _label_cubes   : Label        = $Root/CollectablesPanel/LabelCubes
@onready var _timer_panel   : Control      = $Root/TimerPanel
@onready var _timer_label   : Label        = $Root/TimerPanel/LabelTimer
@onready var _score_label   : Label        = $Root/LabelScore

# ── Constantes ────────────────────────────────────────────────────
## offset_left del BarClip_Stamina = 30, ancho fill = 262px
const STAMINA_OFFSET_LEFT   : float = 30.0
const BAR_MAX_STAMINA       : float = 262.0
const LOW_STAMINA_THRESHOLD : float = 0.20

# ── Estado ────────────────────────────────────────────────────────
var player         : CharacterBody2D = null
var _timer_running : bool  = false
var _timer_seconds : float = 0.0

# ══════════════════════════════════════════════════════════════════

func _ready() -> void:
	await get_tree().process_frame
	_find_player()

func _process(delta: float) -> void:
	if not player or not is_instance_valid(player):
		_find_player()
		return
	_update_bars()
	_update_collectables()
	_update_timer(delta)
	_update_score()

# ══════════════════════════════════════════════════════════════════
# BARRAS
# ══════════════════════════════════════════════════════════════════

func _update_bars() -> void:
	# ── Corazones ─────────────────────────────────────────────────
	if _heart_display:
		var current_hp : int = player.get_health()
		var max_health : int = player.get_max_health()
		_heart_display.update_hearts(current_hp, max_health)

	# ── Stamina ────────────────────────────────────────────────────
	var stam : float = player.get_tool_durability_percent()
	_stamina_clip.offset_right = 30.0 + stam * 262.0
	_stamina_fill.modulate = Color(1.0, 0.5, 0.1) if stam <= LOW_STAMINA_THRESHOLD else Color.WHITE

# ══════════════════════════════════════════════════════════════════
# COLECCIONABLES
# ══════════════════════════════════════════════════════════════════

func _update_collectables() -> void:
	_label_coins.text = "x %d" % player.get_coins_count()
	_label_cubes.text = "x %d" % player.get_cubes_count()

# ══════════════════════════════════════════════════════════════════
# TIMER
# ══════════════════════════════════════════════════════════════════

func _update_timer(delta: float) -> void:
	if not _timer_running:
		return
	_timer_seconds += delta
	var m := int(_timer_seconds / 60)
	var s := int(_timer_seconds) % 60
	_timer_label.text = "%02d:%02d" % [m, s]

# ══════════════════════════════════════════════════════════════════
# SCORE
# ══════════════════════════════════════════════════════════════════

func _update_score() -> void:
	_score_label.text = "SCORE  %06d" % GameManager.get_score()

# ══════════════════════════════════════════════════════════════════
# BÚSQUEDA DE JUGADOR
# ══════════════════════════════════════════════════════════════════

func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		return
	player = _search_node(get_tree().root, "kai")

func _search_node(node: Node, target: String) -> Node:
	if node.name == target:
		return node
	for child in node.get_children():
		var r := _search_node(child, target)
		if r:
			return r
	return null

# ══════════════════════════════════════════════════════════════════
# API PÚBLICA
# ══════════════════════════════════════════════════════════════════

func show_timer() -> void:
	_timer_running = true
	_timer_seconds = 0.0
	_timer_panel.visible = true

func hide_timer() -> void:
	_timer_running = false
	_timer_panel.visible = false

func get_elapsed_time() -> float:
	return _timer_seconds

func flash_damage() -> void:
	if _heart_display:
		_heart_display.flash_damage()
