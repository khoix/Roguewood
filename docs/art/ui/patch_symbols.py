"""Adds the symbols the interface uses to the bundled OFL font, in place.
Usage: python3 docs/art/ui/patch_symbols.py assets/ui/fonts/PixelifySans.ttf
Requires fontTools. Run it again after any change; it replaces its own glyphs.

Why: the face had no glyph for these characters. A desktop borrows them from a
system font; a browser has none to borrow, so a phone drew a "missing glyph" box
for every rarity seal, the rule badge's information mark and the arrows.

Each glyph is original pixel work for Roguewood on the font's own grid (a pixel
is 91 units wide and 92 tall; capitals are seven rows from -12), under OFL 1.1.
tests/font_coverage_test.gd fails if the game's text uses a character the font
still lacks, so a new symbol is added here first.
"""
import sys
from fontTools.ttLib import TTFont
from fontTools.pens.ttGlyphPen import TTGlyphPen

PITCH_X, PITCH_Y, LEFT, BASE, OVERDRAW, RIGHT = 91, 92, 60, -12, 10, 61

# Rows read top to bottom; the last row sits on the baseline unless `lift` raises it.
GLYPHS = {
    0x25A0: ("blacksquare", 1, ["#####", "#####", "#####", "#####", "#####"]),
    0x2161: ("romantwo", 0, ["#####", ".#.#.", ".#.#.", ".#.#.", ".#.#.", ".#.#.", "#####"]),
    0x25C6: ("blackdiamond", 0, ["...#...", "..###..", ".#####.", "#######", ".#####.", "..###..", "...#..."]),
    0x2726: ("fourpointstar", 0, ["...#...", "...#...", "..###..", "#######", "..###..", "...#...", "...#..."]),
    0x265B: ("crown", 0, ["#..#..#", "#..#..#", "##.#.##", "#######", "#######", ".......", "#######"]),
    0x24D8: ("circledi", 0, [".#####.", "#..#..#", "#.....#", "#..#..#", "#..#..#", "#..#..#", ".#####."]),
    0x25CB: ("whitecircle", 1, [".###.", "#...#", "#...#", "#...#", ".###."]),
    0x2192: ("arrowright", 1, ["....#..", ".....#.", "#######", ".....#.", "....#.."]),
    0x2193: ("arrowdown", 0, ["...#...", "...#...", "...#...", "#..#..#", ".#.#.#.", "..###..", "...#..."]),
    0x25B6: ("triangleright", 0, ["#....", "##...", "###..", "####.", "###..", "##...", "#...."]),
    0x25C0: ("triangleleft", 0, ["....#", "...##", "..###", ".####", "..###", "...##", "....#"]),
    0x2715: ("crossmark", 1, ["#...#", ".#.#.", "..#..", ".#.#.", "#...#"]),
    0x2717: ("ballotx", 1, ["#...#", ".#.#.", "..#..", ".#.#.", "#...#"]),
    0x2713: ("checkmark", 1, ["......#", ".....#.", "#...#..", ".#.#...", "..#...."]),
    0x21BB: ("turnclockwise", 0, ["..###.#", ".#...##", "#...###", "#......", "#.....#", ".#...#.", "..###.."]),
    0x21BA: ("turnanticlockwise", 0, ["#.###..", "##...#.", "###...#", "......#", "#.....#", ".#...#.", "..###.."]),
    0x230A: ("floorleft", 0, ["#..", "#..", "#..", "#..", "#..", "#..", "###"]),
    0x230B: ("floorright", 0, ["..#", "..#", "..#", "..#", "..#", "..#", "###"]),
}

def outline(rows, lift):
    """One rectangle per run of pixels in a row; rows meet exactly, so nothing overlaps."""
    pen = TTGlyphPen(None)
    for index, row in enumerate(rows):
        y0 = BASE + PITCH_Y * (len(rows) - 1 - index + lift)
        y1 = y0 + PITCH_Y
        col = 0
        while col < len(row):
            if row[col] != "#":
                col += 1
                continue
            end = col
            while end < len(row) and row[end] == "#":
                end += 1
            x0, x1 = LEFT + PITCH_X * col, LEFT + PITCH_X * end + OVERDRAW
            pen.moveTo((x0, y0)); pen.lineTo((x0, y1)); pen.lineTo((x1, y1)); pen.lineTo((x1, y0)); pen.closePath()
            col = end
    return pen.glyph()

def main(path):
    font = TTFont(path)
    for tag in font.keys():
        font[tag] # read every table before the glyph order grows
    order = font.getGlyphOrder()
    widths = font["HVAR"].table.AdvWidthMap
    classes = font["GDEF"].table.GlyphClassDef.classDefs
    for code, (name, lift, rows) in GLYPHS.items():
        assert len({len(row) for row in rows}) == 1, name
        glyph_name = "rw." + name
        if glyph_name not in order:
            order.append(glyph_name)
        font["glyf"][glyph_name] = outline(rows, lift)
        font["hmtx"][glyph_name] = (LEFT + PITCH_X * len(rows[0]) + OVERDRAW + RIGHT, LEFT)
        font["gvar"].variations[glyph_name] = [] # the symbols keep one weight
        if widths is not None:
            widths.mapping[glyph_name] = widths.mapping["H"]
        classes[glyph_name] = 1
        for table in font["cmap"].tables:
            table.cmap[code] = glyph_name
    font.setGlyphOrder(order)
    font.save(path)
    print("patched %d symbols into %s" % (len(GLYPHS), path))

if __name__ == "__main__":
    main(sys.argv[1])
