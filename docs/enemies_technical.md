# Ukibuki Enemy System — Technical Notes

## AI State Machine
- States: IDLE, PATROL, ALERT, CHASE, ATTACK, DAMAGED, DESTROYED
- Line-of-Sight via PhysicsRayQueryParameters2D
- Lost sight timeout: 2.5s before returning to patrol

## Projectile System
- Speed: 210 px/s
- Parry window: activated by projectile script
- Visual: sprite from ukibuki spritesheet frames 12-15

## Tuning Values
- detection_range: 320px
- attack_range: 260px  
- attack_cooldown: 2.2s
- chase_speed_mult: 1.4x
