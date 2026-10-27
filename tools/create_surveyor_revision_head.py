import bpy,addon_utils,json,sys
from pathlib import Path
R=Path(r"C:\Users\Snkii\Documents\UNLISTED\Checkpoints\20261028_surveyor_revision")
OLD=R.parent/'20261028_surveyor_assets'
bpy.ops.wm.read_factory_settings(use_empty=True)
repo=bpy.context.preferences.extensions.repos.new(name='UNLISTED head authoring',module='surveyor_revision',custom_directory=str(OLD/'MPFB_compat'))
addon_utils.enable('bl_ext.surveyor_revision.mpfb',default_set=True,persistent=False)
from bl_ext.surveyor_revision.mpfb.services import HumanService,TargetService
macro=TargetService.get_default_macro_info_dict();macro.update(gender=.93,age=.88,muscle=.33,weight=.31,height=.53,proportions=.50)
macro['race']={'caucasian':.8,'asian':.2,'african':0}
h=HumanService.create_human(mask_helpers=True,feet_on_ground=True,scale=.1,macro_detail_dict=macro)
targets={'chin/chin-width-decr':.28,'chin/chin-height-incr':.16,'nose/nose-scale-vert-incr':.24,'nose/nose-septumangle-decr':.15,'asym/asym-cheek-1-r':.25,'asym/asym-eye-2-l':.20}
for name,weight in targets.items():
 p=OLD/'MPFB_compat/mpfb/data/targets'/(name+'.target.gz')
 if p.exists():TargetService.load_target(h,str(p),weight=weight)
eyes=HumanService.add_mhclo_asset(str(R/'Sources/SystemEyes/eyes/high-poly/high-poly.mhclo'),h,asset_type='Eyes',subdiv_levels=0,set_up_rigging=False,import_weights=False)
eyes.name='Anatomical_Eyes_Source'
TargetService.bake_targets(h)
bpy.context.view_layer.update()
info={'macro':macro,'targets':targets,'dimensions':list(h.dimensions),'vertices':len(h.data.vertices),'groups':[]}
for vg in h.vertex_groups:
 if any(x in vg.name for x in ['head','eye','neck','body','jaw']):
  vs=[v for v in h.data.vertices if any(w.group==vg.index and w.weight>.2 for w in v.groups)]
  if vs:info['groups'].append({'name':vg.name,'n':len(vs),'min':[min(v.co[i] for v in vs) for i in range(3)],'max':[max(v.co[i] for v in vs) for i in range(3)]})
(R/'HEAD_SOURCE.json').write_text(json.dumps(info,indent=2))
h.name='Surveyor_Aged_Anatomy_Source'
bpy.ops.wm.save_as_mainfile(filepath=str(R/'MPFB_Aged_Head_With_Eyes.blend'))
print(json.dumps(info))
