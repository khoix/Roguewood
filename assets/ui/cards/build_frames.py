"""Original House card vector masters; no third-party imagery. Run to regenerate."""
from pathlib import Path
OUT=Path(__file__).parent
COLORS={'common':'bca888','uncommon':'bf9268','rare':'95d9cb','epic':'b4a1ee','legendary':'e7bc70'}
def svg(body,w=210,h=300):
 return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">{body}</svg>\n'
for rank,(name,c) in enumerate(COLORS.items()):
 body=f'''<rect x="1" y="1" width="208" height="298" rx="14" fill="#101820"/>
 <rect x="4" y="4" width="202" height="292" rx="11" fill="#{c}"/>
 <rect x="7" y="7" width="196" height="286" rx="9" fill="#573a2e"/>
 <rect x="10" y="10" width="190" height="280" rx="7" fill="#f4e6cd"/>
 <path d="M14 39H196V224H14Z" fill="#17363d" stroke="#{c}" stroke-width="2"/>
 <path d="M16 223H194M16 266H194" stroke="#bca888" stroke-width="2"/>
 <path d="M18 44H192M18 218H192" stroke="#377d83"/>
 <path d="M11 26V15Q11 11 16 11H29M181 11H195Q199 11 199 16V26M11 274V284Q11 289 16 289H29M181 289H195Q199 289 199 284V274" fill="none" stroke="#{c}" stroke-width="2"/>'''
 # Distinct corner constructions, not color-only rarity: notches, diamonds, glass rays, brass relief.
 for x,y in [(7,7),(203,7),(7,293),(203,293)]:
  if rank==0: body+=f'<rect x="{x-2}" y="{y-2}" width="4" height="4" fill="#{c}"/>'
  if rank==1: body+=f'<path d="M{x-3} {y-4}v8M{x+2} {y-4}v8" stroke="#{c}" stroke-width="2"/>'
  if rank>=2: body+=f'<path d="M{x} {y-6}l4 6-4 6-4-6Z" fill="#{c}" stroke="#101820"/>'
  if rank>=3: body+=f'<path d="M{x-6} {y}h12M{x} {y-9}v18" stroke="#{c}"/>'
 if rank>=2:
  for y in range(48,216,12):
   body+=f'<path d="M5 {y}l3 4M202 {y+4}l3 -4" stroke="#{c}"/>'
 if rank>=3:
  body+='<path d="M15 68L50 40H78L15 103Z M195 180L153 223H174L195 202Z" fill="#8976cf" opacity=".22"/>'
 if rank==4:
  body+='<path d="M74 5L86 12 94 5 105 14 116 5 124 12 136 5M74 295L86 288 94 295 105 286 116 295 124 288 136 295" fill="none" stroke="#e7bc70" stroke-width="3"/>'
  for y in range(52,216,20):
   body+=f'<path d="M12 {y}q10 4 0 12M198 {y}q-10 4 0 12" fill="none" stroke="#e7bc70"/>'
 (OUT/f'face-{name}.svg').write_text(svg(body))
body='<rect x="1" y="1" width="208" height="298" rx="14" fill="#101820"/><rect x="5" y="5" width="200" height="290" rx="10" fill="#e7bc70"/><rect x="9" y="9" width="192" height="282" rx="7" fill="#17363d"/>'
for y in range(20,285,16):
 for x in range(18,199,16):
  body+=f'<path d="M{x} {y-5}l5 5-5 5-5-5Z" fill="none" stroke="#377d83"/>'
body+='<path d="M105 44L175 150 105 256 35 150Z" fill="#101820" stroke="#e7bc70" stroke-width="3"/><path d="M105 59L164 150 105 241 46 150Z" fill="none" stroke="#c58a49"/><circle cx="105" cy="150" r="37" fill="#573a2e" stroke="#e7bc70" stroke-width="3"/><circle cx="96" cy="140" r="5" fill="#e7bc70"/><circle cx="113" cy="140" r="5" fill="#e7bc70"/><circle cx="105" cy="156" r="5" fill="#e7bc70"/><path d="M90 98h30l-15-21ZM90 202h30l-15 21Z" fill="#e7bc70"/>'
(OUT/'back.svg').write_text(svg(body))
shapes={
'value':'<path d="M7 4H25V10H20V27H12V10H7Z" fill="#f4e6cd"/><path d="M6 28H26" stroke="#e7bc70" stroke-width="2"/>',
'mult':'<path d="M8 8L24 24M24 8L8 24" stroke="#95d9cb" stroke-width="5"/>',
'money':'<circle cx="16" cy="16" r="12" fill="#e7bc70"/><path d="M21 10H12L10 16H22L20 22H11M16 6V26" fill="none" stroke="#101820" stroke-width="2"/>',
'ball':'<circle cx="16" cy="16" r="12" fill="#e7bc70"/><path d="M12 10h3v3h-3ZM19 11h3v3h-3ZM15 17h3v3h-3Z" fill="#101820"/>',
'pin':'<path d="M12 3H20L21 8 18 13 24 25 22 29H10L8 25 14 13 11 8Z" fill="#e7bc70"/><path d="M13 12H19" stroke="#101820" stroke-width="3"/>',
'charm':'<path d="M16 2L29 16 16 30 3 16Z" fill="#e7bc70"/><path d="M16 8L23 16 16 24 9 16Z" fill="none" stroke="#101820" stroke-width="2"/>',
'consumable':'<path d="M7 3H25V26L22 29 19 26 16 29 13 26 10 29 7 26Z" fill="#e7bc70"/><path d="M10 9H22M16 13V23M11 18H21" stroke="#101820" stroke-width="2"/>',
'shop_upgrade':'<path d="M5 8H10V3H22V8H27V24L16 30 5 24Z" fill="#e7bc70"/><path d="M10 22V17H15V12H20V8" fill="none" stroke="#101820" stroke-width="3"/>'}
for name,shape in shapes.items():
 (OUT/f'{name}.svg').write_text(svg('<rect width="32" height="32" rx="5" fill="#101820"/>'+shape,32,32))
