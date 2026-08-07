#!/usr/bin/env python3
"""Fan out the app-icon source to every iOS/Android icon file.

The source is the designed brand mark on its navy field, kept at
`assets/icons/app_icon.png` (icon-ready square). flutter_launcher_icons'
bundled decoder mangles it, so we distribute the icons ourselves with PIL.

Run from the `mobile/` directory whenever `assets/icons/app_icon.png` changes:
    python3 test/tools/distribute_app_icon.py
"""
import json
import os
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BG = (0x0A, 0x12, 0x20)  # opaque navy behind the mark

opaque = Image.open(os.path.join(ROOT, "assets/icons/app_icon.png")).convert("RGBA")
# The adaptive-icon background colour matches the icon's navy, so the opaque
# icon doubles as the foreground layer (its inset border blends into the bg).
foreground = opaque


def flatten(img):
    """Composite an RGBA image onto opaque navy -> RGB (no alpha, App Store-safe)."""
    base = Image.new("RGB", img.size, BG)
    base.paste(img, (0, 0), img)
    return base


def resized(src, px, mode):
    img = src.resize((px, px), Image.LANCZOS)
    return flatten(img) if mode == "opaque" else img


# ── iOS: drive off Contents.json so every declared slot is filled ─────────────
ios_dir = os.path.join(ROOT, "ios/Runner/Assets.xcassets/AppIcon.appiconset")
with open(os.path.join(ios_dir, "Contents.json")) as fh:
    contents = json.load(fh)

ios_count = 0
for entry in contents["images"]:
    fname = entry.get("filename")
    if not fname:
        continue
    size = float(entry["size"].split("x")[0])
    scale = int(entry["scale"].rstrip("x"))
    px = round(size * scale)
    resized(opaque, px, "opaque").save(os.path.join(ios_dir, fname))
    ios_count += 1
print(f"iOS: wrote {ios_count} icons")

# ── Android legacy launcher icons (opaque) ────────────────────────────────────
legacy = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
for dens, px in legacy.items():
    path = os.path.join(ROOT, f"android/app/src/main/res/mipmap-{dens}/ic_launcher.png")
    if os.path.isdir(os.path.dirname(path)):
        resized(opaque, px, "opaque").save(path)
print(f"Android legacy: wrote {len(legacy)} icons")

# ── Android adaptive foreground (transparent, 108dp canvas) ───────────────────
fg = {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324, "xxxhdpi": 432}
fg_count = 0
for dens, px in fg.items():
    path = os.path.join(
        ROOT, f"android/app/src/main/res/drawable-{dens}/ic_launcher_foreground.png"
    )
    if os.path.isdir(os.path.dirname(path)):
        resized(foreground, px, "alpha").save(path)
        fg_count += 1
print(f"Android adaptive foreground: wrote {fg_count} icons")
print("done")
