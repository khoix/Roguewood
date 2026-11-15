// Targeted static decompilation; APK code is never executed.
//@category PokemonResearch
import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.*;
import ghidra.program.model.address.*;
import ghidra.program.model.listing.*;
import ghidra.program.model.symbol.SourceType;
import ghidra.program.model.data.*;
import ghidra.app.cmd.disassemble.DisassembleCommand;
import java.nio.file.*;
import java.util.*;

public class DumpThrows extends GhidraScript {
 Map<String,String[]> signatures=new HashMap<>();
 TreeSet<Long> starts=new TreeSet<>();
 Function prepare(long a,String name) throws Exception {
  Address ad=toAddr(a);Long next=starts.higher(a);
  for(var sym:currentProgram.getSymbolTable().getSymbols(ad))if(sym.getSymbolType()==ghidra.program.model.symbol.SymbolType.LABEL&&sym.getName().equals(name))sym.delete();
  AddressSet bounds=next==null?new AddressSet(ad,ad.add(4095)):new AddressSet(ad,toAddr(next-1));
  new DisassembleCommand(ad,bounds,true).applyTo(currentProgram,monitor);
  Function f=getFunctionAt(ad);
  if(f==null)f=currentProgram.getFunctionManager().createFunction(name,ad,bounds,SourceType.USER_DEFINED);
  else {f.setName(name,SourceType.USER_DEFINED);f.setBody(bounds);}
  if(next!=null&&getFunctionAt(toAddr(next))==null)currentProgram.getFunctionManager().createFunction("boundary_"+Long.toHexString(next),toAddr(next),new AddressSet(toAddr(next),toAddr(next+3)),SourceType.USER_DEFINED);
  signature(f);return f;
 }
 DataType dtype(String name) {
  if(name.equals("void"))return VoidDataType.dataType;
  if(name.equals("float"))return FloatDataType.dataType;
  if(name.equals("double"))return DoubleDataType.dataType;
  if(name.equals("bool"))return BooleanDataType.dataType;
  if(name.equals("int")||name.equals("uint"))return IntegerDataType.dataType;
  if(name.equals("long")||name.equals("ulong"))return LongLongDataType.dataType;
  if(name.equals("Vector2")||name.equals("Vector3")||name.equals("Vector4")||name.equals("Quaternion")){
   int n=name.equals("Vector2")?2:name.equals("Vector3")?3:4;
   StructureDataType s=new StructureDataType(name,0);
   for(int i=0;i<n;i++)s.add(FloatDataType.dataType,"xyzw".substring(i,i+1),null);
   return s;
  }
  return PointerDataType.dataType;
 }
 void signature(Function f) throws Exception {
  String name=f.getName();String id=name.substring(name.lastIndexOf('_')+1);String[] s=signatures.get(id);if(s==null)return;
  List<Parameter> p=new ArrayList<>();
  if(s[2].equals("False"))p.add(new ParameterImpl("self",PointerDataType.dataType,currentProgram));
  if(s.length>3&&!s[3].isEmpty())for(String t:s[3].split(","))p.add(new ParameterImpl("arg"+p.size(),dtype(t),currentProgram));
  p.add(new ParameterImpl("method",PointerDataType.dataType,currentProgram));
  f.updateFunction(null,new ReturnParameterImpl(dtype(s[1]),currentProgram),p,Function.FunctionUpdateType.DYNAMIC_STORAGE_ALL_PARAMS,true,SourceType.USER_DEFINED);
 }
 public void run() throws Exception {
  String[] args=getScriptArgs();
  if(args.length>2)for(String line:Files.readAllLines(Path.of(args[2]))){String[] p=line.split("\t",-1);signatures.put(p[0],p);}
  Map<Long,String> names=new HashMap<>();
  List<Long> targets=new ArrayList<>();
  long base=currentProgram.getImageBase().getOffset();
  println("IMAGE_BASE="+Long.toHexString(base));
  if(args.length>2){
   List<Address> old=new ArrayList<>();
   for(Function f:currentProgram.getFunctionManager().getFunctions(true))old.add(f.getEntryPoint());
   for(Address a:old)currentProgram.getFunctionManager().removeFunction(a);
  }
  for(String line:Files.readAllLines(Path.of(args[0]))) {
   String[] p=line.split("\t");long a=Long.parseUnsignedLong(p[0],16)+base;
   names.put(a,p[1]);starts.add(a);if(p.length>2 && p[2].equals("target")) targets.add(a);
  }
  for(long a:targets) {
   Function f=prepare(a,names.get(a));
   println("PREPARED "+names.get(a));
  }
  // Label directly called helpers, preserving the MethodDef address evidence.
  for(long a:targets) {
   Function f=getFunctionAt(toAddr(a));if(f==null)continue;
   InstructionIterator it=currentProgram.getListing().getInstructions(f.getBody(),true);
   while(it.hasNext()) {
    Instruction ins=it.next();if(!ins.getFlowType().isCall()&&!ins.getFlowType().isJump())continue;
    for(Address dest:ins.getFlows()) {
     if(f.getBody().contains(dest))continue;
     String name=names.get(dest.getOffset());
     Function callee=getFunctionAt(dest);
     if(name!=null){callee=prepare(dest.getOffset(),name);}
     else if(callee==null){
      callee=currentProgram.getFunctionManager().createFunction("native_"+dest.toString(),dest,new AddressSet(dest,dest.add(3)),SourceType.USER_DEFINED);
     }
     if(dest.getOffset()==base+0x4f17004L||dest.getOffset()==base+0x4f71700L||(name!=null&&name.contains("ThrowNullReferenceException")))callee.setNoReturn(true);
    }
   }
  }
  DecompInterface dec=new DecompInterface();dec.openProgram(currentProgram);
  Path out=Path.of(args[1]);Files.createDirectories(out);
  targets.sort((a,b)->Integer.compare(names.get(a).contains("__Launch_")?0:1,names.get(b).contains("__Launch_")?0:1));
  for(long a:targets) {
   Function f=getFunctionAt(toAddr(a));if(f==null)continue;
   DecompileResults r=dec.decompileFunction(f,10,monitor);
   String text="// RVA 0x"+Long.toHexString(a-base)+"\n";
   text+=r.decompileCompleted()?r.getDecompiledFunction().getC():r.getErrorMessage();
   Files.writeString(out.resolve(Long.toHexString(a-base)+"_"+names.get(a)+".c"),text);
   StringBuilder asm=new StringBuilder();
   InstructionIterator it=currentProgram.getListing().getInstructions(f.getBody(),true);
   while(it.hasNext()){Instruction ins=it.next();asm.append(ins.getAddress()).append(" ").append(ins).append("\n");}
   Files.writeString(out.resolve(Long.toHexString(a-base)+".asm"),asm.toString());
   println("DONE "+names.get(a));
  }
  dec.dispose();
 }
}
