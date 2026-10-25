"""One isolated static study: native CC0 workwear proxy fit, no weight transfer.
Blender --background --python this_file -- NEW_PRIVATE_OUTPUT
No active asset, rig or animation is modified. Reject before rigging if weak.
"""
from pathlib import Path
import bpy,sys,math,json,hashlib
from mathutils import Vector
G=Path(__file__).resolve().parents[1]
P=G.parent/'Assets/Intake_20261021_MakeHuman'
O=Path(sys.argv[sys.argv.index('--')+1]);O.mkdir(parents=True,exist_ok=False)
bpy.ops.wm.read_factory_settings(use_empty=True)

def read_obj(path):
    verts=[];faces=[];uv=[];loops=[]
    for line in path.read_text().splitlines():
        q=line.split()
        if not q:continue
        if q[0]=='v':verts.append(Vector(tuple(map(float,q[1:4]))))
        elif q[0]=='vt':uv.append(tuple(map(float,q[1:3])))
        elif q[0]=='f':
            parts=[s.split('/') for s in q[1:]]
            faces.append([int(s[0])-1 for s in parts]);loops.extend(uv[int(s[1])-1] if len(s)>1 and s[1] else (0,0) for s in parts)
    return verts,faces,loops

base=read_obj(P/'base.obj')[0]
def proxy(path,count):
    rows=[];active=False
    for line in path.read_text().splitlines():
        q=line.split()
        if q[:1]==['verts']:active=True;continue
        if not active or not q:continue
        if len(rows)==count:break
        if len(q)>=9:
            ids=list(map(int,q[:3]));w=list(map(float,q[3:6]));off=Vector(tuple(map(float,q[6:9])))
            rows.append(sum((base[i]*a for i,a in zip(ids,w)),Vector())+off)
        elif len(q)==1 and q[0].isdigit():rows.append(base[int(q[0])].copy())
    assert len(rows)==count
    return rows

def material(name,color,texture=None):
    m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
    bs=m.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(*color,1);bs.inputs['Roughness'].default_value=.94
    if texture:
        t=m.node_tree.nodes.new('ShaderNodeTexImage');t.image=bpy.data.images.load(str(texture));t.image.pack()
        mix=m.node_tree.nodes.new('ShaderNodeMixRGB');mix.blend_type='MULTIPLY';mix.inputs[0].default_value=.8;mix.inputs[2].default_value=(*color,1)
        m.node_tree.links.new(t.outputs['Color'],mix.inputs[1]);m.node_tree.links.new(mix.outputs[0],bs.inputs['Base Color'])
    return m

canvas=material('Unclosed inspection / tobacco canvas',(.22,.19,.12),G/'assets/original/work_canvas.png')
skin=material('Unexposed human anatomy',(.23,.20,.16));gloves=material('Worn gloves and boots',(.045,.05,.04))
mesh_face=material('Recessed gauze opening',(.012,.016,.012))

def create(name,verts,faces,uv,mat):
    mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.update()
    ob=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(ob);ob.data.materials.append(mat)
    if uv:
        layer=mesh.uv_layers.new()
        for loop,value in zip(layer.data,uv):loop.uv=value
    for p in mesh.polygons:p.use_smooth=True
    return ob

def world(v):return (v.x*.1,-v.z*.1,(v.y+8.183)*.1)
v,f,uv=read_obj(P/'Selected/proxymeshes/male_generic/male_generic.obj')
body=create('Native human foundation - no transferred weights',[world(p) for p in v],f,uv,skin)
body.data.materials.append(gloves)
for face in body.data.polygons:
    center=sum((body.data.vertices[i].co for i in face.vertices),Vector())/len(face.vertices)
    if center.z<.18 or (abs(center.x)>.44 and center.z<1.15):face.material_index=1
path=P/'Selected/clothes/male_worksuit01/male_worksuit01.obj'
v,f,uv=read_obj(path)
v=proxy(path.with_suffix('.mhclo'),len(v))
garment=create('Continuous native workwear - original source topology',[world(p) for p in v],f,uv,canvas)
# The anatomical base and garment share their original MakeHuman coordinates.
# No coat extraction, remapping onto another body or automatic rig binding.
verts=[];faces=[]
for row,(z,rx,ry,shift) in enumerate([(1.47,.15,.145,-.005),(1.60,.14,.15,-.015),(1.77,.115,.13,-.025),(1.84,.085,.105,-.035)]):
    for i in range(16):
        t=2*math.pi*i/16
        verts.append((rx*math.cos(t),shift+ry*math.sin(t),z+.007*math.sin(t*3)))
for row in range(3):
    for i in range(16):
        a=row*16+i;b=row*16+(i+1)%16;faces.append((a,b,b+16,a+16))
faces.append(tuple(range(48,64)))
hood=create('Single sewn inspection hood - static construction only',verts,faces,[],canvas)
solid=hood.modifiers.new('Bound cloth thickness','SOLIDIFY');solid.thickness=.004
# The face remains within real anatomy; a narrow opaque gauze panel obscures it.
create('Recessed face screen',[(-.065,-.152,1.61),(.065,-.152,1.61),(.055,-.151,1.72),(-.055,-.151,1.72)],[(0,1,2,3)],[],mesh_face)
for ob in [body,garment,hood]:ob['status']='ISOLATED STATIC STUDY / not rigged / not promoted'
bpy.context.scene.render.engine='CYCLES';bpy.context.scene.cycles.samples=24
bpy.context.scene.render.resolution_x=900;bpy.context.scene.render.resolution_y=1100;bpy.context.scene.render.resolution_percentage=100
bpy.context.scene.world=bpy.data.worlds.new('Neutral studio world');bpy.context.scene.world.color=(.15,.15,.15)
for loc,energy,size in [((2,-3,4),450,4),((-3,1,3),300,3)]:
    data=bpy.data.lights.new('Neutral review light','AREA');data.energy=energy;data.shape='DISK';data.size=size
    ob=bpy.data.objects.new(data.name,data);bpy.context.collection.objects.link(ob);ob.location=loc;ob.rotation_euler=(Vector((0,0,.9))-ob.location).to_track_quat('-Z','Y').to_euler()
data=bpy.data.cameras.new('Review camera');camera=bpy.data.objects.new('Review camera',data);bpy.context.collection.objects.link(camera);bpy.context.scene.camera=camera;data.type='ORTHO';data.ortho_scale=2.12
for name,loc in [('front',(0,-4,1.05)),('side',(4,0,1.05)),('rear',(0,4,1.05))]:
    camera.location=loc;camera.rotation_euler=(Vector((0,0,.94))-camera.location).to_track_quat('-Z','Y').to_euler()
    bpy.context.scene.render.filepath=str(O/(name+'.png'));bpy.ops.render.render(write_still=True)
bpy.ops.wm.save_as_mainfile(filepath=str(O/'Surveyor_Unseen_Static.blend'))
bpy.ops.export_scene.gltf(filepath=str(O/'surveyor_unseen_static.glb'),export_format='GLB',export_animations=False,export_cameras=False,export_lights=False)
(O/'provenance.json').write_text(json.dumps({'status':'unapproved static candidate; no rig/animation promotion','sources':'Preserved MakeHuman CC0 intake and native original canvas','source_obj_sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'pipeline':'native proxy coordinates, no garment extraction or cross-rig weight transfer'},indent=2))
