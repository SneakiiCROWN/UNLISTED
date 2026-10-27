"""Custom field-coat construction + deliberately authored MPFB aged head.

Private art gate, not a replacement for the ordinary game actor. Run in Blender.
Original sources, the previous rejected candidate and active model stay intact.
"""
import bpy,bmesh,math,json
from pathlib import Path
from mathutils import Vector,Matrix
G=Path(__file__).resolve().parents[1]
R=G.parent/'Checkpoints/20261028_surveyor_revision'
O=R/'Construction04';O.mkdir(exist_ok=False) # Select a new output folder for any further revision.
bpy.ops.wm.read_factory_settings(use_empty=True)

def imported(path):
 before=set(bpy.data.objects);bpy.ops.import_scene.gltf(filepath=str(path));return set(bpy.data.objects)-before
old=imported(G/'assets/original/surveyor_presence.glb')
rig=next(o for o in old if o.type=='ARMATURE');rig.name='SurveyorRig'
for obj in list(old):
 if obj.type=='MESH':bpy.data.objects.remove(obj,do_unlink=True)
for tr in rig.animation_data.nla_tracks:tr.mute=True
rig.animation_data.action=None
for b in rig.pose.bones:b.matrix_basis=Matrix.Identity(4)
keep={rig}

def material(name,color,texture=None,roughness=.85,normal=None):
 m=bpy.data.materials.new(name);m.use_nodes=True;m.diffuse_color=(*color,1)
 bs=m.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(*color,1)
 bs.inputs['Roughness'].default_value=roughness;bs.inputs['Metallic'].default_value=0
 if texture:
  t=m.node_tree.nodes.new('ShaderNodeTexImage');t.image=bpy.data.images.load(str(texture),check_existing=True)
  m.node_tree.links.new(t.outputs['Color'],bs.inputs['Base Color'])
 if normal:
  t=m.node_tree.nodes.new('ShaderNodeTexImage');t.image=bpy.data.images.load(str(normal),check_existing=True);t.image.colorspace_settings.name='Non-Color'
  n=m.node_tree.nodes.new('ShaderNodeNormalMap');n.inputs['Strength'].default_value=.35;m.node_tree.links.new(t.outputs['Color'],n.inputs['Color']);m.node_tree.links.new(n.outputs['Normal'],bs.inputs['Normal'])
 return m
canvas=material('Weathered umber waxed canvas',(.23,.19,.13),R/'Textures/waxed_canvas.png',.77,R/'Textures/fabric_normal.png')
twill=material('Worn charcoal twill',(.13,.12,.10),R/'Textures/trouser_twill.png')
leather=material('Creased dark leather',(.10,.085,.065),R/'Textures/boot_leather.png',.72)
lining=material('Faded storm-collar facing',(.28,.24,.17),R/'Textures/collar_lining.png')
seam=material('Waxed binding and recessed seams',(.065,.052,.035))
sole=material('Worn rubber soles',(.027,.025,.021))
metal=material('Oxidised blackened brass',(.11,.095,.06),roughness=.76)
skin=material('Aged skin / retained photographic pores',(.46,.36,.28),R/'Textures/aged_skin.png',.69,R/'Textures/skin_normal.png')
bs=skin.node_tree.nodes.get('Principled BSDF');t=skin.node_tree.nodes.new('ShaderNodeTexImage');t.image=bpy.data.images.load(str(R/'Textures/skin_roughness.png'));t.image.colorspace_settings.name='Non-Color';skin.node_tree.links.new(t.outputs[0],bs.inputs['Roughness'])
eye_mat=material('Natural grey brown eyes / no emission',(.37,.34,.27),R/'Sources/SystemEyes/eyes/materials/grey_eye.png',.27)
eye_bs=eye_mat.node_tree.nodes.get('Principled BSDF')
eye_texture=next(n for n in eye_mat.node_tree.nodes if n.type=='TEX_IMAGE')
eye_mat.node_tree.links.new(eye_texture.outputs['Alpha'],eye_bs.inputs['Alpha'])
eye_mat.surface_render_method='DITHERED'

def bind(obj,weight):
 obj.parent=rig;obj.matrix_world=Matrix.Identity(4)
 for mod in list(obj.modifiers):
  if mod.type=='ARMATURE':obj.modifiers.remove(mod)
 for v in obj.data.vertices:
  w=weight(v.co);total=sum(w.values())
  for name,value in w.items():
   vg=obj.vertex_groups.get(name) or obj.vertex_groups.new(name=name)
   if value>.0001:vg.add([v.index],value/total,'REPLACE')
 mod=obj.modifiers.new('Original Surveyor rig / authored anatomical weights','ARMATURE');mod.object=rig;keep.add(obj)

