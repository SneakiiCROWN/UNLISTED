"""Selective, non-overwriting private intake of owner-supplied character packs.

No download, installation, public asset copy or alteration of original archives.
The Blender builder consumes this layout. MPFB compatibility uses its own
temporary extension repository; do not install it into the owner's preferences.
"""
import hashlib, json, zipfile
from pathlib import Path

G=Path(__file__).resolve().parents[1]
R=G.parent/'Checkpoints/20261028_surveyor_assets'
choices={
 'Universal Animation Library[Standard].zip':lambda n:n.endswith('Unreal-Godot/UAL1_Standard.glb'),
 'Universal Animation Library 2[Standard].zip':lambda n:n.endswith('Unreal-Godot/UAL2_Standard.glb'),
 'Universal Base Characters[Standard].zip':lambda n:n.endswith('Godot - UE/Superhero_Male_FullBody.gltf'),
 'Modular Character Outfits - Fantasy[Standard].zip':lambda n:'glTF (Godot-Unreal)/' in n and Path(n).name in {
     'Male_Peasant.gltf','Male_Ranger.gltf','Male_Peasant_Body.gltf','Male_Peasant_Legs.gltf',
     'Male_Peasant_Feet.gltf','Male_Ranger_Arms.gltf','Male_Ranger_Head_Hood.gltf'},
}

def write_once(path, data):
 path=path.resolve()
 assert path.is_relative_to(R.resolve()),path
 path.parent.mkdir(parents=True,exist_ok=True)
 if path.exists():
  assert path.read_bytes()==data,'Existing staging differs; preserve it and select a new staging directory: '+str(path)
 else:path.write_bytes(data)

def main():
 receipt={}
 for name,pick in choices.items():
  archive=G.parent/'Assets'/name
  with zipfile.ZipFile(archive) as z:
   members=z.namelist();selected=[n for n in members if pick(n)]
   assert selected,name
   selected += [n for n in members if any(s in Path(n).name.lower() for s in ['license','readme']) and not n.endswith('/')]
   dest=R/'Sources'/archive.stem
   for n in selected:
    write_once(dest/n,z.read(n))
    if not n.endswith('.gltf'):continue
    doc=json.loads(z.read(n));parent=Path(n).parent
    for dep in doc.get('buffers',[])+doc.get('images',[]):
     uri=dep.get('uri','')
     if not uri or uri.startswith('data:'):continue
     relative=(parent/uri).as_posix()
     if relative in members:source=relative
     else:
      exact=[p for p in members if Path(p).name==Path(uri).name]
      if not exact:exact=[p for p in members if Path(p).name==Path(uri).name.replace('_png.png','.png')]
      assert exact,(name,uri)
      source=exact[0]
     write_once(dest/relative,z.read(source))
   receipt[name]={'archive_sha256':hashlib.sha256(archive.read_bytes()).hexdigest(),'selected_roots':selected}
 output=R/'SELECTED_RESOURCE_INTAKE.json'
 write_once(output,(json.dumps(receipt,indent=2)+'\n').encode('utf8'))
 print(output)

if __name__=='__main__':main()
