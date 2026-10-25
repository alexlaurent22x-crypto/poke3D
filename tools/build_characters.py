"""Regenerate GLB assets: blender --background --python tools/build_characters.py.
Uses CC0 MakeHuman adult basemesh, morph targets, rig and weights (see ATTRIBUTION).
No MakeHuman application code is bundled. Godot users need only the exported GLBs.
"""
import bpy, math, json, pathlib
from mathutils import Vector, Quaternion
ROOT=pathlib.Path(__file__).resolve().parents[1]
SRC=ROOT/'assets/source/makehuman'
OUT=ROOT/'assets/characters'
SCALE=.15

def read_obj():
    vertices=[]; groups={}; group=''; uv=[]
    for line in open(SRC/'base.obj'):
        v=line.split()
        if not v: continue
        if v[0]=='v': vertices.append(Vector(tuple(map(float,v[1:4]))))
        elif v[0]=='g': group=v[1]; groups.setdefault(group,[])
        elif v[0]=='f': groups[group].append([int(x.split('/')[0])-1 for x in v[1:]])
    return vertices,groups
BASE,GROUPS=read_obj()
RIG=json.load(open(SRC/'default.mhskel'))
WEIGHTS=json.load(open(SRC/'default_weights.mhw'))['weights']

def mat(name,color,metal=0,rough=.5):
    m=bpy.data.materials.new(name); m.diffuse_color=(*color,1);m.use_nodes=True
    p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1)
    p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=rough
    return m

def sphere(name,location,scale,material,parent=None):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=24,ring_count=16,location=location)
    ob=bpy.context.object;ob.name=name;ob.scale=scale
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    ob.data.materials.append(material)
    for p in ob.data.polygons:p.use_smooth=True
    if parent: ob.parent=parent
    return ob

def transformed(v): return Vector((-v.x*SCALE,v.z*SCALE,(v.y+8.2)*SCALE))

def target(vertices,name):
    for l in open(SRC/(name+'.target')):
        a=l.split()
        if len(a)==4 and not a[0].startswith('#'):vertices[int(a[0])]+=Vector(tuple(map(float,a[1:])))

def mesh_obj(name,ids,faces,vs,materials,arm,assign=None,offset=0):
    ids=sorted(ids); remap={old:i for i,old in enumerate(ids)}
    mesh=bpy.data.meshes.new(name);mesh.from_pydata([transformed(vs[i]) for i in ids],[],[[remap[i] for i in f] for f in faces]);mesh.update()
    ob=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(ob)
    for m in materials:mesh.materials.append(m)
    for poly,face in zip(mesh.polygons,faces):
        poly.use_smooth=True
        if assign:poly.material_index=assign(sum((vs[i] for i in face),Vector())/len(face))
    for bone,pairs in WEIGHTS.items():
        selected=[(remap[i],w) for i,w in pairs if i in remap and w>.0001]
        if selected:
            group=ob.vertex_groups.new(name=bone)
            for i,w in selected:group.add([i],w,'REPLACE')
    ob.parent=arm
    if offset:
        for vert in mesh.vertices:vert.co+=vert.normal*offset
    mod=ob.modifiers.new('Tailored smooth surface','SUBSURF');mod.levels=1
    mod=ob.modifiers.new('Adult skeleton','ARMATURE');mod.object=arm
    return ob

def curve(name,points,radius,material,parent):
    data=bpy.data.curves.new(name,'CURVE');data.dimensions='3D';data.bevel_depth=radius;data.bevel_resolution=2
    spline=data.splines.new('BEZIER');spline.bezier_points.add(len(points)-1)
    for b,p in zip(spline.bezier_points,points):b.co=p;b.handle_left_type='AUTO';b.handle_right_type='AUTO'
    obj=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(obj);data.materials.append(material);obj.parent=parent
    return obj

