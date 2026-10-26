"""Blender 4.x: convert licensed assets to FBX and author the new POKS salon.
Run from UnityPoker: blender -b --python Tools/build_unity_art.py
No Godot runtime or Godot scene is used. Source GLBs are anatomical CC0 derivatives.
"""
import bpy, math, json, pathlib, random
from mathutils import Vector
ROOT=pathlib.Path(__file__).resolve().parents[1]
OUT=ROOT/'Assets/POKS/Resources/Models';TEX=ROOT/'Assets/POKS/Resources/Textures'
OUT.mkdir(parents=True,exist_ok=True);TEX.mkdir(parents=True,exist_ok=True)
catalog=[]
def clear():
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
 for d in list(bpy.data.materials):bpy.data.materials.remove(d)
 for d in list(bpy.data.actions):bpy.data.actions.remove(d)
def mat(n,c,metal=0,rough=.5):
 m=bpy.data.materials.new(n);m.diffuse_color=(*c,1);m.use_nodes=True
 s=m.node_tree.nodes.get('Principled BSDF');s.inputs['Base Color'].default_value=(*c,1);s.inputs['Metallic'].default_value=metal;s.inputs['Roughness'].default_value=rough
 return m
def xyz(p):return (p[0],-p[2],p[1])
def finish(o,n,m):
 o.name=n;o.data.materials.append(m)
 for p in o.data.polygons:p.use_smooth=True
 return o
def box(n,p,s,m,bevel=.025):
 bpy.ops.mesh.primitive_cube_add(size=1,location=xyz(p));o=bpy.context.object;o.scale=(s[0],s[2],s[1]);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 if bevel:
  b=o.modifiers.new('Crafted edges','BEVEL');b.width=bevel;b.segments=3
  o.modifiers.new('Weighted normals','WEIGHTED_NORMAL')
 return finish(o,n,m)
def sphere(n,p,s,m):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=32,ring_count=20,location=xyz(p));o=bpy.context.object;o.scale=(s[0],s[2],s[1]);return finish(o,n,m)
def cylinder(n,p,r,h,m,verts=64):
 bpy.ops.mesh.primitive_cylinder_add(vertices=verts,radius=r,depth=h,location=xyz(p));o=bpy.context.object
 b=o.modifiers.new('Rounded rim','BEVEL');b.width=.012;b.segments=3;o.modifiers.new('Normals','WEIGHTED_NORMAL');return finish(o,n,m)
def ring(n,p,r,thickness,m,sx=1,sz=1):
 bpy.ops.mesh.primitive_torus_add(major_segments=96,minor_segments=12,location=xyz(p),major_radius=r,minor_radius=thickness);o=bpy.context.object;o.scale=(sx,sz,1);return finish(o,n,m)
def text(n,body,p,size,m,rot=(90,0,0)):
 bpy.ops.object.text_add(location=xyz(p));o=bpy.context.object;o.name=n;o.data.body=body;o.data.align_x='CENTER';o.data.size=size;o.data.extrude=.001;o.rotation_euler=tuple(math.radians(x) for x in rot);o.data.materials.append(m)
 bpy.ops.object.convert(target='MESH');return o
