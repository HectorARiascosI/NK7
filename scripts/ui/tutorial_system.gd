extends CanvasLayer

## Sistema de Tutorial Mejorado para NK7
## Muestra controles y mecánicas del juego con navegación completa
## Permite avanzar, retroceder, saltar todo, y ver historial

signal tutorial_finished
signal tutorial_skipped

# ── Estado ────────────────────────────────────────────────────
var is_active      : bool = false
var _pages         : Array[Dictionary] = []
var _current_page  : int  = 0
var _history       : Array[Dictionary] = []  # Historial de páginas vistas
var _can_navigate  : bool = true
var _tutorial_shown_once : bool = false  # Para no mostrar después de morir

# ── Nodos UI ──────────────────────────────────────────────────
var _panel         : PanelContainer
var _title         : Label
var _content       : RichTextLabel
var _page_counter  : Label
var _btn_prev      : Button
var _btn_next      : Button
var _btn_skip      : Button
var _btn_history   : Button
var _controls_hint : Label

# ── Páginas del tutorial ──────────────────────────────────────
const TUTORIAL_PAGES : Array[Dictionary] = [
	{
		"title": "Bienvenido al Complejo NK7",
		"content": """[center]Este es un nivel de demostración donde aprenderás
los controles básicos y las mecánicas del juego.

Usa las flechas de navegación para avanzar o retroceder.
Puedes saltar el tutorial en cualquier momento.[/center]"""
	},
	{
		"title": "Movimiento Básico",
		"content": """[b]Caminar:[/b] [color=#E8A000]A[/color] (izquierda) / [color=#E8A000]D[/color] (derecha)

[b]Saltar:[/b] [color=#E8A000]ESPACIO[/color]
• Salta más alto manteniendo presionado
• El salto es más corto si sueltas rápido

[b]Agacharse:[/b] [color=#E8A000]CTRL[/color]
• Mantén presionado para moverte agachado
• Útil para pasar por espacios estrechos"""
	},
	{
		"title": "Movimiento Avanzado",
		"content": """[b]Correr:[/b] [color=#E8A000]SHIFT[/color] (mantener mientras caminas)
• Aumenta tu velocidad considerablemente
• [color=#00CC44]Al saltar corriendo llegarás MÁS LEJOS[/color]
• Usa esto para cruzar plataformas distantes

[b]Física realista:[/b]
• Tu momentum se conserva en el aire
• Puedes controlar la dirección mientras saltas
• Correr + saltar = mayor distancia horizontal"""
	},
	{
		"title": "Escaleras y Escalada",
		"content": """[b]Subir escaleras:[/b] [color=#E8A000]W[/color]
[b]Bajar escaleras:[/b] [color=#E8A000]S[/color]

• Acércate a una escalera y presiona W o S
• Puedes moverte horizontalmente mientras escalas
• Presiona [color=#E8A000]ESPACIO[/color] para saltar desde la escalera
• Mantén [color=#E8A000]SHIFT[/color] para escalar más rápido

Las escaleras conectan diferentes niveles del complejo."""
	},
	{
		"title": "Interacciones Básicas",
		"content": """[b]Interactuar:[/b] [color=#E8A000]E[/color]
• Activar interruptores
• Hablar con personajes
• Recoger objetos
• Usar paneles de control

[b]Empujar:[/b] [color=#E8A000]R[/color] (mantener)
• Mantén presionado mientras caminas hacia el objeto
• Útil para mover cajas y obstáculos
• Algunos puzzles requieren reposicionar objetos"""
	},
	{
		"title": "Herramientas y Hackeo",
		"content": """[b]Hackear:[/b] [color=#E8A000]Q[/color] (mantener)
• Desbloquear puertas bloqueadas
• Hackear paneles de seguridad
• [color=#00CCFF]Consume ENERGÍA[/color] (15 pts/segundo)

[b]Atacar:[/b] [color=#E8A000]F[/color] cerca de un enemigo
• Golpe eléctrico de corto alcance
• [color=#00CCFF]Consume 8 pts de ENERGÍA[/color] por golpe

[color=#00CC44]Agáchate quieto para recuperar energía más rápido.[/color]"""
	},
	{
		"title": "Sistema de Puertas NK-7",
		"content": """El complejo tiene DOS tipos de puertas:

[b]1. PUERTAS DAÑADAS[/b] (luz roja parpadeante)
• Mantén [color=#E8A000]F[/color] para reparar paso a paso
• Requieren 1-3 pasos de reparación
• Consumen durabilidad de herramienta
• Se abren automáticamente al completar

[b]2. PUERTAS BLOQUEADAS[/b] (panel apagado)
• Mantén [color=#E8A000]Q[/color] para hackear el sistema
• Requieren 2-4 segundos de hackeo
• Consumen energía del jugador
• Se abren automáticamente al completar

[b]3. PUERTAS PRINCIPALES[/b] (requieren tarjeta)
• Necesitas una [color=#FFD700]Tarjeta de Acceso[/color]
• Busca tarjetas en el nivel
• Algunas ocultan coleccionables valiosos"""
	},
	{
		"title": "Coleccionables",
		"content": """[b]CUBOS HOLOGRÁFICOS[/b] [color=#00CCFF](Azul)[/color]
• Coleccionable principal del juego
• Aumentan tu puntuación significativamente
• Algunos están ocultos o protegidos

[b]TARJETAS DE ACCESO[/b] [color=#FFD700](Dorado)[/color]
• Abren puertas principales bloqueadas
• Algunas son coleccionables para puntuación
• Necesarias para acceder a áreas secretas

[b]TUBOS DE ENERGÍA[/b] [color=#00FFCC](Cyan)[/color]
• Restauran tu energía
• Necesarios para hackear múltiples sistemas
• Aparecen en áreas con muchos peligros

[b]ENGRANAJES[/b] [color=#FFA500](Naranja)[/color]
• Aumentan tu puntuación
• Abundantes en el nivel
• Recolecta todos para máxima puntuación"""
	},
	{
		"title": "Enemigos: Ukibuki",
		"content": """[b]ROBOT UKIBUKI[/b] [color=#FF3333](Corrupto)[/color]
• Robot flotante corrupto que patrulla el complejo.
• [color=#FF6666]Dispara proyectiles si te ve directamente.[/color]
• [color=#00CC44]Si te cubres detrás de una estructura, NO dispara.[/color]

[b]Estados (color de luz):[/b]
• [color=#FF4444]Rojo:[/color] Patrullando — no te ha visto
• [color=#FFAA00]Naranja:[/color] ¡Alerta! — te detectó
• [color=#FF8800]Naranja intenso:[/color] Persiguiéndote
• [color=#FF2222]Rojo brillante:[/color] ¡Disparando!

[b]Estrategia:[/b]
• Usa paredes y cajas como cobertura
• Ataca por sorpresa desde atrás
• Destruirlo da [color=#FFD700]500 puntos[/color]"""
	},
	{
		"title": "Peligros y Zonas de Muerte",
		"content": """[color=#CC2200][b]¡CUIDADO![/b][/color]

• [b]Láseres de seguridad:[/b] Muerte instantánea
  - Horizontales, verticales y rotativos
  - Observa los patrones antes de cruzar

• [b]Zonas electrificadas:[/b] Observa los patrones
  - Animación eléctrica indica peligro
  - Busca interruptores para desactivarlas

• [b]Caídas al vacío:[/b] Respawn en checkpoint

• [b]Proyectiles enemigos:[/b] Esquiva o usa cobertura

[color=#00CC44]Busca interruptores y palancas para desactivar peligros.[/color]"""
	},
	{
		"title": "Interruptores y Controles",
		"content": """[b]BOTONES PEQUEÑOS[/b]
• Activan/desactivan sistemas cercanos
• Algunos son temporales
• Presiona [color=#E8A000]E[/color] para usar

[b]PANELES DE CONTROL[/b]
• Controlan sistemas complejos
• Pueden desactivar múltiples peligros
• Algunos requieren hackeo [color=#E8A000]Q[/color]

[b]PALANCAS MECÁNICAS[/b]
• Cambian estado de puertas y plataformas
• Efecto permanente hasta cambiar de nuevo
• Observa qué sistemas controlan"""
	},
	{
		"title": "Sistema de Checkpoints",
		"content": """El juego guarda tu progreso automáticamente en:

• [color=#00CC44]Puntos de control verdes[/color]
• Al completar secciones importantes
• Antes de áreas peligrosas
• [color=#FFD700]Al recolectar cubos holográficos[/color]

Si mueres, reaparecerás en el último checkpoint.
No hay límite de vidas.

[b]Tu progreso incluye:[/b]
• Posición en el nivel
• Coleccionables obtenidos
• Puertas abiertas
• Enemigos derrotados"""
	},
	{
		"title": "Recursos del Jugador",
		"content": """[b]SALUD[/b] [color=#FF6699](Rosa)[/color]
• Tu vida. Se reduce al recibir daño.
• Tienes 1.5s de invencibilidad tras cada golpe.

[b]ENERGÍA[/b] [color=#6699FF](Azul)[/color]
• Necesaria para hackear [color=#E8A000]Q[/color] y atacar [color=#E8A000]F[/color].
• Se regenera sola lentamente (3 pts/s, tras 3s sin usar).
• [color=#00CC44]Agáchate quieto para recuperarla más rápido (+10 pts/s).[/color]

[b]STAMINA[/b] [color=#FFAA33](Dorado)[/color]
• Necesaria para correr [color=#E8A000]SHIFT[/color].
• Se agota corriendo (18 pts/s). Al llegar a 0, vuelves a caminar.
• Se regenera al parar (12 pts/s, tras 1.2s).
• [color=#00CC44]Agáchate quieto para recuperarla más rápido (+28 pts/s).[/color]

[color=#FFFF00]Agacharte es tu mejor herramienta de recuperación.[/color]"""
	},
	{
		"title": "Controles Rápidos - Resumen",
		"content": """[b]MOVIMIENTO:[/b]
A / D — Caminar   |   SHIFT — Correr (consume stamina)
ESPACIO — Saltar   |   CTRL — Agacharse
W / S — Subir / Bajar escaleras

[b]ACCIONES:[/b]
E — Interactuar   |   Q — Hackear (consume energía)
F — Atacar / Reparar   |   R — Empujar

[b]RECUPERACIÓN:[/b]
• Agachado quieto: stamina +28/s, energía +13/s
• Parado: stamina +12/s (tras 1.2s), energía +3/s (tras 3s)

[b]PENALIZACIÓN:[/b]
• 5 muertes seguidas sin llegar a un checkpoint
  → pierdes el 15% de tu puntuación

[b]SISTEMA:[/b]
ESC — Pausar   |   TAB — Ver controles

[color=#E8A000]¡Usa la cobertura, gestiona tus recursos y avanza![/color]"""
	}
]

