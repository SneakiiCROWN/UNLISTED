"""Portable gallery from untouched in-engine screenshots, with their scope."""
from pathlib import Path
from html import escape
import shutil, zipfile

G=Path(__file__).resolve().parents[1];root=G.parent/'Builds'
B=root/'UNLISTED_Inspection_12';E=B/'Evidence'

def main():
    assert not E.exists();E.mkdir()
    shots=[
        ('Before: 0.8.1 pencil surface','UNLISTED_Director_Arrival_05/QA/continuous/M01_carbon_rubbing.png'),
        ('Shed inspection equipment / final ultrawide mechanics fixture','UNLISTED_Inspection_12/QA/inspection/I01_inspection_case.png'),
        ('Local UV illumination: unread areas stay dark','UNLISTED_Inspection_12/QA/inspection/I04_local_uv_beam.png'),
        ('Frequency under the beam: no need to sweep blank margins','UNLISTED_Inspection_12/QA/inspection/I04b_frequency_under_beam.png'),
        ('Normal light after discovery: no permanent glowing answer','UNLISTED_Inspection_12/QA/inspection/I06_white_after_discovery.png'),
        ('World sleeve seal under inspection light','UNLISTED_Inspection_12/QA/inspection/I08_world_uv_seal.png'),
        ('Visible service names and line identifiers','UNLISTED_Inspection_12/QA/inspection/I10_service_mapping.png'),
        ('Actual closed cupboard during the fresh route','UNLISTED_Inspection_11/QA/continuous/H01_storage_cupboard.png'),
        ('Inside physical cover, torch off / fresh route','UNLISTED_Inspection_11/QA/continuous/H02_inside_cover.png'),
        ('Survived search and exited / fresh route','UNLISTED_Inspection_11/QA/continuous/H03_after_search.png'),
        ('Seen-entry breach / separate risk fixture, unchanged Surveyor model','UNLISTED_Inspection_10/QA/storage/H04_seen_entry_breach.png'),
        ('Unpowered archive stays unreadable / fresh route','UNLISTED_Inspection_11/QA/continuous/R01_unpowered_office.png'),
        ('Window watcher facing the window / fresh route','UNLISTED_Inspection_11/QA/continuous/M06_window_presence.png'),
        ('Revised live-step comparison / ultrawide layout fixture','UNLISTED_Inspection_12/QA/story_clarity/inspection_comparison_3440.png'),
        ('Ending layout / 1440p fixture','UNLISTED_Inspection_12/QA/story_clarity/current_on_record_2560.png'),
    ]
    body=[]
    for i,(caption,name) in enumerate(shots):
        source=root/name;assert source.is_file(),source
        target=E/(str(i).zfill(2)+'_'+source.name);shutil.copy2(source,target)
        body.append('<figure><figcaption>'+escape(caption)+'</figcaption><a href="'+target.name+'"><img loading="lazy" src="'+target.name+'"></a></figure>')
    (E/'index.html').write_text('<!doctype html><meta charset="utf-8"><title>UNLISTED / Inspection evidence</title><style>body{background:#101619;color:#d4d9d5;font:17px system-ui;margin:30px;max-width:1500px}img{width:100%}figure{margin:32px 0}figcaption{padding:12px 0}a{color:#b6c8b5}</style><h1>UNLISTED 0.9.0 / Inspection</h1><p>Actual exported Windows screenshots. No retouching or concept images. Captions distinguish fresh-route evidence from prepared mechanics/layout fixtures. Open images for their full native resolution. The broader expansion and character-art redesign remain unfinished; this gallery is not human artistic approval.</p><p>Inspection_native.mp4 accompanies the release separately: native wall-clock footage, sampled frames and same-session game audio, driven by isolated automated input. Its duration is not human first-play time.</p>'+''.join(body),encoding='utf-8')
    archive=B/'UNLISTED-Inspection-Evidence.zip';assert not archive.exists()
    with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED,6) as z:
        for file in E.iterdir():z.write(file,'Evidence/'+file.name)
    print(archive,flush=True)

if __name__=='__main__':main()
