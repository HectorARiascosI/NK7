extends CanvasLayer
class_name PlayerHUD

## ════════════════════════════════════════════════════════════════
## HUD DEL JUGADOR — NK-7
## Barras de salud, energía y herramienta con assets pixel art.
## Contadores de monedas y cubos. Timer y Score.
## ════════════════════════════════════════════════════════════════

# ── Nodos de barras ───────────────────────────────────────────────
@onready var _health_clip : Control      = $Root/BarsPanel/RowHealth/BarClip_Health
@onready var _energy_clip : Control      = $Root/BarsPanel/RowEnergy/BarClip_Energy
@onready var _tool_clip   : Control      = $Root/BarsPanel/RowTool/BarClip_Tool
@onready var _health_fill : TextureRect  = $Root/BarsPanel/RowHealth/BarClip_Health/BarFill_Health
@onready var _energy_fill : TextureRect  = $Root/BarsPanel/RowEnergy/BarClip_Energy/BarFill_Energy
# ── Nodos de contadores ───────────────────────────────────────────
@onready var _label_coins : Label = $Root/CollectablesPanel/LabelCoins
@onready var _label_cubes : Label = $Root/CollectablesPanel/LabelCubes

# ── Timer y Score ─────────────────────────────────────────────────
@onready var _timer_panel : Control = $Root/TimerPanel
@onready var _timer_label : Label   = $Root/TimerPanel/LabelTimer
@onready var _score_label : Label   = $Root/LabelScore

# ── Estado ────────────────────────────────────────────────────────
var player         : CharacterBody2D = null
var _timer_running : bool  = false
var _timer_seconds : float = 0.0
var _blink_timer   : float = 0.0

## Ancho máximo del fill en píxeles — 64px original × 3 escala = 192px
const BAR_MAX_W         : float = 192.0
const LOW_HP_THRESHOLD  : float = 0.25   ## parpadeo rojo al 25% de salud
const LOW_NRG_THRESHOLD : float = 0.20   ## tinte azul al 20% de energía

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

	# Recortar el clip según el porcentaje actual
	_health_clip.size.x = hp  * BAR_MAX_W
	_energy_clip.size.x = nrg * BAR_MAX_W
	_tool_clip.size.x   = tl  * BAR_MAX_W

	# Parpadeo de salud baja (≤ 25%)
	if hp <= LOW_HP_THRESHOLD:
		_blink_timer += delta * 7.0
		var t : float = 0.55 + 0.45 * sin(_blink_timer)
		_health_fill.modulate = Color(1.0, t * 0.4 + 0.2, t * 0.2 + 0.1)
	else:
		_blink_timer = 0.0
		_health_fill.modulate = Color.WHITE

	# Tinte de energía baja (≤ 20%)
	_energy_fill.modulate = Color(0.55, 0.55, 1.0) if nrg <= LOW_NRG_THRESHOLD else Color.WHITE

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

## Flash blanco en la barra de salud al recibir daño
func flash_damage() -> void:
	if not _health_fill:
		return
	var tween := create_tween()
	tween.tween_property(_health_fill, "modulate", Color(2.5, 2.5, 2.5), 0.04)
	tween.tween_property(_health_fill, "modulate", Color.WHITE, 0.25)
