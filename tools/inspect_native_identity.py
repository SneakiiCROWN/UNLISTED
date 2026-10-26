"""Read-only native layout evidence. Exported data labels are not function symbols."""
from pathlib import Path
import struct,json,hashlib,os
G=Path(__file__).resolve().parents[1];O=G.parent/'Builds/UNLISTED_Priority_Zero_Evidence'
exe=G.parent/'Checkpoints/20261026_player_experience_candidate/IndependentExtract/UNLISTED.exe'
template=Path(os.environ['APPDATA'])/'Godot/export_templates/4.7.2.stable/windows_release_x86_64.exe'
def inspect(p):
    b=p.read_bytes();e=struct.unpack_from('<I',b,60)[0];n=struct.unpack_from('<H',b,e+6)[0];opt=struct.unpack_from('<H',b,e+20)[0];off=e+24+opt;sections=[]
    for i in range(n):
        name,vs,va,raw,ptr=struct.unpack_from('<8sIIII',b,off+40*i);sections.append({'name':name.rstrip(b'\0').decode(),'rva':va,'virtual_size':vs,'raw_size':raw,'raw_offset':ptr,'raw_sha256':hashlib.sha256(b[ptr:ptr+raw]).hexdigest() if raw else None})
    debug_rva,debug_size=struct.unpack_from('<II',b,e+24+112+6*8)
    return {'path':str(p),'file_sha256':hashlib.sha256(b).hexdigest(),'timestamp':hex(struct.unpack_from('<I',b,e+8)[0]),'sections':sections,'debug_directory_rva':debug_rva,'debug_directory_size':debug_size,'has_RSDS_signature':b.find(b'RSDS')>=0}
a=inspect(exe);t=inspect(template)
text=lambda j:next(s for s in j['sections'] if s['name']=='.text')['raw_sha256']
base=0x7ff794280000;r13=0x7ff7996d3f4c
region=next(s['name'] for s in a['sections'] if s['rva']<=r13-base<s['rva']+s['virtual_size'])
release=json.loads((O/'official_release_metadata.json').read_text())
result={'delivered_executable':a,'installed_template':t,'native_text_identical':text(a)==text(t),'owner_wer_timestamp':'0x6a826696','owner_unwind_candidate_register_r13':hex(r13),'r13_rva':hex(r13-base),'r13_region_using_retained_engine_layout':region,'interpretation':'RIP0 provides no trustworthy function unwind. The shown candidate r13 is in data, not native executable text. Do not name NvOptimusEnablement or NoHotPatch as the cause. Original temporary image unavailable for full identity hash; matching timestamp/header is weaker than a full original-file hash.','published_windows_symbol_assets':[x['name'] for x in release['assets'] if ('win' in x['name'].lower()) and any(y in x['name'].lower() for y in ['symbol','pdb','debug'])],'published_android_symbol_assets':[x['name'] for x in release['assets'] if 'native_debug_symbols' in x['name']]}
(O/'native_identity.json').write_text(json.dumps(result,indent=2),encoding='utf8');print(json.dumps({k:result[k] for k in ['native_text_identical','r13_region_using_retained_engine_layout','published_windows_symbol_assets']},indent=2))
