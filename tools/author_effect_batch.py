"""Emit declared effect recipes and reproducible original material sounds."""
import json,subprocess,sys
from pathlib import Path
batch=sys.argv[1]
config=json.loads(Path('assets/effects/batches.json').read_text())[batch]
p=Path('content/catalogue.json');catalogue=json.loads(p.read_text());items={e['id']:e for e in catalogue['items']}
for row in config:
 id,shape,material,pitch,duration,color,priority=row
 name=id.replace('.','_')
 effect=Path('assets/effects')/(name+'.tres')
 r,g,b=[int(color[i:i+2],16)/255 for i in (0,2,4)]
 effect.write_text(f'''[gd_resource type="Resource" load_steps=2 format=3]
[ext_resource type="Script" path="res://src/presentation/ability_style.gd" id="1"]
[resource]
script = ExtResource("1")
item_id = "{id}"
shape = "{shape}"
ink = Color({r}, {g}, {b}, 1)
duration = 0.55
priority = {priority}
''')
 subprocess.run([sys.executable,'tools/author_foley.py',name,material,str(pitch),str(duration)],check=True)
 items[id]['assets']['activation']='res://'+str(effect)
 items[id]['assets']['sound']='res://assets/audio/'+name+'.wav'
p.write_text(json.dumps(catalogue,indent=2)+'\n')
