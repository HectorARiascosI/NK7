# Architecture Document — NK-7

## Project Structure
`
NK7/
├── assets/          # All game assets (sprites, backgrounds, UI, shaders)
├── scenes/          # Godot scene files (.tscn)
│   ├── characters/  # Kai, Rena
│   ├── enemies/     # Ukibuki, projectile
│   ├── levels/      # level_01 through level_05
│   ├── objects/     # Interactive objects (doors, lasers, switches)
│   └── ui/          # All UI screens and HUD
├── scripts/         # GDScript files (.gd)
│   ├── autoload/    # Global singletons
│   ├── camera/      # SmartCamera
│   ├── characters/  # Player scripts
│   ├── enemies/     # Enemy AI
│   ├── levels/      # Level management
│   ├── objects/     # Interactive object scripts
│   └── ui/          # UI scripts
└── docs/            # Technical documentation
`

## Design Patterns Applied

### Singleton (Autoloads)
- GameManager, AudioManager, LevelStateManager, AchievementManager
- Single point of access to global state
- Reduces coupling between scenes

### Finite State Machine (FSM)
- Ukibuki AI: IDLE→PATROL→ALERT→CHASE→ATTACK→DAMAGED→DESTROYED
- Electric door: LOCKED_DAMAGED→REPAIRING→LOCKED_FIXED→UNLOCKING→OPENING→OPEN

### Observer (Godot Signals)
- door_opened, player_detected, level_completed, checkpoint_reached
- Decouples event producers from consumers

### Template Method
- level_base.gd defines skeleton; level_XX_setup.gd implements specifics

### Component
- Kai's mechanics are independent: health, stamina, energy, climbing

## Save System
- 3 independent slots (save_slot_0.dat, save_slot_1.dat, save_slot_2.dat)
- Persists: level, checkpoint, deaths, time, score, level state
- LevelStateManager tracks per-level state (enemies defeated, doors opened)

## Transition System
- GameManager.transition_to_level(n) handles all level changes
- Black fade overlay (CanvasLayer layer=128)
- Configurable fade duration
