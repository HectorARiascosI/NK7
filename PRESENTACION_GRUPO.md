# NK-7 — Guía de Presentación del Equipo
> Ingeniería de Software — Exposición del Videojuego  
> Duración total: 10–15 minutos | 4 integrantes

---

## CONTEXTO GENERAL (todos deben saber esto)

**NK-7** es un plataformero 2D de acción y puzzle en **Godot 4.6** con GDScript.  
53 scripts · 37 escenas · 167 assets · 6 singletons · 5 niveles

---

## LA HISTORIA (todos deben conocerla de memoria)

**KAI**, técnico de mantenimiento, 7 años en el Complejo NK-7 — planta de fusión nuclear. Un martes de noviembre el sistema de control falla: protocolo de contención activado, salidas bloqueadas, láseres en modo letal. Kai queda solo a 7 metros bajo tierra. Usa su conocimiento del lugar para avanzar. Encuentra a **RENA** por radio. Juntos activan dos paneles simultáneamente y escapan. Epílogo: Kai vuelve solo a investigar la Sala del Protocolo Rojo — el origen real de la falla. No como héroe. Como técnico con trabajo pendiente.

---

# DISTRIBUCIÓN — 3 min por persona aprox.

---

## 🎤 1. TATIANA — Historia + Arquitectura
**~3 min**

### Historia (2 min)

> "Buenos días, vamos a presentar NK-7, un videojuego 2D desarrollado en Godot 4.6."

Cuenta la historia con estas partes:

**El mundo:** El Complejo NK-7 es una planta de fusión nuclear. Kai lleva 7 años ahí, conoce cada válvula y panel dañado. No llegó por ambición — llegó porque era bueno en los sistemas.

**El colapso:** Un martes de noviembre, mientras hace mantenimiento en el Sector B subterráneo, el sistema anuncia: *"Protocolo de contención activado. Falla crítica en el núcleo. Evacuación prohibida."* Las puertas se cierran. Kai está solo a 7 metros bajo tierra.

**La supervivencia:** Kai no entra en pánico. Recuerda rutas secundarias que él mismo reparó. Supera puertas selladas, atraviesa láseres con movimientos calculados.

**Rena:** Tras 40 minutos escucha a **RENA** por radio — técnica atrapada en el ala oeste. Ella conoce rutas que no están en los mapas estándar.

**La resolución:** Activación simultánea: Kai en el panel norte, Rena en el panel oeste. Luces de emergencia verdes. Escapan juntos.

**Epílogo:** Kai vuelve solo a la Sala del Protocolo Rojo. No como héroe. Como técnico con trabajo pendiente.

**Tema:** La tecnología fuera de control vs. el ingenio humano. Cada mecánica tiene sentido narrativo: las puertas dañadas existen porque la instalación colapsó, los láseres están en modo letal porque el protocolo los reconfiguró.

### Arquitectura (1 min)

El proyecto tiene **3 capas**:

```
PRESENTACIÓN  →  Escenas .tscn + UI
LÓGICA        →  Scripts de personajes, enemigos, objetos
DATOS/ESTADO  →  6 Autoloads Singleton (accesibles desde cualquier script)
```

| Singleton | Qué hace |
|-----------|---------|
| `GameManager` | Guardado, transiciones, score, muertes |
| `AudioManager` | Música y efectos de sonido |
| `LevelStateManager` | Persiste estado de niveles |
| `AchievementManager` | Logros y contadores |
| `GameState` | Estado global de sesión |
| `NK7Theme` | Tema visual global |

> "Estos singletons reducen el acoplamiento — cualquier script puede acceder a GameManager sin referencias directas entre escenas."

---

## 🎤 2. STEVEN — Mecánicas del Jugador + Guardado
**~3 min**

### Sistema de recursos (1.5 min)

Kai tiene **3 recursos** que el jugador gestiona al mismo tiempo:

