"""House theme resource bindings and original loop. Never edits image pixels.
Run with Python 3 and numpy. Exact generated PNG/prompt remain in the drop folder.
"""
import json, math, wave, hashlib
from pathlib import Path
import numpy as np
ROOT=Path(__file__).resolve().parents[1];D=ROOT/'assets/leagues/house'
spec=json.loads((ROOT/'content/leagues/house.json').read_text())
assets={};stages=[]
intents=['Worn club arch','Restored slatted bay','Service gallery','Vintage truss room','Star-tile colonnade','Brass mezzanine','Walnut trophy gallery','Grand House hall','Championship double arch']
def save(id,suffix,text):
 p=D/(id+suffix);p.write_text(text);assets[id]='res://'+str(p.relative_to(ROOT));return assets[id]
for i in range(9):
 tag=f'division_{i+1:02d}' if i<8 else 'championship';n=min(i+1,8)
 backdrop='backdrop.league.house.'+tag;sign='signage.league.house.'+tag;env='environment.league.house.'+tag
 row,col=divmod(i,3);top=[0,341,682][row];bottom=[341,682,1024][row]
 bp=save(backdrop,'.tres',f'''[gd_resource type="AtlasTexture" load_steps=2 format=3]
[ext_resource type="Texture2D" path="res://assets/leagues/house/source.environment.png" id="1"]
[resource]
atlas = ExtResource("1")
region = Rect2({col*512+2}, {top+2}, 508, {bottom-top-4})
filter_clip = true
''')
 sp=save(sign,'.tres',f'''[gd_resource type="Resource" load_steps=2 format=3]
[ext_resource type="Script" path="res://assets/leagues/house/signage.gd" id="1"]
[resource]
script = ExtResource("1")
asset_id = "{sign}"
league_title = "HOUSE"
subtitle = "{'CHAMPIONSHIP' if i==8 else f'DIVISION {n:02d}'}"
division = {n}
championship = {'true' if i==8 else 'false'}
''')
 save(env,'.tscn',f'''[gd_scene load_steps=4 format=3]
[ext_resource type="Script" path="res://assets/leagues/house/environment.gd" id="1"]
[ext_resource type="Texture2D" path="{bp}" id="2"]
[ext_resource type="Resource" path="{sp}" id="3"]
[node name="HouseEnvironment" type="Node3D"]
script = ExtResource("1")
asset_id = "{env}"
backdrop = ExtResource("2")
signage = ExtResource("3")
''')
 stages.append(dict(division=n,championship=i==8,name='House Championship' if i==8 else spec['divisions'][i]['name'],environment_id=env,signage_id=sign,backdrop_id=backdrop,art_intent=intents[i]))
lanes=[]
for dry,tag in enumerate(['house_oil','dry_backend']):
 id='lane_visual.lane_condition.'+tag
 save(id,'.tres',f'''[gd_resource type="ShaderMaterial" load_steps=2 format=3]
[ext_resource type="Shader" path="res://assets/leagues/house/lane.gdshader" id="1"]
[resource]
shader = ExtResource("1")
shader_parameter/dry_backend = {'true' if dry else 'false'}
shader_parameter/oil_end_f = 12.192
shader_parameter/deck_start_f = 17.288
''')
 lanes.append(dict(condition_id='lane_condition.'+tag,visual_id=id,name='Dry Backend' if dry else 'House Oil',oil_end_f=12.192,deck_start_f=17.288))
# Original 16-bar, 90 BPM composition. Wrap released voices and delay tails into
# the beginning of the PCM loop; never hard-cut an oscillator at the boundary.
rate=22050;bpm=90;beat=60/bpm;bars=16;length=round(rate*beat*bars*4)
mix=np.zeros((length,2),dtype=np.float64);rng=np.random.default_rng(220601)
def hz(note):return 440*2**((note-69)/12)
def add(voice,start,gain=1,pan=0):
 idx=(round(start*rate)+np.arange(len(voice)))%length
 mix[idx,0]+=voice*gain*math.sqrt((1-pan)*.5);mix[idx,1]+=voice*gain*math.sqrt((1+pan)*.5)
def key(note,duration):
 t=np.arange(round((duration+.8)*rate))/rate;f=hz(note)
 env=(1-np.exp(-t*75))*np.exp(-t/(duration*.85+.16))*np.clip((duration+.8-t)/.35,0,1)
 return (np.sin(2*np.pi*f*t+.65*np.sin(2*np.pi*f*2*t)*np.exp(-t*4))+.12*np.sin(2*np.pi*f*3*t))*env