# ════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ════════════════════════════════════════════════════════════════

func _ready() -> void:
	layer = 10  # Encima del HUD (layer 5)
	_build_ui()
	_hide_panel()
	process_mode = Node.PROCESS_MODE_ALWAYS


func _build_ui() -> void:
	# ── Control raíz: ocupa toda la pantalla ──────────────────────
	var root_ctrl := Control.new()
	root_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_ctrl)

	# (Sin overlay oscuro — no queremos oscurecer el escenario)

	# ── Panel centrado: 560×380 centrado en 1280×720 ──────────────
	# Centro: 1280/2=640, 720/2=360
	# Esquina: 640-280=360, 360-190=170
	var PW := 560.0
	var PH := 380.0
	var PX := (1280.0 - PW) / 2.0   # = 360.0
	var PY := (720.0  - PH) / 2.0   # = 170.0

	_panel = PanelContainer.new()
	# layout_mode=0 = posición libre, respeta position y size
	_panel.set("layout_mode", 0)
	_panel.position = Vector2(PX, PY)
	_panel.size     = Vector2(PW, PH)

	var style := StyleBoxFlat.new()
	style.bg_color     = Color(0.05, 0.08, 0.14, 0.97)
	style.border_color = Color(0.91, 0.63, 0.00, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	style.set_content_margin_all(20)
	_panel.add_theme_stylebox_override("panel", style)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	root_ctrl.add_child(_panel)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_panel.add_child(vbox)
	
	# Título
	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 20)
	_title.add_theme_color_override("font_color", Color(0.91, 0.63, 0.00, 1.0))
	vbox.add_child(_title)
	
	# Separador
	var sep1 := HSeparator.new()
	vbox.add_child(sep1)
	
	# Contenido
	_content = RichTextLabel.new()
	_content.bbcode_enabled = true
	_content.fit_content = false
	_content.custom_minimum_size = Vector2(0, 180)
	_content.add_theme_font_size_override("normal_font_size", 14)
	_content.add_theme_color_override("default_color", Color(1.0, 1.0, 1.0, 1.0))
	vbox.add_child(_content)
	
	# Separador
	var sep2 := HSeparator.new()
	vbox.add_child(sep2)
	
	# Contador de páginas
	_page_counter = Label.new()
	_page_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_page_counter.add_theme_font_size_override("font_size", 12)
	_page_counter.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75, 1.0))
	vbox.add_child(_page_counter)
	
	# Botones de navegación
	var btn_container := HBoxContainer.new()
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_container.add_theme_constant_override("separation", 12)
	vbox.add_child(btn_container)
	
	_btn_prev = _create_button("◄ Anterior")
	_btn_prev.pressed.connect(_on_prev_pressed)
	btn_container.add_child(_btn_prev)
	
	_btn_next = _create_button("Siguiente ►")
	_btn_next.pressed.connect(_on_next_pressed)
	btn_container.add_child(_btn_next)
	
	_btn_skip = _create_button("Saltar Tutorial")
	_btn_skip.pressed.connect(_on_skip_pressed)
	btn_container.add_child(_btn_skip)
	
	_btn_history = _create_button("📋 Historial")
	_btn_history.pressed.connect(_on_history_pressed)
	btn_container.add_child(_btn_history)
	
	# Hint de controles
	_controls_hint = Label.new()
	_controls_hint.text = "[ ← / → - Navegar | ESC - Saltar | TAB - Historial ]"
	_controls_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_controls_hint.add_theme_font_size_override("font_size", 10)
	_controls_hint.add_theme_color_override("font_color", Color(0.55, 0.75, 0.85, 0.9))
	vbox.add_child(_controls_hint)


