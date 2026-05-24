#!/usr/bin/env python3
"""Build launcher PNGs from agroscan_logo.svg.

- agroscan_launcher_foreground.png: transparent margins (adaptive icon foreground)
- agroscan_launcher.png: cream background (legacy mipmap / image_path)
"""
from __future__ import annotations

import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
BRANDING = ROOT / "mobile" / "assets" / "branding"
SVG = BRANDING / "agroscan_logo.svg"
OUT_FOREGROUND = BRANDING / "agroscan_launcher_foreground.png"
OUT_LEGACY = BRANDING / "agroscan_launcher.png"

CANVAS = 1024
# Visible margin on home screen (~28% per side; logo ~44% of canvas).
PADDING_RATIO = 0.28
BACKGROUND = (253, 252, 248, 255)  # #FDFCF8


def _render_logo(inner: int, tmp_path: Path) -> Image.Image:
    try:
        subprocess.run(
            ["rsvg-convert", "--version"],
            check=True,
            capture_output=True,
        )
    except (FileNotFoundError, subprocess.CalledProcessError):
        print(
            "rsvg-convert not found. Install librsvg:\n"
            "  Linux: distro package (e.g. librsvg2-bin)\n"
            "  macOS: brew install librsvg\n"
            "  Windows: GTK/librsvg or use WSL\n",
            file=sys.stderr,
        )
        raise SystemExit(1) from None

    subprocess.run(
        [
            "rsvg-convert",
            "-w",
            str(inner),
            "-h",
            str(inner),
            str(SVG),
            "-o",
            str(tmp_path),
        ],
        check=True,
    )
    return Image.open(tmp_path).convert("RGBA")


def main() -> int:
    if not SVG.exists():
        print(f"Missing {SVG}", file=sys.stderr)
        return 1

    inner = int(CANVAS * (1 - 2 * PADDING_RATIO))
    with tempfile.NamedTemporaryFile(suffix=".png", delete=False) as tmp:
        tmp_path = Path(tmp.name)

    try:
        logo = _render_logo(inner, tmp_path)
        x = (CANVAS - logo.width) // 2
        y = (CANVAS - logo.height) // 2

        # Adaptive foreground: transparent padding so background color shows through.
        foreground = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
        foreground.paste(logo, (x, y), logo)

        # Legacy / flat icon: same layout on cream background.
        legacy = Image.new("RGBA", (CANVAS, CANVAS), BACKGROUND)
        legacy.paste(logo, (x, y), logo)

        BRANDING.mkdir(parents=True, exist_ok=True)
        foreground.save(OUT_FOREGROUND, format="PNG", optimize=True)
        legacy.convert("RGB").save(OUT_LEGACY, format="PNG", optimize=True)
        print(
            f"Wrote {OUT_FOREGROUND} (transparent padding {int(PADDING_RATIO * 100)}%)"
        )
        print(f"Wrote {OUT_LEGACY} (background #FDFCF8)")
    finally:
        tmp_path.unlink(missing_ok=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
