#!/usr/bin/env python3
"""Reproduce path-backed defeated views from RivalArt's unchanged manifest.

Only AtlasTexture metadata is authored. No source pixels are copied or changed.
Resource paths let PERF-2 restore Normal after the original view is freed at Low.
"""
import json
from pathlib import Path
import struct

ROOT = Path(__file__).resolve().parents[1]
NAMES = ("surveyor", "custodian", "proprietor", "old_lou", "custodian_champion")


def main():
    manifest = json.loads((ROOT / "assets/rivals/manifest.json").read_text())
    out = ROOT / "assets/ui/alley_screen/house/portraits"
    out.mkdir(parents=True, exist_ok=True)
    for name in NAMES:
        data = manifest["rival." + name]
        source = data["source"]
        if "regions" in data:
            region = data["regions"][4]  # RivalArt.STATES: defeated
        else:
            png = (ROOT / source.removeprefix("res://")).read_bytes()
            if png[:8] != b"\x89PNG\r\n\x1a\n":
                raise ValueError("Expected the manifest's original PNG: " + source)
            width, height = struct.unpack(">II", png[16:24])
            cell_w, cell_h = width / 3, height / 2
            region = [cell_w, cell_h, cell_w, cell_h]  # index 4: column 1, row 1
        text = ('[gd_resource type="AtlasTexture" load_steps=2 format=3]\n\n'
                f'[ext_resource type="Texture2D" path="{source}" id="1"]\n\n'
                '[resource]\natlas = ExtResource("1")\n'
                'region = Rect2(' + ', '.join(str(v) for v in region) + ')\n'
                'filter_clip = true\n')
        (out / (name + ".tres")).write_text(text)


if __name__ == "__main__":
    main()
