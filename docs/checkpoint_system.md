# Checkpoint & Respawn System — NK-7

## SmartCheckpointSystem

### Philosophy
Unlike traditional fixed checkpoints, NK-7 uses a dynamic respawn system
that finds the nearest safe zone to where the player died.

### How It Works
1. On level load: scans all nodes in group 'safe_zones'
2. Player enters SafeZone Area2D → updates _last_safe_position
3. Player dies → SmartCheckpointSystem.register_death(position)
4. Calculates best respawn:
   - If died inside a safe zone → respawn there
   - Otherwise → use _last_safe_position
   - Fallback → _initial_spawn (level start)
5. Raycast downward from respawn point to find solid ground

### SafeZone Placement Guidelines
- Place at natural rest points (after clearing an area)
- Minimum 1 safe zone per floor section
- Avoid placing near hazards or enemy patrol routes
- Size: minimum 150x80px to ensure reliable detection

### Level 01 Safe Zones
| Zone ID | Position | Description |
|---------|----------|-------------|
| 1 | (-535, 326) | Spawn point (floor 1 left) |
| 2 | (-106, 346) | Floor 1 center |
| 3 | (100, 360) | Floor 1 right |
| 4 | (-400, 90) | Floor 2 left |
| 5 | (0, 90) | Floor 2 center |
| 6 | (291, 60) | Floor 2 right |
| 7 | (-400, -160) | Floor 3 left |
| 8 | (0, -160) | Floor 3 center |
| 9 | (245, -227) | Floor 3 exit area |
