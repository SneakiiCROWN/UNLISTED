"""Private Blender study: licensed modular garment skins, explicit bind correction.

Run with Blender --background --factory-startup --python this_file. Original
archives and gameplay actor are never overwritten. No MPFB extraction/weight
transfer or rejected coat geometry is used.
"""
from pathlib import Path
import bpy, bmesh, math, json
from mathutils import Matrix, Vector

G = Path(__file__).resolve().parents[1]
R = G.parent / 'Checkpoints/20261028_surveyor_assets'
S = R / 'Sources'
O = R / 'Construction04'
O.mkdir(exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)

def imported(path):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(path))
    return set(bpy.data.objects) - before

old = imported(G / 'assets/original/surveyor_presence.glb')
rig = next(o for o in old if o.type == 'ARMATURE')
rig.name = 'SurveyorRig'
for o in list(old):
    if o.type == 'MESH': bpy.data.objects.remove(o, do_unlink=True)
# Keep the working skeleton and its existing retargeted animation actions.
for tr in rig.animation_data.nla_tracks: tr.mute = True
rig.animation_data.action = None
for pb in rig.pose.bones: pb.matrix_basis = Matrix.Identity(4)
bpy.context.view_layer.update()
manifest = {'method': 'Preserve active rig/actions. Per-vertex weighted source-rest to target-rest correction; preserve authored clothing weights.', 'parts': []}
keep = {rig}

def rebind(obj, source):
    # Same names do NOT imply the same joint basis. Correct source rest geometry
    # into this exact target bind space before changing the armature modifier.
    groups = {v.index: v.name for v in obj.vertex_groups}
    maps = {b.name: rig.matrix_world @ rig.data.bones[b.name].matrix_local @
            (source.matrix_world @ b.matrix_local).inverted() @ obj.matrix_world
            for b in source.data.bones if b.name in rig.data.bones}
    unweighted = 0
    for v in obj.data.vertices:
        influences = [(groups[w.group], w.weight) for w in v.groups
                      if groups[w.group] in maps and w.weight > 0]
        total = sum(w for _, w in influences)
        if total < .0001: unweighted += 1; continue
        v.co = sum((maps[n] @ v.co * (w / total) for n, w in influences), Vector())
    assert not unweighted, (obj.name, unweighted)
    obj.parent = rig; obj.matrix_world = Matrix.Identity(4)
    for mod in list(obj.modifiers):
        if mod.type == 'ARMATURE': obj.modifiers.remove(mod)
    mod = obj.modifiers.new('Authored garment skin / corrected bind', 'ARMATURE'); mod.object = rig
    keep.add(obj)
    manifest['parts'].append({'name': obj.name, 'vertices': len(obj.data.vertices), 'unweighted': unweighted,
                             'source_bones': len(source.data.bones), 'target_bones': len(rig.data.bones)})

parts = [('Male_Peasant_Body.gltf', 'Work jacket'),
         ('Male_Peasant_Legs.gltf', 'Work trousers'),
         ('Male_Peasant_Feet.gltf', 'Service boots'),
         ('Male_Ranger_Arms.gltf', 'Sleeves and gloves'),
         ('Male_Ranger_Head_Hood.gltf', 'Rain hood')]
for file, label in parts:
    objs = imported(next(S.rglob(file)))
    source = next(o for o in objs if o.type == 'ARMATURE')
    for obj in objs:
        if obj.type != 'MESH' or obj.name.startswith('Icosphere'): continue
        rebind(obj, source); obj.name = 'Asset study / ' + label
        if label in ['Work jacket', 'Service boots']:
            # Remove authored fantasy buckles, toggle closures and shoulder tabs
            # by connected mesh island, never by a slice through the garment skin.
            bm = bmesh.new(); bm.from_mesh(obj.data); remaining=set(bm.verts); discard=[]
            while remaining:
                todo=[remaining.pop()]; island=[]
                while todo:
                    v=todo.pop(); island.append(v)
                    for e in v.link_edges:
                        other=e.other_vert(v)
                        if other in remaining: remaining.remove(other); todo.append(other)
                if label=='Work jacket':
                    remove=len(island)<400
                else:
                    remove=len(island)<100 or (len(island)<200 and min(v.co.z for v in island)>.3)
                if remove: discard.extend(island)
            bmesh.ops.delete(bm,geom=discard,context='VERTS');bm.to_mesh(obj.data);bm.free()

