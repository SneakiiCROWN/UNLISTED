"""Private custom-character review delivery; licensed media never uploaded."""
from pathlib import Path
import hashlib,html,json,shutil,subprocess,sys,zipfile
from package_surveyor_assets import video
G=Path(__file__).resolve().parents[1];U=G.parent;C=U/'Checkpoints/20261028_surveyor_revision'
P=C/'ReviewPackage';Z=U/'Builds/UNLISTED-Surveyor-Custom-Revision-20261028-PRIVATE.zip'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p):return json.loads(p.read_text(encoding='utf8'))
def git(*args):return subprocess.check_output(['git',*args],cwd=G,text=True).strip()
def pack(root,out):
 with zipfile.ZipFile(out,'x',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
  for p in root.rglob('*'):
   if p.is_file():z.write(p,p.relative_to(root).as_posix())
 with zipfile.ZipFile(out) as z:assert z.testzip() is None

def stage():
 assert not P.exists() and not Z.exists()
 cases={}
 for name in ['revised1080','current1080','rejected1080','revised1440','revised3440','capture_revision']:
  d=read(C/'Evidence02'/name/'result.json');assert d['exit_code']==0 and d['owner_unchanged'] and not d['errors'] and not d['warnings'] and d['reports'] and all(x['failed']==0 for x in d['reports']);cases[name]=d
 P.mkdir();shutil.copy2(C/'Candidate02/UNLISTED.exe',P/'UNLISTED.exe');shutil.copy2(G/'SURVEYOR_ART_REVISION.md',P/'START_HERE.md')
 shutil.copytree(U/'Checkpoints/20261028_surveyor_assets/ReviewPackage/ThirdPartyNotices',P/'ThirdPartyNotices')
 (P/'EditableCharacter').mkdir();shutil.copy2(C/'Construction04/Surveyor_Custom_Fieldcoat.blend',P/'EditableCharacter/Surveyor_Custom_Fieldcoat.blend');shutil.copy2(C/'Construction04/surveyor_revision.glb',P/'EditableCharacter/surveyor_revision.glb')
 shutil.copy2(C/'MPFB_Aged_Head_With_Eyes.blend',P/'EditableCharacter/MPFB_Aged_Head_With_Eyes.blend');shutil.copytree(C/'Textures',P/'EditableCharacter/Textures')
 page='<!doctype html><meta charset="utf-8"><title>UNLISTED custom Surveyor revision</title><style>body{background:#101214;color:#ddd;font:16px sans-serif;margin:24px}section{display:grid;grid-template-columns:repeat(3,1fr);gap:10px}img{width:100%}figure{margin:0}a{color:#bcd}video{width:95%;max-width:1200px}</style><h1>Surveyor Reborn — custom revision</h1><p>PRIVATE / NOT PROMOTED / FINAL ART STANDARD NOT MET. More human anatomy and custom workwear; coat wear, footwear and the ordinary uniform silhouette remain art deficiencies. Main game retains the original model. Prior menu/renderer faults remain unresolved.</p>'
 for name in cases:
  dest=P/'Evidence'/name;dest.mkdir(parents=True)
  for p in (C/'Evidence02'/name).iterdir():
   if p.suffix=='.png' or p.name in ['result.json','launch.json','native.log','repair_report.json']:shutil.copy2(p,dest/p.name)
 for name in ['neutral_front','neutral_face','neutral_side','neutral_rear','hall_silhouette','window_inside','window_outside','rain_outdoors','cellar']:
  page+='<h2>'+name+'</h2><section>'
  for label,folder in [('Active Surveyor','current1080'),('Rejected fantasy study','rejected1080'),('Custom revision / unapproved','revised1080')]:
   rel='Evidence/'+folder+'/'+name+'.png';page+='<figure><a href="'+rel+'"><img loading="lazy" src="'+rel+'"></a><figcaption>'+label+'</figcaption></figure>'
  page+='</section>'
 (P/'NeutralBlender').mkdir()
 page+='<h2>Neutral Blender construction review — not native game screenshots</h2><section>'
 for p in sorted((C/'Construction04').glob('*.png')):
  shutil.copy2(p,P/'NeutralBlender'/p.name);rel='NeutralBlender/'+p.name;page+='<figure><a href="'+rel+'"><img src="'+rel+'"></a><figcaption>'+p.stem+'</figcaption></figure>'
 page+='</section>'
 # The shared encoder takes its output-log directory from its module. Redirect
 # it explicitly; no earlier delivery/log is overwritten.
 import package_surveyor_assets as encoder
 encoder.C=C
 for case,name,caption in [('revised1080','Native_Custom_Character_Showcase','Placed eye-height art, window/rain/cellar, actual collision locomotion, actual sound-led investigation and real AI capture/death/retry.'),('capture_revision','Native_MultiAngle_Capture','Three actual AI approach angles, repeated/interrupted capture, pause, reduced motion and story survival.')]:
  video(C/'Evidence02'/case,P/(name+'.mp4'))
  page+='<h2>'+name+'</h2><p>'+caption+' Scene placement cuts are QA fixture transitions, not authored gameplay events. Approximately6fps sampled at actual wall-clock durations;30fps encoding repeats frames. Not a human playtest.</p><video controls src="'+name+'.mp4"></video>'
 for case in ['revised1440','revised3440']:
  page+='<h2>'+case+'</h2><section>'
  for p in sorted((P/'Evidence'/case).glob('*.png')):
   rel=p.relative_to(P).as_posix();page+='<figure><a href="'+rel+'"><img loading="lazy" src="'+rel+'"></a><figcaption>'+p.stem+'</figcaption></figure>'
  page+='</section>'
 (P/'EVIDENCE.html').write_text(page,encoding='utf8')
 (P/'REVIEW_CHARACTER.ps1').write_text('''param([ValidateSet('current','rejected','revision')][string]$Character='revision')
$reviewRoot=Split-Path -Parent $MyInvocation.MyCommand.Path
$reviewEvidence=Join-Path $reviewRoot ('Review_'+$Character+'_'+(Get-Date -Format 'yyyyMMdd_HHmmss'))
$reviewArgs=@('--','--surveyor-assets-qa','--capture-size=1920x1080','--route-light-capture',('--evidence='+$reviewEvidence))
if($Character -eq 'rejected'){$reviewArgs+='--surveyor-assets'}
if($Character -eq 'revision'){$reviewArgs+='--surveyor-revision'}
& (Join-Path $reviewRoot 'UNLISTED.exe') @reviewArgs
''',encoding='utf8')
 (P/'README.txt').write_text('PRIVATE CHARACTER SHOWCASE / NOT PROMOTED\nOpen EVIDENCE.html for comparisons and footage. EditableCharacter contains packed Blender sources, GLB and textures. REVIEW_CHARACTER.ps1 runs an isolated automated fixture for current/rejected/revision. Ordinary UNLISTED.exe retains the old game character and may use existing saves. This is not artistic approval, a public release or stability clearance.\n',encoding='utf8')
 (P/'VERIFICATION.json').write_text(json.dumps(cases,indent=2),encoding='utf8')
 pack(P,Z);I=C/'IndependentExtract';I.mkdir()
 with zipfile.ZipFile(Z) as z:z.extractall(I)
 assert sha(I/'UNLISTED.exe')==sha(C/'Candidate02/UNLISTED.exe')
 (C/'STAGED_DELIVERY.json').write_text(json.dumps({'runtime_source':git('rev-parse','HEAD'),'windows_zip':str(Z),'windows_sha256':sha(Z),'exe_sha256':sha(I/'UNLISTED.exe'),'gallery':str(I/'EVIDENCE.html'),'editable_blend':str(I/'EditableCharacter/Surveyor_Custom_Fieldcoat.blend'),'rigged_glb':str(I/'EditableCharacter/surveyor_revision.glb'),'status':'PRIVATE / NOT PROMOTED / FINAL ART STANDARD NOT MET / STABILITY NOT CLEARED'},indent=2),encoding='utf8');print(Z)

def recovery():
 assert not git('status','--porcelain')
 private=git('rev-parse','HEAD');files={G/n:'UNLISTED_Game/'+n for n in git('ls-files','-z').split('\0') if n and (G/n).is_file()}
 for p in (G/'tools/asset_sources').rglob('*'):
  if p.is_file():files[p]='UNLISTED_Game/tools/asset_sources/'+p.relative_to(G/'tools/asset_sources').as_posix()
 for p in C.rglob('*'):
  if p.is_file() and (p.suffix=='.blend' or p.parent==C and p.suffix in ['.py','.json','.log'] or any(s in p.parts for s in ['Textures','SystemEyes'])):
   if any(s in p.parts for s in ['ReviewPackage','IndependentExtract','PublicSource','MPFB_user']):continue
   files[p]='Private_Art_Revision/'+p.relative_to(C).as_posix()
 source=C/'UNLISTED_Custom_Surveyor_Complete_Private_Source.zip'
 with zipfile.ZipFile(source,'x',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
  for p,name in files.items():z.write(p,name)
  z.writestr('PRIVATE_SCOPE.txt','Complete tracked project and consumed media, ignored existing art sources, custom packed Blender construction/head sources and selected new textures. Original Assets inbox, older builds and player data remain separately preserved. Source '+private)
 with zipfile.ZipFile(source) as z:assert z.testzip() is None
 bundle=C/'UNLISTED_Private_History.bundle';subprocess.run(['git','bundle','create',str(bundle),'--all'],cwd=G,check=True);subprocess.run(['git','bundle','verify',str(bundle)],cwd=G,check=True,capture_output=True)
 result=read(C/'ExtractedCheck/result.json');assert result['exit_code']==0 and result['owner_unchanged'] and not result['errors'] and not result['warnings']
 d=read(C/'STAGED_DELIVERY.json');d.update(private_source=private,public_source=read(C/'PUBLIC_CHECKPOINT.json'),source_zip=str(source),source_sha256=sha(source),history_bundle=str(bundle),history_sha256=sha(bundle),extracted_verification=result)
 (C/'DELIVERY.json').write_text(json.dumps(d,indent=2),encoding='utf8');print(json.dumps(d,indent=2))
if __name__=='__main__':{'stage':stage,'recovery':recovery}[sys.argv[1]]()
