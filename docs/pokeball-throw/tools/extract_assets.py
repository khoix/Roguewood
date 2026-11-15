import UnityPy,json,struct
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
out=ROOT/'evidence/assets';out.mkdir(exist_ok=True)
env=UnityPy.load(str(ROOT/'input/assets'))
print('objects',len(env.objects),flush=True)
scripts={}
for o in env.objects:
    if o.type.name=='MonoScript':
        try:
            d=o.read();scripts[(o.assets_file.name,o.path_id)]=d.m_ClassName
        except Exception:pass
hits=[]
for o in env.objects:
    if o.type.name not in ('MonoBehaviour','PhysicsManager','GameObject'):continue
    try:
        tree=o.read_typetree()
        s=json.dumps(tree,default=str)
        if any(k in s for k in ['pokeballThrowProperties','gestureFlickTime','curveBallModifier','launchVelocityModifier','m_Gravity']):
            rec={'asset':o.assets_file.name,'path_id':o.path_id,'type':o.type.name,'tree':tree}
            hits.append(rec);print('HIT',o.type.name,o.path_id,s[:180],flush=True)
    except Exception:pass
(out/'physics-settings.json').write_text(json.dumps(hits,indent=2,default=str))
print('hits',len(hits),flush=True)
# For this hash-identified build, the MonoScript IDs are resolved from
# globalgamemanagers.assets; MonoBehaviour type trees are stripped.
script_ids={pid:name for (asset,pid),name in scripts.items() if asset=='globalgamemanagers.assets' and name in ('Pokeball','EncounterGestureHandler')}
behaviours=[];objects=[]
for o in env.objects:
    if o.type.name=='TimeManager':
        (out/'time-manager.json').write_text(json.dumps(o.read_typetree(),indent=2))
    if o.type.name=='MonoBehaviour':
        b=o.get_raw_data()
        if len(b)<28:continue
        fid,pid=struct.unpack_from('<iq',b,16)
        if pid in script_ids and o.assets_file.name=='sharedassets1.assets' and fid==1:
            (out/f'{pid}_{o.path_id}.bin').write_bytes(b)
            behaviours.append(dict(asset=o.assets_file.name,id=o.path_id,script_file=fid,script_id=pid,bytes=len(b)))
    if o.assets_file.name=='sharedassets1.assets' and o.path_id in [4090,3774,7046,8526,42323,43583]:
        objects.append(dict(id=o.path_id,type=o.type.name,tree=o.read_typetree()))
(out/'behaviours.json').write_text(json.dumps(behaviours,indent=2))
(out/'objects.json').write_text(json.dumps(objects,indent=2))
types=json.loads((ROOT/'evidence/types.json').read_text())
props=next(t for t in types if t['type']=='PokeballThrowProperties')
b=(out/'2806_111909.bin').read_bytes();at=0x60;values={}
for f in props['fields']:
    n={'float':1,'Vector2':2,'Vector3':3}[f['type']]
    v=struct.unpack_from('<'+'f'*n,b,at)
    values[f['name']]={'value':v[0] if n==1 else list(v),'serialized_offset':hex(at)}
    at+=4*n
(out/'throw-properties.json').write_text(json.dumps({'source':'sharedassets1.assets:111909 (Pokeball)','values':values},indent=2))