| Recurso | Representación | Se gasta con... | Se recupera con... |
|---------|---------------|-----------------|-------------------|
| ❤️ Salud | 3 corazones | Daño de enemigos/láseres | No se regenera |
| ⚡ Stamina | Barra verde/azul | Correr, escalar, empujar | Estar quieto o agachado |
| 🔋 Energía | (interna) | Hackear, atacar | Esperar o agacharse |

> "Esto crea decisiones constantes: ¿corro y llego más rápido pero sin stamina? ¿hackeo ahora o espero a tener más energía?"

**Stamina en detalle:**
- Correr: -18 pts/s · Escalar rápido: -10 pts/s · Empujar: -8 pts/s
- Regen parado: +12 pts/s (delay 1.2s) · Regen agachado: +28 pts/s (inmediata)
- Si se agota: no puede correr hasta recuperar 20 pts

**Sistema de corazones:**
- 3 corazones = 100 HP · I-frames de 1.5s tras cada golpe
- Al recibir daño: animación de bounce + textura de daño por 0.4s
- HP = 0 → Game Over con fade-in, viñeta roja y shake de pantalla

### Controles (30 seg)

| Acción | Tecla | Nota |
|--------|-------|------|
| Mover | A / D | |
| Correr | Shift | Consume stamina |
| Saltar | Espacio | Más fuerza si corre |
| Agacharse | Ctrl | Regenera recursos |
| Escalar | W / S | Detecta escaleras automáticamente |
| Interactuar | E | Puertas, switches |
| Hackear | Q | Consume energía |
| Atacar | F | Rango 80px, daño 30 |

### Guardado y checkpoints (1 min)

**3 slots de guardado** — cada uno guarda: nivel actual, checkpoint, muertes, tiempo, score y estado del nivel (qué enemigos cayeron, qué puertas se abrieron).

**SmartCheckpointSystem** — checkpoints inteligentes:
- No son posiciones fijas
- Al morir, busca la **zona segura más cercana** al punto de muerte
- Hace un raycast hacia abajo para asegurarse de que hay suelo sólido
- Evita spawns en el aire o dentro de paredes

---

## 🎤 3. SEBASTIAN — IA de Enemigos + Sistema de Puertas
**~3 min**

### IA de los Ukibuki (1.5 min)

Los **Ukibuki** son robots de seguridad con una **máquina de estados finita (FSM)**:

```
IDLE → PATROL → ALERT → CHASE → ATTACK
                                   ↓
                            DAMAGED → DESTROYED
```

| Estado | Qué hace |
|--------|---------|
| IDLE | Quieto, detecta jugador en rango 320px |
| PATROL | Patrulla ±200px, pausa 0.35s al girar |
| ALERT | Detectó jugador, se orienta |
| CHASE | Persigue a 1.4× velocidad, recuerda última posición 2.5s |
| ATTACK | Verifica LOS, dispara, cooldown 2.2s |
| DAMAGED | Pausa 0.5s tras recibir daño |
| DESTROYED | Explosión, desaparece tras 1.2s |

**Line-of-Sight:** Usa un **Raycast** hasta el jugador. Si hay una pared entre ellos, NO dispara — el jugador puede usar la geometría como cobertura.

Al destruir un Ukibuki: +500 puntos, camera shake, registra derrota en `LevelStateManager` (persiste entre sesiones).

### Sistema de puertas (1.5 min)

**6 tipos de puertas**, cada una consume un recurso distinto:

| Tipo | Cómo se abre | Recurso |
|------|-------------|---------|
| Normal | Automática | Ninguno |
| Dañada | [F] Reparar | Stamina |
| Bloqueada | [E] Hackear | Energía |
| Electrificada | [F] Reparar → [E] Hackear | Stamina + Energía |
| De nivel | [E] Entrar | Ninguno (transición) |
| Con keycard | Coleccionable | Keycard |

La **puerta electrificada** tiene 7 estados internos:
`LOCKED_DAMAGED → REPAIRING → LOCKED_FIXED → UNLOCKING → OPENING → OPEN → ELECTRIFIED`