def materials(prefix):
 for m in list(bpy.data.materials):
  if m.users==0:continue
  m.name=prefix+'_'+m.name.replace('.','_').replace(' ','_')
  bs=m.node_tree.nodes.get('Principled BSDF') if m.use_nodes else None
  rec={'name':m.name,'color':list(bs.inputs['Base Color'].default_value if bs else m.diffuse_color),'metallic':float(bs.inputs['Metallic'].default_value) if bs else 0,'smoothness':1-float(bs.inputs['Roughness'].default_value) if bs else .5,'baseMap':'','normalMap':'','maskMap':''}
  if bs:
   def image_for(socket):
    def walk(node,depth=0):
     if depth>8:return None
     if node.type=='TEX_IMAGE':return node.image
     for inp in node.inputs:
      if inp.is_linked:
       found=walk(inp.links[0].from_node,depth+1)
       if found:return found
     return None
    return walk(socket.links[0].from_node) if socket.is_linked else None
   for sock,key in [('Base Color','baseMap'),('Normal','normalMap')]:
    im=image_for(bs.inputs[sock])
    if im:
     fn=m.name+'_'+key;im.filepath_raw=str(TEX/(fn+'.png'));im.file_format='PNG';im.save();rec[key]='Textures/'+fn
   # glTF stores G roughness and B metalness; HDRP needs R metallic/G AO/B detail/A smoothness.
   im=image_for(bs.inputs['Roughness'])
   if im:
    w,h=im.size;pixels=list(im.pixels[:]);mask=[]
    for i in range(0,len(pixels),4):mask.extend((pixels[i+2],1,.5,1-pixels[i+1]))
    fn=m.name+'_maskMap';mi=bpy.data.images.new(fn,width=w,height=h,alpha=True);mi.pixels=mask;mi.filepath_raw=str(TEX/(fn+'.png'));mi.file_format='PNG';mi.save();rec['maskMap']='Textures/'+fn
  catalog.append(rec)
def export(name,animations=False):
 materials(name)
 # FBX cannot carry curves: evaluated bevels are exported as meshes.
 bpy.ops.object.select_all(action='DESELECT')
 for o in bpy.context.scene.objects:
  if o.type in {'MESH','ARMATURE'}:o.select_set(True)
 bpy.ops.export_scene.fbx(filepath=str(OUT/(name+'.fbx')),use_selection=True,object_types={'MESH','ARMATURE'},axis_forward='-Z',axis_up='Y',apply_unit_scale=True,add_leaf_bones=False,bake_anim=animations,bake_anim_use_all_actions=True,bake_anim_use_nla_strips=False,bake_anim_simplify_factor=0,mesh_smooth_type='FACE',use_mesh_modifiers=True,path_mode='AUTO')
 print('EXPORTED',name,len([o for o in bpy.context.scene.objects if o.type=='MESH']))

# Licensed original detailed furniture, with extracted PBR maps.
for name in ['SheenChair','ChairDamask','SheenWoodLeatherSofa','LightsPunctualLamp']:
 clear();source=ROOT/'Tools/SourceAssets'/(name+'-Unity.glb' if name=='SheenWoodLeatherSofa' else name+'.glb');bpy.ops.import_scene.gltf(filepath=str(source));export(name)

