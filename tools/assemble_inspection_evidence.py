"""Keep native capture timestamps and Master-bus audio; no fabricated gameplay."""
from pathlib import Path
import json, subprocess

G=Path(__file__).resolve().parents[1]
R=G.parent/'Builds/UNLISTED_Inspection_11/QA/continuous'
B=G.parent/'Builds/UNLISTED_Inspection_12'
FF=Path(r'C:\Program Files\Jellyfin\Server\ffmpeg.exe')

def main():
    report=json.loads((R/'repair_report.json').read_text());assert report['failed']==0
    frames=json.loads((R/'frames.json').read_text())
    lines=['ffconcat version 1.0']
    gaps=[]
    for i,row in enumerate(frames):
        end=frames[i+1]['seconds'] if i+1<len(frames) else report['duration_seconds']
        duration=end-(row['seconds'] if i else 0);gaps.append(duration)
        lines.extend(["file '"+row['file']+"'",'option framerate 1000','duration '+str(max(.001,duration))])
    concat=R/'native_frames.ffconcat';concat.write_text('\n'.join(lines)+'\n',encoding='utf-8')
    out=B/'Inspection_native.mp4';assert not out.exists()
    with (B/'Inspection_native.encode.log').open('w',encoding='utf-8') as log:
        subprocess.run([str(FF),'-hide_banner','-safe','0','-f','concat','-i',str(concat),'-i',str(R/'game_bus.wav'),
            '-vf','fps=30','-c:v','libx264','-preset','veryfast','-threads','2','-crf','22','-pix_fmt','yuv420p',
            '-c:a','aac','-b:a','160k','-af','apad','-shortest',str(out)],stdout=log,stderr=subprocess.STDOUT,check=True)
    (B/'Inspection_native.capture.json').write_text(json.dumps({'source':'Real exported Windows viewport with isolated automated input',
        'duration_seconds':report['duration_seconds'],'source_frames':len(frames),'average_capture_fps':len(frames)/report['duration_seconds'],
        'largest_capture_interval':max(gaps),'encoded_fps':30,'timing':'Native timestamps; repeated sampled frames, no interpolation or speedup',
        'audio':'Same-session Godot Master bus; no new subjective listening assessment',
        'scope':'Fresh complete investigation and both departures. Automated known-route duration is not human first-play time.'},indent=2),encoding='utf-8')
    print(out,flush=True)

if __name__=='__main__':main()