def torso_weight(p):
 # No nearest-surface transfer from the failed coat. Each panel's anatomy is known.
 z=p.z
 if abs(p.x)>.18 and z>1.24:
  side='l' if p.x>0 else 'r';x=abs(p.x)
  if x<.39:
   t=max(0,min(1,(x-.18)/.16));t=t*t*(3-2*t)
   q=max(0,min(1,(z-1.24)/.14));q=q*q*(3-2*q);t*=q
   return {'spine_03':1-t,'upperarm_'+side:t}
  if x<.51:
   t=(x-.39)/.12;return {'upperarm_'+side:1-t,'lowerarm_'+side:t}
  t=max(0,min(.45,(x-.65)/.12));return {'lowerarm_'+side:1-t,'hand_'+side:t}
 if z<1.02:
  t=max(0,min(.62,(1.02-z)*2.3));return {'pelvis':1-t,'thigh_l' if p.x>0 else 'thigh_r':t}
 levels=[(1.02,'pelvis'),(1.11,'spine_01'),(1.23,'spine_02'),(1.37,'spine_03')]
 for (low,b1),(high,b2) in zip(levels,levels[1:]):
  if low<=z<high:
   t=(z-low)/(high-low);return {b1:1-t,b2:t}
 return {'spine_03':1}

def mesh(name,verts,faces,mat,weights,uv=None,thickness=0,subdiv=0):
 data=bpy.data.meshes.new(name);data.from_pydata(verts,[],faces);data.materials.append(mat);data.update()
 obj=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(obj)
 bm=bmesh.new();bm.from_mesh(data);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(data);bm.free()
 if uv:
  layer=data.uv_layers.new(name='TailoredUV')
  for loop in data.loops:layer.data[loop.index].uv=uv[loop.vertex_index]
 if subdiv:
  mod=obj.modifiers.new('Tailored curved panel transitions','SUBSURF');mod.levels=subdiv
  bpy.context.view_layer.objects.active=obj;bpy.ops.object.modifier_apply(modifier=mod.name)
 if thickness:
  mod=obj.modifiers.new('Bound seam thickness','SOLIDIFY');mod.thickness=thickness;mod.offset=-.4
  bpy.context.view_layer.objects.active=obj;bpy.ops.object.modifier_apply(modifier=mod.name)
 for poly in data.polygons:poly.use_smooth=True
 bind(obj,weights);return obj

def ribbon(name,path,width,mat,weight):
 # Conforming strip cut along the actual cloth surface, not a floating cube.
 verts=[]
 for i,p in enumerate(path):
  p=Vector(p);tangent=Vector(path[min(i+1,len(path)-1)])-Vector(path[max(0,i-1)])
  outward=Vector((p.x,p.y-.025,0)).normalized()
  side=tangent.cross(outward).normalized()*width/2
  for point in [p-side,p+side]:
   if 'closure' in name or 'pocket' in name:
    okay,nearest,normal,_=coat.closest_point_on_mesh(point)
    if okay:point=nearest+normal*.0015
   verts.append(point)
 return mesh(name,verts,[(i*2,i*2+1,i*2+3,i*2+2) for i in range(len(path)-1)],mat,weight)

# New connected coat surface: both sleeve armholes share torso boundary vertices.
N=32;rows=[(.77,.285,.201),(.88,.279,.195),(1.015,.265,.181),(1.15,.226,.159),(1.28,.258,.174),(1.38,.285,.164),(1.535,.285,.137),(1.566,.105,.087)]
verts=[];uv=[];faces=[]
for j,(z,rx,ry) in enumerate(rows):
 for i in range(N):
  a=i*math.tau/N;fold=(.0035*math.sin(a*7+z*14)+.002*math.sin(a*11-z*22))*(1 if j<6 else .25)
  verts.append((math.cos(a)*(rx+fold),.037+math.sin(a)*(ry+fold),z+.003*math.cos(a*5) if j<5 else z))
  uv.append((i/N,j/(len(rows)-1)))
