"""Wave 5 three-item AV sessions. Original foley; flags are never authored here."""
from pathlib import Path
import json, subprocess, sys
ROOT=Path(__file__).resolve().parents[1]
BATCHES={
 'AV-C03-B':[
  ('charm.sweet_spot','grade_pair','glass',1490,.24,'a9d8d0',2),
  ('charm.back_row','back_four','wood',530,.26,'d8c498',2),
  ('charm.underdog','half_target','metal',470,.30,'c7c6df',3),
 ],
 'AV-C03-A':[
  ('pin.crown','crown_last','metal',1180,.30,'e9c179',3),
  ('charm.crown_jewel','jewel_last','glass',1660,.34,'d1b6e8',3),
  ('charm.split_specialist','split_leave','metal',640,.26,'b8d6d0',2),
 ],
}
name=sys.argv[1]; rows=BATCHES[name]
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
bp=ROOT/'assets/effects/batches.json'; data=json.loads(bp.read_text()); data[name]=rows
bp.write_text('{\n'+',\n'.join(' '+json.dumps(k)+': '+json.dumps(v,separators=(',',':')) for k,v in data.items())+'\n}\n')
print(name, 'exact activation/sound pairs; flags untouched')
