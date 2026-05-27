extends CanvasLayer
class_name PlayerHUD

## â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
## HUD DEL JUGADOR â€” NK-7
## â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

# â”€â”€ Nodos â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
@onready var _heart_display : HeartDisplay = $Root/HeartDisplay
@onready var _stamina_clip  : Control      = $Root/RowStamina/BarClip_Stamina
@onready var _stamina_fill  : TextureRect  = $Root/RowStamina/BarClip_Stamina/BarFill_Stamina
@onready var _label_coins   : Label        = $Root/CollectablesPanel/LabelCoins
@onready var _label_cubes   : Label        = $Root/CollectablesPanel/LabelCubes
@onready var _timer_panel   : Control      = $Root/TimerPanel
@onready var _timer_label   : Label        = $Root/TimerPanel/LabelTimer
@onready var _score_label   : Label        = $Root/LabelScore

# â”€â”€ Constantes â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
const STAMINA_OFFSET_LEFT   : float = 30.0
const BAR_MAX_STAMINA       : float = 262.0
const LOW_STAMINA_THRESHOLD : float = 0.20

# â”€â”€ Estado â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
var player         : CharacterBody2D = null
var _timer_running : bool  = false
var _timer_seconds : float = 0.0

# â”€â”€ Combo HUD (creado dinÃ¡micamente) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
var _combo_label   : Label   = null
var _combo_canvas  : CanvasLayer = null
var _combo_tween   : Tween   = null
var _combo_visible : bool    = false

# â”€â”€ Dash indicator â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
var _dash_label    : Label   = null

# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

func _ready() -> void:
	await get_tree().process_frame
	_find_player()
	_setup_combo_hud()
	_setup_dash_indicator()
	# Conectar seÃ±ales del CombatManager
	var cm : Node = get_node_or_null("/root/CombatManager")
	if cm:
		cm.combo_changed.connect(_on_combo_changed)
		cm.combo_broken.connect(_on_combo_broken)

func _process(delta: float) -> void:
	if not player or not is_instance_valid(player):
		_find_player()
		return
	_update_bars()
	_update_collectables()
	_update_timer(delta)
	_update_score()
	_update_dash_indicator()

# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# BARRAS
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

func _update_bars() -> void:
	if _heart_display:
		var current_hp : int = player.get_health()
		var max_health : int = player.get_max_health()
		_heart_display.update_hearts(current_hp, max_health)

	var stam : float = player.get_tool_durability_percent()
	_stamina_clip.offset_right = 30.0 + stam * 262.0
	_stamina_fill.modulate = Color(1.0, 0.5, 0.1) if stam <= LOW_STAMINA_THRESHOLD else Color.WHITE

# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# COLECCIONABLES
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

func _update_collectables() -> void:
	_label_coins.text = "x %d" % player.get_coins_count()
	_label_cubes.text = "x %d" % player.get_cubes_count()

# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# TIMER
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

func _update_timer(delta: float) -> void:
	if not _timer_running:
		return
	_timer_seconds += delta
	var m := int(_timer_seconds / 60)
	var s := int(_timer_seconds) % 60
	_timer_label.text = "%02d:%02d" % [m, s]

# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# SCORE
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

func _update_score() -> void:
	_score_label.text = "SCORE  %06d" % GameManager.get_score()

# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# COMBO HUD
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

func _setup_combo_hud() -> void:
	_combo_canvas = CanvasLayer.new()
	_combo_canvas.layer = 15
	add_child(_combo_canvas)

	_combo_label = Label.new()
	_combo_label.add_theme_font_size_override("font_size", 28)
	_combo_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
	_combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_combo_label.modulate.a = 0.0
	_combo_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_combo_label.position = Vector2(0, -120)
	_combo_canvas.add_child(_combo_label)

func _on_combo_changed(count: int, multiplier: float) -> void:
	if not _combo_label: return
	_combo_visible = true
	if count == 1:
		_combo_label.text = "HIT!"
		_combo_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
	elif count < 5:
		_combo_label.text = "%d COMBO  x%.1f" % [count, multiplier]
		_combo_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.1))
	elif count < 10:
		_combo_label.text = "%d COMBO  x%.1f  ðŸ”¥" % [count, multiplier]
		_combo_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.1))
	else:
		_combo_label.text = "%d COMBO  x%.1f  âš¡ IMPARABLE" % [count, multiplier]
		_combo_label.add_theme_color_override("font_color", Color(1.0, 0.1, 0.1))

	if _combo_tween: _combo_tween.kill()
	_combo_tween = create_tween()
	_combo_tween.tween_property(_combo_label, "modulate:a", 1.0, 0.1)
	_combo_tween.tween_property(_combo_label, "scale", Vector2(1.15, 1.15), 0.06)
	_combo_tween.tween_property(_combo_label, "scale", Vector2(1.0, 1.0), 0.1)

func _on_combo_broken() -> void:
	if not _combo_label or not _combo_visible: return
	_combo_visible = false
	if _combo_tween: _combo_tween.kill()
	_combo_tween = create_tween()
	_combo_tween.tween_property(_combo_label, "modulate:a", 0.0, 0.4)

# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# INDICADOR DE DASH
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

func _setup_dash_indicator() -> void:
	_dash_label = Label.new()
	_dash_label.text = "â—ˆ DASH"
	_dash_label.add_theme_font_size_override("font_size", 12)
	_dash_label.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
	_dash_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_dash_label.position = Vector2(12, -60)
	add_child(_dash_label)

func _update_dash_indicator() -> void:
	if not _dash_label or not player: return
	var cd : float = 0.0
	if player.get("_dash_cooldown") != null:
		cd = float(player.get("_dash_cooldown"))
	if cd <= 0.0:
		_dash_label.modulate = Color(0.4, 0.9, 1.0)
		_dash_label.text = "â—ˆ DASH"
	else:
		var max_cd : float = 1.2
		if player.get("DASH_COOLDOWN") != null:
			max_cd = float(player.get("DASH_COOLDOWN"))
		var pct : float = 1.0 - (cd / max_cd)
		_dash_label.modulate = Color(0.3, 0.3, 0.3).lerp(Color(0.4, 0.9, 1.0), pct)
		_dash_label.text = "â—ˆ DASH  %.0f%%" % (pct * 100.0)

# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# BÃšSQUEDA DE JUGADOR
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

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

# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# API PÃšBLICA
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

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
