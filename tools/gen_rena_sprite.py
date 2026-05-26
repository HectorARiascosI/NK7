#!/usr/bin/env python3
"""
Genera el spritesheet placeholder de RENA para NK-7.
Técnica de control, 28 años, traje negro con detalles naranja.
Misma estructura que Kai: 14 animaciones, 48x48 px por frame.
Tira horizontal: idle(4), walk(6), run(8), jump(4), fall(2),
                 crouch(2), climb(4), hurt(3), dead(4),
                 hack(4), use_tool(4), communicate(3), push(3), attack(4)
Total: 55 frames → 2640x48
"""

from PIL import Image, ImageDraw
import math
import os

FRAME_W = 48
FRAME_H = 48

ANIMS = {
    "idle":        4,
    "walk":        6,
    "run":         8,
    "jump":        4,
    "fall":        2,
    "crouch":      2,
    "climb":       4,
    "hurt":        3,
    "dead":        4,
    "hack":        4,
    "use_tool":    4,
    "communicate": 3,
    "push":        3,
    "attack":      4,
}
TOTAL_FRAMES = sum(ANIMS.values())

# Paleta RENA
C_SUIT      = (20,  20,  28,  255)   # Traje negro
C_SUIT_DARK = (10,  10,  16,  255)   # Sombras
C_ORANGE    = (255, 130, 30,  255)   # Detalles naranja
C_ORANGE_L  = (255, 180, 80,  255)   # Naranja claro
C_SKIN      = (220, 175, 140, 255)   # Piel
C_HAIR      = (40,  30,  20,  255)   # Cabello oscuro
C_VISOR     = (80,  200, 255, 180)   # Visor azul
C_BOOT      = (30,  30,  40,  255)   # Botas
C_TRANS     = (0,   0,   0,   0)


def draw_rena(draw, cx, cy, pose="idle", frame=0):
    """Dibuja a RENA en la pose indicada."""
    # Offset de animación
    bob = int(math.sin(frame * math.pi / 2) * 1.5) if pose in ("idle", "walk") else 0
    
    # Piernas
    leg_spread = {"idle": 2, "walk": 4, "run": 6, "crouch": 8, "jump": 3}.get(pose, 2)
    leg_anim = int(math.sin(frame * math.pi / 2) * leg_spread) if pose in ("walk", "run") else 0
    
    # Pierna izquierda
    draw.rectangle([cx - 8, cy + 14 + bob, cx - 3, cy + 26 + bob + leg_anim],
                   fill=C_SUIT)
    # Pierna derecha
    draw.rectangle([cx + 3, cy + 14 + bob, cx + 8, cy + 26 + bob - leg_anim],
                   fill=C_SUIT)
    # Botas
    draw.rectangle([cx - 9, cy + 24 + bob + leg_anim, cx - 2, cy + 28 + bob + leg_anim],
                   fill=C_BOOT)
    draw.rectangle([cx + 2, cy + 24 + bob - leg_anim, cx + 9, cy + 28 + bob - leg_anim],
                   fill=C_BOOT)
    
    # Cuerpo
    body_y = cy + bob
    if pose == "crouch":
        body_y = cy + 6
    draw.rounded_rectangle([cx - 10, body_y, cx + 10, body_y + 16],
                            radius=3, fill=C_SUIT)
    # Detalle naranja en pecho
    draw.rectangle([cx - 6, body_y + 3, cx + 6, body_y + 6], fill=C_ORANGE)
    # Línea lateral naranja
    draw.line([cx - 10, body_y + 2, cx - 10, body_y + 14], fill=C_ORANGE, width=2)
    draw.line([cx + 10, body_y + 2, cx + 10, body_y + 14], fill=C_ORANGE, width=2)
    
    # Brazos
    arm_anim = int(math.sin(frame * math.pi / 2) * 3) if pose in ("walk", "run") else 0
    if pose == "hack":
        arm_r_y = body_y - 2
        arm_l_y = body_y + 4
    elif pose == "use_tool":
        arm_r_y = body_y - 4
        arm_l_y = body_y + 2
    else:
        arm_r_y = body_y + arm_anim
        arm_l_y = body_y - arm_anim
    
    draw.rectangle([cx - 14, arm_l_y, cx - 10, arm_l_y + 10], fill=C_SUIT)
    draw.rectangle([cx + 10, arm_r_y, cx + 14, arm_r_y + 10], fill=C_SUIT)
    # Guantes naranja
    draw.rectangle([cx - 15, arm_l_y + 8, cx - 9, arm_l_y + 13], fill=C_ORANGE)
    draw.rectangle([cx + 9, arm_r_y + 8, cx + 15, arm_r_y + 13], fill=C_ORANGE)
    
    # Cabeza
    head_y = body_y - 14
    draw.ellipse([cx - 8, head_y, cx + 8, head_y + 14], fill=C_SKIN)
    # Cabello
    draw.ellipse([cx - 8, head_y, cx + 8, head_y + 8], fill=C_HAIR)
    # Visor (casco técnico)
    draw.rectangle([cx - 7, head_y + 5, cx + 7, head_y + 9], fill=C_VISOR)
    # Detalle naranja en casco
    draw.line([cx - 8, head_y + 2, cx + 8, head_y + 2], fill=C_ORANGE, width=1)


def generate_rena_sheet():
    sheet = Image.new("RGBA", (FRAME_W * TOTAL_FRAMES, FRAME_H), C_TRANS)
    
    frame_x = 0
    for anim_name, frame_count in ANIMS.items():
        for f in range(frame_count):
            frame = Image.new("RGBA", (FRAME_W, FRAME_H), C_TRANS)
            draw = ImageDraw.Draw(frame)
            cx = FRAME_W // 2
            cy = FRAME_H // 2 + 4
            draw_rena(draw, cx, cy, pose=anim_name, frame=f)
            sheet.paste(frame, (frame_x, 0))
            frame_x += FRAME_W
    
    out_dir = os.path.join(os.path.dirname(__file__), "..", "assets", "characters", "rena")
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, "rena_spritesheet.png")
    sheet.save(out_path)
    print(f"Spritesheet RENA generado: {out_path}")
    print(f"Tamaño: {sheet.size[0]}x{sheet.size[1]} px, {TOTAL_FRAMES} frames")
    return out_path


if __name__ == "__main__":
    generate_rena_sheet()
