# NK-7 — Guía de Presentación del Equipo
> Ingeniería de Software — Exposición del Videojuego  
> Duración total: 10–15 minutos | 4 integrantes

---

## CONTEXTO GENERAL (todos deben saber esto)

**NK-7** es un plataformero 2D de acción y puzzle desarrollado en **Godot 4.6** con GDScript.  
Motor de física: **Jolt Physics**. Resolución: **1280×720**. Arquitectura: **escenas + autoloads singleton**.

El repositorio tiene:
- **53 scripts `.gd`**
- **37 escenas `.tscn`**
- **167 assets `.png`**
- **6 autoloads (singletons globales)**
- **5 niveles + pantallas de UI completas**

---

## LA HISTORIA (todos deben conocerla)

> *"No llegó por ambición. Llegó porque era bueno en los sistemas."*

**KAI**, 34 años, técnico de mantenimiento con 7 años en el **Complejo NK-7** — una planta de fusión nuclear industrial. Un martes de noviembre, mientras hace mantenimiento rutinario en el Sector B, nivel subterráneo 2, el sistema de control falla catastróficamente.

El protocolo de contención se activa automáticamente:
- Todas las salidas exteriores se bloquean
- Los láseres de seguridad se reconfiguran en modo letal
- Las alarmas rojas reemplazan la iluminación normal
- Kai queda solo, a 7 metros bajo tierra

Kai no entra en pánico. Recuerda las rutas de acceso secundarias que él mismo reparó años atrás. Supera puertas selladas usando consolas de mantenimiento, atraviesa láseres con movimientos calculados, y tras 40 minutos escucha una voz en un panel de emergencia: **RENA**, técnica de control, atrapada en el ala oeste.

Juntos coordinan la solución: Kai en el panel norte, Rena en el panel oeste. Activación simultánea. Las luces se apagan. Silencio. Luego, las luces de emergencia verdes guían hacia la salida.

**Epílogo:** Una semana después, los investigadores descubren la **Sala del Protocolo Rojo** — el origen real de la falla. Nadie tiene autorización para entrar. Kai se ofrece voluntario. No como héroe. Como técnico con trabajo pendiente.

**Tema central:** La tecnología fuera de control vs. el ingenio humano. El protagonista no es un superhéroe: es una persona ordinaria que piensa, se adapta y actúa bajo presión.

---

---

# DISTRIBUCIÓN DE LA EXPOSICIÓN

---

## 🎤 TATIANA — Historia del Juego y Arquitectura del Proyecto
**Tiempo estimado: 3–4 minutos**

### Qué decir:

**[Apertura — 30 seg]**
> "Buenos días. Vamos a presentar NK-7, un videojuego 2D de acción y puzzle desarrollado en Godot 4.6 con GDScript, aplicando patrones de diseño de software y buenas prácticas de ingeniería."

**[Historia completa — 2 min]**

Tatiana presenta la historia con detalle, usando estas secciones como guía:

**El mundo antes del colapso:**
> "El Complejo NK-7 es una planta de fusión nuclear industrial. 200 trabajadores la operan en turnos de 12 horas. Entre ellos está **KAI**, 34 años, técnico de mantenimiento con 7 años en la instalación. No llegó por ambición — llegó porque era bueno en los sistemas: tuberías, circuitos, controles, conductos de ventilación. Conocía cada válvula, cada panel dañado."

**El momento del colapso:**
> "Un martes de noviembre, Kai hace mantenimiento rutinario en la Zona Central, Sector B, nivel subterráneo 2. Una instrucción errónea llevaba semanas acumulando tensión en el sistema de control. Las luces parpadean. Suena la alerta de nivel 2. El sistema anuncia: *'El Protocolo de contención ha sido activado. Falla crítica detectada en el núcleo central. La evacuación está prohibida. Bloqueando todos los accesos exteriores.'* Las puertas se cierran. Las alarmas rojas reemplazan la iluminación. Kai está solo, a 7 metros bajo tierra."

