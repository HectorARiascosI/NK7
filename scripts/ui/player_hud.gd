extends CanvasLayer
class_name PlayerHUD

## ════════════════════════════════════════════════════════════════
## HUD DEL JUGADOR — NK-7  (UIv2 pixel art bars)
## Textura por barra: [icono 96px | fill 192px] = 288px @ 3x
## ════════════════════════════════════════════════════════════════

# ── Nodos barras ──────────────────────────────────────────────────
@onready var _health_clip : Control     = $Root/BarsPanel/RowHealth/BarClip_Health
@onready var _energy_clip : Control     = $Root/BarsPanel/RowEnergy/BarClip_Energy
@onready var _tool_clip   : Control     = $Root/BarsPanel/RowTool/BarClip_Tool
@onready var _health_fill : TextureRect = $Root/BarsPanel/RowHealth/BarClip_Health/BarFill_Health
@onready var _energy_fill : TextureRect = $Root/BarsPanel/RowEnergy/BarClip_Energy/BarFill_Energy
@onready var _tool_fill   : TextureRect = $Root/BarsPanel/RowTool/BarClip_Tool/BarFill_Tool

# ── Nodos coleccionables ──────────────────────────────────────────
@onready var _label_coins : Label = $Root/CollectablesPanel/LabelCoins
@onready var _label_cubes : Label = $Root/CollectablesPanel/LabelCubes

# ── Timer / Score ─────────────────────────────────────────────────
@onready var _timer_panel : Control = $Root/TimerPanel
@onready var _timer_label : Label   = $Root/TimerPanel/LabelTimer
@onready var _score_label : Label   = $Root/LabelScore

# ── Constantes ────────────────────────────────────────────────────
## Zona de barra fill por textura (ancho total 201px - icono)
const BAR_MAX_HP   : float = 162.0   ## 201 - 39 (icono cuadrado health)
const BAR_MAX_NRG  : float = 154.0   ## 201 - 47 (icono energy)
const BAR_MAX_TOOL : float = 154.0   ## 201 - 47 (icono stamina)
const LOW_HP_THRESHOLD   : float = 0.25
const LOW_NRG_THRESHOLD  : float = 0.20
const LOW_TOOL_THRESHOLD : float = 0.20

# ── Estado ────────────────────────────────────────────────────────
var player         : CharacterBody2D = null
var _timer_running : bool  = false
var _timer_seconds : float = 0.0
var _blink_timer   : float = 0.0

# ══════════════════════════════════════════════════════════════════

func _ready() -> void:
	await get_tree().process_frame
	_find_player()

func _process(delta: float) -> void:
	if not player or not is_instance_valid(player):
		_find_player()
		return
	_update_bars(delta)
	_update_collectables()
	_update_timer(delta)
	_update_score()

# ══════════════════════════════════════════════════════════════════
# BARRAS
# ══════════════════════════════════════════════════════════════════

func _update_bars(delta: float) -> void:
	var hp  : float = player.get_health_percent()
	var nrg : float = player.get_energy_percent()
	var tl  : float = player.get_tool_durability_percent()

	# Clip width = porcentaje × ancho máximo de la zona de barra
	_health_clip.size.x = hp  * BAR_MAX_HP
	_energy_clip.size.x = nrg * BAR_MAX_NRG
	_tool_clip.size.x   = tl  * BAR_MAX_TOOL

	# Salud baja (≤25%): parpadeo cálido
	if hp <= LOW_HP_THRESHOLD:
		_blink_timer += delta * 8.0
		var t : float = 0.5 + 0.5 * sin(_blink_timer)
		_health_fill.modulate = Color(1.0, 0.2 + t * 0.3, 0.1 + t * 0.15)
	else:
		_blink_timer = 0.0
		_health_fill.modulate = Color.WHITE

	# Energía baja (≤20%): tinte azul oscuro
	_energy_fill.modulate = Color(0.4, 0.4, 0.9) if nrg <= LOW_NRG_THRESHOLD else Color.WHITE

	# Stamina baja (≤20%): tinte marrón
	_tool_fill.modulate = Color(0.7, 0.5, 0.2) if tl <= LOW_TOOL_THRESHOLD else Color.WHITE

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
	if not _health_fill:
		return
	var tw := create_tween()
	tw.tween_property(_health_fill, "modulate", Color(2.5, 2.5, 2.5), 0.05)
	tw.tween_property(_health_fill, "modulate", Color.WHITE, 0.3)
