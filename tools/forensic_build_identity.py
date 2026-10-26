"""Read-only retained executable/template/source identity matrix."""
from pathlib import Path
import hashlib,json,os,struct,subprocess
G=Path(__file__).resolve().parents[1];R=G.parent;O=R/'Checkpoints/20261026_full_forensic_audit'
def image(p):
    b=p.read_bytes();e=struct.unpack_from('<I',b,60)[0];n=struct.unpack_from('<H',b,e+6)[0];optional=struct.unpack_from('<H',b,e+20)[0];start=e+24+optional
    sections=[]
    for i in range(n):
        name,vs,va,size,offset=struct.unpack_from('<8sIIII',b,start+40*i)
        sections.append({'name':name.rstrip(b'\0').decode(),'rva':va,'size':size,'sha256':hashlib.sha256(b[offset:offset+size]).hexdigest()})
    return {'file':str(p),'sha256':hashlib.sha256(b).hexdigest(),'timestamp':hex(struct.unpack_from('<I',b,e+8)[0]),'native_text_sha256':next(s['sha256'] for s in sections if s['name']=='.text')}
template=image(Path(os.environ['APPDATA'])/'Godot/export_templates/4.7.2.stable/windows_release_x86_64.exe')
paths=[('rollback_0106',R/'Checkpoints/20261026_surveyor_identity_verified/IndependentExtract/UNLISTED.exe'),('crash_a_0107',R/'Builds/UNLISTED_Dread_Within_08/UNLISTED.exe'),('0108',R/'Builds/UNLISTED_Stability_Terror_03/UNLISTED.exe'),('crash_b_fixture',R/'Builds/UNLISTED_Player_Experience_01/UNLISTED.exe'),('retained_owner_candidate',R/'Checkpoints/20261026_player_experience_candidate/IndependentExtract/UNLISTED.exe'),('diagnostic05',R/'Checkpoints/20261026_priority_zero_diagnostic/IndependentExtract/UNLISTED.exe'),('forensic02',R/'Builds/UNLISTED_Forensic_Repair_02/UNLISTED.exe')]
rows=[]
for name,p in paths:
    row=image(p);row['case']=name;row['native_text_matches_template']=row['native_text_sha256']==template['native_text_sha256'];rows.append(row)
refs=['cfd79af','7dc6c29','248b3aa','c4710ce','0d15f78','HEAD'];source=[]
for ref in refs:
    entry={'ref':ref,'commit':subprocess.check_output(['git','rev-parse',ref],cwd=G,text=True).strip(),'asset_tree':subprocess.check_output(['git','rev-parse',ref+':assets'],cwd=G,text=True).strip()}
    for name in ['project.godot','export_presets.cfg']:
        b=subprocess.check_output(['git','show',ref+':'+name],cwd=G);entry[name]={'git_blob_sha256':hashlib.sha256(b).hexdigest(),'text':b.decode('utf8')}
    source.append(entry)
result={'installed_template':template,'retained_executables':rows,'source_configs':source,'original_owner_temporary_executable':'Unavailable; retained candidate hash is not an independently recovered owner temp-file hash.'}
(O/'build_identity_matrix.json').write_text(json.dumps(result,indent=2),encoding='utf8')
print(json.dumps({'retained_cases':len(rows),'all_native_text_matches':all(r['native_text_matches_template'] for r in rows),'unchanged_assets_across_milestones':len({r['asset_tree'] for r in source})==1},indent=2))
