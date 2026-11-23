#!/usr/bin/env python3
import math, os
from PIL import Image, ImageDraw, ImageFilter

S = 2                      # supersample factor
SZ = 360 * S               # 720
C = 180 * S                # center
N = 36                     # frames per loop
OUT = "/home/claude/gifs"
os.makedirs(OUT, exist_ok=True)

BG     = (5, 9, 13)
RIM    = (11, 55, 68)
RET    = (21, 185, 214)
DIM    = (17, 122, 144)
DIM2   = (11, 77, 92)
BRIGHT = (53, 230, 255)
CORE   = (26, 208, 239)
WHITE  = (234, 252, 255)

def R(v):            # scale a 360-space value
    return v * S

def bbox(cx, cy, r):
    return [cx - r, cy - r, cx + r, cy + r]

def dashed(d, cx, cy, r, dash, gap, width, color, a=255):
    ang = 0.0
    while ang < 360:
        d.arc(bbox(cx, cy, r), ang, ang + dash, fill=color + (a,), width=width)
        ang += dash + gap

def ring(d, r, width, color, a=255):
    d.ellipse(bbox(C, C, r), outline=color + (a,), width=width)

def new_layer():
    return Image.new("RGBA", (SZ, SZ), (0, 0, 0, 0))

def rot(layer, deg):
    return layer.rotate(deg, resample=Image.BICUBIC, center=(C, C), expand=False)

def reticle(d):
    b = bbox(C, C, R(155))
    for a0 in (205, 295, 115, 25):
        d.arc(b, a0, a0 + 40, fill=RET + (235,), width=R(2))

def compose(sharp):
    frame = Image.new("RGBA", (SZ, SZ), BG + (255,))
    glow = sharp.filter(ImageFilter.GaussianBlur(R(5)))
    frame.alpha_composite(glow)
    frame.alpha_composite(sharp)
    return frame.convert("RGB").resize((360, 360), Image.LANCZOS)

def core(d, pr, pulse=0.15, flick=0.0, halo=True):
    if halo:
        hr = int(R(40) * (1 + pulse * math.sin(2 * math.pi * pr)))
        ha = int(60 + 80 * (0.5 + 0.5 * math.sin(2 * math.pi * pr)))
        d.ellipse(bbox(C, C, hr), fill=CORE + (ha,))
    ring(d, R(30), R(2), BRIGHT)
    ia = int(210 + 45 * math.sin(2 * math.pi * (pr * (1 + flick))))
    d.ellipse(bbox(C, C, R(18)), fill=CORE + (max(0, min(255, ia)),))
    d.ellipse(bbox(C, C, R(9)), fill=WHITE + (255,))

def idle_frame(t):
    p = t / N
    sharp = new_layer(); d = ImageDraw.Draw(sharp)
    ring(sharp and d, R(120), R(1), DIM2)
    reticle(d)
    dashed(d, C, C, R(66), 70, 22, R(2), RET, 220)
    la = new_layer(); dashed(ImageDraw.Draw(la), C, C, R(150), 2, 10, R(1), DIM); sharp.alpha_composite(rot(la, -p*360))
    lb = new_layer(); dashed(ImageDraw.Draw(lb), C, C, R(92), 4, 8, R(1), DIM); sharp.alpha_composite(rot(lb, p*360))
    lt = new_layer(); dt = ImageDraw.Draw(lt)
    for ang in (0, 90, 180, 270):
        rad = math.radians(ang)
        x1 = C + math.cos(rad)*R(120); y1 = C + math.sin(rad)*R(120)
        x2 = C + math.cos(rad)*R(132); y2 = C + math.sin(rad)*R(132)
        dt.line([x1, y1, x2, y2], fill=BRIGHT + (255,), width=R(2))
    sharp.alpha_composite(rot(lt, p*360))
    core(d, p, pulse=0.15)
    return compose(sharp)

