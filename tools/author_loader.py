"""UI-10 (owner's play notes, 2026-11-15): the web loading screen's progress as a
bowling ball rolling down a short lane toward a pin, which tips over when loading
completes. Writes export_presets.cfg's html/head_include: the existing meta tags and
styles, plus pixel-art SVGs (crisp edges) and a small script that follows the
engine's own <progress id="status-progress"> (kept in place, invisible).
Run: python3 tools/author_loader.py"""
import re, urllib.parse

def pixel_svg(rows, palette, scale=1):
    h = len(rows); w = len(rows[0])
    rects = []
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch != ".":
                rects.append("<rect x='%d' y='%d' width='1' height='1' fill='%s'/>" % (x, y, palette[ch]))
    svg = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 %d %d' shape-rendering='crispEdges'>%s</svg>" % (w, h, "".join(rects))
    return "data:image/svg+xml," + urllib.parse.quote(svg, safe="/:=, ")

BALL = [
    "....bbbb....",
    "..bbhhbbbb..",
    ".bhhhbbbbbb.",
    ".bhhbbkbkbb.",
    "bbhbbbbbbbbs",
    "bbbbbbkbbbbs",
    "bbbbbbbbbbbs",
    "bbbbbbbbbbss",
    ".bbbbbbbbss.",
    ".bbbbbbbsss.",
    "..bbbbssss..",
    "....ssss....",
]
BALL_COLORS = {"b": "#23506a", "h": "#6fb3c9", "k": "#0b1116", "s": "#163747"}
PIN = [
    "..ww..",
    ".wwww.",
    ".wwww.",
    ".wwws.",
    "..ws..",
    "..rr..",
    "..ws..",
    "..rr..",
    ".wwws.",
    "wwwwws",
    "wwwwws",
    "wwwwws",
    "wwwwss",
    ".wwss.",
    ".wwss.",
    "..ss..",
]
PIN_COLORS = {"w": "#f1e6cc", "s": "#c9bfa6", "r": "#b0303a"}

STYLE = (
    "#status-progress{opacity:0;}"
    "#rw-loader{position:absolute;left:0;right:0;bottom:12%;margin:0 auto;width:min(64%,440px);height:44px;display:none;pointer-events:none;}"
    "#rw-track{position:absolute;left:0;right:0;bottom:0;height:6px;background:linear-gradient(90deg,#3a2a17,#7a5a32 40%,#e7bc70);border-radius:1px;box-shadow:0 1px 0 #0b1116;}"
    "#rw-ball{position:absolute;bottom:6px;left:0;width:28px;height:28px;image-rendering:pixelated;}"
    "#rw-pin{position:absolute;bottom:6px;right:0;width:16px;height:42px;image-rendering:pixelated;transform-origin:50% 100%;transition:transform .35s ease-in;}"
    "#rw-pin.down{transform:rotate(70deg) translate(6px,0);}"
)
SCRIPT = (
    "(function(){function go(){var st=document.getElementById('status'),pr=document.getElementById('status-progress');"
    "if(!st||!pr){requestAnimationFrame(go);return;}"
    "var lane=document.createElement('div');lane.id='rw-loader';"
    "lane.innerHTML='<div id=\"rw-track\"></div><img id=\"rw-pin\" alt=\"\" src=\"PIN\"><img id=\"rw-ball\" alt=\"\" src=\"BALL\">';"
    "st.appendChild(lane);var ball=lane.querySelector('#rw-ball'),pin=lane.querySelector('#rw-pin'),t0=performance.now();"
    "function tick(now){var known=pr.hasAttribute('value')&&pr.max>0,f=known?Math.min(Math.max(pr.value/pr.max,0),1):((now-t0)/1800)%1;"
    "lane.style.display=getComputedStyle(pr).display==='none'?'none':'block';"
    "var run=Math.max(lane.clientWidth-28-20,0);ball.style.transform='translateX('+(f*run).toFixed(1)+'px) rotate('+Math.round(f*900)+'deg)';"
    "pin.classList.toggle('down',known&&f>=0.999);lane.dataset.progress=known?f.toFixed(3):'idle';requestAnimationFrame(tick);}"
    "requestAnimationFrame(tick);}"
    "window.rwLoaderStart=go;"
    "if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',go);else go();})();"
).replace("PIN", pixel_svg(PIN, PIN_COLORS)).replace("BALL", pixel_svg(BALL, BALL_COLORS))

def main():
    path = "export_presets.cfg"
    text = open(path, encoding="utf-8").read()
    match = re.search(r'^html/head_include="(.*)"$', text, re.M)
    head = match.group(1).replace('\\"', '"')
    head = re.sub(r"<script id=\"rw-loader-js\">.*?</script>", "", head)
    head = re.sub(r"#status-progress\{[^}]*\}", "", head)
    head = re.sub(r"#rw-[^{]*\{[^}]*\}", "", head)
    head = head.replace("</style>", STYLE + "</style>", 1)
    head += '<script id="rw-loader-js">' + SCRIPT + "</script>"
    escaped = head.replace("\\", "\\\\").replace('"', '\\"')
    text = text[:match.start()] + 'html/head_include="' + escaped + '"' + text[match.end():]
    open(path, "w", encoding="utf-8").write(text)
    print("head_include: %d characters" % len(head))

if __name__ == "__main__":
    main()
