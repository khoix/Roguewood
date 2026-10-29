"""Bind unchanged generated source art to exact D04 IDs; original recipes/foley."""
from pathlib import Path
from PIL import Image
import json,subprocess,sys,math,struct,wave
ROOT=Path(__file__).resolve().parents[1];D=ROOT/'assets/items/d04'
BATCHES={'AV-C04-A':[
 ('pin_mod.brass_cap','cap_tick','metal',1060,.19,'ddc087',2),
 ('pin_mod.gilt_leaf','leaf_coin','paper',1180,.25,'e3c56f',2),
 ('pin_mod.keystone','key_count','wood',420,.28,'bcb5a2',3)]}
name=sys.argv[1];rows=BATCHES[name]
p=ROOT/'content/catalogue.json';data=json.loads(p.read_text());items={i['id']:i for i in data['items']}
designs={d['id']:d['design']['asset_ids'] for d in json.loads((ROOT/'content/catalogue/batches/E17-D04.json').read_text())['landed']}
source=D/('source.'+name+'.png')
with Image.open(source) as im:
 assert im.mode=='RGBA'
 width,height=im.size;alpha=im.getchannel('A').point(lambda value: 255 if value>16 else 0)
 for index,row in enumerate(rows):
  id,shape,material,pitch,seconds,color,priority=row;item=items[id];ids=designs[id]
  left=index*width//len(rows);right=(index+1)*width//len(rows)
  # Ignore near-invisible alpha specks when measuring the view.
  # Atlas view only: the source PNG is never edited or resampled.
  x,y,r,b=alpha.crop((left,0,right,height)).getbbox();x+=left;r+=left
  x=max(left,x-12);r=min(right,r+12);y=max(0,y-12);b=min(height,b+12)
  for slot in ['icon','card','reduced_motion']:
   file=D/(ids[slot]+'.tres')
   file.write_text(f'''[gd_resource type="AtlasTexture" load_steps=2 format=3]
[ext_resource type="Texture2D" path="res://assets/items/d04/{source.name}" id="1"]
[resource]
atlas = ExtResource("1")
region = Rect2({x}, {y}, {r-x}, {b-y})
filter_clip = true
''');item['assets'][slot]='res://'+str(file.relative_to(ROOT))
  rank=['common','uncommon','rare','epic','legendary'].index(item['rarity'])
  colors=['0.65,0.68,0.66','0.75,0.55,0.28','0.4,0.75,0.76','0.76,0.55,0.84','0.9,0.72,0.4']
  file=D/(ids['rarity_treatment']+'.tres')
  file.write_text(f'''[gd_resource type="StyleBoxFlat" format=3]
[resource]
bg_color = Color(0.06,0.10,0.13,1)
border_color = Color({colors[rank]},1)
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
''');item['assets']['rarity_treatment']='res://'+str(file.relative_to(ROOT))
  r,g,b=[int(color[i:i+2],16)/255 for i in (0,2,4)]
  file=ROOT/'assets/effects'/(ids['activation']+'.tres')
  file.write_text(f'''[gd_resource type="Resource" load_steps=2 format=3]
[ext_resource type="Script" path="res://src/presentation/ability_style.gd" id="1"]
[resource]
script = ExtResource("1")
item_id = "{id}"
shape = "{shape}"
ink = Color({r},{g},{b},1)
duration = 0.55
priority = {priority}
''');item['assets']['activation']='res://'+str(file.relative_to(ROOT))
  subprocess.run([sys.executable,str(ROOT/'tools/author_foley.py'),ids['sound'],material,str(pitch),str(seconds)],cwd=ROOT,check=True)
  if id=='pin_mod.gilt_leaf':
   # Original soft foil transient, then one restrained coin tick at 70 ms.
   audio=ROOT/'assets/audio'/(ids['sound']+'.wav')
   with wave.open(str(audio),'rb') as stream:
    rate=stream.getframerate();samples=struct.unpack('<'+'h'*stream.getnframes(),stream.readframes(stream.getnframes()))
   mixed=[]
   for i,sample in enumerate(samples):
    t=i/rate-.070
    coin=sum(gain*math.sin(2*math.pi*pitch*ratio*t)*math.exp(-t*decay) for gain,ratio,decay in [(.20,1,42),(.09,2.41,65)]) if t>=0 else 0
    mixed.append(sample/32767*.45+coin*min(1,max(0,t)*1200)*min(1,(seconds-i/rate)*80))
   peak=max(abs(v) for v in mixed)
   pcm=[round(v/peak*.48*32767) for v in mixed]
   with wave.open(str(audio),'wb') as stream:
    stream.setparams((1,2,rate,0,'NONE','not compressed'));stream.writeframes(struct.pack('<'+'h'*len(pcm),*pcm))
  item['assets']['sound']='res://assets/audio/'+ids['sound']+'.wav'
p.write_text(json.dumps(data,indent=2,ensure_ascii=False)+'\n')
p=ROOT/'assets/effects/batches.json';data=json.loads(p.read_text());data[name]=rows
p.write_text('{\n'+',\n'.join(' '+json.dumps(k)+': '+json.dumps(v,separators=(',',':')) for k,v in data.items())+'\n}\n')
print(name,': six exact slots per item; original PNG retained; flags untouched')
