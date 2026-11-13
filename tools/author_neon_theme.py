"""Original E22-L02-ART frames, resource bindings and synthesized music.
No image editing. Run with Python 3 and numpy; preserves session 1 stage bindings.
"""
import hashlib
import json
import math
import wave
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
D = ROOT / "assets/leagues/neon"
UI = ROOT / "assets/ui/neon"
UI.mkdir(exist_ok=True)
manifest = json.loads((D / "manifest.json").read_text())
assets = manifest["assets"]

def save(path, text):
    path.write_text(text)
    return "res://" + str(path.relative_to(ROOT))

lanes = [{"condition_id": "lane_condition.house_oil", "visual_id": "lane_visual.lane_condition.house_oil",
          "name": "House Oil", "oil_end_f": 12.192, "left_oil_end_f": 12.192, "deck_start_f": 17.288}]
assets[lanes[0]["visual_id"]] = "res://assets/leagues/house/lane_visual.lane_condition.house_oil.tres"
for tag, name, right, left in [("long_oil", "Long Oil", 14.3256, 14.3256), ("two_tone", "Two-Tone", 12.192, 10.3632)]:
    asset_id = "lane_visual.lane_condition." + tag
    assets[asset_id] = save(D / (asset_id + ".tres"), f'''[gd_resource type="ShaderMaterial" load_steps=2 format=3]
[ext_resource type="Shader" path="res://assets/leagues/neon/lane.gdshader" id="1"]
[resource]
shader = ExtResource("1")
shader_parameter/oil_end_f = {right}
shader_parameter/left_oil_end_f = {left}
shader_parameter/deck_start_f = 17.288
''')
    lanes.append(dict(condition_id="lane_condition." + tag, visual_id=asset_id, name=name,
                      oil_end_f=right, left_oil_end_f=left, deck_start_f=17.288))
manifest["lanes"] = lanes

specs = {"hud": ("111c29", "70c9cd", 12), "shop": ("202034", "a49bca", 16),
         "slip": ("f4e6cd", "68567d", 12), "menu": ("1d2130", "c6a468", 16),
         "panel": ("18252e", "658b9b", 12)}
