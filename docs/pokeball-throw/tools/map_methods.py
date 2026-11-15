"""Map metadata MethodDef tokens through known ELF relative relocations.

Does not execute the APK. Unknown external relocations are never guessed.
Uses REA's decoded metadata inventory and the v39 32-byte method layout.
"""
import json, struct
from pathlib import Path
from elftools.elf.elffile import ELFFile

ROOT = Path(__file__).resolve().parents[1]
j = json.loads((ROOT/'evidence/metadata.json').read_text())['normalized_result']
assert j['metadata_version'] == 39 and j['index_widths']['type_definition'] == 2
raw = (ROOT/'input/extracted/libil2cpp.so').read_bytes()
meta = (ROOT/'input/extracted/global-metadata.dat').read_bytes()
with (ROOT/'input/extracted/libil2cpp.so').open('rb') as f:
    elf = ELFFile(f)
    loads = [dict(s.header) for s in elf.iter_segments() if s['p_type']=='PT_LOAD']
    rel = {r['r_offset']:r['r_addend'] for r in elf.get_section_by_name('.rela.dyn').iter_relocations() if r['r_info_type']==1027}

def off(va):
    for s in loads:
        if s['p_vaddr'] <= va < s['p_vaddr']+s['p_filesz']:
            return va-s['p_vaddr']+s['p_offset']
    raise ValueError(hex(va))

def va(offset):
    for s in loads:
        if s['p_offset'] <= offset < s['p_offset']+s['p_filesz']:
            return offset-s['p_offset']+s['p_vaddr']
    raise ValueError(offset)

def ptr(addr):
    if addr in rel:return rel[addr]
    for s in loads:
        if s['p_vaddr']+s['p_filesz'] <= addr < s['p_vaddr']+s['p_memsz']:return 0
    return struct.unpack_from('<Q',raw,off(addr))[0]

reverse = {}
for a,v in rel.items(): reverse.setdefault(v,[]).append(a)
sections={s['name']:s for s in j['sections']}
methods=[]; modules=[]
for image in j['images']:
    count=sum(t['method_count'] for t in j['types'][image['type_start']:image['type_start']+image['type_count']])
    if count==0: continue
    needle=image['name'].encode()+b'\0'; start=0; candidates=[]
    while True:
        pos=raw.find(needle,start)
        if pos<0:break
        start=pos+1
        for record in reverse.get(va(pos),[]):
            n=struct.unpack_from('<I',raw,off(record+8))[0]
            if n==count: candidates.append(record)
    if len(candidates)!=1:
        print('UNMAPPED',image['name'],count,len(candidates));continue
    record=candidates[0]; table=ptr(record+16)
    modules.append(dict(name=image['name'],record=hex(record),count=count,table=hex(table)))
    for ti in range(image['type_start'],image['type_start']+image['type_count']):
        t=j['types'][ti]
        for mi in range(t['method_start'],t['method_start']+t['method_count']):
            token=struct.unpack_from('<I',meta,sections['methods']['offset']+mi*32+20)[0]
            assert token>>24==6 and 1 <= (token&0xffffff) <= count
            addr=ptr(table+8*((token&0xffffff)-1))
            if not addr:continue
            assert any(s['p_flags']&1 and s['p_vaddr']<=addr<s['p_vaddr']+s['p_filesz'] for s in loads)
            methods.append(dict(index=mi,type_index=ti,type=t['name'],namespace=t['namespace'],name=j['methods'][mi]['name'],rva=hex(addr),file_offset=off(addr),token=hex(token)))
(ROOT/'evidence/method-map.json').write_text(json.dumps(dict(modules=modules,methods=methods),indent=2))
print('Mapped',len(modules),'modules and',len(methods),'methods')
