"""Encode native sampled screenshots using their recorded wall-clock timing."""
from pathlib import Path
import json,subprocess,wave,array,math
C=Path(r'C:\Users\Snkii\Documents\UNLISTED\Checkpoints\20261027_graphics_phase4')
for name in ['approach','approach_original','approach_enhanced','window_inside','window_outside','window_ultrawide']:
 d=C/'Evidence04'/('record_'+name);frames=json.loads((d/'frames.json').read_text(encoding='utf8'));assert len(frames)>2
 spans=[b['seconds']-a['seconds'] for a,b in zip(frames,frames[1:])];assert min(spans)>0
 lines=['ffconcat version 1.0']
 for i,f in enumerate(frames):
  lines.extend(["file '"+f['file']+"'",'duration '+str(spans[i] if i<len(spans) else sorted(spans)[len(spans)//2])])
 lines.append("file '"+frames[-1]['file']+"'")
 (d/'native.ffconcat').write_text('\n'.join(lines)+'\n',encoding='utf8')
 movie=d/'native_walk.mp4';assert not movie.exists()
 with (d/'encode.log').open('w',encoding='utf8') as log:
  subprocess.run([r'C:\Program Files\Jellyfin\Server\ffmpeg.exe','-hide_banner','-f','concat','-safe','0','-i',str(d/'native.ffconcat'),'-i',str(d/'game_bus.wav'),'-vf','fps=30','-c:v','libx264','-preset','fast','-crf','21','-pix_fmt','yuv420p','-c:a','aac','-b:a','128k','-shortest','-movflags','+faststart',str(movie)],stdout=log,stderr=subprocess.STDOUT,check=True)
 with wave.open(str(d/'game_bus.wav')) as w:
  duration=w.getnframes()/w.getframerate();assert w.getsampwidth()==2
  signal=array.array('h',w.readframes(w.getnframes()));peak=max(abs(s) for s in signal)/32768
 (d/'movie_scope.json').write_text(json.dumps({'frames':len(frames),'sampled_frame_span_seconds':frames[-1]['seconds']-frames[0]['seconds'],'audio_seconds':duration,'peak_dbfs':20*math.log10(max(peak,1e-12)),'scope':'Actual native sampled-frame wall-clock durations; 30fps encoding repeats frames, not a gameplay-FPS claim. Non-silence is not subjective listening approval.'},indent=2),encoding='utf8')
 print(name,frames[-1]['seconds']-frames[0]['seconds'],peak,flush=True)