func _create_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(140, 36)
	return btn


# ════════════════════════════════════════════════════════════════
# API PÚBLICA
# ════════════════════════════════════════════════════════════════

func show_tutorial() -> void:
	# No mostrar si ya se mostró una vez EN ESTA SESIÓN
	# Usamos GameManager para persistir el flag entre recargas de escena
	if _tutorial_shown_once:
		return
	if has_node("/root/GameManager") and GameManager.get("tutorial_shown"):
		_tutorial_shown_once = true
		return

	_pages.clear()
	for page in TUTORIAL_PAGES:
		_pages.append(page)

	_current_page        = 0
	is_active            = true
	_tutorial_shown_once = true

	# Marcar en GameManager para que persista entre muertes
	if has_node("/root/GameManager"):
		GameManager.set("tutorial_shown", true)

	get_tree().paused = true
	_show_panel()
	_update_page()


func show_controls_reminder() -> void:
	"""Muestra solo la página de resumen de controles"""
	_pages.clear()
	_pages.append(TUTORIAL_PAGES[-1])

	_current_page = 0
	is_active     = true

	get_tree().paused = true

	_show_panel()
	_update_page()


# ════════════════════════════════════════════════════════════════
# NAVEGACIÓN
# ════════════════════════════════════════════════════════════════

