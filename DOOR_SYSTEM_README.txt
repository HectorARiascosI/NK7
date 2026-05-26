════════════════════════════════════════════════════════════════════════════════
SISTEMA DE PUERTAS ELECTRIFICADAS NK-7 - GUÍA DE IMPLEMENTACIÓN
════════════════════════════════════════════════════════════════════════════════

VERSIÓN: 1.0
FECHA: 2026-05-05
AUTOR: Sistema de IA - Kiro

════════════════════════════════════════════════════════════════════════════════
📋 TABLA DE CONTENIDOS
════════════════════════════════════════════════════════════════════════════════

1. Archivos Creados
2. Configuración del Spritesheet
3. Cómo Usar en Tu Nivel
4. Ejemplos de Configuración
5. Integración con Interruptores
6. Troubleshooting
7. Próximos Pasos

════════════════════════════════════════════════════════════════════════════════
1. 📁 ARCHIVOS CREADOS
════════════════════════════════════════════════════════════════════════════════

SCRIPTS:
├── scripts/objects/electric_door.gd          [PRINCIPAL - Sistema de puerta]
├── scripts/characters/kai.gd                 [ACTUALIZADO - Sistema de recursos]
├── scripts/ui/player_hud.gd                  [NUEVO - HUD de recursos]
└── scripts/levels/test_doors_setup.gd        [EJEMPLO - Configuración de nivel]

ESCENAS:
├── scenes/objects/electric_door.tscn         [Prefab de puerta]
├── scenes/ui/player_hud.tscn                 [HUD del jugador]
└── scenes/levels/test_doors_level.tscn       [Nivel de prueba]

RECURSOS:
├── assets/particles/repair_sparks.tres       [Partículas de reparación]
└── assets/particles/electric_sparks.tres     [Partículas eléctricas]

DOCUMENTACIÓN:
├── DOOR_SYSTEM_DESIGN.txt                    [Diseño técnico completo]
└── DOOR_SYSTEM_README.txt                    [Este archivo]

════════════════════════════════════════════════════════════════════════════════
2. 🎨 CONFIGURACIÓN DEL SPRITESHEET
════════════════════════════════════════════════════════════════════════════════

IMPORTANTE: Debes configurar el spritesheet de puertas manualmente en Godot.

ARCHIVO: assets/objects/doors.png (el que proporcionaste)

ESTRUCTURA DEL SPRITESHEET:
┌─────────────────────────────────────────────────────────────────────────────┐
│ FILA 1 (Y=0): Secuencia de apertura                                         │
├─────────────────────────────────────────────────────────────────────────────┤
│ Frame 0 (X=0):     Cerrada, luz roja (LOCKED_DAMAGED)                      │
│ Frame 1 (X=192):   Cerrada, luz amarilla (LOCKED_FIXED)                    │
│ Frame 2 (X=384):   Desbloqueando, chispas 1 (UNLOCKING)                    │
│ Frame 3 (X=576):   Desbloqueando, chispas 2 (UNLOCKING)                    │
│ Frame 4 (X=768):   Abierta, luz verde (OPEN)                               │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│ FILA 2 (Y=312): Estados especiales                                          │
├─────────────────────────────────────────────────────────────────────────────┤
│ Frame 0 (X=0):     Panel apagado                                            │
│ Frame 1 (X=192):   Panel activo                                             │
│ Frame 2 (X=384):   Electrificada (rayos)                                    │
│ Frame 3 (X=576):   Abierta completamente                                    │
└─────────────────────────────────────────────────────────────────────────────┘

DIMENSIONES:
- Tamaño de cada frame: 192x312 píxeles
- Total de frames: 9 (5 en fila 1, 4 en fila 2)

PASOS PARA CONFIGURAR EN GODOT:

1. Abre: scenes/objects/electric_door.tscn

2. Selecciona el nodo "Sprite" (AnimatedSprite2D)

3. En el Inspector, ve a "Sprite Frames"