base = imported(next(S.rglob('Superhero_Male_FullBody.gltf')))
source = next(o for o in base if o.type == 'ARMATURE')
for obj in base:
    if obj.type != 'MESH' or obj.name.startswith('Icosphere'): continue
    if obj.name.startswith('SuperHero_Male'):
        bm = bmesh.new(); bm.from_mesh(obj.data)
        bmesh.ops.delete(bm, geom=[v for v in bm.verts if v.co.z < 1.505 or (v.co.z<1.60 and abs(v.co.x)>.105)], context='VERTS')
        bm.to_mesh(obj.data); bm.free()
        obj.name = 'Anatomical head and neck'
    elif not obj.name.startswith(('Eyes', 'Eyebrows')): continue
    rebind(obj, source)
    obj.name = 'Asset study / ' + obj.name

def pigment(material, label, factor, roughness=.88):
    m = material.copy(); m.name = label
    if m.use_nodes:
        bs = m.node_tree.nodes.get('Principled BSDF')
        bs.inputs['Roughness'].default_value = roughness
        bs.inputs['Metallic'].default_value = 0
        inp = bs.inputs['Base Color']
        if inp.is_linked:
            # Direct texture replacement survives glTF export; arbitrary shader
            # multiply networks are not a portable material interchange contract.
            # Source packs also use mix nodes. Follow the intended material role,
            # rather than assuming a direct source-node layout.
            image_name=('T_Ranger_BaseColor.png' if 'canvas' in label else
                        'T_Superhero_Male_Dark.png' if 'pallor' in label else 'T_Peasant_BaseColor.png')
            replacement=R/'TextureWork'/image_name
            node=m.node_tree.nodes.new('ShaderNodeTexImage');node.image=bpy.data.images.load(str(replacement),check_existing=True)
            for link in list(inp.links):m.node_tree.links.remove(link)
            m.node_tree.links.new(node.outputs['Color'],inp)
            if any(t in label for t in ['glove','eyes','brow']):
                for link in list(inp.links):m.node_tree.links.remove(link)
                inp.default_value=(*factor,1)
            for link in list(bs.inputs['Roughness'].links):m.node_tree.links.remove(link)
            for link in list(bs.inputs['Metallic'].links):m.node_tree.links.remove(link)
        else: inp.default_value = (*factor, 1)
        for n in m.node_tree.nodes:
            if n.type == 'TEX_IMAGE' and n.image:
                n.interpolation = 'Closest'
    return m

