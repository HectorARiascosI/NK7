# Level Design Document — NK-7

## Level 01 — Sector B (Demo)
- **Theme:** Underground maintenance sector, emergency lighting
- **Floors:** 3 vertical floors connected by ladders
- **Hazards:** 2 vertical lasers, death pit, electric zones
- **Enemies:** 2 Ukibuki security robots
- **Key mechanic:** Laser switch puzzle (floor 2 switch → floor 3 laser)
- **Exit:** Level door at floor 3 right → Level 02

## Level 02 — Sector 7-F Security  
- **Theme:** Security checkpoint, high voltage warning
- **Floors:** 3 floors, wider layout
- **Enemies:** 2 Ukibuki with patrol routes
- **Entry:** Left side floor 1 (from Level 01)
- **Safe zones:** 4 checkpoints distributed across floors

## Checkpoint Philosophy
- SmartCheckpointSystem finds nearest safe zone to death point
- Raycast downward to ensure solid ground spawn
- No fixed respawn points — dynamic based on player position

## Difficulty Curve
Level 01: Tutorial mechanics, single laser puzzle
Level 02: Multiple enemies, resource management
Level 03-05: Progressive complexity (planned)
