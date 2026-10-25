"""Isolated canonical-body/workwear construction gate. No active-model changes.
Uses the same native MakeHuman base for all source proxies, rather than fitting
clothes onto a different generic-body OBJ. No rigging or weight transfer.
"""
import bpy,ast,sys,math,json,zipfile
from pathlib import Path
from mathutils import Vector
G=Path(__file__).resolve().parents[1];P=G.parent/'Assets/Intake_20261021_MakeHuman'
O=Path(sys.argv[sys.argv.index('--')+1]);O.mkdir(parents=True,exist_ok=False)
bpy.ops.wm.read_factory_settings(use_empty=True)
# Reuse only the pure source readers/material helpers, not the rejected builder.
tree=ast.parse((G/'tools/build_unseen_static.py').read_text())
helpers=[n for n in tree.body if isinstance(n,ast.FunctionDef) and n.name in ['read_obj','proxy','material','create','world']]
exec(compile(ast.Module(body=helpers,type_ignores=[]),'<source helpers>','exec'))
base,faces,uv=read_obj(P/'base.obj')
skin=material('Pale exposed face',(.32,.27,.22));dark=material('Charcoal undershirt and gloves',(.036,.043,.037))
cloth=material('Oxblood maintenance coverall',(.18,.095,.064),G/'assets/original/work_canvas.png')
hairmat=material('Damp close-cropped hair',(.018,.016,.011));boot=material('Worn leather work shoes',(.035,.03,.022))
# Only actual body faces, never helper cages or joint markers.
groups=[];group=''
for line in (P/'base.obj').read_text().splitlines():
 q=line.split()
 if q and q[0]=='g':group=q[1]
 elif q and q[0]=='f':groups.append(group)
keep=[];kept_uv=[];offset=0
for face,group in zip(faces,groups):
 if group=='body':keep.append(face);kept_uv.extend(uv[offset:offset+len(face)])
 offset+=len(face)
body=create('Canonical body - matches native clothing references',[world(v) for v in base],keep,kept_uv,dark)
body.data.materials.append(skin)
for face in body.data.polygons:
 z=sum(body.data.vertices[i].co.z for i in face.vertices)/len(face.vertices)
 if z>1.43:face.material_index=1

def garment(path,name,mat):
 v,f,u=read_obj(path);v=proxy(path.with_suffix('.mhclo'),len(v))
 return create(name,[world(p) for p in v],f,u,mat)
garment(P/'Selected/clothes/male_worksuit01/male_worksuit01.obj','Native continuous workwear',cloth)
with zipfile.ZipFile(P/'makehuman_system_assets_cc0.zip') as z:
 for prefix in ['hair/short01/','clothes/shoes02/','eyes/low-poly/']:
  for n in z.namelist():
   if n.startswith(prefix) and n.endswith(('.obj','.mhclo')):
    target=O/'Sources'/n;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(z.read(n))
garment(O/'Sources/hair/short01/short01.obj','Native fitted short hair',hairmat)
garment(O/'Sources/clothes/shoes02/shoes02.obj','Native complete footwear',boot)
# Real supplied eye geometry. No glowing dots, masks, hoods or attached plates.
eyes=garment(O/'Sources/eyes/low-poly/low-poly.obj','Recessed eyes',material('Unlit dark eyes',(.035,.032,.025)))
bpy.context.scene.world=bpy.data.worlds.new('Neutral review');bpy.context.scene.world.color=(.12,.12,.12)
bpy.context.scene.render.engine='CYCLES';bpy.context.scene.cycles.samples=24
bpy.context.scene.render.resolution_x=900;bpy.context.scene.render.resolution_y=1100;bpy.context.scene.render.resolution_percentage=100
for loc,energy in [((2,-3,4),480),((-3,1,3),330)]:
 d=bpy.data.lights.new('Review light','AREA');d.energy=energy;d.shape='DISK';d.size=3
 o=bpy.data.objects.new(d.name,d);bpy.context.collection.objects.link(o);o.location=loc;o.rotation_euler=(Vector((0,0,.9))-o.location).to_track_quat('-Z','Y').to_euler()
d=bpy.data.cameras.new('Review');camera=bpy.data.objects.new('Review',d);bpy.context.collection.objects.link(camera);bpy.context.scene.camera=camera;d.type='ORTHO';d.ortho_scale=2.05
for name,loc,target,scale in [('front',(0,-4,1.0),(0,0,.92),2.05),('side',(4,0,1.0),(0,0,.92),2.05),('rear',(0,4,1.0),(0,0,.92),2.05),('face',(0,-3,1.66),(0,0,1.65),.48)]:
 camera.location=loc;camera.rotation_euler=(Vector(target)-camera.location).to_track_quat('-Z','Y').to_euler();d.ortho_scale=scale
 bpy.context.scene.render.filepath=str(O/(name+'.png'));bpy.ops.render.render(write_still=True)
bpy.ops.wm.save_as_mainfile(filepath=str(O/'Matched_Worker_Static.blend'))
bpy.ops.export_scene.gltf(filepath=str(O/'matched_worker.glb'),export_format='GLB',export_animations=False,export_lights=False,export_cameras=False)
(O/'STATUS.json').write_text(json.dumps({'status':'ISOLATED STATIC / NOT APPROVED OR RIGGED','pipeline':'Canonical base topology and all garments/hair/eyes from the same CC0 reference; no cross-body extraction or weight transfer.'},indent=2))
