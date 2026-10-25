class_name CasinoRoom
extends RefCounted
## Original Art Deco lounge. Build once; no imported artwork or runtime dependencies.
## Geometry excludes the poker table, actors, world environment and camera.

static func build(host: Node3D) -> void:
	var room := Node3D.new()
	room.name = "SalonArtDeco"
	host.add_child(room)
	var walnut := _wood()
	var brass := _material(Color("b7985b"), 0.78, 0.3)
	var dark_brass := _material(Color("665136"), 0.72, 0.38)
	var charcoal := _material(Color("14181c"), 0.15, 0.48)
	var velvet := _material(Color("183c39"), 0.0, 0.93)
	var plaster := _material(Color("262b2b"), 0.0, 0.95)
	var marble := _marble()
	var warm_glass := _material(Color("f0d9ae"), 0.18, 0.24)
	warm_glass.emission_enabled = true
	warm_glass.emission = Color("ffdb9e")
	warm_glass.emission_energy_multiplier = 1.25
	# A carpet island encircled by dark marble. Gold stays a thin architectural accent.
	_box(room, Vector3(0, -0.1, 0), Vector3(19, 0.18, 16), marble)
	_box(room, Vector3(0, 0.005, 0), Vector3(11.5, 0.025, 10.5), _carpet())
	for x in [-5.79, 5.79]:
		_box(room, Vector3(x, 0.018, 0), Vector3(0.035, 0.012, 10.65), dark_brass)
	for z in [-5.31, 5.31]:
		_box(room, Vector3(0, 0.018, z), Vector3(11.62, 0.012, 0.035), dark_brass)
	# Real enclosing surfaces and panelled lower walls, so the room reads as architecture.
	_box(room, Vector3(0, 2.8, -7.3), Vector3(19, 5.6, 0.22), plaster)
	_box(room, Vector3(0, 0.67, -7.12), Vector3(19, 1.34, 0.13), walnut)
	_box(room, Vector3(0, 1.37, -7.0), Vector3(19, 0.09, 0.12), brass)
	_box(room, Vector3(0, 0.12, -6.98), Vector3(19, 0.17, 0.15), charcoal)
	for x in [-9.1, 9.1]:
		_box(room, Vector3(x, 2.8, 0), Vector3(0.2, 5.6, 14.6), plaster)
		_box(room, Vector3(x * 0.985, 0.65, 0), Vector3(0.16, 1.3, 14.6), walnut)
		_box(room, Vector3(x * 0.975, 1.37, 0), Vector3(0.1, 0.09, 14.6), brass)
	# Shallow ceiling coffers. A real ceiling keeps the hanging lights grounded.
	_box(room, Vector3(0, 5.5, 0), Vector3(18.4, 0.15, 14.6), charcoal)
	for x in [-7.5, -3.6, 3.6, 7.5]:
		_box(room, Vector3(x, 5.36, 0), Vector3(0.12, 0.18, 14.6), walnut)
	for z in [-6.3, -3.2, 3.2, 6.3]:
		_box(room, Vector3(0, 5.36, z), Vector3(18.2, 0.18, 0.12), walnut)
	# Monumental central inset: a curved, stepped arch rather than a flat logo wall.
	_box(room, Vector3(0, 3.05, -7.08), Vector3(5.4, 3.25, 0.14), charcoal)
	for inset in 3:
		var radius: float = 2.35 + inset * 0.13
		var points := PackedVector3Array()
		points.append(Vector3(-radius, 1.5, -6.94))
		for step in 49:
			var a: float = PI - float(step) / 48.0 * PI
			points.append(Vector3(cos(a) * radius, 3.2 + sin(a) * 1.62, -6.94))
		points.append(Vector3(radius, 1.5, -6.94))
		_tube(room, points, 0.018 if inset != 1 else 0.034, brass, 6)
	_sign(room, "M I N U I T", Vector3(0, 3.77, -6.85), 102, Color("d7ba7e"))
	_sign(room, "P O K E R   •   S A L O N   P R I V É", Vector3(0, 3.24, -6.84), 25, Color("b7aa90"))
	_sign(room, "EST.  2026", Vector3(0, 2.9, -6.84), 22, Color("8b806d"))
	# Fluted wall sections and fan-shaped metal reliefs.
	for side in [-1.0, 1.0]:
		var center: float = side * 5.75
		_box(room, Vector3(center, 3.15, -7.0), Vector3(3.7, 3.25, 0.12), walnut)
		for dx in [-1.45, -0.72, 0.0, 0.72, 1.45]:
			_box(room, Vector3(center + dx, 3.14, -6.9), Vector3(0.025, 3.03, 0.04), dark_brass)
		for frame in 2:
			var rx: float = 1.28 + frame * 0.12
			var points := PackedVector3Array()
			for k in 49:
				var a: float = PI * float(k) / 48.0
				points.append(Vector3(center + cos(a) * rx, 2.8 + sin(a) * 1.1, -6.81))
			_tube(room, points, 0.016, brass, 5)
		for ray in 7:
			var a: float = PI * float(ray + 1) / 8.0
			_tube(room, PackedVector3Array([Vector3(center, 2.8, -6.8), Vector3(center + cos(a) * 1.28, 2.8 + sin(a) * 1.1, -6.8)]), 0.011, dark_brass, 5)
	# Four shaded sconces: modest luminous surfaces, warm pools on the walls.
	for x in [-8.1, -3.3, 3.3, 8.1]:
		_box(room, Vector3(x, 2.85, -6.76), Vector3(0.28, 0.75, 0.1), brass)
		_cylinder(room, Vector3(x, 2.85, -6.61), 0.12, 0.62, warm_glass, 24)
		_cylinder(room, Vector3(x, 3.2, -6.61), 0.15, 0.05, brass, 24)
		_cylinder(room, Vector3(x, 2.5, -6.61), 0.15, 0.05, brass, 24)
		_omni(room, Vector3(x, 3.0, -6.28), Color("ffd3a0"), 0.8, 3.6)
	_build_bar(room, walnut, brass, charcoal, warm_glass)
	_build_lounge(room, velvet, brass, walnut)
	_build_chandelier(room, brass, warm_glass)
	# Two shadow-casting keys only. Soft fill is deliberately shadow-free.
	for x in [-1.8, 1.8]:
		var key := SpotLight3D.new()
		key.name = "TableKeyLeft" if x < 0 else "TableKeyRight"
		key.position = Vector3(x, 4.6, 0.5)
		key.rotation_degrees.x = -90
		key.light_color = Color("ffe3bd")
		key.light_energy = 4.3
		key.spot_range = 8.0
		key.spot_angle = 52
		key.spot_angle_attenuation = 0.55
		key.light_size = 0.35
		key.shadow_enabled = true
		key.shadow_blur = 1.5
		room.add_child(key)
	_omni(room, Vector3(0, 3.7, 4.0), Color("b9c9e2"), 1.1, 8.0)
	_omni(room, Vector3(0, 3.8, -3.8), Color("ffcf98"), 1.2, 7.0)

