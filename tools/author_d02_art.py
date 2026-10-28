"""Bind D02 artwork using designs from both definitions and landed; never set flags."""
from pathlib import Path
from PIL import Image
import json, sys
ROOT=Path(__file__).resolve().parents[1]
DIR=ROOT/'assets/items/d02'
batch_id=sys.argv[1]
groups=json.loads((DIR/'batches.json').read_text())
batch_path=ROOT/'content/catalogue/batches/E17-D02.json'
cat_path=ROOT/'content/catalogue.json'
batch=json.loads(batch_path.read_text());catalogue=json.loads(cat_path.read_text())
cat={i['id']:i for i in catalogue['items']}
entries={d['item']['id']:d for d in batch['definitions']}
entries.update({d['id']:{'item':cat[d['id']],'design':d['design']} for d in batch['landed']})
colors={'common':(0.65,0.68,0.66),'uncommon':(0.75,0.55,0.28),'rare':(0.4,0.75,0.76),'epic':(0.76,0.55,0.84)}
for id in groups[batch_id]:
 d=entries[id];item=d['item'];source=DIR/('source.'+id+'.png')
 with Image.open(source) as image:
  assert image.mode=='RGBA'
  x,y,right,bottom=image.getchannel('A').getbbox()
  x=max(0,x-12);y=max(0,y-12);right=min(image.width,right+12);bottom=min(image.height,bottom+12)
 for slot in ['icon','card','reduced_motion']:
  name=d['design']['asset_ids'][slot]+'.tres'
  (DIR/name).write_text(f'''[gd_resource type="AtlasTexture" load_steps=2 format=3]
[ext_resource type="Texture2D" path="res://assets/items/d02/{source.name}" id="1"]
[resource]
atlas = ExtResource("1")
region = Rect2({x}, {y}, {right-x}, {bottom-y})
filter_clip = true
''')
  item['assets'][slot]='res://assets/items/d02/'+name
 rank=['common','uncommon','rare','epic'].index(item['rarity']);color=', '.join(str(x) for x in colors[item['rarity']])
 name=d['design']['asset_ids']['rarity_treatment']+'.tres'
 (DIR/name).write_text(f'''[gd_resource type="StyleBoxFlat" format=3]
[resource]
bg_color = Color(0.06, 0.10, 0.13, 1)
border_color = Color({color}, 1)
border_width_left = {rank+1}
border_width_right = {rank+1}
border_width_top = 2
border_width_bottom = {rank+2}
corner_radius_top_left = {rank*3}
corner_radius_top_right = {rank*3}
corner_radius_bottom_left = {rank*3}
corner_radius_bottom_right = {rank*3}
content_margin_left = 12.0
content_margin_right = 12.0
content_margin_top = 12.0
content_margin_bottom = 12.0
''')
 item['assets']['rarity_treatment']='res://assets/items/d02/'+name
 assert not item['assets']['in_play'] and not item['assets']['activation'] and not item['assets']['sound']
for path,data in [(batch_path,batch),(cat_path,catalogue)]:path.write_text(json.dumps(data,indent=2,ensure_ascii=False)+'\n')
print(batch_id+': exact identity paths set; flags untouched.')
