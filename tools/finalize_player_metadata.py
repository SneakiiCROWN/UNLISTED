"""Update delivery metadata from completed focused evidence, without self-pinning HEAD."""
import json
from seal_player_experience import G,B,reports
p=json.loads((G/'DEVELOPMENT_CHECKPOINT.json').read_text(encoding='utf-8-sig'))
p.update(version='0.10.9-dev',milestone='The Player Experience',private_source_commit='e8d52600708ff8b78fc089c83d4f3332bc577acb',github_source_commit='e8e3349f652cdc949ad8526204aeff17db34b1f9',development_tag='dev-v0.10.9-player-experience-20261026',verification='PLAYER_EXPERIENCE_VERIFICATION.md',latest_source_is_verified=False,targeted_native_checks_passed=True)
p['targeted_checks']=reports()
p['previous_candidate']={'version':'0.10.8-dev','private_source':'248b3aaefb34c6f5d43fb6792a361e7f13e3fdc9','github_source':'5fa35dcd7684f694964de1048a3a293847fa1977','preserved':True}
for key in ['performance','controlled_comparisons','renderer_evidence','reused_components']:p.pop(key,None)
p['performance']={'new_benchmark':False,'scope':'No new uncapped or sustained performance claim. Readback timing is not a gameplay benchmark; existing separate-process profiling retained.'}
p['surveyor_art']='Original active model and replaceable vocals retained. Search/door-use/gait presentation improved; no rejected replacement promoted.'
p['verification_limit']='Intermittent native stability unresolved. New baseline failure after four screenshots is in UNLISTED.exe at null RCX+0x160, unlike earlier NVIDIA fault. Fixture recorder initialization corrected; no proven general crash fix. Human fear/story/art/controller approval pending.'
p['owner_guide']='OWNER_PLAYTEST_v0.10.9.md'
p['native_executable_sha256']='7ece55e6076aef4c3fbaf748d24ce69811fc71ecdc0bbee6a9b3a83b7e29c51c'
p['segmented_scope']='Final06 repeats recorder/input/save and three-resolution room/UI views. Unchanged05 threat/anomaly/arrival/vent/earned ending B reports retained; only three verified UI/caption string lines differ in production code. Extracted06 earned ending A recorded independently in private DELIVERY.json.'
p['system_modifications']='None'
p['public_playable']='unchanged v0.10.0'
(G/'DEVELOPMENT_CHECKPOINT.json').write_text(json.dumps(p,indent=2)+'\n',encoding='utf8')