def listening_frame(t):
    p = t / N
    sharp = new_layer(); d = ImageDraw.Draw(sharp)
    reticle(d)
    ring(d, R(120), R(1), DIM2)
    dashed(d, C, C, R(66), 70, 22, R(2), RET, 220)
    lb = new_layer(); dashed(ImageDraw.Draw(lb), C, C, R(92), 4, 8, R(1), DIM); sharp.alpha_composite(rot(lb, -p*360))
    la = new_layer(); dla = ImageDraw.Draw(la)
    b = bbox(C, C, R(120))
    dla.arc(b, 0, 55, fill=BRIGHT + (255,), width=R(4))
    dla.arc(b, 180, 235, fill=BRIGHT + (255,), width=R(4))
    sharp.alpha_composite(rot(la, p*360))
    core(d, p, pulse=0.08)
    return compose(sharp)

def thinking_frame(t):
    p = t / N
    sharp = new_layer(); d = ImageDraw.Draw(sharp)
    reticle(d)
    ring(d, R(120), R(1), DIM2)
    la = new_layer(); dashed(ImageDraw.Draw(la), C, C, R(150), 20, 14, R(2), DIM); sharp.alpha_composite(rot(la, p*360))
    lb = new_layer(); dashed(ImageDraw.Draw(lb), C, C, R(90), 10, 10, R(2), DIM); sharp.alpha_composite(rot(lb, -p*360))
    ls = new_layer(); dls = ImageDraw.Draw(ls)
    b = bbox(C, C, R(120))
    dls.arc(b, 0, 70, fill=BRIGHT + (255,), width=R(4))
    dls.arc(b, 0, 40, fill=CORE + (150,), width=R(2))
    sharp.alpha_composite(rot(ls, p*360))
    lo = new_layer(); dlo = ImageDraw.Draw(lo)
    for ang, rr, col in ((0, 120, BRIGHT), (120, 120, CORE), (240, 90, DIM)):
        rad = math.radians(ang)
        x = C + math.cos(rad)*R(rr); y = C + math.sin(rad)*R(rr)
        dlo.ellipse(bbox(x, y, R(5)), fill=col + (255,))
    sharp.alpha_composite(rot(lo, p*360))
    core(d, p, pulse=0.0, flick=1.5, halo=False)
    d.ellipse(bbox(C, C, R(15)), fill=CORE + (200,))
    d.ellipse(bbox(C, C, R(7)), fill=WHITE + (255,))
    return compose(sharp)

def speaking_frame(t):
    p = t / N
    sharp = new_layer(); d = ImageDraw.Draw(sharp)
    reticle(d)
    cols = [BRIGHT, CORE, DIM]
    for i in range(3):
        rp = (p + i/3.0) % 1.0
        rr = R(30) + (R(168) - R(30)) * rp
        ra = int(220 * (1 - rp))
        d.ellipse(bbox(C, C, rr), outline=cols[i] + (ra,), width=R(3))
    d.ellipse(bbox(C, C, R(58)), fill=(6, 22, 28, 255), outline=RET + (255,), width=R(2))
    offs = [0.0, 1.1, 2.0, 1.4, 2.6]
    base_y = C + R(20)
    xs = [153, 165, 177, 189, 201]
    for x0, off in zip(xs, offs):
        h = R(40) * (0.25 + 0.75 * (0.5 + 0.5 * math.sin(2*math.pi*(p*2) + off)))
        x = R(x0)
        d.rounded_rectangle([x, base_y - h, x + R(7), base_y], radius=R(2), fill=BRIGHT + (255,))
    return compose(sharp)

jobs = [
    ("jarvis_idle.gif", idle_frame, 75),
    ("jarvis_listening.gif", listening_frame, 60),
    ("jarvis_thinking.gif", thinking_frame, 45),
    ("jarvis_speaking.gif", speaking_frame, 55),
]
for name, fn, dur in jobs:
    frames = [fn(t) for t in range(N)]
    frames[0].save(os.path.join(OUT, name), save_all=True, append_images=frames[1:],
                   duration=dur, loop=0, optimize=True, disposal=2)
    print("OK", name, os.path.getsize(os.path.join(OUT, name)) // 1024, "KB")
print("done")
