"""Shelfless cupboard derived from the already-approved Kenney CC0 bookcase."""
from pathlib import Path
import bpy,bmesh,json,hashlib
G=Path(__file__).resolve().parents[1];source=G/'assets/interiors/home/bookcaseClosedDoors.glb'
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=str(source))
removed=0
for obj in list(bpy.context.scene.objects):
 if obj.type!='MESH':continue
 if obj.name.lower().startswith(('doorleft','doorright')):
  # Extend the existing fitted doors down to the floor; keep original hinges/handles.
  for vertex in obj.data.vertices:
   point=obj.matrix_world@vertex.co
   if point.z<.13:vertex.co.z-=.10
  continue
 bm=bmesh.new();bm.from_mesh(obj.data)
 delete=[]
 for face in bm.faces:
  center=obj.matrix_world@face.calc_center_median()
  x,y,z=center.x,center.z,-center.y
  if not (x<.045 or x>.355 or z<-.225 or y>.795):delete.append(face)
 removed+=len(delete);bmesh.ops.delete(bm,geom=delete,context='FACES');bm.to_mesh(obj.data);bm.free();obj.data.update()
folder=G/'assets/interiors/home';out=folder/'storageCupboard.glb'
bpy.ops.wm.save_as_mainfile(filepath=str(G/'tools/Storage_Cupboard.blend'))
bpy.ops.export_scene.gltf(filepath=str(out),export_format='GLB',export_animations=False)
(folder/'storage_cupboard_provenance.json').write_text(json.dumps({'source':'Kenney Furniture Kit 2.0 / bookcaseClosedDoors','license':'CC0; existing Kenney Furniture notices apply','source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'derivative_sha256':hashlib.sha256(out.read_bytes()).hexdigest(),'changes':'Remove internal shelves/base to preserve walkable floor; extend existing hinged doors. Original frames, back, top, handles and hinge pivots retained.','faces_removed':removed},indent=2))
print('CUPBOARD_DERIVATIVE removed_faces=',removed)
