"""Emulate only the recovered ballistic arithmetic, with mocked Unity/libm calls.

No APK installation/execution, device or network. ARM64 instructions at
0xacd7bf4..0xacd7c78 are run in Unicorn. External calls return supplied gravity,
cosf and tanf. This validates the pure math, not scene inputs or full gameplay.
"""
import json, math, struct, sys
from pathlib import Path
from unicorn import Uc, UC_ARCH_ARM64, UC_MODE_ARM, UC_HOOK_CODE
from unicorn.arm64_const import *
R=Path(__file__).resolve().parents[1];sys.path.insert(0,str(R))
from physics import target_speed

def bits(x):return struct.unpack('<I',struct.pack('<f',x))[0]
def flt(x):return struct.unpack('<f',struct.pack('<I',x))[0]
raw=(R/'input/extracted/libil2cpp.so').read_bytes()
methods=json.loads((R/'evidence/method-map.json').read_text())['methods']
m=next(m for m in methods if m['index']==43279)
base=int(m['rva'],16);start=0xacd7bf4;end=0xacd7c78
cases=[]
for angle in [36,40.5,45]:
 for target in [(0,1,4),(1,2,6),(-.5,.25,3),(0,8,1)]:
  ball=(0,1,0);theta=math.radians(angle);g=-9.8100004196167
  u=Uc(UC_ARCH_ARM64,UC_MODE_ARM)
  page=base&~0xfff;u.mem_map(page,0x2000)
  u.mem_write(base,raw[m['file_offset']:m['file_offset']+0x180])
  u.mem_map(0x100000,0x10000);u.reg_write(UC_ARM64_REG_SP,0x108000)
  for addr in [0xdbeb280,0xe296b20,0xe294950]:u.mem_map(addr&~0xfff,0x1000)
  for reg,x in [(UC_ARM64_REG_S8,theta),(UC_ARM64_REG_S13,ball[0]),(UC_ARM64_REG_S12,ball[1]),(UC_ARM64_REG_S14,ball[2]),(UC_ARM64_REG_S11,target[0]),(UC_ARM64_REG_S9,target[1]),(UC_ARM64_REG_S10,target[2])]:u.reg_write(reg,bits(x))
  def hook(uc,address,size,user):
   if address==end:uc.emu_stop();return
   if address==0xdbeb280:uc.reg_write(UC_ARM64_REG_S1,bits(g))
   elif address==0xe296b20:uc.reg_write(UC_ARM64_REG_S0,bits(math.cos(flt(uc.reg_read(UC_ARM64_REG_S0)))) )
   elif address==0xe294950:uc.reg_write(UC_ARM64_REG_S0,bits(math.tan(flt(uc.reg_read(UC_ARM64_REG_S0)))) )
   else:return
   uc.reg_write(UC_ARM64_REG_PC,uc.reg_read(UC_ARM64_REG_LR))
  u.hook_add(UC_HOOK_CODE,hook);u.emu_start(start,end+4,count=200)
  native=flt(u.reg_read(UC_ARM64_REG_S0));model=target_speed(theta,ball,target,g)
  error=abs(native-model);assert math.isclose(native,model,rel_tol=2e-6,abs_tol=2e-6),(native,model)
  cases.append(dict(angle=angle,ball=ball,target=target,native_arm64=native,reconstruction=model,absolute_error=error))
(R/'evidence/native-math-validation.json').write_text(json.dumps(dict(scope=__doc__,cases=cases),indent=2))
print(f'{len(cases)} native ARM64 arithmetic comparisons passed; max absolute error {max(c["absolute_error"] for c in cases):.8g}')
