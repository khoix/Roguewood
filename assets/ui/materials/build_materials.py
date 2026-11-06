"""Original UI-A2 resource bindings and icons. No external image sources."""
import json
from pathlib import Path
root=Path(__file__).parent
rarities=['common','uncommon','rare','epic','legendary']
manifest={'schema_version':1,'canonical_size':[210,300],'leagues':{'league.house':{}},'fallback_league':'league.house','icons':{}}
for rank,name in enumerate(rarities):
 for reduced in [False,True]:
  suffix='-reduced' if reduced else ''
  (root/f'house-{name}{suffix}.tres').write_text(f'''[gd_resource type="ShaderMaterial" load_steps=2 format=3]
[ext_resource type="Shader" path="res://assets/ui/materials/house_foil.gdshader" id="1"]
[resource]
shader = ExtResource("1")
shader_parameter/rarity = {rank}
shader_parameter/reduced = {str(reduced).lower()}
shader_parameter/progress = 0.42
''')
 manifest['leagues']['league.house'][name]={'frame':f'res://assets/ui/cards/face-{name}.svg','overlay':f'res://assets/ui/materials/house-{name}.tres','reduced':f'res://assets/ui/materials/house-{name}-reduced.tres'}
# Existing score/category symbols remain stable; new action marks share the same plate.
for name in ['value','mult','money','ball','pin','charm','consumable','shop_upgrade']:
 manifest['icons'][name]=f'res://assets/ui/cards/{name}.svg'
shapes={
 'cycle':'<path d="M8 12a9 9 0 0 1 16 2M24 20a9 9 0 0 1-16-2M19 13l6 2 1-6M13 19l-6-2-1 6"/>',
 'inspect':'<circle cx="14" cy="13" r="8"/><path d="M20 20l7 7"/>',
 'deck':'<path d="M6 9H22V28H6ZM10 5H26V24M14 2H29V20"/>',
 'discard':'<path d="M4 4H19V23H4ZM12 10H27V29H12ZM16 16l7 7M23 16l-7 7"/>',
 'options':'<path d="M5 8H27M5 16H27M5 24H27M11 4V12M22 12V20M14 20V28"/>',
 'target':'<circle cx="16" cy="16" r="11"/><circle cx="16" cy="16" r="5"/><path d="M16 1V8M16 24V31M1 16H8M24 16H31"/>',
 'lock':'<path d="M9 14V9a7 7 0 0 1 14 0V14M6 14H26V29H6ZM16 19V24"/>',
 'armed':'<path d="M5 17l7 8L27 7"/>',
 'sold':'<path d="M4 5H19L29 16 17 29 4 16Z"/><circle cx="10" cy="11" r="2"/><path d="M11 20l4 4 8-9"/>'}
for name,shape in shapes.items():
 path=root.parent/'icons'/f'{name}.svg'
 path.write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32"><rect width="32" height="32" rx="5" fill="#101820"/><g fill="none" stroke="#e7bc70" stroke-width="2" stroke-linecap="square" stroke-linejoin="miter">{shape}</g></svg>\n')
 manifest['icons'][name]=f'res://assets/ui/icons/{name}.svg'
(root/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
