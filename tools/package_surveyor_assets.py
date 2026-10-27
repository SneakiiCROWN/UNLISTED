"""Private review delivery; never uploads media or creates a public release."""
from pathlib import Path
import hashlib, html, json, shutil, subprocess, zipfile, sys
G=Path(__file__).resolve().parents[1];U=G.parent;C=U/'Checkpoints/20261028_surveyor_assets'
P=C/'ReviewPackage';Z=U/'Builds/UNLISTED-Surveyor-Asset-Study-20261028-PRIVATE.zip'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def git(*args):return subprocess.check_output(['git',*args],cwd=G,text=True).strip()
def read(p):return json.loads(p.read_text(encoding='utf8'))
def pack(root,target):
 with zipfile.ZipFile(target,'x',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
  for p in root.rglob('*'):
   if p.is_file():z.write(p,p.relative_to(root).as_posix())
 with zipfile.ZipFile(target) as z:assert z.testzip() is None
def video(directory,target,allow=None):
 frames=[f for f in read(directory/'frames.json') if allow is None or allow(f)]
 assert len(frames)>2
 lines=['ffconcat version 1.0']
 for i,f in enumerate(frames):
  duration=frames[i+1]['seconds']-f['seconds'] if i+1<len(frames) else .17
  assert duration>0
  lines.extend(["file '"+(directory/f['file']).as_posix()+"'",'duration '+str(duration)])
 lines.append("file '"+(directory/frames[-1]['file']).as_posix()+"'")
 concat=C/(target.stem+'.ffconcat');concat.write_text('\n'.join(lines)+'\n',encoding='utf8')
 with (C/(target.stem+'_encode.log')).open('w',encoding='utf8') as log:
  subprocess.run([r'C:\Program Files\Jellyfin\Server\ffmpeg.exe','-hide_banner','-f','concat','-safe','0','-i',str(concat),'-ss',str(frames[0]['seconds']),'-i',str(directory/'game_bus.wav'),'-vf','fps=30','-c:v','libx264','-threads','4','-preset','fast','-crf','22','-pix_fmt','yuv420p','-c:a','aac','-b:a','128k','-shortest','-movflags','+faststart',str(target)],stdout=log,stderr=subprocess.STDOUT,check=True)

def stage():
 assert not P.exists() and not Z.exists()
 cases={}
 for name in ['Evidence01/baseline1080','Evidence02/live1080','Evidence02/candidate1440','Evidence02/candidate3440','Evidence02/candidate_threat']:
  result=read(C/name/'result.json');assert result['exit_code']==0 and result['owner_unchanged'] and not result['errors'] and not result['warnings'] and result['reports'] and all(x['failed']==0 for x in result['reports']);cases[name]=result
 P.mkdir();shutil.copy2(C/'Candidate02/UNLISTED.exe',P/'UNLISTED.exe');shutil.copy2(G/'SURVEYOR_ASSET_STUDY.md',P/'START_HERE.md')
 shutil.copytree(U/'Checkpoints/20261027_next_nightmare/IndependentExtract/ThirdPartyNotices',P/'ThirdPartyNotices')
 licence=next((C/'Sources').rglob('License_Standard.txt'));shutil.copy2(licence,P/'ThirdPartyNotices/Character_Pack_CC0.txt')
 shutil.copy2(U/'Assets/Audio assets/Sonniss.com-GDC2026-GameAudioBundle/License - GDC Game Audio.pdf',P/'ThirdPartyNotices/Sonniss_GDC2026.pdf')
 page='<!doctype html><meta charset="utf-8"><title>UNLISTED Surveyor asset study</title><style>body{background:#101214;color:#ddd;font:16px sans-serif;margin:25px}section{display:grid;grid-template-columns:1fr 1fr;gap:12px}img{width:100%}figure{margin:0}a{color:#bcd}video{width:95%;max-width:1200px}</style><h1>Surveyor asset study — NOT PROMOTED</h1><p>Actual exported Windows comparisons. Mechanics passing does not approve character art. The fantasy-derived outfit and stylised face are unfinished. Ordinary gameplay retains the old model. Prior menu/renderer stability faults remain unresolved.</p>'
 for label,d in [('Current fallback','Evidence01/baseline1080'),('Unapproved candidate','Evidence01/candidate1080'),('1440p candidate','Evidence02/candidate1440'),('Ultrawide candidate','Evidence02/candidate3440'),('Real AI contact','Evidence02/live1080'),('Threat regression','Evidence02/candidate_threat')]:
  dest=P/'Evidence'/d;dest.mkdir(parents=True)
  for p in (C/d).iterdir():
   if p.suffix=='.png' or p.name in ['native.log','result.json','launch.json','repair_report.json','threat_report.json']:shutil.copy2(p,dest/p.name)
 for name in ['neutral_front','neutral_face','neutral_side','neutral_rear','hall_silhouette','window_inside','window_outside']:
  page+='<h2>'+html.escape(name)+'</h2><section>'
  for label,d in [('Current fallback','Evidence01/baseline1080'),('Unapproved candidate','Evidence01/candidate1080')]:
   rel='Evidence/'+d+'/'+name+'.png';page+='<figure><a href="'+rel+'"><img loading="lazy" src="'+rel+'"></a><figcaption>'+label+'</figcaption></figure>'
  page+='</section>'
 for name,d,allow,caption in [
   ('Candidate_Art_Window_Walk_Run',C/'Evidence01/candidate1080',lambda f:f['phase']!='real AI pursuit and contact','Art, retarget preview, window and locomotion excerpt. Its following contact section failed because the fixture disabled AI; the entire failure report is retained.'),
   ('Candidate_Real_Pursuit_Capture_Retry',C/'Evidence02/live1080',None,'Corrected real AI perception, pursuit, warned contact, pause, death and retry. Placed encounter fixture, not a human investigation.'),
   ('Current_Fallback_Comparison',C/'Evidence01/baseline1080',None,'Matched current-model comparison fixtures.')]:
  video(d,P/(name+'.mp4'));page+='<h2>'+name+'</h2><p>'+caption+' Sampled roughly6fps, real wall-clock durations;30fps encoding repeats frames. Audio is actual game output, not subjective listening approval.</p><video controls src="'+name+'.mp4"></video>'
 for label,d in [('1440p','Evidence02/candidate1440'),('3440x1440','Evidence02/candidate3440'),('Real capture','Evidence02/live1080')]:
  page+='<h2>'+label+'</h2><section>'
  for p in sorted((P/'Evidence'/d).glob('*.png')):
   rel=p.relative_to(P).as_posix();page+='<figure><a href="'+rel+'"><img loading="lazy" src="'+rel+'"></a><figcaption>'+html.escape(p.stem)+'</figcaption></figure>'
  page+='</section>'
 (P/'EVIDENCE.html').write_text(page,encoding='utf8')
 (P/'LAUNCH_STUDY.ps1').write_text("$studyRoot = Split-Path -Parent $MyInvocation.MyCommand.Path\n$studyEvidence = Join-Path $studyRoot ('LocalReview_' + (Get-Date -Format 'yyyyMMdd_HHmmss'))\n& (Join-Path $studyRoot 'UNLISTED.exe') -- --surveyor-assets-qa --surveyor-assets --capture-size=1920x1080 --route-light-capture ('--evidence=' + $studyEvidence)\n",encoding='utf8')
 (P/'READ_FIRST.txt').write_text('PRIVATE CHARACTER STUDY / NOT PROMOTED\nOrdinary UNLISTED.exe launches the preserved fallback game and may use existing saves. Use EVIDENCE.html to review comparisons without touching your save. LAUNCH_STUDY.ps1 runs an isolated automated candidate fixture, not a normal human playthrough. No visual approval or crash fix is claimed.\n',encoding='utf8')
 (P/'PRIVATE_PROVENANCE.json').write_text((G/'assets/studies/surveyor_asset/PRIVATE_PROVENANCE.json').read_text(),encoding='utf8')
 (P/'VERIFICATION.json').write_text(json.dumps(cases,indent=2),encoding='utf8')
 pack(P,Z);extract=C/'IndependentExtract';extract.mkdir()
 with zipfile.ZipFile(Z) as z:z.extractall(extract)
 assert sha(extract/'UNLISTED.exe')==sha(C/'Candidate02/UNLISTED.exe')
 (C/'STAGED_DELIVERY.json').write_text(json.dumps({'runtime_source':git('rev-parse','HEAD'),'windows_zip':str(Z),'windows_sha256':sha(Z),'exe_sha256':sha(extract/'UNLISTED.exe'),'gallery':str(extract/'EVIDENCE.html'),'status':'PRIVATE STUDY / ART NOT MET / NOT PROMOTED / STABILITY NOT CLEARED'},indent=2),encoding='utf8')
 print(Z)

def source():
 assert not git('status','--porcelain')
 private=git('rev-parse','HEAD');target=C/'UNLISTED_Surveyor_Asset_Study_Complete_Private_Source.zip';files={G/n:'UNLISTED_Game/'+n for n in git('ls-files','-z').split('\0') if n and (G/n).is_file()}
 for p in (G/'tools/asset_sources').rglob('*'):
  if p.is_file():files[p]='UNLISTED_Game/tools/asset_sources/'+p.relative_to(G/'tools/asset_sources').as_posix()
 for folder in ['Construction01','Construction02','Construction03','Construction04','Sources','TextureWork']:
  for p in (C/folder).rglob('*'):
   if p.is_file() and p.suffix not in ['.blend1']:files[p]='Private_Character_Work/'+p.relative_to(C).as_posix()
 with zipfile.ZipFile(target,'x',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
  for p,name in files.items():z.write(p,name)
  z.writestr('PRIVATE_SCOPE.txt','Complete tracked project, consumed assets, existing ignored extracted source, new character staging and packed Blender projects. Original full Assets inbox, addon archive, older checkpoints and player data remain separately preserved. Private commit '+private)
 with zipfile.ZipFile(target) as z:assert z.testzip() is None
 bundle=C/'UNLISTED_Private_History.bundle';subprocess.run(['git','bundle','create',str(bundle),'--all'],cwd=G,check=True);subprocess.run(['git','bundle','verify',str(bundle)],cwd=G,check=True,capture_output=True)
 receipt=read(C/'STAGED_DELIVERY.json');receipt.update(private_source=private,source_zip=str(target),source_sha256=sha(target),history_bundle=str(bundle),history_sha256=sha(bundle),extracted_verification=read(C/'ExtractedLiveCheck/result.json'),public_source=read(C/'PUBLIC_CHECKPOINT.json'))
 assert receipt['extracted_verification']['exit_code']==0 and receipt['extracted_verification']['owner_unchanged'] and not receipt['extracted_verification']['errors']
 (C/'DELIVERY.json').write_text(json.dumps(receipt,indent=2),encoding='utf8');print(json.dumps(receipt,indent=2))
if __name__=='__main__':{'stage':stage,'source':source}[sys.argv[1]]()