4. Para cada animación, configura los frames usando AtlasTexture:
   - locked_damaged: Frame (0, 0)
   - locked_fixed: Frame (192, 0)
   - unlocking: Frames (384, 0) y (576, 0) alternando
   - opening: Secuencia (384, 0) → (576, 0) → (768, 0)
   - open: Frame (768, 0)
   - closing: Secuencia inversa (768, 0) → (576, 0) → (192, 0)
   - electrified: Frame (384, 312)

5. Ajusta las velocidades de animación:
   - locked_damaged: 2 FPS (parpadeo lento)
   - unlocking: 8 FPS (chispas rápidas)
   - opening/closing: 6 FPS (movimiento suave)

════════════════════════════════════════════════════════════════════════════════
3. 🎮 CÓMO USAR EN TU NIVEL
════════════════════════════════════════════════════════════════════════════════

MÉTODO 1: Arrastrar y Soltar (Más Fácil)
─────────────────────────────────────────

1. Abre tu escena de nivel en Godot
2. Arrastra "scenes/objects/electric_door.tscn" a la escena
3. Posiciona la puerta donde quieras
4. En el Inspector, configura los parámetros exportados
5. ¡Listo!

MÉTODO 2: Por Código (Más Flexible)
────────────────────────────────────

```gdscript
extends Node2D

func _ready():
    # Crear puerta
    var door = preload("res://scenes/objects/electric_door.tscn").instantiate()
    
    # Posicionar
    door.position = Vector2(500, 300)
    
    # Configurar
    door.damage_level = 2  # MEDIUM (2 pasos)
    door.starts_electrified = false
    door.auto_close = false
    
    # Añadir a escena
    add_child(door)
    
    # Conectar señales (opcional)
    door.door_opened.connect(_on_door_opened)
    door.player_damaged.connect(_on_player_hurt)

func _on_door_opened():
    print("¡Puerta abierta!")

func _on_player_hurt():
    print("¡Jugador dañado!")
```

AÑADIR HUD DEL JUGADOR:
───────────────────────

En tu escena de nivel, añade:

```gdscript
# Método 1: En el editor
# Arrastra scenes/ui/player_hud.tscn como hijo de un CanvasLayer

# Método 2: Por código
func _ready():
    var hud = preload("res://scenes/ui/player_hud.tscn").instantiate()
    add_child(hud)
```

════════════════════════════════════════════════════════════════════════════════
4. ⚙️ EJEMPLOS DE CONFIGURACIÓN
════════════════════════════════════════════════════════════════════════════════

EJEMPLO 1: Puerta Tutorial (Fácil)
───────────────────────────────────
```gdscript
door.damage_level = 1              # LIGHT - 1 paso
door.repair_time_per_step = 1.5    # Rápido
door.tool_durability_cost = 5      # Bajo coste
door.starts_electrified = false
```

EJEMPLO 2: Puerta Normal
─────────────────────────
```gdscript
door.damage_level = 2              # MEDIUM - 2 pasos
door.repair_time_per_step = 2.0
door.tool_durability_cost = 10
door.starts_electrified = false
```

EJEMPLO 3: Puerta Difícil
──────────────────────────
```gdscript
door.damage_level = 3              # HEAVY - 3 pasos
door.repair_time_per_step = 2.5
door.tool_durability_cost = 15
door.door_weight = 150.0           # Abre más lento
door.starts_electrified = false
```

EJEMPLO 4: Puerta Electrificada
────────────────────────────────
```gdscript
door.damage_level = 2
door.starts_electrified = true     # ¡PELIGRO!
door.electrified_damage = 25       # Daño al tocar
```

EJEMPLO 5: Puerta con Auto-Cierre
──────────────────────────────────
```gdscript
door.damage_level = 0              # Sin daños
door.auto_close = true
door.auto_close_delay = 3.0        # Cierra en 3 segundos
```