# Existing CC0 anatomical source derivatives, converted to FBX with real skinned animation.
for name,source in [('AvatarMale','gabriel'),('AvatarFemale','elise'),('OpponentFemale','maya'),('Dealer','nora')]:
 clear();bpy.ops.import_scene.gltf(filepath=str(ROOT/'Tools/SourceAssets/Humans'/(source+'.glb')))
 for o in list(bpy.context.scene.objects):
  if o.type!='MESH':continue
  # Blender's FBX supports shape keys only when mesh modifiers are not baked on this mesh.
  if 'Tailored' in o.name:
   if not o.data.shape_keys:o.shape_key_add(name='Basis')
   vs=o.data.vertices;lo=min(v.co.z for v in vs);hi=max(v.co.z for v in vs);head=hi-(hi-lo)*.18
   maxx=max(abs(v.co.x) for v in vs);center_y=sum(v.co.y for v in vs if v.co.z>head)/max(1,sum(v.co.z>head for v in vs))
   for key in ['Build','Eyes','Nose','Mouth','Jaw','Face']:
    shape=o.shape_key_add(name=key)
    for i,v in enumerate(vs):
     p=v.co.copy();hz=(p.z-head)/max(.001,hi-head);front=max(0,min(1,(p.y-center_y+.04)/.12))
     if key=='Build' and p.z<head:p.x*=1.10
     elif 0<hz<1:
      if key=='Face':p.x*=1.07
      elif key=='Eyes' and .42<hz<.65:p.x*=1.06
      elif key=='Nose' and abs(p.x)<maxx*.09 and .27<hz<.60:p.y+=.018*front
      elif key=='Mouth' and .20<hz<.35:p.x*=1.08
      elif key=='Jaw' and hz<.28:p.x*=1.10
     shape.data[i].co=p
  # Preserve all morphs on export. GLB importer has already resolved subdivision.
  for mod in list(o.modifiers):
   if mod.type!='ARMATURE':o.modifiers.remove(mod)
 # Extra hair variants are separately skinned accessories following the existing head bone.
 arm=next((o for o in bpy.context.scene.objects if o.type=='ARMATURE'),None)
 if arm:
  head=arm.data.bones.get('head')
  if head:
   center=arm.matrix_world @ head.head_local
   # Accessories are authored in rest space, then skin to the same bone.
   hair=mat('AccessoryHair',(.028,.014,.008),0,.7)
   for idx in range(1,5):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=32,ring_count=16,location=center+Vector((0,-.015,.115)))
    o=bpy.context.object;o.name='HairOption'+str(idx);o.scale=(.105,.10,.075 if idx==1 else .11)
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(hair)
    if idx==2:o.scale.y=1.5
    if idx==3:o.scale.z=1.5
    if idx==4:o.scale.x=1.2
    # Convert coordinates to arm-local space before skinning.
    world=o.matrix_world.copy();o.parent=arm;o.matrix_world=world
    bpy.context.view_layer.objects.active=o;bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    g=o.vertex_groups.new(name='head');g.add(list(range(len(o.data.vertices))),1,'REPLACE');mod=o.modifiers.new('Head skin','ARMATURE');mod.object=arm
   for idx in range(1,3):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=32,ring_count=16,location=center+Vector((0,.075,-.04)))
    o=bpy.context.object;o.name='BeardOption'+str(idx);o.scale=(.075 if idx==1 else .045,.025,.045 if idx==1 else .065)
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(hair);world=o.matrix_world.copy();o.parent=arm;o.matrix_world=world
    bpy.context.view_layer.objects.active=o;bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    g=o.vertex_groups.new(name='head');g.add(list(range(len(o.data.vertices))),1,'REPLACE');mod=o.modifiers.new('Head skin','ARMATURE');mod.object=arm
 # Export skinned mesh with shape keys (FBX exporter must not apply skin modifiers).
 materials(name)
 bpy.ops.object.select_all(action='SELECT')
 bpy.ops.export_scene.fbx(filepath=str(OUT/(name+'.fbx')),use_selection=True,object_types={'MESH','ARMATURE'},axis_forward='-Z',axis_up='Y',add_leaf_bones=False,bake_anim=True,bake_anim_use_all_actions=True,bake_anim_use_nla_strips=False,bake_anim_simplify_factor=0,use_mesh_modifiers=False,mesh_smooth_type='FACE')
 print('EXPORTED',name)

clear();rng=random.Random(18)
wood=mat('Mahogany',(.095,.025,.018),0,.32);gold=mat('BrushedGold',(.71,.48,.16),.92,.24)
black=mat('BlackLacquer',(.012,.011,.016),.2,.22);red=mat('BordeauxVelvet',(.16,.012,.035),0,.8)
felt=mat('BordeauxFelt',(.095,.009,.025),0,.94);ivory=mat('WarmIvory',(.68,.58,.40),0,.5)
marble=mat('BlackMarble',(.04,.035,.045),.1,.2);glass=mat('BottleGlass',(.045,.12,.08),.35,.2)
light=mat('Luminaire',(.95,.57,.20),.1,.15)
# Oval table: continuous turned bevelled surfaces, piping, rail, cupholders and brass inlays.
base=cylinder('TablePedestal',(0,.36,0),.52,.69,wood);base.scale.y=.62
for y,r,h,m in [(.08,.72,.10,black),(.13,.66,.035,gold),(.67,1.0,.14,wood),(.76,1.0,.10,black),(.805,1.0,.045,gold),(.83,1.0,.065,wood),(.87,.94,.065,black),(.891,.80,.012,felt)]:
 o=cylinder('PokerTable', (0,y,0),r,h,m,128);o.scale.x=1.72;o.scale.y=1.05
