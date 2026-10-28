"""Original V08 recipes; exact landed design IDs, flags left untouched."""
from pathlib import Path
import json, subprocess, sys
ROOT=Path(__file__).resolve().parents[1]
rows=[
 ('charm.pin_counter','tally','paper',870,.22,'e8d8aa',2),
 ('charm.hot_streak','flame_tally','wood',780,.28,'e5b665',3),
 ('charm.last_stand','standing','wood',310,.24,'bbd6cd',2),
 ('charm.tip_jar','jar_drop','glass',1320,.28,'e3c789',3),
 ('charm.banana_ball','banana_strike','swish',630,.28,'e6bf62',3),
 ('charm.plumb_line','plumb','metal',860,.20,'bedbd7',2),
 ('charm.glass_cutter','cutter','glass',2150,.22,'b2dedb',3),
 ('pin.glass','crack','crack',1780,.26,'cce9e2',4),
]
designs={}
for batch in ('E17-D01','E17-D02'):
 data=json.loads((ROOT/f'content/catalogue/batches/{batch}.json').read_text())
 designs.update({d['id']:d['design']['asset_ids'] for d in data['landed']})
p=ROOT/'content/catalogue.json';catalogue=json.loads(p.read_text());items={i['id']:i for i in catalogue['items']}
for id,shape,material,pitch,seconds,color,priority in rows:
 ids=designs[id];effect=Path('assets/effects')/(ids['activation']+'.tres')
 r,g,b=[int(color[i:i+2],16)/255 for i in (0,2,4)]
 (ROOT/effect).write_text(f'''[gd_resource type="Resource" load_steps=2 format=3]
[ext_resource type="Script" path="res://src/presentation/ability_style.gd" id="1"]
[resource]
script = ExtResource("1")
item_id = "{id}"
shape = "{shape}"
ink = Color({r}, {g}, {b}, 1)
duration = 0.55
priority = {priority}
''')
 subprocess.run([sys.executable,str(ROOT/'tools/author_foley.py'),ids['sound'],material,str(pitch),str(seconds)],cwd=ROOT,check=True)
 items[id]['assets']['activation']='res://'+str(effect)
 items[id]['assets']['sound']='res://assets/audio/'+ids['sound']+'.wav'
p.write_text(json.dumps(catalogue,indent=2,ensure_ascii=False)+'\n')
bp=ROOT/'assets/effects/batches.json';data=json.loads(bp.read_text());data['E20-V08']=rows;bp.write_text('{\n'+',\n'.join(' '+json.dumps(k)+': '+json.dumps(v,separators=(',',':')) for k,v in data.items())+'\n}\n')
print('Eight exact activation/sound pairs; flags untouched')
