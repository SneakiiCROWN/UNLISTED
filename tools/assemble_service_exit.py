"""Preserve wall-clock exported gameplay and a labelled, unretouched evidence gallery."""
from pathlib import Path
import html,json,shutil,subprocess,sys,zipfile
import package_service_repair as prior
G=Path(__file__).resolve().parents[1]
B=G.parent/'Builds'/sys.argv[1]
R=B/'QA/continuous'
report=json.loads((R/'repair_report.json').read_text());assert report['failed']==0
frames=json.loads((R/'frames.json').read_text());assert frames
lines=['ffconcat version 1.0']
for i,row in enumerate(frames):
    end=frames[i+1]['seconds'] if i+1<len(frames) else report['duration_seconds']
    lines.extend(["file '"+row['file']+"'",'option framerate 1000','duration '+str(max(.001,end-(row['seconds'] if i else 0)))])
concat=R/'native_frames.ffconcat';concat.write_text('\n'.join(lines)+'\n',encoding='utf8')
video=B/'UNLISTED_Other_Way_Out_native.mp4'
assert not video.exists(),'Preserve earlier rendered evidence'
with (B/'native_encode.log').open('w',encoding='utf8') as log:
    subprocess.run([r'C:\Program Files\Jellyfin\Server\ffmpeg.exe','-hide_banner','-y','-safe','0','-f','concat','-i',str(concat),'-i',str(R/'game_bus.wav'),'-vf','fps=30','-c:v','libx264','-preset','veryfast','-threads','2','-crf','24','-pix_fmt','yuv420p','-c:a','aac','-b:a','160k','-af','apad','-t',str(report['duration_seconds']),'-movflags','+faststart',str(video)],stdout=log,stderr=subprocess.STDOUT,check=True)
capture=dict(source='Actual exported Windows viewport and simultaneous game Master bus; isolated automated inputs, not a human playtest',frames=len(frames),duration_seconds=report['duration_seconds'],average_sampled_fps=len(frames)/report['duration_seconds'],largest_sample_interval=max(frames[i+1]['seconds']-frames[i]['seconds'] for i in range(len(frames)-1)),encoded_fps=30,timing='Original wall-clock timestamps, repeated frames; no interpolation or accelerated simulation',audio=prior.signal(R/'game_bus.wav'))
(B/'NATIVE_CAPTURE.json').write_text(json.dumps(capture,indent=2),encoding='utf8')
E=B/'Evidence';E.mkdir(exist_ok=False)
cards=[]
specs=[('Preserved 0.9.0 records store before this extension',G.parent/'Builds/UNLISTED_Inspection_11/QA/continuous/U03_records_store.png'),('New physical clearance box',R/'W02_unsigned_carbon.png'),('Existing store with its new service connection',R/'U03_records_store.png'),('Actual exterior bulkhead, connected to the property',R/'X01_exterior_bulkhead.png'),('Opening from below, before crossing the contact',R/'X03_open_return.png'),('Discovery, earned on the fresh investigation',R/'X04_false_departure_evidence.png'),('Local practical-light failure; player torch stays usable',R/'X05_blackout_store.png'),('Actual escape into the rainy yard',R/'X06_yard_escape.png'),('1440p terminal and physical strip',G.parent/'Builds/UNLISTED_ServiceExit_09/QA/exit1440/X09_terminal_contact_strip.png'),('Ultrawide discovery-context register / explicit layout fixture',G.parent/'Builds/UNLISTED_ServiceExit_09/QA/exituw/X11_discovery_register.png'),('Focused deliberate-contact death / same encounter code, existing unfinished character art',G.parent/'Builds/UNLISTED_ServiceExit_08/QA/exit/X07_deliberate_contact_death.png')]
for i,(label,p) in enumerate(specs):
    assert p.exists(),p
    name=f'{i:02d}_'+p.name;shutil.copy2(p,E/name);cards.append('<section><h2>'+html.escape(label)+'</h2><img loading="lazy" src="'+name+'"></section>')
for label,p in [('fresh_route',R/'repair_report.json'),('focused_mechanics',G.parent/'Builds/UNLISTED_ServiceExit_08/QA/exit/report.json'),('layout1440',G.parent/'Builds/UNLISTED_ServiceExit_09/QA/exit1440/report.json'),('layout_ultrawide',G.parent/'Builds/UNLISTED_ServiceExit_09/QA/exituw/report.json')]:shutil.copy2(p,E/(label+'.json'))
shutil.copy2(B/'NATIVE_CAPTURE.json',E/'NATIVE_CAPTURE.json')
(E/'index.html').write_text('<!doctype html><meta charset="utf-8"><title>UNLISTED / The Other Way Out</title><style>body{background:#111717;color:#d0d5c9;font:17px system-ui;max-width:1400px;margin:35px auto;padding:20px}h1,h2{font-weight:500}img{display:block;width:100%;height:auto}section{margin:45px 0}a{color:#c0d8d4}</style><h1>UNLISTED 0.9.1 / The Other Way Out</h1><p>Unretouched exported-game images. The native recording uses actual wall-clock timestamps and isolated automated input. The fresh route earns both departures; the alternate restores the earned porch checkpoint. Focused fixtures are labelled separately. Human art, story, fear, listening and first-play duration remain pending. The Surveyor mesh is unchanged.</p><p><a href="../UNLISTED_Other_Way_Out_native.mp4">Native gameplay recording (sibling download)</a></p>'+''.join(cards),encoding='utf8')
archive=B.parent/'UNLISTED-Other-Way-Out-Evidence.zip';assert not archive.exists()
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED,6) as z:
    for p in E.iterdir():z.write(p,'Evidence/'+p.name)
with zipfile.ZipFile(archive) as z:assert z.testzip() is None
print(json.dumps(capture),flush=True)
