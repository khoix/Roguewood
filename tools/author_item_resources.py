"""Author resource views of original atlas sources; never edits image pixels.

Usage: python3 tools/author_item_resources.py E19-A03 source.png
The batch must already have an approved brief and an entry in batches.json.
Artwork flags remain unchanged until native/visual verification.
"""
import json
from pathlib import Path
import shutil
import sys
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
batch, source = sys.argv[1:3]
ids = json.loads((ROOT / "assets/items/batches.json").read_text())[batch]
destination = ROOT / "assets/items/sources" / (batch.lower() + ".png")
destination.parent.mkdir(parents=True, exist_ok=True)
shutil.copyfile(source, destination)
width, height = Image.open(destination).size
catalogue_path = ROOT / "content/catalogue.json"
catalogue = json.loads(catalogue_path.read_text())
items = {item["id"]: item for item in catalogue["items"]}
folders = {"pin": "pins", "charm": "charms", "boss_rule": "rules", "kit": "kits"}
for index, item_id in enumerate(ids):
    item = items[item_id]
    category, name = item_id.split(".")
    folder = ROOT / "assets/items" / folders[category]
    folder.mkdir(parents=True, exist_ok=True)
    resource = "res://" + folder.relative_to(ROOT).as_posix() + "/" + name
    w, h = (width, height) if len(ids) == 1 else (width / 2, height / 2)
    x, y = (0, 0) if len(ids) == 1 else ((index % 2) * w, (index // 2) * h)
    (folder / (name + "-card.tres")).write_text(f'''[gd_resource type="AtlasTexture" load_steps=2 format=3]

[ext_resource type="Texture2D" path="res://assets/items/sources/{batch.lower()}.png" id="1"]

[resource]
atlas = ExtResource("1")
region = Rect2({x}, {y}, {w}, {h})
filter_clip = true
''')
    frame = (ROOT / "assets/items/balls" / ("echo-frame.tres" if item["rarity"] != "common" else "house-frame.tres")).read_text()
    if item["rarity"] == "rare":
        frame = frame.replace("border_width_top = 2", "border_width_top = 5").replace("border_width_bottom = 2", "border_width_bottom = 5").replace("Color(0.73, 0.58, 0.36, 1)", "Color(0.46, 0.80, 0.82, 1)")
    (folder / (name + "-frame.tres")).write_text(frame)
    for slot in ("card", "icon", "reduced_motion", "in_play"):
        item["assets"][slot] = resource + "-card.tres"
    item["assets"]["rarity_treatment"] = resource + "-frame.tres"
    if category == "pin":
        identity = {"grower": 4, "rubber": 5}[name]
        (folder / (name + "-material.tres")).write_text(f'''[gd_resource type="ShaderMaterial" load_steps=2 format=3]

[ext_resource type="Shader" path="res://assets/items/pins/identity.gdshader" id="1"]

[resource]
shader = ExtResource("1")
shader_parameter/identity = {identity}
''')
        item["assets"]["in_play"] = resource + "-material.tres"
catalogue_path.write_text(json.dumps(catalogue, indent=2) + "\n")
