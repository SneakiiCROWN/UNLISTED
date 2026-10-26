"""Record completed native evidence without implying an intermittent crash fix."""
from pathlib import Path
import ast,json
G=Path(__file__).resolve().parents[1]
B=G.parent/'Builds/UNLISTED_Stability_Terror_03'
read=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
ast.parse((G/'tools/seal_stability_terror.py').read_text())
p=read(G/'DEVELOPMENT_CHECKPOINT.json')
p.update(version='0.10.8-dev',milestone='Stability & Terror',private_source_commit='d845e11f93af61081d840e85407f25cf369ba9f1',github_source_commit='b54b405e25f2af616cb0d0a862936194d41bb24a',development_tag='dev-v0.10.8-stability-terror-20261026',verification='STABILITY_TERROR_VERIFICATION.md',latest_source_is_verified=False,targeted_native_checks_passed=True)
p['targeted_checks']={n:read(B/'QA'/n/'repair_report.json')['passed'] for n in ['aftermath','impossible','ending_b']}
p['targeted_checks']['normal_root']=len(read(B/'QA/normal_root/probe_report.json')['checks'])
p['surveyor_art']='Unchanged active model and all art; crash investigation took priority over new construction.'
p['verification_limit']='Original native Vulkan-driver access violation and external-entry failure preserved. All bounded controls and final candidate checks pass; intermittent root cause unresolved. Private QA candidate only.'
p['performance']['results']=[read(B/'QA'/n/'cellar_route_profile.json')['results'][0] for n in ['safe_profile_1080','safe_profile_1440','safe_profile_wide']]
p['performance']['first_final_profile']='Prior 0.10.7 crash preserved; 0.10.8 uses separate processes per resolution.'
p['performance']['repeat']='Three final fixed-resolution processes completed; no before/after speed or crash-fix claim.'
p['controlled_comparisons']='Seven embedded cases: three fixed sizes, pre-start resize, live resize, normal root, child-only layer-filtered live resize. All completed. Preserved 0.10.7 route also completed.'
p['renderer_evidence']='Vulkan / Forward+ runtime queries; installed nv-vk64.json maps Vulkan ICD to nvoglv64.dll; original stack crosses vulkan-1.dll.'
p['system_modifications']='None; one comparison used explicit child-only overlay filtering.'
p['reused_components']['scope']='Retained previous baselines, not rerun this milestone; all art/resources byte-identical to 0.10.7.'
(G/'DEVELOPMENT_CHECKPOINT.json').write_text(json.dumps(p,indent=2)+'\n',encoding='utf8')
with (G/'STABILITY_TERROR_VERIFICATION.md').open('a',encoding='utf8') as f:
    f.write('\n## Final candidate 03 completed evidence\n\n')
    f.write('Native exported checks: '+', '.join(n+' '+str(c)+'/0' for n,c in p['targeted_checks'].items())+'. Owner save/settings integrity remained unchanged. Ending B uses an earned historical snapshot; this is segmented verification, not a fresh full investigation. Independent extracted-package ending A is recorded separately in DELIVERY.json.\n\n')
    f.write('| Render size | Median ms | p95 ms | Maximum ms |\n|---|---:|---:|---:|\n')
    for r in p['performance']['results']:f.write(f"| {r['render_size']} | {r['median_ms']} | {r['p95_ms']} | {r['max_ms']} |\n")
    f.write('\nThese are warmed ~16.6-second, 60fps-capped, isolated walking samples on i9-14900K / RTX 4080 SUPER. Native render sizes are presented in a desktop window. Not uncapped speed, whole-game stability, minimum-spec approval or proof of a crash fix. All successful controls leave intermittence unresolved. No literal manual Alt-Tab, physical-controller or human comprehension approval is claimed.\n')
print(json.dumps(p['targeted_checks']))
