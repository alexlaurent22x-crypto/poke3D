extends SceneTree
## Resource integration checks: real imported faces, distinct art and outward surfaces.
const Table = preload("res://scripts/table_visuals.gd")
var checks := 0
var failures := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var host := Node3D.new()
	root.add_child(host)
	Table.build(host)
	check(host.has_node("BespokePokerTable"), "main table furniture instantiates")
	var felt: Texture2D = load("res://assets/table/felt.png")
	var felt_image := felt.get_image()
	var fabric := felt_image.get_pixel(10,10)
	check(fabric.g > 0.1 and fabric.g > fabric.r, "felt texture is green, not an unsupported SVG pattern")
	var fingerprints := {}
	for id in 52:
		var node := Table.card(host, id, true)
		var mesh: MeshInstance3D = node.get_child(0)
		check(mesh.mesh.get_surface_count() == 3, "face, rounded paper edge and back: %d" % id)
		var mat: StandardMaterial3D = mesh.mesh.surface_get_material(0)
		check(mat.albedo_texture != null, "imported card face: %d" % id)
		var image := mat.albedo_texture.get_image()
		check(not image.is_empty() and image.get_width() >= 360 and image.get_height() >= 520, "face raster is populated: %d" % id)
		fingerprints[hash(image.get_data())] = true
	check(fingerprints.size() == 52, "every rank/suit has distinct imported artwork")
	var back := Table.card(host,0,false)
	var back_mat: StandardMaterial3D = back.get_child(0).mesh.surface_get_material(0)
	check(not fingerprints.has(hash(back_mat.albedo_texture.get_image().get_data())), "hidden card uses distinct opaque artwork")
	# Clockwise front faces are required by Godot; a normal alone cannot fix culling.
	var meshes := [Table._ellipse_disc(2.45,1.49),Table._ellipse_tube(2.62,1.62,0.18,0.115),Table._rounded_card_mesh()]
	var triangles := 0
	for mesh in meshes:
		for surface in mesh.get_surface_count():
			var arrays: Array = mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			for index in range(0,indices.size(),3):
				var a := indices[index]
				var b := indices[index+1]
				var c := indices[index+2]
				var normal := (normals[a] + normals[b] + normals[c]).normalized()
				check((vertices[b]-vertices[a]).cross(vertices[c]-vertices[a]).dot(normal) < -0.00000001, "outward clockwise triangle %d" % triangles)
				triangles += 1
	print("Visual assets: %d checks, 52 distinct faces, %d triangles, %d failures" % [checks,triangles,failures])
	await create_timer(0.2).timeout
	host.queue_free()
	await process_frame
	await process_frame
	Table._card_materials.clear()
	Table._chip_materials.clear()
	Table._card_geometry = null
	Table._chip_geometry = null
	await process_frame
	quit(1 if failures else 0)
