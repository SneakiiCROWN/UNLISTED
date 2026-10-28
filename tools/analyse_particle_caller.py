"""Read-only analysis of a real late-attach particle rejection. Refuse unknown native paths."""
from pathlib import Path
import argparse,hashlib,json,re,struct,subprocess
G=Path(__file__).resolve().parents[1];CDB=Path(r'C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\cdb.exe')
p=argparse.ArgumentParser(description=__doc__);p.add_argument('--capture',type=Path,required=True);a=p.parse_args();C=a.capture.resolve()
assert C.is_relative_to(G.parent/'Checkpoints')
read=lambda p:json.loads(p.read_text(encoding='utf8'))
launch=read(C/'launch.json');hold=read(C/'native_hold.json');attached=read(C/'late_attach_result.json')
assert attached['debugger_exit']==0 and hold['scope'].startswith('Deliberate diagnostic hold AFTER')
E=Path(launch['args'][0]);b=E.read_bytes();assert hashlib.sha256(b).hexdigest()==launch['exe_sha256']
base=int(re.search(r'ENGINE_BASE=([0-9a-fA-F]+)',(C/'late_attach.log').read_text(encoding='utf8')).group(1),16)
e=struct.unpack_from('<I',b,60)[0];off=e+24+struct.unpack_from('<H',b,e+20)[0];n=struct.unpack_from('<H',b,e+6)[0]
def raw(rva):
 for i in range(n):
  _,vs,va,sz,ptr=struct.unpack_from('<8sIIII',b,off+40*i)
  if va<=rva<va+sz:return ptr+rva-va
 raise AssertionError('Unknown native instruction region')
assert b[raw(0x27667c4):raw(0x27667c4)+7]==bytes.fromhex('488b82a8000000')
assert b[raw(0x27667ee):raw(0x27667ee)+5]==bytes.fromhex('e8cdc10c00')
assert b[raw(0x28329c0):raw(0x28329c0)+7]==bytes.fromhex('4883ec484989d2')
dumps=list(C.glob('*particle*.dmp'));assert len(dumps)==1,'Expected exactly one preserved dump'
def debug(command,name,allow_missing=False):
 args=[str(CDB),'-z',str(dumps[0]),'-i',str(E.parent),'-y',str(C),'-c',command+'; q']
 r=subprocess.run(args,capture_output=True,text=True,encoding='utf8',errors='replace',timeout=45,creationflags=subprocess.CREATE_NO_WINDOW)
 text=r.stdout+r.stderr;(C/name).write_text(text,encoding='utf8')
 assert r.returncode==0 or (allow_missing and 'Memory access error' in text), 'Unexpected debugger analysis failure'
 return text
stack=debug('~0s; kn','native_stack_analysis.log')
frames=[]
for m in re.finditer(r'^([0-9a-f]{2}) +([0-9a-f`]+) +([0-9a-f`]+) +',stack,re.M):
 frames.append((int(m[1],16),int(m[2].replace('`',''),16),int(m[3].replace('`',''),16)))
frame=next(x[0]+1 for x in frames if x[2]==base+0x27667f3)
registers=debug('~0s; .frame /r '+hex(frame),'native_caller_registers.log')
m=re.search(r'rip=([0-9a-f]+) rsp=([0-9a-f]+) rbp=([0-9a-f]+)',registers);assert m and int(m[1],16)==base+0x27667f3
surface=int(m[3],16)
# Pinned source cache: sort16, primitive/flags/index/mask16, seven pointers/RIDs56,
# next8, owner8. Actual instructions load owner->data at0xa8, then its base at0.
owner_expression='poi('+hex(surface)+'+60)'
data_expression='poi('+owner_expression+'+a8)'
command='dq '+hex(surface)+' L10; .printf "OWNER=%p DATA=%p BASE_RID=%I64x\\n", '+owner_expression+', '+data_expression+', poi('+data_expression+')'
native=debug(command,'native_owner_fields.log',allow_missing=True)
m=re.search(r'OWNER=([0-9a-f]+) DATA=([0-9a-f]+) BASE_RID=([0-9a-f]+)',native,re.I)
result={'native_caller_rva':'0x27667f3','getter_return_rva':'0x2832a5c','surface_pointer':hex(surface),'owner_memory_available':bool(m),'dump':str(dumps[0]),'scope':'Read-only native dump reconstruction, not a crash repair or proof of native resource creation/destruction.'}
if m:
 rid=int(m[3],16);result.update(owner_pointer=m[1],data_pointer=m[2],rejected_base_rid=rid,rejected_base_hex=hex(rid))
 catalog=read(C/'resource_catalog.json')['instances'];result['application_matches']=[x for x in catalog if x['base_id']==rid or x['instance_id']==rid]
else:result['next_experiment']='Capture full private process memory after this real error; the small dump lacks the owner/data heap. Do not infer a RID from uninitialised argument home slots.'
(C/'NATIVE_PARTICLE_FINDING.json').write_text(json.dumps(result,indent=2),encoding='utf8');print(json.dumps(result,indent=2))
