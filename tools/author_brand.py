"""UI-7: provisional brand images, built from art already in the repository.
Usage: python3 tools/author_brand.py   (needs Pillow; writes assets/brand/)

- icon.png (512x512, opaque): the project icon. Godot's Web export makes the
  favicon (index.icon.png) and the apple-touch-icon (180x180) from it, and the
  desktop builds use it as the window icon. Full-bleed and opaque, because iOS
  fills transparency with black and rounds the corners itself.
- splash.png (720x560, opaque): the boot splash: the web page's loading screen
  and the engine's own start-up image, in place of Godot's logo.

Sources (no new illustration): the House Ball card art (assets/items/balls/
a01-source.png, Codex, AV-H1) and the bundled Pixelify Sans derivative
(assets/ui/fonts/PixelifySans.ttf, OFL 1.1). The lane-wood boards and the
lettering treatment are drawn here. Final brand art (logo, icon, splash, title
key art) is Codex's; these stand in until it lands (docs/handoffs/UI-7.md).
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets/brand"
FONT = ROOT / "assets/ui/fonts/PixelifySans.ttf"
BALL = ROOT / "assets/items/balls/a01-source.png"
INK = (16, 24, 32)          # #101820, the House ink
NIGHT = (11, 17, 22)        # #0b1116, the splash and title background
BRASS = (231, 188, 112)     # #e7bc70
WALNUT = (87, 58, 46)       # #573a2e
BOARDS = [(196, 138, 79), (184, 125, 68), (201, 146, 86), (178, 119, 64)]
SEAM = (122, 74, 38)


def ball(size: int) -> Image.Image:
    """The House Ball illustration, cropped to the ball (its card has a shadow
    fragment under it) and scaled to `size`."""
    source = Image.open(BALL).convert("RGBA").crop((0, 0, 640, 640))
    alpha = source.getchannel("A").point(lambda a: 255 if a > 160 else 0)
    box = alpha.crop((0, 0, 640, 600)).getbbox()  # the ball only, above the shadow
    side = max(box[2] - box[0], box[3] - box[1])
    cx, cy = (box[0] + box[2]) // 2, (box[1] + box[3]) // 2
    crop = source.crop((cx - side // 2, cy - side // 2, cx + side // 2, cy + side // 2))
    return crop.resize((size, size), Image.LANCZOS)


def wood(size: int) -> Image.Image:
    """Lane boards in a pixel grid: eight boards across, drawn small and enlarged."""
    small = Image.new("RGB", (64, 64))
    draw = ImageDraw.Draw(small)
    for board in range(8):
        draw.rectangle((board * 8, 0, board * 8 + 7, 63), fill=BOARDS[board % len(BOARDS)])
        draw.line((board * 8, 0, board * 8, 63), fill=SEAM)
        for y in (13 + board * 7 % 23, 41 + board * 5 % 17):  # a few grain marks
            draw.point((board * 8 + 3, y), fill=SEAM)
            draw.point((board * 8 + 4, y + 1), fill=SEAM)
    return small.resize((size, size), Image.NEAREST)


def icon() -> Image.Image:
    out = wood(512)
    shadow = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).ellipse((62, 82, 470, 490), fill=(40, 22, 10, 110))
    out = Image.alpha_composite(out.convert("RGBA"), shadow)
    out.alpha_composite(ball(416), (48, 44))
    return out.convert("RGB")


def wordmark(text: str, size: int) -> Image.Image:
    """The title in Pixelify Sans Bold: brass, an ink outline, a walnut drop shadow."""
    font = ImageFont.truetype(str(FONT), size)
    try:
        font.set_variation_by_axes([700])
    except OSError:
        pass  # a static build of the font: regular weight
    pixel = max(1, round(size * 0.091))  # one font pixel
    left, top, right, bottom = font.getbbox(text, stroke_width=pixel)
    w, h = right - left + pixel * 2, bottom - top + pixel * 2
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(out)
    origin = (-left, -top)
    draw.text((origin[0] + pixel, origin[1] + pixel), text, font=font, fill=WALNUT, stroke_width=pixel, stroke_fill=WALNUT)
    draw.text(origin, text, font=font, fill=BRASS, stroke_width=pixel, stroke_fill=INK)
    return out


def splash() -> Image.Image:
    out = Image.new("RGBA", (720, 560), NIGHT + (255,))
    out.alpha_composite(ball(260), (230, 40))
    mark = wordmark("ROGUEWOOD", 88)
    out.alpha_composite(mark, ((720 - mark.width) // 2, 340))
    return out.convert("RGB")


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    icon().save(OUT / "icon.png", optimize=True)
    splash().save(OUT / "splash.png", optimize=True)
    print("wrote", OUT / "icon.png", "and", OUT / "splash.png")


if __name__ == "__main__":
    main()
