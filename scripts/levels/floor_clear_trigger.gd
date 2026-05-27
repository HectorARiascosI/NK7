extends Node
class_name FloorClearTrigger

## ════════════════════════════════════════════════════════════════
## FLOOR CLEAR TRIGGER — Desactiva un láser al matar todos los
## enemigos de un piso.
## ════════════════════════════════════════════════════════════════
## Uso en el nivel:
##   1. Agrega este nodo como hijo del nivel
##   2. Asigna los enemy_ids de los enemigos de ese piso
##   3. Asigna el laser_path al láser que debe desactivarse
##   4. Al morir todos los enemigos → láser se apaga con efecto
## ════════════════════════════════════════════════════════════════

## IDs únicos de los enemigos que deben morir para desactivar el láser
@export var enemy_ids   : Array[String] = []
## Ruta al nodo del láser a desactivar
@export var laser_path  : NodePath = NodePath("")
## Mensaje opcional que aparece al limpiar el piso
@export var clear_message : String = "Zona despejada"

var _defeated_count : int = 0
var _laser          : Node = null
var _triggered      : bool = false

func _ready() -> void:
	await get_tree().process_frame
	# Buscar el láser
	if laser_path != NodePath(""):
		_laser = get_node_or_null(laser_path)
	if not _laser:
		push_warning("FloorClearTrigger: laser_path no encontrado — %s" % str(laser_path))
		return

	# Conectar señal destroyed de cada enemigo
	_connect_enemies()

func _connect_enemies() -> void:
	# Buscar todos los enemigos del árbol y conectar los que coincidan con enemy_ids
	var all_enemies := get_tree().get_nodes_in_group("enemies")
	for enemy in all_enemies:
		if not is_instance_valid(enemy): continue
		var eid : String = ""
		if enemy.has_method("get") and "unique_id" in enemy:
			eid = enemy.unique_id
		if eid in enemy_ids:
			if enemy.has_signal("destroyed"):
				enemy.destroyed.connect(_on_enemy_destroyed)

func _on_enemy_destroyed() -> void:
	if _triggered: return
	_defeated_count += 1
	if _defeated_count >= enemy_ids.size():
		_clear_floor()

func _clear_floor() -> void:
	_triggered = true
	if not _laser or not is_instance_valid(_laser): return
	# Desactivar directamente — el láser maneja su propio estado visual
	_deactivate_laser()

func _deactivate_laser() -> void:
	if _laser and is_instance_valid(_laser) and _laser.has_method("deactivate"):
		_laser.deactivate()
	if clear_message != "":
		_show_clear_message()

func _show_clear_message() -> void:
	# Crear label flotante en pantalla
	var canvas := CanvasLayer.new()
	canvas.layer = 20
	get_tree().root.add_child(canvas)

	var label := Label.new()
	label.text = "✓ " + clear_message
	label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	label.add_theme_font_size_override("font_size", 18)
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	canvas.add_child(label)

	# Animación: aparece, sube y desaparece
	label.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(label, "modulate:a", 1.0, 0.3)
	tw.tween_property(label, "position:y", label.position.y - 40, 1.5)
	await tw.finished
	var tw2 := create_tween()
	tw2.tween_property(label, "modulate:a", 0.0, 0.4)
	await tw2.finished
	canvas.queue_free()