> "Cada puerta consume un recurso diferente de Kai. Esto conecta el diseño de niveles con la gestión de recursos — si llegás sin energía, no podés hackear la puerta."

---

## 🎤 4. HECTOR (TÚ) — Patrones de Diseño + Demo + Cierre
**~3 min** *(lo más liviano)*

### Patrones de diseño (1 min)

> "Antes de ver el juego en acción, les muestro los patrones de diseño que aplicamos."

| Patrón | Dónde |
|--------|-------|
| **Singleton** | Los 6 autoloads — un punto de acceso global sin dependencias directas |
| **FSM** | IA del Ukibuki (7 estados) y puertas electrificadas (7 estados) |
| **Observer** | Señales de Godot: `door_opened`, `player_detected`, `level_completed` |
| **Template Method** | `level_base.gd` define el esqueleto; cada nivel implementa su lógica específica |
| **Strategy** | Comportamiento de movimiento cambia según estado: correr, agacharse, escalar |

> "El más importante es el Singleton — con 37 escenas que comparten estado, sin él tendríamos dependencias circulares por todos lados."

### Demo en vivo (1.5 min)

Muestra esto en orden:

1. **Splash screen** → cualquier tecla → menú principal
2. **Iniciar Partida** → escribe nombre → nivel 1
3. **Corre con Shift** → señala que la barra de stamina baja
4. **Toca un láser** → pierde un corazón con animación
5. **Acércate a un Ukibuki** → PATROL → ALERT → CHASE → ATTACK
6. **[E] en el switch** → láser del piso 3 se apaga
7. **Puerta de salida** → [E] → animación → transición al nivel 2

### Cierre (30 seg)

> "NK-7 aplica ingeniería de software de forma práctica: arquitectura en capas, patrones reconocidos y sistemas desacoplados. Si mañana queremos agregar un nuevo enemigo o tipo de puerta, no tocamos código existente — solo lo extendemos. El repositorio tiene commits por integrante, documentación técnica en `docs/` y un README completo. Estamos abiertos a preguntas."

---

---

## PREGUNTAS FRECUENTES

**¿Por qué Godot y no Unity?**
> Open source, sistema de escenas más limpio para 2D, y las señales implementan Observer de forma nativa.

**¿Patrón más importante?**
> Singleton — con 37 escenas compartiendo estado, es lo que evita dependencias circulares.

**¿Cómo funciona el guardado?**
> 3 slots `.dat`. Guarda nivel, checkpoint, muertes, tiempo, score y estado del nivel. `LevelStateManager` restaura qué enemigos cayeron y qué puertas se abrieron.

**¿Cómo funciona el checkpoint?**
> `SmartCheckpointSystem` busca la zona segura más cercana al punto de muerte y hace raycast hacia abajo para encontrar suelo sólido.

**¿Cómo está implementada la IA?**
> FSM con 7 estados. Transiciones basadas en distancia y raycast de línea de visión. Recuerda la última posición del jugador 2.5s antes de volver a patrullar.

**¿Es escalable el sistema de puertas?**
> Sí. Cada puerta es una escena independiente. Para agregar un tipo nuevo, se crea una escena nueva que usa los métodos públicos de Kai (`consume_energy()`, `use_tool()`). Sin tocar código existente.

---

## RESUMEN RÁPIDO

| | |
|-|-|
| Motor | Godot 4.6, GDScript |
| Género | Plataformero 2D acción/puzzle |
| Protagonista | Kai, técnico de mantenimiento |
| Niveles | 5 + epílogo |
| Recursos | Salud (3 corazones), Stamina, Energía |
| Enemigos | Ukibuki — FSM 7 estados + Line-of-Sight |
| Patrones | Singleton, FSM, Observer, Template Method, Strategy |
| Guardado | 3 slots, persistencia de estado de nivel |
| Scripts | 53 `.gd` · Escenas: 37 `.tscn` |

---

*NK-7 — Ingeniería de Software*
