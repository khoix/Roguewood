import json,struct
from pathlib import Path
from elftools.elf.elffile import ELFFile
R=Path(__file__).resolve().parents[1]
j=json.loads((R/'evidence/metadata.json').read_text())['normalized_result']
b=(R/'input/extracted/libil2cpp.so').read_bytes();m=(R/'input/extracted/global-metadata.dat').read_bytes()
with (R/'input/extracted/libil2cpp.so').open('rb') as f:
 e=ELFFile(f);loads=[dict(s.header) for s in e.iter_segments() if s['p_type']=='PT_LOAD']
 rel={r['r_offset']:r['r_addend'] for r in e.get_section_by_name('.rela.dyn').iter_relocations() if r['r_info_type']==1027}
def off(a):
 for s in loads:
  if s['p_vaddr']<=a<s['p_vaddr']+s['p_filesz']:return a-s['p_vaddr']+s['p_offset']
 raise ValueError(hex(a))
def va(a):
 for s in loads:
  if s['p_offset']<=a<s['p_offset']+s['p_filesz']:return a-s['p_offset']+s['p_vaddr']
 raise ValueError(a)
def ptr(a):
 if a in rel:return rel[a]
 return struct.unpack_from('<Q',b,off(a))[0]
def u(a):return struct.unpack_from('<I',b,off(a))[0]
needle=struct.pack('<Q',len(j['types']));pos=0;c=[]
while True:
 pos=b.find(needle,pos)
 if pos<0:break
 if b[pos+16:pos+24]==needle:
  reg=va(pos)-80
  try:
   table=ptr(reg+56);off(table);fo=ptr(reg+88);off(fo);c.append((reg,table,fo))
  except ValueError:pass
 pos+=1
assert len(c)==1,c
reg,table,fo=c[0];print('Registration',hex(reg),'types',u(reg+48),'table',hex(table),'fieldOffsets',hex(fo))
primitives={1:'void',2:'bool',3:'char',4:'sbyte',5:'byte',6:'short',7:'ushort',8:'int',9:'uint',10:'long',11:'ulong',12:'float',13:'double',14:'string',24:'intptr',25:'uintptr',28:'object'}
def typ(i):
 a=ptr(table+8*i);data=ptr(a);bits=u(a+8);kind=(bits>>16)&255
 if kind in primitives:name=primitives[kind]
 elif kind in (17,18):name=j['types'][data]['name']
 else:name=f'kind_{kind}_data_{data:x}'
 return name,bits&0xffff
s={x['name']:x for x in j['sections']};out=[]
for ti in [8181,8205,8413,8415,8417,8418]:
 fields=[(i,f) for i,f in enumerate(j['fields']) if f['declaring_type']==ti];fieldtab=ptr(fo+ti*8)
 rec=dict(type=j['types'][ti]['name'],index=ti,fields=[],methods=[])
 for ordinal,(i,f) in enumerate(fields):
  size=s['fields']['size']//s['fields']['count'];typeidx=struct.unpack_from('<i',m,s['fields']['offset']+size*i+4)[0]
  name,attrs=typ(typeidx)
  rec['fields'].append(dict(name=f['name'],type=name,attributes=hex(attrs),offset=hex(u(fieldtab+ordinal*4))))
 for i,method in enumerate(j['methods']):
  if method['declaring_type']!=ti:continue
  at=s['methods']['offset']+32*i;ret=struct.unpack_from('<i',m,at+6)[0];start=struct.unpack_from('<i',m,at+14)[0];count=struct.unpack_from('<H',m,at+30)[0];params=[]
  psz=s['parameters']['size']//s['parameters']['count']
  for pi in range(start,start+count):
   pt=struct.unpack_from('<i',m,s['parameters']['offset']+psz*pi+8)[0]
   params.append(typ(pt)[0])
  rec['methods'].append(dict(index=i,name=method['name'],returns=typ(ret)[0],parameters=params))
 out.append(rec)
(R/'evidence/types.json').write_text(json.dumps(out,indent=2))
print(json.dumps(out[0],indent=2))
with (R/'evidence/signatures.tsv').open('w') as out:
 for i,method in enumerate(j['methods']):
  at=s['methods']['offset']+32*i;ret=struct.unpack_from('<i',m,at+6)[0];start=struct.unpack_from('<i',m,at+14)[0];count=struct.unpack_from('<H',m,at+30)[0];flags=struct.unpack_from('<H',m,at+24)[0]
  params=[];psz=s['parameters']['size']//s['parameters']['count']
  for pi in range(start,start+count):
   pt=struct.unpack_from('<i',m,s['parameters']['offset']+psz*pi+8)[0];params.append(typ(pt)[0])
  out.write(str(i)+'\t'+typ(ret)[0]+'\t'+str(bool(flags&16))+'\t'+','.join(params)+'\n')
