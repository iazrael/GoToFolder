#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# generate_icon.sh
# Creates a simple ">_<" icon set (AppIcon.icns) using only tools bundled with
# macOS (Python 3 / Pillow optional, falls back to sips + textutil).
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

ICON_DIR="$(dirname "$0")/../Resources/AppIcon.iconset"
mkdir -p "$ICON_DIR"

# ── Python path (use system python3 or brew) ──────────────────────────────────
PYTHON=$(command -v python3 || true)

if [[ -z "$PYTHON" ]]; then
    echo "⚠️  python3 not found – skipping icon generation."
    exit 0
fi

# ── Generate PNG at each required size ───────────────────────────────────────
export ICON_DIR
$PYTHON <<'PYEOF'
import os, sys

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    # Try to install Pillow quietly
    os.system(f"{sys.executable} -m pip install pillow -q")
    try:
        from PIL import Image, ImageDraw, ImageFont
    except ImportError:
        print("Pillow not available – icon generation skipped.")
        sys.exit(0)

SIZES = [16, 32, 64, 128, 256, 512, 1024]
ICON_DIR = os.environ.get('ICON_DIR', os.path.join(os.path.dirname(__file__), "..", "Resources", "AppIcon.iconset"))
os.makedirs(ICON_DIR, exist_ok=True)

BG   = (30, 30, 30, 255)   # dark charcoal
FG   = (0, 255, 136, 255)  # terminal green

for size in SIZES:
    img  = Image.new("RGBA", (size, size), BG)
    draw = ImageDraw.Draw(img)

    # Rounded rectangle background
    r = size // 6
    draw.rounded_rectangle([0, 0, size - 1, size - 1], radius=r, fill=BG)

    # Text: ">_<"
    text      = ">_<"
    font_size = max(8, int(size * 0.36))

    try:
        font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Courier New Bold.ttf", font_size)
    except Exception:
        try:
            font = ImageFont.truetype("/System/Library/Fonts/Monaco.ttf", font_size)
        except Exception:
            font = ImageFont.load_default()

    bbox = draw.textbbox((0, 0), text, font=font)
    tw   = bbox[2] - bbox[0]
    th   = bbox[3] - bbox[1]
    x    = (size - tw) // 2 - bbox[0]
    y    = (size - th) // 2 - bbox[1]
    draw.text((x, y), text, font=font, fill=FG)

    # Save @1x and @2x variants
    name1x = f"icon_{size}x{size}.png"
    img.save(os.path.join(ICON_DIR, name1x))

    # @2x is the same image used at double logical resolution
    if size <= 512:
        name2x = f"icon_{size}x{size}@2x.png"
        img2   = img.resize((size * 2, size * 2), Image.LANCZOS)
        img2.save(os.path.join(ICON_DIR, name2x))

print(f"✅  Generated icons in {ICON_DIR}")
PYEOF

# ── Convert iconset → .icns ───────────────────────────────────────────────────
ICNS_PATH="$(dirname "$0")/../Resources/AppIcon.icns"
iconutil --convert icns "$ICON_DIR" --output "$ICNS_PATH"
echo "✅  Created $ICNS_PATH"
