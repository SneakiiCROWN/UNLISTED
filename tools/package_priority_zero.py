"""Private diagnostic delivery. Never advertises a crash repair or publishes a release."""
from pathlib import Path
import hashlib,json,shutil,subprocess,sys,zipfile
G=Path(__file__).resolve().parents[1];R=G.parent
B=R/'Builds/UNLISTED_Priority_Zero_Diagnostic_05'
COMPONENTS=R/'Builds/UNLISTED_Priority_Zero_Diagnostic_04'
C=R/'Checkpoints/20261026_priority_zero_diagnostic'
Z=R/'Builds/UNLISTED-Windows-Menu-Investigation-v0.10.9-dev-PRIVATE.zip'
read=lambda p:json.loads(p.read_text(encoding='utf8'))
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
def stage():
    results=read(COMPONENTS/'component_results.json')
    assert len(results)==6 and all(r['completed'] for r in results)
    d=read(B/'QA/deferred/result.json')
    assert d['exit_code']==0 and d['all_expected_events'] and d['owner_unchanged'] and not d['script_errors']
    assert not C.exists() and not Z.exists()
    C.mkdir();S=C/'Package';S.mkdir()
    shutil.copy2(B/'UNLISTED.exe',S/'UNLISTED.exe')
    previous=R/'Checkpoints/20261026_player_experience_candidate/IndependentExtract'
    shutil.copytree(previous/'ThirdPartyNotices',S/'ThirdPartyNotices')
    shutil.copy2(G/'THIRD_PARTY.md',S/'THIRD_PARTY.md')
    for name in ['PRIORITY_ZERO_VERIFICATION.md','PRIORITY_ZERO_PROGRESS.md','OWNER_MENU_IDLE_FAILURE.md']:
        shutil.copy2(G/name,S/name)
    (S/'START_HERE.txt').write_text('UNLISTED 0.10.9-dev - PRIVATE MENU INVESTIGATION CANDIDATE\n\nExtract the entire ZIP into a folder, then run UNLISTED.exe.\nThis is NOT a demonstrated crash repair or stability-cleared release.\nThe ordinary menu, gameplay, saves and licensed runtime assets are retained.\nAdditional diagnostic scenes/options are inactive during normal startup.\nNo Windows, driver, registry, BIOS or overlay changes were made.\nRead PRIORITY_ZERO_VERIFICATION.md for exact evidence and limitations.\nPrevious builds and all owner data are preserved. No public release.\n',encoding='utf8')
    with zipfile.ZipFile(Z,'x',compression=zipfile.ZIP_DEFLATED,compresslevel=6) as z:
        for p in sorted(S.rglob('*')):
            if p.is_file():z.write(p,p.relative_to(S).as_posix())
    I=C/'IndependentExtract'
    with zipfile.ZipFile(Z) as z:
        assert z.testzip() is None
        z.extractall(I)
    assert sha(I/'UNLISTED.exe')==sha(B/'UNLISTED.exe')
    delivery={'status':'Diagnostic candidate. Owner crash remains unresolved; no production fix asserted.','version':'0.10.9-dev','windows_zip':str(Z),'windows_sha256':sha(Z),'executable_sha256':sha(I/'UNLISTED.exe'),'independent_executable':str(I/'UNLISTED.exe'),'components':results,'component_evidence_build':str(COMPONENTS),'deferred':d,'ordinary_extracted_candidate_idle':'Pending; inspect final delivery receipt.','public_release':'Unchanged'}
    (C/'DELIVERY.json').write_text(json.dumps(delivery,indent=2),encoding='utf8')
    print(json.dumps(delivery,indent=2))
def finalize():
    d=read(C/'DELIVERY.json')
    normal=read(R/'Builds/UNLISTED_Priority_Zero_Evidence/normal_diagnostic_01/result.json')
    assert normal['exit_code']==0 and normal['target_duration_reached'] and normal['owner_unchanged']
    assert sha(Z)==d['windows_sha256']
    assert not subprocess.check_output(['git','status','--porcelain'],cwd=G,text=True).strip()
    head=subprocess.check_output(['git','rev-parse','HEAD'],cwd=G,text=True).strip()
    src=C/'UNLISTED_Menu_Investigation_Complete_Private_Source.zip'
    tracked=subprocess.check_output(['git','ls-files','-z'],cwd=G).decode().split('\0')
    with zipfile.ZipFile(src,'x',compression=zipfile.ZIP_DEFLATED,compresslevel=6) as z:
        for name in sorted(filter(None,tracked)):
            p=G/name
            if p.is_file():z.write(p,'UNLISTED_Game/'+name)
        for root,label in [(R/'Checkpoints/20261026_owner_menu_idle_5300','Private_Owner_Crash'),(R/'Builds/UNLISTED_Priority_Zero_Evidence','Private_Current_Evidence')]:
            for p in sorted(root.rglob('*')):
                if p.is_file():z.write(p,label+'/'+p.relative_to(root).as_posix())
        for build in [COMPONENTS,B]:
            for p in sorted(build.rglob('*')):
                if p.is_file() and p.suffix.lower() not in ['.exe','.dll'] and 'OwnerDataBefore' not in p.parts:
                    z.write(p,'Private_Diagnostic_Evidence/'+build.name+'/'+p.relative_to(build).as_posix())
    with zipfile.ZipFile(src) as z:assert z.testzip() is None
    d.update(private_source_checkpoint=head,complete_private_source_zip=str(src),source_sha256=sha(src),ordinary_extracted_candidate_idle=normal)
    (C/'DELIVERY.json').write_text(json.dumps(d,indent=2),encoding='utf8')
    print(json.dumps(d,indent=2))
if __name__=='__main__':
    assert sys.argv[1] in ['stage','finalize']
    {'stage':stage,'finalize':finalize}[sys.argv[1]]()
