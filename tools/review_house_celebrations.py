#!/usr/bin/env python3
"""Build review pages from native JUIA9HM/JUIA9HR captures; never change source art.

Run both journeys rendered first. Outputs stay in ignored artifacts/ui-a9-h/review.
Pillow is needed only for labelled contact sheets. HTML shows unscaled native CRT
crops and links to their complete phone screenshots. Story beats are held captures,
not a video recording or rendering-performance measurement.
"""
import html
import json
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / 'artifacts/ui-a9-h'
OUT = BASE / 'review'
FRAMES = [0, 10, 20, 30, 45, 60, 75, 90]


def main():
    scenes = sorted(p.stem for p in (ROOT / 'assets/ui/alley_screen/house').glob('*.tscn'))
    assert len(scenes) == 20, 'Expected the complete House set'
    OUT.mkdir(parents=True, exist_ok=True)
    index = []
    sections = []
    for orientation in ['portrait', 'landscape']:
        for mode, frames in [('motion', FRAMES), ('reduced', [10, 45, 90])]:
            peak_cards = []
            for scene in scenes:
                duration = 3.0 if scene.startswith('boss_') else (1.8 if scene.startswith('strike_') else 1.6)
                cards = []
                images = []
                for fraction in frames:
                    stem = f'{scene}_{orientation}_{fraction:02d}'
                    crop = BASE / mode / 'rendered' / (stem + '_screen.png')
                    full = crop.with_name(stem + '.png')
                    assert crop.is_file() and full.is_file(), f'Missing capture: {crop}'
                    with Image.open(crop) as image:
                        image.load()
                        images.append(image.convert('RGB'))
                        size = image.size
                    index.append({'scene': scene, 'mode': mode, 'orientation': orientation,
                                  'fraction': fraction / 100, 'seconds': duration * fraction / 100,
                                  'size': size, 'crop': str(crop.relative_to(ROOT)),
                                  'full': str(full.relative_to(ROOT))})
                    cards.append(f'<figure><a href="../{mode}/rendered/{stem}.png"><img width="{size[0]}" height="{size[1]}" src="../{mode}/rendered/{stem}_screen.png" alt="{html.escape(scene)} at {fraction}%"></a><figcaption>{fraction}% · {duration*fraction/100:.2f} s</figcaption></figure>')
                if mode == 'reduced':
                    assert all(im.tobytes() == images[0].tobytes() for im in images[1:]), f'Reduced CRT moves: {scene}/{orientation}'
                peak_cards.append((scene, images[-1]))
                sections.append(f'<details><summary>{html.escape(scene)} — {orientation}, {mode}</summary><div class="beats">'+''.join(cards)+'</div></details>')
                w, h = images[0].size
                sheet = Image.new('RGB', (2*w, ((len(images)+1)//2)*(h+24)), '#142b30')
                draw = ImageDraw.Draw(sheet)
                for i, im in enumerate(images):
                    x, y = (i%2)*w, (i//2)*(h+24)
                    draw.text((x+5,y+5), f'{frames[i]}% / {duration*frames[i]/100:.2f} s', fill='#ffdf99')
                    sheet.paste(im,(x,y+24))
                sheet.save(OUT / f'{scene}_{orientation}_{mode}.png')
            w, h = peak_cards[0][1].size
            contact = Image.new('RGB',(3*w,((len(peak_cards)+2)//3)*(h+24)),'#142b30')
            draw = ImageDraw.Draw(contact)
            for i,(scene,im) in enumerate(peak_cards):
                x,y=(i%3)*w,(i//3)*(h+24)
                draw.text((x+5,y+5),scene,fill='#ffdf99')
                contact.paste(im,(x,y+24))
            contact.save(OUT / f'{mode}_{orientation}_contact.png')
    (OUT / 'capture-index.json').write_text(json.dumps(index,indent=2)+'\n')
    contacts = ''.join(f'<li><a href="{m}_{o}_contact.png">{m} · {o}</a></li>' for m in ['motion','reduced'] for o in ['portrait','landscape'])
    page = '''<!doctype html><meta charset="utf-8"><title>House celebration review</title>
<style>body{background:#142b30;color:#f4e4c0;font:16px system-ui;margin:24px}a{color:#ffdf99}summary{padding:12px;cursor:pointer}details{border-bottom:1px solid #603c32}.beats{display:flex;overflow-x:auto;gap:16px}figure{margin:0 0 20px;flex-shrink:0}img{display:block;image-rendering:pixelated}figcaption{padding:6px}</style>
<h1>House celebrations</h1><p>Native CRT crops at 450×800 portrait and 800×450 landscape. Click an image for the complete phone screenshot. Eight held story beats show staging and timing; these are not a live recording or performance evidence. The production journey separately checks natural completion and real scoring triggers.</p>
<p>Motion uses default flash settings. Reduced uses both accessibility settings; all three reduced CRT crops are byte-identical.</p><ul>'''+contacts+'</ul>' + ''.join(sections)
    (OUT / 'index.html').write_text(page+'\n')
    print(f'{len(index)} native CRT crops indexed; 80 story sheets and 4 contact sheets in {OUT}')


if __name__ == '__main__':
    main()
