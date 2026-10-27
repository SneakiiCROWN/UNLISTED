from pathlib import Path
import sys,subprocess
c=Path(r"C:\Users\Snkii\Documents\UNLISTED\Checkpoints\20261027_graphics_phase4")
for name,size in [("final_balanced1920","1920x1080"),("final_balanced2560","2560x1440"),("particle_recheck_2","2560x1440"),("particle_recheck_3","2560x1440")]:
 subprocess.run([sys.executable,"tools/run_graphics_study.py","--exe",str(c/"Candidate04/UNLISTED.exe"),"--output",str(c/"Evidence04"/name),"--profile","balanced","--size",size,"--phase2","--phase3","--phase4","--foreground","--walk"],check=True)
print("PARTICLE_RECHECK_COMPLETE",flush=True)