static func _build_bar(parent: Node3D, wood: Material, brass: Material, black: Material, glow: Material) -> void:
	# Bar sits behind the left-hand opponent and never blocks the table.
	_box(parent, Vector3(-5.8, 0.65, -4.85), Vector3(4.15, 1.3, 0.92), wood)
	_box(parent, Vector3(-5.8, 1.34, -4.85), Vector3(4.4, 0.12, 1.1), _marble())
	_box(parent, Vector3(-5.8, 0.72, -4.36), Vector3(3.9, 0.84, 0.03), black)
	for x in [-7.5, -6.65, -5.8, -4.95, -4.1]:
		_box(parent, Vector3(x, 0.7, -4.32), Vector3(0.025, 0.88, 0.04), brass)
	_tube(parent, PackedVector3Array([Vector3(-7.75, 0.22, -4.04), Vector3(-3.85, 0.22, -4.04)]), 0.035, brass)
	for y in [1.6, 2.25]:
		_box(parent, Vector3(-5.8, y, -6.6), Vector3(4.05, 0.055, 0.36), wood)
		_box(parent, Vector3(-5.8, y + 0.04, -6.44), Vector3(4, 0.018, 0.025), glow)
		for i in 7:
			var x: float = -7.42 + i * 0.54
			var hue := Color("263e2d") if i % 3 == 0 else (Color("744624") if i % 3 == 1 else Color("344547"))
			var bottle := _material(hue, 0.22, 0.19)
			_cylinder(parent, Vector3(x, y + 0.2, -6.58), 0.065, 0.3, bottle, 16)
			_cylinder(parent, Vector3(x, y + 0.405, -6.58), 0.027, 0.12, bottle, 12)
			_box(parent, Vector3(x, y + 0.19, -6.507), Vector3(0.088, 0.1, 0.012), _material(Color("d7c9a9")))
	_omni(parent, Vector3(-5.8, 2.8, -5.9), Color("e8ad70"), 0.8, 4.0)