**La supervivencia:**
> "Kai no entra en pánico. Recuerda las 3 rutas de acceso secundarias del Sector B. Supera una puerta sellada usando una consola de mantenimiento que él mismo reparó 2 años antes. En el siguiente corredor, láseres reconfigurados en modo letal bloquean el paso. Kai los estudia, calcula y los atraviesa con movimientos quirúrgicos."

**La señal en la oscuridad:**
> "Tras 40 minutos, escucha una voz en un panel de comunicaciones de emergencia: **RENA**, técnica de control, 28 años, atrapada en el ala oeste, nivel 3. Ella conoce los protocolos de acceso y las rutas de emergencia que no aparecen en los mapas estándar. Kai responde: *'En camino.'*"

**La resolución:**
> "Necesitan dos activaciones simultáneas: Kai en el panel norte, Rena en el panel oeste. Al activarlos, las luces se apagan completamente. Silencio absoluto. Luego, las luces de emergencia verdes guían hacia la salida. Escapan juntos."

**El epílogo — Protocolo Rojo:**
> "Una semana después, los investigadores encuentran una Sala del Protocolo Rojo en el subsuelo más profundo — el origen real de la falla. Nadie tiene autorización para entrar. Kai reconoce el número de sector en un informe de mantenimiento de 3 años atrás. Se ofrece voluntario. Entra solo, con su kit de herramientas. No como héroe. Como técnico con trabajo pendiente."

**El tema:**
> "La instalación simboliza la tecnología fuera de control. El protagonista no es un superhéroe: es una persona ordinaria con conocimiento técnico que piensa, se adapta y actúa bajo presión. Cada mecánica del juego tiene sentido narrativo: las puertas dañadas existen porque la instalación colapsó, los láseres están en modo letal porque el protocolo los reconfiguró, la stamina representa el esfuerzo físico real de un técnico escapando."

**[Arquitectura general — 1 min]**

El proyecto sigue una arquitectura de **3 capas**:

```
┌─────────────────────────────────────────┐
│           CAPA DE PRESENTACIÓN          │
│  Escenas (.tscn) + Scripts de UI        │
│  main_menu, player_hud, game_over...    │
├─────────────────────────────────────────┤
│           CAPA DE LÓGICA                │
│  Scripts de personajes, enemigos,       │
│  objetos, niveles                       │
├─────────────────────────────────────────┤
│           CAPA DE DATOS / ESTADO        │
│  Autoloads Singleton:                   │
│  GameManager, AudioManager,             │
│  LevelStateManager, AchievementManager  │
└─────────────────────────────────────────┘
```

**Los 6 Autoloads (Singletons globales):**

| Singleton | Responsabilidad |
|-----------|----------------|
| `GameManager` | Progreso, guardado (3 slots), transiciones, score, muertes |
| `AudioManager` | Música y SFX con buses Master/Music/SFX |
| `LevelStateManager` | Persiste estado de niveles entre sesiones |
| `AchievementManager` | Sistema de logros y contadores |
| `GameState` | Estado global del juego |
| `NK7Theme` | Tema visual global |

> "Estos singletons son accesibles desde cualquier script sin necesidad de referencias directas, lo que reduce el acoplamiento entre componentes."

**Patrón aplicado:** **Singleton Pattern** — un único punto de acceso a datos globales, evitando dependencias circulares entre escenas.

---

## 🎤 INTEGRANTE 2 — Mecánicas del Jugador y Sistema de Recursos
**Tiempo estimado: 3–4 minutos**

### Qué decir:

**[Sistema de recursos triple — 1.5 min]**

Kai tiene **3 recursos independientes** que el jugador debe gestionar simultáneamente:

```
❤️ SALUD (3 corazones = 100 HP)
   • Daño de enemigos y láseres
   • I-frames de 1.5s tras cada golpe
   • Sin regeneración automática

⚡ STAMINA (barra verde/azul)
   • Correr: -18 pts/s
   • Escalar rápido: -10 pts/s
   • Empujar: -8 pts/s
   • Regen parado: +12 pts/s (delay 1.2s)
   • Regen agachado: +28 pts/s (inmediata)
   • Si se agota: no puede correr hasta llegar a 20 pts

🔋 ENERGÍA (barra azul)
   • Hackear: -15 pts/s
   • Atacar (F): -8 pts instantáneo
   • Regen pasiva: +3 pts/s (delay 3s)
   • Regen agachado: +13 pts/s extra
```

> "Este diseño crea decisiones constantes: ¿corro y gasto stamina o camino y llego con más recursos? ¿hackeo la puerta ahora o espero a tener más energía?"

**[Mecánicas de movimiento — 1 min]**

| Acción | Tecla | Detalle |
|--------|-------|---------|
| Caminar | A / D | 120 px/s |
| Correr | Shift | 230 px/s, consume stamina |
| Saltar | Espacio | Fuerza mayor si corre |
| Agacharse | Ctrl | 60 px/s, regenera recursos |
| Escalar | W / S | Detecta Area2D de escaleras |
| Hackear | Q | Consume energía continuamente |
| Atacar | F | Rango 80px, daño 30, cooldown 0.6s |
| Interactuar | E | Puertas, switches, NPCs |
| Empujar | R | Velocidad reducida según stamina |

**[Sistema de corazones — 1 min]**

El HUD usa un sistema de **3 corazones** en lugar de barra de vida:
- Cada corazón representa ~33 HP
- Al recibir daño: animación de bounce (escala 1.3→1.0) + textura de daño
- Cuando HP llega a 0: pantalla de Game Over con fade-in, pulso de viñeta roja y shake de pantalla
- Al presionar cualquier tecla: fade out con flash blanco → reinicia el nivel actual

**Patrón aplicado:** **State Pattern** — el personaje tiene estados internos (`is_running`, `is_crouching`, `is_climbing`, `is_pushing`) que determinan qué acciones están disponibles y cómo se comporta la física.

**Patrón aplicado:** **Observer Pattern** — el HUD no accede directamente a Kai; busca al jugador por grupo `"player"` y consulta sus métodos públicos (`get_health()`, `get_tool_durability_percent()`) cada frame.

---

## 🎤 INTEGRANTE 3 — IA de Enemigos, Sistema de Puertas y Patrones de Diseño
**Tiempo estimado: 3–4 minutos**

### Qué decir:

**[IA de los Ukibuki — 1.5 min]**

Los **Ukibuki** son robots de seguridad con una máquina de estados finita (FSM):

```
IDLE ──→ PATROL ──→ ALERT ──→ CHASE ──→ ATTACK
                                ↑           │
                                └───────────┘
                                    ↓
                                DAMAGED ──→ DESTROYED
```

| Estado | Comportamiento |
|--------|---------------|
| `IDLE` | Quieto, detecta jugador en rango 320px |
| `PATROL` | Patrulla ±200px del origen, pausa 0.35s al girar |
| `ALERT` | Detectó jugador, se orienta, decide acción |
| `CHASE` | Persigue a 1.4× velocidad, recuerda última posición |
| `ATTACK` | Verifica LOS, dispara proyectil, cooldown 2.2s |
| `DAMAGED` | Pausa 0.5s tras recibir daño |
| `DESTROYED` | Animación de explosión, desaparece tras 1.2s |

**Line-of-Sight (LOS):** El robot usa un **Raycast** desde su posición hasta el jugador. Si hay una pared entre ellos, NO dispara. Esto obliga al jugador a usar la geometría del nivel como cobertura.

```gdscript
# Verificación de línea de visión
var query = PhysicsRayQueryParameters2D.create(
    global_position, player.global_position, LOS_COLLISION_MASK)
var result = get_world_2d().direct_space_state.intersect_ray(query)
return result.is_empty()  # true = puede ver al jugador
```

