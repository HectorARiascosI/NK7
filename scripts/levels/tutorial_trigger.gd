extends Area2D
class_name TutorialTrigger

## Zona que dispara un mensaje de tutorial cuando el jugador entra

signal triggered

@export var trigger_id     : String = ""
@export var one_shot       : bool   = true
@export var dialogue_lines : Array[Dictionary] = []

var _fired : bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Usar get_node para acceder al autoload GameState
	if trigger_id != "":
		var gs := get_node_or_null("/root/GameState")
		if gs and gs.is_trigger_done(trigger_id):
			_fired = true

func _on_body_entered(body: Node2D) -> void:
	if _fired and one_shot:
		return
	if not (body.is_in_group("player") or body.name == "kai"):
		return

	_fired = true

	if trigger_id != "":
		var gs := get_node_or_null("/root/GameState")
		if gs:
			gs.mark_trigger_done(trigger_id)

	triggered.emit()

	var db := _find_dialogue_box()
	if db and dialogue_lines.size() > 0:
		var typed : Array[Dictionary] = []
		for l in dialogue_lines:
			typed.append(l as Dictionary)
		db.show_dialogue(typed)

func _find_dialogue_box() -> Node:
	return _search_recursive(get_tree().root, "DialogueBox")

func _search_recursive(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node
	for child in node.get_children():
		var result := _search_recursive(child, target_name)
		if result:
			return result
	return null
