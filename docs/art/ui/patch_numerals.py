"""UI-A3: apply original numeral outlines to the bundled OFL font.
Usage: python3 docs/art/ui/patch_numerals.py INPUT.ttf OUTPUT.ttf
Input is the unmodified Pixelify Sans from the parent of UI-A3.
Requires fontTools. Original outlines by Codex for Roguewood, under OFL 1.1.
"""
import sys
from fontTools.ttLib import TTFont
from fontTools.pens.ttGlyphPen import TTGlyphPen

font = TTFont(sys.argv[1])
# Same 586-unit advance and 60-unit left bearing as the source. Curved
# shoulders and bowls intentionally depart from the alphabet's pixel forms.
paths = {
    'two': [('m',60,470),('q',75,631,290,631),('q',525,631,525,455),
            ('q',525,350,385,245),('l',190,100),('l',525,100),('l',525,0),
            ('l',60,0),('l',60,100),('l',315,300),('q',420,385,420,450),
            ('q',420,530,290,530),('q',170,530,165,455),('l',60,470)],
    'five': [('m',80,631),('l',505,631),('l',505,530),('l',185,530),
             ('l',175,365),('q',230,405,310,405),('q',525,405,525,205),
             ('q',525,-12,290,-12),('q',75,-12,60,160),('l',165,175),
             ('q',175,88,290,88),('q',420,88,420,205),('q',420,305,300,305),
             ('q',220,305,170,255),('l',70,280),('l',80,631)]
}
for name, commands in paths.items():
    pen = TTGlyphPen(None)
    for op, *coords in commands:
        if op == 'm': pen.moveTo(tuple(coords))
        elif op == 'l': pen.lineTo(tuple(coords))
        else: pen.qCurveTo(tuple(coords[:2]), tuple(coords[2:]))
    pen.closePath()
    font['glyf'][name] = pen.glyph()
    font['gvar'].variations[name] = []
# Derivative has its own family name. The resource filename remains stable
# for Godot preloads; it is not the font's user-facing family name.
for record in font['name'].names:
    if record.nameID in (1, 3, 4, 6, 16, 17):
        value = record.toUnicode().replace('Pixelify Sans', 'Roguewood Numerals').replace('PixelifySans', 'RoguewoodNumerals')
        record.string = value.encode(record.getEncoding())
font.save(sys.argv[2])
