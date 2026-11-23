"""AV-N4 resources. Generated PNGs remain byte-identical: atlas views only.
Usage: python3 tools/author_neon_n4_items.py A|B. Flags are enabled after native QA.
"""
from pathlib import Path
import json, subprocess, sys
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
DEST=ROOT/'assets/items/neon'
GROUPS={'A':['shop_upgrade.trade_in','shop_upgrade.specialist_shelf','ball.comet'], 'B':['charm.metronome','consumable.steady_hand']}
INKS=['0.58, 0.85, 0.80, 1','0.49, 0.86, 0.95, 1','0.91, 0.74, 0.44, 1']
group=sys.argv[1]; ids=GROUPS[group]; source=DEST/f'source.AV-N4-{group}.png'
image=Image.open(source); assert image.mode=='RGBA'
data=json.loads((ROOT/'content/catalogue.json').read_text())
for i,id in enumerate(ids):
 item=next(x for x in data['items'] if x['id']==id)
 left=round(image.width*i/len(ids));right=round(image.width*(i+1)/len(ids))
 bounds=image.getchannel('A').crop((left,0,right,image.height)).getbbox(); assert bounds
 x,y,r,b=bounds;x=max(left,left+x-12);r=min(right,left+r+12);y=max(0,y-12);b=min(image.height,b+12)
 for slot in ['card','icon','reduced_motion']:
  path=DEST/f'{slot}.{id}.tres'
  path.write_text(f'''[gd_resource type="AtlasTexture" load_steps=2 format=3]
[ext_resource type="Texture2D" path="res://assets/items/neon/{source.name}" id="1"]
[resource]
atlas = ExtResource("1")
region = Rect2({x}, {y}, {r-x}, {b-y})
filter_clip = true
''')
  item['assets'][slot]='res://'+str(path.relative_to(ROOT))
 path=DEST/f'rarity_treatment.{id}.tres'
 path.write_text(f'''[gd_resource type="StyleBoxFlat" format=3]
[resource]
bg_color = Color(0.055, 0.075, 0.12, 1)
border_width_left = 2
border_width_top = 2
border_width_right = 2
border_width_bottom = 2
border_color = Color({INKS[i]})
corner_radius_top_left = 8
corner_radius_top_right = 8
corner_radius_bottom_left = 8
corner_radius_bottom_right = 8
content_margin_left = 12.0
content_margin_right = 12.0
content_margin_top = 12.0
content_margin_bottom = 12.0
''')
 item['assets']['rarity_treatment']='res://'+str(path.relative_to(ROOT))
 path=DEST/f'activation.{id}.tres'
 path.write_text(f'''[gd_resource type="Resource" script_class="" load_steps=2 format=3]
[ext_resource type="Script" path="res://src/presentation/ability_style.gd" id="1"]
[resource]
script = ExtResource("1")
item_id = "{id}"
shape = "neon"
ink = Color({INKS[i]})
duration = 0.85
priority = 3
''')
 item['assets']['activation']='res://'+str(path.relative_to(ROOT))
 material,pitch=[('paper',520),('metal',740),('swish',870)][i] if group=='A' else [('wood',610),('cloth',420)][i]
 subprocess.run([sys.executable,str(ROOT/'tools/author_foley.py'),'sound.'+id,material,str(pitch),'0.32'],cwd=ROOT,check=True)
 item['assets']['sound']=f'res://assets/audio/sound.{id}.wav'
 item['assets']['in_play']='res://assets/items/neon/in_play.ball.comet.tres' if id=='ball.comet' else item['assets']['icon']
(ROOT/'content/catalogue.json').write_text(json.dumps(data,indent=2)+'\n')