static func _build_lounge(parent: Node3D, velvet: Material, brass: Material, wood: Material) -> void:
	# Rounded banquette upholstery is formed with stretched capsules, not box-shaped seats.
	for x in [5.15, 6.55, 7.95]:
		_capsule(parent, Vector3(x, 0.62, -5.45), Vector3(1.35, 0.22, 0.9), velvet, true)
		_capsule(parent, Vector3(x, 1.18, -5.85), Vector3(1.35, 1.08, 0.24), velvet, true)
		for button_x in [-0.34, 0.34]:
			_sphere(parent, Vector3(x + button_x, 1.25, -5.708), Vector3.ONE * 0.025, brass, 8)
	for x in [4.4, 8.7]:
		_capsule(parent, Vector3(x, 0.95, -5.45), Vector3(0.2, 0.5, 0.95), velvet, true)
	_cylinder(parent, Vector3(6.5, 0.6, -4.3), 0.045, 1.15, brass, 16)
	_cylinder(parent, Vector3(6.5, 0.08, -4.3), 0.4, 0.08, wood, 32)
	_cylinder(parent, Vector3(6.5, 1.19, -4.3), 0.7, 0.06, _marble(), 48)
	# A little glassware catches the light without transparency sorting or refraction cost.
	var crystal := _material(Color("929d9b"), 0.35, 0.12)
	for x in [6.2, 6.65]:
		_cylinder(parent, Vector3(x, 1.25, -4.3), 0.04, 0.11, brass, 12)
		_sphere(parent, Vector3(x, 1.37, -4.3), Vector3(0.075, 0.09, 0.075), crystal, 16)

static func _build_chandelier(parent: Node3D, brass: Material, glow: Material) -> void:
	_cylinder(parent, Vector3(0, 5.08, -0.2), 0.025, 0.75, brass, 12)
	for r in [1.3, 1.65]:
		var points := PackedVector3Array()
		for k in 97:
			var a: float = TAU * float(k) / 96.0
			points.append(Vector3(cos(a) * r, 4.58, -0.2 + sin(a) * r * 0.58))
		_tube(parent, points, 0.025, brass, 6)
	for k in 14:
		var a: float = TAU * float(k) / 14.0
		var pos := Vector3(cos(a) * 1.47, 4.52, -0.2 + sin(a) * 0.86)
		_cylinder(parent, pos, 0.045, 0.34, glow, 16)
		_cylinder(parent, pos + Vector3(0, 0.19, 0), 0.065, 0.035, brass, 16)

static func _material(color: Color, metal := 0.0, roughness := 0.65) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metal
	material.roughness = roughness
	return material

static func _carpet() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """shader_type spatial;
	varying vec3 world_pos;
	void vertex(){ world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
	void fragment(){
		vec2 p=world_pos.xz*1.15;
		vec2 tile=fract(p)-0.5;
		float arch=abs(length(vec2(tile.x,tile.y+0.5))-0.48);
		float fan=1.0-smoothstep(0.006,0.014,arch);
		float grain=fract(sin(dot(world_pos.xz*1300.0,vec2(12.9898,78.233)))*43758.5453);
		ALBEDO=mix(vec3(0.025,0.05,0.058),vec3(0.11,0.115,0.09),fan*0.52)+grain*0.009;
		ROUGHNESS=0.97;
	}"""
	var material := ShaderMaterial.new()
	material.shader = shader
	return material