for obj in list(keep):
    if obj.type != 'MESH': continue
    for i, mat in enumerate(obj.data.materials):
        name = obj.name
        if 'hood' in name: color = (.40, .38, .28); label = 'Rain-soaked ochre canvas'
        elif 'jacket' in name: color = (.15, .18, .17); label = 'Weathered charcoal work twill'
        elif 'trousers' in name: color = (.18, .19, .18); label = 'Stained work trousers'
        elif 'boots' in name: color = (.12, .13, .12); label = 'Worn rubberised leather'
        elif 'Sleeves' in name:
            color = (.10, .12, .11) if 'Regular' not in mat.name else (.065, .07, .065)
            label = 'Fitted sleeve' if 'Regular' not in mat.name else 'Close leather glove'
        elif 'Eyes' in name: color = (.24, .25, .22); label = 'Clouded recessed eyes'
        elif 'Eyebrows' in name: color = (.18, .17, .15); label = 'Sparse dark brow'
        else: color = (.59, .63, .57); label = 'Cold pallor / original skin detail'
        obj.data.materials[i] = pigment(mat, label, color)
    # A shared head/hood correction keeps eyes and garment seams in register.
    if any(t in obj.name for t in ['head', 'neck', 'Eyes', 'Eyebrows', 'hood']):
        for v in obj.data.vertices:
            c = v.co
            a = max(0, min(1, (c.z-1.50)/.08))
            c.x *= 1-.075*a
            c.y -= .018*a
            c.z += (c.z-1.55)*.10*a
            # Smooth across the UV seams and centreline; no hard region cuts.
            if 'Anatomical' in obj.name:
                c.z -= .009*math.exp(-((c.x-.04)/.045)**2-((c.z-1.62)/.065)**2)
            if 'Eyebrows' in obj.name: c.z=1.735+(c.z-1.735)*.50
            if 'hood' in obj.name and c.y<-.08 and c.z>1.70:
                fold=min(1,(-c.y-.08)/.075)*min(1,(c.z-1.70)/.12)
                c.z-=.022*fold
                c.y-=.025*fold
    if 'boots' in obj.name:
        for v in obj.data.vertices:
            if v.co.z > .30: v.co.x *= .95

# Remove source armatures/helpers, retaining only licensed fitted parts + active rig.
for obj in list(bpy.data.objects):
    if obj not in keep: bpy.data.objects.remove(obj, do_unlink=True)
for tr in rig.animation_data.nla_tracks: tr.mute = True
rig.animation_data.action = None
for pb in rig.pose.bones: pb.matrix_basis = Matrix.Identity(4)
bpy.context.scene.frame_set(0); bpy.context.view_layer.update()
manifest['target_bones'] = [b.name for b in rig.data.bones]
manifest['existing_actions'] = [tr.name for tr in rig.animation_data.nla_tracks]
(O/'CONSTRUCTION.json').write_text(json.dumps(manifest, indent=2))
# Work on loaded image datablocks only; never overwrite the archive/staged originals.
# A crisp 512px garment / 1024px head is adequate for the established presentation.
images=set()
for obj in keep:
    if obj.type!='MESH':continue
    for mat in obj.data.materials:
        if mat and mat.use_nodes:
            for node in mat.node_tree.nodes:
                if node.type=='TEX_IMAGE' and node.image:images.add(node.image)
for image in images:
    if image.size[0]>1024 or image.size[1]>1024:image.scale(1024,1024)
bpy.ops.file.pack_all()
bpy.ops.wm.save_as_mainfile(filepath=str(O/'Surveyor_Asset_Candidate.blend'))
# Retarget a UAL2 response for review. It is deliberately NOT installed as a
# looping gameplay idle: a repeated head-shake would be an unmotivated gesture.
ual=imported(next(p for p in S.rglob('UAL2_Standard.glb')))
motion=next(o for o in ual if o.type=='ARMATURE')
source_action=next(a for a in bpy.data.actions if a.name=='Idle_No_Loop')
motion.animation_data.action=source_action
if source_action.slots:motion.animation_data.action_slot=source_action.slots[0]
action=bpy.data.actions.new('Asset_HeadResponse');rig.animation_data.action=action
order=[]
def ordered(b):
    order.append(b.name)
    for c in b.children:ordered(c)
for b in rig.data.bones:
    if not b.parent:ordered(b)
