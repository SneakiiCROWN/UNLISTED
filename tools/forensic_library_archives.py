"""Private raw-library preservation and archive metadata/CRC audit; no extraction."""
from pathlib import Path
import hashlib,json,zipfile
R=Path(__file__).resolve().parents[2];L=R/'Assets';O=R/'Checkpoints/20261026_full_forensic_audit'
rows=[]
for p in sorted(L.rglob('*')):
    if not p.is_file():continue
    h=hashlib.sha256()
    with p.open('rb') as f:
        while b:=f.read(1024*1024):h.update(b)
    r={'file':p.relative_to(L).as_posix(),'bytes':p.stat().st_size,'sha256':h.hexdigest()}
    if p.suffix.lower()=='.zip':
        print('ARCHIVE',r['file'],flush=True)
        try:
            with zipfile.ZipFile(p) as z:
                entries=z.infolist();r['archive_entries']=len(entries);r['uncompressed_bytes']=sum(i.file_size for i in entries)
                r['license_candidates']=[i.filename for i in entries if any(s in i.filename.lower() for s in ['licen','copying','copyright','readme','terms','provenance'])]
                r['unsafe_paths']=[i.filename for i in entries if '..' in Path(i.filename.replace('\\','/')).parts or i.filename.startswith(('/','\\'))]
                if r['uncompressed_bytes']<=30*1024**3:r['first_bad_crc']=z.testzip();r['crc_checked']=True
                else:r['crc_checked']=False;r['crc_reason']='Bounded audit: archive exceeds30GiB expansion; not extracted.'
        except Exception as e:r['archive_error']=str(e)
    elif p.suffix.lower() in ['.rar','.7z']:r['archive_note']='SHA256 preserved; this helper does not validate this archive format.'
    rows.append(r)
    (O/'raw_library_hashes_and_archives.json').write_text(json.dumps({'scope':'All raw library files hashed; ZIP metadata and bounded CRC checked, no extraction. License filenames are candidates, not rights approval.','rows':rows},indent=2),encoding='utf8')
print(json.dumps({'files':len(rows),'archives':sum('archive_entries' in r for r in rows),'crc_failures':[r['file'] for r in rows if r.get('first_bad_crc') or r.get('archive_error')],'unsafe_archive_paths':[r['file'] for r in rows if r.get('unsafe_paths')]},indent=2),flush=True)