static func _wood() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """shader_type spatial;
	varying vec3 world_pos;
	void vertex(){ world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
	void fragment(){
		float grain=sin(world_pos.x*65.0+sin(world_pos.y*3.0+world_pos.z*2.0)*1.8)*0.5+0.5;
		float fine=sin(world_pos.x*247.0+world_pos.y*3.0)*0.5+0.5;
		ALBEDO=mix(vec3(0.045,0.021,0.014),vec3(0.14,0.07,0.037),grain*0.5+fine*0.15);
		ROUGHNESS=0.48; METALLIC=0.05;
	}"""
	var material := ShaderMaterial.new()
	material.shader = shader
	return material

static func _marble() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """shader_type spatial;
	varying vec3 world_pos;
	void vertex(){world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
	void fragment(){
		vec2 p=world_pos.xz;
		float veins=sin(p.x*3.1+p.y*2.3+sin(p.y*4.0+p.x)*0.7+sin(p.x*8.0)*0.14);
		float vein=pow(1.0-abs(veins),22.0);
		ALBEDO=mix(vec3(0.055,0.063,0.067),vec3(0.2,0.21,0.2),vein*0.55);
		ROUGHNESS=0.24; METALLIC=0.12;
	}"""
	var material := ShaderMaterial.new()
	material.shader = shader
	return material

static func _mesh(parent: Node3D, mesh: Mesh, position: Vector3, material: Material, scale := Vector3.ONE) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = position
	instance.scale = scale
	instance.material_override = material
	parent.add_child(instance)
	return instance

static func _box(parent: Node3D, position: Vector3, size: Vector3, material: Material) -> void:
	_mesh(parent, BoxMesh.new(), position, material, size)

static func _cylinder(parent: Node3D, position: Vector3, radius: float, height: float, material: Material, segments := 32) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = segments
	_mesh(parent, mesh, position, material)

static func _sphere(parent: Node3D, position: Vector3, scale: Vector3, material: Material, segments := 24) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 1
	mesh.height = 2
	mesh.radial_segments = segments
	mesh.rings = maxi(4, segments / 2)
	_mesh(parent, mesh, position, material, scale)

static func _capsule(parent: Node3D, position: Vector3, scale: Vector3, material: Material, horizontal := false) -> void:
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.5
	mesh.height = 2
	mesh.radial_segments = 20
	mesh.rings = 6
	var instance := _mesh(parent, mesh, position, material, Vector3(scale.x, scale.y * 0.5, scale.z))
	if horizontal:
		# Capsule's long axis follows the width of the upholstery.
		instance.scale = Vector3(scale.y, scale.x * 0.5, scale.z)
		instance.rotation.z = PI / 2

static func _tube(parent: Node3D, points: PackedVector3Array, radius: float, material: Material, sides := 8) -> void:
	if points.size() < 2: return
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(points.size() - 1):
		var direction := (points[i + 1] - points[i]).normalized()
		var up := Vector3.UP if absf(direction.dot(Vector3.UP)) < 0.95 else Vector3.FORWARD
		var side := direction.cross(up).normalized()
		var second := direction.cross(side).normalized()
		for k in sides:
			var a: float = TAU * float(k) / sides
			var b: float = TAU * float(k + 1) / sides
			var na := side * cos(a) + second * sin(a)
			var nb := side * cos(b) + second * sin(b)
			for data in [[points[i] + na * radius, na], [points[i + 1] + na * radius, na], [points[i + 1] + nb * radius, nb], [points[i] + na * radius, na], [points[i + 1] + nb * radius, nb], [points[i] + nb * radius, nb]]:
				st.set_normal(data[1])
				st.add_vertex(data[0])
	st.index()
	_mesh(parent, st.commit(), Vector3.ZERO, material)

static func _sign(parent: Node3D, text: String, position: Vector3, font_size: int, color: Color) -> void:
	var label := Label3D.new()
	label.text = text
	label.position = position
	label.font_size = font_size
	label.pixel_size = 0.003
	label.outline_size = 0
	label.modulate = color
	parent.add_child(label)

static func _omni(parent: Node3D, position: Vector3, color: Color, energy: float, distance: float) -> void:
	var light := OmniLight3D.new()
	light.position = position
	light.light_color = color
	light.light_energy = energy
	light.omni_range = distance
	light.omni_attenuation = 1.7
	light.shadow_enabled = false
	parent.add_child(light)
