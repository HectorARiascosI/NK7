extends Control

## Pantalla de créditos NK7 - Diseño Pixel Art Sci-Fi

# ══════════════════════════════════════════════════════════════════
# NODOS
# ══════════════════════════════════════════════════════════════════

@onready var scroll_container := $Layout/ScrollContainer
@onready var content          := $Layout/ScrollContainer/Content

# ══════════════════════════════════════════════════════════════════
# VARIABLES
# ══════════════════════════════════════════════════════════════════

var auto_scroll := true
var scroll_speed := 40.0

# ══════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ══════════════════════════════════════════════════════════════════

func _ready() -> void:
	# Aplicar tema NK7
	if has_node("/root/NK7Theme"):
		theme = get_node("/root/NK7Theme").get_nk7_theme()
	
	# Fade in
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	
	# Iniciar scroll desde arriba
	scroll_container.scroll_vertical = 0


# ══════════════════════════════════════════════════════════════════
# PROCESO - AUTO SCROLL
# ══════════════════════════════════════════════════════════════════

func _process(delta: float) -> void:
	if auto_scroll:
		scroll_container.scroll_vertical += int(scroll_speed * delta)
		
		# Cuando llega al final, pausar
		var max_scroll : float = scroll_container.get_v_scroll_bar().max_value
		if float(scroll_container.scroll_vertical) >= max_scroll - 10.0:
			auto_scroll = false


# ══════════════════════════════════════════════════════════════════
# INPUT
# ══════════════════════════════════════════════════════════════════

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_button_pressed()
	
	# Pausar/reanudar scroll con cualquier tecla
	if event is InputEventKey and event.pressed and not event.is_action("ui_cancel"):
		auto_scroll = not auto_scroll


# ══════════════════════════════════════════════════════════════════
# CALLBACKS
# ══════════════════════════════════════════════════════════════════

func _on_back_button_pressed() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
