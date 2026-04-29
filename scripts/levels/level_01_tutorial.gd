extends Node

## Tutorial del Nivel 01 — "Acto I: El Colapso"
## Sector B — Complejo Energético NK7
##
## Narrativa:
## KAI despierta en el sector B tras una explosión.
## El sistema de seguridad se ha activado automáticamente.
## Debe escapar antes de que el reactor se sobrecargue.
## En el camino encuentra a RENA (voz por radio) que lo guía.

# ── Referencia al DialogueBox ─────────────────────────────────
var _db : Node = null

# ── Diálogos del tutorial ─────────────────────────────────────

const INTRO_LINES : Array = [
	{
		"speaker": "SISTEMA NK7",
		"type":    "system",
		"text":    "[color=#E8A000]⚠ ALERTA:[/color] Sobrecarga detectada en Reactor B-7.\nProtocolos de emergencia activados."
	},
	{
		"speaker": "KAI",
		"type":    "kai",
		"text":    "¿Qué...? ¿Dónde estoy...?\n[color=#888]Cabeza... todo da vueltas.[/color]"
	},
	{
		"speaker": "RENA [Radio]",
		"type":    "rena",
		"text":    "¡KAI! ¡Gracias a dios! Soy RENA, estoy en el sector C.\nEl complejo está colapsando. Tienes que salir AHORA."
	},
	{
		"speaker": "KAI",
		"type":    "kai",
		"text":    "Rena... ¿cómo llegué aquí? El último que recuerdo es el turno de noche..."
	},
	{
		"speaker": "RENA [Radio]",
		"type":    "rena",
		"text":    "No hay tiempo para eso. Muévete hacia la derecha.\nUsa [color=#E8A000]A/D[/color] para caminar, [color=#E8A000]ESPACIO[/color] para saltar."
	}
]

const MOVE_HINT : Array = [
	{
		"speaker": "RENA [Radio]",
		"type":    "rena",
		"text":    "Bien. Las escaleras te permiten subir y bajar entre niveles.\nAcércate y presiona [color=#E8A000]W[/color] para subir, [color=#E8A000]S[/color] para bajar."
	}
]

const LADDER_HINT : Array = [
	{
		"speaker": "RENA [Radio]",
		"type":    "rena",
		"text":    "¡Perfecto! Puedes correr manteniendo [color=#E8A000]SHIFT[/color].\nEso te ayudará a cruzar zonas peligrosas más rápido."
	}
]

const LASER_HINT : Array = [
	{
		"speaker": "RENA [Radio]",
		"type":    "rena",
		"text":    "¡Cuidado! Esos son láseres de seguridad.\nEl sistema los activó automáticamente. [color=#CC2200]Un toque y estás muerto.[/color]"
	},
	{
		"speaker": "KAI",
		"type":    "kai",
		"text":    "Genial. ¿Y cómo los apago?"
	},
	{
		"speaker": "RENA [Radio]",
		"type":    "rena",
		"text":    "Busca un interruptor o panel de control cerca.\nPresiona [color=#E8A000]E[/color] para interactuar con ellos."
	}
]

const SWITCH_HINT : Array = [
	{
		"speaker": "TUTORIAL",
		"type":    "hint",
		"text":    "Acércate al interruptor y presiona [color=#E8A000]E[/color] para activarlo.\nEsto desactivará los láseres del área."
	}
]

const DOOR_HINT : Array = [
	{
		"speaker": "RENA [Radio]",
		"type":    "rena",
		"text":    "Esa puerta está bloqueada por el sistema de seguridad.\nNecesitas hackear el panel de control.\nPresiona [color=#E8A000]Q[/color] frente al panel."
	}
]

const ELECTRIC_HINT : Array = [
	{
		"speaker": "RENA [Radio]",
		"type":    "rena",
		"text":    "¡Zona electrificada! El suelo está cargado.\nObserva el patrón: [color=#E8A000]se apaga brevemente[/color] entre descargas.\nCruza en ese momento."
	}
]

const CROUCH_HINT : Array = [
	{
		"speaker": "TUTORIAL",
		"type":    "hint",
		"text":    "Mantén [color=#E8A000]CTRL[/color] para agacharte.\nPuedes moverte agachado por espacios estrechos."
	}
]

const CHECKPOINT_MSG : Array = [
	{
		"speaker": "SISTEMA NK7",
		"type":    "system",
		"text":    "[color=#00CC44]✓ Punto de control guardado.[/color]\nProgreso registrado en el sistema."
	}
]

const SECTOR_END : Array = [
	{
		"speaker": "RENA [Radio]",
		"type":    "rena",
		"text":    "¡Lo lograste! Estás en la salida del Sector B.\nYo estoy al otro lado. ¡Date prisa, el reactor tiene menos de 10 minutos!"
	},
	{
		"speaker": "KAI",
		"type":    "kai",
		"text":    "Voy. Pero cuando salgamos de aquí...\nme vas a explicar qué diablos pasó realmente."
	}
]

# ════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ════════════════════════════════════════════════════════════════

func _ready() -> void:
	# Esperar un frame para que todo esté listo
	await get_tree().process_frame
	_db = _find_dialogue_box()
	
	# Disparar intro después de 1.5 segundos
	await get_tree().create_timer(1.5).timeout
	_show(INTRO_LINES)

func _find_dialogue_box() -> Node:
	var root := get_tree().root
	return _search(root, "DialogueBox")

func _search(node: Node, name_target: String) -> Node:
	if node.name == name_target:
		return node
	for child in node.get_children():
		var r := _search(child, name_target)
		if r:
			return r
	return null

func _show(lines: Array) -> void:
	if _db and _db.has_method("show_dialogue"):
		var typed : Array[Dictionary] = []
		for l in lines:
			typed.append(l as Dictionary)
		_db.show_dialogue(typed)

# ════════════════════════════════════════════════════════════════
# MÉTODOS PÚBLICOS — llamados por TutorialTrigger
# ════════════════════════════════════════════════════════════════

func on_move_zone()     -> void: _show(MOVE_HINT)
func on_ladder_zone()   -> void: _show(LADDER_HINT)
func on_laser_zone()    -> void: _show(LASER_HINT)
func on_switch_zone()   -> void: _show(SWITCH_HINT)
func on_door_zone()     -> void: _show(DOOR_HINT)
func on_electric_zone() -> void: _show(ELECTRIC_HINT)
func on_crouch_zone()   -> void: _show(CROUCH_HINT)
func on_checkpoint()    -> void: _show(CHECKPOINT_MSG)
func on_sector_end()    -> void: _show(SECTOR_END)