for j in range(len(rows)-1):
 for i in range(N):
  # Actual armholes, and a short centre-back vent below the hip.
  hole=j==5 and (i in list(range(0,4))+list(range(28,32))+list(range(12,20)))
  back_vent=j<2 and i in [8,24]
  if not hole and not back_vent:faces.append((j*N+i,j*N+(i+1)%N,(j+1)*N+(i+1)%N,(j+1)*N+i))
for sign,mid in [(1,0),(-1,16)]:
 ids=[(mid+k)%N for k in range(-4,5)]
 boundary=[5*N+i for i in ids]+[6*N+i for i in reversed(ids)]
 angles=[math.atan2(verts[i][2]-1.4575,verts[i][1]-.037) for i in boundary]
 previous=boundary
 for j,(x,ry,rz) in enumerate([(.35,.087,.094),(.40,.083,.089),(.45,.078,.079),(.485,.080,.078),(.53,.072,.073),(.60,.062,.062),(.665,.052,.054),(.708,.050,.052)]):
  ring=[]
  for k,a in enumerate(angles):
   fold=.0022*math.sin(a*5+x*55)+.0045*math.sin(a*4+x*75)*math.exp(-((x-.48)/.08)**2)
   ring.append(len(verts));verts.append((sign*x,.065+math.cos(a)*(ry+fold),1.4555+math.sin(a)*(rz+fold)));uv.append((k/len(angles),x*2))
  for k in range(len(ring)):faces.append((previous[k],previous[(k+1)%len(ring)],ring[(k+1)%len(ring)],ring[k]))
  previous=ring
coat=mesh('Revision / Joined field coat and sleeves',verts,faces,canvas,torso_weight,uv,.003,1)

# Sloping high storm collar: lower left aperture, raised right jaw shield.
v=[];f=[];u=[]
for row in range(4):
 for i in range(33):
  a=i*math.tau/32;top=1.626+.031*max(0,math.cos(a))
  z=1.555+(top-1.555)*row/3
  rx=.109+.016*row/3;ry=.095+.009*row/3
  v.append((math.cos(a)*rx,.028+math.sin(a)*ry,z));u.append((i/32,row/3))
for j in range(3):
 for i in range(32):f.append((j*33+i,j*33+i+1,(j+1)*33+i+1,(j+1)*33+i))
mesh('Revision / Asymmetric storm collar',v,f,lining,lambda p:{'spine_03':.65,'neck_01':.35},u,.002)

# Asymmetric closure and welt pockets follow the front panel, with sewn edges.
front=[]
for z in [.82,.9,1,1.12,1.24,1.36,1.46,1.53]:
 row=min(rows,key=lambda r:abs(r[0]-z));x=.035+(z-.82)*.055;y=.037-row[2]-.004
 front.append((x,y,z))
ribbon('Revision / Offset storm closure',front,.018,seam,torso_weight)
for sign in [-1,1]:
 path=[]
 for t in range(9):
  x=sign*(.07+t*.014);z=1.07+t*.005;y=.037-.166*math.sqrt(max(.1,1-(x/.239)**2))-.005;path.append((x,y,z))
 ribbon('Revision / Recessed hand pocket welt',path,.009,seam,torso_weight)

# Purpose-cut trousers, knee compression folds and tucked ankle hems.
for sign,side in [(1,'l'),(-1,'r')]:
 v=[];f=[];u=[]
 for j,(z,rx,ry) in enumerate([(1.02,.121,.133),(.91,.119,.129),(.80,.108,.117),(.67,.099,.107),(.56,.090,.100),(.51,.094,.102),(.465,.083,.094),(.36,.072,.081),(.21,.049,.055)]):
  for i in range(24):
   a=i*math.tau/24;crease=.0035*math.sin(a*4+z*55)*math.exp(-((z-.53)/.14)**2)
   v.append((sign*.1143+math.cos(a)*(rx+crease),.04+math.sin(a)*(ry+crease),z));u.append((i/24,j/8))
 for j in range(8):
  for i in range(24):f.append((j*24+i,j*24+(i+1)%24,(j+1)*24+(i+1)%24,(j+1)*24+i))
 def leg_weight(p,side=side):
  t=max(0,min(1,(.62-p.z)/.15));return {'thigh_'+side:1-t,'calf_'+side:t}
 mesh('Revision / Tailored trouser '+side,v,f,twill,leg_weight,u,subdiv=1)
 # Continuous rubber-soled service boots, no fantasy buckles or flared cuffs.
 v=[];f=[];u=[]
 boot_rows=[(.008,-.031,.070,.172),(.027,-.031,.071,.172),(.045,-.026,.069,.163),(.075,-.012,.066,.145),(.115,.026,.062,.102),(.155,.069,.058,.070),(.21,.068,.058,.068),(.275,.059,.060,.073)]
 for j,(z,cy,rx,ry) in enumerate(boot_rows):
  for i in range(32):
   a=i*math.tau/32;v.append((sign*.1143+math.cos(a)*rx,cy+math.sin(a)*ry,z+.0015*math.sin(a*5+j*2) if j>2 else z));u.append((i/32,j/7))
 for j in range(len(boot_rows)-1):
  for i in range(32):f.append((j*32+i,j*32+(i+1)%32,(j+1)*32+(i+1)%32,(j+1)*32+i))
 boot=mesh('Revision / Rubber-soled service boot '+side,v,f,leather,lambda p,side=side:{'foot_'+side:1},u)
 boot.data.materials.append(sole)
 for poly in boot.data.polygons:
  if poly.center.z<.035:poly.material_index=1

