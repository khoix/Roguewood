import json,capstone
from pathlib import Path
from elftools.elf.elffile import ELFFile
R=Path(__file__).resolve().parents[1];ms=json.loads((R/'evidence/method-map.json').read_text())['methods'];b=(R/'input/extracted/libil2cpp.so').read_bytes()
names={int(m['rva'],16):m['type']+'.'+m['name'] for m in ms};starts=sorted(names)
with (R/'input/extracted/libil2cpp.so').open('rb') as f:
 e=ELFFile(f);p=e.get_section_by_name('.plt');r=e.get_section_by_name('.rela.plt');sy=e.get_section(r['sh_link'])
 for i,rel in enumerate(r.iter_relocations()):names[p['sh_addr']+32+16*i]=sy.get_symbol(rel['r_info_sym']).name
md=capstone.Cs(capstone.CS_ARCH_ARM64,capstone.CS_MODE_LITTLE_ENDIAN);out=R/'evidence/assembly';out.mkdir(exist_ok=True)
for m in ms:
 if not (m['type']=='Pokeball' or 8413<=m['type_index']<=8418):continue
 a=int(m['rva'],16);n=starts[starts.index(a)+1]-a;lines=[]
 for ins in md.disasm(b[m['file_offset']:m['file_offset']+n],a):
  note=''
  if ins.mnemonic in ('bl','b') and ins.op_str.startswith('#'):
   target=int(ins.op_str[1:],16);note=' ; '+names.get(target,'native')
  lines.append(f'{ins.address:x} {ins.mnemonic:8} {ins.op_str}{note}')
 (out/f'{m["type"]}_{m["name"]}_{m["index"]}.asm').write_text('\n'.join(lines))
