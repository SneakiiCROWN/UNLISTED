"""Asset-first isolated inspection-coat study. Preserves original rig and clips.
Blender -b --python tools/build_surveyor_reborn.py -- NEW_OUTPUT_DIRECTORY
Uses only the preserved CC0 MakeHuman/Quaternius intake; no runtime promotion.
"""
import bpy,bmesh,math,json,sys,hashlib,zipfile,struct
from pathlib import Path
from mathutils import Vector,Matrix,Quaternion
from mathutils.kdtree import KDTree
G=Path(__file__).resolve().parents[1]
P=G.parent/'Assets/Intake_20261021_MakeHuman'
O=Path(sys.argv[sys.argv.index('--')+1]).resolve();O.mkdir(parents=True,exist_ok=False)
bpy.ops.wm.open_mainfile(filepath=str(G/'tools/Surveyor_Presence.blend'))
rig=next(o for o in bpy.data.objects if o.type=='ARMATURE')
for t in rig.animation_data.nla_tracks:t.mute=True
for b in rig.pose.bones:b.matrix_basis=Matrix.Identity(4)
bpy.context.scene.frame_set(0);bpy.context.view_layer.update()
donor=bpy.data.objects['Surveyor_WorkClothes']
base=[];joints={};group=''
for line in (P/'base.obj').read_text().splitlines():
    q=line.split()
    if not q:continue
    if q[0]=='v':base.append(Vector(tuple(map(float,q[1:4]))))
    elif q[0]=='g':group=q[1];joints.setdefault(group,set())
    elif q[0]=='f' and group.startswith('joint-'):joints[group].update(int(x.split('/')[0])-1 for x in q[1:])
def world(v):return Vector((v.x*.1,-v.z*.1,(v.y+8.183)*.1))
joint={k:world(sum((base[i] for i in ids),Vector())/len(ids)) for k,ids in joints.items() if ids}
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
    assert len(rows)==count,(path,len(rows),count)
    return rows
def segment_map(v,a,b,c,d):
    axis=b-a;t=max(0,min(1,(v-a).dot(axis)/axis.length_squared))
    residual=v-(a+axis*t)
    turn=axis.normalized().rotation_difference((d-c).normalized())
    scale=(d-c).length/axis.length
    return c+(d-c)*t+(turn@residual)*min(1.15,max(.8,scale)),(v-(a+axis*t)).length
def fit(raw):
    v=world(raw);sign=1 if v.x>=0 else -1;side='l' if sign>0 else 'r'
    # Piecewise rest-pose fitting, shared by anatomy and clothes. The existing
    # animation skeleton is never rescaled, renamed or regenerated.
    zlevels=[0,.0735,.4488,.8669,1.3429,1.4073,1.5158,1.668]
    targets=[0,.0865,.5424,.9712,1.4555,1.5205,1.5998,1.81]
    z=v.z
    for i in range(len(zlevels)-1):
        if z<=zlevels[i+1]:z=targets[i]+(z-zlevels[i])/(zlevels[i+1]-zlevels[i])*(targets[i+1]-targets[i]);break
    else:z=targets[-1]+(z-zlevels[-1])
    torso=Vector((v.x*.95,v.y*.82+.016,z))
    if abs(v.x)>.145 and v.z>.99:
        a=joint['joint-'+side+'-shoulder'];b=joint['joint-'+side+'-elbow'];c=joint['joint-'+side+'-hand']
        qa=rig.data.bones['upperarm_'+side].head_local;qb=rig.data.bones['lowerarm_'+side].head_local;qc=rig.data.bones['hand_'+side].head_local
        options=[segment_map(v,a,b,qa,qb),segment_map(v,b,c,qb,qc)]
        value,dist=min(options,key=lambda x:x[1])
        if (v-c).length<.19 and (v-a).length>(c-a).length*.75:
            # Preserve the closed anatomical fingers, rotating the hand with
            # its forearm rather than replacing it with a primitive glove.
            axis=c-b;turn=axis.normalized().rotation_difference((qc-qb).normalized())
            value=qc+(turn@(v-c))*.90
        blend=max(0,min(1,(abs(v.x)-.145)/.07))
        return torso.lerp(value,blend)
    if v.z<.90:
        a=joint['joint-'+side+'-upper-leg'];b=joint['joint-'+side+'-knee'];c=joint['joint-'+side+'-ankle']
        qa=rig.data.bones['thigh_'+side].head_local;qb=rig.data.bones['calf_'+side].head_local;qc=rig.data.bones['foot_'+side].head_local
        value,dist=min([segment_map(v,a,b,qa,qb),segment_map(v,b,c,qb,qc)],key=lambda x:x[1])
        if v.z<.12:value=qc+Vector(((v.x-c.x)*.9,(v.y-c.y)*.95,v.z-c.z))
        return torso.lerp(value,max(0,min(1,(.90-v.z)/.10)))
    return torso
