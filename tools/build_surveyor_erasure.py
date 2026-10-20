"""Isolated character-art study on the established CC0 anatomical rig.
Never replaces a runtime asset. Usage: blender -b --python ... -- NEW_FOLDER
"""
import bpy, bmesh, math, sys, json, struct, zipfile
from pathlib import Path
from mathutils import Matrix, Vector
G=Path(__file__).resolve().parents[1]
OUT=Path(sys.argv[sys.argv.index('--')+1]);OUT.mkdir(parents=True,exist_ok=False)
bpy.ops.wm.open_mainfile(filepath=str(G/'tools/Surveyor_Presence.blend'))
rig=next(o for o in bpy.data.objects if o.type=='ARMATURE')
for t in rig.animation_data.nla_tracks:t.mute=True
bpy.context.scene.frame_set(0)
for b in rig.pose.bones:b.matrix_basis=Matrix.Identity(4)
bpy.context.view_layer.update()
body=bpy.data.objects['Surveyor_WorkClothes']
for o in list(bpy.data.objects):
    if o.type=='MESH' and o!=body:bpy.data.objects.remove(o,do_unlink=True)

def gauss(x,z,cx,cz,rx,rz):return math.exp(-((x-cx)/rx)**2-((z-cz)/rz)**2)
def material(name,base,vertex=True):
    m=bpy.data.materials.new(name);m.use_nodes=True
    n=m.node_tree.nodes;bs=n.get('Principled BSDF')
    bs.inputs['Base Color'].default_value=(*base,1)
    bs.inputs['Roughness'].default_value=.93;bs.inputs['Specular IOR Level'].default_value=.17
    if vertex:
        vc=n.new('ShaderNodeVertexColor');vc.layer_name='Wear'
        m.node_tree.links.new(vc.outputs['Color'],bs.inputs['Base Color'])
    return m
old_skin=body.data.materials[0].copy()
skin=old_skin;skin.name='Ashen tissue - recessed healed orbits'
ns=skin.node_tree.nodes;lk=skin.node_tree.links;bs=ns.get('Principled BSDF')
for l in list(bs.inputs['Base Color'].links):lk.remove(l)
vc=ns.new('ShaderNodeVertexColor');vc.layer_name='Wear'
tex=next(n for n in ns if n.type=='TEX_IMAGE' and n.image and n.image.name=='skin.png')
mix=ns.new('ShaderNodeMixRGB');mix.blend_type='MULTIPLY';mix.inputs[0].default_value=1
lk.new(tex.outputs['Color'],mix.inputs[1]);lk.new(vc.outputs['Color'],mix.inputs[2]);lk.new(mix.outputs[0],bs.inputs['Base Color'])
bs.inputs['Roughness'].default_value=.97
cloth=material('Saturated umber service canvas',(.10,.095,.075))
leather=material('Cracked gloves and work boots',(.028,.027,.021))
hairmat=material('Clotted wet hair',(.025,.024,.020))
lining=material('Dark coat interior',(.025,.022,.017))
for a in list(body.data.color_attributes):body.data.color_attributes.remove(a)
original_materials=[p.material_index for p in body.data.polygons]
body.data.materials.clear()
for m in [skin,cloth,leather,leather]:body.data.materials.append(m)
for p,mi in zip(body.data.polygons,original_materials):p.material_index=mi
head=body.vertex_groups['Head'].index
# Sculpt the existing anatomical surface, retaining its continuous topology and
# skin weights. The unequal closed orbits are part of the face, not eye props.
for v in body.data.vertices:
    h=next((g.weight for g in v.groups if g.group==head),0)
    x,y,z=v.co;front=max(0,min(1,(-y-.012)/.055))
    if h>.45:
        jaw=gauss(x,z,0,1.612,.09,.042)
        cheek=gauss(abs(x),z,.052,1.662,.028,.029)*front
        orbit=(gauss(x,z,-.034,1.704,.025,.016)+gauss(x,z,.034,1.704,.025,.016))*front
        v.co.x*=1-.19*jaw-.10*cheek
        v.co.y+=.020*cheek+.019*orbit
        v.co.z-=.025*jaw+.012*gauss(x,z,-.024,1.631,.034,.024)*front
        v.co.y+=.008*gauss(x,z,0,1.615,.022,.013)*front
        v.co.y+=.020*gauss(x,z,0,1.662,.024,.024)*front
        v.co.x+=.006*gauss(x,z,0,1.658,.015,.026)*front
    if abs(x)>.19 and z>1.30 and h<.1:
        ease=min(1,max(0,(abs(x)-.19)/.08))
        v.co.y=.068+(v.co.y-.068)*(1-.22*ease)
        v.co.z=1.4555+(v.co.z-1.4555)*(1-.22*ease)
    # Remove the body-builder chest while retaining shoulder/arm joint centres.
    elif 1.04<z<1.47 and abs(x)<.20:
        v.co.x*=.91
        v.co.y=.018+(v.co.y-.018)*.87