for r,y,t,m in [(.96,.865,.015,gold),(.88,.885,.064,black),(.803,.897,.008,gold),(.58,.899,.003,gold)]:ring('TailoredRail',(0,y,0),r,t,m,1.72,1.05)
for a in range(0,360,60):
 x=1.5*math.sin(math.radians(a));z=.91*math.cos(math.radians(a));cylinder('CupHolder',(x,.89,z),.052,.01,black);ring('CupHolderBrass',(x,.902,z),.055,.005,gold)
text('TableCrest','POKS CASINO',(0,.902,.35),.14,gold,rot=(0,0,0))
export('PokerTable')

clear()
wood=mat('WalnutPanels',(.08,.026,.018),0,.38);gold=mat('AntiqueGold',(.63,.39,.10),.88,.32)
black=mat('Obsidian',(.018,.017,.023),.14,.25);red=mat('BordeauxSilk',(.14,.008,.025),0,.77)
cream=mat('CeilingIvory',(.35,.29,.22),0,.9);marble=mat('BlackMarble',(.055,.047,.052),.12,.18)
light=mat('LampIvory',(.92,.61,.26),0,.3);bottle=mat('EmeraldGlass',(.025,.12,.075),.4,.2)
box('MarbleFloor',(0,-.12,0),(14,.22,14),marble)
# Geometric parquet joints and gold borders give the architecture real modeled detail.
for x in [-5.9,5.9]:box('FloorInlay',(x,.003,0),(.025,.008,12),gold,.002)
for z in [-5.9,5.9]:box('FloorInlay',(0,.003,z),(12,.008,.025),gold,.002)
box('Carpet',(0,.012,0),(7,.018,5),red,.008)
for x in [-3.45,3.45]:box('RugBorder',(x,.024,0),(.035,.006,4.85),gold,.002)
for z in [-2.4,2.4]:box('RugBorder',(0,.024,z),(6.9,.006,.035),gold,.002)
for side in [-1,1]:
 box('SideWall',(side*6.8,2.3,0),(.18,4.6,13.6),wood)
 for z in range(-6,7,2):
  box('WallPanel',(side*6.68,1.2,z),(.06,2.1,1.65),red)
  for d in [-.85,.85]:box('PanelMoulding',(side*6.61,1.2,z+d),(.055,2.2,.035),gold,.008)
  for y in [.12,2.3,3.95]:box('Cornice',(side*6.6,y,z),(.12,.06,1.8),gold,.01)
  cylinder('FlutedColumn',(side*6.5,2.05,z),.11,4.1,wood,24)
  for y in [.15,3.95]:cylinder('ColumnCapital',(side*6.5,y,z),.17,.10,gold)
for z in [-6.8,6.8]:
 box('EndWall',(0,2.3,z),(13.6,4.6,.18),wood)
 for y in [.12,2.3,4.2]:box('Cornice',(0,y,z*.97),(13.4,.075,.12),gold)
box('Ceiling',(0,4.65,0),(13.6,.15,13.6),cream)
for x in [-.83,.83]:
 box('GoldenDoor',(x,1.65,6.65),(1.61,3.3,.14),gold,.06)
 box('DoorInset',(x,1.72,6.55),(1.35,2.9,.07),black,.035)
 for yy in [.45,2.85]:box('DoorEmboss',(x,yy,6.49),(1.1,.04,.045),gold,.01)
 cylinder('DoorHandle',(x*.15,1.4,6.43),.026,.35,gold)
text('DoorTitle','LE SALON DES PRÉTENDANTS',(0,3.72,6.53),.22,gold,rot=(90,0,180))
# Bar, shelves, turned stools, glasses and individually modeled bottles.
box('BarCounter',(-4.8,.61,1.3),(1.05,1.2,4.7),wood,.10);box('BarTop',(-4.8,1.27,1.3),(1.28,.14,4.9),marble,.07)
for z in [-.6,.4,1.4,2.4,3.4]:
 box('BarGoldInset',(-4.25,.64,z),(.04,.95,.035),gold,.008)
 cylinder('StoolStem',(-3.55,.43,z),.045,.80,gold);cylinder('StoolBase',(-3.55,.07,z),.28,.08,black);cylinder('StoolCushion',(-3.55,.87,z),.25,.12,red)
