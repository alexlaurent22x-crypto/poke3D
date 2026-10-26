"""Refresh PBR textures/catalog without rebuilding character animation FBXs."""
import ast,pathlib,bpy,json
ROOT=pathlib.Path(__file__).resolve().parents[1];TEX=ROOT/'Assets/POKS/Resources/Textures';catalog=[]
tree=ast.parse((ROOT/'Tools/build_unity_art.py').read_text());functions=[x for x in tree.body if isinstance(x,ast.FunctionDef) and x.name in ['materials','clear']]
exec(compile(ast.Module(body=functions,type_ignores=[]),'build_unity_art.py','exec'))
for name in ['SheenChair','ChairDamask','SheenWoodLeatherSofa','LightsPunctualLamp']:
 clear();source=ROOT/'Tools/SourceAssets'/(name+'-Unity.glb' if name=='SheenWoodLeatherSofa' else name+'.glb')
 bpy.ops.import_scene.gltf(filepath=str(source));materials(name)
p=ROOT/'Assets/POKS/Resources/ArtCatalog.json';old=json.loads(p.read_text());by={e['name']:e for e in old['materials']};by.update({e['name']:e for e in catalog});old['materials']=list(by.values());p.write_text(json.dumps(old,indent=2))
print('Updated',len(catalog),'PBR materials')