body.data.update()

def paint(o,fn):
    a=o.data.color_attributes.new(name='Wear',type='FLOAT_COLOR',domain='CORNER')
    o.data.color_attributes.active_color=a
    for p in o.data.polygons:
        for li in p.loop_indices:
            co=o.data.vertices[o.data.loops[li].vertex_index].co
            a.data[li].color=(*fn(co,p.material_index),1)
def cloth_color(co,mi=0):
    x,y,z=co
    grain=math.sin(x*431+z*317)*math.sin(y*389-z*197)*.006
    fold=.014*math.sin(math.atan2(y-.02,x)*14+z*3)
    wet=.026*gauss(x,z,-.09,.78,.16,.37)+.02*gauss(x,z,.12,1.22,.09,.15)
    hem=.026*max(0,1-(z-.44)/.3)
    v=max(.035,.114+grain+fold-wet-hem)
    # Worn vertical placket and waist pocket openings are painted onto the
    # continuous cloth, so they cannot float or intersect the garment.
    front=max(0,min(1,(-y-.03)/.08))
    seam=math.exp(-((x-.035)/.003)**2)*front
    pocket=(gauss(x,z,-.115,.99,.065,.004)+gauss(x,z,.12,1.005,.06,.004))*front
    v*=1-.48*seam-.34*pocket
    return (v,v*.94,v*.79)
def body_color(co,mi):
    if mi==1:return cloth_color(co)
    if mi>1:
        v=.027+.009*math.sin(co.z*89+co.x*54)**2;return(v,v*.96,v*.82)
    x,y,z=co;front=max(0,min(1,(-y-.01)/.05))
    sockets=(gauss(x,z,-.032,1.702,.027,.019)+gauss(x,z,.033,1.706,.028,.020))*front
    lips=gauss(x,z,0,1.606,.040,.006)*front
    hollow=gauss(abs(x),z,.054,1.663,.021,.028)*front
    scar=gauss(x,z,-.024,1.682,.008,.053)*front
    mott=.024*math.sin(x*133+z*91)*math.sin(z*167-y*112)
    v=.38-.30*min(1,sockets)-.18*lips-.085*hollow-.06*scar+mott
    return(v*.99,v*.96,v*.85)
paint(body,body_color)

def weighted(name,vs,fs,mat,weights):
    d=bpy.data.meshes.new(name);d.from_pydata(vs,[],fs);d.materials.append(mat)
    o=bpy.data.objects.new(name,d);bpy.context.collection.objects.link(o)
    world=o.matrix_world.copy();o.parent=rig;o.matrix_world=world
    for i,items in enumerate(weights):
        for bone,w in items:
            vg=o.vertex_groups.get(bone) or o.vertex_groups.new(name=bone)
            vg.add([i],w,'REPLACE')
    arm=o.modifiers.new('Preserved 65-bone skeleton','ARMATURE');arm.object=rig
    for p in d.polygons:p.use_smooth=True
    return o

