# Physics & Movement Technical Notes — NK-7

## Kai Movement Constants
| Parameter | Value | Notes |
|-----------|-------|-------|
| SPEED | 120 px/s | Base walk speed |
| RUN_SPEED | 230 px/s | Sprint speed |
| CROUCH_SPEED | 60 px/s | Crouch walk |
| CLIMB_SPEED | 80 px/s | Ladder climb |
| CLIMB_RUN_SPEED | 160 px/s | Fast ladder climb |
| JUMP_FORCE | -305 | Normal jump |
| JUMP_FORCE_RUNNING | -345 | Running jump |
| GRAVITY | 980 | Standard gravity |
| FALL_GRAVITY_MULT | 1.2 | Faster fall |
| AIR_CONTROL | 0.85 | Air movement factor |

## Stamina Degradation on Run
- Speed degrades linearly when stamina < 20
- Formula: lerp(SPEED, RUN_SPEED, stamina_factor)
- stamina_factor = clamp(stamina / 20.0, 0.0, 1.0)

## Jump Buffer / Coyote Time
- Implemented in movement iteration commits
- Allows jump input slightly before/after leaving platform

## Collision Layers
- Layer 1: World geometry (floors, walls)
- Layer 2: Player
- Layer 3: Enemies
- Layer 4: Projectiles
- Layer 5: Interactables (doors, switches, ladders)
