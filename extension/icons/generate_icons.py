#!/usr/bin/env python3
# Generates icon16/32/48/128.png for the HomeScope Chrome Extension.
# Pure stdlib – no Pillow or other dependencies needed.

import struct, zlib, math, os

# ── PNG writer (pure stdlib) ───────────────────────────────────────────────────

def write_png(path, pixels, w, h):
    """pixels: flat list of (r,g,b,a) tuples, row-major."""
    def chunk(t, d):
        c = t + d
        return struct.pack('>I', len(d)) + c + struct.pack('>I', zlib.crc32(c) & 0xffffffff)

    raw = b''.join(
        b'\x00' + b''.join(bytes(pixels[y * w + x]) for x in range(w))
        for y in range(h)
    )
    with open(path, 'wb') as f:
        f.write(
            b'\x89PNG\r\n\x1a\n' +
            chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 6, 0, 0, 0)) +
            chunk(b'IDAT', zlib.compress(raw, 9)) +
            chunk(b'IEND', b'')
        )

# ── Helpers ────────────────────────────────────────────────────────────────────

def lerp(a, b, t):
    return int(round(a + (b - a) * max(0.0, min(1.0, t))))

def lerp_color(c1, c2, t):
    return tuple(lerp(a, b, t) for a, b in zip(c1, c2))

def distance(x1, y1, x2, y2):
    return math.sqrt((x1-x2)**2 + (y1-y2)**2)

def alpha_blend(fg, bg):
    """Blend fg (r,g,b,a) over bg (r,g,b)."""
    a = fg[3] / 255.0
    return (
        lerp(bg[0], fg[0], a),
        lerp(bg[1], fg[1], a),
        lerp(bg[2], fg[2], a),
        255,
    )

def smooth_circle(x, y, cx, cy, r, aa=1.5):
    """Returns 0-255 alpha for a smooth circle."""
    d = distance(x, y, cx, cy)
    if d <= r - aa:
        return 255
    if d >= r + aa:
        return 0
    return int(255 * (1.0 - (d - r + aa) / (2 * aa)))

def point_in_polygon(px, py, poly):
    """Ray-casting polygon hit test."""
    n = len(poly)
    inside = False
    j = n - 1
    for i in range(n):
        xi, yi = poly[i]
        xj, yj = poly[j]
        if ((yi > py) != (yj > py)) and (px < (xj - xi) * (py - yi) / (yj - yi + 1e-12) + xi):
            inside = not inside
        j = i
    return inside

def poly_sdf(px, py, poly):
    """Signed distance to polygon boundary (positive outside, negative inside)."""
    min_d = float('inf')
    n = len(poly)
    for i in range(n):
        ax, ay = poly[i]
        bx, by = poly[(i+1) % n]
        dx, dy = bx - ax, by - ay
        t = max(0.0, min(1.0, ((px-ax)*dx + (py-ay)*dy) / (dx*dx + dy*dy + 1e-12)))
        cx2, cy2 = ax + t*dx, ay + t*dy
        min_d = min(min_d, distance(px, py, cx2, cy2))
    sign = -1 if point_in_polygon(px, py, poly) else 1
    return sign * min_d

# ── Icon design ────────────────────────────────────────────────────────────────

# Colours
BG1      = (6,   11,  20)   # #060B14 – darkest bg
BG2      = (13,  22,  37)   # #0D1625 – surface
BLUE1    = (59,  130, 246)  # #3B82F6 – accent
BLUE2    = (108, 99,  255)  # #6C63FF – accent2
GREEN    = (34,  197, 94)   # #22C55E – success dot
WHITE    = (255, 255, 255)

def house_polygon(size):
    """Return house polygon vertices scaled for icon `size`."""
    s    = size
    cx   = s / 2
    cy   = s / 2

    # Fraction-based layout (tuned to look good at all sizes)
    roof_top_y  = cy - s * 0.32
    roof_base_y = cy - s * 0.07
    body_bot_y  = cy + s * 0.34
    half_w      = s * 0.28
    roof_half_w = s * 0.32   # slightly wider than body for eaves

    door_hw     = s * 0.08
    door_top_y  = cy + s * 0.10

    # House outline (including door notch)
    poly = [
        (cx,              roof_top_y),    # peak
        (cx + roof_half_w, roof_base_y),  # right eave
        (cx + half_w,     roof_base_y),   # right wall top
        (cx + half_w,     body_bot_y),    # right wall bottom
        (cx + door_hw,    body_bot_y),    # door right bottom
        (cx + door_hw,    door_top_y),    # door right top
        (cx - door_hw,    door_top_y),    # door left top
        (cx - door_hw,    body_bot_y),    # door left bottom
        (cx - half_w,     body_bot_y),    # left wall bottom
        (cx - half_w,     roof_base_y),   # left wall top
        (cx - roof_half_w, roof_base_y),  # left eave
    ]
    return poly

def render_icon(size):
    s  = size
    cx = s / 2
    cy = s / 2
    aa = max(1.0, s / 32.0)  # anti-alias radius scales with size

    # Outer circle clip radius (leave 1-2px padding)
    circle_r = s / 2 - 1.0

    poly = house_polygon(size)

    # Green dot (top of roof peak)
    dot_r  = max(1.5, s * 0.065)
    dot_cx = cx
    dot_cy = cy - s * 0.32 - dot_r * 0.6   # sits just above the roof peak

    pixels = []
    for y in range(s):
        for x in range(s):
            # ── Circular clip ──────────────────────────────────────
            circle_a = smooth_circle(x + 0.5, y + 0.5, cx, cy, circle_r, aa)
            if circle_a == 0:
                pixels.append((0, 0, 0, 0))
                continue

            # ── Background gradient (dark centre → darker edge) ────
            t_bg = distance(x + 0.5, y + 0.5, cx, cy) / circle_r
            bg_rgb = lerp_color(BG2, BG1, t_bg)

            # ── House shape ────────────────────────────────────────
            sdf = poly_sdf(x + 0.5, y + 0.5, poly)
            house_a = 0
            if sdf < 0:
                house_a = 255
            elif sdf < aa * 1.5:
                house_a = int(255 * (1.0 - sdf / (aa * 1.5)))

            if house_a > 0:
                # Blue → purple gradient (top-left to bottom-right)
                t_house = ((x + 0.5) / s + (y + 0.5 - cy) / s * 0.5)
                house_rgb = lerp_color(BLUE1, BLUE2, t_house)
                bg_rgb = lerp_color(bg_rgb, house_rgb, house_a / 255.0)

            # ── Green indicator dot ────────────────────────────────
            dot_a = smooth_circle(x + 0.5, y + 0.5, dot_cx, dot_cy, dot_r, aa)
            if dot_a > 0:
                bg_rgb = lerp_color(bg_rgb, GREEN, dot_a / 255.0)

            pixels.append((*bg_rgb, circle_a))

    return pixels

# ── Generate all sizes ─────────────────────────────────────────────────────────

output_dir = os.path.dirname(os.path.abspath(__file__))
sizes = [16, 32, 48, 128]

for size in sizes:
    path = os.path.join(output_dir, f'icon{size}.png')
    print(f'Generating {path} … ', end='', flush=True)
    pixels = render_icon(size)
    write_png(path, pixels, size, size)
    print('done')

print('\nAll icons generated successfully!')
