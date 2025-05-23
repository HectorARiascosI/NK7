# NK-7 — Videojuego 2D de Acción y Puzzle

> *"No llegó por ambición. Llegó porque era bueno en los sistemas."*

## Descripción

NK-7 es un plataformero 2D de acción y puzzle desarrollado en **Godot 4.6** con GDScript. El jugador controla a **Kai**, un técnico de mantenimiento atrapado en una planta de fusión nuclear tras un fallo catastrófico del sistema de control.

## Tecnologías

| Tecnología | Versión |
|-----------|---------|
| Godot Engine | 4.6 stable |
| GDScript | 2.0 |
| Jolt Physics | Integrado |
| Resolución | 1280×720 |

## Estructura del Proyecto

`
NK7/
├── assets/          # Sprites, fondos, UI, shaders
├── scenes/          # Escenas Godot (.tscn)
├── scripts/         # Lógica del juego (.gd)
├── docs/            # Documentación técnica
└── .godot/          # Cache de Godot (ignorado en git)
`

## Mecánicas Principales

- **Sistema de recursos triple:** Salud (3 corazones), Stamina, Energía
- **IA de enemigos:** FSM con 7 estados + Line-of-Sight via Raycast
- **Sistema de puertas:** 6 tipos con estados y recursos requeridos
- **Guardado:** 3 slots con persistencia de estado de nivel
- **Checkpoints inteligentes:** Respawn en zona segura más cercana

## Patrones de Diseño

- **Singleton** — 6 autoloads globales (GameManager, AudioManager, etc.)
- **FSM** — IA de Ukibuki y sistema de puertas electrificadas
- **Observer** — Señales de Godot para comunicación entre sistemas
- **Template Method** — level_base.gd como base para todos los niveles
- **Component** — Mecánicas de Kai como sistemas independientes

## Controles

| Acción | Tecla |
|--------|-------|
| Mover | A / D |
| Saltar | Espacio |
| Correr | Shift |
| Agacharse | Ctrl |
| Escalar | W / S |
| Interactuar | E |
| Hackear | Q |
| Atacar | F |
| Pausa | Escape |

## Equipo

| Integrante | Rol |
|-----------|-----|
| Hector | Arquitectura, sistemas técnicos, transiciones |
| Tatiana | UI/UX, sprites, historia, HUD |
| Sebastian | Diseño de niveles, checkpoints, tutorial |
| Steven | Física, enemigos, objetos interactivos |

## Instalación

1. Clonar el repositorio
2. Abrir con Godot 4.6
3. Ejecutar la escena principal (F5)
