"""Original procedural material foley. Deterministic PCM, no recordings/samples.
Usage: python3 tools/author_foley.py <name> <material> <pitch> <duration>
Peak normalized below -6 dBFS; the game further limits the four-voice mix.
"""
import hashlib, math, random, struct, sys, wave
from pathlib import Path
name, material, pitch, duration = sys.argv[1:]
freq, seconds = float(pitch), float(duration)
rng = random.Random(int.from_bytes(hashlib.sha256(name.encode()).digest()[:8], 'big'))
rate = 22050
values = []
last_noise = 0.0
for i in range(int(rate * seconds)):
    t = i / rate
    p = t / seconds
    noise = rng.uniform(-1, 1)
    low = last_noise * .82 + noise * .18
    last_noise = low
    attack = min(1.0, t * 1200)
    if material == 'glass':
        value = sum(a*math.sin(2*math.pi*freq*r*t)*math.exp(-p*d) for a,r,d in [(.42,1,8),(.25,2.71,13),(.13,4.98,20)]) + .18*(noise-low)*math.exp(-p*55)
    elif material == 'crack':
        # Three short, irregular fracture transients; not a metallic bell.
        brittle = sum(math.exp(-max(0,t-delay)*decay) if t >= delay else 0 for delay,decay in [(0,180),(.021,140),(.057,110)])
        value = .7*(noise-low)*brittle + .12*math.sin(2*math.pi*freq*2.71*t)*math.exp(-p*18)
    elif material == 'swish':
        value = .55*low*math.sin(math.pi*p)**2 + .24*math.sin(2*math.pi*freq*t)*math.exp(-max(0,p-.65)*28)*(1 if p>.65 else 0)
    elif material == 'cloth':
        value = .8 * low * math.sin(math.pi*p)**1.4 + .12 * noise * math.sin(math.pi*p)**3
    elif material == 'rubber':
        value = .5 * math.sin(2*math.pi*(freq*t - freq*t*t*.7))*math.exp(-p*7) + .2*low*math.exp(-p*13)
    elif material == 'wood':
        value = (.5*math.sin(2*math.pi*freq*t)+.25*math.sin(2*math.pi*freq*2.73*t))*math.exp(-p*12)+.35*noise*math.exp(-p*40)
    elif material == 'paper':
        value = .5*(noise-low)*math.exp(-p*17)+.22*low*math.sin(math.pi*p*3)**2*math.exp(-p*4)
    else:
        value = sum(a*math.sin(2*math.pi*freq*r*t)*math.exp(-p*d) for a,r,d in [(.35,1,5),(.22,2.41,9),(.12,4.13,15)])+.15*noise*math.exp(-p*60)
    values.append(value*attack*min(1.0,(1-p)*40))
# Hand-authored short rhythmic identities, mixed before peak limiting.
patterns = {
 'sound.charm.underdog': [(0,.65),(.055,1)],
 'sound.charm.hot_streak': [(0,.85),(.065,1)],
 'ball_echo': [(0,1),(.085,.65)],
 'charm_encore': [(0,1),(.075,.75)],
 'charm_turkey_club': [(0,.85),(.07,.9),(.14,1)],
 'charm_flat_bonus': [(0,1),(.04,.65),(.08,.65),(.12,.8)],
 'charm_gold_rush': [(0,1),(.055,.6),(.115,.7)],
 'charm_spare_change': [(0,.9),(.08,1)],
 'charm_last_chance': [(0,.4),(.09,.5),(.18,1)],
}
if name in patterns:
    original = values[:]
    values = [0.0]*len(original)
    for hit, (delay,gain) in enumerate(patterns[name]):
        offset = round(delay*rate)
        for i in range(offset,len(values)):
            at = int((i-offset)*(1+hit*.045))
            if at < len(original): values[i] += original[at]*gain
peak = max(abs(v) for v in values)
values = [round(v / max(peak, .001) * .48 * 32767) for v in values]
path = Path('assets/audio') / (name + '.wav')
path.parent.mkdir(parents=True,exist_ok=True)
with wave.open(str(path), 'wb') as out:
    out.setparams((1,2,rate,0,'NONE','not compressed'))
    out.writeframes(struct.pack('<'+'h'*len(values),*values))
print(path, 'frames',len(values),'peak',max(abs(v) for v in values)/32767)
