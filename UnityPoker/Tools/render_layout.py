"""Offline Blender geometry review only. Not a Unity/HDRP screenshot."""
import bpy,pathlib,math,json
from mathutils import Vector
ROOT=pathlib.Path(__file__).resolve().parents[1];bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
cat=json.loads((ROOT/'Assets/POKS/Resources/ArtCatalog.json').read_text())['materials'];entries={e['name']:e for e in cat}
def load(name,pos=(0,0,0),yaw=0,scale=1):
 before=set(bpy.context.scene.objects);before_actions=set(bpy.data.actions);bpy.ops.import_scene.fbx(filepath=str(ROOT/'Assets/POKS/Resources/Models'/(name+'.fbx')));obs=[o for o in bpy.context.scene.objects if o not in before]
 root=bpy.data.objects.new(name+'_placement',None);bpy.context.collection.objects.link(root);root.location=pos;root.rotation_euler.z=math.radians(yaw);root.scale=(scale,)*3
 for o in obs:
  if o.parent not in obs:o.parent=root
  if o.name.startswith(('HairOption','BeardOption','Banquette','TuftButton')):o.hide_render=True
  if o.type=='ARMATURE' and o.animation_data:
   new_actions=[a for a in bpy.data.actions if a not in before_actions and not a.name.startswith('Key')];act=next((a for a in new_actions if 'idle' in a.name.lower()),next(iter(new_actions),None))
   if act:o.animation_data.action=act
  if o.type=='MESH':
   for m in o.data.materials:
    if not m or not m.use_nodes:continue
    key=m.name
    if key not in entries and key[-4:-3]=='.':key=key[:-4]
    e=entries.get(key)
    if not e:continue
    bs=m.node_tree.nodes.get('Principled BSDF')
    if not bs:continue
    bs.inputs['Base Color'].default_value=e['color'];bs.inputs['Roughness'].default_value=1-e['smoothness'];bs.inputs['Metallic'].default_value=e['metallic']
    if e['baseMap']:
     im=bpy.data.images.load(str(ROOT/'Assets/POKS/Resources'/(e['baseMap']+'.png')),check_existing=True);tex=m.node_tree.nodes.new('ShaderNodeTexImage');tex.image=im;m.node_tree.links.new(tex.outputs['Color'],bs.inputs['Base Color'])
load('Salon');load('PokerTable')
# Unity +Z is Blender -Y. Character source faces Blender +Y.
for name,x,z,yaw in [('AvatarMale',0,-1.65,0),('AvatarMale',-1.5,.88,120),('OpponentFemale',1.5,.88,-120),('Dealer',0,1.75,180)]:
 load(name,(x,-z,0),180-yaw,.72)
 load('ChairDamask',(x,-z,0),-yaw,1.07/.687)
load('SheenWoodLeatherSofa',(0,5.7,0),180,1.0);load('LightsPunctualLamp',(3.3,5.5,0),180,.82)
load('GuardMale',(-2.1,-6,.36),0,.72);load('GuardMale',(2.1,-6,.36),0,.72)
load('BartenderFemale',(-5.65,-1,.36),90,.72)
load('SleepingCat',(.8,5.52,.67))
bpy.context.scene.frame_set(1)
for pos,power,size in [((0,0,3.4),1300,3),((-4,-1,3),800,2),((0,-5,3),700,2),((1,4,3),700,2)]:
 bpy.ops.object.light_add(type='AREA',location=pos);bpy.context.object.data.energy=power;bpy.context.object.data.shape='DISK';bpy.context.object.data.size=size
bpy.ops.object.camera_add(location=(5.2,6.0,3.6));camera=bpy.context.object;camera.rotation_euler=(Vector((0,-.2,1.1))-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.lens=28
scene=bpy.context.scene;scene.camera=camera;scene.render.engine='CYCLES';scene.cycles.samples=32;scene.cycles.use_denoising=False;scene.render.resolution_x=1100;scene.render.resolution_y=720;scene.render.resolution_percentage=100;scene.world.color=(.08,.08,.08);scene.render.image_settings.file_format='PNG';scene.render.filepath=str(ROOT/'Documentation/Blender-layout-review.png');bpy.ops.render.render(write_still=True)