EJEMPLO 6: Puerta Controlada por Interruptor
─────────────────────────────────────────────
```gdscript
# La puerta se abre solo con interruptor externo
door.damage_level = 0
door.requires_energy = true
door.can_be_forced = false

# El interruptor la activará
var switch = preload("res://scenes/objects/switch.tscn").instantiate()
switch.targets = [door.get_path()]
add_child(switch)
```

════════════════════════════════════════════════════════════════════════════════
5. 🔌 INTEGRACIÓN CON INTERRUPTORES
════════════════════════════════════════════════════════════════════════════════

Las puertas son compatibles con el sistema de interruptores existente.

CONFIGURACIÓN EN EDITOR:
────────────────────────

1. Crea un Switch (scenes/objects/switch.tscn)
2. En el Inspector del Switch, ve a "Targets"
3. Añade el NodePath de la puerta
4. ¡Listo! El interruptor controlará la puerta

CONFIGURACIÓN POR CÓDIGO:
─────────────────────────

```gdscript
# Crear puerta
var door = preload("res://scenes/objects/electric_door.tscn").instantiate()
door.name = "MyDoor"
door.position = Vector2(500, 300)
add_child(door)

# Crear interruptor
var switch = preload("res://scenes/objects/switch.tscn").instantiate()
switch.position = Vector2(300, 350)
switch.targets = [door.get_path()]  # Conectar al path de la puerta
add_child(switch)
```

MÉTODOS DISPONIBLES PARA INTERRUPTORES:
────────────────────────────────────────

```gdscript
door.activate()      # Abrir puerta (desde interruptor)
door.deactivate()    # Cerrar puerta
door.force_open()    # Forzar apertura (bypass)
door.electrify()     # Electrificar puerta
door.de_electrify()  # Quitar electricidad
```

════════════════════════════════════════════════════════════════════════════════
6. 🔧 TROUBLESHOOTING
════════════════════════════════════════════════════════════════════════════════

PROBLEMA: La puerta no aparece
───────────────────────────────
SOLUCIÓN:
- Verifica que el spritesheet esté en assets/objects/doors.png
- Asegúrate de haber configurado los frames en AnimatedSprite2D
- Revisa que la escena electric_door.tscn esté correctamente guardada

PROBLEMA: Las animaciones no funcionan
───────────────────────────────────────
SOLUCIÓN:
- Abre electric_door.tscn
- Selecciona el nodo Sprite
- Verifica que SpriteFrames tenga todas las animaciones configuradas
- Asegúrate de que los AtlasTexture apunten a las regiones correctas

PROBLEMA: El jugador no puede reparar
──────────────────────────────────────
SOLUCIÓN:
- Verifica que kai.gd tenga las nuevas variables de recursos
- Asegúrate de que tool_durability > 0
- Revisa que el InteractionArea de la puerta esté configurado
- Verifica que las capas de colisión sean correctas (Layer 0, Mask 1)

PROBLEMA: El HUD no muestra los recursos
─────────────────────────────────────────
SOLUCIÓN:
- Asegúrate de que player_hud.tscn esté añadido a la escena
- Verifica que el jugador esté en el grupo "player"
- Revisa que los métodos get_health_percent(), etc. existan en kai.gd

PROBLEMA: Las partículas no se ven
───────────────────────────────────
SOLUCIÓN:
- Verifica que los archivos .tres estén en assets/particles/
- Asegúrate de que los GPUParticles2D tengan process_material asignado
- Revisa que emitting se active correctamente en el código

PROBLEMA: La puerta no responde a interruptores
────────────────────────────────────────────────
SOLUCIÓN:
- Verifica que el NodePath en switch.targets sea correcto
- Asegúrate de que la puerta tenga los métodos activate()/deactivate()
- Revisa que el interruptor esté configurado correctamente

════════════════════════════════════════════════════════════════════════════════
7. 🚀 PRÓXIMOS PASOS
════════════════════════════════════════════════════════════════════════════════