def obj_data(path,proxy_path,name,authored_head=False):
    vs=[];uv=[];faces=[];face_uv=[]
    for line in path.read_text().splitlines():
        q=line.split()
        if not q:continue
        if q[0]=='v':vs.append(tuple(map(float,q[1:4])))
        elif q[0]=='vt':uv.append(tuple(map(float,q[1:3])))
        elif q[0]=='f':
            faces.append([int(x.split('/')[0])-1 for x in q[1:]])
            face_uv.append([int(x.split('/')[1])-1 if len(x.split('/'))>1 and x.split('/')[1] else 0 for x in q[1:]])
    coords=proxy(proxy_path,len(vs))
    if authored_head:
        # Keep the provided male proxy's authored head shape rather than its
        # neutral-base reconstruction. Compress only the source height interval
        # to the established rig's neck/crown landmarks; do not sculpt a face.
        for i,raw in enumerate(vs):
            if raw[1]>5.89:
                source=Vector(raw);source.y=5.89+(source.y-5.89)*(8.4967-5.89)/(9.3003-5.89)
                coords[i]=source
    mesh=bpy.data.meshes.new(name);mesh.from_pydata([fit(v) for v in coords],[],faces);mesh.update()
    layer=mesh.uv_layers.new(name='UVMap')
    for p,indices in zip(mesh.polygons,face_uv):
        for loop,ui in zip(p.loop_indices,indices):layer.data[loop].uv=uv[ui]
    ob=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(ob)
    return ob
kd=KDTree(len(donor.data.vertices))
for v in donor.data.vertices:kd.insert(donor.matrix_world@v.co,v.index)
kd.balance();names={g.index:g.name for g in donor.vertex_groups}
donor_weights={v.index:[(names[w.group],float(w.weight)) for w in v.groups] for v in donor.data.vertices}
def skin(ob):
    ob.parent=rig
    for bone in rig.data.bones:ob.vertex_groups.new(name=bone.name)
    for vi,co in [(v.index,v.co.copy()) for v in ob.data.vertices]:
        weights={}
        for _,index,dist in kd.find_n(co,4):
            for name,w in donor_weights[index]:
                if name in ob.vertex_groups:weights[name]=weights.get(name,0)+w/max(.002,dist)**4
        selected=sorted(weights.items(),key=lambda x:x[1],reverse=True)[:4];total=sum(w for _,w in selected)
        for name,w in selected:ob.vertex_groups[name].add([vi],w/total,'REPLACE')
    mod=ob.modifiers.new('Existing 65-bone deformation','ARMATURE');mod.object=rig
def mat(name,color,texture=None):
    m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
    bs=m.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(*color,1);bs.inputs['Roughness'].default_value=.91;bs.inputs['Specular IOR Level'].default_value=.18
    if texture:
        tx=m.node_tree.nodes.new('ShaderNodeTexImage');tx.image=bpy.data.images.load(str(texture));tx.interpolation='Closest'
        if max(tx.image.size)>1024:tx.image.scale(1024,1024)
        m.node_tree.links.new(tx.outputs['Color'],bs.inputs['Base Color'])
    return m
skin_files=list((P/'Selected/skins/onlytheghosts_old_eurasian_male').glob('*diffuse*'))
if not skin_files:skin_files=[p for p in (P/'Selected/skins/onlytheghosts_old_eurasian_male').glob('*.png') if 'normal' not in p.name]
skinmat=mat('CC0 aged human skin',(.57,.53,.46),skin_files[0]);glove=mat('Reborn worn umber leather',(.058,.048,.032));sole=mat('Reborn boot rubber',(.026,.029,.025))
canvas=mat('Reborn ochre oilskin',(.24,.19,.10),G/'assets/original/work_canvas.png')
body=obj_data(P/'Selected/proxymeshes/male_generic/male_generic.obj',P/'Selected/proxymeshes/male_generic/male_generic.proxy','Reborn fitted human anatomy')
skin(body);body.data.materials.clear()
for m in [skinmat,glove,sole]:body.data.materials.append(m)
for f in body.data.polygons:
    z=sum(body.data.vertices[i].co.z for i in f.vertices)/len(f.vertices);x=abs(sum(body.data.vertices[i].co.x for i in f.vertices)/len(f.vertices))
    f.material_index=2 if z<.18 else 1 if x>.70 and z>1.25 else 0
