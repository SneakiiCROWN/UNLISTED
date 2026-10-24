"""Fixed grip derivatives of the existing original work hand; fallback mesh untouched."""
from pathlib import Path
import bpy,math,os
from mathutils import Vector
G=Path(__file__).resolve().parents[1]
source=(G/'tools/build_first_person.py').read_text();exec(source[:source.index("palm('Right hand');")])
out=G/'assets/first_person'
for id,radius in [('tool',.011),('cell',.019)]:
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
 tube('Left palm',[(-.052,-.065,.035),(-.036,-.031,.015),(-.031,-.007,-.012)],[.023,.030,.027],skin,12,.8)
 for i,z in enumerate([.026,.009,-.009,-.026]):
  r=[.009,.0095,.0085,.0075][i]
  tube('Curled left finger '+str(i),[(-.032,-.008,z),(-.026,-radius-.007,z),(.001,-radius-.009,z),(.020,-.007,z),(.018,radius+.005,z),(.003,radius+.008,z)],[r,r,r*.95,r*.85,r*.70,r*.5],skin,10)
 tube('Opposing thumb',[(-.038,.001,.035),(-.023,radius+.022,.026),(.002,radius+.021,.009),(.014,radius+.009,-.004)],[.014,.012,.010,.007],skin,10)
 join_skin()
 bpy.ops.wm.save_as_mainfile(filepath=str(G/('tools/FirstPerson_Grip_'+id+'.blend')))
 bpy.ops.export_scene.gltf(filepath=str(out/('grip_'+id+'.glb')),export_format='GLB',export_animations=False)
 # Neutral construction reference, multiple angles, without game lighting tricks.
 scene=bpy.context.scene;scene.render.engine='BLENDER_EEVEE';scene.render.resolution_x=640;scene.render.resolution_y=640;scene.render.resolution_percentage=100
 scene.world.color=(.16,.16,.16)
 bpy.ops.object.light_add(type='AREA',location=(.15,-.25,.3));bpy.context.object.data.energy=20;bpy.context.object.data.shape='DISK';bpy.context.object.data.size=.3
 bpy.ops.object.camera_add(location=(.16,-.22,.14));cam=bpy.context.object;scene.camera=cam;cam.data.type='ORTHO';cam.data.ortho_scale=.19
 cam.rotation_euler=(Vector((0,0,0))-cam.location).to_track_quat('-Z','Y').to_euler()
 scene.render.filepath=str(G.parent/'Assets/Intake_20261025_SoundTouch'/('grip_'+id+'_neutral.png'));bpy.ops.render.render(write_still=True)
os._exit(0)