def rigid_bind(ob,arm,bone='head'):
    # Preserve the rest-space coordinates and let skinning follow facial bones.
    if ob.type=='CURVE':
        bpy.context.view_layer.objects.active=ob;ob.select_set(True)
        bpy.ops.object.convert(target='MESH');ob=bpy.context.object;ob.select_set(False)
    if ob.type=='MESH':
        group=ob.vertex_groups.new(name=bone);group.add(list(range(len(ob.data.vertices))),1,'REPLACE')
        mod=ob.modifiers.new('Head attachment','ARMATURE');mod.object=arm
    ob.parent=arm
    return ob

def build(name,feminine,ethnicity,color,hair_color,skin_color):
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
    for action in list(bpy.data.actions):bpy.data.actions.remove(action)
    vs=[v.copy() for v in BASE]
    gender='female' if feminine else 'male'
    target(vs,f'{ethnicity}-{gender}-young')
    target(vs,f'universal-{gender}-young-averagemuscle-averageweight')
    skin=mat('Natural skin',skin_color,rough=.7)
    suit=mat('Silk eveningwear' if feminine else 'Midnight wool',color,rough=.42 if feminine else .76)
    shirt=mat('Ivory cotton',(.82,.79,.70),rough=.8)
    shoes=mat('Polished leather',(.015,.012,.018),rough=.24)
    gold=mat('Champagne gold',(.66,.45,.18),.82,.22)
    hair=mat('Hair',hair_color,rough=.65)
    lips=mat('Muted lip colour',(.38,.16,.15) if feminine else (.35,.19,.15),rough=.55)
    white=mat('Sclera',(.77,.75,.65),rough=.25)
    iris=mat('Iris',(.13,.20,.17) if name=='elise' else (.11,.062,.03),rough=.28)
    pupil=mat('Pupil',(.002,.003,.004),rough=.15)
    armdata=bpy.data.armatures.new('AdultSkeleton');arm=bpy.data.objects.new('AdultSkeleton',armdata);bpy.context.collection.objects.link(arm)
    bpy.context.view_layer.objects.active=arm;arm.select_set(True);bpy.ops.object.mode_set(mode='EDIT')
    def joint(n):return sum((transformed(vs[i]) for i in RIG['joints'][n]),Vector())/len(RIG['joints'][n])
    for bone,info in RIG['bones'].items():
        b=armdata.edit_bones.new(bone);b.head=joint(info['head']);b.tail=joint(info['tail'])
        if (b.head-b.tail).length<.0001:b.tail.z+=.01
    for bone,info in RIG['bones'].items():
        if info['parent']:armdata.edit_bones[bone].parent=armdata.edit_bones[info['parent']]
    bpy.ops.object.mode_set(mode='OBJECT');arm.select_set(False)
    arm.location.z=-.5
    def group_center(name):
        ids=set(i for f in GROUPS[name] for i in f)
        return sum((vs[i] for i in ids),Vector())/len(ids)
    neck_y=group_center('joint-neck').y
    eye_raw=group_center('joint-l-eye')
    mouth=group_center('joint-mouth')
    def clothes(p):
        x,y,z=p
        if y<-6.9:return 3
        if y<.9:return 1 if not feminine else 0
        if abs(x)>3.9:return 0
        if feminine and name!='maya':
            if y<neck_y-.4 and abs(x)<1.8:return 1
            return 0
        if y<neck_y+.2:
            if y>neck_y-.25 and abs(x)<.58:return 0
            if z>.6 and abs(x)<.6 and y>3.2:return 2
            return 1
        return 0
    bodyfaces=GROUPS['body'];bodyids=set(i for f in bodyfaces for i in f)
    body=mesh_obj('Tailored adult body',bodyids,bodyfaces,vs,[skin,suit,shirt,shoes,lips],arm,clothes)
    # Slightly raised tailoring shell: proper cloth edges rather than a recoloured body.
    shellfaces=[f for f in bodyfaces if clothes(sum((vs[i] for i in f),Vector())/len(f))==1]
    mesh_obj('Evening garment',set(i for f in shellfaces for i in f),shellfaces,vs,[suit],arm,offset=.008)
    if feminine:
        fs=[f for f in GROUPS['helper-skirt'] if sum(vs[i].y for i in f)/len(f)>-3.7]
        mesh_obj('Knee length cocktail skirt',set(i for f in fs for i in f),fs,vs,[suit],arm)
    # Eyes use basemesh eye helper centres, following the actual adult face morph.
    for side in ['l','r']:
        ids=set(i for f in GROUPS['helper-'+side+'-eye'] for i in f)
        center=sum((transformed(vs[i]) for i in ids),Vector())/len(ids)
        radius=.022
        rigid_bind(sphere('Eye sclera',center,(radius,radius*.84,radius*.78),white),arm)
        at=center+Vector((0,radius*.76,0))
        rigid_bind(sphere('Iris',at,(.0095,.003,.0095),iris),arm)
        rigid_bind(sphere('Pupil',at+Vector((0,.0027,0)),(.0048,.001,.0048),pupil),arm)
        rigid_bind(sphere('Catchlight',at+Vector((-.003,.0035,.003)),(.0017,.001,.0017),white),arm)
    for side in ['l','r']:
        ids=set(i for f in GROUPS['helper-'+side+'-eye'] for i in f)
        center=sum((transformed(vs[i]) for i in ids),Vector())/len(ids)
        points=[center+Vector((dx,.017,.027+(.003 if abs(dx)<.01 else 0))) for dx in [-.026,-.014,0,.014,.026]]
        rigid_bind(curve('Eyebrow',points,.0025 if feminine else .0035,hair,None),arm)
    # Scalp following ellipsoid; high hairline leaves face and ears visible.
    headverts=[vs[i] for i in bodyids if vs[i].y>eye_raw.y-.65 and abs(vs[i].x)<1.4]
    minx=min(v.x for v in headverts);maxx=max(v.x for v in headverts)
    top=max(v.y for v in headverts)
    cx=(minx+maxx)/2;rx=(maxx-minx)*.5+.05;cy=top-1.05;cz=(min(v.z for v in headverts)+max(v.z for v in headverts))/2
    rz=(max(v.z for v in headverts)-min(v.z for v in headverts))*.57
    hverts=[];hfaces=[];rows=14;cols=48
    for row in range(rows+1):
        for col in range(cols):
            phi=2*math.pi*col/cols
            front=(math.cos(phi)+1)/2
            max_theta=(2.55 if feminine else 1.92)*(1-front)+(1.35 if feminine else 1.25)*front
            theta=.025+(max_theta-.025)*row/rows
            raw=Vector((cx+rx*math.sin(theta)*math.sin(phi),cy+1.16*math.cos(theta),cz+rz*math.sin(theta)*math.cos(phi)))
            hverts.append(transformed(raw))
    for r in range(rows):
        for c in range(cols):
            a=r*cols+c;b=r*cols+(c+1)%cols;hfaces.append((a+cols,b+cols,b,a))
    mesh=bpy.data.meshes.new('Sculpted hair');mesh.from_pydata(hverts,[],hfaces);mesh.update()
    ob=bpy.data.objects.new('Sculpted hair',mesh);bpy.context.collection.objects.link(ob);mesh.materials.append(hair)
    for p in mesh.polygons:p.use_smooth=True
    rigid_bind(ob,arm)
    # Fine swept locks, visible as real highlights along the hair silhouette.
    for c in range(0,cols,2):
        points=[hverts[r*cols+c]*1.0 for r in range(2,rows+1,2)]
        rigid_bind(curve('Swept hair strand',points,.0018,hair,None),arm)
    if feminine:
        for sign in [-1,1]:
            ear=transformed(Vector((sign*rx*.99,cy-.43,.0)))
            points=[ear+Vector((.013*math.cos(i*math.tau/24),0,.023*math.sin(i*math.tau/24)-.026)) for i in range(25)]
            rigid_bind(curve('Gold earring',points,.0022,gold,None),arm)
            rigid_bind(sphere('Earring stone',ear+Vector((0,0,-.053)),(.008,.006,.011),iris),arm)
    else:
        # Shirt studs and black bow tie, attached to chest.
        for y in [neck_y-2.1,neck_y-1.5,neck_y-.9]:
            rigid_bind(sphere('Shirt stud',transformed(Vector((0,y,.91))),(.008,.008,.008),gold),arm,'spine01')
        tie=transformed(Vector((0,neck_y-.38,.72)))
        for sign in [-1,1]:rigid_bind(sphere('Bow tie',tie+Vector((sign*.037,0,0)),(.038,.018,.025),shoes),arm,'spine01')
    # Anatomical seated pose. Align paired twist bones in armature space to
    # avoid dependence on IK pole conventions / roll across MakeHuman morphs.
    bpy.context.view_layer.update()
    def point_bone(name,direction):
        b=arm.pose.bones[name]
        old=b.matrix.copy()
        current=(b.tail-b.head).normalized()
        q=current.rotation_difference(Vector(direction).normalized())
        new=q.to_matrix().to_4x4() @ old
        new.translation=old.translation
        b.matrix=new
        bpy.context.view_layer.update()
    for side,sign in [('L',-1),('R',1)]:
        for part in ['upperleg01.','upperleg02.']:point_bone(part+side,(sign*.02,1,-.08))
        for part in ['lowerleg01.','lowerleg02.']:point_bone(part+side,(0,.03,-1))
        for part in ['upperarm01.','upperarm02.']:point_bone(part+side,(sign*.15,.12,-1))
        for part in ['lowerarm01.','lowerarm02.']:point_bone(part+side,(-sign*.06,1,.45))
        point_bone('wrist.'+side,(0,1,-.1))
    scene=bpy.context.scene;scene.frame_start=1;scene.frame_end=64;scene.render.fps=30
    rest={b.name:b.matrix_basis.copy() for b in arm.pose.bones}
    for frame,angle in [(1,0),(16,0),(28,-.22),(40,-.1),(52,0),(64,0)]:
        scene.frame_set(frame)
        for b in arm.pose.bones:
            b.matrix_basis=rest[b.name]
            b.rotation_mode='QUATERNION'
            if b.name=='lowerarm01.R':b.rotation_quaternion=b.rotation_quaternion @ Quaternion((1,0,0),angle)
            b.keyframe_insert('location',frame=frame);b.keyframe_insert('rotation_quaternion',frame=frame);b.keyframe_insert('scale',frame=frame)
    arm.animation_data.action.name='deal'
    # Save a separate gentle idle clip from the baked seated pose.
    deal=arm.animation_data.action
    scene.frame_set(1)
    poses={b.name:b.matrix_basis.copy() for b in arm.pose.bones}
    arm.animation_data.action=None
    for f,angle in [(1,0),(45,.018),(90,0)]:
        scene.frame_set(f)
        for b in arm.pose.bones:
            b.matrix_basis=poses[b.name]
            if b.name=='head':b.rotation_mode='QUATERNION';b.rotation_quaternion=b.rotation_quaternion @ Quaternion((0,1,0),angle)
            b.keyframe_insert('location',frame=f);b.keyframe_insert('rotation_quaternion',frame=f);b.keyframe_insert('scale',frame=f)
    idle=arm.animation_data.action;idle.name='idle'
    # NLA strips expose both actions by name in GLTF and in Godot AnimationPlayer.
    for action in [deal,idle]:
        track=arm.animation_data.nla_tracks.new();track.name=action.name;strip=track.strips.new(action.name,1,action);track.mute=True
    arm.animation_data.action=idle
    scene.frame_end=90;scene.frame_set(1)
    bpy.ops.object.select_all(action='DESELECT')
    for obj in bpy.context.scene.objects:
        if obj.type in {'MESH','ARMATURE'}:obj.select_set(True)
    bpy.context.view_layer.objects.active=arm
    bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_force_sampling=True,export_apply=True,export_yup=True)
    print('EXPORTED',name)

for options in [
 ('gabriel',False,'caucasian',(.025,.034,.044),(.023,.014,.01),(.48,.29,.19)),
 ('elise',True,'caucasian',(.22,.012,.039),(.12,.055,.017),(.61,.39,.28)),
 ('nora',True,'african',(.015,.09,.077),(.011,.007,.006),(.22,.105,.062)),
 ('maya',True,'asian',(.021,.025,.03),(.012,.009,.011),(.52,.31,.19))]:build(*options)
