import bpy, math, json
from pathlib import Path
from mathutils import Vector
root=Path(__file__).resolve().parents[2]
for o in list(bpy.data.objects):bpy.data.objects.remove(o,do_unlink=True)
bpy.ops.import_scene.gltf(filepath=str(root/'Game/assets/first_person/work_torch.glb'))
body=next(o for o in bpy.data.objects if o.name=='Torch body')
print('TORCH_BODY_WORLD_BOUNDS',[list(body.matrix_world@Vector(c)) for c in body.bound_box],flush=True)
# Open the deployed model's actual rear end, preserving all other authored parts.
import bmesh
bm=bmesh.new();bm.from_mesh(body.data)
faces=[f for f in bm.faces if all(abs((body.matrix_world@v.co).y+.067)<.0001 for v in f.verts)]
assert faces,'Rear end must be identified before modification'
bmesh.ops.delete(bm,geom=faces,context='FACES');bm.to_mesh(body.data);bm.free()
print('REMOVED_REAR_FACES',len(faces),flush=True)
# Godot (x,y,z) -> Blender (x,-z,y).
def xyz(p):return (p[0],-p[2],p[1])
mat=bpy.data.materials.new('Dark inner barrel');mat.diffuse_color=(.035,.039,.033,1);mat.use_nodes=True
bs=mat.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=mat.diffuse_color;bs.inputs['Roughness'].default_value=.83
verts=[];faces=[]
for z,r in [(.067,.029),(.067,.024),(-.045,.024)]:
 for i in range(24):
  a=i*math.tau/24;verts.append(xyz((r*math.cos(a),.012+r*math.sin(a),z)))
for i in range(24):
 j=(i+1)%24;faces.append((i,j,24+j,24+i));faces.append((24+i,24+j,48+j,48+i))
faces.append(tuple(range(48,72)))
mesh=bpy.data.meshes.new('Rear barrel bore');mesh.from_pydata(verts,[],faces);mesh.materials.append(mat)
o=bpy.data.objects.new('Open battery barrel',mesh);bpy.context.collection.objects.link(o)
out=root/'Checkpoints'/('torch_reload_authoring_'+__import__('datetime').datetime.now().strftime('%Y%m%d_%H%M%S'))
out.mkdir(parents=True,exist_ok=False)
bpy.ops.wm.save_as_mainfile(filepath=str(out/'Torch_Reload_OpenBarrel.blend'))
bpy.ops.export_scene.gltf(filepath=str(out/'work_torch_open.glb'),export_format='GLB',export_yup=True,export_apply=False)