# Construct the whole coat from the continuous anatomical shirt surface, not
# separate torso and arm shells. Bisecting keeps interpolated deformation weights.
coat_source=body.copy();coat_source.data=body.data.copy();bpy.context.collection.objects.link(coat_source)
bm=bmesh.new();bm.from_mesh(coat_source.data)
bmesh.ops.delete(bm,geom=[f for f in bm.faces if f.material_index!=1],context='FACES')
bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=.00001,plane_co=(0,0,.99),plane_no=(0,0,1),clear_inner=True,clear_outer=False)
bm.normal_update();bm.to_mesh(coat_source.data);bm.free();coat_source.data.update()
vs=[];ws=[];fs=[]
for v in coat_source.data.vertices:
    co=v.co+v.normal*.008
    if abs(co.x)<.22 and .98<co.z<1.43:
        amount=min(1,max(0,(1.44-co.z)/.15))
        co.x*=1+.13*amount
        front=.02-.15*math.sqrt(max(.06,1-(co.x/.245)**2))
        back=.02+.145*math.sqrt(max(.06,1-(co.x/.245)**2))
        target=front if co.y<.02 else back
        co.y=co.y*(1-.86*amount)+target*.86*amount
        co.y+=.003*math.sin(co.x*97+co.z*8)*amount
    if abs(co.x)>.2:co+=v.normal*.0025*math.sin(co.x*73+co.y*41)
    vs.append(tuple(co));ws.append([(coat_source.vertex_groups[w.group].name,w.weight) for w in v.groups])
for p in coat_source.data.polygons:fs.append(tuple(p.vertices))
# Find the exact waist cut's boundary. Extruded rings share this boundary, so
# shoulder, cuff, waist and skirt cannot leave independent floating pieces.
edges={}
for face in fs:
    for a,b in zip(face,face[1:]+face[:1]):
        key=tuple(sorted((a,b)));edges.setdefault(key,[]).append((a,b))
waist=[pairs[0] for pairs in edges.values() if len(pairs)==1 and all(abs(coat_source.data.vertices[i].co.z-.99)<.0002 for i in pairs[0])]
assert len(waist)>8,('No continuous waist boundary',len(waist))
ids=sorted({i for edge in waist for i in edge});previous={i:i for i in ids}
for row,z in enumerate([.88,.75,.62,.49]):
    new={}
    for i in ids:
        x,y,_=vs[i];growth=1+(row+1)*.10
        angle=math.atan2(y-.02,x);wrinkle=.004*math.sin(angle*12+z*2)
        co=(x*growth+math.cos(angle)*wrinkle,.02+(y-.02)*growth+math.sin(angle)*wrinkle,z+.007*math.sin(angle*5))
        new[i]=len(vs);vs.append(co)
        amount=.15*max(0,1-abs(z-.68)/.3)
        ws.append([('pelvis',1-amount),('thigh_l' if x>0 else 'thigh_r',amount)])
    for a,b in waist:fs.append((previous[b],previous[a],new[a],new[b]))
    previous=new
coat=weighted('Continuous tailored service coat',vs,fs,cloth,ws)
# Real vertices along the placket let its narrow worn edge survive at PSX
# sampling distances, instead of a painted line falling between coarse vertices.
bm=bmesh.new();bm.from_mesh(coat.data)
for x in [.018,.027,.035,.043,.052]:
    bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=.00001,plane_co=(x,0,0),plane_no=(1,0,0),clear_inner=False,clear_outer=False)
bm.to_mesh(coat.data);bm.free()
paint(coat,cloth_color)
uv=coat.data.uv_layers.new(name='CanvasUV')
for p in coat.data.polygons:
    for li in p.loop_indices:
        co=coat.data.vertices[coat.data.loops[li].vertex_index].co
        uv.data[li].uv=(co.x*3+co.y*2,co.z*3)
