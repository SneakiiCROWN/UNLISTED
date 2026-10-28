"""Bounded private silhouette revision from the preserved rigged Blender source.
No normal-game model changes; review the static construction before integration.
"""
import bpy,bmesh,math,json
from pathlib import Path
from mathutils import Vector,Matrix
G=Path(__file__).resolve().parents[1];C=G.parent/'Checkpoints/20261028_house_remembers';O=C/'Weatherhood01';O.mkdir(exist_ok=False)
source=G.parent/'Checkpoints/20261028_surveyor_revision/Construction04/Surveyor_Custom_Fieldcoat.blend'
bpy.ops.wm.open_mainfile(filepath=str(source))
rig=next(o for o in bpy.data.objects if o.type=='ARMATURE')
for tr in rig.animation_data.nla_tracks:tr.mute=True
rig.animation_data.action=None
for bone in rig.pose.bones:bone.matrix_basis=Matrix.Identity(4)
removed=[]
for obj in list(bpy.data.objects):
 if any(s in obj.name for s in ['Fitted rain cap','Curved weather peak','Asymmetric storm collar']):removed.append(obj.name);bpy.data.objects.remove(obj,do_unlink=True)
coat=next(o for o in bpy.data.objects if o.type=='MESH' and 'Joined field coat' in o.name)
# Sculpt the existing continuous surface; no extra rings/primitive garment parts.
# Compressed elbow folds and long weather-set folds have anatomical envelopes.
for vert in coat.data.vertices:
 p=vert.co;x=abs(p.x)
 if x>.34 and 1.32<p.z<1.57:
  elbow=math.exp(-((x-.49)/.075)**2)
  a=math.atan2(p.z-1.455,p.y-.055)
  displacement=(.007*math.sin(x*105+a*1.5)+.003*math.sin(x*161-a*2))*elbow
  p.y+=math.cos(a)*displacement;p.z+=math.sin(a)*displacement
 elif .79<p.z<1.30:
  a=math.atan2(p.y-.037,p.x)
  f=.004*math.sin(a*9+p.z*16)+.002*math.sin(a*15-p.z*25)
  p.x+=math.cos(a)*f;p.y+=math.sin(a)*f
coat.data.update()
canvas=coat.data.materials[0].copy();canvas.name='Weatherhood / rain-darkened canvas'
bs=canvas.node_tree.nodes.get('Principled BSDF');bs.inputs['Roughness'].default_value=.86
tex=next(n for n in canvas.node_tree.nodes if n.type=='TEX_IMAGE' and n.image.colorspace_settings.name!='Non-Color')
mix=canvas.node_tree.nodes.new('ShaderNodeMixRGB');mix.blend_type='MULTIPLY';mix.inputs[0].default_value=1;mix.inputs[2].default_value=(.42,.36,.27,1)
canvas.node_tree.links.new(tex.outputs['Color'],mix.inputs[1]);canvas.node_tree.links.new(mix.outputs[0],bs.inputs['Base Color'])
coat.data.materials[0]=canvas
verts=[];uv=[];faces=[];N=36
# Open, asymmetric storm hood. Lower perimeter overlaps the coat's real neck
# seam; the aperture frames the face rather than sealing it inside a cone.
rows=[(1.557,.109,.094,.028),(1.61,.134,.111,.033),(1.70,.153,.133,.042),(1.80,.155,.141,.044),(1.875,.137,.134,.040),(1.918,.085,.103,.039)]
for j,(z,rx,ry,cy) in enumerate(rows):
 for i in range(N+1):
  t=i/N;a=-.72+t*(math.tau-1.67)
  # Heavy left edge hangs lower and closer to one cheek, without moving eyes.
  sag=.017*math.sin(t*math.pi)*math.exp(-((z-1.78)/.16)**2)
  fold=.0035*math.sin(t*math.pi*12+j*.7)*(1 if j<5 else .35)
  verts.append((math.cos(a)*(rx+fold),cy+math.sin(a)*(ry+fold),z-sag+.004*math.sin(t*math.pi*3)))
  uv.append((t,j/5))
for j in range(len(rows)-1):
 for i in range(N):faces.append((j*(N+1)+i,j*(N+1)+i+1,(j+1)*(N+1)+i+1,(j+1)*(N+1)+i))
