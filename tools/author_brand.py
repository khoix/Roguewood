"""UI-A4 production exports from immutable original illustrations.

Usage: python3 tools/author_brand.py [--previews]
Needs Pillow. No provisional House-ball crop or font wordmark is regenerated.
source.logo.png and source.icon.png are original OpenAI-generated artwork;
exact prompts and hashes: docs/art/ui/UI-A4.md, docs/art/ASSET-LEDGER.md.
This script only performs the requested size/format exports and splash assembly.
"""
from pathlib import Path
import argparse
import shutil
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets/brand"
NIGHT = (11, 17, 22)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--previews", action="store_true")
    args = parser.parse_args()
    logo = Image.open(OUT / "source.logo.png").convert("RGBA")
    source = Image.open(OUT / "source.icon.png").convert("RGB")
    assert source.width == source.height
    assert logo.getchannel("A").getextrema() == (0, 255)
    shutil.copyfile(OUT / "source.logo.png", OUT / "logo.png")
    # Bounded palette keeps the full-size favicon below 150 KB. Opaque PNG
    # avoids iOS adding an unwanted black transparency background.
    icon = source.resize((512, 512), Image.Resampling.LANCZOS)
    icon = icon.quantize(colors=32, method=Image.Quantize.MEDIANCUT).convert("RGB")
    icon.save(OUT / "icon.png", optimize=True)
    assert (OUT / "icon.png").stat().st_size < 150_000
    splash = Image.new("RGBA", (720, 560), NIGHT + (255,))
    fitted = logo.resize((680, round(680 * logo.height / logo.width)), Image.Resampling.LANCZOS)
    splash.alpha_composite(fitted, ((720 - fitted.width) // 2, (560 - fitted.height) // 2))
    splash.convert("RGB").save(OUT / "splash.png", optimize=True)
    if args.previews:
        dest = ROOT / "artifacts/ui-a4/brand"
        dest.mkdir(parents=True, exist_ok=True)
        sheet = Image.new("RGB", (640, 300), NIGHT)
        draw = ImageDraw.Draw(sheet)
        for size, x in [(180, 30), (32, 290), (16, 430)]:
            small = icon.resize((size, size), Image.Resampling.LANCZOS)
            small.save(dest / f"icon_{size}.png")
            sheet.paste(small, (x, 60))
            draw.text((x, 30), f"{size} px (actual size)", fill=(244, 230, 205))
        sheet.save(dest / "icon_sizes.png")
    for name in ("logo.png", "icon.png", "splash.png"):
        print(name, Image.open(OUT / name).size, (OUT / name).stat().st_size)


if __name__ == "__main__":
    main()
