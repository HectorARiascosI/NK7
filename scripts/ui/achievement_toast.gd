extends CanvasLayer

## ════════════════════════════════════════════════════════════════
## ACHIEVEMENT TOAST — NK-7
## ════════════════════════════════════════════════════════════════
## Notificación visual cuando se desbloquea un logro.
## Se muestra en la esquina superior derecha durante 3 segundos.
## ════════════════════════════════════════════════════════════════

const SHOW_DURATION := 3.0
const SLIDE_DURATION := 0.3

var _queue : Array[String] = []
var _showing : bool = false

var _panel : Control
var _icon_lbl : Label
var _name_lbl : Label
var _desc_lbl : Label

# ══════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ══════════════════════════════════════════════════════════════════

func _ready() -> void:
	layer = 100
	_build_panel()
	
	# Conectar al sistema de logros
	if has_node("/root/AchievementManager"):
		AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)

func _build_panel() -> void:
	_panel = Control.new()
	_panel.size = Vector2(320, 64)
	_panel.position = Vector2(1280 - 330, -70)  # Fuera de pantalla arriba
	add_child(_panel)
	
	# Fondo
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.10, 0.15, 0.95)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.add_child(bg)
	
	# Borde dorado
	for edge in [
		[Vector2(0, 0), Vector2(320, 2)],
		[Vector2(0, 62), Vector2(320, 2)],
		[Vector2(0, 0), Vector2(2, 64)],
		[Vector2(318, 0), Vector2(2, 64)],
	]:
		var b := ColorRect.new()
		b.color = Color(1.0, 0.80, 0.20, 1.0)
		b.position = edge[0]
		b.size = edge[1]
		_panel.add_child(b)
	
	# Etiqueta "LOGRO"
	var tag := Label.new()
	tag.text = "✦ LOGRO DESBLOQUEADO"
	tag.position = Vector2(8, 6)
	tag.size = Vector2(304, 16)
	tag.add_theme_font_size_override("font_size", 9)
	tag.add_theme_color_override("font_color", Color(1.0, 0.80, 0.20))
	_panel.add_child(tag)
	
	# Icono
	_icon_lbl = Label.new()
	_icon_lbl.text = "🏆"
	_icon_lbl.position = Vector2(8, 22)
	_icon_lbl.size = Vector2(32, 36)
	_icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_icon_lbl.add_theme_font_size_override("font_size", 22)
	_panel.add_child(_icon_lbl)
	
	# Nombre del logro
	_name_lbl = Label.new()
	_name_lbl.text = ""
	_name_lbl.position = Vector2(46, 22)
	_name_lbl.size = Vector2(268, 20)
	_name_lbl.add_theme_font_size_override("font_size", 13)
	_name_lbl.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
	_panel.add_child(_name_lbl)
	
	# Descripción
	_desc_lbl = Label.new()
	_desc_lbl.text = ""
	_desc_lbl.position = Vector2(46, 42)
	_desc_lbl.size = Vector2(268, 16)
	_desc_lbl.add_theme_font_size_override("font_size", 10)
	_desc_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.70))
	_panel.add_child(_desc_lbl)

# ══════════════════════════════════════════════════════════════════
# LÓGICA
# ══════════════════════════════════════════════════════════════════

func _on_achievement_unlocked(achievement_id: String) -> void:
	_queue.append(achievement_id)
	if not _showing:
		_show_next()

func _show_next() -> void:
	if _queue.is_empty():
		_showing = false
		return
	
	_showing = true
	var id : String = _queue.pop_front()
	
	if not AchievementManager.ACHIEVEMENTS.has(id):
		_show_next()
		return
	
	var a : Dictionary = AchievementManager.ACHIEVEMENTS[id]
	_icon_lbl.text = a.get("icon", "🏆")
	_name_lbl.text = a["name"]
	_desc_lbl.text = a["desc"]
	
	# Slide in desde arriba
	_panel.position.x = 1280 - 330
	_panel.position.y = -70
	
	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(_panel, "position:y", 10.0, SLIDE_DURATION)
	await tw.finished
	
	# Esperar
	await get_tree().create_timer(SHOW_DURATION).timeout
	
	# Slide out
	var tw2 := create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tw2.tween_property(_panel, "position:y", -70.0, SLIDE_DURATION)
	await tw2.finished
	
	# Siguiente en cola
	_show_next()