for y in [1.65,2.35,3.05]:
 box('BarShelf',(-6.3,y,1.35),(.55,.07,4.7),wood)
 for j in range(12):
  z=-.7+j*.36;cylinder('Bottle',(-6.25,y+.19,z),.044,.31,bottle);cylinder('BottleNeck',(-6.25,y+.40,z),.019,.12,gold)
# Observation desk and lit TV.
cylinder('SupervisorTable',(4.65,.74,2.6),.65,.09,wood);cylinder('SupervisorStem',(4.65,.37,2.6),.075,.72,gold)
box('Paper',(4.5,.795,2.4),(.21,.004,.30),cream,.001);box('Pen',(4.7,.805,2.4),(.008,.008,.18),gold,.003)
box('TelevisionFrame',(6.57,2.6,-2.2),(.10,1.05,1.85),gold,.035);box('TelevisionScreen',(6.49,2.6,-2.2),(.04,.95,1.75),black,.01)
# Back banquette and coffee table.
box('BanquetteBase',(0,.28,-5.7),(4.3,.43,.85),wood,.14);box('BanquetteSeat',(0,.54,-5.55),(4.3,.24,.93),red,.15);box('BanquetteBack',(0,1.02,-5.99),(4.3,1.1,.22),red,.12)
for x in [-1.65,-.82,0,.82,1.65]:sphere('TuftButton',(x,1.05,-5.84),(.025,.025,.015),gold)
cylinder('CoffeeTable',(0,.48,-4.3),.72,.08,black);cylinder('CoffeeTableStem',(0,.23,-4.3),.075,.45,gold)
# Tiered chandelier and wall sconces. Emissive bulbs get local Unity light sources.
for y,r in [(3.7,1.15),(4.0,.75)]:
 ring('ChandelierRing',(0,y,0),r,.025,gold)
 for a in range(0,360,30):
  x=r*math.sin(math.radians(a));z=r*math.cos(math.radians(a));cylinder('ChandelierRod',(x,y+.18,z),.012,.36,gold);sphere('LampBulb',(x,y-.08,z),(.055,.11,.055),light)
cylinder('Suspension',(0,4.25,0),.035,.9,gold)
for x in [-6.45,6.45]:
 for z in [-4,0,4]:
  cylinder('Sconce',(x,2.85,z),.10,.32,gold);sphere('LampBulb',(x,3.05,z),(.13,.22,.13),light)
export('Salon')

clear();fur=mat('CatFur',(.13,.075,.04),0,.95);nose=mat('CatNose',(.18,.075,.055),0,.7)
sphere('SleepingCatBody',(0,.17,0),(.42,.18,.28),fur);sphere('SleepingCatHead',(.29,.20,.08),(.18,.16,.16),fur)
for z in [-.04,.22]:
 bpy.ops.mesh.primitive_cone_add(vertices=32,radius1=.075,radius2=.008,depth=.14,location=xyz((.29,.37,z)));finish(bpy.context.object,'CatEar',fur)
 sphere('CatPaw',(.30,.07,z),(.18,.055,.065),fur)
sphere('CatMuzzle',(.435,.17,.08),(.065,.06,.10),fur);sphere('CatNose',(.49,.20,.08),(.018,.014,.022),nose)
ring('CurledTail',(-.23,.12,.08),.23,.055,fur,.9,1)
# Closed eyes: thin dark eyelids following the head, no robotic eye spheres.
for z in [-.005,.165]:box('ClosedEye',(.43,.25,z),(.008,.008,.07),nose,.003)
export('SleepingCat')
(ROOT/'Assets/POKS/Resources/ArtCatalog.json').write_text(json.dumps({'materials':catalog},indent=2))
print('DONE',len(catalog),'materials')