func _update_page() -> void:
	if _pages.is_empty():
		return
	
	var page := _pages[_current_page]
	_title.text = page.get("title", "")
	_content.text = page.get("content", "")
	_page_counter.text = "Página %d de %d" % [_current_page + 1, _pages.size()]
	
	# Actualizar estado de botones
	_btn_prev.disabled = (_current_page == 0)
	_btn_next.text = "Finalizar ✓" if _current_page == _pages.size() - 1 else "Siguiente ►"
	
	# Agregar al historial si no es la misma página
	if _history.is_empty() or _history[-1] != page:
		_history.append(page)


func _on_prev_pressed() -> void:
	if _current_page > 0:
		_current_page -= 1
		_update_page()


func _on_next_pressed() -> void:
	if _current_page < _pages.size() - 1:
		_current_page += 1
		_update_page()
	else:
		_finish()


func _on_skip_pressed() -> void:
	tutorial_skipped.emit()
	_finish()


func _on_history_pressed() -> void:
	# TODO: Implementar panel de historial si se requiere
	# Por ahora, muestra la última página vista
	if not _history.is_empty():
		var last_page := _history[-1]
		_title.text = "[HISTORIAL] " + last_page.get("title", "")
		_content.text = last_page.get("content", "")


func _finish() -> void:
	is_active = false
	# ── REANUDAR el mundo al cerrar el tutorial ───────────────────
	get_tree().paused = false
	tutorial_finished.emit()
	_hide_panel()


# ════════════════════════════════════════════════════════════════
# INPUT
# ════════════════════════════════════════════════════════════════

func _input(event: InputEvent) -> void:
	if not is_active or not _can_navigate:
		return
	
	# Capturar TODOS los inputs relacionados con navegación
	# Usar _input en lugar de _unhandled_input para mayor prioridad
	
	if event.is_action_pressed("ui_left") or event.is_action_pressed("move_left"):
		if _current_page > 0:
			get_viewport().set_input_as_handled()
			_on_prev_pressed()
	
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("move_right"):
		if _current_page < _pages.size() - 1:
			get_viewport().set_input_as_handled()
			_on_next_pressed()
		else:
			get_viewport().set_input_as_handled()
			_finish()
	
	elif event.is_action_pressed("ui_cancel"):
		# Capturar ESC con máxima prioridad
		get_viewport().set_input_as_handled()
		_on_skip_pressed()
	
	elif event.is_action_pressed("pause"):
		# También capturar la acción de pausa
		get_viewport().set_input_as_handled()
		_on_skip_pressed()
	
	elif event.is_action_pressed("ui_focus_next"):  # TAB
		get_viewport().set_input_as_handled()
		_on_history_pressed()


# ════════════════════════════════════════════════════════════════
# HELPERS
# ════════════════════════════════════════════════════════════════

func _show_panel() -> void:
	_panel.modulate.a = 0.0
	_panel.visible = true
	var tw := create_tween()
	tw.tween_property(_panel, "modulate:a", 1.0, 0.25)


func _hide_panel() -> void:
	var tw := create_tween()
	tw.tween_property(_panel, "modulate:a", 0.0, 0.2)
	await tw.finished
	_panel.visible = false