frames = {}
for kind, (fill, edge, margin) in specs.items():
    # Nested stepped rail corners are distinct from the House kit's cross rivets.
    body = f'<path d="M10 0H54V4H60V10H64V54H60V60H54V64H10V60H4V54H0V10H4V4H10Z" fill="#101820"/><path d="M11 2H53V6H58V11H62V53H58V58H53V62H11V58H6V53H2V11H6V6H11Z" fill="#{edge}"/><path d="M12 5H52V9H55V12H59V52H55V55H52V59H12V55H9V52H5V12H9V9H12Z" fill="#272635"/><rect x="10" y="10" width="44" height="44" fill="#{fill}"/>'
    body += '<path d="M14 8H28M36 8H50M14 56H28M36 56H50" stroke="#7c6e55" stroke-width="2"/>'
    for x, y in [(8, 8), (56, 8), (8, 56), (56, 56)]:
        body += f'<path d="M{x-3} {y}L{x} {y-3} {x+3} {y} {x} {y+3}Z" fill="#f4e6cd"/>'
    save(UI / f"{kind}.svg", f'<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64">{body}</svg>\n')
    path = save(UI / f"{kind}.tres", f'''[gd_resource type="StyleBoxTexture" load_steps=2 format=3]
[ext_resource type="Texture2D" path="res://assets/ui/neon/{kind}.svg" id="1"]
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
    asset_id = "ui.neon." + kind
    assets[asset_id] = path
    frames[asset_id] = dict(path=path, source_px=[64, 64], slice_px=margin, content_inset_px=margin+8, minimum_px=[2*margin+16]*2)
ornaments = []
for kind, width, height, body in [
    ("corner", 32, 32, '<path d="M2 30V10H6V6H10V2H30M8 26V14H14V8H26" stroke="#70c9cd" stroke-width="2" fill="none"/><path d="M15 15H22V22H15Z" fill="#a49bca"/>'),
    ("divider", 128, 16, '<path d="M0 6H46L52 12H76L82 6H128M0 10H42M86 10H128" stroke="#658b9b" stroke-width="2" fill="none"/><path d="M58 3H70V9H58Z" fill="#c6a468"/>')]:
    path = save(UI / f"{kind}.svg", f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}">{body}</svg>\n')
    assets["ui.neon." + kind] = path
    ornaments.append(path)
save(UI / "manifest.json", json.dumps(dict(schema_version=1, frames=frames, ornaments=ornaments,
     font="res://assets/ui/fonts/PixelifySans.ttf"), indent=2) + "\n")
manifest["ui"] = {"manifest": "res://assets/ui/neon/manifest.json", "frames": {kind: "ui.neon." + kind for kind in specs}}
manifest["flank"] = {}
for reduced in [False, True]:
    mode = "reduced" if reduced else "normal"
    asset_id = "backdrop.ui.neon." + mode
    assets[asset_id] = save(ROOT / f"assets/ui/backdrops/neon_{mode}.tscn", f'''[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://assets/ui/backdrops/neon.gd" id="1"]
[node name="NeonFlank" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
script = ExtResource("1")
reduced = {str(reduced).lower()}
''')
    manifest["flank"][mode] = asset_id
manifest["rule_visuals"] = {rule: "rule_visual." + rule for rule in ["boss_rule.narrow_lane", "boss_rule.strobe"]}
for asset_id in manifest["rule_visuals"].values():
    assets[asset_id] = "res://assets/leagues/neon/rule_overlay.gd"
assets["trophy.neon"] = "res://assets/clubhouse/trophy.neon.png"

# Original sixteen-bar, 112 BPM Neon circuit theme. No samples or donor melody.
rate = 22050
bpm = 112
beat = 60 / bpm
bars = 16
length = round(rate * beat * bars * 4)
mix = np.zeros((length, 2), dtype=np.float64)
rng = np.random.default_rng(221202)

def hz(note):
    return 440 * 2 ** ((note - 69) / 12)

def add(voice, beats, gain, pan=0):
    indices = (round(beats * beat * rate) + np.arange(len(voice))) % length
    mix[indices, 0] += voice * gain * math.sqrt((1-pan)*.5)
    mix[indices, 1] += voice * gain * math.sqrt((1+pan)*.5)

def synth(note, duration, tone="pluck"):
    t = np.arange(round((duration + .35) * rate)) / rate
    f = hz(note)
    attack = np.minimum(t / (.025 if tone == "pad" else .008), 1)
    release = np.clip((duration + .35 - t) / .35, 0, 1)
    if tone == "pad":
        voice = sum(np.sin(2*np.pi*f*(1+d)*t) for d in [-.002, 0, .002]) / 3
        return voice * attack * release * np.exp(-t/(duration+1))
    voice = np.sin(2*np.pi*f*t + .9*np.sin(2*np.pi*2*f*t)*np.exp(-t*6))
    voice += .12*np.sin(2*np.pi*f*3*t)
    return voice * attack * release * np.exp(-t/(.18 if tone == "bass" else .32))

chords = [[62, 65, 69, 76], [58, 62, 65, 72], [55, 58, 62, 69], [57, 61, 64, 71]]
roots = [38, 34, 43, 33]
motifs = [[74, 81, 77, 76, 74, 69], [77, 74, 72, 70, 69, 72],
          [74, 77, 81, 79, 77, 74], [76, 73, 71, 69, 73, 76]]
for bar in range(bars):
    harmony = (bar // 2) % 4
    at = bar * 4
    for j, note in enumerate(chords[harmony]):
        add(synth(note, 3.6*beat, "pad"), at, .033, -.6+j*.4)
    for j, offset in enumerate([0, .75, 1.5, 2, 2.75, 3.5]):
        add(synth(roots[harmony] + (12 if j == 5 else 0), .34, "bass"), at+offset, .16)
    for j in range(8):
        note = chords[harmony][[0, 2, 1, 3, 2, 1, 3, 2][j]] + (12 if bar >= 8 else 0)
        add(synth(note, .20), at+j*.5, .030 if j%2 else .023, .35 if j%2 else -.35)
    if bar % 2 == 1:
        for note, offset in zip(motifs[harmony], [.25, .75, 1.5, 2.25, 2.75, 3.5]):
            add(synth(note - (12 if bar >= 12 else 0), .32), at+offset, .055, .12)
    for offset in [0, 1.5, 2, 3.5]:
        t = np.arange(round(.24*rate))/rate
        kick = np.sin(2*np.pi*(47*t+6*(1-np.exp(-t*30))))*np.exp(-t*23)*np.minimum(t/.004, 1)
        add(kick, at+offset, .13)
    for offset in [1, 3]:
        t = np.arange(round(.15*rate))/rate
        noise = rng.uniform(-1, 1, len(t))
        clap = (noise-np.convolve(noise, np.ones(7)/7, "same"))*np.exp(-t*35)*np.minimum(t/.005, 1)
        add(clap, at+offset, .045, -.12)
    for j in range(8):
        t = np.arange(round(.055*rate))/rate
        noise = rng.uniform(-1, 1, len(t))
        hat = np.diff(noise, prepend=0)*np.exp(-t*85)*np.minimum(t/.003, 1)
        add(hat, at+j*.5, .010 if j%2 else .006, -.4)
# Circular echo preserves releases across the loop boundary; no hard-cut tails.
dry = mix.copy()
for delay, gain in [(.75*beat, .17), (1.5*beat, .08), (2.25*beat, .04)]:
    mix += np.roll(dry, round(delay*rate), axis=0)[:, ::-1]*gain
mix -= mix.mean(axis=0)
mix = np.tanh(mix*1.2)
mix *= .65 / np.max(np.abs(mix))
pcm = np.round(mix*32767).astype("<i2")
asset_id = "music.league.neon.circuit"
audio = D / (asset_id + ".wav")
with wave.open(str(audio), "wb") as out:
    out.setparams((2, 2, rate, 0, "NONE", "not compressed"))
    out.writeframes(pcm.tobytes())
assets[asset_id] = "res://" + str(audio.relative_to(ROOT))
imported = "res://.godot/imported/" + audio.name + "-" + hashlib.md5(assets[asset_id].encode()).hexdigest() + ".sample"
save(audio.with_suffix(".wav.import"), f'''[remap]
importer="wav"
type="AudioStreamWAV"
path="{imported}"
[deps]
source_file="{assets[asset_id]}"
dest_files=["{imported}"]
[params]
force/8_bit=false
force/mono=false
force/max_rate=false
force/max_rate_hz=44100
edit/trim=false
edit/normalize=false
edit/loop_mode=2
edit/loop_begin=0
edit/loop_end=-1
compress/mode=0
''')
manifest["music"] = dict(asset_id=asset_id, bpm=bpm, bars=bars, sample_rate=rate, frames=length,
                         seconds=length/rate, peak=float(np.max(np.abs(mix))), rms=float(np.sqrt(np.mean(mix**2))),
                         seam_delta=float(np.max(np.abs(mix[0]-mix[-1]))),
                         sha256=hashlib.sha256(audio.read_bytes()).hexdigest())
manifest["delivery_status"] = "assets_ready_live_theme_hook_pending"
save(D / "manifest.json", json.dumps(manifest, indent=2) + "\n")
print(json.dumps(manifest["music"], indent=2))
print(len(assets), "stable asset bindings")