chords=[[50,57,60,64,65],[46,53,57,60,62],[48,53,57,60,64],[48,55,58,62,65]]
roots=[38,34,41,36]
melody=[[74,77,76,69],[72,69,65,67],[69,72,76,74],[70,69,67,64]]
for bar in range(bars):
 at=bar*4*beat;phrase=bar//4;h=bar%4
 for j,note in enumerate(chords[h]):
  add(key(note,2.8*beat),at+j*.018,.055,(-.48+j*.24))
  if phrase in [1,3]:add(key(note,1.1*beat),at+2.5*beat+j*.012,.022,(-.35+j*.175))
 for offset,note in [(0,roots[h]),(1.75,roots[h]),(2.5,roots[h]+7)]:
  t=np.arange(round(.65*rate))/rate;f=hz(note)
  bass=(np.sin(2*np.pi*f*t)+.2*np.sin(2*np.pi*2*f*t))*np.minimum(t/.012,1)*np.exp(-t*6)*np.minimum((.65-t)/.05,1)
  add(bass,at+offset*beat,.15)
 if bar>=2:
  for j,offset in enumerate([.5,1.25,2.0,3.25]):
   # The last phrase answers down an octave rather than repeating a sample.
   note=melody[h][j]-(12 if phrase==3 and j>1 else 0)
   add(key(note,.36*beat),at+offset*beat,.047 if phrase else .033,(-.2 if j%2 else .2))
 for offset in [0,2]:
  t=np.arange(round(.23*rate))/rate
  kick=np.sin(2*np.pi*(48*t+5*(1-np.exp(-t*28))))*np.exp(-t*24)*np.minimum(t/.004,1)
  add(kick,at+offset*beat,.13)
 for offset in [1,3]:
  t=np.arange(round(.14*rate))/rate;noise=rng.uniform(-1,1,len(t));smooth=np.convolve(noise,np.ones(5)/5,'same')
  brush=(noise-smooth)*np.exp(-t*36)*np.minimum(t/.008,1)
  add(brush,at+offset*beat,.025,.12)
 for step in range(8):
  t=np.arange(round(.065*rate))/rate;noise=rng.uniform(-1,1,len(t))
  hat=np.diff(noise,prepend=0)*np.exp(-t*75)*np.minimum(t/.003,1)
  add(hat,at+(step*.5+(.035 if step%2 else 0))*beat,.009 if step%2 else .006,-.38)
# Original short stereo room/tape reflections, circular for an intact seam.
room=mix.copy()
for delay,gain in [(.1875*beat,.13),(.375*beat,.08),(.75*beat,.045)]:mix+=np.roll(room,round(delay*rate),axis=0)[:,::-1]*gain
mix-=mix.mean(axis=0);mix=np.tanh(mix*1.3);mix*=.68/np.max(np.abs(mix))
pcm=np.round(mix*32767).astype('<i2');id='music.league.house.after_hours';audio=D/(id+'.wav')
with wave.open(str(audio),'wb') as out:out.setparams((2,2,rate,0,'NONE','not compressed'));out.writeframes(pcm.tobytes())
assets[id]='res://'+str(audio.relative_to(ROOT))
source_path=assets[id];imported='res://.godot/imported/'+audio.name+'-'+hashlib.md5(source_path.encode()).hexdigest()+'.sample'
metadata=audio.with_suffix('.wav.import')
if not metadata.exists():
 metadata.write_text(f'[remap]\nimporter="wav"\ntype="AudioStreamWAV"\npath="{imported}"\n[deps]\nsource_file="{source_path}"\ndest_files=["{imported}"]\n[params]\nforce/8_bit=false\nforce/mono=false\nforce/max_rate=false\nforce/max_rate_hz=44100\nedit/trim=false\nedit/normalize=false\nedit/loop_mode=2\nedit/loop_begin=0\nedit/loop_end=-1\ncompress/mode=0\n')
else:
 import re
 text=metadata.read_text();text=re.sub(r'edit/loop_mode=\d+', 'edit/loop_mode=2', text);text=re.sub(r'compress/mode=\d+', 'compress/mode=0', text);metadata.write_text(text)

manifest=dict(schema_version=1,league_id='league.house',source='res://assets/leagues/house/source.environment.png',stages=stages,lanes=lanes,assets=assets,music=dict(asset_id=id,bpm=bpm,bars=bars,sample_rate=rate,frames=length,seconds=length/rate,peak=float(np.max(np.abs(mix))),rms=float(np.sqrt(np.mean(mix**2))),seam_delta=float(np.max(np.abs(mix[0]-mix[-1]))),sha256=hashlib.sha256(audio.read_bytes()).hexdigest()))
(D/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print(json.dumps(manifest['music'],indent=2));print(len(assets),'stable asset IDs')
