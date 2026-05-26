extends HBoxContainer
class_name HeartDisplay

## ════════════════════════════════════════════════════════════════
## DISPLAY DE CORAZONES — 3 corazones, vida visual
## ════════════════════════════════════════════════════════════════
## 3 corazones = 100 HP total
## Corazón 1: 67-100 HP  (lleno)
## Corazón 2: 34-66 HP   (lleno)
## Corazón 3: 1-33 HP    (lleno)
## ════════════════════════════════════════════════════════════════

# ── Configuración ─────────────────────────────────────────────────
const MAX_HEARTS  : int   = 3
const HEART_SIZE  : float = 56.0   ## tamaño en pantalla (px)

# ── Texturas ──────────────────────────────────────────────────────
var tex_full       : Texture2D = null
var tex_empty      : Texture2D = null
var tex_damage     : Texture2D = null

# ── Nodos ─────────────────────────────────────────────────────────
var hearts : Array[TextureRect] = []

# ── Estado ────────────────────────────────────────────────────────
var _current_hp  : int   = 100
var _max_hp      : int   = 100
var _anim_timer  : float = 0.0
var _anim_idx    : int   = -1

# ══════════════════════════════════════════════════════════════════

func _ready() -> void:
	# Separación entre corazones
	add_theme_constant_override("separation", 6)
	_load_textures()
	_build_hearts()
	_refresh(100, 100)

func _process(delta: float) -> void:
	if _anim_timer > 0.0:
		_anim_timer -= delta
		if _anim_timer <= 0.0:
			_end_anim()

# ══════════════════════════════════════════════════════════════════

func _load_textures() -> void:
	var p : String = "res://assets/ui/hearts/"
	tex_full   = load(p + "heart_full_0.png")   as Texture2D
	tex_empty  = load(p + "heart_empty_0.png")  as Texture2D
	tex_damage = load(p + "heart_damage_0.png") as Texture2D

func _build_hearts() -> void:
	for i in range(MAX_HEARTS):
		var h : TextureRect = TextureRect.new()
		h.name             = "Heart%d" % i
		h.texture          = tex_full
		h.expand_mode      = TextureRect.EXPAND_IGNORE_SIZE
		h.stretch_mode     = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		h.custom_minimum_size = Vector2(HEART_SIZE, HEART_SIZE)
		h.modulate         = Color.WHITE
		add_child(h)
		hearts.append(h)

# ══════════════════════════════════════════════════════════════════
# API PÚBLICA
# ══════════════════════════════════════════════════════════════════

func update_hearts(hp: int, max_health: int) -> void:
	var old_hp : int = _current_hp
	_current_hp = hp
	_max_hp     = max_health

	# Detectar corazón que se perdió para animarlo
	if hp < old_hp:
		var lost_heart : int = _heart_index_for_hp(old_hp) 
		_play_damage_anim(lost_heart)

	_refresh(hp, max_health)

func flash_damage() -> void:
	for h in hearts:
		var tw : Tween = create_tween()
		tw.tween_property(h, "modulate", Color(2.0, 0.3, 0.3), 0.05)
		tw.tween_property(h, "modulate", Color.WHITE, 0.2)

# ══════════════════════════════════════════════════════════════════
# INTERNO
# ══════════════════════════════════════════════════════════════════

## Devuelve cuántos corazones llenos hay según el HP
func _full_hearts_count(hp: int, max_health: int) -> int:
	if hp <= 0:
		return 0
	# Dividir la vida en 3 partes iguales
	var per_heart : float = float(max_health) / float(MAX_HEARTS)
	return int(ceil(float(hp) / per_heart))

## Devuelve el índice del corazón que corresponde a ese HP
func _heart_index_for_hp(hp: int) -> int:
	var count : int = _full_hearts_count(hp, _max_hp)
	return clamp(count - 1, 0, MAX_HEARTS - 1)

func _refresh(hp: int, max_health: int) -> void:
	if hearts.size() == 0:
		return
	var full : int = _full_hearts_count(hp, max_health)
	for i in range(hearts.size()):
		if i < full:
			if i != _anim_idx:   # no sobreescribir el que está animando
				hearts[i].texture  = tex_full
				hearts[i].modulate = Color.WHITE
		else:
			if i != _anim_idx:
				hearts[i].texture  = tex_empty
				hearts[i].modulate = Color(0.5, 0.5, 0.5, 0.8)

func _play_damage_anim(idx: int) -> void:
	if idx < 0 or idx >= hearts.size():
		return
	_anim_idx   = idx
	_anim_timer = 0.4
	hearts[idx].texture  = tex_damage
	hearts[idx].modulate = Color.WHITE
	# Bounce scale
	var tw : Tween = create_tween()
	tw.tween_property(hearts[idx], "scale", Vector2(1.3, 1.3), 0.08)
	tw.tween_property(hearts[idx], "scale", Vector2(1.0, 1.0), 0.12)

func _end_anim() -> void:
	if _anim_idx < 0 or _anim_idx >= hearts.size():
		return
	var full : int = _full_hearts_count(_current_hp, _max_hp)
	if _anim_idx < full:
		hearts[_anim_idx].texture  = tex_full
		hearts[_anim_idx].modulate = Color.WHITE
	else:
		hearts[_anim_idx].texture  = tex_empty
		hearts[_anim_idx].modulate = Color(0.5, 0.5, 0.5, 0.8)
	_anim_idx = -1