# The licensed workwear supplies fitted trouser construction and actual UVs.
work=obj_data(P/'Selected/clothes/male_worksuit01/male_worksuit01.obj',P/'Selected/clothes/male_worksuit01/male_worksuit01.mhclo','Reborn licensed work trousers')
bm=bmesh.new();bm.from_mesh(work.data)
bmesh.ops.delete(bm,geom=[f for f in bm.faces if f.calc_center_median().z>1.01 or abs(f.calc_center_median().x)>.27],context='FACES');bm.to_mesh(work.data);bm.free()
work.data.materials.clear();work.data.materials.append(mat('Reborn weathered twill trousers',(.10,.115,.105)));skin(work)
# Derive one connected coat surface from the fitted anatomical torso/sleeves,
# including a real continuous waist boundary, skirt and asymmetric storm collar.
coat=body.copy();coat.data=body.data.copy();bpy.context.collection.objects.link(coat);coat.name='Reborn continuous inspection coat'
coat.data.materials.clear();coat.data.materials.append(canvas)
bm=bmesh.new();bm.from_mesh(coat.data)
bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.00005)
bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=.00001,plane_co=(0,0,1.03),plane_no=(0,0,1),clear_inner=True)
remove=[f for f in bm.faces if f.calc_center_median().z>1.527 or abs(f.calc_center_median().x)>.695]
bmesh.ops.delete(bm,geom=remove,context='FACES')
for v in bm.verts:
    v.co.x*=1.055;v.co.y=(v.co.y-.02)*1.12+.02
    v.co+=v.normal*.007
# Exact wrist cuts remove the last anatomical palm fragments; a face-centre
# cutoff can retain a long triangle crossing the finger influence boundary.
bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=.00001,plane_co=(.69,0,0),plane_no=(1,0,0),clear_outer=True)
bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=.00001,plane_co=(-.69,0,0),plane_no=(-1,0,0),clear_outer=True)
waist=[e for e in bm.edges if e.is_boundary and all(abs(v.co.z-1.03)<.015 for v in e.verts)]
for step in [.15,.16,.14]:
    ex=bmesh.ops.extrude_edge_only(bm,edges=waist);verts=[v for v in ex['geom'] if isinstance(v,bmesh.types.BMVert)]
    for v in verts:
        v.co.z-=step;v.co.x*=1.08;v.co.y=(v.co.y-.02)*1.08+.02
        # The overlapping storm front hangs lower on the fastened side.
        if v.co.y<-.04:v.co.z-=.008*(1 if v.co.x<0 else .2)
    waist=[e for e in ex['geom'] if isinstance(e,bmesh.types.BMEdge) and e.is_boundary and all(v in verts for v in e.verts)]
# The neck edge rises into the garment, not a separate rigid mask/accessory.
neck=[e for e in bm.edges if e.is_boundary and min(v.co.z for v in e.verts)>1.48 and all(abs(v.co.x)<.15 for v in e.verts)]
ex=bmesh.ops.extrude_edge_only(bm,edges=neck)
for v in [v for v in ex['geom'] if isinstance(v,bmesh.types.BMVert)]:
    v.co.z+=.075+(.020 if v.co.x<0 else 0);v.co.x*=1.65;v.co.y=(v.co.y-.02)*1.45+.02
for f in bm.faces:f.material_index=0
bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(coat.data);bm.free()
# Rebind added skirt/collar vertices with the same nearest-surface method.
coat.modifiers.clear();coat.vertex_groups.clear();skin(coat)
# Explicit garment weights replace ambiguous nearest-finger/leg matches at
# the free skirt and neck edge. Back/front vents allow the legs to separate.
for v in coat.data.vertices:
    if v.co.z<1.04:
        for group in coat.vertex_groups:group.remove([v.index])
        w=max(0,min(.45,(1.04-v.co.z)*.9));side='l' if v.co.x>0 else 'r'
        coat.vertex_groups['pelvis'].add([v.index],1-w,'REPLACE');coat.vertex_groups['thigh_'+side].add([v.index],w,'REPLACE')
    elif v.co.z>1.52 and abs(v.co.x)<.17:
        for group in coat.vertex_groups:group.remove([v.index])
        coat.vertex_groups['spine_03'].add([v.index],.75,'REPLACE');coat.vertex_groups['neck_01'].add([v.index],.25,'REPLACE')
    elif abs(v.co.x)>.58:
        for group in coat.vertex_groups:group.remove([v.index])
        coat.vertex_groups['lowerarm_'+('l' if v.co.x>0 else 'r')].add([v.index],1,'REPLACE')
