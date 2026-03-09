#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# generate_icon.sh
# Creates a ">_<" icon with elegant gradient background and terminal-style design.
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ICON_DIR="$SCRIPT_DIR/../Resources/AppIcon.iconset"
ICNS_PATH="$SCRIPT_DIR/../Resources/AppIcon.icns"

mkdir -p "$ICON_DIR"

PYTHON=$(command -v python3 || true)

if [[ -z "$PYTHON" ]]; then
    echo "⚠️  python3 not found – skipping icon generation."
    exit 0
fi

export ICON_DIR
$PYTHON <<'PYEOF'
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import os
import sys

try:
    from PIL import Image, ImageDraw, ImageFont, ImageFilter
except ImportError:
    import subprocess
    subprocess.run([sys.executable, "-m", "pip", "install", "pillow", "-q"], check=True)
    from PIL import Image, ImageDraw, ImageFont, ImageFilter

def create_icon(size):
    """Create a >_< icon with elegant gradient background."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    padding = size * 0.06
    corner_radius = size * 0.20

    # Elegant gradient background - warm dark slate to deep purple
    colors = [
        (35, 35, 50, 255),   # Outer: dark slate
        (45, 40, 65, 255),   # Mid: purple-slate
        (55, 50, 80, 255),   # Inner: deeper purple
    ]

    # Draw gradient layers
    for i, color in enumerate(colors):
        p = padding + i * size * 0.04
        r = corner_radius * (1 - i * 0.08)
        draw.rounded_rectangle([p, p, size - p - 1, size - p - 1],
                               radius=r, fill=color)

    # Draw ">_<" text
    text = ">_<"
    font_size = int(size * 0.32)

    # Try fonts
    font = None
    font_paths = [
        "/System/Library/Fonts/Supplemental/Courier New Bold.ttf",
        "/System/Library/Fonts/Monaco.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
    ]
    for fp in font_paths:
        try:
            font = ImageFont.truetype(fp, font_size)
            break
        except:
            continue
    if font is None:
        font = ImageFont.load_default()

    # Text color - soft mint green (terminal-ish but elegant)
    text_color = (140, 255, 180, 255)
    shadow_color = (80, 200, 140, 100)

    # Get text bounding box
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    x = (size - tw) // 2 - bbox[0]
    y = (size - th) // 2 - bbox[1]

    # Draw subtle shadow/glow
    for offset in range(3, 0, -1):
        alpha = 30 + offset * 15
        glow = (80, 200, 140, alpha)
        draw.text((x + offset, y + offset), text, font=font, fill=glow)

    # Draw main text
    draw.text((x, y), text, font=font, fill=text_color)

    # Add subtle inner glow effect
    glow_layer = img.filter(ImageFilter.GaussianBlur(radius=size * 0.01))
    final = Image.alpha_composite(glow_layer, img)

    return final

# Generate icons
ICON_DIR = os.environ.get('ICON_DIR', os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'Resources', 'AppIcon.iconset'))
os.makedirs(ICON_DIR, exist_ok=True)

sizes = [16, 32, 64, 128, 256, 512, 1024]
for size in sizes:
    icon = create_icon(size)
    icon.save(os.path.join(ICON_DIR, f"icon_{size}x{size}.png"))
    if size <= 512:
        create_icon(size * 2).save(os.path.join(ICON_DIR, f"icon_{size}x{size}@2x.png"))

print(f"✅ Generated icons in {ICON_DIR}")
PYEOF

iconutil --convert icns "$ICON_DIR" --output "$ICNS_PATH"
echo "✅ Created $ICNS_PATH"