for frame in range(math.ceil(source_action.frame_range[0]),math.ceil(source_action.frame_range[1])+1):
    bpy.context.scene.frame_set(frame);bpy.context.view_layer.update();world={}
    for name in order:
        bone=rig.data.bones[name];pb=rig.pose.bones[name];sb=motion.data.bones[name]
        # Rotation in source rest space -> target rest, then target parent-local.
        desired=motion.pose.bones[name].matrix.to_quaternion() @ sb.matrix_local.to_quaternion().inverted() @ bone.matrix_local.to_quaternion()
        parent=world[bone.parent.name] if bone.parent else rig.matrix_world.to_quaternion()
        local=(bone.parent.matrix_local.inverted() @ bone.matrix_local).to_quaternion() if bone.parent else bone.matrix_local.to_quaternion()
        pb.rotation_mode='QUATERNION';pb.rotation_quaternion=local.inverted() @ parent.inverted() @ desired
        pb.location=motion.pose.bones[name].location.copy() if name in ['root','pelvis'] else Vector()
        pb.scale=(1,1,1);pb.keyframe_insert('rotation_quaternion',frame=frame,group=name)
        if name in ['root','pelvis']:pb.keyframe_insert('location',frame=frame,group=name)
        world[name]=desired
rig.animation_data.action=None
track=rig.animation_data.nla_tracks.new();track.name='Asset_HeadResponse'
strip=track.strips.new('Asset_HeadResponse',0,action)
if action.slots:strip.action_slot=action.slots[0]
for obj in list(ual):
    if obj.name in bpy.data.objects:bpy.data.objects.remove(obj,do_unlink=True)
manifest['ual2_retarget']={'source':'UAL2_Standard.glb / Idle_No_Loop','destination':'Asset_HeadResponse','bones':len(order),'automatic_gameplay_use':False,'root_motion':'disabled / source in-place file'}
(O/'CONSTRUCTION.json').write_text(json.dumps(manifest,indent=2))
for pb in rig.pose.bones:pb.matrix_basis=Matrix.Identity(4)
for tr in rig.animation_data.nla_tracks: tr.mute = False
bpy.ops.file.pack_all()
bpy.ops.wm.save_as_mainfile(filepath=str(O/'Surveyor_Asset_Candidate_Rigged.blend'))
bpy.ops.export_scene.gltf(filepath=str(O/'surveyor_asset_candidate.glb'), export_format='GLB',
                         export_animations=True, export_animation_mode='NLA_TRACKS', export_force_sampling=True,
                         export_frame_range=False)

# Neutral static review before spending time on gameplay or new animation.
for tr in rig.animation_data.nla_tracks: tr.mute = True
rig.animation_data.action = None
for pb in rig.pose.bones: pb.matrix_basis = Matrix.Identity(4)
# Review the actual existing idle, not a separately hand-posed arm basis.
idle=next(tr.strips[0].action for tr in rig.animation_data.nla_tracks if tr.name.startswith('Idle_'))
rig.animation_data.action=idle
if idle.slots:rig.animation_data.action_slot=idle.slots[0]
bpy.context.scene.frame_set(12)
bpy.context.view_layer.update()
world = bpy.data.worlds.new('Neutral review'); bpy.context.scene.world = world; world.use_nodes = True
world.node_tree.nodes['Background'].inputs[0].default_value = (.10, .10, .10, 1)
for loc, power, size in [((1,-3,4), 320, 4), ((-2,1,3), 220, 3)]:
    bpy.ops.object.light_add(type='AREA', location=loc); obj=bpy.context.object
    obj.data.energy=power; obj.data.size=size
    obj.rotation_euler=(Vector((0,0,1))-obj.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add(); cam=bpy.context.object; bpy.context.scene.camera=cam
scene=bpy.context.scene; scene.render.engine='CYCLES'; scene.cycles.samples=24
scene.render.resolution_x=900; scene.render.resolution_y=1100; scene.render.resolution_percentage=100
for name, loc, target, scale in [('front',(0,-4,1.1),(0,0,1),2.2),('side',(4,0,1.1),(0,0,1),2.2),
                                 ('rear',(0,4,1.1),(0,0,1),2.2),('face',(.16,-2,1.77),(0,0,1.73),.62)]:
    cam.location=loc; cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler()
    cam.data.type='ORTHO'; cam.data.ortho_scale=scale
    scene.render.filepath=str(O/(name+'.png')); bpy.ops.render.render(write_still=True)