**Al destruir un Ukibuki:**
- +500 puntos al score
- Camera shake (intensidad 8.0, duración 0.35s)
- Registra derrota en `LevelStateManager` (persiste entre sesiones)
- Incrementa contador en `AchievementManager`

**[Sistema de puertas — 1.5 min]**

El juego tiene **6 tipos de puertas**, cada una con comportamiento distinto:

| Tipo | Interacción | Recurso consumido |
|------|-------------|-------------------|
| `door.tscn` | Automática | Ninguno |
| `damaged_door.tscn` | [F] Reparar | Stamina (herramienta) |
| `locked_door.tscn` | [E] Hackear | Energía |
| `electric_door.tscn` | [F] Reparar → [E] Hackear | Stamina + Energía |
| `level_door.tscn` | [E] Entrar | Ninguno (transición) |
| `locked_door.tscn` | Keycard | Coleccionable |

La **puerta electrificada** tiene 7 estados internos:
`LOCKED_DAMAGED → REPAIRING → LOCKED_FIXED → UNLOCKING → OPENING → OPEN → ELECTRIFIED`

> "Cada tipo de puerta consume un recurso diferente de Kai, creando decisiones de gestión de recursos. Una puerta dañada requiere stamina para reparar; una puerta bloqueada requiere energía para hackear."

**[Patrones de diseño aplicados — 1 min]**

| Patrón | Dónde se aplica |
|--------|----------------|
| **Singleton** | Los 6 autoloads (GameManager, AudioManager, etc.) |
| **State Machine (FSM)** | IA de Ukibuki (7 estados), puertas electrificadas (7 estados) |
| **Observer** | Señales de Godot: `door_opened`, `player_detected`, `level_completed` |
| **Strategy** | Diferentes comportamientos de movimiento según estado (correr/agacharse/escalar) |
| **Template Method** | `level_base.gd` define el esqueleto de cada nivel; subclases implementan `_on_level_ready()` |
| **Component** | Cada mecánica de Kai es independiente (stamina, energía, salud, escaleras) |

---

## 🎤 INTEGRANTE 4 — Sistemas de Persistencia, UI, Demo en Vivo y Cierre
**Tiempo estimado: 3–4 minutos**

### Qué decir:

**[Sistema de guardado — 1 min]**

El juego tiene **3 slots de guardado** independientes. Cada slot guarda:

```
save_slot_0.dat
├── save_name: "Mi Partida"
├── current_level: 2
├── current_checkpoint: 3
├── total_deaths: 7
├── total_time: 1847.3 (segundos)
├── total_score: 12500
├── date_string: "2025-05-26"
└── level_state: { enemigos derrotados, puertas abiertas... }
```

El `LevelStateManager` persiste el estado de cada nivel: si un enemigo fue derrotado, sigue derrotado al volver al nivel. Si una puerta fue abierta, sigue abierta.

**Sistema de checkpoints inteligente (`SmartCheckpointSystem`):**
- No usa checkpoints fijos en posiciones predefinidas
- Detecta todas las `SafeZone` del nivel (Area2D con grupo `"safe_zones"`)
- Al morir, calcula la zona segura **más cercana** al punto de muerte
- Hace un raycast hacia abajo para encontrar suelo sólido (evita spawns en el aire)

**[Flujo completo del juego — 1 min]**

```
Splash Screen
    ↓ (cualquier tecla)
Menú Principal
    ├── Iniciar Partida → nombre de partida → Nivel 1
    ├── Cargar Partida → selector de slots → nivel guardado
    ├── Ajustes → volumen, controles
    ├── Créditos
    ├── Perfil / Logros
    └── Salir

Durante el juego:
    Nivel 1 (Demo) → [E] Puerta → Nivel 2 → ... → Nivel 5
    
    Si muere:
    Animación "dead" → 1.5s → Game Over Screen
    (cualquier tecla) → reinicia nivel actual con vida completa

    Pausa (Escape):
    Reanudar / Ajustes / Menú Principal
```

