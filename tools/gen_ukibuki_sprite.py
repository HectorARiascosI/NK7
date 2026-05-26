#!/usr/bin/env python3
"""
Genera el spritesheet del Ukibuki para NK-7.
Robot flotante corrupto: cuerpo hexagonal, ojo central rojo, antenas.
Tamaño de frame: 64x64 px
Animaciones (6): idle(4f), move(4f), alert(4f), shoot(4f), damage(3f), explosion(5f)
Total: 24 frames en una tira horizontal (1536x64)
"""

from PIL import Image, ImageDraw
import math
import os

FRAME_W = 64
FRAME_H = 64
FRAMES = {
    "idle":      4,
    "move":      4,
    "alert":     4,
    "shoot":     4,
    "damage":    3,
    "explosion": 5,
}
TOTAL_FRAMES = sum(FRAMES.values())  # 24

# Paleta NK-7 Ukibuki
C_BODY      = (40,  55,  70,  255)   # Gris azulado oscuro
C_BODY_DARK = (25,  35,  45,  255)   # Más oscuro para sombras
C_ACCENT    = (200, 60,  60,  255)   # Rojo corrupto
C_EYE       = (255, 80,  80,  255)   # Ojo rojo brillante
C_EYE_GLOW  = (255, 160, 160, 180)   # Halo del ojo
C_ANTENNA   = (80,  120, 160, 255)   # Antenas azul-gris
C_PANEL     = (55,  75,  95,  255)   # Paneles laterales
C_ALERT     = (255, 160, 40,  255)   # Naranja alerta
C_SHOOT     = (255, 220, 80,  255)   # Amarillo disparo
C_DAMAGE    = (255, 100, 100, 255)   # Rojo daño
C_SPARK     = (200, 220, 255, 255)   # Chispas
C_TRANS     = (0,   0,   0,   0)     # Transparente


def draw_ukibuki_base(draw, cx, cy, body_color=C_BODY, eye_color=C_EYE, scale=1.0):
    """Dibuja el cuerpo base del Ukibuki."""
    bw = int(28 * scale)
    bh = int(22 * scale)
    
    # Cuerpo hexagonal (simulado con rectángulo redondeado)
    body_rect = [cx - bw, cy - bh, cx + bw, cy + bh]
    draw.rounded_rectangle(body_rect, radius=int(8 * scale), fill=body_color)
    
    # Sombra inferior
    shadow_rect = [cx - bw + 2, cy + bh - 4, cx + bw - 2, cy + bh + 2]
    draw.rounded_rectangle(shadow_rect, radius=3, fill=C_BODY_DARK)
    
    # Paneles laterales
    panel_l = [cx - bw - 4, cy - int(8 * scale), cx - bw + 2, cy + int(8 * scale)]
    panel_r = [cx + bw - 2, cy - int(8 * scale), cx + bw + 4, cy + int(8 * scale)]
    draw.rectangle(panel_l, fill=C_PANEL)
    draw.rectangle(panel_r, fill=C_PANEL)
    
    # Líneas de detalle en el cuerpo
    for i in range(-1, 2):
        lx = cx + i * int(9 * scale)
        draw.line([lx, cy - bh + 4, lx, cy + bh - 4], fill=C_BODY_DARK, width=1)
    
    # Antenas
    ant_h = int(12 * scale)
    draw.line([cx - int(8 * scale), cy - bh, cx - int(12 * scale), cy - bh - ant_h],
              fill=C_ANTENNA, width=2)
    draw.line([cx + int(8 * scale), cy - bh, cx + int(12 * scale), cy - bh - ant_h],
              fill=C_ANTENNA, width=2)
    # Puntas de antenas
    draw.ellipse([cx - int(14 * scale) - 2, cy - bh - ant_h - 2,
                  cx - int(10 * scale) + 2, cy - bh - ant_h + 2], fill=C_ACCENT)
    draw.ellipse([cx + int(10 * scale) - 2, cy - bh - ant_h - 2,
                  cx + int(14 * scale) + 2, cy - bh - ant_h + 2], fill=C_ACCENT)
    
    # Ojo central (halo + núcleo)
    eye_r = int(7 * scale)
    draw.ellipse([cx - eye_r - 3, cy - eye_r - 3, cx + eye_r + 3, cy + eye_r + 3],
                 fill=C_EYE_GLOW)
    draw.ellipse([cx - eye_r, cy - eye_r, cx + eye_r, cy + eye_r], fill=eye_color)
    draw.ellipse([cx - int(3 * scale), cy - int(3 * scale),
                  cx + int(3 * scale), cy + int(3 * scale)], fill=(255, 255, 255, 200))
    
    # Acento rojo en bordes
    draw.rounded_rectangle([cx - bw, cy - bh, cx + bw, cy + bh],
                            radius=int(8 * scale), outline=C_ACCENT, width=2)


def gen_idle_frame(draw, cx, cy, frame_idx):
    """Idle: flotación suave, ojo parpadeando."""
    float_y = int(math.sin(frame_idx * math.pi / 2) * 2)
    eye_color = C_EYE if frame_idx != 3 else (180, 40, 40, 255)
    draw_ukibuki_base(draw, cx, cy + float_y, eye_color=eye_color)


