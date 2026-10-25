extends SceneTree
## Capture the real game (requires a graphical display, not --headless).
## godot --path . --script res://tools/capture_scene.gd -- --detail
func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	Engine.time_scale = 12.0
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.game.rng.seed = 17
	root.add_child(scene)
	if "--detail" in OS.get_cmdline_user_args():
		scene.camera.position = Vector3(0.2, 2.15, 1.45)
		scene.camera.look_at(Vector3(0.1, 1.8, -2.2), Vector3.UP)
		scene.camera.fov = 57
	scene.muted = true
	scene.set_process(false)
	await create_timer(3.0).timeout
	while scene.game.actor > 0 and not scene.game.finished: scene.game.act("check_call")
	scene.animation_busy = false
	scene.update_buttons()
	scene.toggle_peek()
	await RenderingServer.frame_post_draw
	var path := "/tmp/poke3d-detail.png" if "--detail" in OS.get_cmdline_user_args() else "/tmp/poke3d-screenshot.png"
	var error := root.get_texture().get_image().save_png(path)
	print("Screenshot: ", path, " error=", error)
	call_deferred("finish_capture", scene, error)

func finish_capture(scene: Node, error: int) -> void:
	# Let SceneTree own teardown, as in the actual game quit path.
	quit(0 if error == OK else 1)
