"""Original Roguewood House nine-slice vector masters; no third-party art."""
from pathlib import Path
import json
D=Path(__file__).parent
specs={'hud':('101820','e7bc70',12),'shop':('17363d','c58a49',16),'slip':('f4e6cd','bca888',12),'menu':('241f22','e7bc70',16),'panel':('17363d','377d83',12)}
def svg(body,w=64,h=64):return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}">{body}</svg>\n'
for name,(fill,edge,margin) in specs.items():
 body=f'<path d="M8 0H56L64 8V56L56 64H8L0 56V8Z" fill="#101820"/><path d="M8 2H56L62 8V56L56 62H8L2 56V8Z" fill="#{edge}"/><path d="M8 4H56L60 8V56L56 60H8L4 56V8Z" fill="#573a2e"/><rect x="7" y="7" width="50" height="50" fill="#{fill}"/>'
 if name in ('menu','shop'):
  body+='<path d="M16 5H48M16 59H48M5 16V48M59 16V48" stroke="#93623e" stroke-width="2"/>'
 for x,y in [(9,9),(55,9),(9,55),(55,55)]:
  body+=f'<path d="M{x-5} {y}h10M{x} {y-5}v10" stroke="#{edge}" stroke-width="2"/><rect x="{x-2}" y="{y-2}" width="4" height="4" fill="#f4e6cd"/>'
 if name=='slip':
  body+='<path d="M16 5H20M24 5H28M32 5H36M40 5H44M48 5H52M16 59H20M24 59H28M32 59H36M40 59H44M48 59H52" stroke="#573a2e" stroke-width="2"/>'
 (D/f'{name}.svg').write_text(svg(body))
 (D/f'{name}.tres').write_text(f'''[gd_resource type="StyleBoxTexture" load_steps=2 format=3]
[ext_resource type="Texture2D" path="res://assets/ui/house/{name}.svg" id="1"]
[resource]
texture = ExtResource("1")
texture_margin_left = {margin}.0
texture_margin_top = {margin}.0
texture_margin_right = {margin}.0
texture_margin_bottom = {margin}.0
axis_stretch_horizontal = 1
axis_stretch_vertical = 1
content_margin_left = {margin+8}.0
content_margin_top = {margin+8}.0
content_margin_right = {margin+8}.0
content_margin_bottom = {margin+8}.0
''')
(D/'corner.svg').write_text(svg('<path d="M2 30V8L8 2H30M7 26V12L12 7H26" fill="none" stroke="#e7bc70" stroke-width="2"/><path d="M13 13L23 16 16 23Z" fill="#c58a49"/><rect x="9" y="9" width="4" height="4" fill="#f4e6cd"/>',32,32))
(D/'divider.svg').write_text(svg('<path d="M0 8H48M80 8H128M12 12H44M84 12H116" stroke="#c58a49" stroke-width="2"/><path d="M64 2L73 8 64 14 55 8Z" fill="#e7bc70"/><rect x="62" y="6" width="4" height="4" fill="#17363d"/>',128,16))
(D/'manifest.json').write_text(json.dumps({'schema_version':1,'frames':{f'ui.house.{n}':{'path':f'res://assets/ui/house/{n}.tres','source_px':[64,64],'slice_px':m,'content_inset_px':m+8,'minimum_px':[2*m+16,2*m+16]} for n,(_,_,m) in specs.items()},'ornaments':['res://assets/ui/house/corner.svg','res://assets/ui/house/divider.svg'],'font':'res://assets/ui/fonts/PixelifySans.ttf'},indent=2)+'\n')