bpy.context.view_layer.objects.active=coat;coat.select_set(True)
bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.uv.smart_project(island_margin=.025);bpy.ops.object.mode_set(mode='OBJECT');coat.select_set(False)
solid=coat.modifiers.new('Bound cloth thickness','SOLIDIFY');solid.thickness=.004;solid.offset=-.3
# Hide only anatomy actually covered by clothes; no skin protruding through fabric.
bm=bmesh.new();bm.from_mesh(body.data)
bmesh.ops.delete(bm,geom=[f for f in bm.faces if f.calc_center_median().z<1.51 or abs(f.calc_center_median().x)>.65],context='FACES');bm.to_mesh(body.data);bm.free()
for v in body.data.vertices:
    if v.co.z>1.57:
        for group in body.vertex_groups:group.remove([v.index])
        body.vertex_groups['Head'].add([v.index],1,'REPLACE')
# Preserve the established rig's exact anatomical finger/foot topology and
# native weights. Nearest-surface transfer across a different finger spread
# is inappropriate and produced visible spikes in the retained first capture.
extremities=donor.copy();extremities.data=donor.data.copy();bpy.context.collection.objects.link(extremities);extremities.name='Reborn rig-native gloves and practical boots'
bm=bmesh.new();bm.from_mesh(extremities.data)
bmesh.ops.delete(bm,geom=[f for f in bm.faces if not (f.calc_center_median().z<.19 or abs(f.calc_center_median().x)>.69)],context='FACES')
bm.to_mesh(extremities.data);bm.free();extremities.data.materials.clear();extremities.data.materials.append(glove)
for f in extremities.data.polygons:f.material_index=0
# A close-fitting storm cap replaces floating hair or a full enclosing hood.
# Connected crown and brim retain a recognisable side profile and shadow one eye.
head=[v.co for v in body.data.vertices if v.co.z>1.73 and abs(v.co.x)<.20]
cx=(max(v.x for v in head)+min(v.x for v in head))/2
cy=(max(v.y for v in head)+min(v.y for v in head))/2
rx=max(abs(v.x-cx) for v in head)+.009;ry=max(abs(v.y-cy) for v in head)+.010
vs=[];fs=[];N=24
for z,rx_,ry_,cy_ in [(1.735,rx,ry,cy),(1.797,rx*.95,ry*.95,cy+.004),(1.818,rx*.68,ry*.70,cy+.006)]:
    for i in range(N):
        a=2*math.pi*i/N;vs.append((cx+rx_*math.cos(a),cy_+ry_*math.sin(a),z+.004*math.cos(a)))
for j in range(2):
    for i in range(N):a=j*N+i;b=j*N+(i+1)%N;fs.append((a,b,b+N,a+N))
fs.append(tuple(range(2*N,3*N)))
for i in range(N):
    a=2*math.pi*i/N
    if math.sin(a)>-.12:continue
    ni=(i+1)%N;edge=len(vs);vs.extend([(vs[i][0]*1.35,vs[i][1]-.055,vs[i][2]-.014),(vs[ni][0]*1.35,vs[ni][1]-.055,vs[ni][2]-.014)]);fs.append((i,ni,edge+1,edge))
me=bpy.data.meshes.new('Storm cap sewn crown and peak');me.from_pydata(vs,[],fs);me.materials.append(mat('Reborn storm cap',(.075,.066,.041)))
cap=bpy.data.objects.new('Reborn fitted storm cap',me);bpy.context.collection.objects.link(cap);cap.parent=rig
vg=cap.vertex_groups.new(name='Head');vg.add(list(range(len(vs))),1,'REPLACE');mo=cap.modifiers.new('Head attachment','ARMATURE');mo.object=rig
mo=cap.modifiers.new('Bound cap edge','SOLIDIFY');mo.thickness=.003
# The anatomical proxy has open eye sockets. Use its own matching licensed
# low-poly eyeballs, fitted through the same barycentric/rest-pose transform.
eye_files=['eyes/low-poly/low-poly.obj','eyes/low-poly/low-poly.mhclo','eyes/materials/brown_eye.png']
with zipfile.ZipFile(P/'makehuman_system_assets_cc0.zip') as z:
    for name in eye_files:
        target=O/'Intake'/name;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(z.read(name))