PASO 1: Probar el Sistema
──────────────────────────
1. Abre scenes/levels/test_doors_level.tscn
2. Presiona F5 para ejecutar
3. Prueba cada puerta y sus mecánicas
4. Revisa la consola para ver los logs de debug

PASO 2: Configurar Sprites
───────────────────────────
1. Abre scenes/objects/electric_door.tscn
2. Configura los frames del AnimatedSprite2D según la sección 2
3. Guarda la escena

PASO 3: Integrar en Tu Nivel
─────────────────────────────
1. Abre tu nivel existente (ej: level_01.tscn)
2. Añade puertas donde las necesites
3. Configura sus parámetros según el gameplay deseado
4. Añade el PlayerHUD si no lo tienes

PASO 4: Crear Puzzles
──────────────────────
1. Combina puertas con interruptores
2. Crea secuencias de puertas con recursos limitados
3. Añade puertas electrificadas como obstáculos peligrosos
4. Diseña desafíos de timing con auto_close

PASO 5: Añadir Sonidos
───────────────────────
1. Crea/importa archivos de audio:
   - repair_start.ogg
   - repair_complete.ogg
   - hack_start.ogg
   - hack_complete.ogg
   - door_opening.ogg
   - door_closing.ogg
   - electric_shock.ogg

2. Actualiza el método _play_sound() en electric_door.gd:
```gdscript
func _play_sound(sound_name: String) -> void:
    if not play_sounds or not audio_player:
        return
    
    var sound_path := "res://assets/sounds/" + sound_name + ".ogg"
    if ResourceLoader.exists(sound_path):
        audio_player.stream = load(sound_path)
        audio_player.volume_db = linear_to_db(sound_volume)
        audio_player.play()
```

PASO 6: Balancear Recursos
───────────────────────────
1. Juega tu nivel completo
2. Ajusta los costes de durabilidad
3. Coloca kits de reparación estratégicamente
4. Balancea la dificultad de cada puerta

PASO 7: Pulir Visuales
───────────────────────
1. Ajusta los colores de las luces
2. Refina las partículas
3. Añade shaders si es necesario
4. Optimiza el rendimiento

════════════════════════════════════════════════════════════════════════════════
📞 SOPORTE Y DOCUMENTACIÓN ADICIONAL
════════════════════════════════════════════════════════════════════════════════

Para más información técnica detallada, consulta:
- DOOR_SYSTEM_DESIGN.txt (Diseño técnico completo)

Para ver ejemplos de código:
- scripts/levels/test_doors_setup.gd (Configuración de ejemplo)

Para debugging:
- Usa las teclas 1-4 en el nivel de prueba para forzar puertas
- Usa R para reiniciar el nivel
- Usa H para restaurar recursos del jugador

════════════════════════════════════════════════════════════════════════════════
✅ CHECKLIST DE IMPLEMENTACIÓN
════════════════════════════════════════════════════════════════════════════════

□ Spritesheet configurado en electric_door.tscn
□ Todas las animaciones funcionan correctamente
□ Sistema de recursos integrado en kai.gd
□ PlayerHUD añadido y funcionando
□ Nivel de prueba ejecutado exitosamente
□ Puertas añadidas a tu nivel principal
□ Interruptores conectados correctamente
□ Sonidos añadidos (opcional)
□ Partículas visibles y funcionando
□ Gameplay balanceado y testeado

════════════════════════════════════════════════════════════════════════════════
¡SISTEMA COMPLETO Y LISTO PARA USAR!
════════════════════════════════════════════════════════════════════════════════

Este sistema de puertas electrificadas está diseñado con estándares profesionales
de la industria de videojuegos, incluyendo:

✓ Arquitectura modular y extensible
✓ Sistema de estados robusto
✓ Feedback visual y auditivo claro
✓ Integración profunda con mecánicas del jugador
✓ Configuración flexible por nivel
✓ Optimización de rendimiento
✓ Documentación completa

¡Disfruta creando puzzles y desafíos increíbles con este sistema!

════════════════════════════════════════════════════════════════════════════════