# Preserve the licensed anatomical hands and their working finger weights only.
src=next((R.parent/'20261028_surveyor_assets/Sources').rglob('Superhero_Male_FullBody.gltf'))
objects=imported(src)
hands=next(o for o in objects if o.type=='MESH' and o.name.startswith('SuperHero'))
bm=bmesh.new();bm.from_mesh(hands.data)
bmesh.ops.delete(bm,geom=[v for v in bm.verts if abs(v.co.x)<.698],context='VERTS');bm.to_mesh(hands.data);bm.free()
hands.name='Revision / Fitted anatomical gloves';hands.data.materials.clear();hands.data.materials.append(leather)
for mod in list(hands.modifiers):hands.modifiers.remove(mod)
hands.parent=rig;hands.matrix_world=Matrix.Identity(4);mod=hands.modifiers.new('Preserved finger skin','ARMATURE');mod.object=rig;keep.add(hands)
for o in list(objects):
 if o!=hands:bpy.data.objects.remove(o,do_unlink=True)

# MPFB target-authored aged skull, real eyelids/mouth/ears, and correctly fitted eyes.
with bpy.data.libraries.load(str(R/'MPFB_Aged_Head_With_Eyes.blend'),link=False) as (a,b):
 b.objects=[n for n in a.objects if n in ['Surveyor_Aged_Anatomy_Source','Anatomical_Eyes_Source']]
anatomy=[]
for obj in b.objects:
 bpy.context.collection.objects.link(obj);anatomy.append(obj)
def map_head(p):return Vector((p.x*1.12,p.y*1.12+.065,(p.z-1.43)*1.32+1.5))
for obj in anatomy:
 if 'Anatomy' in obj.name:
  # Helpers are never exported. Keep actual body topology and its original UVs.
  body_id=obj.vertex_groups['body'].index
  kill=[v.index for v in obj.data.vertices if v.co.z<1.425 or not any(w.group==body_id and w.weight>.5 for w in v.groups)]
  bm=bmesh.new();bm.from_mesh(obj.data);bm.verts.ensure_lookup_table();bmesh.ops.delete(bm,geom=[bm.verts[i] for i in kill],context='VERTS');bm.to_mesh(obj.data);bm.free()
  obj.name='Revision / Aged asymmetric human face'
  mat=skin
 else:obj.name='Revision / Natural recessed eyes';mat=eye_mat
 for mod in list(obj.modifiers):obj.modifiers.remove(mod)
 for v in obj.data.vertices:v.co=map_head(v.co)
 obj.data.materials.clear();obj.data.materials.append(mat);obj.vertex_groups.clear()
 def head_weight(p):
  h=max(0,min(1,(p.z-1.505)/.075));return {'neck_01':1-h,'Head':h}
 bind(obj,head_weight)
 for poly in obj.data.polygons:poly.use_smooth=True

# Low fitted survey cap and long narrow rain peak. Curved cloth, not a flat box.
head_obj=next(o for o in anatomy if 'Aged asymmetric' in o.name)
def scalp(a,z):
 direction=Vector((math.cos(a),math.sin(a),0));centre=Vector((0,.018,z))
 okay,hit,_,_=head_obj.ray_cast(centre,direction)
 return hit+direction*.004 if okay else centre+direction*.10
