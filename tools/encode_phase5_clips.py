"""Representative actual investigation clips; preserve sampled wall-clock timing."""
from pathlib import Path
import json,subprocess
G=Path(__file__).resolve().parents[1];C=G.parent/'Checkpoints/20261027_phase5_integration';D=C/'Evidence02/fresh_balanced1080';O=C/'Media';O.mkdir(exist_ok=True)
frames=json.loads((D/'frames.json').read_text(encoding='utf8'))
encounter=next(f['seconds'] for f in frames if 'Surveyor detection' in f['phase'])
departure=next(f['seconds'] for f in frames if f['phase']=='porch register return')
receipt=[]
for name,start,end in [('Arrival_and_approach',0,54),('Surveyor_contact_and_retry',encounter-4,encounter+36),('Porch_receipt_and_physical_departure',departure,frames[-1]['seconds'])]:
 chosen=[f for f in frames if start<=f['seconds']<=end];assert len(chosen)>2
 spans=[b['seconds']-a['seconds'] for a,b in zip(chosen,chosen[1:])];assert min(spans)>0
 duration=chosen[-1]['seconds']-chosen[0]['seconds']+sorted(spans)[len(spans)//2]
 lines=['ffconcat version 1.0']
 for i,f in enumerate(chosen):lines.extend(["file '"+(D/f['file']).as_posix()+"'",'duration '+str(spans[i] if i<len(spans) else sorted(spans)[len(spans)//2])])
 lines.append("file '"+(D/chosen[-1]['file']).as_posix()+"'")
 concat=O/(name+'.ffconcat');concat.write_text('\n'.join(lines)+'\n',encoding='utf8');movie=O/(name+'.mp4');assert not movie.exists()
 args=[r'C:\Program Files\Jellyfin\Server\ffmpeg.exe','-hide_banner','-f','concat','-safe','0','-i',str(concat),'-ss',str(chosen[0]['seconds']),'-i',str(D/'game_bus.wav'),'-t',str(duration),'-vf','fps=30','-c:v','libx264','-preset','fast','-crf','23','-pix_fmt','yuv420p','-c:a','aac','-b:a','128k','-shortest','-movflags','+faststart',str(movie)]
 with (O/(name+'_encode.log')).open('w',encoding='utf8') as log:subprocess.run(args,stdout=log,stderr=subprocess.STDOUT,check=True)
 receipt.append({'file':movie.name,'source_start_seconds':chosen[0]['seconds'],'duration_seconds':duration,'frames':len(chosen),'scope':'Native sampled images, approximately six samples/sec; encoded30fps repeats frames. Actual wall-clock durations and game bus audio, not a native FPS or human-playtest claim.'});print(name,duration,flush=True)
(O/'RECORDING_SCOPE.json').write_text(json.dumps(receipt,indent=2),encoding='utf8')