verts.append((0,.045,1.93));uv.append((.5,1))
for i in range(N):faces.append((5*(N+1)+i,5*(N+1)+i+1,len(verts)-1))
mesh=bpy.data.meshes.new('Continuous weatherhood');mesh.from_pydata(verts,[],faces);mesh.materials.append(canvas);mesh.update()
hood=bpy.data.objects.new('Revision / Asymmetric weatherhood',mesh);bpy.context.collection.objects.link(hood)
bm=bmesh.new();bm.from_mesh(mesh);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(mesh);bm.free()
layer=mesh.uv_layers.new(name='Storm panels')
for loop in mesh.loops:layer.data[loop.index].uv=uv[loop.vertex_index]
for poly in mesh.polygons:poly.use_smooth=True
bpy.context.view_layer.objects.active=hood
solid=hood.modifiers.new('Bound fabric thickness','SOLIDIFY');solid.thickness=.003;solid.offset=0;bpy.ops.object.modifier_apply(modifier=solid.name)
hood.parent=rig
for vert in hood.data.vertices:
 t=max(0,min(1,(vert.co.z-1.57)/.12))
 for name,w in [('spine_03',1-t),('neck_01',t*.25),('Head',t*.75)]:
  if w>0:(hood.vertex_groups.get(name) or hood.vertex_groups.new(name=name)).add([vert.index],w,'REPLACE')
mod=hood.modifiers.new('Existing 65-bone rig','ARMATURE');mod.object=rig
# Add a narrow rolled facing along the real aperture, fitted to its vertices.
for side in [0,N]:
 curve=bpy.data.curves.new('Rolled storm edge','CURVE');curve.dimensions='3D';curve.bevel_depth=.0035;curve.bevel_resolution=1
 spline=curve.splines.new('POLY');spline.points.add(len(rows)-1)
 for j,p in enumerate(spline.points):p.co=(*verts[j*(N+1)+side],1)
 obj=bpy.data.objects.new('Revision / Hood edge',curve);bpy.context.collection.objects.link(obj);curve.materials.append(canvas)
 obj.parent=rig;bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);bpy.context.view_layer.objects.active=obj;bpy.ops.object.convert(target='MESH')
 obj=bpy.context.object
 for v in obj.data.vertices:
  t=max(0,min(1,(v.co.z-1.57)/.12))
  for name,w in [('spine_03',1-t),('neck_01',t*.25),('Head',t*.75)]:
   if w>0:(obj.vertex_groups.get(name) or obj.vertex_groups.new(name=name)).add([v.index],w,'REPLACE')
 mod=obj.modifiers.new('Existing rig','ARMATURE');mod.object=rig
bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(O/'Surveyor_Weatherhood.blend'))
for tr in rig.animation_data.nla_tracks:tr.mute=False
bpy.ops.export_scene.gltf(filepath=str(O/'surveyor_weatherhood.glb'),export_format='GLB',export_animation_mode='NLA_TRACKS',export_animations=True,export_force_sampling=True,export_frame_range=False)
for tr in rig.animation_data.nla_tracks:tr.mute=True
idle=next(t.strips[0].action for t in rig.animation_data.nla_tracks if t.name.startswith('Idle_'));rig.animation_data.action=idle
if idle.slots:rig.animation_data.action_slot=idle.slots[0]
bpy.context.scene.frame_set(10)
world=bpy.data.worlds.new('Neutral hood construction');bpy.context.scene.world=world;world.use_nodes=True;world.node_tree.nodes['Background'].inputs[0].default_value=(.075,.08,.09,1)
for loc,power in [((2,-3,4),400),((-2,-1,2),160),((1,2,3),300)]:
 bpy.ops.object.light_add(type='AREA',location=loc);o=bpy.context.object;o.data.energy=power;o.data.size=3;o.rotation_euler=(Vector((0,0,1.2))-o.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add();cam=bpy.context.object;scene=bpy.context.scene;scene.camera=cam;scene.render.engine='CYCLES';scene.cycles.samples=24;scene.render.resolution_x=900;scene.render.resolution_y=1100;scene.render.resolution_percentage=100
for name,loc,target,scale in [('front',(0,-4,1.1),(0,0,1),2.18),('side',(4,0,1.1),(0,0,1),2.18),('rear',(0,4,1.1),(0,0,1),2.18),('face',(.13,-2,1.75),(0,-.02,1.72),.48)]:
 cam.location=loc;cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=scale;scene.render.filepath=str(O/(name+'.png'));bpy.ops.render.render(write_still=True)
(O/'ART_SCOPE.json').write_text(json.dumps({'status':'STATIC REVIEW REQUIRED / NOT PROMOTED','source':str(source),'removed':removed,'bones':len(rig.data.bones),'scope':'New asymmetric hood, exposed face framing and anatomically weighted cloth folds. Original anatomy/boots/hands retained. Not a new approved antagonist.'},indent=2))