**[Demo en vivo — 1 min]**

Mostrar mientras se juega:
1. **Splash screen** → menú principal con animaciones de botones
2. **Iniciar partida** → nivel 1 (Sector B)
3. Mostrar **barra de stamina** bajando al correr
4. Mostrar **corazones** perdiendo uno al tocar un láser
5. Acercarse a un **Ukibuki** — mostrar que se activa la IA (PATROL → ALERT → CHASE → ATTACK)
6. Usar **[E]** en el switch para desactivar el láser del piso 3
7. Llegar a la **puerta de salida** → animación de apertura → transición al nivel 2

**[Cierre — 30 seg]**

> "NK-7 aplica principios de ingeniería de software como separación de responsabilidades, patrones de diseño reconocidos y arquitectura en capas. El resultado es un juego mantenible, extensible y con mecánicas coherentes con su narrativa. Cada sistema — desde la IA hasta el guardado — fue diseñado pensando en la escalabilidad del proyecto."

---

---

## PREGUNTAS FRECUENTES (prepararse para responder)

**¿Por qué Godot y no Unity?**
> Godot es open source, tiene un sistema de escenas más limpio para 2D, y GDScript es más legible para prototipar rápido. El sistema de señales de Godot implementa Observer de forma nativa.

**¿Qué patrón de diseño consideran el más importante del proyecto?**
> El Singleton (autoloads) porque permite que cualquier script acceda a GameManager sin crear dependencias directas entre escenas. Esto es crítico cuando el juego tiene 37 escenas que necesitan compartir estado.

**¿Cómo manejan la persistencia entre niveles?**
> `LevelStateManager` serializa el estado de cada nivel en un diccionario. `GameManager.save_game()` lo incluye en el archivo `.dat`. Al cargar, `LevelStateManager` restaura el estado antes de que el nivel termine de inicializarse.

**¿Cómo funciona el sistema de checkpoints?**
> No son checkpoints fijos. El `SmartCheckpointSystem` busca todas las `SafeZone` del nivel, registra cuál fue la última en la que estuvo el jugador, y al morir hace un raycast hacia abajo desde esa posición para encontrar suelo sólido. Esto evita spawns en el aire o dentro de paredes.

**¿Cómo está implementada la IA?**
> Máquina de estados finita (FSM) con 7 estados. La transición entre estados se basa en distancia al jugador y verificación de línea de visión mediante raycast. El robot recuerda la última posición conocida del jugador durante 2.5 segundos antes de volver a patrullar.

**¿Qué tan escalable es el sistema de puertas?**
> Muy escalable. Cada tipo de puerta es una escena independiente con su propio script. Para agregar un nuevo tipo de puerta, se crea una nueva escena que extiende `Node2D` y se conecta a los recursos de Kai mediante sus métodos públicos (`consume_energy()`, `use_tool()`). No hay que modificar código existente.

---

## RESUMEN RÁPIDO PARA MEMORIZAR

| Aspecto | Dato clave |
|---------|-----------|
| Motor | Godot 4.6, GDScript |
| Género | Plataformero 2D acción/puzzle |
| Protagonista | Kai, técnico de mantenimiento |
| Antagonista | El sistema automatizado fuera de control |
| Niveles | 5 + epílogo (Protocolo Rojo) |
| Recursos del jugador | Salud (3 corazones), Stamina, Energía |
| Enemigos | Ukibuki (robots con FSM + LOS) |
| Patrones principales | Singleton, FSM, Observer, Template Method |
| Guardado | 3 slots, persistencia de estado de nivel |
| Scripts totales | 53 `.gd` |
| Escenas totales | 37 `.tscn` |

---

*Documento generado para la exposición del proyecto NK-7 — Ingeniería de Software*