def gen_move_frame(draw, cx, cy, frame_idx):
    """Move: inclinación lateral + flotación."""
    float_y = int(math.sin(frame_idx * math.pi / 2) * 3)
    lean = [-2, 0, 2, 0][frame_idx]
    draw_ukibuki_base(draw, cx + lean, cy + float_y)
    # Estela de movimiento
    for i in range(1, 3):
        alpha = int(80 / i)
        trail_color = (*C_BODY[:3], alpha)
        draw.ellipse([cx - 20 - i * 4, cy + float_y - 8,
                      cx - 20 + 4, cy + float_y + 8], fill=trail_color)


def gen_alert_frame(draw, cx, cy, frame_idx):
    """Alert: ojo naranja parpadeante, antenas activas."""
    float_y = int(math.sin(frame_idx * math.pi) * 2)
    eye_color = C_ALERT if frame_idx % 2 == 0 else (255, 200, 80, 255)
    draw_ukibuki_base(draw, cx, cy + float_y, eye_color=eye_color)
    # Pulso de alerta
    if frame_idx % 2 == 0:
        pulse_r = 12 + frame_idx * 2
        draw.ellipse([cx - pulse_r, cy - pulse_r, cx + pulse_r, cy + pulse_r],
                     outline=(*C_ALERT[:3], 120), width=2)


def gen_shoot_frame(draw, cx, cy, frame_idx):
    """Shoot: carga y disparo."""
    float_y = int(math.sin(frame_idx * math.pi / 2) * 1)
    draw_ukibuki_base(draw, cx, cy + float_y, eye_color=C_SHOOT)
    
    if frame_idx == 2:
        # Carga máxima
        draw.ellipse([cx - 14, cy - 14, cx + 14, cy + 14],
                     outline=(*C_SHOOT[:3], 180), width=3)
    elif frame_idx == 3:
        # Disparo: proyectil saliendo
        for i in range(4):
            px = cx + 30 + i * 6
            draw.ellipse([px - 4, cy - 4, px + 4, cy + 4], fill=C_SHOOT)


def gen_damage_frame(draw, cx, cy, frame_idx):
    """Damage: flash rojo, cuerpo dañado."""
    float_y = [-3, 3, -1][frame_idx]
    body_color = [C_DAMAGE, C_BODY_DARK, C_BODY][frame_idx]
    draw_ukibuki_base(draw, cx, cy + float_y, body_color=body_color, eye_color=C_DAMAGE)
    # Chispas
    if frame_idx == 0:
        for i in range(5):
            angle = i * 72 * math.pi / 180
            sx = cx + int(math.cos(angle) * 20)
            sy = cy + int(math.sin(angle) * 20)
            draw.ellipse([sx - 2, sy - 2, sx + 2, sy + 2], fill=C_SPARK)


def gen_explosion_frame(draw, cx, cy, frame_idx):
    """Explosion: expansión y desvanecimiento."""
    radii = [8, 16, 24, 32, 40]
    alphas = [255, 220, 160, 80, 20]
    r = radii[frame_idx]
    a = alphas[frame_idx]
    
    if frame_idx < 3:
        # Cuerpo fragmentado
        body_alpha = max(0, 255 - frame_idx * 80)
        body_color = (*C_BODY[:3], body_alpha)
        draw.rounded_rectangle([cx - 20 + frame_idx * 4, cy - 16 + frame_idx * 3,
                                 cx + 20 - frame_idx * 4, cy + 16 - frame_idx * 3],
                                radius=6, fill=body_color)
    
    # Onda expansiva
    draw.ellipse([cx - r, cy - r, cx + r, cy + r],
                 outline=(*C_ACCENT[:3], a), width=3)
    
    # Partículas
    for i in range(6):
        angle = i * 60 * math.pi / 180 + frame_idx * 0.3
        px = cx + int(math.cos(angle) * r * 0.7)
        py = cy + int(math.sin(angle) * r * 0.7)
        ps = max(1, 4 - frame_idx)
        draw.ellipse([px - ps, py - ps, px + ps, py + ps],
                     fill=(*C_SHOOT[:3], a))


def generate_spritesheet():
    sheet = Image.new("RGBA", (FRAME_W * TOTAL_FRAMES, FRAME_H), C_TRANS)
    
    frame_generators = {
        "idle":      gen_idle_frame,
        "move":      gen_move_frame,
        "alert":     gen_alert_frame,
        "shoot":     gen_shoot_frame,
        "damage":    gen_damage_frame,
        "explosion": gen_explosion_frame,
    }
    
    frame_x = 0
    for anim_name, frame_count in FRAMES.items():
        gen_func = frame_generators[anim_name]
        for f in range(frame_count):
            frame = Image.new("RGBA", (FRAME_W, FRAME_H), C_TRANS)
            draw = ImageDraw.Draw(frame)
            cx = FRAME_W // 2
            cy = FRAME_H // 2 + 4  # Centrado ligeramente abajo
            gen_func(draw, cx, cy, f)
            sheet.paste(frame, (frame_x, 0))
            frame_x += FRAME_W
    
    out_dir = os.path.join(os.path.dirname(__file__), "..", "assets", "characters", "ukibuki")
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, "ukibuki_spritesheet.png")
    sheet.save(out_path)
    print(f"Spritesheet generado: {out_path}")
    print(f"Tamaño: {sheet.size[0]}x{sheet.size[1]} px")
    print(f"Frames: {TOTAL_FRAMES} ({FRAME_W}x{FRAME_H} cada uno)")
    print(f"Animaciones: {list(FRAMES.keys())}")
    return out_path


if __name__ == "__main__":
    generate_spritesheet()