v=[];f=[];u=[]
for j,(z,rx,ry,cy) in enumerate([(1.785,.098,.110,.014),(1.838,.100,.111,.017),(1.865,.084,.090,.020),(1.878,.045,.050,.025)]):
 for i in range(40):
  a=i*math.tau/40;v.append(tuple(scalp(a,z)) if j==0 else (math.cos(a)*rx,cy+math.sin(a)*ry,z));u.append((i/40,j/3))
for j in range(3):
 for i in range(40):f.append((j*40+i,j*40+(i+1)%40,(j+1)*40+(i+1)%40,(j+1)*40+i))
v.append((0,.025,1.881));u.append((.5,1))
for i in range(40):f.append((120+i,120+(i+1)%40,160))
mesh('Revision / Fitted rain cap',v,f,canvas,lambda p:{'Head':1},u,.002)
v=[];f=[];u=[]
for j in range(4):
 for i in range(25):
  a=-math.pi*.82+i*math.pi*.64/24;root=scalp(a,1.785)
  root+=Vector((math.cos(a),math.sin(a),0))*(j*.013)
  root.z-=.010*j/3
  v.append(tuple(root));u.append((i/24,j/3))
for j in range(3):
 for i in range(24):f.append((j*25+i,j*25+i+1,(j+1)*25+i+1,(j+1)*25+i))
mesh('Revision / Curved weather peak',v,f,canvas,lambda p:{'Head':1},u,.003)

for obj in list(bpy.data.objects):
 if obj not in keep:bpy.data.objects.remove(obj,do_unlink=True)
for tr in rig.animation_data.nla_tracks:tr.mute=True
rig.animation_data.action=None
for b in rig.pose.bones:b.matrix_basis=Matrix.Identity(4)
bpy.context.view_layer.update();bpy.ops.file.pack_all()
bpy.ops.wm.save_as_mainfile(filepath=str(O/'Surveyor_Custom_Fieldcoat.blend'))
# The neutral construction has now been reviewed. Preserve this exact rigged
# source and export all existing clips for the isolated native art showcase.
for tr in rig.animation_data.nla_tracks:tr.mute=False
bpy.ops.export_scene.gltf(filepath=str(O/'surveyor_revision.glb'),export_format='GLB',export_animations=True,export_animation_mode='NLA_TRACKS',export_force_sampling=True,export_frame_range=False)
for tr in rig.animation_data.nla_tracks:tr.mute=True
# Neutral modelling gate: no export/gameplay promotion at this step.
idle=next(tr.strips[0].action for tr in rig.animation_data.nla_tracks if tr.name.startswith('Idle_'))
rig.animation_data.action=idle
if idle.slots:rig.animation_data.action_slot=idle.slots[0]
bpy.context.scene.frame_set(10);bpy.context.view_layer.update()
world=bpy.data.worlds.new('Neutral physical art review');bpy.context.scene.world=world;world.use_nodes=True
world.node_tree.nodes['Background'].inputs[0].default_value=(.08,.085,.09,1)
for loc,power,size in [((2,-3,4),380,4),((-2,-1,2),120,3),((1,2,3),260,3)]:
 bpy.ops.object.light_add(type='AREA',location=loc);o=bpy.context.object;o.data.energy=power;o.data.size=size;o.rotation_euler=(Vector((0,0,1.2))-o.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add();cam=bpy.context.object;bpy.context.scene.camera=cam
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=32;scene.render.resolution_x=1050;scene.render.resolution_y=1200;scene.render.resolution_percentage=100
for name,loc,target,scale in [('front',(0,-4,1.1),(0,0,1),2.18),('side',(4,0,1.1),(0,0,1),2.18),('rear',(0,4,1.1),(0,0,1),2.18),('face',(.13,-2,1.75),(0,-.02,1.72),.48),('face_side',(2,-.4,1.75),(0,-.02,1.72),.48),('clothing',(.3,-3,1.3),(0,0,1.26),.9)]:
 cam.location=loc;cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=scale;scene.render.filepath=str(O/(name+'.png'));bpy.ops.render.render(write_still=True)
(O/'ART_GATE.json').write_text(json.dumps({'status':'UNREVIEWED / NOT PROMOTED','source':'MPFB aged target-authored head + custom joined fieldcoat, collar, trousers, boots, cap; licensed anatomical hands; original rig','parts':[(o.name,len(o.data.vertices)) for o in keep if o.type=='MESH'],'motion':'Existing clips preserved; no new AI/controller changes'},indent=2))
