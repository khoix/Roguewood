"""UI-10 (owner's play notes, 2026-11-15): the web loading screen's progress as a
bowling ball rolling down a short lane toward a pin, which tips over when loading
completes. UI-36 (owner, 2026-11-20): on phones it lagged and the knockdown rarely
showed, so its motion is CSS the browser runs while the game starts, it loops when the
download has no known size, and it gets a short finale after the engine removes the
loading overlay. Writes export_presets.cfg's html/head_include: the existing meta tags and
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
    "#rw-loader{position:absolute;left:0;right:0;bottom:12%;margin:0 auto;width:min(64%,440px);height:44px;display:none;pointer-events:none;--f:0;}"
    "#rw-track{position:absolute;left:0;right:0;bottom:0;height:6px;background:linear-gradient(90deg,#3a2a17,#7a5a32 40%,#e7bc70);border-radius:1px;box-shadow:0 1px 0 #0b1116;overflow:hidden;}"
    "#rw-track::after{content:'';position:absolute;top:0;bottom:0;width:30%;left:-30%;background:linear-gradient(90deg,transparent,rgba(255,240,200,.55),transparent);animation:rw-shine 1.4s linear infinite;}"
    "@keyframes rw-shine{to{left:100%;}}"
    # UI-36 (owner, 2026-11-20): every motion is a CSS animation or transition, which
    # the browser keeps playing while a phone's main thread compiles and starts the
    # game; JavaScript only sets where the ball should be (--f, eased by a transition).
    "#rw-roll{position:absolute;left:0;right:0;bottom:6px;height:28px;transform:translateX(calc((100% - 48px) * var(--f)));transition:transform .5s linear;}"
    "#rw-bob{position:absolute;left:0;bottom:0;width:28px;height:28px;animation:rw-bob .36s ease-in-out infinite alternate;}"
    "@keyframes rw-bob{to{transform:translateY(-3px);}}"
    "#rw-ball{width:28px;height:28px;image-rendering:pixelated;animation:rw-spin .55s linear infinite;}"
    "@keyframes rw-spin{to{transform:rotate(360deg);}}"
    "#rw-pin{position:absolute;bottom:6px;right:0;width:16px;height:42px;image-rendering:pixelated;transform-origin:50% 100%;transition:transform .35s ease-in;}"
    "#rw-pin.down{transform:rotate(70deg) translate(6px,0);}"
    # No total from the server (a compressed download): roll to the pin and knock it over, again and again.
    "#rw-loader.idle #rw-roll{transition:none;animation:rw-run 1.8s linear infinite;}"
    "@keyframes rw-run{0%{transform:translateX(0);}78%,100%{transform:translateX(calc(100% - 48px));}}"
    "#rw-loader.idle #rw-pin{transition:none;animation:rw-knock 1.8s linear infinite;}"
    "@keyframes rw-knock{0%,76%{transform:none;}82%,96%{transform:rotate(70deg) translate(6px,0);}100%{transform:none;}}"
    # The finale: the ball reaches the pin, the pin falls, then the screen fades into the game.
    "#rw-loader.finale #rw-pin{transition-delay:.4s;}"
)
SCRIPT = (
    "(function(){function go(root){var st=root instanceof Element?root:document.getElementById('status'),pr=st&&st.querySelector('#status-progress');"
    "if(!st||!pr){requestAnimationFrame(function(){go(root);});return;}"
    "var lane=document.createElement('div');lane.id='rw-loader';"
    "lane.innerHTML='<div id=\"rw-track\"></div><img id=\"rw-pin\" alt=\"\" src=\"PIN\"><div id=\"rw-roll\"><div id=\"rw-bob\"><img id=\"rw-ball\" alt=\"\" src=\"BALL\"></div></div>';"
    "st.appendChild(lane);var pin=lane.querySelector('#rw-pin'),host=st.parentNode,ending=false;"
    "function tick(){if(ending)return;var known=pr.hasAttribute('value')&&pr.max>0,f=known?Math.min(Math.max(pr.value/pr.max,0),1):0;"
    "lane.style.display=getComputedStyle(pr).display==='none'?'none':'block';lane.classList.toggle('idle',!known);"
    "lane.style.setProperty('--f',f.toFixed(3));pin.classList.toggle('down',known&&f>=0.999);lane.dataset.progress=known?f.toFixed(3):'idle';"
    "requestAnimationFrame(tick);}"
    # The engine removes its loading overlay the moment the game starts; put it back briefly for the knockdown.
    "function finale(){if(ending||st.isConnected||!host)return;ending=true;lane.classList.remove('idle');lane.classList.add('finale');"
    "lane.style.display='block';lane.style.setProperty('--f','1');lane.dataset.progress='1.000';"
    "st.style.pointerEvents='none';st.style.visibility='visible';st.style.transition='opacity .45s ease';host.appendChild(st);"
    "requestAnimationFrame(function(){pin.classList.add('down');});"
    "setTimeout(function(){st.style.opacity='0';},900);setTimeout(function(){st.remove();},1400);}"
    "if(host)new MutationObserver(finale).observe(host,{childList:true});"
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
    head = re.sub(r"@keyframes rw-[a-z]+\{[^{}]*\{[^}]*\}\}", "", head)
    head = re.sub(r"#rw-[^{]*\{[^}]*\}", "", head)
    head = head.replace("</style>", STYLE + "</style>", 1)
    head += '<script id="rw-loader-js">' + SCRIPT + "</script>"
    escaped = head.replace("\\", "\\\\").replace('"', '\\"')
    text = text[:match.start()] + 'html/head_include="' + escaped + '"' + text[match.end():]
    open(path, "w", encoding="utf-8").write(text)
    print("head_include: %d characters" % len(head))

if __name__ == "__main__":
    main()
