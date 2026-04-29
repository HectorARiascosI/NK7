extends Node

## GameState — Estado de sesión (no persistente entre reinicios)
## Guarda qué triggers de tutorial ya se dispararon en esta sesión

var _done_triggers : Dictionary = {}

func is_trigger_done(id: String) -> bool:
	return _done_triggers.has(id)

func mark_trigger_done(id: String) -> void:
	_done_triggers[id] = true

func reset_triggers() -> void:
	_done_triggers.clear()
