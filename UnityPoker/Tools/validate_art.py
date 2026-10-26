import bpy,pathlib,json,math,hashlib
from mathutils import Vector
ROOT=pathlib.Path(__file__).resolve().parents[1];reports=[]
for path in sorted((ROOT/'Assets/POKS/Resources/Models').glob('*.fbx')):
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
 for a in list(bpy.data.actions):bpy.data.actions.remove(a)
 bpy.ops.import_scene.fbx(filepath=str(path))
 meshes=[o for o in bpy.context.scene.objects if o.type=='MESH'];arms=[o for o in bpy.context.scene.objects if o.type=='ARMATURE']
 bounds=[o.matrix_world@Vector(corner) for o in meshes for corner in o.bound_box]
 morphs=sorted(set(k.name for o in meshes if o.data.shape_keys for k in o.data.shape_keys.key_blocks))
 rec={'model':path.name,'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'meshes':len(meshes),'triangles':sum(sum(len(poly.vertices)-2 for poly in o.data.polygons) for o in meshes),'bones':sum(len(a.data.bones) for a in arms),'actions':[a.name for a in bpy.data.actions],'morphs':morphs,'bounds':[[round(min(v[i] for v in bounds),3),round(max(v[i] for v in bounds),3)] for i in range(3)]}
 assert len(meshes)>0,path
 if path.stem in ['AvatarMale','AvatarFemale']:
  assert all(n in morphs for n in ['Build','Eyes','Nose','Mouth','Jaw','Face']),rec
  assert rec['bones']>100,rec
  assert any('idle' in n.lower() for n in rec['actions']),rec
 for o in meshes:
  if not o.data.shape_keys:continue
  base=o.data.shape_keys.key_blocks[0]
  for key in o.data.shape_keys.key_blocks[1:]:
   assert any((v.co-b.co).length>1e-6 for v,b in zip(key.data,base.data)),(path.name,key.name,'empty morph')
 reports.append(rec);print('VALIDATED',json.dumps(rec))
(ROOT/'Documentation/art-validation.json').write_text(json.dumps(reports,indent=2))
