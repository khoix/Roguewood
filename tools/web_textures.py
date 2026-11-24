#!/usr/bin/env python3
"""PACK-A (owner, 2026-11-24; docs/ideas/PACK-1.md): the Web build's art, compressed.

Every painted sheet imports as lossy WebP (Godot's `compress/mode=1`) at LOSSY_QUALITY.
A sample of ten sheets measured about a quarter of the lossless size at 0.9. The few
small, crisp images in LOSSLESS stay lossless. The Web export also leaves out art the
game never loads (WEB_EXCLUDE). Each entry was found unreferenced by path, UID and the
Clubhouse's built names, and stays in the repository for the tools and tests that use it.

    python3 tools/web_textures.py           # apply: rewrite .import params and the Web preset
    python3 tools/web_textures.py --check   # report anything off the rule (qa.py content runs it)

New art follows the rule automatically once this runs (or `--check` names it).
"""
import fnmatch
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LOSSY_QUALITY = 0.9
# Small or pixel-crisp images where lossy encoding saves little and could soften edges.
LOSSLESS = {
    "assets/brand/icon.png",    # 512 px app icon (also the Web favicon source)
    "assets/brand/splash.png",  # 720 x 560 loading splash
}
# Never loaded by the game (PACK-A audit, 2026-11-24): source sheets the tools cut
# from, identical copies of the Clubhouse ribbons it does load (`ribbon.<goal>`;
# clubhouse_model.gd asset_id drops "mastery."), and three item sheets only tools read.
WEB_EXCLUDE = [
    "assets/brand/source.icon.png",
    "assets/brand/source.logo.png",
    "assets/clubhouse/sources/*",
    "assets/clubhouse/ribbon.mastery.*",
    "assets/items/d09/source.AV-H3-B.png",
    "assets/items/d10/source.AV-H4-A.png",
    "assets/items/d10/source.AV-H4-B.png",
]
BASE_EXCLUDE = ["docs/*", "tools/*", "artifacts/*", "tests/*", "build/*"]
SKIP = ("build/", "artifacts/", ".godot/")


def images():
    for imp in sorted(ROOT.glob("assets/**/*.png.import")):
        rel = imp.relative_to(ROOT).as_posix()
        if rel.startswith(SKIP):
            continue
        yield rel[: -len(".import")], imp


def wanted(source):
    return (0, None) if source in LOSSLESS else (1, LOSSY_QUALITY)


def excluded(source):
    return any(fnmatch.fnmatch(source, pattern) for pattern in WEB_EXCLUDE)


def import_params(text):
    mode = re.search(r"^compress/mode=(\d+)$", text, re.M)
    quality = re.search(r"^compress/lossy_quality=([\d.]+)$", text, re.M)
    return int(mode.group(1)) if mode else None, float(quality.group(1)) if quality else None


def web_filter():
    return ",".join(BASE_EXCLUDE + WEB_EXCLUDE)


def preset_section(text):
    """The Web preset's [preset.N] block: (start, end) offsets."""
    for match in re.finditer(r"^\[preset\.(\d+)\]\n(.*?)(?=^\[preset\.\d+(?:\.options)?\]|\Z)", text, re.M | re.S):
        if re.search(r'^name="Web"$', match.group(2), re.M):
            return match.start(), match.end()
    raise SystemExit("export_presets.cfg has no Web preset")


def problems():
    found = []
    for source, imp in images():
        if excluded(source):
            continue
        mode, quality = import_params(imp.read_text())
        want_mode, want_quality = wanted(source)
        if mode != want_mode or (want_quality is not None and (quality is None or abs(quality - want_quality) > 1e-6)):
            found.append(f"{source}: compress/mode={mode} lossy_quality={quality}; want mode={want_mode} quality={want_quality}")
    presets = (ROOT / "export_presets.cfg").read_text()
    start, end = preset_section(presets)
    current = re.search(r'^exclude_filter="(.*)"$', presets[start:end], re.M)
    if not current or current.group(1) != web_filter():
        found.append("export_presets.cfg Web exclude_filter is not tools/web_textures.py's list")
    for pattern in WEB_EXCLUDE:
        if not any(fnmatch.fnmatch(source, pattern) for source, _ in images()):
            found.append(f"WEB_EXCLUDE entry matches nothing: {pattern}")
    return found


def apply():
    changed = 0
    for source, imp in images():
        if excluded(source):
            continue
        text = imp.read_text()
        want_mode, want_quality = wanted(source)
        new = re.sub(r"^compress/mode=\d+$", f"compress/mode={want_mode}", text, flags=re.M)
        if want_quality is not None:
            new = re.sub(r"^compress/lossy_quality=[\d.]+$", f"compress/lossy_quality={want_quality}", new, flags=re.M)
        if new != text:
            imp.write_text(new)
            changed += 1
    path = ROOT / "export_presets.cfg"
    presets = path.read_text()
    start, end = preset_section(presets)
    block = re.sub(r'^exclude_filter=".*"$', f'exclude_filter="{web_filter()}"', presets[start:end], flags=re.M)
    path.write_text(presets[:start] + block + presets[end:])
    print(f"{changed} image imports updated; Web exclude_filter set ({len(WEB_EXCLUDE)} art entries)")


if __name__ == "__main__":
    if "--check" in sys.argv:
        issues = problems()
        for issue in issues:
            print("PACK-A:", issue)
        sys.exit(1 if issues else 0)
    apply()
