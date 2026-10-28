"""Bind unmodified original PNGs to the exact authored IDs; no gameplay flags."""
from pathlib import Path
import json, sys
from PIL import Image
ROOT = Path(__file__).resolve().parents[1]
DIR = ROOT / 'assets/items/d01'
BATCHES = {'E19-A08':['ball.gold','pin.glass','pin.fuse','pin.crown'],
'E19-A09':['pin.echo','consumable.nudge','consumable.reserve_call','consumable.rule_waiver'],
'E19-A10':['ball.spark'],'E19-A11':['ball.ghost'],'E19-A12':['ball.splitter']}
COLORS = {'common':(0.65,0.68,0.66),'uncommon':(0.75,0.55,0.28),'rare':(0.4,0.75,0.76),'epic':(0.76,0.55,0.84)}
batch = sys.argv[1]
p = ROOT/'content/catalogue/batches/E17-D01.json'
data = json.loads(p.read_text())
for d in data['definitions']:
 item=d['item'];id=item['id']
 if id not in BATCHES[batch]: continue
 source=DIR/('source.'+id+'.png')
 with Image.open(source) as image:
  assert image.mode=='RGBA',source
  bounds=image.getchannel('A').getbbox();assert bounds
  x,y,right,bottom=bounds
  # Atlas view only: original generated PNG remains byte-for-byte untouched.
  pad=12;x=max(0,x-pad);y=max(0,y-pad);right=min(image.width,right+pad);bottom=min(image.height,bottom+pad)
  region=f'{x}, {y}, {right-x}, {bottom-y}'
 for slot in ['card','icon','reduced_motion']:
  aid=d['design']['asset_ids'][slot];name=aid+'.tres'
  (DIR/name).write_text(f'''[gd_resource type="AtlasTexture" load_steps=2 format=3]
[ext_resource type="Texture2D" path="res://assets/items/d01/{source.name}" id="1"]
[resource]
atlas = ExtResource("1")
region = Rect2({region})
filter_clip = true
''')
  item['assets'][slot]='res://assets/items/d01/'+name
 aid=d['design']['asset_ids']['rarity_treatment'];name=aid+'.tres'
 rgb=', '.join(str(v) for v in COLORS[item['rarity']]);rank=['common','uncommon','rare','epic'].index(item['rarity'])
 (DIR/name).write_text(f'''[gd_resource type="StyleBoxFlat" format=3]
[resource]
bg_color = Color(0.06, 0.10, 0.13, 1)
border_color = Color({rgb}, 1)
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
 item['assets']['rarity_treatment']='res://assets/items/d01/'+name
 if 'in_play' in d['design']['asset_ids']:
  name=d['design']['asset_ids']['in_play']+'.tscn'
  (DIR/name).write_text(f'''[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://assets/items/d01/identity.gd" id="1"]
[node name="Identity" type="Node3D"]
script = ExtResource("1")
item_id = "{id}"
''')
  item['assets']['in_play']='res://assets/items/d01/'+name
 assert not item['completeness']['artwork']
 assert not item['assets']['activation'] and not item['assets']['sound']
p.write_text(json.dumps(data,indent=2,ensure_ascii=False)+'\n')
(DIR/'batches.json').write_text(json.dumps(BATCHES,indent=2)+'\n')
print(batch+': exact identity slots bound; completeness and effect/audio paths unchanged.')
