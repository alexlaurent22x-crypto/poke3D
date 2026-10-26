import bpy,pathlib,math
from mathutils import Vector
ROOT=pathlib.Path(__file__).resolve().parents[1]
for name,source in [('GuardMale','AvatarMale'),('BartenderFemale','AvatarFemale')]:
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
 bpy.ops.import_scene.fbx(filepath=str(ROOT/'Assets/POKS/Resources/Models'/(source+'.fbx')))
 arm=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
 if arm.animation_data:arm.animation_data_clear()
 for b in arm.pose.bones:
  b.rotation_mode='QUATERNION';b.rotation_quaternion=(1,0,0,0);b.location=(0,0,0);b.scale=(1,1,1)
 # The adult rest skeleton has straight legs. Lower the arms from the anatomical A/T pose.
 for side in ['L','R']:
  bone=arm.pose.bones.get('upperarm01.'+side)
  if bone:
   direction=Vector((.08 if side=='L' else -.08,0,-1));local=bone.bone.matrix_local.to_3x3().inverted()@direction
   bone.rotation_quaternion=Vector((0,1,0)).rotation_difference(local.normalized())
 # Idle is baked into a legacy-compatible animation, including the new standing pose.
 bpy.context.scene.render.fps=30
 for frame in [1,31,61,91,121]:
  for b in arm.pose.bones:
   if b.name=='head':
    from mathutils import Quaternion
    b.rotation_quaternion=Quaternion((0,1,0),math.sin((frame-1)/120*math.tau)*.018)
   b.keyframe_insert('location',frame=frame);b.keyframe_insert('rotation_quaternion',frame=frame);b.keyframe_insert('scale',frame=frame)
 arm.animation_data.action.name='idle_standing'
 for t in bpy.context.scene.objects:
  if t.name.startswith(('HairOption','BeardOption')):t.hide_render=True
 bpy.ops.object.select_all(action='SELECT')
 bpy.ops.export_scene.fbx(filepath=str(ROOT/'Assets/POKS/Resources/Models'/(name+'.fbx')),use_selection=True,object_types={'MESH','ARMATURE'},axis_forward='-Z',axis_up='Y',add_leaf_bones=False,bake_anim=True,bake_anim_use_all_actions=False,bake_anim_use_nla_strips=False,bake_anim_simplify_factor=0,use_mesh_modifiers=False)
 print('EXPORTED',name)
