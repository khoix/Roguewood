"""AV-FIX1 (owner, 2026-11-17): transparent card art for seven House items whose
generated source sheets were saved on an opaque plate (about #0F181F).

For each item, the card region is cut from its unchanged source sheet and given an
alpha matte:
  1. the plate colour is the median of the region's border pixels;
  2. the background is the area connected to the region's edge whose colour is
     within HIGH of the plate (a flood fill, so dark parts inside the subject stay),
     plus enclosed pockets that are large and on average plate colour (inside a
     ring, between handles);
  3. alpha is 0 within LOW of the plate and eases to 1 at HIGH (a soft edge);
  4. the plate colour is removed from soft-edge pixels (no dark fringe).
The result is saved beside the sheet as matte.<item>.png, and the item's card, icon
and reduced-motion views are pointed at it. The source sheets are not modified.
Deterministic: the same sheets give the same files. Spare Jar is not here: its
glass shows the plate through it, which a matte cannot fix (left to Codex).

Usage: python3 tools/author_card_mattes.py   (then: python3 tools/qa.py import)
"""
import hashlib
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
# item id: (batch folder, source sheet, region x, y, w, h, LOW, HIGH)
ITEMS = {
    "pin.tin": ("d09", "source.AV-H3-B.png", 32, 32, 416, 896, 10.0, 34.0),
    "charm.consolation_prize": ("d09", "source.AV-H3-B.png", 1032, 48, 480, 880, 10.0, 34.0),
    "consumable.double_take": ("d10", "source.AV-H4-A.png", 32, 160, 464, 700, 10.0, 34.0),
    "consumable.called_shot": ("d10", "source.AV-H4-A.png", 496, 160, 512, 700, 10.0, 34.0),
    "consumable.pin_count": ("d10", "source.AV-H4-A.png", 1024, 160, 512, 700, 10.0, 34.0),
    "charm.cleanup_crew": ("d10", "source.AV-H4-B.png", 0, 40, 768, 900, 10.0, 34.0),
    "charm.lucky_seven": ("d10", "source.AV-H4-B.png", 800, 120, 720, 800, 10.0, 34.0),
}
VIEWS = ("card", "icon", "reduced_motion")
POCKET_MIN = 400 # pixels: an enclosed pocket at least this big may be background
POCKET_PLATE = 12.0 # and its mean distance from the plate colour at most this


def matte(region: np.ndarray, low: float, high: float) -> tuple[np.ndarray, np.ndarray]:
    h, w, _ = region.shape
    border = np.concatenate([region[0], region[-1], region[:, 0], region[:, -1]])
    plate = np.median(border, axis=0)
    dist = np.sqrt(((region - plate) ** 2).sum(axis=2))
    near = dist < high
    background = np.zeros((h, w), bool)
    queue = deque()
    for y in range(h):
        for x in (0, w - 1):
            if near[y, x] and not background[y, x]:
                background[y, x] = True
                queue.append((y, x))
    for x in range(w):
        for y in (0, h - 1):
            if near[y, x] and not background[y, x]:
                background[y, x] = True
                queue.append((y, x))
    while queue:
        y, x = queue.popleft()
        for ny, nx in ((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)):
            if 0 <= ny < h and 0 <= nx < w and near[ny, nx] and not background[ny, nx]:
                background[ny, nx] = True
                queue.append((ny, nx))
    # Pockets the subject encloses (inside a ring, between handles): a connected
    # patch of near-plate colour that is large and, on average, plate itself is
    # background too. Small or merely dark details inside the subject are kept.
    seen = background.copy()
    for sy in range(h):
        for sx in range(w):
            if not near[sy, sx] or seen[sy, sx]:
                continue
            seen[sy, sx] = True
            patch = [(sy, sx)]
            queue.append((sy, sx))
            while queue:
                y, x = queue.popleft()
                for ny, nx in ((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)):
                    if 0 <= ny < h and 0 <= nx < w and near[ny, nx] and not seen[ny, nx]:
                        seen[ny, nx] = True
                        patch.append((ny, nx))
                        queue.append((ny, nx))
            if len(patch) >= POCKET_MIN:
                ys, xs = zip(*patch)
                if float(dist[ys, xs].mean()) <= POCKET_PLATE:
                    background[ys, xs] = True
    t = np.clip((dist - low) / (high - low), 0.0, 1.0)
    alpha = np.where(background, t * t * (3.0 - 2.0 * t), 1.0)
    a = alpha[..., None]
    rgb = np.where(a > 0.02, (region - (1.0 - a) * plate) / np.maximum(a, 0.02), 0.0)
    rgba = np.dstack([np.clip(rgb, 0, 255), alpha * 255.0]).round().astype(np.uint8)
    return rgba, plate


def view_resource(png: str, w: int, h: int) -> str:
    return ('[gd_resource type="AtlasTexture" load_steps=2 format=3]\n'
            f'[ext_resource type="Texture2D" path="res://{png}" id="1"]\n'
            '[resource]\n'
            'atlas = ExtResource("1")\n'
            f'region = Rect2(0, 0, {w}, {h})\n'
            'filter_clip = true\n')


def main() -> None:
    for item, (batch, sheet, x, y, w, h, low, high) in ITEMS.items():
        folder = ROOT / "assets" / "items" / batch
        source = Image.open(folder / sheet).convert("RGB")
        region = np.asarray(source.crop((x, y, x + w, y + h))).astype(np.float32)
        rgba, plate = matte(region, low, high)
        out = folder / f"matte.{item}.png"
        Image.fromarray(rgba, "RGBA").save(out, optimize=False)
        rel = out.relative_to(ROOT).as_posix()
        for view in VIEWS:
            (folder / f"{view}.{item}.tres").write_text(view_resource(rel, w, h))
        transparent = float((rgba[..., 3] == 0).mean())
        digest = hashlib.sha256(out.read_bytes()).hexdigest()
        print(f"{item}\t{rel}\t{w}x{h}\tplate #{''.join('%02x' % int(round(c)) for c in plate)}\ttransparent {transparent:.0%}\tsha256 {digest}")


if __name__ == "__main__":
    main()
