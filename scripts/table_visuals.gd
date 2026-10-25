class_name TableVisuals
extends RefCounted
## Original casino furniture and complete vector deck. No external artwork.
static var _card_geometry: ArrayMesh
static var _card_materials: Dictionary = {}
static var _chip_materials: Dictionary = {}
static var _chip_geometry: CylinderMesh

static func _pbr(color: Color, metallic: float = 0.0, roughness: float = 0.55) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metallic
	mat.roughness = roughness
	return mat

static func _instance(host: Node3D, mesh: Mesh, pos: Vector3, mat: Material, size: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.material_override = mat
	node.mesh = mesh
	node.position = pos
	node.scale = size
	host.add_child(node)
	return node

static func _box(host: Node3D, pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	return _instance(host, BoxMesh.new(), pos, mat, size)

static func _cylinder(host: Node3D, pos: Vector3, radius: float, depth: float, mat: Material, oval: float = 1.0) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = depth
	mesh.radial_segments = 96
	return _instance(host, mesh, pos, mat, Vector3(1, 1, oval))

static func _ellipse_disc(a: float, b: float) -> ArrayMesh:
	var verts := PackedVector3Array([Vector3.ZERO])
	var normals := PackedVector3Array([Vector3.UP])
	var uv := PackedVector2Array([Vector2(0.5, 0.5)])
	var indices := PackedInt32Array()
	for i in 129:
		var t := float(i) / 128.0 * TAU
		verts.append(Vector3(a * cos(t), 0, b * sin(t)))
		normals.append(Vector3.UP)
		uv.append(Vector2(cos(t), sin(t)) * 0.5 + Vector2(0.5, 0.5))
	for i in 128: indices.append_array([0, i + 1, i + 2])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uv
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

static func _ellipse_tube(a: float, b: float, width: float, height: float, rings: int = 128, sections: int = 12) -> ArrayMesh:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uv := PackedVector2Array()
	var indices := PackedInt32Array()
	for i in range(rings + 1):
		var t := float(i) / rings * TAU
		for j in range(sections + 1):
			var p := float(j) / sections * TAU
			verts.append(Vector3((a + width * cos(p)) * cos(t), height * sin(p), (b + width * cos(p)) * sin(t)))
			normals.append(Vector3(cos(p) * cos(t) / width, sin(p) / height, cos(p) * sin(t) / width).normalized())
			uv.append(Vector2(float(i) / rings, float(j) / sections))
	for i in rings:
		for j in sections:
			var v := i * (sections + 1) + j
			indices.append_array([v, v + sections + 2, v + 1, v, v + sections + 1, v + sections + 2])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uv
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

static func _leather() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """shader_type spatial;
	varying vec3 local_pos;
	void vertex() { local_pos = VERTEX; }
	float hash(vec3 p) { return fract(sin(dot(p, vec3(127.1,311.7,74.7))) * 43758.5453); }
	void fragment() {
		float grain = hash(floor(local_pos * 1600.0));
		float crease = sin(local_pos.x*620.0 + sin(local_pos.z*470.0))*.5+.5;
		ALBEDO = vec3(.042,.031,.026) * (.87 + grain*.25 + crease*.1);
		ROUGHNESS = .40 + grain*.14;
		METALLIC = .02;
	}
	"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	return mat

static func _wood() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """shader_type spatial;
	varying vec3 local_pos;
	void vertex() { local_pos = VERTEX; }
	void fragment() {
		float grain = sin(local_pos.x*80.0 + sin(local_pos.z*6.0)*4.0 + sin(local_pos.z*17.0));
		float fine = sin(local_pos.x*390.0 + sin(local_pos.z*14.0)*8.0)*.5+.5;
		ALBEDO = mix(vec3(.065,.022,.013), vec3(.17,.067,.031), grain*.3+.5) * (.85+fine*.15);
		ROUGHNESS = .29 + fine*.08;
		METALLIC = .04;
	}
	"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	return mat

static func build(host: Node3D) -> void:
	var table := Node3D.new()
	table.name = "BespokePokerTable"
	host.add_child(table)
	var wood := _wood()
	var brass := _pbr(Color("ac8c4d"), 0.76, 0.27)
	var dark := _pbr(Color("13161a"), 0.12, 0.45)
	var leather := _leather()
	# A real pedestal silhouette with brass collars, not one scaled flat cylinder.
	for x in [-1.25, 1.25]:
		_cylinder(table, Vector3(x, 0.10, 0), 0.49, 0.16, dark, 0.82)
		_cylinder(table, Vector3(x, 0.20, 0), 0.40, 0.06, brass, 0.82)
		_cylinder(table, Vector3(x, 0.61, 0), 0.29, 0.77, wood, 0.80)
		_cylinder(table, Vector3(x, 0.97, 0), 0.35, 0.06, brass, 0.80)
	_box(table, Vector3(0, 0.64, 0), Vector3(2.6, 0.15, 0.17), wood)
	_cylinder(table, Vector3(0, 1.16, 0), 2.77, 0.22, wood, 1.77 / 2.77)
	_instance(table, _ellipse_tube(2.74, 1.74, 0.025, 0.023), Vector3(0, 1.22, 0), brass)
	_cylinder(table, Vector3(0, 1.295, 0), 2.55, 0.11, dark, 1.55 / 2.55)
	_instance(table, _ellipse_tube(2.62, 1.62, 0.18, 0.115), Vector3(0, 1.265, 0), leather)
	var felt := _pbr(Color.WHITE, 0.0, 0.92)
	felt.albedo_texture = load("res://assets/table/felt.png")
	felt.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_instance(table, _ellipse_disc(2.45, 1.49), Vector3(0, 1.356, 0), felt)
	_instance(table, _ellipse_tube(2.45, 1.49, 0.008, 0.006), Vector3(0, 1.356, 0), brass)
	# Two hundred stitches in one draw call.
	var stitch_mesh := BoxMesh.new()
	stitch_mesh.size = Vector3(0.026, 0.0035, 0.004)
	stitch_mesh.material = _pbr(Color("9f8a68"), 0, 0.8)
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = stitch_mesh
	multimesh.instance_count = 240
	for i in 240:
		var t := float(i) / 240.0 * TAU
		var tangent := Vector3(-2.51 * sin(t), 0, 1.51 * cos(t)).normalized()
		var basis := Basis(Vector3.UP, atan2(-tangent.z, tangent.x))
		multimesh.set_instance_transform(i, Transform3D(basis, Vector3(2.51*cos(t), 1.359, 1.51*sin(t))))
	var stitches := MultiMeshInstance3D.new()
	stitches.multimesh = multimesh
	table.add_child(stitches)
	for pos in [Vector3(2.61, 1.374, 0.22), Vector3(-2.61, 1.374, 0.22), Vector3(-1.13, 1.374, 1.46), Vector3(1.13, 1.374, 1.46)]:
		_cylinder(table, pos - Vector3(0, 0.015, 0), 0.088, 0.013, dark)
		var ring := TorusMesh.new()
		ring.inner_radius = 0.083
		ring.outer_radius = 0.106
		ring.rings = 24
		ring.ring_segments = 8
		_instance(table, ring, pos, brass, Vector3(1, 0.6, 1))
	# Recessed dealer rack, chip rows and a shoe.
	_box(table, Vector3(1.1, 1.386, -1.22), Vector3(0.89, 0.045, 0.30), brass)
	_box(table, Vector3(1.1, 1.414, -1.22), Vector3(0.85, 0.019, 0.26), dark)
	for i in 5:
		for j in 5:
			chip(table, Vector3(0.78 + i * 0.16, 1.438 + j * 0.021, -1.22), [Color("b43c43"),Color("315d64"),Color("dbcfaa"),Color("323847"),Color("ba9650")][i], i)
	_box(table, Vector3(-0.43, 1.395, -1.28), Vector3(0.42, 0.06, 0.60), dark)
	var deck := card(table, 0, false)
	deck.position = Vector3(-0.43, 1.445, -1.28)
	deck.scale.y = 2.4
	# Small embossed identification plate.
	_box(table, Vector3(0, 1.16, 1.79), Vector3(0.57, 0.07, 0.012), brass)

static func _rounded_card_mesh() -> ArrayMesh:
	var points: Array[Vector2] = []
	var w := 0.185
	var h := 0.265
	var r := 0.016
	for c in 4:
		var center: Vector2 = [Vector2(w-r,h-r),Vector2(-w+r,h-r),Vector2(-w+r,-h+r),Vector2(w-r,-h+r)][c]
		for j in 7:
			var t := float(c) * PI * 0.5 + float(j) / 6.0 * PI * 0.5
			points.append(center + Vector2(cos(t),sin(t))*r)
	var mesh := ArrayMesh.new()
	for side in 3:
		var verts := PackedVector3Array()
		var normals := PackedVector3Array()
		var uv := PackedVector2Array()
		var indices := PackedInt32Array()
		if side != 1:
			var y := 0.007 if side == 0 else -0.007
			var normal := Vector3.UP if side == 0 else Vector3.DOWN
			verts.append(Vector3(0,y,0))
			normals.append(normal)
			uv.append(Vector2(0.5,0.5))
			for p in points:
				verts.append(Vector3(p.x,y,p.y))
				normals.append(normal)
				uv.append(Vector2(p.x/0.37+0.5,p.y/0.53+0.5))
			for i in points.size():
				var a := i+1
				var b := (i+1)%points.size()+1
				indices.append_array([0,a,b] if side == 0 else [0,b,a])
		else:
			for i in points.size():
				var p := points[i]
				var q := points[(i+1)%points.size()]
				var n := Vector3(p.x,0,p.y).normalized()
				var start := verts.size()
				verts.append_array([Vector3(p.x,-0.007,p.y),Vector3(p.x,0.007,p.y),Vector3(q.x,0.007,q.y),Vector3(q.x,-0.007,q.y)])
				for j in 4:
					normals.append(n)
					uv.append(Vector2.ZERO)
				indices.append_array([start,start+2,start+1,start,start+3,start+2])
		var arrays: Array = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = verts
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_TEX_UV] = uv
		arrays[Mesh.ARRAY_INDEX] = indices
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return mesh

static func _card_material(key: String) -> StandardMaterial3D:
	if not _card_materials.has(key):
		var mat := _pbr(Color.WHITE,0,0.65)
		mat.albedo_texture = load("res://assets/table/cards/"+key+".png")
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		_card_materials[key] = mat
	return _card_materials[key]

static func card(host: Node3D, card_id: int, face: bool) -> Node3D:
	if _card_geometry == null:
		_card_geometry = _rounded_card_mesh()
		for surface in 3: _card_geometry.surface_set_material(surface,_pbr(Color("eee9dd")))
	var root := Node3D.new()
	root.name = "PrintedCard"
	host.add_child(root)
	var node := MeshInstance3D.new()
	var geometry: ArrayMesh = _card_geometry.duplicate()
	geometry.surface_set_material(0,_card_material("%02d"%card_id if face else "back"))
	geometry.surface_set_material(1,_pbr(Color("e9dfc7"),0,0.85))
	geometry.surface_set_material(2,_card_material("back"))
	node.mesh = geometry
	root.add_child(node)
	return root

static func chip(host: Node3D, pos: Vector3, color: Color, _index: int = 0) -> MeshInstance3D:
	if _chip_geometry == null:
		_chip_geometry = CylinderMesh.new()
		_chip_geometry.top_radius = 0.071
		_chip_geometry.bottom_radius = 0.071
		_chip_geometry.height = 0.019
		_chip_geometry.radial_segments = 32
	var key := color.to_html()
	if not _chip_materials.has(key):
		var shader := Shader.new()
		shader.code = """shader_type spatial;
		uniform vec4 color : source_color;
		varying vec3 pos;
		void vertex(){pos = VERTEX;}
		void fragment(){
			float r = length(pos.xz) / .071;
			float angle = atan(pos.z,pos.x);
			float stripe = step(.53, sin(angle*6.0)*.5+.5);
			vec3 ink = mix(color.rgb,vec3(.85,.82,.72),stripe * step(.76,r));
			float ring = (1.0-smoothstep(.014,.027,abs(r-.62))) + (1.0-smoothstep(.01,.02,abs(r-.45)));
			ALBEDO = mix(ink,vec3(.77,.67,.44),clamp(ring,0.0,.7));
			ROUGHNESS = .62;
		}
		"""
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("color",color)
		_chip_materials[key] = mat
	return _instance(host,_chip_geometry,pos,_chip_materials[key])