solid=coat.modifiers.new('Bound garment edges','SOLIDIFY');solid.thickness=.003;solid.offset=-1
bpy.context.view_layer.objects.active=coat;bpy.ops.object.modifier_move_up(modifier=solid.name)
bpy.data.objects.remove(coat_source,do_unlink=True)
# The original canvas remains a synchronized in-game texture.
ns=cloth.node_tree.nodes;lk=cloth.node_tree.links;bs=ns.get('Principled BSDF')
tex=ns.new('ShaderNodeTexImage');tex.image=bpy.data.images.load(str(G/'assets/original/work_canvas.png'));tex.interpolation='Closest'
vc=next(n for n in ns if n.type=='VERTEX_COLOR')
mix=ns.new('ShaderNodeMixRGB');mix.blend_type='MULTIPLY';mix.inputs[0].default_value=1
lk.new(tex.outputs['Color'],mix.inputs[1]);lk.new(vc.outputs['Color'],mix.inputs[2]);lk.new(mix.outputs[0],bs.inputs['Base Color'])

# Recessed opaque lids close the anatomical orbital openings. They are a fitted
# facial surface below the brow, not luminous eyeballs or a floating blindfold.
for side in [-1,1]:
    vs=[];fs=[]
    for row in range(5):
        for i in range(13):
            u=i/12*2-1;v=row/4*2-1
            x=side*.033+u*.020
            z=1.701+v*.009*math.sqrt(max(0,1-u*u))-(.004 if side<0 else 0)
            y=-.058+.006*(1-u*u)*(1-v*v)
            vs.append((x,y,z))
    for j in range(4):
        for i in range(12):a=j*13+i;fs.append((a,a+1,a+14,a+13))
    o=weighted('Healed orbital tissue '+str(side),vs,fs,material('Healed orbital scar tissue',(.08,.07,.05)),[[('Head',1)]]*len(vs))
    paint(o,lambda co,mi:(.055,.045,.033))

# Use the licensed fitted hairstyle rather than another procedural skull cap.
# Its mesh is rebound to the existing Head; the imported duplicate rig is removed.
previous=set(bpy.data.objects)
source_dir=OUT/'LicensedHairSource';source_dir.mkdir()
with zipfile.ZipFile(G.parent/'Assets/Universal Base Characters[Standard].zip') as archive:
    for entry in archive.namelist():
        if 'Rigged to Head Bone/glTF (Godot -Unreal)/' in entry and (Path(entry).name in ['Hair_Long.gltf','Hair_Long.bin'] or entry.endswith('.png')):
            (source_dir/Path(entry).name).write_bytes(archive.read(entry))
source=source_dir/'Hair_Long.gltf'
bpy.ops.import_scene.gltf(filepath=str(source))
added=set(bpy.data.objects)-previous
hair=next(o for o in added if o.type=='MESH' and 'Hair_Long' in o.name)
world=hair.matrix_world.copy()
coords=[world@v.co for v in hair.data.vertices]
hair.modifiers.clear();hair.parent=rig;hair.matrix_world=Matrix.Identity(4)
for v,co in zip(hair.data.vertices,coords):
    co.x*=.90;co.z+=.040
    # Wet fringe falls over the left eye, while the other orbit stays readable.
    if co.y<-.047 and co.x<.025:
        co.z-=.055*max(0,min(1,(-co.y-.047)/.05))
    v.co=co
hair.vertex_groups.clear();vg=hair.vertex_groups.new(name='Head');vg.add(list(range(len(coords))),1,'REPLACE')
mod=hair.modifiers.new('Established head deformation','ARMATURE');mod.object=rig
hair.name='Licensed matted hair - fitted and rebound'
if '--licensed-hair-texture' in sys.argv:
    hairmat=hair.data.materials[0].copy();hairmat.name='Rain-plastered licensed hair'
hair.data.materials.clear();hair.data.materials.append(hairmat)
paint(hair,lambda co,mi:(.032+.006*math.sin(co.x*270+co.z*110),.029,.022))
for o in added:
    if o!=hair:bpy.data.objects.remove(o,do_unlink=True)
