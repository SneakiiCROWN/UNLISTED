from pathlib import Path
import bpy,math,json
from mathutils import Vector
G=Path(__file__).resolve().parents[1]
A=G.parent/'Assets/Intake_20261023_GGBotCars/source/Car 01'
for o in list(bpy.data.objects):bpy.data.objects.remove(o,do_unlink=True)
bpy.ops.wm.obj_import(filepath=str(A/'Car.obj'))
for image in bpy.data.images:
 if image.filepath:image.filepath=str(A/'car_gray.png');image.reload()
mesh=[o for o in bpy.data.objects if o.type=='MESH'];corners=[o.matrix_world@Vector(c) for o in mesh for c in o.bound_box]
lo=Vector([min(v[i] for v in corners) for i in range(3)]);hi=Vector([max(v[i] for v in corners) for i in range(3)])
print('BOUNDS',list(lo),list(hi),flush=True)
# Keep the source proportions; bring station wagon to 4.45 m length.
size=hi-lo;scale=4.45/max(size.x,size.y)
for o in mesh:
 o.location= (o.location-Vector(((lo.x+hi.x)/2,(lo.y+hi.y)/2,lo.z)))*scale;o.scale*=scale
 for m in o.data.materials:
  if m and m.use_nodes:
   for node in m.node_tree.nodes:
    if node.type=='BSDF_PRINCIPLED':node.inputs['Roughness'].default_value=.43;node.inputs['Metallic'].default_value=.12
out=G/'assets/exterior/arrival';out.mkdir(exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=str(G/'tools/Arrival_StationWagon.blend'))
bpy.ops.export_scene.gltf(filepath=str(out/'eli_station_wagon.glb'),export_format='GLB',export_yup=True,export_apply=True)
print('EXPORTED',flush=True)