eyes=obj_data(O/'Intake'/eye_files[0],O/'Intake'/eye_files[1],'Reborn fitted anatomical eyes')
eyes.data.materials.clear();eyes.data.materials.append(mat('Reborn nonluminous brown eyes',(.32,.30,.25),O/'Intake'/eye_files[2]));skin(eyes)
# Remove every previous head/wardrobe mesh, including the weight donor.
keep={body,work,coat,cap,eyes,extremities}
for ob in list(bpy.data.objects):
    if ob.type=='MESH' and ob not in keep:bpy.data.objects.remove(ob,do_unlink=True)
for ob in keep:
    for f in ob.data.polygons:f.use_smooth=True
# Materialise topology-changing thickness before the skin modifier. Exporting
# a post-armature Solidify stack can leave generated vertices without a stable
# rest-skin correspondence. Preserve the editable topology in this source.
for ob in [coat,cap]:
    bpy.ops.object.select_all(action='DESELECT');ob.select_set(True);bpy.context.view_layer.objects.active=ob
    thickness_names=[modifier.name for modifier in ob.modifiers if modifier.type=='SOLIDIFY']
    for name in thickness_names:
        # Cache names, not RNA modifier handles across stack mutations.
        for _ in range(ob.modifiers.find(name)):bpy.ops.object.modifier_move_up(modifier=name)
        bpy.ops.object.modifier_apply(modifier=name)
for t in rig.animation_data.nla_tracks:t.mute=False
for image in bpy.data.images:
    if image.source=='FILE':image.pack()
provenance={'design':'Unclosed Inspector: fitted aged human anatomy, continuous oilskin inspection coat, high asymmetric storm collar, fitted peaked cap, work trousers and anatomical leather gloves. Identity remains unknown.',
 'status':'ISOLATED WORKING STUDY - NOT APPROVED OR ACTIVE','rig_bones':len(rig.data.bones),'clips':len(rig.animation_data.nla_tracks),
 'sources':['CC0 MakeHuman male_generic proxy and male_worksuit01','CC0 onlytheghosts old Eurasian male skin','Existing CC0 Quaternius rig and seven retargeted UAL clips','Original coat, cap construction and existing canvas'],
 'method':'MakeHuman proxy barycentric fitting against preserved base; shared rest-pose mapping; four-influence skin transfer to unchanged rig; connected waist/collar extrusion; no rejected character mesh input retained',
 'source_hashes':{str(p.relative_to(P)):hashlib.sha256(p.read_bytes()).hexdigest() for p in [P/'base.obj',P/'Selected/proxymeshes/male_generic/male_generic.obj',P/'Selected/clothes/male_worksuit01/male_worksuit01.obj',skin_files[0]]}}
bpy.data.texts.new('REBORN_PROVENANCE.json').write(json.dumps(provenance,indent=2))
bpy.ops.wm.save_as_mainfile(filepath=str(O/'Surveyor_Reborn.blend'))
bpy.ops.export_scene.gltf(filepath=str(O/'surveyor_reborn.glb'),export_format='GLB',export_animations=True,export_animation_mode='NLA_TRACKS',export_force_sampling=True,export_frame_range=False)
raw=(O/'surveyor_reborn.glb').read_bytes();length=struct.unpack_from('<I',raw,12)[0];doc=json.loads(raw[20:20+length]);tail=raw[20+length:]
for m in doc.get('materials',[]):
    factors={'Reborn ochre oilskin':[.43,.34,.19,1],'CC0 aged human skin':[.68,.65,.58,1],'Reborn nonluminous brown eyes':[.32,.30,.25,1]}
    if m['name'] in factors:m['pbrMetallicRoughness']['baseColorFactor']=factors[m['name']]
    if m['name']=='Reborn ochre oilskin':m['doubleSided']=True
    m.pop('emissiveTexture',None);m['emissiveFactor']=[0,0,0]
data=json.dumps(doc,separators=(',',':')).encode();data+=b' '*((-len(data))%4)
(O/'surveyor_reborn.glb').write_bytes(struct.pack('<III',0x46546c67,2,20+len(data)+len(tail))+struct.pack('<II',len(data),0x4e4f534a)+data+tail)
(O/'provenance.json').write_text(json.dumps(provenance,indent=2))
print('REBORN_COMPLETE',O)