# Remove the old shirt surface under the new coat. Keeping both surfaces
# produced neckline intersections and made the tailored shoulder look padded.
bm=bmesh.new();bm.from_mesh(body.data)
covered=[f for f in bm.faces if f.material_index==1 and f.calc_center_median().z>.975]
bmesh.ops.delete(bm,geom=covered,context='FACES');bm.to_mesh(body.data);bm.free()
rig.scale.x*=.88
for t in rig.animation_data.nla_tracks:t.mute=False
bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'Surveyor_Erasure.blend'))
out=OUT/'surveyor_erasure.glb'
# Export vertex paint directly; append the two existing texture images below.
for m in [skin,cloth]:
    ns=m.node_tree.nodes;lk=m.node_tree.links;bs=ns.get('Principled BSDF')
    for l in list(bs.inputs['Base Color'].links):lk.remove(l)
    vc=next(n for n in ns if n.type=='VERTEX_COLOR' and n.layer_name=='Wear')
    lk.new(vc.outputs['Color'],bs.inputs['Base Color'])
bpy.ops.export_scene.gltf(filepath=str(out),export_format='GLB',export_animations=True,export_animation_mode='NLA_TRACKS',export_force_sampling=True,export_frame_range=False,export_all_vertex_colors=True)
raw=out.read_bytes();n=struct.unpack_from('<I',raw,12)[0];doc=json.loads(raw[20:20+n]);binary=bytearray(raw[28+n:])
image_paths={}
for key,img in [('skin',bpy.data.images['skin.png']),('cloth',tex.image)]:
    target=OUT/(key+'.png');img.save_render(str(target));image_paths[key]=target
texture_ids={}
for key,path in image_paths.items():
    binary.extend(b'\0'*((-len(binary))%4));offset=len(binary);png=path.read_bytes();binary.extend(png)
    view=len(doc.setdefault('bufferViews',[]));doc['bufferViews'].append({'buffer':0,'byteOffset':offset,'byteLength':len(png)})
    image=len(doc.setdefault('images',[]));doc['images'].append({'bufferView':view,'mimeType':'image/png'})
    texture_ids[key]=len(doc.setdefault('textures',[]));doc['textures'].append({'source':image})
binary.extend(b'\0'*((-len(binary))%4));doc['buffers'][0]['byteLength']=len(binary)
tail=struct.pack('<II',len(binary),0x004e4942)+binary
for m in doc['materials']:
    m['doubleSided']=True
    p=m.setdefault('pbrMetallicRoughness',{});p['roughnessFactor']=.93;p['metallicFactor']=0
    if 'tissue' in m['name']:p['baseColorTexture']={'index':texture_ids['skin']}
    elif 'canvas' in m['name']:p['baseColorTexture']={'index':texture_ids['cloth']}
    p['baseColorFactor']=[.72,.69,.60,1] if 'tissue' in m['name'] else [.42,.34,.20,1]
    if 'canvas' in m['name']:p['baseColorFactor']=[.75,.34,.09,1]
    if 'tissue' in m['name'] and 'normalTexture' in m:m['normalTexture']['scale']=.22
    if 'Healed orbital' in m['name']:p['baseColorFactor']=[.07,.055,.04,1]
    if 'Rain-plastered licensed' in m['name']:
        p['baseColorFactor']=[.18,.16,.12,1]
        if 'normalTexture' in m:m['normalTexture']['scale']=.3
data=json.dumps(doc,separators=(',',':')).encode();data+=b' '*((-len(data))%4)
out.write_bytes(struct.pack('<III',0x46546c67,2,20+len(data)+len(tail))+struct.pack('<II',len(data),0x4e4f534a)+data+tail)
assert len(doc['skins'][0]['joints'])==65 and len(doc['animations'])>=7
print('ERASURE_CANDIDATE',out)
